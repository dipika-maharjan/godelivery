import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/payouts_repository.dart';
import '../../../data/riders_repository.dart';
import '../../../models/payout.dart';
import '../../../models/rider.dart';
import '../../../providers/auth_provider.dart';

final _myUnpaidDeliveriesProvider =
    FutureProvider.autoDispose<RiderUnpaidDeliveries?>((ref) {
  final myId = ref.watch(authControllerProvider).user?.id;
  if (myId == null) return null;
  return ref.read(ridersRepositoryProvider).unpaidDeliveries(myId);
});

final _myPayoutsProvider = FutureProvider.autoDispose<List<Payout>>((ref) {
  final myId = ref.watch(authControllerProvider).user?.id;
  if (myId == null) return Future.value(<Payout>[]);
  return ref.read(payoutsRepositoryProvider).list(riderId: myId).then((p) => p.data);
});

class RiderEarningsPage extends ConsumerWidget {
  const RiderEarningsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unpaid = ref.watch(_myUnpaidDeliveriesProvider);
    final payouts = ref.watch(_myPayoutsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_myUnpaidDeliveriesProvider);
          ref.invalidate(_myPayoutsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              'Earnings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Text('Owed to you', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            unpaid.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              )),
              error: (error, _) => Text(
                error is ApiException ? error.message : 'Could not load unpaid deliveries.',
                style: TextStyle(color: context.colors.textMuted),
              ),
              data: (data) {
                if (data == null || data.orders.isEmpty) {
                  return Text(
                    'Nothing owed right now.',
                    style: TextStyle(color: context.colors.textMuted),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.totalAmountOwed} ${data.currency}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.orders.length} delivered order(s) awaiting payout',
                        style: TextStyle(fontSize: 12.5, color: context.colors.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Payout history', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            payouts.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              )),
              error: (error, _) => Text(
                error is ApiException ? error.message : 'Could not load payouts.',
                style: TextStyle(color: context.colors.textMuted),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'No payouts yet.',
                    style: TextStyle(color: context.colors.textMuted),
                  );
                }
                return Column(
                  children: list.map((payout) => _PayoutRow(payout: payout)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.payout});

  final Payout payout;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (payout.status) {
      PayoutStatus.pending => ('Pending', Colors.orange),
      PayoutStatus.paid => ('Paid', AppColors.success),
      PayoutStatus.failed => ('Failed', AppColors.danger),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.banknote, size: 16, color: context.colors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payout.amount} ${payout.currency}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${payout.orders.length} order(s) · ${DateFormat('MMM d, y').format(payout.createdAt)}',
                  style: TextStyle(fontSize: 11.5, color: context.colors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
