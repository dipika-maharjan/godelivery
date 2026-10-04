import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../models/order.dart';

class AdminOrdersFilter {
  const AdminOrdersFilter({this.status, this.search});

  final OrderStatus? status;
  final String? search;

  AdminOrdersFilter copyWith({
    OrderStatus? Function()? status,
    String? Function()? search,
  }) {
    return AdminOrdersFilter(
      status: status == null ? this.status : status(),
      search: search == null ? this.search : search(),
    );
  }
}

final adminOrdersProvider =
    AsyncNotifierProvider<AdminOrdersNotifier, List<Order>>(
      AdminOrdersNotifier.new,
    );

final adminOrdersFilterProvider = StateProvider<AdminOrdersFilter>(
  (ref) => const AdminOrdersFilter(),
);

class AdminOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    final filter = ref.watch(adminOrdersFilterProvider);
    final page = await ref
        .read(orderRepositoryProvider)
        .list(
          role: OrderRoleFilter.all,
          pageSize: 50,
          status: filter.status,
          search: filter.search,
        );
    return page.data;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
