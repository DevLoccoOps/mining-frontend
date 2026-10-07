import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../models/api_models.dart';
import '../models/chart_data.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/kpi_card.dart';

/// Analytics — trends from the backend's recent telemetry history
/// (/api/telemetry/recent, last 500 readings) and the live snapshot.
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final telemetry = live.telemetry;
    final logs = live.logs;

    final temps = telemetry.where((r) => r.tempC != null && r.createdAt != null).toList()
      ..sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
    final avgTemp = temps.isEmpty ? null : temps.map((r) => r.tempC!).reduce((a, b) => a + b) / temps.length;
    final withBattery = telemetry.where((r) => r.battery != null).toList();
    final avgBattery = withBattery.isEmpty ? null : withBattery.map((r) => r.battery!).reduce((a, b) => a + b) / withBattery.length;
    final readingsByZone = <String, int>{};
    for (final r in telemetry) {
      readingsByZone[r.zone ?? 'unknown'] = (readingsByZone[r.zone ?? 'unknown'] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text(
                  telemetry.isEmpty
                      ? 'Derived from the most recent 500 telemetry readings'
                      : '${telemetry.length} recent readings · newest ${timeAgo(telemetry.first.createdAt ?? DateTime.now())}',
                  style: TextStyle(fontSize: 13, color: t.muted),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 760 ? 4 : 2;
              const spacing = 12.0;
              final cards = [
                KpiCard(icon: Icons.timeline, label: 'Recent Readings', value: '${telemetry.length}', color: KpiColor.blue),
                KpiCard(icon: Icons.thermostat, label: 'Avg Temperature', value: avgTemp != null ? '${avgTemp.toStringAsFixed(1)}°C' : '—', color: (avgTemp ?? 0) > 32 ? KpiColor.red : KpiColor.green),
                KpiCard(icon: Icons.battery_std, label: 'Avg Battery', value: avgBattery != null ? '${avgBattery.round()}%' : '—', color: (avgBattery ?? 100) < 20 ? KpiColor.red : KpiColor.green),
                KpiCard(icon: Icons.warning_amber_rounded, label: 'Alerts Logged', value: '${logs.length}', color: KpiColor.yellow),
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
          LayoutBuilder(
            builder: (context, c) {
              final twoCols = c.maxWidth > 1024;
              return Column(
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _card(t, 'Temperature Trend (recent readings)', _tempChart(temps, t))),
                    if (twoCols) ...[const SizedBox(width: 20), Expanded(child: _card(t, 'Readings per Zone', _zoneBar(readingsByZone, t)))],
                  ]),
                  const SizedBox(height: 20),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (twoCols) ...[Expanded(child: _card(t, 'Live Battery Distribution', _batteryBody(t, live))), const SizedBox(width: 20)],
                    Expanded(child: _card(t, 'Alerts per Hour (last 6h)', _alertsChart(logs, t))),
                  ]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _card(SurfaceTokens t, String title, Widget body) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
          const SizedBox(height: 16),
          body,
        ],
      ),
    );
  }

  Widget _empty(SurfaceTokens t, String msg) => SizedBox(
        height: 180,
        child: Center(child: Text(msg, style: TextStyle(fontSize: 12, color: t.muted), textAlign: TextAlign.center)),
      );

  Widget _tempChart(List<TelemetryRecord> temps, SurfaceTokens t) {
    if (temps.isEmpty) return _empty(t, 'No temperature readings yet');
    // Bucket readings into per-minute averages (max 60 points).
    final byMinute = <int, List<double>>{};
    final first = temps.first.createdAt!;
    for (final r in temps) {
      final minute = r.createdAt!.difference(first).inMinutes;
      byMinute.putIfAbsent(minute, () => []).add(r.tempC!);
    }
    final spots = [
      for (final e in byMinute.entries)
        FlSpot(e.key.toDouble(), e.value.reduce((a, b) => a + b) / e.value.length),
    ];
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spots.map((s) => s.x).reduce((a, b) => a > b ? a : b) + 1,
          minY: 0,
          maxY: 45,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: t.border, strokeWidth: 1, dashArray: [3, 3])),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.round()}', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5, getTitlesWidget: (v, _) => Text('${v.round()}m', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))))),
          ),
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, barWidth: 2, color: AppColors.red, dotData: FlDotData(show: spots.length <= 20), belowBarData: BarAreaData(show: true, color: AppColors.red.withOpacity(0.08))),
            // Heat-stress threshold reference line.
            LineChartBarData(spots: const [FlSpot(0, 32), FlSpot(60, 32)], barWidth: 1, color: AppColors.amber.withOpacity(0.5), dotData: const FlDotData(show: false), dashArray: [4, 4]),
          ],
        ),
      ),
    );
  }

  Widget _zoneBar(Map<String, int> readingsByZone, SurfaceTokens t) {
    if (readingsByZone.isEmpty) return _empty(t, 'No zone readings yet');
    final entries = readingsByZone.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(8).toList();
    final maxY = top.first.value.toDouble();
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: t.border, strokeWidth: 1, dashArray: [3, 3])),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.round()}', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, i) {
              final idx = v.toInt();
              return idx >= 0 && idx < top.length ? Padding(padding: const EdgeInsets.only(top: 6), child: Text(top[idx].key, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)))) : const SizedBox();
            })),
          ),
          barGroups: [
            for (final e in top)
              BarChartGroupData(x: top.indexOf(e), barRods: [
                BarChartRodData(toY: e.value.toDouble(), width: 16, borderRadius: BorderRadius.circular(4), color: AppColors.blue, backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY * 1.2, color: t.mutedBg)),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _alertsChart(List<AlertLogRecord> logs, SurfaceTokens t) {
    if (logs.isEmpty) return _empty(t, 'No alerts logged yet');
    final now = DateTime.now();
    final buckets = List<int>.filled(6, 0);
    for (final l in logs) {
      final age = now.difference(l.createdAt ?? now).inHours;
      if (age >= 0 && age < 6) buckets[5 - age]++;
    }
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: (buckets.reduce((a, b) => a > b ? a : b) + 1) * 1.2,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: t.border, strokeWidth: 1, dashArray: [3, 3])),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.round()}', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, i) {
              final idx = v.toInt();
              final labels = ['-5h', '-4h', '-3h', '-2h', '-1h', 'now'];
              return idx >= 0 && idx < 6 ? Padding(padding: const EdgeInsets.only(top: 6), child: Text(labels[idx], style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)))) : const SizedBox();
            })),
          ),
          barGroups: [
            for (var i = 0; i < 6; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: buckets[i].toDouble(), width: 20, borderRadius: BorderRadius.circular(4), color: buckets[i] > 0 ? AppColors.amber : AppColors.blue.withOpacity(0.3), backDrawRodData: BackgroundBarChartRodData(show: true, toY: (buckets.reduce((a, b) => a > b ? a : b) + 1) * 1.2, color: t.mutedBg)),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _batteryBody(SurfaceTokens t, LiveService live) {
    final miners = live.state.miners.where((m) => m.battery != null).toList();
    if (miners.isEmpty) return _empty(t, 'No battery readings yet');
    final slices = <BatterySlice>[
      BatterySlice('High (>60%)', miners.where((m) => m.battery! > 60).length, 0xFF22C55E),
      BatterySlice('OK (20–60%)', miners.where((m) => m.battery! > 20 && m.battery! <= 60).length, 0xFF3B82F6),
      BatterySlice('Low (<20%)', miners.where((m) => m.battery! <= 20).length, 0xFFEF4444),
    ].where((s) => s.value > 0).toList();
    return Row(
      children: [
        Expanded(flex: 3, child: BatteryDonut(size: 180, data: slices)),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: slices
                .map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(s.color), shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s.name, style: TextStyle(fontSize: 12, color: t.muted))),
                        Text('${s.value}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
                      ]),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}