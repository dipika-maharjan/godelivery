import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/admin_users_repository.dart';
import '../../../models/admin_user.dart';
import '../../../models/user.dart';
import '../../../providers/admin_users_provider.dart';
import '../../../widgets/app_text_field.dart';

class AdminUserDetailPage extends ConsumerWidget {
  const AdminUserDetailPage({super.key, required this.userId});

  final String userId;

  Future<void> _edit(BuildContext context, WidgetRef ref, AdminUserDetail user) async {
    final result = await showModalBottomSheet<_UserEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditUserSheet(user: user),
    );
    if (result == null) return;
    try {
      await ref.read(adminUsersRepositoryProvider).updateOne(
            user.id,
            name: result.name,
            shopName: result.shopName,
            email: result.email,
          );
      ref.invalidate(adminUserDetailProvider(user.id));
      await ref.read(adminUsersProvider.notifier).refresh();
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not update the account.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(adminUserDetailProvider(userId));
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiException ? error.message : 'Something went wrong.'),
        ),
        data: (value) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    value.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                _RoleBadge(role: value.role),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value.phoneNumber,
              style: TextStyle(color: context.colors.textMuted, fontSize: 13),
            ),
            if (value.email != null)
              Text(
                value.email!,
                style: TextStyle(color: context.colors.textMuted, fontSize: 13),
              ),
            if (value.shopName != null) ...[
              const SizedBox(height: 10),
              _InfoRow(icon: LucideIcons.store, label: value.shopName!),
            ],
            if (value.shopLocation != null) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: LucideIcons.mapPin, label: value.shopLocation!.addressLine),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _edit(context, ref, value),
              child: const Text('Edit profile'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _CountTile(label: 'Sent', value: value.sentOrdersCount),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountTile(label: 'Received', value: value.receivedOrdersCount),
                ),
                if (value.riderProfile != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CountTile(label: 'Deliveries', value: value.riderOrdersCount),
                  ),
                ],
              ],
            ),
            if (value.riderProfile != null) ...[
              const SizedBox(height: 20),
              Text('Rider profile', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    label: value.riderProfile!.isActive ? 'Active' : 'Suspended',
                  ),
                  _InfoPill(
                    label: value.riderProfile!.isAvailable ? 'Available' : 'Unavailable',
                  ),
                  if (value.riderProfile!.vehiclePlateNumber != null)
                    _InfoPill(label: value.riderProfile!.vehiclePlateNumber!),
                ],
              ),
            ],
            if (value.recentSentOrders.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Recent sent orders', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...value.recentSentOrders.map((o) => _OrderRow(order: o)),
            ],
            if (value.recentReceivedOrders.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Recent received orders', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...value.recentReceivedOrders.map((o) => _OrderRow(order: o)),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserEdit {
  const _UserEdit({required this.name, this.shopName, this.email});

  final String name;
  final String? shopName;
  final String? email;
}

class _EditUserSheet extends StatefulWidget {
  const _EditUserSheet({required this.user});

  final AdminUserDetail user;

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _shopNameController = TextEditingController(text: widget.user.shopName);
  late final _emailController = TextEditingController(text: widget.user.email);

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _emailController.dispose();
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
            Text('Edit profile', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            AppTextField(controller: _nameController, label: 'Name'),
            const SizedBox(height: 12),
            AppTextField(controller: _shopNameController, label: 'Shop name'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _nameController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                          _UserEdit(
                            name: _nameController.text.trim(),
                            shopName: _shopNameController.text.trim().isEmpty
                                ? null
                                : _shopNameController.text.trim(),
                            email: _emailController.text.trim().isEmpty
                                ? null
                                : _emailController.text.trim(),
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      UserRole.customer => 'Customer',
      UserRole.rider => 'Rider',
      UserRole.admin => 'Admin',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.cardAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: context.colors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, color: context.colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.cardAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.value});

  final String label;
  final int value;

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
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final AdminUserOrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(LucideIcons.package, size: 15, color: context.colors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(order.trackingNumber)),
          Text(
            DateFormat('MMM d').format(order.createdAt),
            style: TextStyle(fontSize: 12, color: context.colors.textMuted),
          ),
          const SizedBox(width: 8),
          Text(
            '${order.amount} ${order.currency}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
