import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/api_keys_repository.dart';
import '../../../models/api_key.dart';
import '../../../providers/admin_users_provider.dart';
import '../../../widgets/app_text_field.dart';

class ApiKeysPage extends ConsumerWidget {
  const ApiKeysPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New API key'),
        content: AppTextField(
          controller: nameController,
          label: 'Name',
          hint: 'e.g. Warehouse integration',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final created = await ref.read(apiKeysRepositoryProvider).create(name: name);
      await ref.read(apiKeysProvider.notifier).refresh();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Save this secret now'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This is shown only once and cannot be retrieved again.'),
              const SizedBox(height: 12),
              SelectableText(
                created.secret,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: created.secret));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Copied to clipboard.')));
              },
              icon: const Icon(LucideIcons.copy, size: 16),
              label: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not create the API key.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref, ApiKeyListItem key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke this key?'),
        content: Text('"${key.name}" will stop working immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiKeysRepositoryProvider).revoke(key.id);
      await ref.read(apiKeysProvider.notifier).refresh();
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not revoke the key.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(apiKeysProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('API keys'),
        actions: [
          IconButton(
            tooltip: 'Create API key',
            onPressed: () => _create(context, ref),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: keys.when(
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
                  'No API keys yet. Create one for server-to-server integration.',
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
              final key = items[index];
              final revoked = key.revokedAt != null;
              return Container(
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
                      LucideIcons.key,
                      size: 18,
                      color: revoked ? context.colors.textMuted : context.colors.text,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            key.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${key.keyPrefix}••••••',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: context.colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            revoked
                                ? 'Revoked'
                                : key.lastUsedAt == null
                                ? 'Never used'
                                : 'Last used ${DateFormat('MMM d, y').format(key.lastUsedAt!)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: revoked
                                  ? AppColors.danger
                                  : context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!revoked)
                      IconButton(
                        onPressed: () => _revoke(context, ref, key),
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: AppColors.danger,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
