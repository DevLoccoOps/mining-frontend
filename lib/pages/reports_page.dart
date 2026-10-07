import 'package:flutter/material.dart' hide Badge;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../models/chart_data.dart';
import '../theme/app_theme.dart';
import '../utils/csv_export.dart';
import '../widgets/badge.dart';
import '../widgets/charts.dart';

/// Reports & Analytics — an operational summary of the current live state,
/// plus the recent alert log, generated from real backend data.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final state = live.state;
    final generated = DateFormat('d/M/y HH:mm', 'en_ZA').format(DateTime.now());
    final summaryDate = DateFormat('EEEE, d MMMM y', 'en_ZA').format(DateTime.now());

    final miners = state.miners;
    final lowBattery = miners.where((m) => (m.battery ?? 100) < 20).length;
    final emergencyAlerts = state.alerts.where((a) => a.type == 'critical' || a.type == 'danger').length;
    final activeGw = state.gateways.length;
    final rssiValues = miners.map((m) => m.rssi).toList();
    final avgRssi = rssiValues.isEmpty
        ? null
        : rssiValues.reduce((a, b) => a + b) / rssiValues.length;
    final batteries = miners.map((m) => m.battery).whereType<int>().toList();

    // Metric / value / target / status
    final summary = <(String, String, String, String)>[
      ('Personnel Underground', '${state.totalMiners}', '≤ 50', state.totalMiners <= 50 ? 'Met' : 'Critical'),
      ('Tags Reporting', '${miners.length} / ${live.tags.length}', 'all registered tags', miners.length >= live.tags.length ? 'Met' : 'Warning'),
      ('Gateways Seen', '$activeGw', '≥ 1 per zone', activeGw > 0 ? 'Met' : 'Critical'),
      ('Emergency Alerts', '$emergencyAlerts', '0', emergencyAlerts == 0 ? 'Met' : 'Critical'),
      ('Battery Warnings', '$lowBattery', '0', lowBattery == 0 ? 'Met' : 'Warning'),
      ('Avg Signal Strength', avgRssi != null ? '${avgRssi.toStringAsFixed(0)} dBm' : '—', '≥ -70 dBm', (avgRssi ?? 0) >= -70 ? 'Met' : 'Warning'),
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
              ElevatedButton.icon(
                onPressed: () => _exportCsv(context, live),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Export Alert Log (CSV)'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Charts — live telemetry + zone distribution
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1024 ? 2 : 1;
              const spacing = 20.0;
              final cards = [
                _card(t, 'Temperature — recent telemetry', TelemetryTrendChart(
                  readings: live.telemetry,
                  valuePicker: (r) => r.tempC,
                  color: AppColors.red,
                  maxY: 45,
                  unit: '°',
                )),
                _card(t, 'Worker Distribution — live zones', WorkerDistributionBar(
                  data: state.zones.map((z) => ZoneCount(z.zone, z.total)).toList()..sort((a, b) => b.n.compareTo(a.n)),
                )),
                _card(t, 'Signal Strength — recent telemetry', TelemetryTrendChart(
                  readings: live.telemetry,
                  valuePicker: (r) => r.rssi,
                  color: AppColors.blue,
                  minY: -100,
                  maxY: 0,
                )),
                _batteryCard(t, batteries),
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
                    headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
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
          const SizedBox(height: 20),
          // Alert log
          Container(
            decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('Alert Log (latest ${live.logs.take(50).length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
                    columns: ['Time', 'Personnel / Tag', 'Zone', 'Type', 'Message']
                        .map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted))))
                        .toList(),
                    rows: live.logs.take(50).isEmpty
                        ? [
                            DataRow(cells: [
                              DataCell(Text('No alerts logged', style: TextStyle(fontSize: 12, color: t.muted))),
                              ...List.filled(4, const DataCell(SizedBox())),
                            ]),
                          ]
                        : live.logs
                            .take(50)
                            .map((a) => DataRow(cells: [
                                  DataCell(Text(a.createdAt != null ? DateFormat('d/M HH:mm:ss', 'en_ZA').format(a.createdAt!) : '—',
                                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
                                  DataCell(Text(a.minerName ?? a.mac, style: TextStyle(fontSize: 11, color: t.fg))),
                                  DataCell(Text(a.zone ?? '—', style: TextStyle(fontSize: 11, color: t.muted))),
                                  DataCell(Badge(
                                      label: a.alertType ?? 'warning',
                                      color: a.alertType == 'critical'
                                          ? BadgeColor.red
                                          : a.alertType == 'danger'
                                              ? BadgeColor.yellow
                                              : BadgeColor.blue)),
                                  DataCell(Text(a.alertMsg ?? '', style: TextStyle(fontSize: 11, color: t.fg))),
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

  Widget _card(SurfaceTokens t, String title, Widget chart) {
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

  Widget _batteryCard(SurfaceTokens t, List<int> batteries) {
    final slices = batteries.isEmpty
        ? const <BatterySlice>[]
        : [
            BatterySlice('80-100%', batteries.where((b) => b >= 80).length, 0xFF22C55E),
            BatterySlice('60-79%', batteries.where((b) => b >= 60 && b < 80).length, 0xFF3B82F6),
            BatterySlice('40-59%', batteries.where((b) => b >= 40 && b < 60).length, 0xFFF59E0B),
            BatterySlice('20-39%', batteries.where((b) => b >= 20 && b < 40).length, 0xFFEF4444),
            BatterySlice('<20%', batteries.where((b) => b < 20).length, 0xFF7C3AED),
          ].where((s) => s.value > 0).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Battery Distribution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
          const SizedBox(height: 16),
          if (slices.isEmpty)
            SizedBox(height: 180, child: Center(child: Text('No battery readings yet', style: TextStyle(fontSize: 12, color: t.muted))))
          else
            Row(
              children: [
                Expanded(flex: 1, child: BatteryDonut(size: 180, inner: 45, outer: 75, data: slices)),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: slices
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

  /// Downloads the current alert log as a CSV file (web: triggers a download).
  void _exportCsv(BuildContext context, LiveService live) {
    final buffer = StringBuffer('id,time,mac,name,zone,temp_c,battery,type,message\n');
    for (final a in live.logs) {
      final time = a.createdAt?.toIso8601String() ?? '';
      final esc = (String? s) => (s ?? '').replaceAll('"', '""');
      buffer.writeln('"${a.id}","$time","${esc(a.mac)}","${esc(a.minerName)}","${esc(a.zone)}",'
          '${a.tempC ?? ''},${a.battery ?? ''},"${esc(a.alertType)}","${esc(a.alertMsg)}"');
    }
    downloadFileWeb('alert_log.csv', buffer.toString().codeUnits);
  }
}