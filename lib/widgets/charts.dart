import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../models/chart_data.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

const _axisLabelColor = Color(0xFF9CA3AF);

Widget _bottomTitle(String text, {double size = 10, Color color = _axisLabelColor}) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(text, style: TextStyle(fontSize: size, color: color)),
  );
}

AxisTitles _hiddenAxis() => AxisTitles(sideTitles: SideTitles(showTitles: false));

FlGridData _grid(SurfaceTokens t) => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (v) => FlLine(color: t.border, strokeWidth: 1, dashArray: [3, 3]),
    );

class BatteryDonut extends StatelessWidget {
  final double size;
  final double inner;
  final double outer;
  final List<BatterySlice> data;
  const BatteryDonut({super.key, this.size = 160, this.inner = 45, this.outer = 68, this.data = const []});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final total = data.fold<int>(0, (sum, s) => sum + s.value);
    return SizedBox(
      width: double.infinity,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: inner,
              sections: data
                  .map((s) => PieChartSectionData(
                        value: s.value.toDouble(),
                        color: Color(s.color),
                        radius: outer - inner,
                        title: '',
                      ))
                  .toList(),
            ),
          ),
          // Headline total in the donut center — the eye lands here first.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$total',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: t.fg, height: 1.1)),
              Text('TAGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: t.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkerDistributionBar extends StatelessWidget {
  final List<ZoneCount> data;
  const WorkerDistributionBar({super.key, this.data = const []});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final maxN = data.isEmpty ? 1.0 : data.map((e) => e.n).reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxN + 1,
          barGroups: List.generate(data.length, (i) {
            final e = data[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: e.n.toDouble(),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  color: const Color(0xFF3B82F6),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            topTitles: _hiddenAxis(),
            rightTitles: _hiddenAxis(),
            leftTitles: _hiddenAxis(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => v.toInt() >= 0 && v.toInt() < data.length
                    ? _bottomTitle(data[v.toInt()].zone, color: t.muted)
                    : const SizedBox(),
              ),
            ),
          ),
          gridData: _grid(t),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

/// Battery percentage progress bar with colored fill.
class BatteryBar extends StatelessWidget {
  final int value;
  final double width;
  const BatteryBar({super.key, required this.value, this.width = 64});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final col = Color(batteryColor(value));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: 6,
          decoration: BoxDecoration(color: t.mutedBg, borderRadius: BorderRadius.circular(999)),
          clipBehavior: Clip.hardEdge,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100).clamp(0.0, 1.0),
            child: Container(color: col),
          ),
        ),
        const SizedBox(width: 6),
        Text('$value%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: col)),
      ],
    );
  }
}
/// Live line chart over the backend's recent telemetry history. Readings are
/// bucketed per minute; [valuePicker] selects the field to plot (temp, RSSI…).
class TelemetryTrendChart extends StatelessWidget {
  final List<TelemetryRecord> readings;
  final double? Function(TelemetryRecord) valuePicker;
  final Color color;
  final double minY;
  final double maxY;
  final String unit;
  const TelemetryTrendChart({
    super.key,
    required this.readings,
    required this.valuePicker,
    this.color = const Color(0xFF3B82F6),
    this.minY = 0,
    this.maxY = 100,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final points = readings
        .where((r) => r.createdAt != null && valuePicker(r) != null)
        .toList()
      ..sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
    if (points.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(child: Text('No readings yet — waiting for tag telemetry', style: TextStyle(fontSize: 12, color: t.muted))),
      );
    }
    // Per-minute averages, capped at 60 points.
    final first = points.first.createdAt!;
    final byMinute = <int, List<double>>{};
    for (final p in points) {
      byMinute.putIfAbsent(p.createdAt!.difference(first).inMinutes, () => []).add(valuePicker(p)!);
    }
    final spots = [
      for (final e in byMinute.entries)
        FlSpot(e.key.toDouble(), e.value.reduce((a, b) => a + b) / e.value.length),
    ];
    final maxX = spots.map((s) => s.x).reduce((a, b) => a > b ? a : b) + 1;
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: _grid(t),
          titlesData: FlTitlesData(
            topTitles: _hiddenAxis(),
            rightTitles: _hiddenAxis(),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.round()}$unit', style: const TextStyle(fontSize: 9, color: _axisLabelColor)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5, getTitlesWidget: (v, _) => _bottomTitle('${v.round()}m'))),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2,
              color: color,
              dotData: FlDotData(show: spots.length <= 20),
              belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
            ),
          ],
        ),
      ),
    );
  }
}
