import 'package:latlong2/latlong.dart';

import 'rider.dart';

/// Where the rider on an order's current leg is right now, matching
/// `OrderLiveLocationResponseDto`. Only populated while that rider is
/// sharing their location for the order — [sharing] false means there's
/// nothing to show.
class OrderLiveLocation {
  const OrderLiveLocation({
    required this.sharing,
    this.isLive = false,
    this.isDeliveryLeg = false,
    this.position,
    this.heading,
    this.speedKmh,
    this.recordedAt,
    this.riderName,
    this.vehicleType,
    this.vehiclePlateNumber,
    this.destination,
    this.destinationLabel,
    this.trail = const [],
  });

  factory OrderLiveLocation.fromJson(Map<String, dynamic> json) {
    final sharing = json['sharing'] as bool? ?? false;
    if (!sharing) return const OrderLiveLocation(sharing: false);

    final rider = json['rider'] as Map<String, dynamic>?;
    final destination = json['destination'] as Map<String, dynamic>?;
    return OrderLiveLocation(
      sharing: true,
      isLive: json['isLive'] as bool? ?? false,
      isDeliveryLeg: json['leg'] == 'DELIVERY',
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      heading: (json['heading'] as num?)?.toDouble(),
      speedKmh: (json['speedKmh'] as num?)?.toDouble(),
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : null,
      riderName: rider?['name'] as String?,
      vehicleType: rider?['vehicleType'] != null
          ? vehicleTypeFromJson(rider!['vehicleType'] as String)
          : null,
      vehiclePlateNumber: rider?['vehiclePlateNumber'] as String?,
      destination: destination != null
          ? LatLng(
              (destination['latitude'] as num).toDouble(),
              (destination['longitude'] as num).toDouble(),
            )
          : null,
      destinationLabel: destination?['label'] as String?,
      trail: ((json['trail'] as List?) ?? const [])
          .map((p) {
            final point = p as Map<String, dynamic>;
            return LatLng(
              (point['latitude'] as num).toDouble(),
              (point['longitude'] as num).toDouble(),
            );
          })
          .toList(),
    );
  }

  final bool sharing;

  /// True while the latest ping is fresh; false means last-known position.
  final bool isLive;
  final bool isDeliveryLeg;
  final LatLng? position;

  /// Compass heading in degrees, when the device reported one.
  final double? heading;
  final double? speedKmh;
  final DateTime? recordedAt;
  final String? riderName;
  final VehicleType? vehicleType;
  final String? vehiclePlateNumber;

  /// Where the rider is heading on this leg. Never set on public tracking.
  final LatLng? destination;
  final String? destinationLabel;

  /// Recent path for this order, oldest first.
  final List<LatLng> trail;
}
