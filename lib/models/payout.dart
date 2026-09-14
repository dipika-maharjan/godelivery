enum PayoutStatus { pending, paid, failed }

PayoutStatus payoutStatusFromJson(String value) => switch (value) {
  'PAID' => PayoutStatus.paid,
  'FAILED' => PayoutStatus.failed,
  _ => PayoutStatus.pending,
};

String payoutStatusToJson(PayoutStatus status) => switch (status) {
  PayoutStatus.pending => 'PENDING',
  PayoutStatus.paid => 'PAID',
  PayoutStatus.failed => 'FAILED',
};

class PayoutRider {
  const PayoutRider({required this.id, required this.name, required this.phoneNumber});

  factory PayoutRider.fromJson(Map<String, dynamic> json) {
    return PayoutRider(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }

  final String id;
  final String name;
  final String phoneNumber;
}

class PayoutProcessedBy {
  const PayoutProcessedBy({required this.id, required this.name});

  factory PayoutProcessedBy.fromJson(Map<String, dynamic> json) {
    return PayoutProcessedBy(id: json['id'] as String, name: json['name'] as String);
  }

  final String id;
  final String name;
}

class PayoutOrderLine {
  const PayoutOrderLine({
    required this.id,
    required this.trackingNumber,
    required this.amount,
  });

  factory PayoutOrderLine.fromJson(Map<String, dynamic> json) {
    return PayoutOrderLine(
      id: json['id'] as String,
      trackingNumber: json['trackingNumber'] as String,
      amount: json['amount'] as String,
    );
  }

  final String id;
  final String trackingNumber;
  final String amount;
}

/// A batch of a rider's delivered orders marked for reimbursement, matching
/// `PayoutResponseDto`. Record-keeping only — no bank transfer is triggered.
class Payout {
  const Payout({
    required this.id,
    required this.rider,
    required this.amount,
    required this.currency,
    required this.status,
    this.processedBy,
    this.paidAt,
    this.referenceNote,
    required this.orders,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      rider: PayoutRider.fromJson(json['rider'] as Map<String, dynamic>),
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      status: payoutStatusFromJson(json['status'] as String),
      processedBy: json['processedBy'] == null
          ? null
          : PayoutProcessedBy.fromJson(json['processedBy'] as Map<String, dynamic>),
      paidAt: json['paidAt'] == null ? null : DateTime.parse(json['paidAt'] as String),
      referenceNote: json['referenceNote'] as String?,
      orders: (json['orders'] as List)
          .map((e) => PayoutOrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final PayoutRider rider;
  final String amount;
  final String currency;
  final PayoutStatus status;
  final PayoutProcessedBy? processedBy;
  final DateTime? paidAt;
  final String? referenceNote;
  final List<PayoutOrderLine> orders;
  final DateTime createdAt;
  final DateTime updatedAt;
}
