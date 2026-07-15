import 'package:flutter/material.dart' hide Badge;

import '../data/mock_data.dart';
import '../models/worker.dart';
import '../widgets/badge.dart';
import '../widgets/mine_map.dart';
import '../widgets/worker_tooltip.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  Worker? _hovered;
  Worker? _selected;
  String? _layer; // null | "heatmap" | "gas"

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 760;
        return Container(
          color: const Color(0xFF05101E),
          child: wide ? _row(c) : _column(c),
        );
      },
    );
  }

  Widget _row(BoxConstraints c) => Row(
        children: [
          Expanded(child: _mapArea()),
          SizedBox(width: 288, child: _drawer()),
        ],
      );

  Widget _column(BoxConstraints c) => Column(
        children: [
          Expanded(flex: 3, child: _mapArea()),
          Expanded(flex: 2, child: _drawer()),
        ],
      );

  Widget _mapArea() {
    return Column(
      children: [
        // Controls bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xE60B1F3A),
            border: Border(bottom: BorderSide(color: Color(0x11FFFFFF))),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 720;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('COMMAND CENTRE',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      _livePill(),
                      const Spacer(),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search worker…',
                              hintStyle: TextStyle(color: const Color(0xFF60A5FA).withOpacity(0.5)),
                              prefixIcon: Icon(Icons.search, size: 12, color: const Color(0xFF60A5FA)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.07),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (narrow) const SizedBox(height: 8),
                  Row(
                    children: [
                      if (narrow) const Spacer(),
                      ...['normal', 'heatmap', 'gas'].map((l) {
                        final sel = _layer == l || (l == 'normal' && _layer == null);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _layerBtn(l, sel),
                        );
                      }),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(icon: const Icon(Icons.add, color: Colors.white, size: 16), onPressed: () {}, splashRadius: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.white.withOpacity(0.1)))),
                              child: const Text('100%', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11)),
                            ),
                            IconButton(icon: const Icon(Icons.remove, color: Colors.white, size: 16), onPressed: () {}, splashRadius: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        // Map
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: MineMap(
                  hoveredWorker: _hovered,
                  selectedWorker: _selected,
                  layer: _layer,
                  onHover: (w) {
                    setState(() {
                      _hovered = w;
                      if (w != null) _selected = w;
                    });
                  },
                  onTap: (w) => setState(() => _selected = w),
                ),
              ),
              if (_hovered != null)
                Positioned(top: 16, right: 16, child: WorkerTooltip(w: _hovered!)),
              // Stats overlay
              Positioned(
                bottom: 16,
                left: 16,
                child: Wrap(
                  spacing: 8,
                  children: [
                    _stat('Underground', workers.length, const Color(0xFF3B82F6)),
                    _stat('Emergency', workers.where((w) => w.status == WorkerStatus.emergency).length, const Color(0xFFEF4444)),
                    _stat('Low Battery', workers.where((w) => w.battery < 20).length, const Color(0xFFF59E0B)),
                    _stat('Gateways OK', gateways.where((g) => g.online).length, const Color(0xFF22C55E)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, int value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xE60B1F3A),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xB393C5FD))),
          ],
        ),
      );

  Widget _layerBtn(String l, bool sel) {
    final label = l == 'normal' ? 'Default' : l == 'heatmap' ? 'Heatmap' : 'Gas Overlay';
    return Material(
      color: sel ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _layer = l == 'normal' ? null : l),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: sel ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.1)), borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11, color: sel ? Colors.white : const Color(0xFF93C5FD), fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _livePill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x4D22C55E),
          border: Border.all(color: const Color(0x6622C55E)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Blink(),
            SizedBox(width: 5),
            Text('LIVE', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _drawer() {
    return Container(
      color: const Color(0xFF0B1F3A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x11FFFFFF)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Worker Details', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Click a dot to select', style: TextStyle(color: Color(0x9960A5FA), fontSize: 11)),
              ],
            ),
          ),
          if (_selected != null)
            Expanded(child: _selectedBody())
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 32, color: const Color(0xFF1E3A8A).withOpacity(0.8)),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Hover over a worker dot on the map to view details',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0x9960A5FA), fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          // Personnel list
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x11FFFFFF)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ALL UNDERGROUND',
                    style: TextStyle(color: Color(0x9960A5FA), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                ...workers.take(6).map((w) => _personnelBtn(w)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personnelBtn(Worker w) {
    final sel = _selected?.id == w.id;
    final dot = w.status == WorkerStatus.emergency
        ? const Color(0xFFEF4444)
        : w.battery < 20
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);
    return InkWell(
      onTap: () => setState(() => _selected = w),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: sel ? const Color(0x332563EB) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12))),
            Text(w.zone.split(' ').take(2).join(' '),
                style: const TextStyle(color: Color(0x8060A5FA), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _selectedBody() {
    final w = _selected!;
    final rows = <(String, String)>[
      ("Current Zone", w.zone),
      ("BLE Tag", w.bleTag),
      ("Nearest Gateway", w.gateway),
      ("Signal", "${w.signal} dBm"),
      ("Battery", "${w.battery}%"),
      ("Last Movement", w.lastSeen),
      ("Shift", w.shift),
      ("Nearest Exit", "Main Shaft · 180m"),
      ("Est. Evacuation", "~4 min"),
    ];
    final battColor = w.battery > 60 ? const Color(0xFF22C55E) : w.battery > 30 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(w.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${w.empNo} · ${w.dept}', style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12)),
                    const SizedBox(height: 4),
                    Badge(label: w.status.label, color: w.status == WorkerStatus.emergency ? BadgeColor.red : w.status == WorkerStatus.moving ? BadgeColor.blue : BadgeColor.gray),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 6),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF)))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.$1, style: const TextStyle(color: Color(0x9960A5FA), fontSize: 12)),
                      Text(r.$2, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 12),
          const Text('Battery', style: TextStyle(color: Color(0x9960A5FA), fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: w.battery / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.1),
              color: battColor,
            ),
          ),
          Align(alignment: Alignment.centerRight, child: Text('${w.battery}%', style: TextStyle(color: battColor, fontSize: 12))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(onPressed: () {}, child: const Text('Track')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Blink extends StatefulWidget {
  const _Blink();
  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Opacity(
          opacity: 0.4 + 0.6 * _c.value,
          child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
        ),
      );
}