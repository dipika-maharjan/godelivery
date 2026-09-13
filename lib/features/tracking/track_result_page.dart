import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/status_display.dart';
import '../../models/order.dart';
import '../../models/tracking.dart';
import '../../providers/tracking_provider.dart';
import '../../widgets/order_status_chip.dart';

class TrackResultPage extends ConsumerWidget {
  const TrackResultPage({super.key, required this.trackingNumber});

  final String trackingNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(trackingProvider(trackingNumber));

    return Scaffold(
      appBar: AppBar(title: Text(trackingNumber)),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(trackingProvider(trackingNumber)),
        ),
        data: (tracking) => _TrackingBody(tracking: tracking),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.packageX, size: 44, color: AppColors.muted),
            const SizedBox(height: 12),
            const Text(
              "We couldn't find a shipment with that tracking number.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({required this.tracking});

  final PublicTracking tracking;

  @override
  Widget build(BuildContext context) {
    final events = tracking.trackingEvents.reversed.toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tracking.shopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  OrderStatusChip(status: tracking.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'To ${tracking.receiverName}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Packages', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...tracking.packages.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.package,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(p.name)),
                Text(
                  '${p.weightKg} kg',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...events.asMap().entries.map((entry) {
          final isFirst = entry.key == 0;
          return _TimelineTile(
            event: entry.value,
            isLast: entry.key == events.length - 1,
            isCurrent: isFirst,
          );
        }),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isLast,
    required this.isCurrent,
  });

  final OrderTrackingEvent event;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final display = statusDisplayFor(event.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? display.color.withValues(alpha: 0.16)
                      : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  display.icon,
                  size: 15,
                  color: isCurrent ? display.color : AppColors.muted,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.description!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('MMM d, h:mm a').format(event.createdAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
