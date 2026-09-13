import 'package:godelivery/domain/entities/counter_entity.dart';

abstract class CounterRepository {
  Future<CounterEntity> getCounter();
  Future<CounterEntity> incrementCounter();
}
