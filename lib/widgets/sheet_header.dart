import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A title row with a close (X) button, for the top of a bottom sheet —
/// dragging down or tapping outside also dismiss it, but that's not always
/// obvious, especially on a sheet that otherwise only has a "Save"-style
/// button.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.style});

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: style ?? Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.x, size: 20),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Close',
        ),
      ],
    );
  }
}
