import 'package:flutter/material.dart' hide Badge;

import '../data/mock_data.dart';
import '../models/worker.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';
import '../widgets/charts.dart';

class PersonnelPage extends StatefulWidget {
  const PersonnelPage({super.key});

  @override
  State<PersonnelPage> createState() => _PersonnelPageState();
}

class _PersonnelPageState extends State<PersonnelPage> {
  final _search = TextEditingController();
  String _dept = 'All';
  String _status = 'All';
  List<Worker> _filtered() => workers.where((w) {
        final ms = w.name.toLowerCase().contains(_search.text.toLowerCase()) || w.empNo.contains(_search.text);
        final md = _dept == 'All' || w.dept == _dept;
        final mst = _status == 'All' || w.status.label == _status;
        return ms && md && mst;
      }).toList();

  List<String> get _depts => ['All', ...{for (final w in workers) w.dept}];

  void _openRegister() {
    showDialog(context: context, builder: (_) => const _RegisterDialog());
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
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personnel Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
                  Text('${workers.length} workers currently underground', style: TextStyle(fontSize: 13, color: t.muted)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openRegister,
                icon: const Icon(Icons.person_add_alt, size: 15),
                label: const Text('Register Employee'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name or employee number…',
                      prefixIcon: const Icon(Icons.search, size: 14),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                _dropdown(_depts, _dept, (v) => setState(() => _dept = v), t),
                _dropdown(['All', 'Moving', 'Stationary', 'Emergency', 'Surface'], _status, (v) => setState(() => _status = v), t),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 13),
                  label: const Text('Export'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Expanded(child: _table(filtered, t)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
                    child: Row(
                      children: [
                        Text('Showing ${filtered.length} of ${workers.length} employees', style: TextStyle(fontSize: 12, color: t.muted)),
                        const Spacer(),
                        OutlinedButton(onPressed: () {}, child: const Text('Previous')),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: () {}, child: const Text('1')),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: () {}, child: const Text('Next')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(List<String> items, String value, ValueChanged<String> onChg, SurfaceTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.mutedBg,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 13, color: t.fg)))).toList(),
          onChanged: (v) => onChg(v!),
          style: TextStyle(fontSize: 13, color: t.fg),
          icon: Icon(Icons.expand_more, size: 16, color: t.muted),
        ),
      ),
    );
  }

  Widget _table(List<Worker> rows, SurfaceTokens t) {
    final headers = ['Photo', 'Emp No', 'Full Name', 'Department', 'Shift', 'Zone', 'BLE Tag', 'Battery', 'Signal', 'Status', 'Last Seen', 'Actions'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: MaterialStateProperty.all(t.mutedBg.withOpacity(0.4)),
        columns: headers.map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted)))).toList(),
        rows: rows
            .map((w) => DataRow(cells: [
                  DataCell(CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF3B82F6),
                    child: Text(w.initials, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  )),
                  DataCell(Text(w.empNo, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
                  DataCell(Text(w.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg))),
                  DataCell(Text(w.dept, style: TextStyle(fontSize: 11, color: t.muted))),
                  DataCell(Badge(label: w.shift, color: BadgeColor.blue)),
                  DataCell(Text(w.zone, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t.fg))),
                  DataCell(Text(w.bleTag, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.fg))),
                  DataCell(BatteryBar(value: w.battery, width: 56)),
                  DataCell(Text('${w.signal}', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
                  DataCell(Badge(
                      label: w.status.label,
                      color: w.status == WorkerStatus.emergency
                          ? BadgeColor.red
                          : w.status == WorkerStatus.moving
                              ? BadgeColor.blue
                              : BadgeColor.gray)),
                  DataCell(Text(w.lastSeen, style: TextStyle(fontSize: 11, color: t.muted))),
                  DataCell(Row(children: [
                    IconButton(icon: const Icon(Icons.visibility_outlined, size: 13), onPressed: () {}, splashRadius: 12, tooltip: 'View'),
                    IconButton(icon: const Icon(Icons.navigation_outlined, size: 13), onPressed: () {}, splashRadius: 12, tooltip: 'Track'),
                    IconButton(icon: const Icon(Icons.edit, size: 13), onPressed: () {}, splashRadius: 12, tooltip: 'Edit'),
                    IconButton(icon: const Icon(Icons.tag, size: 13), onPressed: () {}, splashRadius: 12, tooltip: 'Assign Tag'),
                  ])),
                ]))
            .toList(),
      ),
    );
  }
}

