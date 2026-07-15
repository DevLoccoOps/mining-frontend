import 'package:flutter/material.dart';

enum BadgeColor { green, red, yellow, blue, gray, purple }

class Badge extends StatelessWidget {
  final String label;
  final BadgeColor color;
  const Badge({super.key, required this.label, this.color = BadgeColor.gray});

  static BadgeColor? fromName(String? name) {
    switch (name) {
      case 'green':
        return BadgeColor.green;
      case 'red':
        return BadgeColor.red;
      case 'yellow':
        return BadgeColor.yellow;
      case 'blue':
        return BadgeColor.blue;
      case 'purple':
        return BadgeColor.purple;
      case 'gray':
        return BadgeColor.gray;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pair = _styles[color]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: pair.$1,
        border: Border.all(color: pair.$2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: pair.$3,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

const _styles = <BadgeColor, (Color, Color, Color)>{
  BadgeColor.green: (Color(0xFFDCFCE7), Color(0xFFBBF7D0), Color(0xFF15803D)),
  BadgeColor.red: (Color(0xFFFEE2E2), Color(0xFFFECACA), Color(0xFFB91C1C)),
  BadgeColor.yellow: (Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFB45309)),
  BadgeColor.blue: (Color(0xFFDBEAFE), Color(0xFFBFDBFE), Color(0xFF1D4ED8)),
  BadgeColor.gray: (Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFF475569)),
  BadgeColor.purple: (Color(0xFFEDE9FE), Color(0xFFDDD6FE), Color(0xFF6D28D9)),
};