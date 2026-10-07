import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/kpi_card.dart';

/// Gateway Management — real gateway liveness from the backend's gateways[]
/// broadcast. KNOT gateways have no heartbeat of their own, so liveness is
/// the time since each gateway last forwarded tag telemetry.
class GatewaysPage extends StatelessWidget {
  const GatewaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final gateways = live.state.gateways;
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final online = gateways.where((g) => now - g.lastSeen < 300).length;
    final offline = gateways.length - online;
    final carriedMiners = gateways.fold<int>(0, (sum, g) => sum + g.miners);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gateway Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text('KNOT scanner gateways — liveness inferred from forwarded telemetry', style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 760 ? 4 : 2;
              const spacing = 12.0;
              final cards = [
                KpiCard(icon: Icons.wifi, label: 'Seen Gateways', value: '${gateways.length}', color: KpiColor.blue),
                KpiCard(icon: Icons.check_circle, label: 'Active (5 min)', value: '$online', color: KpiColor.green),
                KpiCard(icon: Icons.wifi_off, label: 'Quiet', value: '$offline', color: KpiColor.yellow),
                KpiCard(icon: Icons.group, label: 'Miners Carried', value: '$carriedMiners', color: KpiColor.blue),
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
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
                  columns: ['Gateway ID', 'Zone', 'Signal', 'Miners Carried', 'Last Telemetry', 'Status']
                      .map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted))))
                      .toList(),
                  rows: gateways.isEmpty
                      ? [
                          DataRow(cells: [
                            DataCell(Text(
                              live.status == ConnStatus.offline
                                  ? 'Backend offline — cannot load gateway status'
                                  : 'No gateways have forwarded telemetry yet',
                              style: TextStyle(fontSize: 12, color: t.muted),
                            )),
                            ...List.filled(5, const DataCell(SizedBox())),
                          ]),
                        ]
                      : gateways
                          .map((g) {
                            final age = now - g.lastSeen;
                            final isOnline = age < 300;
                            return DataRow(cells: [
                              DataCell(Text(g.id, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: t.fg))),
                              DataCell(Text(g.zone, style: TextStyle(fontSize: 11, color: t.fg))),
                              DataCell(Text('${g.rssi.toStringAsFixed(0)} dBm', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
                              DataCell(Text('${g.miners}', style: TextStyle(fontSize: 11, color: t.fg, fontWeight: FontWeight.w500))),
                              DataCell(Text(timeAgoFromEpoch(g.lastSeen), style: TextStyle(fontSize: 11, color: t.muted))),
                              DataCell(Badge(label: isOnline ? 'Active' : 'Quiet', color: isOnline ? BadgeColor.green : BadgeColor.gray)),
                            ]);
                          })
                          .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}