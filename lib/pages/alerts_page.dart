import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../models/api_models.dart';
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
  String _category = 'All';

  /// Maps a backend alert_type to the UI severity scale.
  static String _severityOf(AlertLogRecord a) {
    switch (a.alertType) {
      case 'critical':
        return 'critical';
      case 'danger':
        return 'warning';
      default:
        return 'info';
    }
  }

  /// Derives a human category from the alert message (the backend's alert_type
  /// only carries the severity level).
  static String _categoryOf(AlertLogRecord a) {
    final msg = (a.alertMsg ?? '').toUpperCase();
    if (msg.contains('HEAT')) return 'Heat';
    if (msg.contains('FALL')) return 'Fall';
    if (msg.contains('IMMOBIL')) return 'Immobility';
    if (msg.contains('BATTERY')) return 'Battery';
    if (msg.contains('UNREGISTERED')) return 'Tag';
    if (msg.contains('GAS')) return 'Gas';
    return 'Other';
  }

  List<AlertLogRecord> _filtered(List<AlertLogRecord> logs) {
    return logs.where((a) {
      final ms = _severity == 'All' || _severityOf(a) == _severity.toLowerCase();
      final mt = _category == 'All' || _categoryOf(a) == _category;
      return ms && mt;
    }).toList();
  }

  BadgeColor _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return BadgeColor.red;
      case 'warning':
        return BadgeColor.yellow;
      default:
        return BadgeColor.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final logs = live.logs;
    final activeNow = live.state.alerts.length;
    final filtered = _filtered(logs);
    final categories = ['All', ...logs.map(_categoryOf).toSet()..remove('All')];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Alerts & Incident Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text(
                  activeNow > 0
                      ? '$activeNow active live incident${activeNow == 1 ? '' : 's'} · ${logs.length} logged'
                      : '${logs.length} logged alert${logs.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 13, color: t.muted),
                ),
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
              final crit = logs.where((a) => _severityOf(a) == 'critical').length;
              final warn = logs.where((a) => _severityOf(a) == 'warning').length;
              final lastHour = logs
                  .where((a) => a.createdAt != null && DateTime.now().difference(a.createdAt!) <= const Duration(hours: 1))
                  .length;
              final cards = [
                KpiCard(icon: Icons.warning_amber_rounded, label: 'Critical', value: '$crit', color: KpiColor.red),
                KpiCard(icon: Icons.error_outline, label: 'Warnings', value: '$warn', color: KpiColor.yellow),
                KpiCard(icon: Icons.schedule, label: 'Last Hour', value: '$lastHour', color: KpiColor.blue),
                KpiCard(icon: Icons.inventory_2_outlined, label: 'Total Logged', value: '${logs.length}', color: KpiColor.green),
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
                ...categories.map((s) => _pill(s, _category, (v) => setState(() => _category = v), t)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Alert list
          Expanded(
            child: filtered.isEmpty
                ? _emptyState(t, live)
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _alertCard(filtered[i], t),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(SurfaceTokens t, LiveService live) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 40, color: t.muted),
          const SizedBox(height: 12),
          Text('No alerts match', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.fg)),
          const SizedBox(height: 4),
          Text(
            live.status == ConnStatus.offline
                ? 'Backend offline — reconnecting…'
                : 'Nothing logged' + (live.status == ConnStatus.live ? ' — the safety engine is quiet' : ''),
            style: TextStyle(fontSize: 12, color: t.muted),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(AlertLogRecord a, SurfaceTokens t) {
    final severity = _severityOf(a);
    final iconColor = severity == 'critical'
        ? AppColors.red
        : severity == 'warning'
            ? AppColors.amber
            : AppColors.blue;
    final tintBorder = switch (severity) {
      'critical' => t.isDark ? const Color(0x66EF4444) : const Color(0xFFE5A0A0),
      'warning' => t.isDark ? const Color(0x66F59E0B) : const Color(0xFFFDE68A),
      _ => t.border,
    };
    final who = a.minerName ?? a.mac;
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
                    Badge(label: _categoryOf(a), color: _severityColor(severity)),
                    Badge(label: severity.toUpperCase(), color: _severityColor(severity)),
                    Text(who, style: TextStyle(fontSize: 12, color: t.muted, fontFamily: 'monospace')),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history, size: 10, color: t.muted),
                      const SizedBox(width: 4),
                      Text(a.createdAt != null ? timeAgo(a.createdAt!) : 'unknown time', style: TextStyle(fontSize: 12, color: t.muted)),
                    ]),
                  ],
                ),
                const SizedBox(height: 6),
                Text(a.alertMsg ?? 'Alert raised', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.fg)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on, size: 10, color: t.muted),
                  const SizedBox(width: 4),
                  Text(a.zone ?? 'unknown zone', style: TextStyle(fontSize: 12, color: t.muted)),
                  if (a.tempC != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.thermostat, size: 10, color: t.muted),
                    const SizedBox(width: 4),
                    Text('${a.tempC!.toStringAsFixed(1)}°C', style: TextStyle(fontSize: 12, color: t.muted)),
                  ],
                  if (a.battery != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.battery_std, size: 10, color: t.muted),
                    const SizedBox(width: 4),
                    Text('${a.battery}%', style: TextStyle(fontSize: 12, color: t.muted)),
                  ],
                ]),
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