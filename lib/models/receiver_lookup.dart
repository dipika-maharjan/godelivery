import 'location.dart';

class ReceiverOrderHistoryItem {
  const ReceiverOrderHistoryItem({
    required this.trackingNumber,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  factory ReceiverOrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReceiverOrderHistoryItem(
      trackingNumber: json['trackingNumber'] as String,
      status: json['status'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String trackingNumber;
  final String status;
  final String amount;
  final String currency;
  final DateTime createdAt;
}

class ReceiverLookupResult {
  const ReceiverLookupResult({
    required this.exists,
    this.id,
    this.name,
    this.phoneNumber,
    this.email,
    this.lastLocation,
    this.recentOrders = const [],
  });

  factory ReceiverLookupResult.fromJson(Map<String, dynamic> json) {
    return ReceiverLookupResult(
      exists: json['exists'] as bool,
      id: json['id'] as String?,
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      lastLocation: json['lastLocation'] == null
          ? null
          : LocationResponse.fromJson(
              json['lastLocation'] as Map<String, dynamic>,
            ),
      recentOrders: json['recentOrders'] == null
          ? const []
          : (json['recentOrders'] as List)
                .map(
                  (e) => ReceiverOrderHistoryItem.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
    );
  }

  final bool exists;
  final String? id;
  final String? name;
  final String? phoneNumber;
  final String? email;
  final LocationResponse? lastLocation;
  final List<ReceiverOrderHistoryItem> recentOrders;
}
