import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/kpi_card.dart';

/// Visitors — personnel whose role is visitor-like, joined with live
/// underground status so the control room can see who is underground.
class VisitorsPage extends StatelessWidget {
  const VisitorsPage({super.key});

  static const _visitorRoles = {'visitor', 'contractor', 'inspector', 'guest', 'tour'};

  bool _isVisitor(PersonnelRecord p) {
    final role = (p.role ?? '').toLowerCase();
    return _visitorRoles.any(role.contains);
  }

  (PersonnelRecord, MinerEntry?) _liveFor(PersonnelRecord p, List<MinerEntry> miners) {
    final norm = p.assignedMac?.replaceAll(':', '').replaceAll('-', '').toUpperCase();
    if (norm == null) return (p, null);
    for (final m in miners) {
      if (m.mac.replaceAll(':', '').replaceAll('-', '').toUpperCase() == norm) return (p, m);
    }
    return (p, null);
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final visitors = live.personnel.where(_isVisitor).map((p) => _liveFor(p, live.state.miners)).toList();
    final underground = visitors.where((r) => r.$2 != null).length;
    // Unregistered tags currently reporting — potential unbadged entrants.
    final unregisteredTags = live.state.miners.where((m) => !m.registered).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Visitors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                Text('Visitors, contractors and inspectors on site', style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _registerVisitor(context),
                icon: const Icon(Icons.person_add_alt, size: 14),
                label: const Text('Register Visitor'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 760 ? 3 : 2;
              const spacing = 12.0;
              final cards = [
                KpiCard(icon: Icons.person_add_alt, label: 'Visitors Registered', value: '${visitors.length}', color: KpiColor.blue),
                KpiCard(icon: Icons.location_on, label: 'Underground Now', value: '$underground', color: KpiColor.green),
                KpiCard(icon: Icons.help_outline, label: 'Unknown Tags Reporting', value: '${unregisteredTags.length}', color: unregisteredTags.isNotEmpty ? KpiColor.yellow : KpiColor.green),
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
            child: Container(
              decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
                  columns: ['Visitor', 'Role', 'BLE Tag', 'Zone', 'Battery', 'Status', 'Last Seen']
                      .map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted))))
                      .toList(),
                  rows: visitors.isEmpty
                      ? [
                          DataRow(cells: [
                            DataCell(Text('No visitors registered — use "Register Visitor" to add one', style: TextStyle(fontSize: 12, color: t.muted))),
                            ...List.filled(6, const DataCell(SizedBox())),
                          ]),
                        ]
                      : visitors
                          .map((r) {
                            final (p, m) = r;
                            return DataRow(cells: [
                              DataCell(Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.fg))),
                              DataCell(Text(p.role ?? '—', style: TextStyle(fontSize: 11, color: t.muted))),
                              DataCell(Text(p.assignedMac ?? '—', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.fg))),
                              DataCell(Text(m?.zone ?? '—', style: TextStyle(fontSize: 11, color: t.fg))),
                              DataCell(m?.battery != null ? Text('${m!.battery}%', style: TextStyle(fontSize: 11, color: m.battery! < 20 ? AppColors.red : t.muted)) : Text('—', style: TextStyle(fontSize: 11, color: t.muted))),
                              DataCell(Badge(label: m != null ? 'Underground' : 'Surface', color: m != null ? BadgeColor.green : BadgeColor.gray)),
                              DataCell(Text(m != null ? timeAgoFromEpoch(m.lastSeen) : '—', style: TextStyle(fontSize: 11, color: t.muted))),
                            ]);
                          })
                          .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerVisitor(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final macCtrl = TextEditingController();
    final saving = ValueNotifier(false);
    final error = ValueNotifier<String?>(null);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Register Visitor'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(controller: macCtrl, decoration: const InputDecoration(labelText: 'BLE tag MAC', hintText: 'AA:BB:CC:DD:EE:FF')),
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
                if (nameCtrl.text.trim().isEmpty || macCtrl.text.trim().isEmpty) {
                  error.value = 'Name and tag MAC are required';
                  return;
                }
                saving.value = true;
                error.value = null;
                final live = context.read<LiveService>();
                final ok = await live.savePersonnel(PersonnelRecord(
                  '',
                  nameCtrl.text.trim(),
                  'Visitor',
                  'Day Visit',
                  macCtrl.text.trim(),
                ));
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