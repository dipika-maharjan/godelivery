import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/rider_jobs_provider.dart';
import '../../../widgets/order_list_tile.dart';

class MyDeliveriesPage extends ConsumerWidget {
  const MyDeliveriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(riderAssignedOrdersProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'My deliveries',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(riderAssignedOrdersProvider.notifier).refresh(),
              child: orders.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    error is ApiException ? error.message : 'Something went wrong.',
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      children: [
                        const SizedBox(height: 100),
                        Icon(LucideIcons.bike, size: 44, color: context.colors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          "You don't have any orders assigned right now.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = list[index];
                      return OrderListTile(
                        order: order,
                        counterpartyName: order.receiverName,
                        counterpartyLabel: 'To',
                        onTap: () => context.push('/rider/orders/${order.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
