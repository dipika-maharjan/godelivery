/// Geography constants for GoDelivery's current service area: the Kathmandu
/// valley, in Bagmati province.
class NepalGeo {
  NepalGeo._();

  static const double minLatitude = 27.55;
  static const double maxLatitude = 27.85;
  static const double minLongitude = 85.15;
  static const double maxLongitude = 85.55;

  /// Thamel-ish center of the valley, used as the default map camera target.
  static const (double, double) defaultMapCenter = (27.7172, 85.3240);

  static bool isWithinKathmanduValley(double latitude, double longitude) {
    return latitude >= minLatitude &&
        latitude <= maxLatitude &&
        longitude >= minLongitude &&
        longitude <= maxLongitude;
  }

  /// Cities GoDelivery currently serves, all within the Kathmandu valley.
  static const List<String> kathmanduValleyCities = [
    'Kathmandu',
    'Lalitpur',
    'Bhaktapur',
  ];
  static const String defaultCity = 'Kathmandu';

  /// Nepal's 7 provinces. Only [defaultProvince] is enabled for selection
  /// today; the rest are listed (disabled) to signal future coverage.
  static const List<String> provinces = [
    'Koshi',
    'Madhesh',
    'Bagmati',
    'Gandaki',
    'Lumbini',
    'Karnali',
    'Sudurpashchim',
  ];
  static const String defaultProvince = 'Bagmati';

  static bool isProvinceEnabled(String province) => province == defaultProvince;
}
