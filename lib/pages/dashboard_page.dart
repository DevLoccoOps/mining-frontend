import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../core/worker_mapper.dart';
import '../models/api_models.dart';
import '../models/chart_data.dart';
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
    final live = context.watch<LiveService>();
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final onlineGw = live.state.gateways.where((g) => now - g.lastSeen < 300).length;
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
                _buildKpiGrid(c.maxWidth, onlineGw, live),
                const SizedBox(height: 20),
                _mapAndEvents(c, t, live),
                const SizedBox(height: 20),
                _tabbedTable(t, live),
                const SizedBox(height: 20),
                _buildChartGrid(c.maxWidth, live),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(double width, int onlineGw, LiveService live) {
    final cols = width > 1280 ? 6 : width > 1024 ? 4 : width > 640 ? 3 : 2;
    const spacing = 12.0;
    final cards = _kpis(onlineGw, live);

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

  Widget _buildChartGrid(double width, LiveService live) {
    final cols = width > 1280 ? 4 : width > 760 ? 2 : 1;
    const spacing = 20.0;

    // Zone distribution straight from the live state_update broadcast.
    final zoneData = live.state.zones.map((z) => ZoneCount(z.zone, z.total)).toList()
      ..sort((a, b) => b.n.compareTo(a.n));

    // Battery health sliced from live per-miner battery readings.
    final batteries = live.state.miners.map((m) => m.battery).whereType<int>().toList();
    final batterySlices = batteries.isEmpty
        ? const <BatterySlice>[]
        : [
            BatterySlice('80-100%', batteries.where((b) => b >= 80).length, 0xFF22C55E),
            BatterySlice('60-79%', batteries.where((b) => b >= 60 && b < 80).length, 0xFF3B82F6),
            BatterySlice('40-59%', batteries.where((b) => b >= 40 && b < 60).length, 0xFFF59E0B),
            BatterySlice('20-39%', batteries.where((b) => b >= 20 && b < 40).length, 0xFFEF4444),
            BatterySlice('<20%', batteries.where((b) => b < 20).length, 0xFF7C3AED),
          ];

    final cards = [
      _batteryCard(batterySlices),
      _card('Worker Distribution — live zones', WorkerDistributionBar(data: zoneData)),
      _card('Temperature — recent telemetry', TelemetryTrendChart(
        readings: live.telemetry,
        valuePicker: (r) => r.tempC,
        color: AppColors.red,
        maxY: 45,
        unit: '°',
      )),
      _card('Signal Strength — recent telemetry', TelemetryTrendChart(
        readings: live.telemetry,
        valuePicker: (r) => r.rssi,
        color: AppColors.blue,
        minY: -100,
        maxY: 0,
      )),
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

  List<Widget> _kpis(int onlineGw, LiveService live) {
    final state = live.state;
    final criticalCount = state.alerts.where((a) => a.type == 'critical' || a.type == 'danger').length;
    final lowBattery = state.miners.where((m) => (m.battery ?? 100) < 20).length;
    final assignedTags = live.tags.where((t) => t.assignedTo != null).length;

    // Hottest live zone reading (avg_temp is "N/A" when a zone has no sensors).
    double? maxTemp;
    for (final z in state.zones) {
      final v = double.tryParse(z.avgTemp);
      if (v != null && (maxTemp == null || v > maxTemp)) maxTemp = v;
    }

    return [
      // ── Live from the backend ──
      KpiCard(icon: Icons.group, label: 'Active Underground', value: '${state.totalMiners}', sub: 'Live tags reporting', color: KpiColor.blue),
      KpiCard(icon: Icons.tag, label: 'Registered Tags', value: '${live.tags.length}', sub: '$assignedTags assigned', color: KpiColor.blue),
      KpiCard(icon: Icons.warning_amber_rounded, label: 'Emergency Alerts', value: '$criticalCount', sub: criticalCount > 0 ? 'Active now' : 'None active', color: KpiColor.red),
      KpiCard(icon: Icons.battery_alert, label: 'Battery Warnings', value: '$lowBattery', sub: 'Tags under 20%', color: KpiColor.yellow),
      if (maxTemp != null) KpiCard(icon: Icons.thermostat, label: 'Max Zone Temp', value: '${maxTemp.toStringAsFixed(1)}°C', sub: 'Live zone average', color: maxTemp > 32 ? KpiColor.red : KpiColor.green),
      // ── Live gateway liveness (seen = forwarded telemetry in last 5 min) ──
      KpiCard(icon: Icons.wifi, label: 'Gateways Active', value: '$onlineGw', sub: '${state.gateways.length} seen', color: KpiColor.green),
      KpiCard(icon: Icons.wifi_off, label: 'Gateways Quiet', value: '${state.gateways.length - onlineGw}', sub: 'no telemetry in 5 min', color: state.gateways.length - onlineGw > 0 ? KpiColor.red : KpiColor.green),
      // ── Not tracked by the backend ──
      KpiCard(icon: Icons.calendar_month_outlined, label: 'Current Shift', value: 'Day', sub: '06:00 – 18:00', color: KpiColor.blue),
      KpiCard(icon: Icons.flash_on, label: 'Equipment Tracking', value: '7', sub: 'Active units', color: KpiColor.purple),
    ];
  }

  Widget _mapAndEvents(BoxConstraints c, SurfaceTokens t, LiveService live) {
    final wide = c.maxWidth > 1024;
    final mapH = wide ? 440.0 : 320.0;
    if (wide) {
      return SizedBox(
        height: mapH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: _mapCard(t, live)),
            const SizedBox(width: 20),
            Expanded(flex: 1, child: _eventsCard(t, live)),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: mapH, child: _mapCard(t, live)),
        const SizedBox(height: 20),
        SizedBox(height: mapH, child: _eventsCard(t, live)),
      ],
    );
  }

  Widget _mapCard(SurfaceTokens t, LiveService live) {
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
                _liveBadge(live.status),
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
                      workers: live.state.miners.map((m) => workerFromMiner(m)).toList(),
                      gateways: live.state.gateways,
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

  Widget _eventsCard(SurfaceTokens t, LiveService live) {
    final events = live.logs.take(12).toList();
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
                Text('${live.logs.length} logged', style: TextStyle(fontSize: 12, color: t.muted)),
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 24, color: t.muted),
                          const SizedBox(height: 8),
                          Text('No alert history yet', style: TextStyle(fontSize: 12, color: t.muted)),
                          const SizedBox(height: 4),
                          Text('Events appear as tags report telemetry', style: TextStyle(fontSize: 10, color: t.muted)),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
                    itemBuilder: (_, i) {
                      final ev = events[i];
                      final isCritical = ev.alertType == 'critical';
                      final color = isCritical
                          ? AppColors.red
                          : ev.alertType == 'danger'
                              ? AppColors.amber
                              : AppColors.blue;
                      final who = ev.minerName ?? ev.mac;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ev.alertMsg ?? '$who raised an alert', style: TextStyle(fontSize: 12, color: t.fg, height: 1.3)),
                                  const SizedBox(height: 2),
                                  Text(
                                    [who, ev.zone, ev.createdAt != null ? timeAgo(ev.createdAt!) : null]
                                        .whereType<String>()
                                        .where((s) => s.isNotEmpty)
                                        .join(' · '),
                                    style: TextStyle(fontSize: 10, color: t.muted),
                                  ),
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

  Widget _liveBadge(ConnStatus status) {
    final t = tokensOf(context);
    final Color bg;
    final Color border;
    final Color fg;
    final String label;
    final bool animate;
    switch (status) {
      case ConnStatus.live:
        bg = t.isDark ? const Color(0x1A22C55E) : const Color(0xFFF0FDF4);
        border = t.isDark ? const Color(0x3322C55E) : const Color(0xFFBBF7D0);
        fg = t.isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
        label = 'LIVE';
        animate = true;
      case ConnStatus.connecting:
        bg = t.isDark ? const Color(0x1AF59E0B) : const Color(0xFFFEF3C7);
        border = t.isDark ? const Color(0x33F59E0B) : const Color(0xFFFDE68A);
        fg = t.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        label = 'CONNECTING';
        animate = false;
      case ConnStatus.offline:
        bg = t.isDark ? const Color(0x1AEF4444) : const Color(0xFFFEE2E2);
        border = t.isDark ? const Color(0x33EF4444) : const Color(0xFFFECACA);
        fg = t.isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
        label = 'OFFLINE';
        animate = false;
    }
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
          _BlinkDot(color: fg, animate: animate),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _tabbedTable(SurfaceTokens t, LiveService live) {
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
          _tabPersonnel ? _personnelTable(t, live) : _gatewayTable(t),
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

  Widget _personnelTable(SurfaceTokens t, LiveService live) {
    final miners = live.state.miners;
    final headers = ['#', 'Personnel', 'Zone', 'BLE Tag', 'Battery', 'Temp', 'Signal', 'Status', 'Last Seen', 'Actions'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
        columns: headers.map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted)))).toList(),
        rows: miners.isEmpty
            ? [
                DataRow(
                  cells: [
                    DataCell(Text(
                      live.status == ConnStatus.offline
                          ? 'Backend offline — showing nothing until the connection is restored'
                          : 'No tags reporting yet — waiting for BLE telemetry',
                      style: TextStyle(fontSize: 12, color: t.muted),
                    )),
                    ...List.filled(headers.length - 1, const DataCell(SizedBox())),
                  ],
                ),
              ]
            : List.generate(miners.length, (i) {
                final m = miners[i];
                final hasCritical = m.alerts.any((a) => a.type == 'critical');
                final hasDanger = m.alerts.any((a) => a.type == 'danger');
                final displayName = m.name ?? live.nameForMac(m.mac) ?? 'Unregistered tag';
                return DataRow(
                  color: WidgetStateProperty.all(
                      hasCritical ? AppColors.red.withOpacity(0.08) : hasDanger ? AppColors.amber.withOpacity(0.06) : null),
                  cells: [
                    DataCell(Text('${i + 1}', style: TextStyle(fontSize: 11, color: t.muted))),
                    DataCell(Row(children: [
                      CircleAvatar(
                          radius: 14,
                          backgroundColor: hasCritical ? AppColors.red : AppColors.blue600,
                          child: Text(_initials(displayName),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.fg)),
                        Text(m.registered ? 'Registered' : 'MAC ${m.mac}', style: TextStyle(fontSize: 10, color: t.muted)),
                      ]),
                    ])),
                    DataCell(Text(m.zone ?? '—', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t.fg))),
                    DataCell(Text(m.mac, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.fg))),
                    DataCell(m.battery != null ? BatteryBar(value: m.battery!, width: 64) : Text('—', style: TextStyle(fontSize: 11, color: t.muted))),
                    DataCell(m.temperature != null
                        ? Text('${m.temperature!.toStringAsFixed(1)}°C',
                            style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: m.temperature! > 32 ? AppColors.red : t.fg,
                                fontWeight: m.temperature! > 32 ? FontWeight.w500 : FontWeight.normal))
                        : Text('—', style: TextStyle(fontSize: 11, color: t.muted))),
                    DataCell(Text('${m.rssi.toStringAsFixed(0)} dBm', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
                    DataCell(_minerStatusBadge(t, m)),
                    DataCell(Text(timeAgoFromEpoch(m.lastSeen), style: TextStyle(fontSize: 11, color: t.muted))),
                    DataCell(Row(children: [
                      IconButton(
                        icon: Icon(Icons.visibility_outlined, size: 15),
                        onPressed: () {},
                        tooltip: 'View $displayName',
                        visualDensity: VisualDensity.compact,
                      ),
                    ])),
                  ],
                );
              }),
      ),
    );
  }

  Badge _minerStatusBadge(SurfaceTokens t, MinerEntry m) {
    if (m.alerts.any((a) => a.type == 'critical')) return const Badge(label: 'EMERGENCY', color: BadgeColor.red);
    if (m.alerts.any((a) => a.type == 'danger')) return const Badge(label: 'ALERT', color: BadgeColor.yellow);
    if (m.moving) return const Badge(label: 'Moving', color: BadgeColor.blue);
    return const Badge(label: 'Stationary', color: BadgeColor.gray);
  }

  String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length > 2 ? 2 : 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _gatewayTable(SurfaceTokens t) {
    final live = context.watch<LiveService>();
    final gateways = live.state.gateways;
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final headers = ['Gateway', 'Zone', 'Signal', 'Miners Carried', 'Status', 'Last Telemetry'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
        columns: headers.map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted)))).toList(),
        rows: gateways.isEmpty
            ? [
                DataRow(cells: [
                  DataCell(Text(
                    live.status == ConnStatus.offline
                        ? 'Backend offline — cannot load gateway status'
                        : 'No gateways have forwarded telemetry yet',
                    style: TextStyle(fontSize: 12, color: t.muted),
                  )),
                  ...List.filled(headers.length - 1, const DataCell(SizedBox())),
                ]),
              ]
            : gateways
                .map((g) {
                  final isOnline = now - g.lastSeen < 300;
                  return DataRow(cells: [
                    DataCell(Text(g.id, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: t.fg))),
                    DataCell(Text(g.zone, style: TextStyle(fontSize: 11, color: t.muted))),
                    DataCell(Text('${g.rssi.toStringAsFixed(0)} dBm', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
                    DataCell(Text('${g.miners}', style: TextStyle(fontSize: 11, color: t.fg, fontWeight: FontWeight.w500))),
                    DataCell(Badge(label: isOnline ? 'Active' : 'Quiet', color: isOnline ? BadgeColor.green : BadgeColor.gray)),
                    DataCell(Text(timeAgoFromEpoch(g.lastSeen), style: TextStyle(fontSize: 11, color: t.muted))),
                  ]);
                })
                .toList(),
      ),
    );
  }

  Widget _batteryCard(List<BatterySlice> slices) {
    final t = tokensOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Battery Health', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
          const SizedBox(height: 12),
          BatteryDonut(size: 160, data: slices),
          const SizedBox(height: 8),
          if (slices.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text('No battery readings yet — waiting for tag telemetry', style: TextStyle(fontSize: 10, color: t.muted)),
            )
          else
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: slices
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
  final Color color;
  final bool animate;
  const _BlinkDot({required this.color, this.animate = true});

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
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _BlinkDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncMotion();
  }

  void _syncMotion() {
    // Honor the platform "reduce motion" setting and non-live connection states.
    final shouldAnimate = widget.animate && !MediaQuery.of(context).disableAnimations;
    if (shouldAnimate && !_animating) {
      _c.repeat(reverse: true);
      _animating = true;
    } else if (!shouldAnimate && _animating) {
      _c.stop();
      _animating = false;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.4 + 0.6 * _c.value,
        child: Container(width: 6, height: 6, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
      ),
    );
  }
}