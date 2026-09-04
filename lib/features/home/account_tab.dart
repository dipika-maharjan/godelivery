import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/order_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/package_info_provider.dart';
import '../../providers/theme_provider.dart';

const _websiteUrl = 'https://godelivery.godokan.com';
const _termsUrl = 'https://godelivery.godokan.com/help/terms-and-conditions';
const _privacyUrl = 'https://godelivery.godokan.com/help/privacy-policies';
const _androidPackageId = 'com.godokan.godelivery';

class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final sentCount = ref
        .watch(ordersProvider(OrderRoleFilter.sent))
        .valueOrNull
        ?.length;
    final receivedCount = ref
        .watch(ordersProvider(OrderRoleFilter.received))
        .valueOrNull
        ?.length;
    final packageInfo = ref.watch(packageInfoProvider).valueOrNull;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          const Text(
            'Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (user?.name.isNotEmpty ?? false)
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (user?.shopName != null)
                        Text(
                          user!.shopName!,
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      Text(
                        user?.phoneNumber ?? '',
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.send,
                  label: 'Sent',
                  value: sentCount?.toString() ?? '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.packageOpen,
                  label: 'Received',
                  value: receivedCount?.toString() ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SentReceivedChart(
            sent: sentCount ?? 0,
            received: receivedCount ?? 0,
          ),
          const SizedBox(height: 24),
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const _ThemeModeSelector(),
          const SizedBox(height: 24),
          _ActionTile(
            icon: LucideIcons.messageSquare,
            label: 'Send feedback',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon.')));
            },
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: LucideIcons.globe,
            label: 'Visit website',
            onTap: () => _openUrl(context, _websiteUrl),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: LucideIcons.star,
            label: 'Rate the app',
            onTap: () => _rateApp(context),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: LucideIcons.fileText,
            label: 'Terms and conditions',
            onTap: () => _openUrl(context, _termsUrl),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: LucideIcons.shieldCheck,
            label: 'Privacy policy',
            onTap: () => _openUrl(context, _privacyUrl),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: LucideIcons.logOut,
            label: 'Log out',
            destructive: true,
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 24),
          if (packageInfo != null)
            Center(
              child: Text(
                'GoDelivery v${packageInfo.version} (${packageInfo.buildNumber})',
                style: TextStyle(
                  color: context.colors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open the link.")));
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final marketLaunched = await launchUrl(
        Uri.parse('market://details?id=$_androidPackageId'),
        mode: LaunchMode.externalApplication,
      );
      if (!marketLaunched) {
        await launchUrl(
          Uri.parse(
            'https://play.google.com/store/apps/details?id=$_androidPackageId',
          ),
          mode: LaunchMode.externalApplication,
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Coming soon.')));
    }
  }

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
            child: const Text(
              'Log out',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.colors.text),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: context.colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Two-bar sent-vs-received comparison. Colors are a validated categorical
/// pair (see dataviz skill) rather than the brand yellow, which is too light
/// to pass as a bare bar fill — `node validate_palette.js "#eda100,#2a78d6"`.
class _SentReceivedChart extends StatelessWidget {
  const _SentReceivedChart({required this.sent, required this.received});

  final int sent;
  final int received;

  static const _sentLight = Color(0xFFEDA100);
  static const _sentDark = Color(0xFFC98500);
  static const _receivedLight = Color(0xFF2A78D6);
  static const _receivedDark = Color(0xFF3987E5);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sentColor = isDark ? _sentDark : _sentLight;
    final receivedColor = isDark ? _receivedDark : _receivedLight;
    final maxValue = [sent, received, 1].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sent vs received',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _ChartBarRow(
            label: 'Sent',
            value: sent,
            maxValue: maxValue,
            color: sentColor,
          ),
          const SizedBox(height: 12),
          _ChartBarRow(
            label: 'Received',
            value: received,
            maxValue: maxValue,
            color: receivedColor,
          ),
        ],
      ),
    );
  }
}

class _ChartBarRow extends StatelessWidget {
  const _ChartBarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: context.colors.text,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: context.colors.cardAlt,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: context.colors.text,
            ),
          ),
        ),
      ],
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
              child: _ThemeModeSegment(
                label: label,
                icon: icon,
                selected: selected == mode,
                onTap: () =>
                    ref.read(themeModeProvider.notifier).setThemeMode(mode),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeModeSegment extends StatelessWidget {
  const _ThemeModeSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
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
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: context.colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
