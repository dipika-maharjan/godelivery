import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/payment_display.dart';
import '../../../core/utils/status_display.dart';
import '../../../data/order_repository.dart';
import '../../../models/location.dart';
import '../../../models/order.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/live_location_sharing_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/rider_jobs_provider.dart';
import '../../../widgets/order_status_chip.dart';
import '../../../widgets/package_flags_row.dart';

const _pickupShareStatuses = {
  OrderStatus.pending,
  OrderStatus.confirmed,
  OrderStatus.pickedUp,
  OrderStatus.inTransit,
};

const _terminalStatuses = {
  OrderStatus.delivered,
  OrderStatus.failedDelivery,
  OrderStatus.cancelled,
  OrderStatus.returned,
};

class RiderOrderDetailPage extends ConsumerWidget {
  const RiderOrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery'),
        actions: [
          IconButton(
            tooltip: 'Refresh order',
            onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            error is ApiException ? error.message : 'Something went wrong.',
          ),
        ),
        data: (value) => _RiderOrderDetailBody(order: value),
      ),
    );
  }
}

class _NextAction {
  const _NextAction(this.status, this.title, this.label);

  final OrderStatus status;
  final String title;
  final String label;
}

class _RiderOrderDetailBody extends ConsumerStatefulWidget {
  const _RiderOrderDetailBody({required this.order});

  final Order order;

  @override
  ConsumerState<_RiderOrderDetailBody> createState() =>
      _RiderOrderDetailBodyState();
}

class _RiderOrderDetailBodyState extends ConsumerState<_RiderOrderDetailBody> {
  bool _acting = false;

