/// A pickup address saved to the sender's address book, matching
/// `SavedLocationResponseDto`.
class SavedLocation {
  const SavedLocation({
    required this.id,
    this.label,
    required this.addressLine,
    this.landmark,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String,
      label: json['label'] as String?,
      addressLine: json['addressLine'] as String,
      landmark: json['landmark'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isDefault: json['isDefault'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String? label;
  final String addressLine;
  final String? landmark;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime createdAt;
}
