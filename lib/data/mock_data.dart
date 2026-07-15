import 'dart:math';

import '../models/alert_item.dart';
import '../models/ble_device.dart';
import '../models/gateway.dart';
import '../models/recent_event.dart';
import '../models/worker.dart';

final List<Worker> workers = [
  Worker(id: 1, name: "John Smith", empNo: "EMP-001", dept: "Mining", zone: "Tunnel A", bleTag: "TAG-1023", battery: 85, signal: -62, lastSeen: "30s ago", gateway: "KNOT-05", status: WorkerStatus.moving, shift: "Day", x: 192, y: 224),
  Worker(id: 2, name: "Sarah Johnson", empNo: "EMP-002", dept: "Drilling", zone: "Level 1 East", bleTag: "TAG-1045", battery: 42, signal: -71, lastSeen: "15s ago", gateway: "KNOT-02", status: WorkerStatus.stationary, shift: "Day", x: 580, y: 152),
  Worker(id: 3, name: "Michael Brown", empNo: "EMP-003", dept: "Blasting", zone: "Tunnel B", bleTag: "TAG-1067", battery: 91, signal: -58, lastSeen: "5s ago", gateway: "KNOT-08", status: WorkerStatus.moving, shift: "Day", x: 133, y: 376),
  Worker(id: 4, name: "David Wilson", empNo: "EMP-004", dept: "Engineering", zone: "Main Junction", bleTag: "TAG-1089", battery: 17, signal: -80, lastSeen: "2m ago", gateway: "KNOT-01", status: WorkerStatus.emergency, shift: "Day", x: 410, y: 299),
  Worker(id: 5, name: "Emma Davis", empNo: "EMP-005", dept: "Safety", zone: "Level 3 West", bleTag: "TAG-1112", battery: 73, signal: -63, lastSeen: "45s ago", gateway: "KNOT-12", status: WorkerStatus.moving, shift: "Night", x: 248, y: 452),
  Worker(id: 6, name: "Robert Taylor", empNo: "EMP-006", dept: "Mining", zone: "Tunnel C", bleTag: "TAG-1134", battery: 56, signal: -70, lastSeen: "10s ago", gateway: "KNOT-09", status: WorkerStatus.moving, shift: "Day", x: 613, y: 376),
  Worker(id: 7, name: "Lisa Anderson", empNo: "EMP-007", dept: "Ventilation", zone: "Vent Shaft", bleTag: "TAG-1156", battery: 88, signal: -55, lastSeen: "20s ago", gateway: "KNOT-11", status: WorkerStatus.stationary, shift: "Day", x: 671, y: 228),
  Worker(id: 8, name: "James Martinez", empNo: "EMP-008", dept: "Pump Ops", zone: "Pump Station", bleTag: "TAG-1178", battery: 34, signal: -75, lastSeen: "1m ago", gateway: "KNOT-14", status: WorkerStatus.stationary, shift: "Day", x: 91, y: 452),
  Worker(id: 9, name: "Chen Wei", empNo: "EMP-009", dept: "Mining", zone: "Level 2 East", bleTag: "TAG-1201", battery: 62, signal: -67, lastSeen: "8s ago", gateway: "KNOT-05", status: WorkerStatus.moving, shift: "Day", x: 643, y: 302),
  Worker(id: 10, name: "Priya Patel", empNo: "EMP-010", dept: "Geology", zone: "Level 1 West", bleTag: "TAG-1223", battery: 79, signal: -60, lastSeen: "12s ago", gateway: "KNOT-03", status: WorkerStatus.moving, shift: "Day", x: 270, y: 152),
  Worker(id: 11, name: "Marcus Johnson", empNo: "EMP-011", dept: "Maintenance", zone: "Level 2 West", bleTag: "TAG-1245", battery: 11, signal: -82, lastSeen: "3m ago", gateway: "KNOT-04", status: WorkerStatus.stationary, shift: "Day", x: 300, y: 302),
];

