import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum KpiColor { blue, green, red, yellow, purple, teal, gray }

class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final KpiColor color;
  final TrendArrow? trend;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.color = KpiColor.blue,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    // Light-mode pastel tints glare on dark surfaces; use translucent chips + bright fg instead.
    final iconBg = (t.isDark ? _iconBgDark : _iconBgLight)[color]!;
    final iconFg = (t.isDark ? _iconFgDark : _iconFgLight)[color]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: iconFg),
          ),
          const SizedBox(width: 12),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: t.fg,
                    height: 1.1,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (trend == TrendArrow.up)
                        Icon(Icons.trending_up, size: 11, color: AppColors.green)
                      else if (trend == TrendArrow.down)
                        Icon(Icons.trending_down, size: 11, color: AppColors.red),
                      if (trend != null) const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          sub!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: t.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum TrendArrow { up, down, neutral }

const _iconBgLight = <KpiColor, Color>{
  KpiColor.blue: Color(0xFFEFF6FF),
  KpiColor.green: Color(0xFFF0FDF4),
  KpiColor.red: Color(0xFFFEF2F2),
  KpiColor.yellow: Color(0xFFFFFBEB),
  KpiColor.purple: Color(0xFFF5F3FF),
  KpiColor.teal: Color(0xFFF0FDFA),
  KpiColor.gray: Color(0xFFF8FAFC),
};

const _iconFgLight = <KpiColor, Color>{
  KpiColor.blue: Color(0xFF2563EB),
  KpiColor.green: Color(0xFF16A34A),
  KpiColor.red: Color(0xFFDC2626),
  KpiColor.yellow: Color(0xFFD97706),
  KpiColor.purple: Color(0xFF7C3AED),
  KpiColor.teal: Color(0xFF0D9488),
  KpiColor.gray: Color(0xFF64748B),
};

const _iconBgDark = <KpiColor, Color>{
  KpiColor.blue: Color(0x1A2563EB),
  KpiColor.green: Color(0x1A16A34A),
  KpiColor.red: Color(0x1ADC2626),
  KpiColor.yellow: Color(0x1AD97706),
  KpiColor.purple: Color(0x1A7C3AED),
  KpiColor.teal: Color(0x1A0D9488),
  KpiColor.gray: Color(0x1A64748B),
};

const _iconFgDark = <KpiColor, Color>{
  KpiColor.blue: Color(0xFF60A5FA),
  KpiColor.green: Color(0xFF4ADE80),
  KpiColor.red: Color(0xFFF87171),
  KpiColor.yellow: Color(0xFFFBBF24),
  KpiColor.purple: Color(0xFFA78BFA),
  KpiColor.teal: Color(0xFF2DD4BF),
  KpiColor.gray: Color(0xFF94A3B8),
};