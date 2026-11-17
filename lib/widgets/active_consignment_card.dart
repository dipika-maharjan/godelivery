import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_theme.dart';
import '../models/order.dart';
import 'order_status_chip.dart';

const activeConsignmentStatuses = {
  OrderStatus.confirmed,
  OrderStatus.pickedUp,
  OrderStatus.inTransit,
  OrderStatus.atWarehouse,
  OrderStatus.outForDelivery,
  OrderStatus.deliveredPendingVerification,
};

class ActiveConsignmentCard extends StatelessWidget {
  const ActiveConsignmentCard({
    super.key,
    required this.order,
    required this.subtitle,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
    this.onLongPress,
  });

  final Order order;
  final String subtitle;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectionChanged;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 2, 0, 12),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.65),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadowSoft,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: selectionMode
            ? onSelectionChanged
            : () => context.push(
                _isRider(context)
                    ? '/rider/orders/${order.id}'
                    : '/orders/${order.id}',
              ),
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (selectionMode) ...[
                Checkbox(
                  value: selected,
                  onChanged: onSelectionChanged == null
                      ? null
                      : (_) => onSelectionChanged!(),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.packageOpen,
                  size: 22,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.trackingNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${order.amount} ${order.currency}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RouteLine(
                      icon: LucideIcons.circle,
                      label: order.pickupLocation.addressLine,
                    ),
                    const SizedBox(height: 7),
                    _RouteLine(
                      icon: LucideIcons.mapPin,
                      label: order.deliveryLocation.addressLine,
                    ),
                    const SizedBox(height: 8),
                    OrderStatusChip(status: order.status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isRider(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return location.startsWith('/rider');
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: context.colors.textMuted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.25,
              color: context.colors.text,
            ),
          ),
        ),
      ],
    );
  }
}
