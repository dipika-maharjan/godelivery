import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_theme.dart';
import '../core/network/api_exception.dart';
import '../data/riders_repository.dart';
import '../models/rider.dart';

class RiderAvailabilityCard extends ConsumerStatefulWidget {
  const RiderAvailabilityCard({super.key});

  @override
  ConsumerState<RiderAvailabilityCard> createState() =>
      _RiderAvailabilityCardState();
}

class _RiderAvailabilityCardState extends ConsumerState<RiderAvailabilityCard>
    with WidgetsBindingObserver {
  Rider? _rider;
  bool _loading = true;
  bool _acting = false;
  StreamSubscription<ServiceStatus>? _locationStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationStatusSubscription = Geolocator.getServiceStatusStream().listen(
      _onLocationServiceStatus,
    );
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncAvailabilityWithLocation();
  }

  void _onLocationServiceStatus(ServiceStatus status) {
    if (status == ServiceStatus.disabled) _disableAvailability();
  }

  Future<void> _load() async {
    try {
      final rider = await ref.read(ridersRepositoryProvider).getMe();
      if (!mounted) return;
      setState(() {
        _rider = rider;
        _loading = false;
      });
      await _syncAvailabilityWithLocation();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _ensureLocationForAvailability() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return 'Allow location access in Settings, then try again.';
    }
    if (permission == LocationPermission.denied) {
      return 'Location permission is needed to go online.';
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return 'Turn on location services, then try again.';
    }
    return null;
  }

  Future<void> _syncAvailabilityWithLocation() async {
    final rider = _rider;
    if (rider == null || !rider.isAvailable || _acting) return;
    final permission = await Geolocator.checkPermission();
    if (!await Geolocator.isLocationServiceEnabled() ||
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _disableAvailability();
    }
  }

  Future<void> _disableAvailability() async {
    final rider = _rider;
    if (rider == null || !rider.isAvailable || _acting) return;
    setState(() => _acting = true);
    try {
      final updated = await ref
          .read(ridersRepositoryProvider)
          .setAvailability(false);
      if (mounted) setState(() => _rider = updated);
    } catch (_) {
      // The next resume or service-status event retries synchronization.
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (_acting) return;
    if (value) {
      final error = await _ensureLocationForAvailability();
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }
    }
    setState(() => _acting = true);
    try {
      final updated = await ref
          .read(ridersRepositoryProvider)
          .setAvailability(value);
      if (mounted) setState(() => _rider = updated);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException
            ? error.message
            : 'Could not update availability.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rider = _rider;
    if (_loading || rider == null) {
      return const SizedBox(
        height: 64,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final online = rider.isAvailable;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: online ? AppColors.primary : context.colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadowSoft,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: online
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : context.colors.cardAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(
              online ? LucideIcons.radio : LucideIcons.power,
              size: 19,
              color: online ? AppColors.onPrimary : context.colors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  online ? 'You are online' : 'You are offline',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  online
                      ? 'Ready to receive new deliveries'
                      : 'Go online to receive new deliveries',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_acting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Switch(
              value: online,
              onChanged: _toggleAvailability,
              activeTrackColor: AppColors.primary,
              activeThumbColor: AppColors.onPrimary,
            ),
        ],
      ),
    );
  }
}
