/// Central place for environment-ish configuration.
class AppConfig {
  AppConfig._();

  /// NOTE: `localhost` only resolves to the host machine on iOS simulators
  /// and desktop/web. On an Android emulator, use `http://10.0.2.2:3000`
  /// instead; on a physical device, use your machine's LAN IP.
  // static const String baseUrl = 'https://zsljfc89-3000.inc1.devtunnels.ms';
  //   static const String baseUrl = 'https://api.godelivery.godokan.com';
  static const String baseUrl = 'http://192.168.101.8:3000';
  // static const String baseUrl = 'https://xw4p2nm8-3000.inc1.devtunnels.ms/';
  // static const String baseUrl = 'https://192.168.101.14';
  // static const String baseUrl = 'http://localhost:3000';

  static const String baatomapsApiKey =
      'bpk.YdZs7urbXkXFjpz47tbJE3OjmDG1dKlCIOH8q4nrpk02'; //5000 monthly limit
  static const int baatomapsMonthlyLimit = 5000;

  static const String gallimapsApiKey =
      'c45ae985-cfbe-435b-8260-4851b02e6b21'; //10000 monthly limit
  static const int gallimapsMonthlyLimit = 10000;
}
