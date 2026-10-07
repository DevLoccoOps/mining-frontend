import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/live_service.dart';
import '../core/page_type.dart';
import '../theme/app_theme.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late final Stream<DateTime> _clock;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clock = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAlerts(BuildContext context) {
    context.read<AppState>().setPage(PageKey.alerts);
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final app = context.watch<AppState>();
    final live = context.watch<LiveService>();
    return LayoutBuilder(
      builder: (context, c) {
        final showConn = c.maxWidth > 760;
        final showClock = c.maxWidth > 640;
        final showProfileName = c.maxWidth > 520;
        final showEmergencyLabel = c.maxWidth > 420;
        final emergencyCount =
            live.state.alerts.where((a) => a.type == 'critical' || a.type == 'danger').length;
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: t.card, border: Border(bottom: BorderSide(color: t.border))),
          child: Row(
            children: [
              // Search — feeds the global query consumed by Live Tracking.
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search personnel, tags, zones…',
                      prefixIcon: Icon(Icons.search, size: 14, color: t.muted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: app.setSearch,
                    onSubmitted: (_) => app.setPage(PageKey.liveTracking),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (showConn) ...[
                _connChip(context, live, t),
                const SizedBox(width: 8),
              ],
              const Spacer(),
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
              // Emergency — jumps straight to the live Alerts page.
              Tooltip(
                message: 'View live alerts',
                child: InkWell(
                  onTap: () => _openAlerts(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
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
                          const Text('EMERGENCY',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                        if (emergencyCount > 0) ...[
                          const SizedBox(width: 5),
                          Text('$emergencyCount',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bell — badge shows the real live alert count; hidden when zero.
              Semantics(
                label: emergencyCount > 0
                    ? 'Notifications. $emergencyCount active alerts.'
                    : 'Notifications. No active alerts.',
                child: IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications_none_rounded, color: t.muted, size: 18),
                      if (emergencyCount > 0)
                        Positioned(
                          top: -2,
                          right: -4,
                          child: ExcludeSemantics(
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(minWidth: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$emergencyCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => _openAlerts(context),
                  tooltip: 'Notifications',
                ),
              ),
              // Dark toggle
              IconButton(
                icon: Icon(app.darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: t.muted, size: 18),
                onPressed: app.toggleDarkMode,
                tooltip: app.darkMode ? 'Switch to light mode' : 'Switch to dark mode',
              ),
              const SizedBox(width: 4),
              // Local session — no fake user identity; the button signs out.
              TextButton.icon(
                onPressed: app.logout,
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                  child: const Center(
                    child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 15),
                  ),
                ),
                label: Row(
                  children: [
                    if (showProfileName)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Operator', style: TextStyle(color: t.fg, fontSize: 12, fontWeight: FontWeight.w600, height: 1.1)),
                          Text('Local session', style: TextStyle(color: t.muted, fontSize: 10, height: 1.2)),
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

  /// Real connection status chip — replaces the hardcoded "Day Shift".
  Widget _connChip(BuildContext context, LiveService live, SurfaceTokens t) {
    final (color, label, icon) = switch (live.status) {
      ConnStatus.live => (AppColors.green, 'LIVE', Icons.check_circle_rounded),
      ConnStatus.connecting => (AppColors.amber, 'CONNECTING', Icons.sync_rounded),
      ConnStatus.offline => (AppColors.red, 'OFFLINE', Icons.error_outline_rounded),
    };
    return _chip(
      context,
      icon: icon,
      label: label,
      fg: color,
      bg: t.isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
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