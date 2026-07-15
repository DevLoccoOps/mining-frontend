import 'package:flutter/material.dart' hide Badge;

import '../data/mock_data.dart';
import '../models/alert_item.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/kpi_card.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  String _severity = 'All';
  String _type = 'All';
  final _types = ['All', 'Emergency', 'Gas', 'Medical', 'Battery', 'Gateway', 'Communication', 'Geofence', 'SOS'];

  List<AlertItem> _filtered() {
    return alerts.where((a) {
      final ms = _severity == 'All' || a.severity.label == _severity.toLowerCase();
      final mt = _type == 'All' || a.type == _type;
      return ms && mt;
    }).toList();
  }

  BadgeColor _severityColor(AlertSeverity s) {
    if (s == AlertSeverity.critical) return BadgeColor.red;
    if (s == AlertSeverity.warning) return BadgeColor.yellow;
    return BadgeColor.blue;
  }

  BadgeColor _statusColor(AlertStatus s) {
    if (s == AlertStatus.open) return BadgeColor.red;
    if (s == AlertStatus.inProgress) return BadgeColor.yellow;
    return BadgeColor.green;
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final filtered = _filtered();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Alerts & Incident Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text('${alerts.where((a) => a.status != AlertStatus.closed).length} active incidents', style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
              const Spacer(),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 14), label: const Text('Export Report')),
            ],
          ),
          const SizedBox(height: 20),
          // Stats — responsive rows; cards size to content (no fixed aspect ratio).
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 760 ? 4 : 2;
              const spacing = 12.0;
              final cards = [
                KpiCard(icon: Icons.warning_amber_rounded, label: 'Critical', value: '${alerts.where((a) => a.severity == AlertSeverity.critical).length}', color: KpiColor.red),
                KpiCard(icon: Icons.error_outline, label: 'Warnings', value: '${alerts.where((a) => a.severity == AlertSeverity.warning).length}', color: KpiColor.yellow),
                KpiCard(icon: Icons.cancel, label: 'Open', value: '${alerts.where((a) => a.status == AlertStatus.open).length}', color: KpiColor.red),
                KpiCard(icon: Icons.check_circle, label: 'Resolved', value: '${alerts.where((a) => a.status == AlertStatus.closed).length}', color: KpiColor.green),
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
          // Filters
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _label('Severity:', t),
                ...['All', 'Critical', 'Warning', 'Info'].map((s) => _pill(s, _severity, (v) => setState(() => _severity = v), t)),
                const SizedBox(width: 12),
                _label('Type:', t),
                ..._types.map((s) => _pill(s, _type, (v) => setState(() => _type = v), t)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Alert list
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _alertCard(filtered[i], t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(AlertItem a, SurfaceTokens t) {
    final Color tint;
    final Color tintBorder;
    if (a.severity == AlertSeverity.critical) {
      tint = const Color(0x4DEF4444);
      tintBorder = const Color(0xFFE5A0A0);
    } else if (a.severity == AlertSeverity.warning) {
      tint = const Color(0x33F59E0B);
      tintBorder = const Color(0xFFFDE68A);
    } else {
      tint = t.mutedBg;
      tintBorder = t.border;
    }
    final iconColor = a.severity == AlertSeverity.critical ? AppColors.red : a.severity == AlertSeverity.warning ? AppColors.amber : AppColors.blue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: tintBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.warning_amber_rounded, size: 16, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Badge(label: a.type, color: _severityColor(a.severity)),
                    Badge(label: a.status.label, color: _statusColor(a.status)),
                    if (a.assigned != null)
                      Text('→ ${a.assigned}', style: TextStyle(fontSize: 12, color: t.muted)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history, size: 10, color: t.muted),
                      const SizedBox(width: 4),
                      Text(a.time, style: TextStyle(fontSize: 12, color: t.muted)),
                    ]),
                  ],
                ),
                const SizedBox(height: 6),
                Text(a.message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.fg)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on, size: 10, color: t.muted),
                  const SizedBox(width: 4),
                  Text(a.location, style: TextStyle(fontSize: 12, color: t.muted)),
                ]),
              ],
            ),
          ),
          if (a.status != AlertStatus.closed)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ElevatedButton(onPressed: () {}, child: const Text('Assign')),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: OutlinedButton(onPressed: () {}, child: const Text('Close')),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String s, SurfaceTokens t) =>
      Padding(padding: const EdgeInsets.only(right: 4), child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.muted)));

  Widget _pill(String label, String current, ValueChanged<String> onChg, SurfaceTokens t) {
    final sel = current == label;
    return Material(
      color: sel ? AppColors.blue : t.mutedBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChg(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? Colors.white : t.muted)),
        ),
      ),
    );
  }
}