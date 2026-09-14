import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'more/admin_more_page.dart';
import 'orders/admin_orders_page.dart';
import 'payouts/admin_payouts_page.dart';
import 'riders/admin_riders_page.dart';

enum AdminTab { orders, riders, payouts, more }

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminTab _tab = AdminTab.orders;
  late final PageController _pageController = PageController(initialPage: _tab.index);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(AdminTab tab) {
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
            onPageChanged: (index) => setState(() => _tab = AdminTab.values[index]),
            children: const [
              AdminOrdersPage(),
              AdminRidersPage(),
              AdminPayoutsPage(),
              AdminMorePage(),
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

  final AdminTab current;
  final ValueChanged<AdminTab> onChanged;

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
            icon: LucideIcons.package,
            label: 'Orders',
            selected: current == AdminTab.orders,
            onTap: () => onChanged(AdminTab.orders),
          ),
          _NavItem(
            icon: LucideIcons.bike,
            label: 'Riders',
            selected: current == AdminTab.riders,
            onTap: () => onChanged(AdminTab.riders),
          ),
          _NavItem(
            icon: LucideIcons.banknote,
            label: 'Payouts',
            selected: current == AdminTab.payouts,
            onTap: () => onChanged(AdminTab.payouts),
          ),
          _NavItem(
            icon: LucideIcons.menu,
            label: 'More',
            selected: current == AdminTab.more,
            onTap: () => onChanged(AdminTab.more),
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
