import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_theme.dart';
import '../data/order_repository.dart';
import '../models/live_location.dart';
import '../models/order.dart';
import '../models/rider.dart';

/// Statuses where a rider is moving the parcel — only mount
/// [LiveRiderMapCard] for these so finished orders don't keep polling.
const liveTrackableStatuses = {
  OrderStatus.pending,
  OrderStatus.confirmed,
  OrderStatus.pickedUp,
  OrderStatus.inTransit,
  OrderStatus.outForDelivery,
};

const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _pollInterval = Duration(seconds: 5);
const _glideDuration = Duration(milliseconds: 1200);
// After the viewer pans/zooms, stop auto-following for a while so the map
// doesn't jump away from what they're looking at.
const _followPause = Duration(seconds: 20);
// Straight-line distance undercounts real roads; rough urban detour factor,
// and a typical city motorbike speed when the device reports none.
const _roadFactor = 1.3;
const _fallbackSpeedKmh = 20.0;
const _liveGreen = Color(0xFF10B981);

/// Uber-style live map of the rider on an order's current leg. Shows only
/// while that rider is sharing their location (they switch it on from their
/// delivery screen); otherwise renders [placeholder], or nothing.
class LiveRiderMapCard extends ConsumerStatefulWidget {
  /// Sender, receiver or admin view — any leg, with the destination pin.
  const LiveRiderMapCard.forOrder(String this.orderId, {super.key, this.placeholder})
    : trackingNumber = null;

  /// Public tracking view — last-mile only, no destination.
  const LiveRiderMapCard.forTracking(String this.trackingNumber, {super.key})
    : orderId = null,
      placeholder = null;

  final String? orderId;
  final String? trackingNumber;
  final Widget? placeholder;

  @override
  ConsumerState<LiveRiderMapCard> createState() => _LiveRiderMapCardState();
}

