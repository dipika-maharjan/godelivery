import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/order_repository.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/order_list_tile.dart';

class ShipmentsTab extends ConsumerStatefulWidget {
  const ShipmentsTab({super.key});

  @override
  ConsumerState<ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends ConsumerState<ShipmentsTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Order> _filter(List<Order> list) {
    if (_query.isEmpty) return list;
    final query = _query.toLowerCase();
    return list
        .where(
          (order) =>
              order.trackingNumber.toLowerCase().contains(query) ||
              order.receiverName.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider(OrderRoleFilter.sent));

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Shipments',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search by tracking number or receiver',
              prefix: Icon(
                LucideIcons.search,
                size: 18,
                color: context.colors.textMuted,
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(ordersProvider(OrderRoleFilter.sent).notifier)
                  .refresh(),
              child: orders.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: error is ApiException
                      ? error.message
                      : 'Something went wrong.',
                  onRetry: () =>
                      ref.invalidate(ordersProvider(OrderRoleFilter.sent)),
                ),
                data: (list) {
                  final filtered = _filter(list);
                  if (filtered.isEmpty) {
                    return _EmptyState(
                      icon: _query.isNotEmpty
                          ? LucideIcons.searchX
                          : LucideIcons.send,
                      message: _query.isNotEmpty
                          ? "No shipments match '$_query'."
                          : "You haven't sent any shipments yet. Tap + to create one.",
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return OrderListTile(
                        order: order,
                        counterpartyName: order.receiverName,
                        counterpartyLabel: 'To',
                        onTap: () => context.push('/orders/${order.id}'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 44, color: context.colors.textMuted),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textMuted),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 80),
        Icon(
          LucideIcons.circleAlert,
          size: 40,
          color: context.colors.textMuted,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textMuted),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
