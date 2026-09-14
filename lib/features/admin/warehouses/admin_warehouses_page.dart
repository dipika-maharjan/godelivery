import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/warehouses_repository.dart';
import '../../../models/warehouse.dart';
import '../../../providers/warehouses_provider.dart';
import 'warehouse_form_page.dart';

class AdminWarehousesPage extends ConsumerWidget {
  const AdminWarehousesPage({super.key});

  Future<void> _add(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WarehouseFormPage()),
    );
  }

  Future<void> _edit(BuildContext context, Warehouse warehouse) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WarehouseFormPage(existing: warehouse)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Warehouse warehouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete warehouse?'),
        content: Text(
          'In-flight orders routed through "${warehouse.name}" keep their history; this only stops new routing through it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(warehousesRepositoryProvider).delete(warehouse.id);
      await ref.read(warehousesProvider.notifier).refresh();
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not delete the warehouse.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehouses = ref.watch(warehousesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses'),
        actions: [
          IconButton(
            tooltip: 'Add warehouse',
            onPressed: () => _add(context),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: warehouses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiException ? error.message : 'Something went wrong.'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No warehouses yet. Add one to enable pickup/delivery routing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final warehouse = items[index];
              return InkWell(
                onTap: () => _edit(context, warehouse),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.warehouse,
                        size: 18,
                        color: warehouse.isActive
                            ? context.colors.text
                            : context.colors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    warehouse.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (!warehouse.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.cardAlt,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Inactive',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: context.colors.textMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              warehouse.location.addressLine,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _delete(context, ref, warehouse),
                        icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
