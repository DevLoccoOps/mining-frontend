import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/kpi_card.dart';

/// Shift Management — the personnel registry grouped by shift, each person
/// joined with their live underground status where a tag is reporting.
class ShiftsPage extends StatelessWidget {
  const ShiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();

    // Group personnel by shift (null/empty shift buckets under "Unassigned").
    final byShift = <String, List<(PersonnelRecord, MinerEntry?)>>{};
    for (final p in live.personnel) {
      final shift = (p.shift == null || p.shift!.isEmpty) ? 'Unassigned' : p.shift!;
      byShift.putIfAbsent(shift, () => []).add(_liveFor(p, live.state.miners));
    }
    final shifts = byShift.entries.toList()
      ..sort((a, b) {
        // Unassigned always last.
        if (a.key == 'Unassigned') return 1;
        if (b.key == 'Unassigned') return -1;
        return a.key.compareTo(b.key);
      });

    final underground = byShift.values
        .expand((list) => list)
        .where((r) => r.$2 != null)
        .length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Shift Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text('Personnel grouped by shift, with live underground status', style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 760 ? 3 : 2;
              const spacing = 12.0;
              final cards = [
                KpiCard(icon: Icons.calendar_month, label: 'Shifts', value: '${shifts.where((s) => s.key != 'Unassigned').length}', color: KpiColor.blue),
                KpiCard(icon: Icons.group, label: 'Personnel', value: '${live.personnel.length}', color: KpiColor.green),
                KpiCard(icon: Icons.location_on, label: 'Underground Now', value: '$underground', color: KpiColor.blue),
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
            child: live.personnel.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month, size: 40, color: t.muted),
                        const SizedBox(height: 12),
                        Text('No personnel registered yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.fg)),
                        const SizedBox(height: 4),
                        Text('Register personnel with a shift on the Personnel page', style: TextStyle(fontSize: 12, color: t.muted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: shifts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _shiftCard(shifts[i].key, shifts[i].value, t),
                  ),
          ),
        ],
      ),
    );
  }

  (PersonnelRecord, MinerEntry?) _liveFor(PersonnelRecord p, List<MinerEntry> miners) {
    final norm = p.assignedMac?.replaceAll(':', '').replaceAll('-', '').toUpperCase();
    if (norm == null) return (p, null);
    for (final m in miners) {
      if (m.mac.replaceAll(':', '').replaceAll('-', '').toUpperCase() == norm) return (p, m);
    }
    return (p, null);
  }

  Widget _shiftCard(String shift, List<(PersonnelRecord, MinerEntry?)> people, SurfaceTokens t) {
    final underground = people.where((r) => r.$2 != null).length;
    return Container(
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: AppColors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(shift, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.fg))),
                Badge(label: '$underground/${people.length} underground', color: underground > 0 ? BadgeColor.green : BadgeColor.gray),
              ],
            ),
          ),
          const Divider(height: 1),
          ...people.map((r) => _personRow(r, t)),
        ],
      ),
    );
  }

  Widget _personRow((PersonnelRecord, MinerEntry?) r, SurfaceTokens t) {
    final (p, m) = r;
    final online = m != null;
    final critical = m?.alerts.any((a) => a.type == 'critical' || a.type == 'danger') ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: critical ? AppColors.red : online ? AppColors.green : t.mutedBg, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.fg))),
          if (p.role != null) ...[
            const SizedBox(width: 8),
            Text(p.role!, style: TextStyle(fontSize: 11, color: t.muted)),
          ],
          const SizedBox(width: 12),
          Text(m?.zone ?? 'not reporting', style: TextStyle(fontSize: 11, color: m != null ? t.fg : t.muted)),
          const SizedBox(width: 12),
          if (m?.battery != null) ...[
            Text('${m!.battery}%', style: TextStyle(fontSize: 11, color: m.battery! < 20 ? AppColors.red : t.muted)),
            const SizedBox(width: 12),
          ],
          Badge(label: online ? (critical ? 'Alert' : 'Underground') : 'Surface', color: critical ? BadgeColor.red : online ? BadgeColor.green : BadgeColor.gray),
        ],
      ),
    );
  }
}