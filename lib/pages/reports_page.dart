import 'package:flutter/material.dart' hide Badge;
import 'package:intl/intl.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/charts.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _active = 'daily';
  final _reports = [
    ('daily', 'Daily Personnel'),
    ('shift', 'Shift Report'),
    ('attendance', 'Attendance'),
    ('movement', 'Movement History'),
    ('tag', 'Tag Utilisation'),
    ('gateway', 'Gateway Uptime'),
    ('battery', 'Battery Health'),
    ('evacuation', 'Evacuation Drill'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final generated = DateFormat('d/M/y', 'en_ZA').format(DateTime.now());
    final summaryDate = DateFormat('EEEE, d MMMM y', 'en_ZA').format(DateTime.now());
    final summary = [
      ('Total Personnel Underground', '11', '≤ 50', 'Met'),
      ('Active BLE Tags', '20 / 28', '≥ 18', 'Met'),
      ('Gateway Uptime', '90%', '≥ 95%', 'Warning'),
      ('Emergency Alerts', '2', '0', 'Critical'),
      ('Battery Warnings', '4', '0', 'Warning'),
      ('Avg Signal Strength', '-62 dBm', '≥ -70 dBm', 'Met'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Reports & Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text('Generated: $generated', style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
              const Spacer(),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 14), label: const Text('Export PDF')),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Export Excel'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tabs
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reports
                .map((r) => Material(
                      color: _active == r.$1 ? AppColors.blue : t.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _active == r.$1 ? AppColors.blue : t.border),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _active = r.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(r.$2,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _active == r.$1 ? Colors.white : t.muted)),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          // Charts — responsive rows; cards size to content (page scrolls).
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1024 ? 2 : 1;
              const spacing = 20.0;
              final cards = [
                _card('Personnel Underground — Today', const PersonnelAreaChart()),
                _card('Gateway Uptime (%)', const GatewayUptimeBar()),
                _batteryCard(t),
                _card('Signal Strength Trend', const SignalLineChart()),
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
          // Summary
          Container(
            decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Daily Summary — $summaryDate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                  ),
                ),
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: MaterialStateProperty.all(t.mutedBg.withOpacity(0.4)),
                    columns: ['Metric', 'Value', 'Target', 'Status']
                        .map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted))))
                        .toList(),
                    rows: summary
                        .map((r) => DataRow(cells: [
                              DataCell(Text(r.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.fg))),
                              DataCell(Text(r.$2, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.fg))),
                              DataCell(Text(r.$3, style: TextStyle(fontSize: 11, color: t.muted))),
                              DataCell(Badge(label: r.$4, color: r.$4 == 'Met' ? BadgeColor.green : r.$4 == 'Warning' ? BadgeColor.yellow : BadgeColor.red)),
                            ]))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, Widget chart) {
    final t = tokensOf(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }

  Widget _batteryCard(SurfaceTokens t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Battery Distribution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 1, child: const BatteryDonut(size: 180, inner: 45, outer: 75)),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: batteryPie
                      .map((d) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(d.color), shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Text(d.name, style: TextStyle(fontSize: 12, color: t.muted)),
                              const Spacer(),
                              Text('${d.value} tags', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
                            ]),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}