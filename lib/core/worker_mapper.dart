import 'dart:convert';

import '../models/api_models.dart';
import '../models/worker.dart';
import 'live_service.dart';

/// Maps a live backend [MinerEntry] onto the map's [Worker] model, including a
/// deterministic zone → map-position estimate.
///
/// The backend only knows which gateway (reporter) last saw a tag, so the
/// position is an estimate: known zone keywords (levels/tunnels/shaft) map to
/// their map region, anything else is hashed onto a walkable anchor point.
/// The MAC hash adds a small stable jitter so a zone's miners don't stack.
Worker workerFromMiner(MinerEntry m, {String? shift}) {
  final pos = _zonePosition(m.zone, m.mac);
  final hasEmergency = m.alerts.any((a) => a.type == 'critical' || a.type == 'danger');
  return Worker(
    id: m.mac.hashCode,
    name: m.name ?? 'Unknown',
    empNo: m.mac.length >= 8 ? m.mac.substring(0, 8) : m.mac,
    dept: m.zone ?? 'unknown zone',
    zone: m.zone ?? 'UNKNOWN',
    bleTag: m.mac,
    battery: m.battery ?? 0,
    signal: m.rssi.round(),
    lastSeen: timeAgoFromEpoch(m.lastSeen),
    gateway: m.reporter ?? '—',
    status: hasEmergency
        ? WorkerStatus.emergency
        : m.outdoor
            ? WorkerStatus.surface
            : m.moving
                ? WorkerStatus.moving
                : WorkerStatus.stationary,
    shift: shift ?? '—',
    x: pos.$1,
    y: pos.$2,
  );
}

/// Walkable anchor points inside levels/tunnels, viewBox 820x520.
const _anchors = <(double, double)>[
  // Level 1 (y ≈ 143)
  (120.0, 143.0), (220.0, 143.0), (330.0, 143.0), (470.0, 143.0),
  (560.0, 143.0), (660.0, 143.0), (730.0, 143.0),
  // Level 2 (y ≈ 283)
  (140.0, 283.0), (240.0, 283.0), (330.0, 283.0), (470.0, 283.0),
  (520.0, 283.0), (560.0, 283.0), (730.0, 283.0),
  // Level 3 (y ≈ 428)
  (140.0, 428.0), (240.0, 428.0), (330.0, 428.0), (470.0, 428.0),
  (540.0, 428.0), (600.0, 428.0), (640.0, 428.0),
  // Tunnels A (x≈192), B (x≈132), C (x≈614) — vertical runs
  (192.0, 200.0), (192.0, 250.0), (132.0, 320.0), (132.0, 360.0),
  (614.0, 320.0), (614.0, 360.0), (410.0, 90.0), (410.0, 240.0),
  (410.0, 380.0), (672.0, 100.0), (672.0, 200.0),
];

(int, double) _hash(String s) {
  final bytes = utf8.encode(s);
  var h = 2166136261;
  for (final b in bytes) {
    h ^= b;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  return (h, (h % 1000) / 1000.0);
}

/// Estimated (x, y) for a zone: keyword match first, then a hashed anchor.
(double, double) _zonePosition(String? zone, String mac) {
  final (_, macJit) = _hash(mac);
  final z = (zone ?? '').toUpperCase();

  double jitter(double v, double span) => v + (macJit - 0.5) * span;

  // Known map regions win over the hash.
  if (z.contains('LEVEL 1') || z.contains('L1')) return (jitter(410, 600), 143);
  if (z.contains('LEVEL 2') || z.contains('L2')) return (jitter(410, 600), 283);
  if (z.contains('LEVEL 3') || z.contains('L3')) return (jitter(370, 480), 428);
  if (z.contains('TUNNEL A')) return (192, jitter(205, 100));
  if (z.contains('TUNNEL B')) return (132, jitter(325, 80));
  if (z.contains('TUNNEL C')) return (614, jitter(325, 80));
  if (z.contains('SHAFT')) return (410, jitter(240, 340));

  final (h, _) = _hash(z);
  final anchor = _anchors[h % _anchors.length];
  return (jitter(anchor.$1, 28), jitter(anchor.$2, 14));
}