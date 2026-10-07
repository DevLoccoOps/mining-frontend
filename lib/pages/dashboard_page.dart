import 'package:flutter/material.dart' hide Badge;

import '../data/mock_data.dart';
import '../models/worker.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/charts.dart';
import '../widgets/kpi_card.dart';
import '../widgets/mine_map.dart';
import '../widgets/worker_tooltip.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Worker? _hovered;
  bool _tabPersonnel = true;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final onlineGw = gateways.where((g) => g.online).length;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildKpiGrid(c.maxWidth, onlineGw),
                const SizedBox(height: 20),
                _mapAndEvents(c, t),
                const SizedBox(height: 20),
                _tabbedTable(t),
                const SizedBox(height: 20),
                _buildChartGrid(c.maxWidth),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(double width, int onlineGw) {
    final cols = width > 1280 ? 6 : width > 1024 ? 4 : width > 640 ? 3 : 2;
    const spacing = 12.0;
    final cards = _kpis(onlineGw);

    final List<Widget> rows = [];
    for (var i = 0; i < cards.length; i += cols) {
      final rowChildren = <Widget>[];
      for (var j = i; j < cards.length && j < i + cols; j++) {
        if (rowChildren.isNotEmpty) rowChildren.add(const SizedBox(width: spacing));
        rowChildren.add(Expanded(child: cards[j]));
      }
      // Pad incomplete final row so its cards match the width of cards above.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _buildChartGrid(double width) {
    final cols = width > 1280 ? 4 : width > 760 ? 2 : 1;
    const spacing = 20.0;
    final cards = [
      _batteryCard(),
      _card('Worker Distribution', const WorkerDistributionBar()),
      _card('Avg Signal Strength', const SignalAreaChart()),
      _card('Personnel Underground', const PersonnelAreaChart(green: true)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  List<Widget> _kpis(int onlineGw) {
    return [
      KpiCard(icon: Icons.group, label: 'Active Underground', value: '${workers.length}', sub: '+3 since last hour', color: KpiColor.blue, trend: TrendArrow.up),
      KpiCard(icon: Icons.wifi, label: 'Online Gateways', value: '$onlineGw', sub: '${gateways.length} total', color: KpiColor.green),
      KpiCard(icon: Icons.wifi_off, label: 'Offline Gateways', value: '${gateways.length - onlineGw}', sub: '1 critical', color: KpiColor.red),
      KpiCard(icon: Icons.tag, label: 'Registered Tags', value: '28', sub: '20 assigned', color: KpiColor.blue),
      KpiCard(icon: Icons.battery_alert, label: 'Battery Warnings', value: '4', sub: '2 critical', color: KpiColor.yellow),
      KpiCard(icon: Icons.warning_amber_rounded, label: 'Emergency Alerts', value: '2', sub: 'Active now', color: KpiColor.red),
      KpiCard(icon: Icons.person_add_alt, label: 'Visitors Underground', value: '3', sub: 'Escorted', color: KpiColor.teal),
      KpiCard(icon: Icons.calendar_month_outlined, label: 'Current Shift', value: 'Day', sub: '06:00 – 18:00', color: KpiColor.blue),
      KpiCard(icon: Icons.signal_cellular_alt, label: 'Avg Signal Strength', value: '-64 dBm', sub: 'Good', color: KpiColor.green, trend: TrendArrow.up),
      KpiCard(icon: Icons.thermostat, label: 'Mine Temperature', value: '31°C', sub: 'Level 3 reading', color: KpiColor.yellow),
      KpiCard(icon: Icons.air, label: 'Gas Sensor Alerts', value: '1', sub: 'Tunnel B — active', color: KpiColor.red),
      KpiCard(icon: Icons.flash_on, label: 'Equipment Tracking', value: '7', sub: 'Active units', color: KpiColor.purple),
    ];
  }

  Widget _mapAndEvents(BoxConstraints c, SurfaceTokens t) {
    final wide = c.maxWidth > 1024;
    final mapH = wide ? 440.0 : 320.0;
    if (wide) {
      return SizedBox(
        height: mapH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: _mapCard(t)),
            const SizedBox(width: 20),
            Expanded(flex: 1, child: _eventsCard(t)),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: mapH, child: _mapCard(t)),
        const SizedBox(height: 20),
        SizedBox(height: mapH, child: _eventsCard(t)),
      ],
    );
  }

  Widget _mapCard(SurfaceTokens t) {
    return Container(
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
            child: Row(
              children: [
                Icon(Icons.map_outlined, size: 15, color: AppColors.blue),
                const SizedBox(width: 8),
                Text('Underground Mine Map — Live',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                const SizedBox(width: 8),
                _liveBadge(),
                const Spacer(),
                IconButton(icon: Icon(Icons.layers, size: 14, color: t.muted), onPressed: () {}, tooltip: 'Map layers'),
                IconButton(icon: Icon(Icons.refresh, size: 14, color: t.muted), onPressed: () {}, tooltip: 'Refresh map'),
              ],
            ),
          ),
          // Map area — fills remaining card height (card is bounded by _mapAndEvents)
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: MineMap(
                      hoveredWorker: _hovered,
                      onHover: (w) => setState(() => _hovered = w),
                    ),
                  ),
                ),
                if (_hovered != null)
                  Positioned(top: 12, right: 12, child: WorkerTooltip(w: _hovered!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventsCard(SurfaceTokens t) {
    return Container(
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
            child: Row(
              children: [
                Icon(Icons.show_chart, size: 15, color: AppColors.blue),
                const SizedBox(width: 8),
                Text('Recent Events', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                const Spacer(),
                Text('${recentEvents.length} events', style: TextStyle(fontSize: 12, color: t.muted)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: recentEvents.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
              itemBuilder: (_, i) {
                final ev = recentEvents[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(ev.color), shape: BoxShape.circle)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ev.msg, style: TextStyle(fontSize: 12, color: t.fg, height: 1.3)),
                            const SizedBox(height: 2),
                            Text(ev.time, style: TextStyle(fontSize: 10, color: t.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveBadge() {
    final t = tokensOf(context);
    // Light-mode pastel chip glares on dark surfaces; use a translucent tint + bright fg.
    final bg = t.isDark ? const Color(0x1A22C55E) : const Color(0xFFF0FDF4);
    final border = t.isDark ? const Color(0x3322C55E) : const Color(0xFFBBF7D0);
    final fg = t.isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BlinkDot(),
          const SizedBox(width: 5),
          Text('LIVE', style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _tabbedTable(SurfaceTokens t) {
    return Container(
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              _tab(t, 'Personnel Underground', true),
              _tab(t, 'Gateway Status', false),
            ],
          ),
          const Divider(height: 1),
          _tabPersonnel ? _personnelTable(t) : _gatewayTable(t),
        ],
      ),
    );
  }

  Widget _tab(SurfaceTokens t, String label, bool isPersonnelTab) {
    final sel = isPersonnelTab == _tabPersonnel;
    return InkWell(
      onTap: () => setState(() => _tabPersonnel = isPersonnelTab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: sel ? AppColors.blue : Colors.transparent, width: 2)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: sel ? AppColors.blue : t.muted,
            )),
      ),
    );
  }

  Widget _personnelTable(SurfaceTokens t) {
    final headers = ['#', 'Employee', 'Department', 'Shift', 'Zone', 'BLE Tag', 'Battery', 'Signal', 'Status', 'Last Seen', 'Actions'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
        columns: headers.map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted)))).toList(),
        rows: List.generate(workers.length, (i) {
          final w = workers[i];
          return DataRow(
            cells: [
              DataCell(Text('${i + 1}', style: TextStyle(fontSize: 11, color: t.muted))),
              DataCell(Row(children: [
                CircleAvatar(radius: 14, backgroundColor: AppColors.blue600, child: Text(w.initials, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(w.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.fg)),
                  Text(w.empNo, style: TextStyle(fontSize: 10, color: t.muted)),
                ]),
              ])),
              DataCell(Text(w.dept, style: TextStyle(fontSize: 11, color: t.muted))),
              DataCell(Badge(label: w.shift, color: BadgeColor.blue)),
              DataCell(Text(w.zone, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t.fg))),
              DataCell(Text(w.bleTag, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.fg))),
              DataCell(BatteryBar(value: w.battery, width: 64)),
              DataCell(Text('${w.signal} dBm', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
              DataCell(Badge(label: w.status.label, color: _workerStatusColor(w))),
              DataCell(Text(w.lastSeen, style: TextStyle(fontSize: 11, color: t.muted))),
              DataCell(Row(children: [
                IconButton(
                  icon: Icon(Icons.visibility_outlined, size: 15),
                  onPressed: () {},
                  tooltip: 'View ${w.name}',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.navigation_outlined, size: 15),
                  onPressed: () {},
                  tooltip: 'Locate ${w.name} on map',
                  visualDensity: VisualDensity.compact,
                ),
              ])),
            ],
          );
        }),
      ),
    );
  }

  Widget _gatewayTable(SurfaceTokens t) {
    final headers = ['Gateway', 'Location', 'Signal', 'Power', 'UPS', 'Temperature', 'Status', 'Last Comm', 'Battery Health'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
        columns: headers.map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted)))).toList(),
        rows: gateways.map((g) {
          return DataRow(
            cells: [
              DataCell(Text(g.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: t.fg))),
              DataCell(Text(g.location, style: TextStyle(fontSize: 11, color: t.muted))),
              DataCell(Text('${g.signal} dBm', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
              DataCell(Badge(label: g.power, color: g.power == 'PoE' ? BadgeColor.blue : BadgeColor.yellow)),
              DataCell(Icon(g.ups ? Icons.check_circle : Icons.cancel, size: 13, color: g.ups ? AppColors.green : t.muted)),
              DataCell(Text('${g.temperature}°C', style: TextStyle(fontSize: 11, color: g.temperature > 34 ? AppColors.red : t.fg, fontWeight: g.temperature > 34 ? FontWeight.w500 : FontWeight.normal))),
              DataCell(Badge(label: g.online ? 'Online' : 'Offline', color: g.online ? BadgeColor.green : BadgeColor.red)),
              DataCell(Text(g.lastComm, style: TextStyle(fontSize: 11, color: t.muted))),
              DataCell(BatteryBar(value: g.batteryHealth, width: 56)),
            ],
          );
        }).toList(),
      ),
    );
  }

  BadgeColor _workerStatusColor(Worker w) {
    if (w.status == WorkerStatus.emergency) return BadgeColor.red;
    if (w.status == WorkerStatus.moving) return BadgeColor.blue;
    return BadgeColor.gray;
  }

  Widget _batteryCard() {
    final t = tokensOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Battery Health', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
          const SizedBox(height: 12),
          const BatteryDonut(size: 160),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: batteryPie
                .map((d) => Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(d.color), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Flexible(child: Text('${d.name}: ${d.value}', style: TextStyle(fontSize: 10, color: t.muted))),
                    ]))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, Widget chart) {
    final t = tokensOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
          const SizedBox(height: 12),
          chart,
        ],
      ),
    );
  }
}

class _BlinkDot extends StatefulWidget {
  const _BlinkDot();
  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _animating = false;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honor the platform "reduce motion" setting: steady dot instead of blinking.
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce && _animating) {
      _c.stop();
      _animating = false;
    } else if (!reduce && !_animating) {
      _c.repeat(reverse: true);
      _animating = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Opacity(
          opacity: 0.4 + 0.6 * _c.value,
          child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
        ),
      );
}
