import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/notifications/push_notifications_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/notifications_provider.dart';
import 'deliveries/my_deliveries_page.dart';
import 'earnings/rider_earnings_page.dart';
import 'jobs/available_jobs_page.dart';
import 'profile/rider_profile_page.dart';

enum RiderTab { jobs, deliveries, earnings, profile }

class RiderShell extends ConsumerStatefulWidget {
  const RiderShell({super.key});

  @override
  ConsumerState<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends ConsumerState<RiderShell> {
  RiderTab _tab = RiderTab.jobs;
  late final PageController _pageController = PageController(initialPage: _tab.index);

  @override
  void initState() {
    super.initState();
    // Riders need push just as much as customers do — assignment and status
    // pushes are how they find out about new jobs without polling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationsServiceProvider).initialize();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(RiderTab tab) {
    if (tab != _tab) HapticFeedback.selectionClick();
    setState(() => _tab = tab);
    _pageController.animateToPage(
      tab.index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _tab = RiderTab.values[index]),
            children: const [
              AvailableJobsPage(),
              MyDeliveriesPage(),
              RiderEarningsPage(),
              RiderProfilePage(),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 20,
            child: const _NotificationBellButton(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(child: _NavPill(current: _tab, onChanged: _goToTab)),
          ),
        ],
      ),
    );
  }
}

class _NotificationBellButton extends ConsumerWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return InkWell(
      onTap: () => context.push('/rider/notifications'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.card,
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: context.colors.shadowSoft,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(LucideIcons.bell, size: 19, color: context.colors.text),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 2,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 15),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({required this.current, required this.onChanged});

  final RiderTab current;
  final ValueChanged<RiderTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadowSoft,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavItem(
            icon: LucideIcons.packageSearch,
            label: 'Jobs',
            selected: current == RiderTab.jobs,
            onTap: () => onChanged(RiderTab.jobs),
          ),
          _NavItem(
            icon: LucideIcons.bike,
            label: 'Deliveries',
            selected: current == RiderTab.deliveries,
            onTap: () => onChanged(RiderTab.deliveries),
          ),
          _NavItem(
            icon: LucideIcons.banknote,
            label: 'Earnings',
            selected: current == RiderTab.earnings,
            onTap: () => onChanged(RiderTab.earnings),
          ),
          _NavItem(
            icon: LucideIcons.user,
            label: 'Profile',
            selected: current == RiderTab.profile,
            onTap: () => onChanged(RiderTab.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : context.colors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: color),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
