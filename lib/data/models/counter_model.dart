import 'package:godelivery/domain/entities/counter_entity.dart';

class CounterModel extends CounterEntity {
  const CounterModel({required super.count});

  factory CounterModel.fromJson(Map<String, dynamic> json) {
    return CounterModel(count: json['count'] as int);
  }

  Map<String, dynamic> toJson() {
    return {'count': count};
  }

  factory CounterModel.fromEntity(CounterEntity entity) {
    return CounterModel(count: entity.count);
  }
}
