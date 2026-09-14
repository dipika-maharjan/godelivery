import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double iconSize;
  final double textSize;
  final bool compact;

  const BrandLogo({
    super.key,
    this.iconSize = 34,
    this.textSize = 26,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 30 : iconSize + 10,
          height: compact ? 30 : iconSize + 10,
          decoration: BoxDecoration(
            color: const Color(0xFFFFCC00),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.local_shipping,
            color: Colors.black,
            size: iconSize,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'GoDelivery',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}
