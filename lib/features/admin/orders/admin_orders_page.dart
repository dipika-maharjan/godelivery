import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/order_repository.dart';
import '../../../models/order.dart';
import '../../../models/user.dart';
import '../../../providers/admin_orders_provider.dart';
import '../../../providers/auth_provider.dart';
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
  final _selectedOrderIds = <String>{};
  bool _isDeleting = false;

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
    ref
        .read(adminOrdersFilterProvider.notifier)
        .update(
          (state) => state.copyWith(
            search: () => value.trim().isEmpty ? null : value.trim(),
          ),
        );
  }

  void _toggleSelection(Order order) {
    setState(() {
      if (!_selectedOrderIds.add(order.id)) {
        _selectedOrderIds.remove(order.id);
      }
    });
  }

  void _enterSelectionMode(Order order) {
    if (_selectedOrderIds.isEmpty) {
      setState(() => _selectedOrderIds.add(order.id));
    } else {
      _toggleSelection(order);
    }
  }

  void _clearSelection() {
    if (_selectedOrderIds.isNotEmpty) {
      setState(_selectedOrderIds.clear);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedOrderIds.isEmpty || _isDeleting) return;
    final count = _selectedOrderIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count ${count == 1 ? 'order' : 'orders'}?'),
        content: const Text(
          'This will cancel the selected orders. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    var cancelled = 0;
    String? errorMessage;
    for (final orderId in _selectedOrderIds.toList()) {
      try {
        await ref.read(orderRepositoryProvider).adminCancel(orderId);
        cancelled++;
      } catch (error) {
        errorMessage = error is ApiException
            ? error.message
            : 'Could not delete all selected orders.';
      }
    }
    if (!mounted) return;
    setState(() {
      _isDeleting = false;
      _selectedOrderIds.clear();
    });
    await ref.read(adminOrdersProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage ??
              '$cancelled ${cancelled == 1 ? 'order' : 'orders'} deleted.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminOrdersProvider);
    final isAdmin =
        ref.watch(authControllerProvider).user?.role == UserRole.admin;

    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
                child: _selectedOrderIds.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          IconButton(
                            onPressed: _clearSelection,
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear selection',
                          ),
                          Text(
                            '${_selectedOrderIds.length} selected',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _isDeleting ? null : _deleteSelected,
                            icon: _isDeleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.delete_outline),
                            tooltip: 'Delete selected orders',
                          ),
                        ],
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
                      onTap: () =>
                          setState(() => _quickFilter = _QuickFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Needs pickup',
                      selected: _quickFilter == _QuickFilter.needsPickup,
                      onTap: () => setState(
                        () => _quickFilter = _QuickFilter.needsPickup,
                      ),
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
                  onRefresh: () =>
                      ref.read(adminOrdersProvider.notifier).refresh(),
                  child: orders.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
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
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 180),
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
                            selectionMode: _selectedOrderIds.isNotEmpty,
                            selected: _selectedOrderIds.contains(order.id),
                            onTap: () => _selectedOrderIds.isNotEmpty
                                ? _toggleSelection(order)
                                : context.push('/admin/orders/${order.id}'),
                            onLongPress: () => _enterSelectionMode(order),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (isAdmin && _selectedOrderIds.isEmpty)
            Positioned(
              right: 20,
              bottom: 88,
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/admin/orders/new'),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                icon: const Icon(LucideIcons.plus, size: 19),
                label: const Text('New order'),
              ),
            ),
          if (isAdmin && _selectedOrderIds.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 88,
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isDeleting ? null : _deleteSelected,
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(
                    _isDeleting
                        ? 'Deleting...'
                        : 'Delete ${_selectedOrderIds.length} selected',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
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
