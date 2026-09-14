import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/warehouses_repository.dart';
import '../models/warehouse.dart';

final warehousesProvider =
    AsyncNotifierProvider<WarehousesNotifier, List<Warehouse>>(
      WarehousesNotifier.new,
    );

class WarehousesNotifier extends AsyncNotifier<List<Warehouse>> {
  @override
  Future<List<Warehouse>> build() {
    return ref.read(warehousesRepositoryProvider).list();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
