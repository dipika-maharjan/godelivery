import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/order.dart';
import '../theme/app_theme.dart';

class PaymentMethodDisplay {
  const PaymentMethodDisplay(this.label, this.icon);

  final String label;
  final IconData icon;
}

PaymentMethodDisplay paymentMethodDisplayFor(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cod:
      return const PaymentMethodDisplay('Cash', LucideIcons.banknote);
    case PaymentMethod.bankTransfer:
      return const PaymentMethodDisplay('Bank transfer', LucideIcons.landmark);
    case PaymentMethod.esewa:
      return const PaymentMethodDisplay('eSewa', LucideIcons.wallet);
    case PaymentMethod.khalti:
      return const PaymentMethodDisplay('Khalti', LucideIcons.wallet);
    case PaymentMethod.fonepay:
      return const PaymentMethodDisplay('FonePay', LucideIcons.qrCode);
    case PaymentMethod.connectIps:
      return const PaymentMethodDisplay('ConnectIPS', LucideIcons.landmark);
  }
}

class PaymentStatusDisplay {
  const PaymentStatusDisplay(this.label, this.color);

  final String label;
  final Color color;
}

PaymentStatusDisplay paymentStatusDisplayFor(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid:
      return const PaymentStatusDisplay('Paid', AppColors.success);
    case PaymentStatus.failed:
      return const PaymentStatusDisplay('Payment failed', AppColors.danger);
    case PaymentStatus.pending:
      return const PaymentStatusDisplay('Payment pending', Colors.orange);
  }
}

String orderPayerLabel(OrderPayer payer) => switch (payer) {
  OrderPayer.sender => 'You pay',
  OrderPayer.receiver => 'Receiver pays',
};