final List<Gateway> gateways = [
  Gateway(id: 1, name: "KNOT-01", location: "Main Junction L2", signal: -45, power: "PoE", ups: true, temperature: 28, online: true, lastComm: "2s ago", batteryHealth: 92),
  Gateway(id: 2, name: "KNOT-02", location: "Level 1 East", signal: -52, power: "PoE", ups: true, temperature: 24, online: true, lastComm: "3s ago", batteryHealth: 88),
  Gateway(id: 3, name: "KNOT-03", location: "Level 1 West", signal: -58, power: "PoE", ups: false, temperature: 26, online: true, lastComm: "4s ago", batteryHealth: 95),
  Gateway(id: 4, name: "KNOT-04", location: "Level 2 West", signal: -61, power: "Battery", ups: false, temperature: 31, online: true, lastComm: "6s ago", batteryHealth: 67),
  Gateway(id: 5, name: "KNOT-05", location: "Tunnel A Mid", signal: -67, power: "PoE", ups: true, temperature: 29, online: true, lastComm: "2s ago", batteryHealth: 91),
  Gateway(id: 6, name: "KNOT-06", location: "Level 3 Central", signal: -71, power: "Battery", ups: false, temperature: 35, online: true, lastComm: "8s ago", batteryHealth: 44),
  Gateway(id: 7, name: "KNOT-07", location: "Level 3 West", signal: -74, power: "Battery", ups: false, temperature: 33, online: false, lastComm: "18m ago", batteryHealth: 12),
  Gateway(id: 8, name: "KNOT-08", location: "Tunnel B Lower", signal: -69, power: "PoE", ups: true, temperature: 30, online: true, lastComm: "5s ago", batteryHealth: 83),
  Gateway(id: 9, name: "KNOT-09", location: "Tunnel C Mid", signal: -63, power: "PoE", ups: false, temperature: 27, online: true, lastComm: "3s ago", batteryHealth: 78),
  Gateway(id: 10, name: "KNOT-10", location: "Ventilation Shaft", signal: -55, power: "PoE", ups: true, temperature: 22, online: true, lastComm: "1s ago", batteryHealth: 97),
];

final List<AlertItem> alerts = [
  AlertItem(id: 1, type: "Emergency", message: "Emergency button pressed — David Wilson, Main Junction", time: "2 min ago", severity: AlertSeverity.critical, location: "Main Junction", status: AlertStatus.open),
  AlertItem(id: 2, type: "Gas", message: "Methane above threshold in Tunnel B Lower section", time: "5 min ago", severity: AlertSeverity.critical, location: "Tunnel B", status: AlertStatus.inProgress, assigned: "Safety Team"),
  AlertItem(id: 3, type: "Battery", message: "TAG-1245 critically low (11%) — Marcus Johnson", time: "8 min ago", severity: AlertSeverity.warning, location: "Level 2 West", status: AlertStatus.open),
  AlertItem(id: 4, type: "Battery", message: "TAG-1089 low battery (17%) — David Wilson", time: "12 min ago", severity: AlertSeverity.warning, location: "Main Junction", status: AlertStatus.open),
  AlertItem(id: 5, type: "Gateway", message: "KNOT-07 offline — Level 3 West, 18 min downtime", time: "18 min ago", severity: AlertSeverity.warning, location: "Level 3 West", status: AlertStatus.inProgress, assigned: "IT Team"),
  AlertItem(id: 6, type: "Communication", message: "Signal loss for TAG-1178 — James Martinez at Pump Station", time: "22 min ago", severity: AlertSeverity.warning, location: "Pump Station", status: AlertStatus.closed),
  AlertItem(id: 7, type: "Geofence", message: "Michael Brown entered restricted zone in Tunnel B Lower", time: "35 min ago", severity: AlertSeverity.critical, location: "Tunnel B Lower", status: AlertStatus.inProgress),
  AlertItem(id: 8, type: "Medical", message: "Medical distress signal — Priya Patel, first aid dispatched", time: "1h ago", severity: AlertSeverity.critical, location: "Level 1 West", status: AlertStatus.closed),
  AlertItem(id: 9, type: "SOS", message: "SOS activated — Emma Davis exiting Level 3", time: "2h ago", severity: AlertSeverity.critical, location: "Level 3", status: AlertStatus.closed),
];

