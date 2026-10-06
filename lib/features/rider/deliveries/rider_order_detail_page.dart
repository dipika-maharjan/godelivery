import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/payment_display.dart';
import '../../../core/utils/status_display.dart';
import '../../../data/order_repository.dart';
import '../../../data/riders_repository.dart';
import '../../../models/order.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/rider_jobs_provider.dart';
import '../../../widgets/order_status_chip.dart';
import '../../../widgets/package_flags_row.dart';

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
          child: Text(error is ApiException ? error.message : 'Something went wrong.'),
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
  ConsumerState<_RiderOrderDetailBody> createState() => _RiderOrderDetailBodyState();
}

class _RiderOrderDetailBodyState extends ConsumerState<_RiderOrderDetailBody> {
  bool _acting = false;
  bool _sharingLocation = false;
  Timer? _locationTimer;

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      final message = e is ApiException ? e.message : 'Something went wrong.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        content: const Text('This records the delivery as failed for this order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Report failed', style: TextStyle(color: AppColors.danger)),
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
        content: const Text('It returns to the available pool for another rider to claim.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Give up', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _sharingLocation = false);
    _locationTimer?.cancel();
    await _run(
      (repo) => isPickupLeg
          ? repo.unassignPickup(widget.order.id)
          : repo.unassignDelivery(widget.order.id),
      'Order given up.',
    );
  }

  void _toggleLocationSharing(bool value) {
    setState(() => _sharingLocation = value);
    _locationTimer?.cancel();
    if (!value) return;
    _postLocationPing();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _postLocationPing(),
    );
  }

  Future<void> _postLocationPing() async {
    final position = await _tryGetPosition();
    if (position == null || !mounted) return;
    try {
      await ref.read(ridersRepositoryProvider).submitLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracyMeters: position.accuracy,
            speedKmh: position.speed * 3.6,
            heading: position.heading,
            orderId: widget.order.id,
          );
    } catch (_) {
      // A missed ping isn't worth interrupting the rider over — the next
      // periodic tick will try again.
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
          return const _NextAction(OrderStatus.pickedUp, 'Picked up', 'Mark picked up');
        case OrderStatus.pickedUp:
          return const _NextAction(OrderStatus.inTransit, 'In transit', 'Mark in transit');
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
        isPickupLeg && (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed);
    final canGiveUpDelivery = isDeliveryLeg && order.status == OrderStatus.atWarehouse;
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
                    Icon(LucideIcons.package, size: 16, color: context.colors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.name)),
                    Text(
                      '${p.weightKg} kg',
                      style: TextStyle(color: context.colors.textMuted, fontSize: 12.5),
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
        if ((isPickupLeg || isDeliveryLeg) && !isTerminal) ...[
          const SizedBox(height: 24),
          Text('Location sharing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.colors.cardAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sharingLocation,
              onChanged: _toggleLocationSharing,
              title: const Text('Share my live location', style: TextStyle(fontSize: 13.5)),
              subtitle: const Text(
                'Posts your GPS position every 30s while this screen is open',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (nextAction != null)
              FilledButton(
                onPressed: _acting ? null : () => _performNextAction(nextAction),
                child: Text(nextAction.label),
              ),
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

class _SignatureCaptureDialog extends StatefulWidget {
  const _SignatureCaptureDialog();

  @override
  State<_SignatureCaptureDialog> createState() => _SignatureCaptureDialogState();
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
          _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
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
    return AlertDialog(
      title: const Text('Receiver confirmation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ask the receiver to sign below to confirm receipt.'),
          const SizedBox(height: 12),
          RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              height: 170,
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
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
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
        FilledButton(onPressed: _save, child: const Text('Confirm receipt')),
      ],
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
        _PaymentPill(icon: LucideIcons.userRound, label: orderPayerLabel(order.payer)),
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
  const _AddressCard({required this.icon, required this.label, required this.address});

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
                  style: TextStyle(fontSize: 11.5, color: context.colors.textMuted),
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
  const _TimelineTile({required this.event, required this.isLast, required this.isCurrent});

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
                Expanded(child: Container(width: 2, color: context.colors.border)),
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
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.description!,
                      style: TextStyle(fontSize: 12.5, color: context.colors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('MMM d, h:mm a').format(event.createdAt),
                    style: TextStyle(fontSize: 11.5, color: context.colors.textMuted),
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
