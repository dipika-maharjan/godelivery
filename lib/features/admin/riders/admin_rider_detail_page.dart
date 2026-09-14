import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/riders_repository.dart';
import '../../../models/rider.dart';
import '../../../providers/admin_riders_provider.dart';
import '../../../widgets/app_text_field.dart';

class AdminRiderDetailPage extends ConsumerStatefulWidget {
  const AdminRiderDetailPage({super.key, required this.riderId});

  final String riderId;

  @override
  ConsumerState<AdminRiderDetailPage> createState() => _AdminRiderDetailPageState();
}

class _AdminRiderDetailPageState extends ConsumerState<AdminRiderDetailPage> {
  Rider? _rider;
  bool _loading = true;
  bool _acting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rider = await ref.read(ridersRepositoryProvider).getOne(widget.riderId);
      if (!mounted) return;
      setState(() {
        _rider = rider;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive() async {
    final rider = _rider;
    if (rider == null || _acting) return;
    setState(() => _acting = true);
    try {
      final updated = await ref
          .read(ridersRepositoryProvider)
          .update(rider.id, isActive: !rider.isActive);
      if (!mounted) return;
      setState(() => _rider = updated);
      await ref.read(adminRidersProvider.notifier).refresh();
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not update the rider.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _editVehicle() async {
    final rider = _rider;
    if (rider == null) return;
    final result = await showModalBottomSheet<_VehicleEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditVehicleSheet(rider: rider),
    );
    if (result == null) return;
    setState(() => _acting = true);
    try {
      final updated = await ref.read(ridersRepositoryProvider).update(
            rider.id,
            name: result.name,
            vehicleType: result.vehicleType,
            vehiclePlateNumber: result.plateNumber,
          );
      if (!mounted) return;
      setState(() => _rider = updated);
      await ref.read(adminRidersProvider.notifier).refresh();
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not update the rider.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rider = _rider;
    return Scaffold(
      appBar: AppBar(title: Text(rider?.name ?? 'Rider')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : rider == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rider.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ),
                      _StatusBadge(
                        label: rider.isActive ? 'Active' : 'Suspended',
                        color: rider.isActive ? AppColors.success : AppColors.danger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rider.phoneNumber,
                    style: TextStyle(color: context.colors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        icon: LucideIcons.bike,
                        label: vehicleTypeLabel(rider.vehicleType),
                      ),
                      if (rider.vehiclePlateNumber != null)
                        _InfoPill(icon: LucideIcons.idCard, label: rider.vehiclePlateNumber!),
                      _InfoPill(
                        icon: rider.isAvailable
                            ? LucideIcons.circleCheck
                            : LucideIcons.circle,
                        label: rider.isAvailable ? 'Available' : 'Unavailable',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _acting ? null : _editVehicle,
                        child: const Text('Edit vehicle info'),
                      ),
                      OutlinedButton(
                        onPressed: _acting ? null : _toggleActive,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: rider.isActive ? AppColors.danger : null,
                          side: rider.isActive
                              ? const BorderSide(color: AppColors.danger)
                              : null,
                        ),
                        child: Text(rider.isActive ? 'Suspend' : 'Reactivate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Metrics', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, _) {
                      final metrics = ref.watch(riderMetricsProvider(rider.id));
                      return metrics.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        ),
                        error: (_, _) => Text(
                          'Could not load metrics.',
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                        data: (m) => Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                label: 'Deliveries',
                                value: '${m.totalDeliveries}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                label: 'Avg. duration',
                                value: m.averageDeliveryDurationMinutes == null
                                    ? '—'
                                    : '${m.averageDeliveryDurationMinutes!.round()} min',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Bank account', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, _) {
                      final bankAccount = ref.watch(riderBankAccountProvider(rider.id));
                      return bankAccount.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        ),
                        error: (_, _) => Text(
                          'Could not load bank details.',
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                        data: (account) => account == null
                            ? Text(
                                'No bank account on file yet.',
                                style: TextStyle(color: context.colors.textMuted),
                              )
                            : Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.colors.card,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.bankName,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${account.accountName} · ${account.accountNumber}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: context.colors.textMuted,
                                      ),
                                    ),
                                    if (account.branch != null)
                                      Text(
                                        account.branch!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.colors.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Unpaid deliveries', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, _) {
                      final unpaid = ref.watch(riderUnpaidDeliveriesProvider(rider.id));
                      return unpaid.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        ),
                        error: (_, _) => Text(
                          'Could not load unpaid deliveries.',
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                        data: (data) {
                          if (data.orders.isEmpty) {
                            return Text(
                              'Nothing owed right now.',
                              style: TextStyle(color: context.colors.textMuted),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total owed: ${data.totalAmountOwed} ${data.currency}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              ...data.orders.map(
                                (o) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(o.trackingNumber)),
                                      Text(
                                        '${o.amount} ${o.currency}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: context.colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _VehicleEdit {
  const _VehicleEdit({required this.name, required this.vehicleType, this.plateNumber});

  final String name;
  final VehicleType vehicleType;
  final String? plateNumber;
}

class _EditVehicleSheet extends StatefulWidget {
  const _EditVehicleSheet({required this.rider});

  final Rider rider;

  @override
  State<_EditVehicleSheet> createState() => _EditVehicleSheetState();
}

class _EditVehicleSheetState extends State<_EditVehicleSheet> {
  late final _nameController = TextEditingController(text: widget.rider.name);
  late final _plateController =
      TextEditingController(text: widget.rider.vehiclePlateNumber);
  late VehicleType _vehicleType = widget.rider.vehicleType;

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit vehicle info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            AppTextField(controller: _nameController, label: 'Name'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.colors.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VehicleType>(
                  value: _vehicleType,
                  isExpanded: true,
                  items: [
                    for (final type in VehicleType.values)
                      DropdownMenuItem(value: type, child: Text(vehicleTypeLabel(type))),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _vehicleType = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _plateController, label: 'Plate number'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _nameController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                          _VehicleEdit(
                            name: _nameController.text.trim(),
                            vehicleType: _vehicleType,
                            plateNumber: _plateController.text.trim().isEmpty
                                ? null
                                : _plateController.text.trim(),
                          ),
                        ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.cardAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.text),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ],
      ),
    );
  }
}
