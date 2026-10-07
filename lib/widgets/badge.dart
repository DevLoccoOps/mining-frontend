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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pair = (dark ? _darkStyles : _lightStyles)[color]!;
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

const _lightStyles = <BadgeColor, (Color, Color, Color)>{
  BadgeColor.green: (Color(0xFFDCFCE7), Color(0xFFBBF7D0), Color(0xFF15803D)),
  BadgeColor.red: (Color(0xFFFEE2E2), Color(0xFFFECACA), Color(0xFFB91C1C)),
  BadgeColor.yellow: (Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFB45309)),
  BadgeColor.blue: (Color(0xFFDBEAFE), Color(0xFFBFDBFE), Color(0xFF1D4ED8)),
  BadgeColor.gray: (Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFF475569)),
  BadgeColor.purple: (Color(0xFFEDE9FE), Color(0xFFDDD6FE), Color(0xFF6D28D9)),
};

// Dark variants: translucent tint + bright foreground so badges sit on dark
// surfaces instead of rendering as bright light-mode chips.
const _darkStyles = <BadgeColor, (Color, Color, Color)>{
  BadgeColor.green: (Color(0x1A22C55E), Color(0x3322C55E), Color(0xFF4ADE80)),
  BadgeColor.red: (Color(0x1AEF4444), Color(0x33EF4444), Color(0xFFF87171)),
  BadgeColor.yellow: (Color(0x1AF59E0B), Color(0x33F59E0B), Color(0xFFFBBF24)),
  BadgeColor.blue: (Color(0x1A3B82F6), Color(0x333B82F6), Color(0xFF60A5FA)),
  BadgeColor.gray: (Color(0x1A64748B), Color(0x3364748B), Color(0xFF94A3B8)),
  BadgeColor.purple: (Color(0x1A7C3AED), Color(0x337C3AED), Color(0xFFA78BFA)),
};