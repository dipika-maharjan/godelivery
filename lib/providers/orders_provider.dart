import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../models/order.dart';

final ordersProvider =
    AsyncNotifierProvider.family<OrdersNotifier, List<Order>, OrderRoleFilter>(
      OrdersNotifier.new,
    );

class OrdersNotifier extends FamilyAsyncNotifier<List<Order>, OrderRoleFilter> {
  @override
  Future<List<Order>> build(OrderRoleFilter arg) async {
    final page = await ref
        .read(orderRepositoryProvider)
        .list(role: arg, page: 1, pageSize: 50);
    return page.data;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final orderDetailProvider = FutureProvider.family<Order, String>((ref, id) {
  return ref.read(orderRepositoryProvider).getOne(id);
});
