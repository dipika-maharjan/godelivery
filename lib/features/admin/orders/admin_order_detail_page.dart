import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/payment_display.dart';
import '../../../core/utils/status_display.dart';
import '../../../data/order_repository.dart';
import '../../../models/order.dart';
import '../../../models/rider.dart';
import '../../../providers/admin_orders_provider.dart';
import '../../../providers/admin_riders_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/order_status_chip.dart';
import '../../../widgets/package_flags_row.dart';
import '../../../widgets/pdf_viewer_page.dart';
import '../../../widgets/sheet_header.dart';

const _terminalStatuses = {
  OrderStatus.delivered,
  OrderStatus.failedDelivery,
  OrderStatus.cancelled,
  OrderStatus.returned,
};

class AdminOrderDetailPage extends ConsumerWidget {
  const AdminOrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            error is ApiException ? error.message : 'Something went wrong.',
          ),
        ),
        data: (value) => _AdminOrderDetailBody(order: value),
      ),
    );
  }
}

class _AdminOrderDetailBody extends ConsumerStatefulWidget {
  const _AdminOrderDetailBody({required this.order});

  final Order order;

  @override
  ConsumerState<_AdminOrderDetailBody> createState() =>
      _AdminOrderDetailBodyState();
}

class _AdminOrderDetailBodyState extends ConsumerState<_AdminOrderDetailBody> {
  bool _acting = false;

  Future<void> _run(
    Future<Order> Function(OrderRepository repo) action,
    String successMessage,
  ) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await action(ref.read(orderRepositoryProvider));
      ref.invalidate(orderDetailProvider(widget.order.id));
      ref.invalidate(adminOrdersProvider);
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

