import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/order_repository.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/order_list_tile.dart';
import '../../widgets/active_consignment_card.dart';

class ShipmentsTab extends ConsumerStatefulWidget {
  const ShipmentsTab({super.key});

  @override
  ConsumerState<ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends ConsumerState<ShipmentsTab> {
  final _searchController = TextEditingController();
  final _selectedOrderIds = <String>{};
  String _query = '';
  bool _isCancelling = false;

  static const _terminalStatuses = {
    OrderStatus.delivered,
    OrderStatus.failedDelivery,
    OrderStatus.cancelled,
    OrderStatus.returned,
  };

  bool _canCancel(Order order, String? userId) =>
      userId != null &&
      order.senderId == userId &&
      order.pickupRiderAssignedAt == null &&
      !_terminalStatuses.contains(order.status);

  void _toggleSelection(Order order) {
    setState(() {
      if (!_selectedOrderIds.add(order.id)) {
        _selectedOrderIds.remove(order.id);
      }
    });
  }

  void _startSelection(Order order) {
    if (_selectedOrderIds.isEmpty) {
      setState(() => _selectedOrderIds.add(order.id));
    } else {
      _toggleSelection(order);
    }
  }

  void _explainCancellationLimit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A shipment can only be cancelled by its sender before a pickup rider is assigned.',
        ),
      ),
    );
  }

  Future<void> _cancelSelected(List<Order> orders) async {
    if (_selectedOrderIds.isEmpty || _isCancelling) return;
    final selectedOrders = orders
        .where(
          (order) =>
              _selectedOrderIds.contains(order.id) &&
              _canCancel(order, ref.read(authControllerProvider).user?.id),
        )
        .toList();
    if (selectedOrders.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel ${selectedOrders.length} '
          '${selectedOrders.length == 1 ? 'shipment' : 'shipments'}?',
        ),
        content: const Text(
          'The selected shipments will be cancelled. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel shipments'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    var cancelledCount = 0;
    final failures = <String>[];
    for (final order in selectedOrders) {
      try {
        await ref.read(orderRepositoryProvider).cancel(order.id);
        cancelledCount++;
      } catch (error) {
        failures.add(
          error is ApiException ? error.message : 'Could not cancel shipment.',
        );
      }
    }

    try {
      await ref.read(ordersProvider(OrderRoleFilter.sent).notifier).refresh();
    } catch (error) {
      failures.add(
        error is ApiException
            ? error.message
            : 'Could not refresh the shipment list.',
      );
    }

    if (!mounted) return;
    setState(() {
      _isCancelling = false;
      _selectedOrderIds.clear();
    });

    final message = cancelledCount > 0
        ? '$cancelledCount '
              '${cancelledCount == 1 ? 'shipment' : 'shipments'} cancelled.'
              '${failures.isEmpty ? '' : ' ${failures.first}'}'
        : failures.isNotEmpty
        ? failures.first
        : 'No shipments were cancelled.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
    final currentUserId = ref.watch(authControllerProvider).user?.id;
    final activeOrder = orders.valueOrNull
        ?.where((order) => activeConsignmentStatuses.contains(order.status))
        .firstOrNull;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              _selectedOrderIds.isEmpty
                  ? 'Shipments'
                  : '${_selectedOrderIds.length} selected',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          if (_selectedOrderIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isCancelling
                        ? null
                        : () => setState(_selectedOrderIds.clear),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isCancelling
                          ? null
                          : () =>
                                _cancelSelected(orders.valueOrNull ?? const []),
                      icon: _isCancelling
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
                        _isCancelling
                            ? 'Cancelling…'
                            : 'Remove ${_selectedOrderIds.length} selected',
                      ),
                    ),
                  ),
                ],
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
                  final otherOrders = filtered
                      .where((order) => order.id != activeOrder?.id)
                      .toList();
                  if (otherOrders.isEmpty && activeOrder == null) {
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
                    itemCount:
                        otherOrders.length + (activeOrder == null ? 0 : 1),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (activeOrder != null && index == 0) {
                        final canCancelActive = _canCancel(
                          activeOrder,
                          currentUserId,
                        );
                        final selectionMode = _selectedOrderIds.isNotEmpty;
                        return ActiveConsignmentCard(
                          order: activeOrder,
                          subtitle: 'Shipment in progress',
                          selectionMode: selectionMode,
                          selected: _selectedOrderIds.contains(activeOrder.id),
                          onSelectionChanged: canCancelActive
                              ? () => _toggleSelection(activeOrder)
                              : null,
                          onLongPress: () {
                            if (canCancelActive) {
                              _startSelection(activeOrder);
                            } else {
                              _explainCancellationLimit();
                            }
                          },
                        );
                      }
                      final orderIndex = activeOrder == null
                          ? index
                          : index - 1;
                      final order = otherOrders[orderIndex];
                      final canCancel = _canCancel(order, currentUserId);
                      final selectionMode = _selectedOrderIds.isNotEmpty;
                      return OrderListTile(
                        order: order,
                        counterpartyName: order.receiverName,
                        counterpartyLabel: 'To',
                        selected: _selectedOrderIds.contains(order.id),
                        selectionMode: selectionMode,
                        onSelectionChanged: canCancel
                            ? () => _toggleSelection(order)
                            : null,
                        onTap: () {
                          if (selectionMode) {
                            if (canCancel) {
                              _toggleSelection(order);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'This shipment cannot be cancelled at its current stage.',
                                  ),
                                ),
                              );
                            }
                          } else {
                            context.push('/orders/${order.id}');
                          }
                        },
                        onLongPress: () {
                          if (canCancel) {
                            _startSelection(order);
                          } else {
                            _explainCancellationLimit();
                          }
                        },
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
