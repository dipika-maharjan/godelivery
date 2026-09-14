import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payouts_repository.dart';
import '../models/payout.dart';

final payoutsStatusFilterProvider = StateProvider<PayoutStatus?>((ref) => null);

final payoutsProvider = AsyncNotifierProvider<PayoutsNotifier, List<Payout>>(
  PayoutsNotifier.new,
);

class PayoutsNotifier extends AsyncNotifier<List<Payout>> {
  @override
  Future<List<Payout>> build() async {
    final status = ref.watch(payoutsStatusFilterProvider);
    final page = await ref.read(payoutsRepositoryProvider).list(status: status);
    return page.data;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final payoutDetailProvider = FutureProvider.family<Payout, String>(
  (ref, id) => ref.read(payoutsRepositoryProvider).getOne(id),
);
