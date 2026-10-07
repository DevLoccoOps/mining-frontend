import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/kpi_card.dart';

/// Mine Zones — live zone summaries from the state_update broadcast: headcount,
/// alert counts and average temperature per zone.
class MineZonesPage extends StatelessWidget {
  const MineZonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final zones = live.state.zones;
    final totalMiners = live.state.totalMiners;
    final criticalZones = zones.where((z) => z.critical > 0).length;
    final hotZones = zones.where((z) => _avgTemp(z) != null && _avgTemp(z)! > 32).length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Mine Zones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text('Live headcount and conditions per zone', style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 760 ? 4 : 2;
              const spacing = 12.0;
              final cards = [
                KpiCard(icon: Icons.map_outlined, label: 'Active Zones', value: '${zones.length}', color: KpiColor.blue),
                KpiCard(icon: Icons.group, label: 'Miners Underground', value: '$totalMiners', color: KpiColor.green),
                KpiCard(icon: Icons.warning_amber_rounded, label: 'Zones Critical', value: '$criticalZones', color: KpiColor.red),
                KpiCard(icon: Icons.thermostat, label: 'Hot Zones (>32°C)', value: '$hotZones', color: KpiColor.yellow),
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
            child: zones.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 40, color: t.muted),
                        const SizedBox(height: 12),
                        Text('No zone data yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.fg)),
                        const SizedBox(height: 4),
                        Text(
                          live.status == ConnStatus.offline
                              ? 'Backend offline — reconnecting…'
                              : 'Zones appear once gateways start forwarding tag telemetry',
                          style: TextStyle(fontSize: 12, color: t.muted),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 340, childAspectRatio: 1.9, mainAxisSpacing: 12, crossAxisSpacing: 12),
                    itemCount: zones.length,
                    itemBuilder: (_, i) => _zoneCard(zones[i], t),
                  ),
          ),
        ],
      ),
    );
  }

  double? _avgTemp(ZoneSummary z) => double.tryParse(z.avgTemp);

  Widget _zoneCard(ZoneSummary z, SurfaceTokens t) {
    final avgTemp = _avgTemp(z);
    final hasCritical = z.critical > 0;
    final border = hasCritical
        ? AppColors.red
        : z.danger > 0
            ? AppColors.amber
            : t.border;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: border, width: hasCritical ? 1.5 : 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: hasCritical ? AppColors.red : AppColors.blue),
              const SizedBox(width: 6),
              Expanded(child: Text(z.zone, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg))),
              Badge(label: '${z.total} miner${z.total == 1 ? '' : 's'}', color: BadgeColor.blue),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _metric(Icons.warning_amber_rounded, '${z.critical}', 'critical', AppColors.red, t),
              _metric(Icons.error_outline, '${z.danger}', 'danger', AppColors.amber, t),
              _metric(Icons.info_outline, '${z.warning}', 'warnings', AppColors.blue, t),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.thermostat, size: 12, color: (avgTemp ?? 0) > 32 ? AppColors.red : t.muted),
              const SizedBox(width: 4),
              Text(avgTemp != null ? 'avg ${avgTemp.toStringAsFixed(1)}°C' : 'avg temp N/A',
                  style: TextStyle(fontSize: 11, color: (avgTemp ?? 0) > 32 ? AppColors.red : t.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label, Color color, SurfaceTokens t) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: value == '0' ? t.muted : color)),
          Text(label, style: TextStyle(fontSize: 9, color: t.muted)),
        ],
      ),
    );
  }
}