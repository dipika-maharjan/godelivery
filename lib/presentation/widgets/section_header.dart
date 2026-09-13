import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final String? actionLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.onPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onPressed,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
