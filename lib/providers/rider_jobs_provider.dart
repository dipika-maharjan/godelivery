import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../models/order.dart';

enum RiderJobLeg { pickup, delivery }

final availableJobsLegProvider = StateProvider<RiderJobLeg>(
  (ref) => RiderJobLeg.pickup,
);

final availableJobsProvider =
    AsyncNotifierProvider<AvailableJobsNotifier, List<Order>>(
      AvailableJobsNotifier.new,
    );

class AvailableJobsNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    final leg = ref.watch(availableJobsLegProvider);
    final page = await ref
        .read(orderRepositoryProvider)
        .listAvailable(
          leg: leg == RiderJobLeg.pickup ? 'PICKUP' : 'DELIVERY',
          pageSize: 50,
        );
    return page.data;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Orders currently assigned to the signed-in rider, for either leg.
final riderAssignedOrdersProvider =
    AsyncNotifierProvider<RiderAssignedOrdersNotifier, List<Order>>(
      RiderAssignedOrdersNotifier.new,
    );

class RiderAssignedOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    final page = await ref
        .read(orderRepositoryProvider)
        .list(role: OrderRoleFilter.assigned, pageSize: 50);
    return page.data;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