  Future<void> _openNavigation(LocationResponse destination) async {
    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': '${destination.latitude},${destination.longitude}',
        'travelmode': 'driving',
      },
    );
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No map application is available.'),
        ),
      );
    }
  }

  Future<void> _run(
    Future<Order> Function(OrderRepository repo) action,
    String successMessage,
  ) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await action(ref.read(orderRepositoryProvider));
      ref.invalidate(orderDetailProvider(widget.order.id));
      ref.invalidate(riderAssignedOrdersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      final message = e is ApiException ? e.message : 'Something went wrong.';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<Position?> _tryGetPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<void> _performNextAction(_NextAction next) async {
    final position = await _tryGetPosition();
    await _run(
      (repo) => repo.updateStatus(
        widget.order.id,
        status: next.status,
        title: next.title,
        latitude: position?.latitude,
        longitude: position?.longitude,
      ),
      '${next.title}.',
    );
  }

  Future<void> _confirmFailedDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report failed delivery?'),
        content: const Text(
          'This records the delivery as failed for this order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Report failed',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final position = await _tryGetPosition();
    await _run(
      (repo) => repo.updateStatus(
        widget.order.id,
        status: OrderStatus.failedDelivery,
        title: 'Failed delivery',
        latitude: position?.latitude,
        longitude: position?.longitude,
      ),
      'Marked as failed delivery.',
    );
  }

  Future<void> _captureReceiverSignature() async {
    final signature = await showDialog<String>(
      context: context,
      builder: (_) => const _SignatureCaptureDialog(),
    );
    if (signature == null) return;
    await _run(
      (repo) => repo.verifyDeliveryReceiver(widget.order.id, signature),
      'Receiver signature captured.',
    );
  }

  Future<void> _confirmGiveUp({required bool isPickupLeg}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Give up this order?'),
        content: const Text(
          'It returns to the available pool for another rider to claim.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Give up',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(liveLocationSharingProvider.notifier).stop(widget.order.id);
    await _run(
      (repo) => isPickupLeg
          ? repo.unassignPickup(widget.order.id)
          : repo.unassignDelivery(widget.order.id),
      'Order given up.',
    );
  }

  Future<void> _toggleLocationSharing(bool value) async {
    final sharing = ref.read(liveLocationSharingProvider.notifier);
    if (!value) {
      sharing.stop(widget.order.id);
      return;
    }
    final error = await sharing.start(widget.order.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  _NextAction? _nextAction(Order order, bool isPickupLeg, bool isDeliveryLeg) {
    if (isDeliveryLeg &&
        (order.status == OrderStatus.atWarehouse ||
            order.status == OrderStatus.outForDelivery)) {
      return switch (order.status) {
        OrderStatus.atWarehouse => const _NextAction(
          OrderStatus.outForDelivery,
          'Out for delivery',
          'Mark out for delivery',
        ),
        OrderStatus.outForDelivery => const _NextAction(
          OrderStatus.deliveredPendingVerification,
          'Delivered',
          'Mark delivered',
        ),
        _ => null,
      };
    }

    if (isPickupLeg) {
      switch (order.status) {
        case OrderStatus.pending:
        case OrderStatus.confirmed:
          return const _NextAction(
            OrderStatus.pickedUp,
            'Picked up',
            'Mark picked up',
          );
        case OrderStatus.pickedUp:
          return const _NextAction(
            OrderStatus.inTransit,
            'In transit',
            'Mark in transit',
          );
        case OrderStatus.inTransit:
          return const _NextAction(
            OrderStatus.atWarehouse,
            'Arrived at warehouse',
            'Mark arrived at warehouse',
          );
        default:
          return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final myUserId = ref.watch(authControllerProvider).user?.id;
    final isPickupLeg = order.pickupRider?.id == myUserId;
    final isDeliveryLeg = order.deliveryRider?.id == myUserId;
    final isTerminal = _terminalStatuses.contains(order.status);
    final nextAction = _nextAction(order, isPickupLeg, isDeliveryLeg);
    final canGiveUpPickup =
        isPickupLeg &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed);
    final canGiveUpDelivery =
        isDeliveryLeg && order.status == OrderStatus.atWarehouse;
    // Same leg/status pairs the API shows to customers on the live map, and
    // only once an admin has approved this rider's claim.
    final canShareLocation =
        (isPickupLeg &&
            order.pickupRiderClaimRequestedAt == null &&
            _pickupShareStatuses.contains(order.status)) ||
        (isDeliveryLeg &&
            order.deliveryRiderClaimRequestedAt == null &&
            order.status == OrderStatus.outForDelivery);
    final isSharingLocation = ref
        .watch(liveLocationSharingProvider)
        .contains(order.id);
    if (isSharingLocation && !canShareLocation) {
      // The leg just ended (dropped at warehouse, delivered, cancelled…) —
      // stop broadcasting rather than leave the rider tracked for nothing.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(liveLocationSharingProvider.notifier).stop(order.id),
      );
    }
    final events = order.trackingEvents.reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              order.trackingNumber,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            OrderStatusChip(status: order.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${order.amount} ${order.currency} · ${order.distanceKm.toStringAsFixed(1)} km',
          style: TextStyle(color: context.colors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        _PaymentSummary(order: order),
        const SizedBox(height: 20),
        _AddressCard(
          icon: LucideIcons.store,
          label: 'Pickup',
          address: order.pickupLocation.addressLine,
        ),
        if (order.pickupLocation.landmark != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Landmark: ${order.pickupLocation.landmark}',
              style: TextStyle(fontSize: 12, color: context.colors.textMuted),
            ),
          ),
        const SizedBox(height: 10),
        _AddressCard(
          icon: LucideIcons.mapPin,
          label: 'Delivery to ${order.receiverName}',
          address: order.deliveryLocation.addressLine,
        ),
        if (isPickupLeg || isDeliveryLeg) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openNavigation(
                isPickupLeg
                    ? order.pickupLocation
                    : order.deliveryLocation,
              ),
              icon: const Icon(LucideIcons.navigation),
              label: const Text('Navigate'),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _AddressCard(
          icon: LucideIcons.userRound,
          label: 'Sender',
          address:
              '${order.senderName ?? order.senderShopName ?? 'Sender'} · ${order.senderPhoneNumber}',
        ),
        const SizedBox(height: 10),
        _AddressCard(
          icon: LucideIcons.userRound,
          label: 'Receiver',
          address: '${order.receiverName} · ${order.receiverPhoneNumber}',
        ),
        const SizedBox(height: 24),
        Text('Packages', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...order.packages.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.package,
                      size: 16,
                      color: context.colors.textMuted,
                    ),

                    const SizedBox(width: 8),
                    Expanded(child: Text(p.name)),
                    Text(
                      '${p.weightKg} kg',
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: PackageFlagsRow(package: p),
                ),
              ],
            ),
          ),
        ),
        if (canShareLocation) ...[
          const SizedBox(height: 24),
          Text(
            'Location sharing',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.colors.cardAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isSharingLocation,
              onChanged: _toggleLocationSharing,
              title: const Text(
                'Share my live location',
                style: TextStyle(fontSize: 13.5),
              ),
              subtitle: Text(
                isSharingLocation
                    ? 'The sender and receiver can see you on a live map. Keeps running if you leave this screen.'
                    : 'Lets the sender and receiver follow you on a live map until this leg is done',
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (nextAction != null)
          _SwipeActionButton(
            label: nextAction.label,
            enabled: !_acting,
            onComplete: () => _performNextAction(nextAction),
          ),
        if (nextAction != null) const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (isDeliveryLeg && order.codAmount != null && !isTerminal)
              _ActionButton(
                label: 'Collect COD amount',
                enabled: !_acting,
                onPressed: () => _run(
                  (repo) => repo.collectCodAmount(order.id),
                  'COD amount recorded as collected.',
                ),
              ),
            if ((isPickupLeg || isDeliveryLeg) && !isTerminal)
              _ActionButton(
                label: 'Report failed delivery',
                enabled: !_acting,
                destructive: true,
                onPressed: _confirmFailedDelivery,
              ),
            if (isDeliveryLeg &&
                order.status == OrderStatus.deliveredPendingVerification)
              if (order.receiverVerifiedAt == null)
                _ActionButton(
                  label: 'Capture receiver signature',
                  enabled: !_acting,
                  onPressed: _captureReceiverSignature,
                )
              else
                const Chip(label: Text('Receiver signature captured')),
            if (canGiveUpPickup)
              _ActionButton(
                label: 'Give up this order',
                enabled: !_acting,
                destructive: true,
                onPressed: () => _confirmGiveUp(isPickupLeg: true),
              ),
            if (canGiveUpDelivery)
              _ActionButton(
                label: 'Give up this order',
                enabled: !_acting,
                destructive: true,
                onPressed: () => _confirmGiveUp(isPickupLeg: false),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...events.asMap().entries.map(
          (entry) => _TimelineTile(
            event: entry.value,
            isLast: entry.key == events.length - 1,
            isCurrent: entry.key == 0,
          ),
        ),
      ],
    );
  }
}

class _SwipeActionButton extends StatefulWidget {
  const _SwipeActionButton({
    required this.label,
    required this.enabled,
    required this.onComplete,
  });

  final String label;
  final bool enabled;
  final Future<void> Function() onComplete;

  @override
  State<_SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<_SwipeActionButton> {
  double _dragProgress = 0;
  bool _completed = false;

  Future<void> _complete() async {
    if (_completed || !widget.enabled) return;
    setState(() {
      _completed = true;
      _dragProgress = 1;
    });
    await widget.onComplete();
    if (!mounted) return;
    setState(() {
      _completed = false;
      _dragProgress = 0;
    });
  }

  void _updateDrag(DragUpdateDetails details, double width) {
    if (_completed || !widget.enabled) return;
    const thumbSize = 52.0;
    final travel = width - thumbSize - 8;
    setState(() {
      _dragProgress = (_dragProgress + details.delta.dx / travel).clamp(0, 1);
    });
  }

  void _endDrag() {
    if (_completed || !widget.enabled) return;
    if (_dragProgress >= 0.82) {
      _complete();
    } else {
      setState(() => _dragProgress = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbOffset = _dragProgress * (width - 60);
        return GestureDetector(
          onHorizontalDragUpdate: (details) => _updateDrag(details, width),
          onHorizontalDragEnd: (_) => _endDrag(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 60,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.enabled
                  ? AppColors.primary
                  : context.colors.cardAlt,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: widget.enabled
                    ? AppColors.primary
                    : context.colors.border,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    _completed ? 'Updating...' : widget.label,
                    style: TextStyle(
                      color: widget.enabled
                          ? AppColors.onPrimary
                          : context.colors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  left: thumbOffset,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: context.colors.card,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.shadowStrong,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _completed
                          ? LucideIcons.loaderCircle
                          : LucideIcons.chevronsRight,
                      color: widget.enabled
                          ? AppColors.onPrimary
                          : context.colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SignatureCaptureDialog extends StatefulWidget {
  const _SignatureCaptureDialog();

  @override
  State<_SignatureCaptureDialog> createState() =>
      _SignatureCaptureDialogState();
}

class _SignatureCaptureDialogState extends State<_SignatureCaptureDialog> {
  final _boundaryKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  String? _error;

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      setState(() => _error = 'Ask the receiver to sign before continuing.');
      return;
    }

    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) throw StateError('Could not encode the signature.');

      final signature =
          'data:image/png;base64,${base64Encode(byteData.buffer.asUint8List())}';
      if (signature.length > 1900000) {
        throw StateError('Signature image is too large. Please sign again.');
      }
      if (mounted) Navigator.of(context).pop(signature);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width - 32;
    final dialogHeight = size.height - 48;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: dialogHeight),
        child: SizedBox(
          width: dialogWidth > 720 ? 720 : dialogWidth,
          height: dialogHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receiver confirmation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ask the receiver to sign below to confirm receipt.',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) => setState(() {
                          _error = null;
                          _strokes.add([details.localPosition]);
                        }),
                        onPanUpdate: (details) => setState(
                          () => _strokes.last.add(details.localPosition),
                        ),
                        child: CustomPaint(
                          painter: _SignaturePainter(_strokes),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _strokes.clear();
                        _error = null;
                      }),
                      child: const Text('Clear'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Confirm receipt'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: destructive ? AppColors.danger : null,
        side: destructive ? const BorderSide(color: AppColors.danger) : null,
      ),
      child: Text(label),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final method = paymentMethodDisplayFor(order.paymentMethod);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PaymentPill(icon: method.icon, label: method.label),
        _PaymentPill(
          icon: LucideIcons.userRound,
          label: orderPayerLabel(order.payer),
        ),
        if (order.codAmount != null)
          _PaymentPill(
            icon: LucideIcons.banknote,
            label: 'Collect ${order.codAmount} ${order.currency}',
          ),
      ],
    );
  }
}

class _PaymentPill extends StatelessWidget {
  const _PaymentPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.cardAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.colors.text),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: context.colors.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.icon,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.colors.text),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(address, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isLast,
    required this.isCurrent,
  });

  final OrderTrackingEvent event;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final display = statusDisplayFor(event.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? display.color.withValues(alpha: 0.16)
                      : context.colors.cardAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  display.icon,
                  size: 15,
                  color: isCurrent ? display.color : context.colors.textMuted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: context.colors.border),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.description!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('MMM d, h:mm a').format(event.createdAt),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
