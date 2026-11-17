import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/order_repository.dart';
import '../../../models/order.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/rider_jobs_provider.dart';
import '../../../widgets/order_list_tile.dart';

class MyDeliveriesPage extends ConsumerStatefulWidget {
  const MyDeliveriesPage({super.key});

  @override
  ConsumerState<MyDeliveriesPage> createState() => _MyDeliveriesPageState();
}

class _MyDeliveriesPageState extends ConsumerState<MyDeliveriesPage> {
  final _selectedOrderIds = <String>{};
  bool _isRemoving = false;

  String? _giveUpLeg(Order order, String? riderId) {
    if (riderId == null) return null;
    if (order.pickupRider?.id == riderId &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed)) {
      return 'PICKUP';
    }
    if (order.deliveryRider?.id == riderId &&
        order.status == OrderStatus.atWarehouse) {
      return 'DELIVERY';
    }
    return null;
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
    if (!_isRemoving) setState(_selectedOrderIds.clear);
  }

  Future<void> _removeSelected(List<Order> orders, String? riderId) async {
    if (_selectedOrderIds.isEmpty || _isRemoving) return;

    final selectedOrders = orders
        .where((order) => _selectedOrderIds.contains(order.id))
        .toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove ${selectedOrders.length} '
          '${selectedOrders.length == 1 ? 'delivery' : 'deliveries'}?',
        ),
        content: const Text(
          'This releases the selected jobs back to Available Jobs. The orders '
          'will not be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final idsByLeg = <String, List<String>>{'PICKUP': [], 'DELIVERY': []};
    for (final order in selectedOrders) {
      final leg = _giveUpLeg(order, riderId);
      if (leg != null) idsByLeg[leg]!.add(order.id);
    }

    setState(() => _isRemoving = true);
    var succeededCount = 0;
    final failures = <BulkUnassignFailure>[];
    final repository = ref.read(orderRepositoryProvider);

    for (final entry in idsByLeg.entries) {
      if (entry.value.isEmpty) continue;
      try {
        final result = await repository.bulkUnassign(
          ids: entry.value,
          leg: entry.key,
        );
        succeededCount += result.succeeded.length;
        failures.addAll(result.failed);
      } catch (error) {
        final message = error is ApiException
            ? error.message
            : 'Could not remove these jobs from your deliveries.';
        failures.addAll(
          entry.value.map((id) => BulkUnassignFailure(id: id, error: message)),
        );
      }
    }

    String? refreshError;
    try {
      await ref.read(riderAssignedOrdersProvider.notifier).refresh();
      await ref.read(availableJobsProvider.notifier).refresh();
    } catch (error) {
      refreshError = error is ApiException
          ? error.message
          : 'Could not refresh the job lists.';
    }

    if (!mounted) return;
    setState(() {
      _isRemoving = false;
      _selectedOrderIds
        ..clear()
        ..addAll(failures.map((failure) => failure.id));
    });

    final failureMessage = failures.isEmpty
        ? ''
        : ' ${failures.length} failed: ${failures.first.error}';
    final message = succeededCount > 0
        ? '$succeededCount ${succeededCount == 1 ? 'job' : 'jobs'} returned.'
              '$failureMessage'
        : failures.isNotEmpty
        ? failures.first.error
        : 'No eligible jobs were selected.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          refreshError == null ? message : '$message $refreshError',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(riderAssignedOrdersProvider);
    final riderId = ref.watch(authControllerProvider).user?.id;
    final selectionMode = _selectedOrderIds.isNotEmpty;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectionMode
                        ? '${_selectedOrderIds.length} selected'
                        : 'My deliveries',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isRemoving ? null : _clearSelection,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isRemoving
                          ? null
                          : () => _removeSelected(
                              orders.valueOrNull ?? const [],
                              riderId,
                            ),
                      icon: _isRemoving
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
                        _isRemoving
                            ? 'Removing…'
                            : 'Remove ${_selectedOrderIds.length} selected',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(riderAssignedOrdersProvider.notifier).refresh(),
              child: orders.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    error is ApiException
                        ? error.message
                        : 'Something went wrong.',
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          LucideIcons.bike,
                          size: 44,
                          color: context.colors.textMuted,
                        ),
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
                      final canGiveUp = _giveUpLeg(order, riderId) != null;
                      return OrderListTile(
                        order: order,
                        counterpartyName: order.receiverName,
                        counterpartyLabel: 'To',
                        selected: _selectedOrderIds.contains(order.id),
                        selectionMode: selectionMode,
                        onSelectionChanged: selectionMode && canGiveUp
                            ? () => _toggleSelection(order)
                            : null,
                        onTap: () {
                          if (selectionMode) {
                            if (canGiveUp) {
                              _toggleSelection(order);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'This job can no longer be given up at its current stage.',
                                  ),
                                ),
                              );
                            }
                          } else {
                            context.push('/rider/orders/${order.id}');
                          }
                        },
                        onLongPress: canGiveUp
                            ? () => _enterSelectionMode(order)
                            : null,
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
