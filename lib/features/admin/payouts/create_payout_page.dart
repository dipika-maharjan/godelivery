import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/payouts_repository.dart';
import '../../../models/rider.dart';
import '../../../providers/admin_riders_provider.dart';
import '../../../providers/payouts_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';

/// Pick a rider, choose which of their unpaid deliveries to cover, and
/// create a payout batch (`POST /payouts`).
class CreatePayoutPage extends ConsumerStatefulWidget {
  const CreatePayoutPage({super.key});

  @override
  ConsumerState<CreatePayoutPage> createState() => _CreatePayoutPageState();
}

class _CreatePayoutPageState extends ConsumerState<CreatePayoutPage> {
  final _noteController = TextEditingController();
  Rider? _selectedRider;
  final Set<String> _selectedOrderIds = {};
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickRider() async {
    final rider = await showModalBottomSheet<Rider>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RiderPickerSheet(),
    );
    if (rider == null) return;
    setState(() {
      _selectedRider = rider;
      _selectedOrderIds.clear();
    });
  }

  Future<void> _submit() async {
    final rider = _selectedRider;
    if (rider == null || _selectedOrderIds.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(payoutsRepositoryProvider).create(
            riderId: rider.id,
            orderIds: _selectedOrderIds.toList(),
            referenceNote: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      await ref.read(payoutsProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not create the payout. Please try again.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rider = _selectedRider;
    return Scaffold(
      appBar: AppBar(title: const Text('New payout')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rider',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickRider,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.bike, size: 18, color: context.colors.text),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rider?.name ?? 'Choose a rider',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: rider != null ? context.colors.text : context.colors.textMuted,
                        ),
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 18, color: context.colors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (rider != null)
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final unpaid = ref.watch(riderUnpaidDeliveriesProvider(rider.id));
                    return unpaid.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const Center(child: Text('Could not load deliveries.')),
                      data: (data) {
                        if (data.orders.isEmpty) {
                          return Center(
                            child: Text(
                              'Nothing owed to this rider right now.',
                              style: TextStyle(color: context.colors.textMuted),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unpaid deliveries',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.separated(
                                itemCount: data.orders.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final order = data.orders[index];
                                  final selected = _selectedOrderIds.contains(order.id);
                                  return CheckboxListTile(
                                    value: selected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value ?? false) {
                                          _selectedOrderIds.add(order.id);
                                        } else {
                                          _selectedOrderIds.remove(order.id);
                                        }
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(order.trackingNumber),
                                    subtitle: Text('${order.amount} ${order.currency}'),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              controller: _noteController,
                              label: 'Reference note (optional)',
                              hint: 'e.g. bank transfer reference',
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: _selectedOrderIds.isEmpty
                                  ? 'Select deliveries to pay out'
                                  : 'Create payout for ${_selectedOrderIds.length} order(s)',
                              enabled: _selectedOrderIds.isNotEmpty,
                              loading: _submitting,
                              onPressed: _submit,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RiderPickerSheet extends ConsumerWidget {
  const _RiderPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riders = ref.watch(adminRidersProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a rider', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: riders.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text('Could not load riders.')),
                data: (list) => ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final rider = list[index];
                    return ListTile(
                      leading: const Icon(LucideIcons.bike, size: 18),
                      title: Text(rider.name),
                      subtitle: Text(rider.phoneNumber),
                      onTap: () => Navigator.of(context).pop(rider),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
