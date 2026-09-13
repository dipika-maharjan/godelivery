/// Request-side location payload, matching `LocationInputDto`.
class LocationInput {
  const LocationInput({
    this.label,
    required this.addressLine,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.formattedAddress,
  });

  final String? label;
  final String addressLine;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? formattedAddress;

  Map<String, dynamic> toJson() {
    return {
      if (label != null) 'label': label,
      'addressLine': addressLine,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (postalCode != null) 'postalCode': postalCode,
      if (country != null) 'country': country,
      'latitude': latitude,
      'longitude': longitude,
      if (placeId != null) 'placeId': placeId,
      if (formattedAddress != null) 'formattedAddress': formattedAddress,
    };
  }
}

/// Response-side location, matching `LocationResponseDto`.
class LocationResponse {
  const LocationResponse({
    required this.id,
    this.label,
    required this.addressLine,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      id: json['id'] as String,
      label: json['label'] as String?,
      addressLine: json['addressLine'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  final String id;
  final String? label;
  final String addressLine;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final double latitude;
  final double longitude;
}
