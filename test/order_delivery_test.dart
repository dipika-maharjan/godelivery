import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery/data/order_repository.dart';
import 'package:godelivery/models/order.dart';
import 'package:godelivery/models/pricing.dart';

void main() {
  group('delivery type serialization', () {
    test('maps all delivery types to backend enum values', () {
      expect(deliveryTypeToJson(DeliveryType.express), 'EXPRESS');
      expect(deliveryTypeToJson(DeliveryType.normal), 'NORMAL');
      expect(deliveryTypeToJson(DeliveryType.scheduled), 'SCHEDULED');
    });

    test('defaults unknown or missing values to normal', () {
      expect(deliveryTypeFromJson(null), DeliveryType.normal);
      expect(deliveryTypeFromJson('UNKNOWN'), DeliveryType.normal);
      expect(deliveryTypeFromJson('SCHEDULED'), DeliveryType.scheduled);
    });
  });

  test('pricing request includes the selected delivery type', () {
    final request = EstimateRequest(
      pickup: const Coordinates(latitude: 27.7, longitude: 85.3),
      delivery: const Coordinates(latitude: 27.71, longitude: 85.31),
      totalWeightKg: 2,
      deliveryType: DeliveryType.express,
    );

    expect(request.toJson()['deliveryType'], 'EXPRESS');
  });

  test('package payload includes optional dimensions and handling flags', () {
    final payload = const PackageDraft(
      name: 'Box',
      weightKg: 1.5,
      lengthInches: 10,
      widthInches: 8,
      heightInches: 4,
      isDangerous: false,
      isFragile: true,
      isFlammable: false,
      needsToBeDry: true,
    ).toJson();

    expect(payload['name'], 'Box');
    expect(payload['weightKg'], 1.5);
    expect(payload['lengthInches'], 10);
    expect(payload['widthInches'], 8);
    expect(payload['heightInches'], 4);
    expect(payload['isFragile'], isTrue);
    expect(payload['needsToBeDry'], isTrue);
  });
}
