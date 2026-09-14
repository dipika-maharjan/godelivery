import 'package:dio/dio.dart';

import '../constants/nepal_geo.dart';

/// A search result from Photon: a coordinate plus a human-readable label.
typedef PhotonResult = ({double latitude, double longitude, String label});

/// Free, keyless search against Komoot's public Photon instance, biased to
/// the Kathmandu valley. Used as the secondary search fallback by every map
/// provider implementation, and as the primary search for the OSM path.
class PhotonSearch {
  PhotonSearch._();

  static Future<List<PhotonResult>> search(String query, {int limit = 6}) async {
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://photon.komoot.io/api/',
        queryParameters: {
          'q': '$query, Kathmandu, Nepal',
          'limit': limit,
          'lat': NepalGeo.defaultMapCenter.$1,
          'lon': NepalGeo.defaultMapCenter.$2,
        },
        options: Options(headers: {'User-Agent': 'GoDelivery/1.0'}),
      );
      final features = response.data?['features'];
      if (features is! List || features.isEmpty) return const [];
      return features.whereType<Map<String, dynamic>>().map((feature) {
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;
        final properties =
            feature['properties'] as Map<String, dynamic>? ?? {};
        final name = (properties['name'] ?? properties['street'] ?? query)
            .toString();
        final area =
            (properties['city'] ?? properties['district'] ?? 'Nepal')
                .toString();
        return (
          latitude: (coordinates[1] as num).toDouble(),
          longitude: (coordinates[0] as num).toDouble(),
          label: '$name, $area',
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}
