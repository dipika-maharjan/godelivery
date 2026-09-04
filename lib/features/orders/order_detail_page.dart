import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/payment_display.dart';
import '../../core/utils/status_display.dart';
import '../../data/order_repository.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/order_status_chip.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Shipment')),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            error is ApiException ? error.message : 'Something went wrong.',
          ),
        ),
        data: (value) => _OrderDetailBody(order: value),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  const _OrderDetailBody({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  bool _cancelling = false;

  bool _canCancel(String? currentUserId) =>
      widget.order.senderId == currentUserId &&
      (widget.order.status == OrderStatus.pending ||
          widget.order.status == OrderStatus.confirmed);

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(orderRepositoryProvider).cancel(widget.order.id);
      ref.invalidate(orderDetailProvider(widget.order.id));
      ref.invalidate(ordersProvider(OrderRoleFilter.sent));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shipment cancelled.')));
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not cancel the shipment.';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final events = order.trackingEvents.reversed.toList();
    final currentUserId = ref.watch(authControllerProvider).user?.id;

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
          icon: LucideIcons.userRound,
          label: 'Sender',
          address:
              '${order.senderName ?? order.senderShopName ?? 'Sender'} · ${order.senderPhoneNumber}',
        ),
        const SizedBox(height: 10),
        _AddressCard(
          icon: LucideIcons.store,
          label: 'Pickup',
          address: order.pickupLocation.addressLine,
        ),
        const SizedBox(height: 10),
        _AddressCard(
          icon: LucideIcons.mapPin,
          label: 'Delivery to ${order.receiverName}',
          address: order.deliveryLocation.addressLine,
        ),
        if (order.rider != null) ...[
          const SizedBox(height: 10),
          _AddressCard(
            icon: LucideIcons.bike,
            label: 'Rider',
            address: '${order.rider!.name} · ${order.rider!.phoneNumber}',
          ),
        ],
        const SizedBox(height: 24),
        Text('Packages', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...order.packages.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
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
          ),
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
        if (_canCancel(currentUserId)) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _cancelling ? null : _cancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_cancelling ? 'Cancelling…' : 'Cancel shipment'),
          ),
        ],
      ],
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final method = paymentMethodDisplayFor(order.paymentMethod);
    final status = paymentStatusDisplayFor(order.paymentStatus);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PaymentPill(
          icon: method.icon,
          label: method.label,
          color: context.colors.text,
          background: context.colors.cardAlt,
        ),
        _PaymentPill(
          icon: LucideIcons.userRound,
          label: orderPayerLabel(order.payer),
          color: context.colors.text,
          background: context.colors.cardAlt,
        ),
        _PaymentPill(
          icon: LucideIcons.circle,
          label: status.label,
          color: status.color,
          background: status.color.withValues(alpha: 0.12),
        ),
      ],
    );
  }
}

class _PaymentPill extends StatelessWidget {
  const _PaymentPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
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
