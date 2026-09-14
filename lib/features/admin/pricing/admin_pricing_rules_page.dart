import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/pricing_rules_repository.dart';
import '../../../models/pricing_rule.dart';
import '../../../providers/pricing_rules_provider.dart';
import 'pricing_rule_form_page.dart';

class AdminPricingRulesPage extends ConsumerWidget {
  const AdminPricingRulesPage({super.key});

  Future<void> _add(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PricingRuleFormPage()),
    );
  }

  Future<void> _edit(BuildContext context, PricingRule rule) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PricingRuleFormPage(existing: rule)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, PricingRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete pricing rule?'),
        content: Text('Remove "${rule.name}"? This cannot be undone.'),
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
      await ref.read(pricingRulesRepositoryProvider).delete(rule.id);
      await ref.read(pricingRulesProvider.notifier).refresh();
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not delete the rule.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(pricingRulesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing rules'),
        actions: [
          IconButton(
            tooltip: 'Add pricing rule',
            onPressed: () => _add(context),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: rules.when(
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
                  'No pricing rules yet.',
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
              final rule = items[index];
              return InkWell(
                onTap: () => _edit(context, rule),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.receipt,
                        size: 18,
                        color: rule.isActive ? context.colors.text : context.colors.textMuted,
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
                                    rule.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (!rule.isActive)
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
                              'Base ${rule.baseFare} + ${rule.ratePerKg}/kg + '
                              '${rule.ratePerKm}/km · min ${rule.minCharge} ${rule.currency}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _delete(context, ref, rule),
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