final List<RecentEvent> recentEvents = [
  RecentEvent(id: 1, color: 0xFF3B82F6, msg: "John Smith entered Tunnel A", time: "30s ago"),
  RecentEvent(id: 2, color: 0xFF3B82F6, msg: "BLE Tag TAG-1023 detected at KNOT-05", time: "45s ago"),
  RecentEvent(id: 3, color: 0xFFEF4444, msg: "Emergency button pressed — David Wilson", time: "2m ago"),
  RecentEvent(id: 4, color: 0xFFEF4444, msg: "Gas alert in Tunnel B Lower section", time: "5m ago"),
  RecentEvent(id: 5, color: 0xFFF59E0B, msg: "TAG-1245 battery critically low (11%)", time: "8m ago"),
  RecentEvent(id: 6, color: 0xFFEF4444, msg: "Gateway KNOT-07 offline — Level 3 West", time: "18m ago"),
  RecentEvent(id: 7, color: 0xFFF59E0B, msg: "Michael Brown entered restricted zone", time: "35m ago"),
  RecentEvent(id: 8, color: 0xFF22C55E, msg: "Ahmed Al-Rashid exited mine to surface", time: "45m ago"),
  RecentEvent(id: 9, color: 0xFF3B82F6, msg: "Visitor group (3 personnel) entered Level 1", time: "1h ago"),
  RecentEvent(id: 10, color: 0xFF22C55E, msg: "Medical alert resolved — Priya Patel", time: "1h ago"),
];

final List<BLEDevice> bleDevices = List.generate(28, (i) {
  final rand = Random(i);
  final battery = rand.nextInt(100);
  final status = i < 20
      ? "Assigned"
      : i < 24
          ? "Available"
          : i < 26
              ? "Low Battery"
              : "Maintenance";
  return BLEDevice(
    id: i + 1,
    tag: "TAG-${1000 + i * 11}",
    battery: i < 20 ? workers[i % workers.length].battery : battery,
    firmware: "v2.4.${rand.nextInt(5)}",
    status: status,
    employee: i < 20 ? workers[i % workers.length].name : "—",
    lastDetected: i < 20 ? workers[i % workers.length].lastSeen : "—",
  );
});

// ── Chart datasets ────────────────────────────────────────────────────────────

class BatterySlice {
  final String name;
  final int value;
  final int color;
  const BatterySlice(this.name, this.value, this.color);
}

final List<BatterySlice> batteryPie = [
  BatterySlice("80-100%", 5, 0xFF22C55E),
  BatterySlice("60-79%", 3, 0xFF3B82F6),
  BatterySlice("40-59%", 2, 0xFFF59E0B),
  BatterySlice("20-39%", 1, 0xFFEF4444),
  BatterySlice("<20%", 2, 0xFF7C3AED),
];

class ZoneCount {
  final String zone;
  final int n;
  const ZoneCount(this.zone, this.n);
}

final List<ZoneCount> workerDist = [
  ZoneCount("Tunnel A", 3),
  ZoneCount("Tunnel B", 2),
  ZoneCount("Tunnel C", 2),
  ZoneCount("Level 1", 4),
  ZoneCount("Level 2", 3),
  ZoneCount("Level 3", 2),
  ZoneCount("Pump/Vent", 2),
];

class TimePoint {
  final String t;
  final double v;
  final double n;
  const TimePoint(this.t, this.v, this.n);
}

final List<TimePoint> signalTrend = [
  TimePoint("06:00", -58, 8), TimePoint("07:00", -61, 14),
  TimePoint("08:00", -65, 22), TimePoint("09:00", -63, 28),
  TimePoint("10:00", -62, 31), TimePoint("11:00", -59, 29),
  TimePoint("12:00", -64, 25), TimePoint("13:00", -67, 27),
  TimePoint("14:00", -66, 30), TimePoint("15:00", -63, 28),
  TimePoint("16:00", -60, 24), TimePoint("Now", -62, 18),
];

final List<TimePoint> personnelTrend = signalTrend;

class GatewayUptime {
  final String name;
  final double uptime;
  const GatewayUptime(this.name, this.uptime);
}

final List<GatewayUptime> gatewayUptime = List.generate(gateways.length, (i) {
  final g = gateways[i];
  return GatewayUptime(
    g.name,
    g.online ? 95 + Random(i).nextDouble() * 5 : 62,
  );
});

// Audit log preview (admin page)
class AuditLog {
  final String user;
  final String action;
  final String time;
  final String type; // "Alert" | "Create" | "System" | "Update"
  const AuditLog(this.user, this.action, this.time, this.type);
}

final List<AuditLog> auditLogs = [
  AuditLog("James Adams", "Registered employee EMP-012", "10:24:05", "Create"),
  AuditLog("Sarah Johnson", "Assigned TAG-1267 to EMP-012", "10:25:13", "Update"),
  AuditLog("System", "KNOT-07 offline alert triggered", "09:47:32", "Alert"),
  AuditLog("James Adams", "Closed incident #ALR-006", "09:52:01", "Update"),
  AuditLog("System", "Daily backup completed successfully", "03:00:00", "System"),
];