class _RegisterDialog extends StatefulWidget {
  const _RegisterDialog();

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final steps = ['Personal Info', 'Assignment', 'Emergency'];
    return Dialog(
      backgroundColor: t.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Register New Employee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.fg)),
                    Text('Step $_step of 3', style: TextStyle(fontSize: 13, color: t.muted)),
                  ]),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 16,
                  ),
                ],
              ),
            ),
            // Step indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: List.generate(steps.length, (i) {
                  final done = _step > i + 1;
                  final cur = _step == i + 1;
                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: done ? AppColors.green : cur ? AppColors.blue : t.mutedBg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: done
                                ? const Icon(Icons.check, color: Colors.white, size: 12)
                                : Text('${i + 1}',
                                    style: TextStyle(
                                        color: cur ? Colors.white : t.muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(steps[i],
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: cur ? t.fg : t.muted)),
                        if (i < 2) ...[
                          const SizedBox(width: 8),
                          Expanded(child: Container(height: 1, color: t.border)),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _step == 1
                    ? _step1(t)
                    : _step == 2
                        ? _step2(t)
                        : _step3(t),
              ),
            ),
            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      if (_step > 1) {
                        setState(() => _step--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(_step > 1 ? 'Back' : 'Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_step < 3) {
                        setState(() => _step++);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(_step == 3 ? 'Save Employee' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step1(SurfaceTokens t) {
    final fields = [
      ('Employee Number', 'EMP-XXX'),
      ('National ID', 'ID Number'),
      ('First Name', 'John'),
      ('Surname', 'Smith'),
      ('Phone Number', '+27 XX XXX XXXX'),
      ('Department', 'Mining'),
      ('Position / Role', 'Underground Miner'),
      ('Contractor', 'Internal / Company name'),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final f in fields)
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
                const SizedBox(height: 6),
                TextField(decoration: InputDecoration(hintText: f.$2, isDense: true)),
              ],
            ),
          ),
        SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shift', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
              const SizedBox(height: 6),
              DropdownButtonFormField(
                decoration: const InputDecoration(isDense: true),
                items: ['Day Shift', 'Night Shift', 'Rotating'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PPE Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
              const SizedBox(height: 6),
              DropdownButtonFormField(
                decoration: const InputDecoration(isDense: true),
                items: ['Small', 'Medium', 'Large', 'XL'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _step2(SurfaceTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medical Expiry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
                  const SizedBox(height: 6),
                  TextField(decoration: const InputDecoration(isDense: true, suffixIcon: Icon(Icons.calendar_today_outlined, size: 14))),
                ],
              ),
            ),
            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Training Expiry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
                  const SizedBox(height: 6),
                  TextField(decoration: const InputDecoration(isDense: true, suffixIcon: Icon(Icons.calendar_today_outlined, size: 14))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Upload Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: t.border, style: BorderStyle.solid, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.person_outline, size: 28, color: t.muted),
                const SizedBox(height: 8),
                Text('Click to upload or drag & drop', style: TextStyle(fontSize: 13, color: t.muted)),
                const SizedBox(height: 4),
                Text('PNG, JPG up to 5MB', style: TextStyle(fontSize: 12, color: t.muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _step3(SurfaceTokens t) {
    final fields = [
      ('Emergency Contact Name', 'Jane Smith'),
      ('Relationship', 'Spouse'),
      ('Emergency Phone', '+27 XX XXX XXXX'),
      ('Blood Type', 'A+'),
      ('Medical Conditions', 'None / describe'),
      ('Allergies', 'None / describe'),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final f in fields)
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
                const SizedBox(height: 6),
                TextField(decoration: InputDecoration(hintText: f.$2, isDense: true)),
              ],
            ),
          ),
      ],
    );
  }
}