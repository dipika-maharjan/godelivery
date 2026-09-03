/// Central place for environment-ish configuration.
class AppConfig {
  AppConfig._();

  /// NOTE: `localhost` only resolves to the host machine on iOS simulators
  /// and desktop/web. On an Android emulator, use `http://10.0.2.2:3000`
  /// instead; on a physical device, use your machine's LAN IP.
  static const String baseUrl = 'http://localhost:3000';
  static const String galliMapsAccessToken =
      'c45ae985-cfbe-435b-8260-4851b02e6b21';
}
