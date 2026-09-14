import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../api_keys/api_keys_page.dart';
import '../pricing/admin_pricing_rules_page.dart';
import '../users/admin_users_page.dart';
import '../warehouses/admin_warehouses_page.dart';

class AdminMorePage extends ConsumerWidget {
  const AdminMorePage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          "You'll need to verify your phone number again to sign back in.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            'More',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        user?.phoneNumber ?? '',
                        style: TextStyle(color: context.colors.textMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ActionTile(
            icon: LucideIcons.warehouse,
            label: 'Warehouses',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminWarehousesPage()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: LucideIcons.receipt,
            label: 'Pricing rules',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminPricingRulesPage()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: LucideIcons.users,
            label: 'Users',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminUsersPage()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: LucideIcons.key,
            label: 'API keys',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ApiKeysPage()),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Appearance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          const _ThemeModeSelector(),
          const SizedBox(height: 24),
          _ActionTile(
            icon: LucideIcons.logOut,
            label: 'Log out',
            destructive: true,
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  static const _options = [
    (ThemeMode.system, 'System', LucideIcons.smartphone),
    (ThemeMode.light, 'Light', LucideIcons.sun),
    (ThemeMode.dark, 'Dark', LucideIcons.moon),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          for (final (mode, label, icon) in _options)
            Expanded(
              child: InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == mode ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: selected == mode ? AppColors.onPrimary : context.colors.text,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: selected == mode ? AppColors.onPrimary : context.colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : context.colors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}
