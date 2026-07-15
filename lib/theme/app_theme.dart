import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const blue = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const sidebarBg = Color(0xFF0B1F3A);
  static const sidebarBorder = Color(0x11FFFFFF);
  static const tunnelBg = Color(0xFF0E2035);
  static const loginBg = Color(0xFF05101E);

  // Semantic
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFF7C3AED);
  static const teal = Color(0xFF14B8A6);
  static const gray = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData light() {
    const bg = Color(0xFFF8FAFC);
    const card = Colors.white;
    const fg = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    const border = Color(0xFFE2E8F0);
    const mutedBg = Color(0xFFF1F5F9);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: border,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: fg, fontSize: 14),
        bodyMedium: TextStyle(color: fg, fontSize: 13),
        bodySmall: TextStyle(color: muted, fontSize: 12),
        titleLarge: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: muted, fontSize: 11),
      ),
      iconTheme: const IconThemeData(color: fg, size: 16),
      appBarTheme: const AppBarTheme(
        backgroundColor: card,
        foregroundColor: fg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.blue),
      ),
      colorScheme: const ColorScheme.light(
        background: bg,
        surface: card,
        onSurface: fg,
        primary: AppColors.blue,
        outline: border,
      ),
    );
  }

  static ThemeData dark() {
    const bg = Color(0xFF0B1220);
    const card = Color(0xFF121A2B);
    const fg = Color(0xFFE2E8F0);
    const muted = Color(0xFF94A3B8);
    const border = Color(0xFF1E293B);
    const mutedBg = Color(0xFF16213A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: border,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: fg, fontSize: 14),
        bodyMedium: TextStyle(color: fg, fontSize: 13),
        bodySmall: TextStyle(color: muted, fontSize: 12),
        titleLarge: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: muted, fontSize: 11),
      ),
      iconTheme: const IconThemeData(color: fg, size: 16),
      appBarTheme: const AppBarTheme(
        backgroundColor: card,
        foregroundColor: fg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.blue),
      ),
      colorScheme: const ColorScheme.dark(
        background: bg,
        surface: card,
        onSurface: fg,
        primary: AppColors.blue,
        outline: border,
      ),
    );
  }
}

/// Theme-derived tokens used across widgets.
class SurfaceTokens {
  final Color card;
  final Color bg;
  final Color fg;
  final Color muted;
  final Color border;
  final Color mutedBg;
  final bool isDark;
  const SurfaceTokens(this.card, this.bg, this.fg, this.muted, this.border, this.mutedBg, this.isDark);
}

SurfaceTokens tokensOf(BuildContext context) {
  final c = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return SurfaceTokens(
    c.surface,
    c.background,
    c.onSurface,
    Theme.of(context).textTheme.bodySmall!.color!,
    c.outline,
    isDark ? const Color(0xFF16213A) : const Color(0xFFF1F5F9),
    isDark,
  );
}