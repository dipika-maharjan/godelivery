import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_theme.dart';
import '../models/order.dart';
import 'order_status_chip.dart';

class OrderListTile extends StatelessWidget {
  const OrderListTile({
    super.key,
    required this.order,
    required this.onTap,
    required this.counterpartyName,
    this.counterpartyLabel = 'To',
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
    this.onSelectionChanged,
  });

  final Order order;
  final VoidCallback onTap;
  final String counterpartyName;
  final String counterpartyLabel;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : context.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : context.colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (selectionMode) ...[
              if (onSelectionChanged != null)
                Checkbox(
                  value: selected,
                  onChanged: (_) => onSelectionChanged!(),
                  activeColor: AppColors.primary,
                )
              else
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.primary
                      : context.colors.textMuted,
                  size: 23,
                ),
              const SizedBox(width: 10),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.package,
                size: 20,
                color: context.colors.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.trackingNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$counterpartyLabel $counterpartyName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.deliveryType == DeliveryType.scheduled &&
                            order.scheduledPickupDate != null
                        ? '${deliveryTypeLabel(order.deliveryType)} · '
                              '${DateFormat('MMM d').format(order.scheduledPickupDate!)}'
                              '${order.pickupStartTime != null && order.pickupEndTime != null ? ' · ${order.pickupStartTime}–${order.pickupEndTime}' : ''}'
                        : '${deliveryTypeLabel(order.deliveryType)} · As soon as possible',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(order.createdAt),
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OrderStatusChip(status: order.status),
          ],
        ),
      ),
    );
  }
}