  Future<void> _assignPickup() async {
    final riderId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RiderPickerSheet(),
    );
    if (riderId == null) return;
    await _run(
      (repo) => repo.assignPickupRider(widget.order.id, riderId),
      'Pickup rider assigned.',
    );
  }

  Future<void> _assignDelivery() async {
    final riderId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RiderPickerSheet(),
    );
    if (riderId == null) return;
    await _run(
      (repo) => repo.assignDeliveryRider(widget.order.id, riderId),
      'Delivery rider assigned.',
    );
  }

  Future<void> _updateStatus() async {
    final result = await showModalBottomSheet<_StatusUpdate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _UpdateStatusSheet(),
    );
    if (result == null) return;
    await _run(
      (repo) => repo.updateStatus(
        widget.order.id,
        status: result.status,
        title: result.title,
        description: result.description,
      ),
      'Status updated.',
    );
  }

  Future<void> _confirmAdminCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'This cancels the order at its current stage and notifies any assigned riders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run((repo) => repo.adminCancel(widget.order.id), 'Order cancelled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final events = order.trackingEvents.reversed.toList();
    final isTerminal = _terminalStatuses.contains(order.status);

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
        if (order.pickupRider != null) ...[
          const SizedBox(height: 10),
          _AddressCard(
            icon: LucideIcons.bike,
            label: order.pickupRiderClaimRequestedAt != null
                ? 'Pickup rider (self-claim pending)'
                : 'Pickup rider',
            address:
                '${order.pickupRider!.name} · ${order.pickupRider!.phoneNumber}',
          ),
        ],
        const SizedBox(height: 10),
        _AddressCard(
          icon: LucideIcons.mapPin,
          label: 'Delivery to ${order.receiverName}',
          address: order.deliveryLocation.addressLine,
        ),
        if (order.warehouse != null) ...[
          const SizedBox(height: 10),
          _AddressCard(
            icon: LucideIcons.warehouse,
            label: order.warehouseArrivedAt != null
                ? 'At warehouse'
                : 'Routed via warehouse',
            address: order.warehouse!.name,
          ),
        ],
        if (order.deliveryRider != null) ...[
          const SizedBox(height: 10),
          _AddressCard(
            icon: LucideIcons.bike,
            label: order.deliveryRiderClaimRequestedAt != null
                ? 'Delivery rider (self-claim pending)'
                : 'Delivery rider',
            address:
                '${order.deliveryRider!.name} · ${order.deliveryRider!.phoneNumber}',
          ),
        ],
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
        const SizedBox(height: 24),
        Text('Admin actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionButton(
              label: 'Print shipping label',
              enabled: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PdfViewerPage(
                    title: 'Shipping label',
                    fileName: '${order.trackingNumber}-label.pdf',
                    loadBytes: () =>
                        ref.read(orderRepositoryProvider).getLabelPdf(order.id),
                  ),
                ),
              ),
            ),
            if (order.pickupRiderClaimRequestedAt != null) ...[
              _ActionButton(
                label: 'Approve pickup claim',
                enabled: !_acting,
                onPressed: () => _run(
                  (repo) => repo.approvePickupRider(order.id),
                  'Pickup claim approved.',
                ),
              ),
              _ActionButton(
                label: 'Reject pickup claim',
                enabled: !_acting,
                destructive: true,
                onPressed: () => _run(
                  (repo) => repo.rejectPickupRider(order.id),
                  'Pickup claim rejected.',
                ),
              ),
            ] else if (order.pickupRiderAssignedAt == null && !isTerminal)
              _ActionButton(
                label: 'Assign pickup rider',
                enabled: !_acting,
                onPressed: _assignPickup,
              )
            else if (order.pickupRiderAssignedAt != null && !isTerminal)
              _ActionButton(
                label: 'Unassign pickup',
                enabled: !_acting,
                destructive: true,
                onPressed: () => _run(
                  (repo) => repo.unassignPickup(order.id),
                  'Pickup unassigned.',
                ),
              ),
            if (order.status == OrderStatus.atWarehouse) ...[
              if (order.deliveryRiderClaimRequestedAt != null) ...[
                _ActionButton(
                  label: 'Approve delivery claim',
                  enabled: !_acting,
                  onPressed: () => _run(
                    (repo) => repo.approveDeliveryRider(order.id),
                    'Delivery claim approved.',
                  ),
                ),
                _ActionButton(
                  label: 'Reject delivery claim',
                  enabled: !_acting,
                  destructive: true,
                  onPressed: () => _run(
                    (repo) => repo.rejectDeliveryRider(order.id),
                    'Delivery claim rejected.',
                  ),
                ),
              ] else if (order.deliveryRiderAssignedAt == null)
                _ActionButton(
                  label: 'Assign delivery rider',
                  enabled: !_acting,
                  onPressed: _assignDelivery,
                ),
            ],
            if (order.deliveryRiderAssignedAt != null && !isTerminal)
              _ActionButton(
                label: 'Unassign delivery',
                enabled: !_acting,
                destructive: true,
                onPressed: () => _run(
                  (repo) => repo.unassignDelivery(order.id),
                  'Delivery unassigned.',
                ),
              ),
            if (order.codAmount != null)
              _ActionButton(
                label: 'Collect COD amount',
                enabled: !_acting,
                onPressed: () => _run(
                  (repo) => repo.collectCodAmount(order.id),
                  'COD amount recorded as collected.',
                ),
              ),
            if (order.status == OrderStatus.deliveredPendingVerification)
              _ActionButton(
                label: 'Verify delivery',
                enabled: !_acting,
                onPressed: () => _run(
                  (repo) => repo.verifyDeliveryAdmin(order.id),
                  'Delivery verified.',
                ),
              ),
            if (!isTerminal)
              _ActionButton(
                label: 'Update status',
                enabled: !_acting,
                onPressed: _updateStatus,
              ),
            if (!isTerminal)
              _ActionButton(
                label: 'Cancel order',
                enabled: !_acting,
                destructive: true,
                onPressed: _confirmAdminCancel,
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

class _RiderPickerSheet extends ConsumerStatefulWidget {
  const _RiderPickerSheet();

  @override
  ConsumerState<_RiderPickerSheet> createState() => _RiderPickerSheetState();
}

class _RiderPickerSheetState extends ConsumerState<_RiderPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riders = ref.watch(adminRidersProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Choose a rider'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _searchController,
              hint: 'Search by name or phone',
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: riders.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Could not load riders.')),
                ),
                data: (list) {
                  final activeRiders = list.where((r) => r.isActive).toList();
                  final filtered = _query.isEmpty
                      ? activeRiders
                      : activeRiders
                          .where(
                            (r) =>
                                r.name.toLowerCase().contains(_query) ||
                                r.phoneNumber.contains(_query),
                          )
                          .toList();
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No riders found.')),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final rider = filtered[index];
                      return ListTile(
                        leading: Icon(
                          rider.isAvailable
                              ? LucideIcons.circleCheck
                              : LucideIcons.circle,
                          size: 18,
                          color: rider.isAvailable
                              ? AppColors.success
                              : context.colors.textMuted,
                        ),
                        title: Text(rider.name),
                        subtitle: Text(
                          '${vehicleTypeLabel(rider.vehicleType)} · ${rider.phoneNumber}',
                        ),
                        onTap: () => Navigator.of(context).pop(rider.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusUpdate {
  const _StatusUpdate({
    required this.status,
    required this.title,
    this.description,
  });

  final OrderStatus status;
  final String title;
  final String? description;
}

const _adminSettableStatuses = [
  OrderStatus.pending,
  OrderStatus.confirmed,
  OrderStatus.pickedUp,
  OrderStatus.inTransit,
  OrderStatus.atWarehouse,
  OrderStatus.outForDelivery,
  OrderStatus.deliveredPendingVerification,
  OrderStatus.failedDelivery,
  OrderStatus.cancelled,
  OrderStatus.returned,
];

class _UpdateStatusSheet extends StatefulWidget {
  const _UpdateStatusSheet();

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  OrderStatus _status = OrderStatus.confirmed;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Update status'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in _adminSettableStatuses)
                  _StatusOption(
                    status: status,
                    selected: _status == status,
                    onTap: () => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'e.g. Out for delivery',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              hint: 'Extra context for the tracking timeline',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _titleController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                          _StatusUpdate(
                            status: _status,
                            title: _titleController.text.trim(),
                            description: _descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim(),
                          ),
                        ),
                child: const Text('Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final OrderStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = statusDisplayFor(status);
    final color = selected ? AppColors.onPrimary : context.colors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.colors.cardAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(display.icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              display.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
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
        if (order.codAmount != null)
          _PaymentPill(
            icon: LucideIcons.banknote,
            label: 'Collect ${order.codAmount} ${order.currency}',
            color: context.colors.text,
            background: context.colors.cardAlt,
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
            style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
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
