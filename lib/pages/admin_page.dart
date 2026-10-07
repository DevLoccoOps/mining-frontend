import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/live_service.dart';
import '../core/page_type.dart';
import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';

/// Administration — an honest hub: every card links to a page that is actually
/// wired to the backend, and the system facts card shows real /api/stats data.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final stats = live.stats;

    // Every entry navigates to a real, live-data page — nothing decorative.
    final links = <(IconData, PageKey, String, String)>[
      (Icons.group, PageKey.personnel, 'Personnel', 'Register staff, assign tags, manage roles'),
      (Icons.tag, PageKey.bleDevices, 'BLE Tags', 'Register and remove tracking tags'),
      (Icons.wifi, PageKey.gateways, 'Gateways', 'Live gateway liveness and carried-miner counts'),
      (Icons.map_outlined, PageKey.mineZones, 'Mine Zones', 'Zone occupancy, temperature and alert state'),
      (Icons.warning_amber_rounded, PageKey.alerts, 'Alerts', 'Live alert queue with acknowledge'),
      (Icons.calendar_month, PageKey.shifts, 'Shifts', 'Personnel grouped by shift with live status'),
      (Icons.dns, PageKey.systemHealth, 'System Health', 'Backend uptime, connections and data volumes'),
      (Icons.settings, PageKey.settings, 'Settings', 'Appearance and display preferences'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Administration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
          Text('Manage the live tracking system', style: TextStyle(fontSize: 13, color: t.muted)),
          const SizedBox(height: 20),
          _factsCard(t, live, stats),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1280 ? 4 : c.maxWidth > 760 ? 2 : 1;
              const spacing = 16.0;
              final cards = links.map((l) => _linkCard(l, t, context)).toList();
              final List<Widget> rows = [];
              for (var i = 0; i < cards.length; i += cols) {
                final rowChildren = <Widget>[];
                for (var j = i; j < cards.length && j < i + cols; j++) {
                  if (rowChildren.isNotEmpty) rowChildren.add(const SizedBox(width: spacing));
                  rowChildren.add(Expanded(child: cards[j]));
                }
                final remainder = cards.length - i;
                if (remainder < cols) {
                  for (var k = 0; k < cols - remainder; k++) {
                    rowChildren.add(const SizedBox(width: spacing));
                    rowChildren.add(const Expanded(child: SizedBox()));
                  }
                }
                if (rows.isNotEmpty) rows.add(const SizedBox(height: spacing));
                rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren));
              }
              return Column(mainAxisSize: MainAxisSize.min, children: rows);
            },
          ),
          const SizedBox(height: 20),
          _notYetCard(t),
        ],
      ),
    );
  }

  /// Real system facts from GET /api/stats — no invented numbers.
  Widget _factsCard(SurfaceTokens t, LiveService live, StatsSnapshot s) {
    final up = s.uptimeSeconds;
    final uptime = up > 0
        ? up >= 86400
            ? '${(up / 86400).toStringAsFixed(1)} days'
            : up >= 3600
                ? '${(up / 3600).toStringAsFixed(1)} h'
                : '${(up / 60).toStringAsFixed(0)} min'
        : '—';
    final facts = <(IconData, String, String)>[
      (Icons.schedule, 'Backend Uptime', uptime),
      (Icons.location_on, 'Personnel Underground', '${s.liveMiners}'),
      (Icons.wifi, 'Active Gateways', '${s.activeGateways}'),
      (Icons.person, 'Personnel Registered', '${s.personnelCount}'),
      (Icons.tag, 'Tags Registered', '${s.tagCount}'),
      (Icons.warning_amber_rounded, 'Alerts Logged', '${s.alertLogCount}'),
      (Icons.storage, 'Telemetry Records', '${s.telemetryCount}'),
      (Icons.devices, 'Dashboard Clients', '${s.wsClients}'),
    ];
    return Container(
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text('System Facts — live from the backend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                const Spacer(),
                Badge(
                  label: live.status == ConnStatus.live ? 'Live' : live.status == ConnStatus.connecting ? 'Connecting' : 'Offline',
                  color: live.status == ConnStatus.live
                      ? BadgeColor.green
                      : live.status == ConnStatus.connecting
                          ? BadgeColor.yellow
                          : BadgeColor.red,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 1024 ? 4 : 2;
                const spacing = 12.0;
                final List<Widget> rows = [];
                for (var i = 0; i < facts.length; i += cols) {
                  final rowChildren = <Widget>[];
                  for (var j = i; j < facts.length && j < i + cols; j++) {
                    if (rowChildren.isNotEmpty) rowChildren.add(const SizedBox(width: spacing));
                    rowChildren.add(Expanded(
                      child: Row(
                        children: [
                          Icon(facts[j].$1, size: 14, color: AppColors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(facts[j].$2,
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: t.muted)),
                          ),
                          const SizedBox(width: 8),
                          Text(facts[j].$3,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg, fontFamily: 'monospace')),
                        ],
                      ),
                    ));
                  }
                  if (rows.isNotEmpty) rows.add(const SizedBox(height: spacing));
                  rows.add(Row(children: rowChildren));
                }
                return Column(mainAxisSize: MainAxisSize.min, children: rows);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard((IconData, PageKey, String, String) l, SurfaceTokens t, BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.read<AppState>().setPage(l.$2),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: t.mutedBg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(l.$1, size: 18, color: AppColors.blue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.$3, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                        const SizedBox(height: 2),
                        Text(l.$4, style: TextStyle(fontSize: 11, color: t.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: t.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Honest note about what is NOT implemented, instead of fake modules.
  Widget _notYetCard(SurfaceTokens t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'User accounts, roles, notification channels (email/SMS/WhatsApp), audit logging and data-retention '
              'policies are not implemented in this deployment. This screen only links to modules that are live. '
              'Adding user sign-in is the prerequisite for audit logs and role-based permissions.',
              style: TextStyle(fontSize: 12, color: t.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}