import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../core/live_service.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/kpi_card.dart';

/// System Health — live backend snapshot from /api/stats plus the frontend's
/// own WebSocket/REST connection state.
class SystemHealthPage extends StatelessWidget {
  const SystemHealthPage({super.key});

  String _uptime(double seconds) {
    if (seconds <= 0) return '—';
    final d = (seconds / 86400).floor();
    final h = ((seconds % 86400) / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final stats = live.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('System Health', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text('Backend: ${apiBaseUrl.replaceFirst(RegExp(r'^https?://'), '')}', style: TextStyle(fontSize: 13, color: t.muted, fontFamily: 'monospace')),
              ]),
              const Spacer(),
              Badge(
                label: switch (live.status) {
                  ConnStatus.live => 'Backend reachable',
                  ConnStatus.connecting => 'Connecting…',
                  ConnStatus.offline => 'Backend offline',
                },
                color: switch (live.status) {
                  ConnStatus.live => BadgeColor.green,
                  ConnStatus.connecting => BadgeColor.yellow,
                  ConnStatus.offline => BadgeColor.red,
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 760 ? 4 : 2;
              const spacing = 12.0;
              final cards = [
                KpiCard(icon: Icons.schedule, label: 'Backend Uptime', value: _uptime(stats.uptimeSeconds), color: KpiColor.green),
                KpiCard(icon: Icons.group, label: 'Live Miners', value: '${stats.liveMiners}', color: KpiColor.blue),
                KpiCard(icon: Icons.wifi, label: 'Active Gateways', value: '${stats.activeGateways}', color: KpiColor.blue),
                KpiCard(icon: Icons.desktop_windows, label: 'Dashboard Clients', value: '${stats.wsClients}', color: KpiColor.green),
                KpiCard(icon: Icons.badge, label: 'Personnel Registered', value: '${stats.personnelCount}', color: KpiColor.blue),
                KpiCard(icon: Icons.tag, label: 'Tags Registered', value: '${stats.tagCount}', color: KpiColor.blue),
                KpiCard(icon: Icons.warning_amber_rounded, label: 'Alerts Logged', value: '${stats.alertLogCount}', color: KpiColor.yellow),
                KpiCard(icon: Icons.timeline, label: 'Telemetry Rows (24h)', value: '${stats.telemetryCount}', color: KpiColor.green),
              ];
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connections', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                const SizedBox(height: 8),
                _row('WebSocket /ws/state', switch (live.status) {
                  ConnStatus.live => ('Connected — receiving state updates every 500 ms', BadgeColor.green),
                  ConnStatus.connecting => ('Connecting…', BadgeColor.yellow),
                  ConnStatus.offline => ('Disconnected — retrying with backoff', BadgeColor.red),
                }, t),
                _row(
                  'REST /api/*',
                  ('Registry polled every 20 s · stats every 10 s · ${live.lastUpdate != null ? 'last WS update ${timeAgo(live.lastUpdate!)}' : 'no WS update yet'}',
                      live.status == ConnStatus.offline ? BadgeColor.red : BadgeColor.green),
                  t,
                ),
                _row(
                  'MQTT ingestion',
                  ('ActiveMQ → Camel paho route, sakura.proxy.rlwy.net:50528 — status visible via gateway/miner liveness',
                      live.state.gateways.isNotEmpty ? BadgeColor.green : BadgeColor.gray),
                  t,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String name, (String, BadgeColor) detail, SurfaceTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: t.fg)),
                const SizedBox(height: 2),
                Text(detail.$1, style: TextStyle(fontSize: 11, color: t.muted)),
              ],
            ),
          ),
          Badge(label: detail.$2 == BadgeColor.green ? 'OK' : detail.$2 == BadgeColor.red ? 'Down' : '…', color: detail.$2),
        ],
      ),
    );
  }
}