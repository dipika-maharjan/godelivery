import 'package:godelivery/domain/entities/counter_entity.dart';
import 'package:godelivery/domain/repositories/counter_repository.dart';

class GetCounterUseCase {
  final CounterRepository repository;

  GetCounterUseCase({required this.repository});

  Future<CounterEntity> call() async {
    return await repository.getCounter();
  }
}
