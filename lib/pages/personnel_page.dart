import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/live_service.dart';
import '../models/api_models.dart';
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
  String _role = 'All';
  String _status = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// A personnel row joined with its live tag telemetry (null when the
  /// assigned tag isn't currently reporting).
  (PersonnelRecord, MinerEntry?)? _liveFor(PersonnelRecord p, Iterable<MinerEntry> miners) {
    final normalized = p.assignedMac?.replaceAll(':', '').replaceAll('-', '').toUpperCase();
    if (normalized == null || normalized.isEmpty) return (p, null);
    try {
      final m = miners.firstWhere((m) => m.mac.toUpperCase() == normalized);
      return (p, m);
    } catch (_) {
      return (p, null);
    }
  }

  List<(PersonnelRecord, MinerEntry?)> _filtered(LiveService live) {
    final rows = live.personnel.map((p) => _liveFor(p, live.state.miners)).whereType<(PersonnelRecord, MinerEntry?)>().toList();
    final q = _search.text.toLowerCase();
    return rows.where((row) {
      final (p, m) = row;
      final ms = p.name.toLowerCase().contains(q) || p.id.toLowerCase().contains(q) || (p.assignedMac ?? '').toLowerCase().contains(q);
      final md = _role == 'All' || (p.role ?? '') == _role;
      final live = m != null ? 'Underground' : 'Not reporting';
      final mst = _status == 'All' || live == _status;
      return ms && md && mst;
    }).toList();
  }

  List<String> _roles(List<PersonnelRecord> personnel) => ['All', ...{for (final p in personnel) if (p.role != null) p.role!}];

  void _openRegister() {
    showDialog(context: context, builder: (_) => const _RegisterDialog());
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final live = context.watch<LiveService>();
    final filtered = _filtered(live);
    final reporting = filtered.where((r) => r.$2 != null).length;
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
                  Text('${live.personnel.length} registered · $reporting currently underground', style: TextStyle(fontSize: 13, color: t.muted)),
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
                    decoration: const InputDecoration(
                      hintText: 'Search by name, ID, or tag MAC…',
                      prefixIcon: Icon(Icons.search, size: 14),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                _dropdown(_roles(live.personnel), _role, (v) => setState(() => _role = v), t),
                _dropdown(['All', 'Underground', 'Not reporting'], _status, (v) => setState(() => _status = v), t),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        live.personnel.isEmpty
                            ? 'No personnel registered yet — use "Register Employee"'
                            : 'No personnel match the filters',
                        style: TextStyle(fontSize: 13, color: t.muted),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _table(filtered, t),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(List<String> items, String value, ValueChanged<String> onChg, SurfaceTokens t) {
    // A filter value may vanish from the data; fall back to 'All'.
    final effective = items.contains(value) ? value : 'All';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.mutedBg,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effective,
          dropdownColor: t.card,
          items: items
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d, style: TextStyle(fontSize: 13, color: t.fg, fontFamily: 'Inter')),
                  ))
              .toList(),
          onChanged: (v) => onChg(v!),
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontFamily: 'Inter'),
          selectedItemBuilder: (context) => items
              .map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(d, style: TextStyle(fontSize: 13, color: t.fg, fontFamily: 'Inter')),
                  ))
              .toList(),
          icon: Icon(Icons.expand_more, size: 16, color: t.muted),
        ),
      ),
    );
  }

  Widget _table(List<(PersonnelRecord, MinerEntry?)> rows, SurfaceTokens t) {
    final headers = ['Emp No', 'Full Name', 'Role', 'Shift', 'BLE Tag', 'Zone', 'Battery', 'Temp', 'Signal', 'Status', 'Last Seen'];
    return DataTable(
      columnSpacing: 16,
      headingRowColor: WidgetStateProperty.all(t.mutedBg.withOpacity(0.4)),
      columns: headers.map((h) => DataColumn(label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.muted)))).toList(),
      rows: rows
          .map((row) {
            final (p, m) = row;
            final emergency = m?.alerts.any((a) => a.type == 'critical') ?? false;
            return DataRow(
              color: WidgetStateProperty.all(emergency ? t.mutedBg.withOpacity(0.15) : null),
              cells: [
                DataCell(Text(p.id, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))),
                DataCell(Row(children: [
                  CircleAvatar(
                      radius: 16,
                      backgroundColor: emergency ? AppColors.red : AppColors.blue600,
                      child: Text(_initials(p.name), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
                ])),
                DataCell(Text(p.role ?? '—', style: TextStyle(fontSize: 11, color: t.muted))),
                DataCell(Badge(label: p.shift ?? '—', color: BadgeColor.blue)),
                DataCell(Text(p.assignedMac ?? '—', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.fg))),
                DataCell(Text(m?.zone ?? '—', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t.fg))),
                DataCell(m?.battery != null ? BatteryBar(value: m!.battery!, width: 56) : Text('—', style: TextStyle(fontSize: 11, color: t.muted))),
                DataCell(m?.temperature != null
                    ? Text('${m!.temperature!.toStringAsFixed(1)}°C', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.fg))
                    : Text('—', style: TextStyle(fontSize: 11, color: t.muted))),
                DataCell(m != null
                    ? Text('${m.rssi.toStringAsFixed(0)} dBm', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted))
                    : Text('—', style: TextStyle(fontSize: 11, color: t.muted))),
                DataCell(m == null
                    ? const Badge(label: 'Not reporting', color: BadgeColor.gray)
                    : emergency
                        ? const Badge(label: 'EMERGENCY', color: BadgeColor.red)
                        : m.moving
                            ? const Badge(label: 'Moving', color: BadgeColor.blue)
                            : const Badge(label: 'Stationary', color: BadgeColor.green)),
                DataCell(Text(m != null ? timeAgoFromEpoch(m.lastSeen) : '—', style: TextStyle(fontSize: 11, color: t.muted))),
              ],
            );
          })
          .toList(),
    );
  }

  String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length > 2 ? 2 : 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _RegisterDialog extends StatefulWidget {
  const _RegisterDialog();

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

/// Registers an employee against the backend `POST /api/personnel`.
/// The backend stores id, name, role, shift and assigned tag; the extra
/// wizard fields (medical, PPE, contacts) are not persisted yet.
class _RegisterDialogState extends State<_RegisterDialog> {
  int _step = 1;
  bool _saving = false;
  String? _error;

  final _empNo = TextEditingController();
  final _firstName = TextEditingController();
  final _surname = TextEditingController();
  final _role = TextEditingController();
  final _tagMac = TextEditingController();
  String _shift = 'Day';

  @override
  void dispose() {
    _empNo.dispose();
    _firstName.dispose();
    _surname.dispose();
    _role.dispose();
    _tagMac.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = '${_firstName.text.trim()} ${_surname.text.trim()}'.trim();
    if (_empNo.text.trim().isEmpty || name.isEmpty) {
      setState(() {
        _step = 1;
        _error = 'Employee number and name are required';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await context.read<LiveService>().savePersonnel(PersonnelRecord(
          _empNo.text.trim(),
          name,
          _role.text.trim().isEmpty ? null : _role.text.trim(),
          _shift,
          _tagMac.text.trim().isEmpty ? null : _tagMac.text.trim().toUpperCase(),
        ));
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = 'Backend rejected the registration (check the employee number is unique and the MAC is valid)';
      });
    }
  }

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
                    tooltip: 'Close',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline, size: 14, color: AppColors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: TextStyle(fontSize: 12, color: t.fg))),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_step == 1) _step1(t) else if (_step == 2) _step2(t) else _step3(t),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () {
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
                    onPressed: _saving ? null : () async { if (_step < 3) { setState(() => _step++); } else { await _save(); } },
                    child: _saving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_step == 3 ? 'Save Employee' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController controller, SurfaceTokens t) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
          const SizedBox(height: 6),
          TextField(controller: controller, decoration: InputDecoration(hintText: hint, isDense: true)),
        ],
      ),
    );
  }

  Widget _step1(SurfaceTokens t) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _field('Employee Number', 'EMP-001', _empNo, t),
        _field('First Name', 'John', _firstName, t),
        _field('Surname', 'Smith', _surname, t),
        _field('Position / Role', 'Underground Miner', _role, t),
        SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shift', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _shift,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: t.mutedBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                ),
                dropdownColor: t.card,
                style: TextStyle(fontSize: 13, color: t.fg, fontFamily: 'Inter'),
                items: ['Day', 'Night', 'Rotating']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 13, color: t.fg, fontFamily: 'Inter'))))
                    .toList(),
                onChanged: (v) => _shift = v ?? 'Day',
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
            _field('Assigned Tag MAC', 'AA:BB:CC:DD:EE:FF', _tagMac, t),
            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medical Expiry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg)),
                  const SizedBox(height: 6),
                  TextField(
                      decoration: const InputDecoration(
                          isDense: true, suffixIcon: Icon(Icons.calendar_today_outlined, size: 14))),
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
                  TextField(
                      decoration: const InputDecoration(
                          isDense: true, suffixIcon: Icon(Icons.calendar_today_outlined, size: 14))),
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