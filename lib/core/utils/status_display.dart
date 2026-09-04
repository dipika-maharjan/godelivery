import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/order.dart';
import '../theme/app_theme.dart';

class StatusDisplay {
  const StatusDisplay(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

StatusDisplay statusDisplayFor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return const StatusDisplay('Pending', Colors.orange, LucideIcons.clock);
    case OrderStatus.confirmed:
      return const StatusDisplay(
        'Confirmed',
        Colors.blueGrey,
        LucideIcons.badgeCheck,
      );
    case OrderStatus.pickedUp:
      return const StatusDisplay(
        'Picked up',
        Colors.indigo,
        LucideIcons.packageCheck,
      );
    case OrderStatus.inTransit:
      return const StatusDisplay('In transit', Colors.blue, LucideIcons.truck);
    case OrderStatus.outForDelivery:
      return const StatusDisplay(
        'Out for delivery',
        Colors.deepPurple,
        LucideIcons.bike,
      );
    case OrderStatus.delivered:
      return const StatusDisplay(
        'Delivered',
        AppColors.success,
        LucideIcons.circleCheck,
      );
    case OrderStatus.failedDelivery:
      return const StatusDisplay(
        'Failed delivery',
        AppColors.danger,
        LucideIcons.circleAlert,
      );
    case OrderStatus.cancelled:
      return const StatusDisplay('Cancelled', Colors.grey, LucideIcons.circleX);
    case OrderStatus.returned:
      return const StatusDisplay('Returned', Colors.grey, LucideIcons.undo2);
  }
}
