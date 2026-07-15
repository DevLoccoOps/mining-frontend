import 'dart:ui';

/// Battery percentage -> color (green / amber / red).
int batteryColor(int v) {
  if (v > 60) return 0xFF22C55E;
  if (v > 30) return 0xFFF59E0B;
  return 0xFFEF4444;
}

/// dBm signal -> label.
String signalLabel(int v) {
  if (v > -65) return "Strong";
  if (v > -75) return "Good";
  return "Weak";
}

Color argb(int hex) => Color(hex);