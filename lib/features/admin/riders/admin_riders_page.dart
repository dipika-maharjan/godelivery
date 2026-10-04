import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/rider.dart';
import '../../../providers/admin_riders_provider.dart';
import 'admin_rider_detail_page.dart';
import 'onboard_rider_page.dart';

class AdminRidersPage extends ConsumerWidget {
  const AdminRidersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riders = ref.watch(adminRidersProvider);
    final filter = ref.watch(adminRidersFilterProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Riders',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Onboard rider',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardRiderPage()),
                  ),
                  icon: const Icon(LucideIcons.userPlus),
                ),
              ],
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
                  selected: filter.isActive == null && filter.isAvailable == null,
                  onTap: () => ref
                      .read(adminRidersFilterProvider.notifier)
                      .state = const AdminRidersFilter(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  selected: filter.isActive == true,
                  onTap: () => ref.read(adminRidersFilterProvider.notifier).state =
                      const AdminRidersFilter(isActive: true),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Available now',
                  selected: filter.isAvailable == true,
                  onTap: () => ref.read(adminRidersFilterProvider.notifier).state =
                      const AdminRidersFilter(isAvailable: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(adminRidersProvider.notifier).refresh(),
              child: riders.when(
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
                        Icon(LucideIcons.bike, size: 44, color: context.colors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No riders match this filter.',
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
                      final rider = list[index];
                      return _RiderTile(rider: rider);
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

class _RiderTile extends StatelessWidget {
  const _RiderTile({required this.rider});

  final Rider rider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminRiderDetailPage(riderId: rider.id)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.bike, size: 20, color: context.colors.text),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${vehicleTypeLabel(rider.vehicleType)} · ${rider.phoneNumber}',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            if (!rider.isActive)
              const _Dot(color: AppColors.danger, label: 'Suspended')
            else if (rider.isAvailable)
              const _Dot(color: AppColors.success, label: 'Available')
            else
              _Dot(color: context.colors.textMuted, label: 'Offline'),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

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
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
