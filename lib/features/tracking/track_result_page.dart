import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/share_helper.dart';
import '../../core/utils/status_display.dart';
import '../../models/order.dart';
import '../../models/tracking.dart';
import '../../providers/tracking_provider.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/package_flags_row.dart';

const _trackingWebBaseUrl = 'https://godelivery.godokan.com/track';

class TrackResultPage extends ConsumerStatefulWidget {
  const TrackResultPage({super.key, required this.trackingNumber});

  final String trackingNumber;

  @override
  ConsumerState<TrackResultPage> createState() => _TrackResultPageState();
}

class _TrackResultPageState extends ConsumerState<TrackResultPage> {
  final _snapshotKey = GlobalKey();
  bool _sharingSnapshot = false;

  String _shareText(PublicTracking tracking) {
    final display = statusDisplayFor(tracking.status);
    return 'Track my GoDelivery shipment ${widget.trackingNumber} '
        '(${display.label}): $_trackingWebBaseUrl/${widget.trackingNumber}';
  }

  Future<void> _share(PublicTracking tracking) {
    return shareText(_shareText(tracking), subject: 'GoDelivery tracking');
  }

  Future<void> _shareSnapshot(PublicTracking tracking) async {
    if (_sharingSnapshot) return;
    setState(() => _sharingSnapshot = true);
    try {
      await shareWidgetSnapshot(
        _snapshotKey,
        fileName: '${widget.trackingNumber}.png',
        text: _shareText(tracking),
        subject: 'GoDelivery tracking',
      );
    } finally {
      if (mounted) setState(() => _sharingSnapshot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(trackingProvider(widget.trackingNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trackingNumber),
        actions: [
          ...result.maybeWhen(
            data: (tracking) => [
              IconButton(
                tooltip: 'Share',
                onPressed: () => _share(tracking),
                icon: const Icon(LucideIcons.share2),
              ),
              IconButton(
                tooltip: 'Share snapshot',
                onPressed: _sharingSnapshot ? null : () => _shareSnapshot(tracking),
                icon: _sharingSnapshot
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.camera),
              ),
            ],
            orElse: () => const [],
          ),
        ],
      ),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(trackingProvider(widget.trackingNumber)),
        ),
        data: (tracking) => RepaintBoundary(
          key: _snapshotKey,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: _TrackingBody(tracking: tracking),
          ),
        ),
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
            Icon(
              LucideIcons.packageX,
              size: 44,
              color: context.colors.textMuted,
            ),
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
            color: context.colors.card,
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
                style: TextStyle(color: context.colors.textMuted, fontSize: 13),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.package,
                      size: 16,
                      color: context.colors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.name)),
                    Text(
                      '${p.weightKg} kg',
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: PackageFlagsRow(package: p),
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
                      : context.colors.cardAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  display.icon,
                  size: 15,
                  color: isCurrent ? display.color : context.colors.textMuted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: context.colors.border),
                ),
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
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('MMM d, h:mm a').format(event.createdAt),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.colors.textMuted,
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
