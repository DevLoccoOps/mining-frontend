import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme/app_theme.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late final Stream<DateTime> _clock;

  @override
  void initState() {
    super.initState();
    _clock = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final app = context.watch<AppState>();
    return LayoutBuilder(
      builder: (context, c) {
        final showShift = c.maxWidth > 760;
        final showClock = c.maxWidth > 640;
        final showProfileName = c.maxWidth > 520;
        final showEmergencyLabel = c.maxWidth > 420;
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: t.card, border: Border(bottom: BorderSide(color: t.border))),
          child: Row(
            children: [
              // Search (shrinks on narrow screens instead of overflowing)
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search personnel, tags, zones…',
                      prefixIcon: Icon(Icons.search, size: 14, color: t.muted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (showShift) ...[
                _chip(
                  context,
                  icon: Icons.calendar_month_outlined,
                  label: 'Day Shift',
                  fg: AppColors.blue,
                  bg: t.isDark ? const Color(0x332563EB) : const Color(0xFFEFF6FF),
                ),
                const SizedBox(width: 8),
              ],
              if (showClock) ...[
                StreamBuilder<DateTime>(
                  stream: _clock,
                  initialData: DateTime.now(),
                  builder: (context, snap) {
                    final time = DateFormat('HH:mm:ss', 'en_ZA').format(snap.data!);
                    return _chip(context, icon: Icons.schedule, label: time, fg: t.muted, bg: t.mutedBg, mono: true);
                  },
                ),
                const SizedBox(width: 8),
              ],
              // Emergency
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Color(0x33DC2626), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 13),
                    if (showEmergencyLabel) ...[
                      const SizedBox(width: 5),
                      const Text('EMERGENCY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Bell
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_rounded, color: t.muted, size: 18),
                    onPressed: () {},
                    splashRadius: 18,
                  ),
                  Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle))),
                ],
              ),
              // Dark toggle
              IconButton(
                icon: Icon(app.darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: t.muted, size: 18),
                onPressed: app.toggleDarkMode,
                splashRadius: 18,
              ),
              const SizedBox(width: 4),
              // Profile
              TextButton.icon(
                onPressed: app.logout,
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                  child: const Center(child: Text('JA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                ),
                label: Row(
                  children: [
                    if (showProfileName)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('James Adams', style: TextStyle(color: t.fg, fontSize: 12, fontWeight: FontWeight.w600, height: 1.1)),
                          Text('Administrator', style: TextStyle(color: t.muted, fontSize: 10, height: 1.2)),
                        ],
                      ),
                    const SizedBox(width: 6),
                    Icon(Icons.logout, color: t.muted, size: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(BuildContext context, {required IconData icon, required String label, required Color fg, required Color bg, bool mono = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: fg, fontFamily: mono ? 'monospace' : null, fontWeight: mono ? FontWeight.w500 : FontWeight.w500)),
        ],
      ),
    );
  }
}