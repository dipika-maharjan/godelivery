class Coordinates {
  const Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude};
}

class EstimateRequest {
  const EstimateRequest({
    required this.pickup,
    required this.delivery,
    required this.totalWeightKg,
    this.hasDangerousGoods = false,
  });

  final Coordinates pickup;
  final Coordinates delivery;
  final double totalWeightKg;
  final bool hasDangerousGoods;

  Map<String, dynamic> toJson() => {
    'pickup': pickup.toJson(),
    'delivery': delivery.toJson(),
    'totalWeightKg': totalWeightKg,
    'hasDangerousGoods': hasDangerousGoods,
  };
}

class EstimateResult {
  const EstimateResult({
    required this.amount,
    required this.currency,
    required this.distanceKm,
  });

  factory EstimateResult.fromJson(Map<String, dynamic> json) {
    return EstimateResult(
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
    );
  }

  final String amount;
  final String currency;
  final double distanceKm;
}