class _LiveRiderMapCardState extends ConsumerState<LiveRiderMapCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _mapController = MapController();
  late final AnimationController _glide = AnimationController(
    vsync: this,
    duration: _glideDuration,
  );

  OrderLiveLocation? _live;
  LatLng? _from;
  LatLng? _to;
  Timer? _pollTimer;
  Timer? _clockTimer;
  bool _mapReady = false;
  bool _fitted = false;
  DateTime _userMovedAt = DateTime.fromMillisecondsSinceEpoch(0);

  LatLng? get _displayed {
    final from = _from;
    final to = _to;
    if (to == null) return null;
    if (from == null) return to;
    final t = Curves.easeInOut.transform(_glide.value);
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
    // Keeps the "updated 12s ago" label ticking between polls.
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _live?.sharing == true) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _glide.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _poll();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    final repo = ref.read(orderRepositoryProvider);
    try {
      final next = widget.orderId != null
          ? await repo.liveLocation(widget.orderId!)
          : await repo.trackLiveLocation(widget.trackingNumber!);
      if (!mounted) return;
      _apply(next);
    } catch (_) {
      // Keep the last known position on screen; the next tick retries.
    }
  }

  void _apply(OrderLiveLocation next) {
    final position = next.position;
    setState(() {
      _live = next;
      if (!next.sharing || position == null) {
        _from = null;
        _to = null;
        _fitted = false;
        // The map unmounts with this state; it reports ready again on remount.
        _mapReady = false;
        return;
      }
      if (_to == null) {
        _to = position;
      } else if (position != _to) {
        _from = _displayed;
        _to = position;
        _glide.forward(from: 0);
      }
    });
    if (next.sharing && position != null) _updateCamera(next, position);
  }

  void _updateCamera(OrderLiveLocation live, LatLng position) {
    if (!_mapReady) return;
    if (!_fitted) {
      _fitted = true;
      final destination = live.destination;
      if (destination != null) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds(position, destination),
            padding: const EdgeInsets.all(48),
            maxZoom: 16,
          ),
        );
      } else {
        _mapController.move(position, 16);
      }
      return;
    }
    final following = DateTime.now().difference(_userMovedAt) > _followPause;
    if (following && !_mapController.camera.visibleBounds.contains(position)) {
      _mapController.move(position, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = _live;
    final position = _to;
    if (live == null || !live.sharing || position == null) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    final secondsAgo = live.recordedAt == null
        ? 0
        : math.max(0, DateTime.now().difference(live.recordedAt!).inSeconds);
    final destination = live.destination;
    final remainingKm = destination == null
        ? null
        : const Distance().as(LengthUnit.Meter, position, destination) / 1000 * _roadFactor;
    final speed = (live.speedKmh ?? 0) > 5 ? live.speedKmh! : _fallbackSpeedKmh;
    final etaMin = remainingKm == null ? null : math.max(1, (remainingKm / speed * 60).round());

    final vehicle = [
      if (live.vehicleType != null) vehicleTypeLabel(live.vehicleType!),
      if (live.vehiclePlateNumber != null) live.vehiclePlateNumber!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.cardAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bike, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      live.riderName ?? 'Your rider',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      [
                        live.isDeliveryLeg ? 'On the way to deliver' : 'Pickup rider',
                        if (vehicle.isNotEmpty) vehicle,
                      ].join(' · '),
                      style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                    ),
                  ],
                ),
              ),
              _LiveBadge(isLive: live.isLive, secondsAgo: secondsAgo),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 260,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onMapReady: () {
                    _mapReady = true;
                    _updateCamera(live, position);
                  },
                  onPositionChanged: (_, hasGesture) {
                    if (hasGesture) _userMovedAt = DateTime.now();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _osmTileUrl,
                    userAgentPackageName: 'com.godokan.godelivery',
                  ),
                  if (live.trail.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: live.trail,
                          color: _liveGreen.withValues(alpha: 0.6),
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  if (destination != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: destination,
                          width: 36,
                          height: 36,
                          alignment: Alignment.topCenter,
                          child: const Icon(LucideIcons.mapPin, color: AppColors.danger, size: 34),
                        ),
                      ],
                    ),
                  AnimatedBuilder(
                    animation: _glide,
                    builder: (context, _) => MarkerLayer(
                      markers: [
                        Marker(
                          point: _displayed ?? position,
                          width: 44,
                          height: 44,
                          child: _RiderDot(isLive: live.isLive, heading: live.heading),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (remainingKm != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.navigation, size: 14, color: context.colors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${live.destinationLabel ?? 'Destination'}: ~'
                      '${remainingKm < 1 ? '${(remainingKm * 1000).round()} m' : '${remainingKm.toStringAsFixed(1)} km'}'
                      '${etaMin != null ? ' · about $etaMin min' : ''}',
                      style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                    ),
                  ],
                ),
              Text(
                'Updated ${_agoLabel(secondsAgo)}',
                style: TextStyle(fontSize: 12, color: context.colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _agoLabel(int seconds) {
  if (seconds < 10) return 'just now';
  if (seconds < 60) return '${seconds}s ago';
  return '${seconds ~/ 60} min ago';
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.isLive, required this.secondsAgo});

  final bool isLive;
  final int secondsAgo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLive ? _liveGreen : context.colors.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            const _PulsingDot(),
            const SizedBox(width: 6),
          ],
          Text(
            isLive ? 'Live' : 'Last seen ${_agoLabel(secondsAgo)}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isLive ? Colors.white : context.colors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}

/// Rider marker: a green dot with a halo while live (grey when stale), and
/// an arrow rotated to the GPS heading when the device reports one.
class _RiderDot extends StatelessWidget {
  const _RiderDot({required this.isLive, required this.heading});

  final bool isLive;
  final double? heading;

  @override
  Widget build(BuildContext context) {
    final color = isLive ? _liveGreen : Colors.grey.shade600;
    final hasHeading = heading != null && heading! >= 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isLive)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.25), shape: BoxShape.circle),
          ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: hasHeading
              ? Transform.rotate(
                  angle: heading! * math.pi / 180,
                  child: const Icon(Icons.navigation, size: 15, color: Colors.white),
                )
              : const Center(
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
