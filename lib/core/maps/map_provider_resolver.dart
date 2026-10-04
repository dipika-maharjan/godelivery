import '../config/app_config.dart';
import '../storage/map_usage_storage.dart';

enum MapProviderKind { baato, galli, osm }

/// Decides which map SDK a location picker/preview should use this session,
/// and records usage against the local monthly counters that decision is
/// based on. Baato is primary; once its counter reaches
/// [AppConfig.baatomapsMonthlyLimit] for the current month, Galli takes
/// over; once Galli's counter reaches [AppConfig.gallimapsMonthlyLimit] too,
/// OpenStreetMap (uncapped) is used.
class MapProviderResolver {
  MapProviderResolver._();

  static const _baatoKey = 'baato';
  static const _galliKey = 'galli';

  static Future<MapProviderKind> resolveActiveProvider() async {
    final baatoCount = await MapUsageStorage.count(_baatoKey);
    if (baatoCount < AppConfig.baatomapsMonthlyLimit) {
      return MapProviderKind.baato;
    }
    final galliCount = await MapUsageStorage.count(_galliKey);
    if (galliCount < AppConfig.gallimapsMonthlyLimit) {
      return MapProviderKind.galli;
    }
    return MapProviderKind.osm;
  }

  /// Records one "map session" against [provider]'s monthly counter. Call
  /// once per deliberate picker open — not on every preview rebuild.
  static Future<void> recordUse(MapProviderKind provider) async {
    switch (provider) {
      case MapProviderKind.baato:
        await MapUsageStorage.increment(_baatoKey);
      case MapProviderKind.galli:
        await MapUsageStorage.increment(_galliKey);
      case MapProviderKind.osm:
        break; // Uncapped — nothing to track.
    }
  }
}
