import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/charts.dart';
import '../widgets/kpi_card.dart';

class BLEDevicesPage extends StatefulWidget {
  const BLEDevicesPage({super.key});

  @override
  State<BLEDevicesPage> createState() => _BLEDevicesPageState();
}

class _BLEDevicesPageState extends State<BLEDevicesPage> {
  String _filter = 'All';
  static const _filters = ['All', 'Assigned', 'Unassigned', 'Reporting', 'Low Battery'];

  /// Joins a registered tag with its live miner reading (battery/zone/seen).
  (TagRecord, MinerEntry?) _liveFor(TagRecord tag, List<MinerEntry> miners) {
    final norm = tag.mac.replaceAll(':', '').replaceAll('-', '').toUpperCase();
    for (final m in miners) {
      if (m.mac.replaceAll(':', '').replaceAll('-', '').toUpperCase() == norm) return (tag, m);
    }
    return (tag, null);
  }

  bool _matches((TagRecord, MinerEntry?) row) {
    final (tag, miner) = row;
    switch (_filter) {
      case 'Assigned':
        return tag.assignedTo != null && tag.assignedTo!.isNotEmpty;
      case 'Unassigned':
        return tag.assignedTo == null || tag.assignedTo!.isEmpty;
      case 'Reporting':
        return miner != null;
      case 'Low Battery':
        return (miner?.battery ?? 100) < 20;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final rows = live.tags.map((tag) => _liveFor(tag, live.state.miners)).toList();
    final filtered = rows.where(_matches).toList();
    final reporting = rows.where((r) => r.$2 != null).length;
    final lowBattery = rows.where((r) => (r.$2?.battery ?? 100) < 20).length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BLE Device Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text('MikroTik BLE Tag Inventory', style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _registerTag(context),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Register Tag'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats — responsive rows; cards size to content (no fixed aspect ratio).
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 760 ? 4 : 2;
              const spacing = 12.0;
              final cards = [
                KpiCard(icon: Icons.tag, label: 'Registered Tags', value: '${live.tags.length}', color: KpiColor.blue),
                KpiCard(icon: Icons.check_circle, label: 'Reporting Now', value: '$reporting', color: KpiColor.green),
                KpiCard(icon: Icons.wifi_off, label: 'Silent', value: '${live.tags.length - reporting}', color: KpiColor.yellow),
                KpiCard(icon: Icons.battery_alert, label: 'Low Battery', value: '$lowBattery', color: KpiColor.red),
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
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
            child: Wrap(
              spacing: 4,
              children: _filters
                  .map((f) => Material(
                        color: _filter == f ? AppColors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _filter == f ? Colors.white : t.muted)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
                  columns: ['Tag MAC', 'Type', 'Assigned To', 'Battery', 'Zone', 'Signal', 'Last Seen', 'Status', 'Actions']
                      .map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted))))
                      .toList(),
                  rows: filtered.isEmpty
                      ? [
                          DataRow(cells: [
                            DataCell(Text(
                              live.status == ConnStatus.offline
                                  ? 'Backend offline — cannot load the tag registry'
                                  : 'No tags registered yet — use "Register Tag" to add one',
                              style: TextStyle(fontSize: 12, color: t.muted),
                            )),
                            ...List.filled(8, const DataCell(SizedBox())),
                          ]),
                        ]
                      : filtered
                          .map((row) => _tagRow(row, t, live))
                          .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _tagRow((TagRecord, MinerEntry?) row, SurfaceTokens t, LiveService live) {
    final (tag, miner) = row;
    final assigned = live.nameForMac(tag.mac) ?? tag.assignedTo;
    final status = miner == null
        ? ('Silent', BadgeColor.gray)
        : miner.alerts.any((a) => a.type == 'critical' || a.type == 'danger')
            ? ('Alert', BadgeColor.red)
            : ('Reporting', BadgeColor.green);
    return DataRow(cells: [
      DataCell(Text(tag.mac, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: t.fg))),
      DataCell(Badge(label: tag.type, color: tag.type == 'outdoor' ? BadgeColor.blue : BadgeColor.gray)),
      DataCell(Text(assigned ?? '—', style: TextStyle(fontSize: 11, color: assigned != null ? t.fg : t.muted))),
      DataCell(miner?.battery != null ? BatteryBar(value: miner!.battery!, width: 64) : Text('—', style: TextStyle(fontSize: 11, color: t.muted))),
      DataCell(Text(miner?.zone ?? '—', style: TextStyle(fontSize: 11, color: t.fg))),
      DataCell(miner != null ? Text('${miner.rssi.toStringAsFixed(0)} dBm', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted)) : Text('—', style: TextStyle(fontSize: 11, color: t.muted))),
      DataCell(Text(miner != null ? timeAgoFromEpoch(miner.lastSeen) : '—', style: TextStyle(fontSize: 11, color: t.muted))),
      DataCell(Badge(label: status.$1, color: status.$2)),
      DataCell(Row(children: [
        _actionBtn('Delete', AppColors.red, t, () async {
          final ok = await live.deleteTag(tag.mac);
          if (ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tag deleted')));
          }
        }),
      ])),
    ]);
  }

  Widget _actionBtn(String label, Color color, SurfaceTokens t, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
          ),
        ),
      ),
    );
  }

  Future<void> _registerTag(BuildContext context) async {
    final macCtrl = TextEditingController();
    final typeCtrl = ValueNotifier<String>('indoor');
    final assignedCtrl = TextEditingController();
    final saving = ValueNotifier(false);
    final error = ValueNotifier<String?>(null);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Register BLE Tag'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: macCtrl,
                decoration: const InputDecoration(labelText: 'Tag MAC address', hintText: 'AA:BB:CC:DD:EE:FF'),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder(
                valueListenable: typeCtrl,
                builder: (_, type, __) => DropdownButtonFormField<String>(
                  value: type,
                  items: const [DropdownMenuItem(value: 'indoor', child: Text('indoor')), DropdownMenuItem(value: 'outdoor', child: Text('outdoor'))],
                  onChanged: (v) => typeCtrl.value = v ?? 'indoor',
                  decoration: const InputDecoration(labelText: 'Tag type'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: assignedCtrl,
                decoration: const InputDecoration(labelText: 'Assigned to (personnel id, optional)'),
              ),
              ValueListenableBuilder(
                valueListenable: error,
                builder: (_, err, __) => err == null
                    ? const SizedBox()
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(err, style: TextStyle(fontSize: 12, color: AppColors.red)),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ValueListenableBuilder(
            valueListenable: saving,
            builder: (_, busy, __) => FilledButton(
              onPressed: busy ? null : () async {
                if (macCtrl.text.trim().isEmpty) {
                  error.value = 'MAC address is required';
                  return;
                }
                saving.value = true;
                error.value = null;
                final live = context.read<LiveService>();
                final ok = await live.saveTag(TagRecord(macCtrl.text.trim(), typeCtrl.value, assignedCtrl.text.trim().isEmpty ? null : assignedCtrl.text.trim()));
                saving.value = false;
                if (ok) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } else {
                  error.value = 'Save failed — check the backend connection';
                }
              },
              child: busy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Register'),
            ),
          ),
        ],
      ),
    );
  }
}