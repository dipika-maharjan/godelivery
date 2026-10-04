import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/order_repository.dart';
import '../../../models/order.dart';
import '../../../providers/rider_jobs_provider.dart';

class AvailableJobsPage extends ConsumerWidget {
  const AvailableJobsPage({super.key});

  Future<void> _claim(BuildContext context, WidgetRef ref, Order order, RiderJobLeg leg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Claim this ${leg == RiderJobLeg.pickup ? 'pickup' : 'delivery'}?'),
        content: const Text(
          'This reserves the order for you, pending admin approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = ref.read(orderRepositoryProvider);
      if (leg == RiderJobLeg.pickup) {
        await repo.claimPickup(order.id);
      } else {
        await repo.claimDelivery(order.id);
      }
      await ref.read(availableJobsProvider.notifier).refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claimed — waiting for admin approval.')),
      );
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not claim this order.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leg = ref.watch(availableJobsLegProvider);
    final jobs = ref.watch(availableJobsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Available jobs',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.colors.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _LegSegment(
                      label: 'Pickup',
                      selected: leg == RiderJobLeg.pickup,
                      onTap: () =>
                          ref.read(availableJobsLegProvider.notifier).state = RiderJobLeg.pickup,
                    ),
                  ),
                  Expanded(
                    child: _LegSegment(
                      label: 'Delivery',
                      selected: leg == RiderJobLeg.delivery,
                      onTap: () => ref.read(availableJobsLegProvider.notifier).state =
                          RiderJobLeg.delivery,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(availableJobsProvider.notifier).refresh(),
              child: jobs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    error is ApiException ? error.message : 'Something went wrong.',
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
                          LucideIcons.packageSearch,
                          size: 44,
                          color: context.colors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No available jobs right now.',
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
                      return _JobTile(
                        order: order,
                        leg: leg,
                        onClaim: () => _claim(context, ref, order, leg),
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

class _JobTile extends StatelessWidget {
  const _JobTile({required this.order, required this.leg, required this.onClaim});

  final Order order;
  final RiderJobLeg leg;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final location =
        leg == RiderJobLeg.pickup ? order.pickupLocation : order.deliveryLocation;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                leg == RiderJobLeg.pickup ? LucideIcons.store : LucideIcons.mapPin,
                size: 16,
                color: context.colors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location.addressLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.trackingNumber} · ${order.totalWeightKg} kg · ${order.distanceKm.toStringAsFixed(1)} km',
            style: TextStyle(fontSize: 12, color: context.colors.textMuted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onClaim, child: const Text('Claim')),
          ),
        ],
      ),
    );
  }
}

class _LegSegment extends StatelessWidget {
  const _LegSegment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : context.colors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
