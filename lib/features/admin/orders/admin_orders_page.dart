import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order.dart';
import '../../../providers/admin_orders_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/order_list_tile.dart';

enum _QuickFilter { all, needsPickup, needsDelivery, pendingApproval }

const _terminalStatuses = {
  OrderStatus.delivered,
  OrderStatus.failedDelivery,
  OrderStatus.cancelled,
  OrderStatus.returned,
};

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  final _searchController = TextEditingController();
  _QuickFilter _quickFilter = _QuickFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Order> _applyQuickFilter(List<Order> orders) {
    switch (_quickFilter) {
      case _QuickFilter.all:
        return orders;
      case _QuickFilter.needsPickup:
        return orders
            .where(
              (o) =>
                  o.pickupRiderAssignedAt == null &&
                  !_terminalStatuses.contains(o.status),
            )
            .toList();
      case _QuickFilter.needsDelivery:
        return orders
            .where(
              (o) =>
                  o.warehouseArrivedAt != null &&
                  o.deliveryRiderAssignedAt == null &&
                  !_terminalStatuses.contains(o.status),
            )
            .toList();
      case _QuickFilter.pendingApproval:
        return orders
            .where(
              (o) =>
                  o.pickupRiderClaimRequestedAt != null ||
                  o.deliveryRiderClaimRequestedAt != null,
            )
            .toList();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(adminOrdersFilterProvider.notifier).update(
      (state) => state.copyWith(search: () => value.trim().isEmpty ? null : value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminOrdersProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Orders',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search by tracking number',
              prefix: Icon(
                LucideIcons.search,
                size: 18,
                color: context.colors.textMuted,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _quickFilter == _QuickFilter.all,
                  onTap: () => setState(() => _quickFilter = _QuickFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Needs pickup',
                  selected: _quickFilter == _QuickFilter.needsPickup,
                  onTap: () =>
                      setState(() => _quickFilter = _QuickFilter.needsPickup),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Needs delivery',
                  selected: _quickFilter == _QuickFilter.needsDelivery,
                  onTap: () => setState(
                    () => _quickFilter = _QuickFilter.needsDelivery,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending approval',
                  selected: _quickFilter == _QuickFilter.pendingApproval,
                  onTap: () => setState(
                    () => _quickFilter = _QuickFilter.pendingApproval,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(adminOrdersProvider.notifier).refresh(),
              child: orders.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: error is ApiException
                      ? error.message
                      : 'Something went wrong.',
                  onRetry: () => ref.invalidate(adminOrdersProvider),
                ),
                data: (list) {
                  final filtered = _applyQuickFilter(list);
                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          LucideIcons.packageSearch,
                          size: 44,
                          color: context.colors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No orders match this filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                      ],
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
                        counterpartyName:
                            order.senderName ??
                            order.senderShopName ??
                            order.receiverName,
                        counterpartyLabel: 'From',
                        onTap: () => context.push('/admin/orders/${order.id}'),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : context.colors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.colors.cardAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
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
        Icon(LucideIcons.circleAlert, size: 40, color: context.colors.textMuted),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textMuted),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ),
      ],
    );
  }
}
