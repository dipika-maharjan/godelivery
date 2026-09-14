/// A pricing formula version, matching `PricingRuleResponseDto`. Money
/// fields stay `String` as delivered by the API (same convention as
/// `Order.amount`/`codAmount`).
class PricingRule {
  const PricingRule({
    required this.id,
    required this.name,
    required this.baseFare,
    required this.ratePerKg,
    required this.ratePerKm,
    required this.dangerousGoodsSurcharge,
    required this.minCharge,
    required this.currency,
    required this.isActive,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PricingRule.fromJson(Map<String, dynamic> json) {
    return PricingRule(
      id: json['id'] as String,
      name: json['name'] as String,
      baseFare: json['baseFare'] as String,
      ratePerKg: json['ratePerKg'] as String,
      ratePerKm: json['ratePerKm'] as String,
      dangerousGoodsSurcharge: json['dangerousGoodsSurcharge'] as String,
      minCharge: json['minCharge'] as String,
      currency: json['currency'] as String,
      isActive: json['isActive'] as bool,
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      effectiveTo: json['effectiveTo'] == null
          ? null
          : DateTime.parse(json['effectiveTo'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String name;
  final String baseFare;
  final String ratePerKg;
  final String ratePerKm;
  final String dangerousGoodsSurcharge;
  final String minCharge;
  final String currency;
  final bool isActive;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final DateTime createdAt;
  final DateTime updatedAt;
}
