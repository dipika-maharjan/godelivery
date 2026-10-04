import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/admin_user.dart';
import '../../../models/user.dart';
import '../../../providers/admin_users_provider.dart';
import '../../../widgets/app_text_field.dart';
import 'admin_user_detail_page.dart';
import 'create_admin_page.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(adminUsersFilterProvider.notifier).update(
      (state) => AdminUsersFilter(
        role: state.role,
        search: value.trim().isEmpty ? null : value.trim(),
      ),
    );
  }

  void _setRole(UserRole? role) {
    final current = ref.read(adminUsersFilterProvider);
    ref.read(adminUsersFilterProvider.notifier).state = AdminUsersFilter(
      role: role,
      search: current.search,
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);
    final filter = ref.watch(adminUsersFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            tooltip: 'Create admin',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateAdminPage()),
            ),
            icon: const Icon(LucideIcons.userPlus),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search name, phone, email, or shop',
              prefix: Icon(LucideIcons.search, size: 18, color: context.colors.textMuted),
              onChanged: _onSearchChanged,
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
                  selected: filter.role == null,
                  onTap: () => _setRole(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Customers',
                  selected: filter.role == UserRole.customer,
                  onTap: () => _setRole(UserRole.customer),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Riders',
                  selected: filter.role == UserRole.rider,
                  onTap: () => _setRole(UserRole.rider),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Admins',
                  selected: filter.role == UserRole.admin,
                  onTap: () => _setRole(UserRole.admin),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(adminUsersProvider.notifier).refresh(),
              child: users.when(
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
                        Icon(LucideIcons.users, size: 44, color: context.colors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No accounts match this filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _UserTile(user: list[index]),
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

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final AdminUserSummary user;

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (user.role) {
      UserRole.customer => 'Customer',
      UserRole.rider => 'Rider',
      UserRole.admin => 'Admin',
    };
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminUserDetailPage(userId: user.id)),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.shopName ?? user.phoneNumber,
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.cardAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roleLabel,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
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
