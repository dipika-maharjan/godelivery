import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/locations_repository.dart';
import '../../models/saved_location.dart';
import '../../providers/saved_locations_provider.dart';
import 'saved_address_form_page.dart';

/// The sender's saved pickup-address book, backed by `savedLocationsProvider`.
class SavedAddressesPage extends ConsumerWidget {
  const SavedAddressesPage({super.key});

  Future<void> _add(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SavedAddressFormPage()),
    );
  }

  Future<void> _edit(BuildContext context, SavedLocation location) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavedAddressFormPage(existing: location),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SavedLocation location,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove address?'),
        content: Text(
          'Remove "${location.label ?? location.addressLine}" from your saved addresses?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(locationsRepositoryProvider).delete(location.id);
      await ref.read(savedLocationsProvider.notifier).refresh();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not remove the address.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(savedLocationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved addresses'),
        actions: [
          IconButton(
            tooltip: 'Add address',
            onPressed: () => _add(context),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: locations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            error is ApiException ? error.message : 'Something went wrong.',
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No saved addresses yet. Add one to reuse it as a pickup point when creating a shipment.',
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
              final location = items[index];
              return _SavedAddressTile(
                location: location,
                onTap: () => _edit(context, location),
                onDelete: () => _delete(context, ref, location),
              );
            },
          );
        },
      ),
    );
  }
}

class _SavedAddressTile extends StatelessWidget {
  const _SavedAddressTile({
    required this.location,
    required this.onTap,
    required this.onDelete,
  });

  final SavedLocation location;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              location.isDefault ? LucideIcons.star : LucideIcons.mapPin,
              size: 18,
              color: location.isDefault
                  ? AppColors.primary
                  : context.colors.text,
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
                          location.label ?? location.addressLine,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (location.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.addressLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.colors.textMuted,
                    ),
                  ),
                  if (location.landmark != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      location.landmark!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                LucideIcons.trash2,
                size: 18,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
