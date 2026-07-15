import 'package:flutter/material.dart' hide Badge;

import '../data/mock_data.dart';
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
  final _filters = ['All', 'Assigned', 'Available', 'Low Battery', 'Maintenance'];

  BadgeColor _statusColor(String s) {
    if (s == 'Assigned') return BadgeColor.blue;
    if (s == 'Available') return BadgeColor.green;
    if (s == 'Low Battery') return BadgeColor.yellow;
    return BadgeColor.red;
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final filtered = _filter == 'All' ? bleDevices : bleDevices.where((d) => d.status == _filter).toList();
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
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 14), label: const Text('Export')),
              const SizedBox(width: 12),
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 14), label: const Text('Add Device')),
            ],
          ),
          const SizedBox(height: 20),
          // Stats — responsive rows; cards size to content (no fixed aspect ratio).
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 760 ? 5 : 2;
              const spacing = 12.0;
              final cards = [
                KpiCard(icon: Icons.tag, label: 'Total Devices', value: '28', color: KpiColor.blue),
                KpiCard(icon: Icons.check_circle, label: 'Assigned', value: '20', color: KpiColor.green),
                KpiCard(icon: Icons.tag, label: 'Available', value: '4', color: KpiColor.blue),
                KpiCard(icon: Icons.battery_alert, label: 'Low Battery', value: '2', color: KpiColor.yellow),
                KpiCard(icon: Icons.error_outline, label: 'Maintenance', value: '2', color: KpiColor.red),
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
                  headingRowColor: MaterialStateProperty.all(t.mutedBg.withOpacity(0.4)),
                  columns: ['Tag Number', 'Battery', 'Firmware', 'Status', 'Assigned To', 'Last Detected', 'Actions']
                      .map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted))))
                      .toList(),
                  rows: filtered
                      .map((d) => DataRow(cells: [
                            DataCell(Text(d.tag, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: t.fg))),
                            DataCell(BatteryBar(value: d.battery, width: 64)),
                            DataCell(Text(d.firmware, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
                            DataCell(Badge(label: d.status, color: _statusColor(d.status))),
                            DataCell(Text(d.employee, style: TextStyle(fontSize: 11, color: t.fg))),
                            DataCell(Text(d.lastDetected, style: TextStyle(fontSize: 11, color: t.muted))),
                            DataCell(Row(children: [
                              _actionBtn('Assign', AppColors.blue, t),
                              _actionBtn('Battery', AppColors.amber, t),
                              _actionBtn('Deactivate', AppColors.red, t),
                            ])),
                          ]))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, SurfaceTokens t) {
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
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
          ),
        ),
      ),
    );
  }
}