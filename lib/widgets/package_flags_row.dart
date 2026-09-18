import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_theme.dart';
import '../models/order.dart';

/// Small icon badges for whichever handling flags are set on a package —
/// the same flags that drive the icons on the printed shipping label.
class PackageFlagsRow extends StatelessWidget {
  const PackageFlagsRow({super.key, required this.package});

  final OrderPackage package;

  @override
  Widget build(BuildContext context) {
    final flags = [
      if (package.isFragile) (LucideIcons.wineOff, 'Fragile'),
      if (package.isFlammable) (LucideIcons.flame, 'Flammable'),
      if (package.needsToBeDry) (LucideIcons.umbrella, 'Keep dry'),
      if (package.isDangerous) (LucideIcons.triangleAlert, 'Dangerous'),
    ];
    if (flags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final (icon, label) in flags)
          Tooltip(
            message: label,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.cardAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 12, color: context.colors.textMuted),
            ),
          ),
      ],
    );
  }
}
