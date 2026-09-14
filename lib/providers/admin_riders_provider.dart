import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/riders_repository.dart';
import '../models/rider.dart';

class AdminRidersFilter {
  const AdminRidersFilter({this.isActive, this.isAvailable});

  final bool? isActive;
  final bool? isAvailable;
}

final adminRidersFilterProvider = StateProvider<AdminRidersFilter>(
  (ref) => const AdminRidersFilter(),
);

final adminRidersProvider =
    AsyncNotifierProvider<AdminRidersNotifier, List<Rider>>(
      AdminRidersNotifier.new,
    );

class AdminRidersNotifier extends AsyncNotifier<List<Rider>> {
  @override
  Future<List<Rider>> build() async {
    final filter = ref.watch(adminRidersFilterProvider);
    final page = await ref
        .read(ridersRepositoryProvider)
        .list(isActive: filter.isActive, isAvailable: filter.isAvailable);
    return page.data;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final riderMetricsProvider = FutureProvider.family<RiderMetrics, String>(
  (ref, id) => ref.read(ridersRepositoryProvider).metrics(id),
);

final riderBankAccountProvider = FutureProvider.family<BankAccount?, String>(
  (ref, id) async {
    try {
      return await ref.read(ridersRepositoryProvider).bankAccount(id);
    } catch (_) {
      // A rider may not have added bank details yet.
      return null;
    }
  },
);

final riderUnpaidDeliveriesProvider =
    FutureProvider.family<RiderUnpaidDeliveries, String>(
      (ref, id) => ref.read(ridersRepositoryProvider).unpaidDeliveries(id),
    );
