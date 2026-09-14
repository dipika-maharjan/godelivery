import 'package:shared_preferences/shared_preferences.dart';

/// Local, best-effort monthly usage counters per map provider. There's no
/// server-side quota API for Baato/Galli, so this is only ever an estimate
/// of how many map sessions this device has opened this month.
///
/// Used by [MapProviderResolver] (`lib/core/maps/map_provider_resolver.dart`),
/// which is invoked from static picker methods off a `BuildContext` rather
/// than from widgets with a `WidgetRef` — so this stays a plain class
/// instead of a riverpod provider.
class MapUsageStorage {
  MapUsageStorage._();

  static final _prefs = SharedPreferencesAsync();

  static String _key(String provider) {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return 'godelivery.mapUsage.$provider.${now.year}-$month';
  }

  static Future<int> count(String provider) async {
    return (await _prefs.getInt(_key(provider))) ?? 0;
  }

  static Future<void> increment(String provider) async {
    final key = _key(provider);
    final current = (await _prefs.getInt(key)) ?? 0;
    await _prefs.setInt(key, current + 1);
  }
}
