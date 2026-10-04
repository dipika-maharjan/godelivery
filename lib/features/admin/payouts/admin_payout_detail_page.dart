import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/payouts_repository.dart';
import '../../../models/payout.dart';
import '../../../providers/payouts_provider.dart';
import '../../../widgets/app_text_field.dart';

class AdminPayoutDetailPage extends ConsumerWidget {
  const AdminPayoutDetailPage({super.key, required this.payoutId});

  final String payoutId;

  Future<void> _markPaid(BuildContext context, WidgetRef ref, Payout payout) async {
    try {
      await ref.read(payoutsRepositoryProvider).markPaid(payout.id);
      ref.invalidate(payoutDetailProvider(payout.id));
      await ref.read(payoutsProvider.notifier).refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout marked as paid.')),
      );
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not update the payout.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _markFailed(BuildContext context, WidgetRef ref, Payout payout) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark payout as failed?'),
        content: AppTextField(
          controller: reasonController,
          label: 'Reason (optional)',
          hint: 'e.g. wrong account number',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mark failed', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(payoutsRepositoryProvider).markFailed(
            payout.id,
            reason: reasonController.text.trim().isEmpty
                ? null
                : reasonController.text.trim(),
          );
      ref.invalidate(payoutDetailProvider(payout.id));
      await ref.read(payoutsProvider.notifier).refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout marked as failed.')),
      );
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not update the payout.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payout = ref.watch(payoutDetailProvider(payoutId));
    return Scaffold(
      appBar: AppBar(title: const Text('Payout')),
      body: payout.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiException ? error.message : 'Something went wrong.'),
        ),
        data: (value) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${value.amount} ${value.currency}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                ),
                _StatusBadge(status: value.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${value.rider.name} · ${value.rider.phoneNumber}',
              style: TextStyle(color: context.colors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y · h:mm a').format(value.createdAt),
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
            ),
            if (value.referenceNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.cardAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(value.referenceNote!),
              ),
            ],
            if (value.status == PayoutStatus.pending) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => _markPaid(context, ref, value),
                    child: const Text('Mark as paid'),
                  ),
                  OutlinedButton(
                    onPressed: () => _markFailed(context, ref, value),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Mark as failed'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text('Orders', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...value.orders.map(
              (line) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.package, size: 16, color: context.colors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line.trackingNumber)),
                    Text(
                      line.amount,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PayoutStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PayoutStatus.pending => ('Pending', Colors.orange),
      PayoutStatus.paid => ('Paid', AppColors.success),
      PayoutStatus.failed => ('Failed', AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
