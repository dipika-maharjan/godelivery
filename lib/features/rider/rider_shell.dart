import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'deliveries/my_deliveries_page.dart';
import 'earnings/rider_earnings_page.dart';
import 'jobs/available_jobs_page.dart';
import 'profile/rider_profile_page.dart';

enum RiderTab { jobs, deliveries, earnings, profile }

class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  RiderTab _tab = RiderTab.jobs;
  late final PageController _pageController = PageController(initialPage: _tab.index);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(RiderTab tab) {
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
