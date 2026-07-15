import 'package:flutter/material.dart';

import '../models/worker.dart';
import '../utils/helpers.dart';

class WorkerTooltip extends StatelessWidget {
  final Worker w;
  const WorkerTooltip({super.key, required this.w});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ("Zone", w.zone),
      ("BLE Tag", w.bleTag),
      ("Battery", "${w.battery}%"),
      ("Signal", "${w.signal} dBm (${signalLabel(w.signal)})"),
      ("Last Detected", w.lastSeen),
      ("Nearest Gateway", w.gateway),
      ("Movement", w.status.label),
    ];
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 256,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1F3A),
          border: Border.all(color: const Color(0x991E3A8A)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: const Color(0xFF1D4ED8), child: Text(w.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text("${w.empNo} · ${w.dept}", style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.only(top: 12), child: Divider(color: Color(0x22FFFFFF), height: 1)),
            const SizedBox(height: 8),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.$1, style: const TextStyle(color: Color(0x9960A5FA), fontSize: 11)),
                      Flexible(child: Text(r.$2, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.end)),
                    ],
                  ),
                )),
            const Padding(padding: EdgeInsets.only(top: 8), child: Divider(color: Color(0x22FFFFFF), height: 1)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Status", style: TextStyle(color: Color(0x9960A5FA), fontSize: 11)),
                _statusChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip() {
    final isEmergency = w.status == WorkerStatus.emergency;
    final isMoving = w.status == WorkerStatus.moving;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isEmergency
            ? const Color(0x33EF4444)
            : isMoving
                ? const Color(0x333B82F6)
                : const Color(0x339CA3AF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        w.status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isEmergency ? const Color(0xFFFCA5A5) : isMoving ? const Color(0xFF93C5FD) : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}