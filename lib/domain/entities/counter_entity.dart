import 'package:equatable/equatable.dart';

class CounterEntity extends Equatable {
  final int count;

  const CounterEntity({required this.count});

  @override
  List<Object?> get props => [count];
}
