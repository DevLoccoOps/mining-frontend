/// Models for the minesafe backend API (snake_case JSON).
///
/// Shapes match the backend records in StateBroadcaster.java (WebSocket
/// state_update payload) and the JPA entities exposed by the REST
/// controllers (Personnel, Tag, AlertLog).

class ApiAlert {
  final String type; // critical | danger | warning
  final String message;
  const ApiAlert(this.type, this.message);

  static ApiAlert? fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final message = json['message'];
    if (type is! String || message is! String) return null;
    return ApiAlert(type, message);
  }
}

class ZoneSummary {
  final String zone;
  final int total;
  final int critical;
  final int danger;
  final int warning;
  final String avgTemp; // "35.5" or "N/A"
  const ZoneSummary(this.zone, this.total, this.critical, this.danger, this.warning, this.avgTemp);

  static ZoneSummary fromJson(Map<String, dynamic> json) => ZoneSummary(
        (json['zone'] as String?) ?? 'UNKNOWN',
        (json['total'] as num?)?.toInt() ?? 0,
        (json['critical'] as num?)?.toInt() ?? 0,
        (json['danger'] as num?)?.toInt() ?? 0,
        (json['warning'] as num?)?.toInt() ?? 0,
        (json['avg_temp'] as String?) ?? 'N/A',
      );
}

class LiveAlert {
  final String mac;
  final String? name;
  final String zone;
  final String type; // critical | danger | warning
  final String msg;
  const LiveAlert(this.mac, this.name, this.zone, this.type, this.msg);

  static LiveAlert fromJson(Map<String, dynamic> json) => LiveAlert(
        (json['mac'] as String?) ?? '?',
        json['name'] as String?,
        (json['zone'] as String?) ?? 'UNKNOWN',
        (json['type'] as String?) ?? 'warning',
        (json['msg'] as String?) ?? '',
      );
}

class MinerEntry {
  final String mac;
  final String? name;
  final String? zone;
  final String? reporter;
  final double? temperature;
  final int? battery;
  final double distance;
  final double rssi;
  final List<ApiAlert> alerts;
  final bool outdoor;
  final bool moving;
  final double lastSeen; // epoch seconds
  final bool registered;
  const MinerEntry({
    required this.mac,
    this.name,
    this.zone,
    this.reporter,
    this.temperature,
    this.battery,
    required this.distance,
    required this.rssi,
    required this.alerts,
    required this.outdoor,
    required this.moving,
    required this.lastSeen,
    required this.registered,
  });

  static MinerEntry fromJson(Map<String, dynamic> json) => MinerEntry(
        mac: (json['mac'] as String?) ?? '?',
        name: json['name'] as String?,
        zone: json['zone'] as String?,
        reporter: json['reporter'] as String?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        battery: (json['battery'] as num?)?.toInt(),
        distance: (json['distance'] as num?)?.toDouble() ?? 0,
        rssi: (json['rssi'] as num?)?.toDouble() ?? -100,
        alerts: (json['alerts'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ApiAlert.fromJson)
                .whereType<ApiAlert>()
                .toList() ??
            const [],
        outdoor: json['outdoor'] as bool? ?? false,
        moving: json['moving'] as bool? ?? false,
        lastSeen: (json['last_seen'] as num?)?.toDouble() ?? 0,
        registered: json['registered'] as bool? ?? false,
      );
}

/// Gateway liveness entry from the state_update gateways[] array.
class GatewayEntry {
  final String id; // e.g. KNOT_05
  final String zone; // id minus the KNOT_ prefix
  final double rssi;
  final double lastSeen; // epoch seconds
  final int miners; // live miners it currently reports on
  const GatewayEntry(this.id, this.zone, this.rssi, this.lastSeen, this.miners);

  static GatewayEntry fromJson(Map<String, dynamic> json) => GatewayEntry(
        (json['id'] as String?) ?? '?',
        (json['zone'] as String?) ?? '?',
        (json['rssi'] as num?)?.toDouble() ?? -100,
        (json['last_seen'] as num?)?.toDouble() ?? 0,
        (json['miners'] as num?)?.toInt() ?? 0,
      );
}

class PersonnelRecord {
  final String id;
  final String name;
  final String? role;
  final String? shift;
  final String? assignedMac;
  const PersonnelRecord(this.id, this.name, this.role, this.shift, this.assignedMac);

  static PersonnelRecord fromJson(Map<String, dynamic> json) => PersonnelRecord(
        (json['id'] as String?) ?? '',
        (json['name'] as String?) ?? '',
        json['role'] as String?,
        json['shift'] as String?,
        json['assigned_mac'] as String?,
      );
}

class TagRecord {
  final String mac;
  final String type; // indoor | outdoor
  final String? assignedTo;
  const TagRecord(this.mac, this.type, this.assignedTo);

  static TagRecord fromJson(Map<String, dynamic> json) => TagRecord(
        (json['mac'] as String?) ?? '',
        (json['type'] as String?) ?? 'indoor',
        json['assigned_to'] as String?,
      );
}

class AlertLogRecord {
  final int id;
  final String mac;
  final String? minerName;
  final String? zone;
  final double? distM;
  final double? tempC;
  final int? battery;
  final String? alertType;
  final String? alertMsg;
  final DateTime? createdAt;
  const AlertLogRecord({
    required this.id,
    required this.mac,
    this.minerName,
    this.zone,
    this.distM,
    this.tempC,
    this.battery,
    this.alertType,
    this.alertMsg,
    this.createdAt,
  });

  static AlertLogRecord fromJson(Map<String, dynamic> json) => AlertLogRecord(
        id: (json['id'] as num?)?.toInt() ?? 0,
        mac: (json['mac'] as String?) ?? '?',
        minerName: json['miner_name'] as String?,
        zone: json['zone'] as String?,
        distM: (json['dist_m'] as num?)?.toDouble(),
        tempC: (json['temp_c'] as num?)?.toDouble(),
        battery: (json['battery'] as num?)?.toInt(),
        alertType: json['alert_type'] as String?,
        alertMsg: json['alert_msg'] as String?,
        createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      );
}

/// One continuous telemetry reading from GET /api/telemetry/recent.
class TelemetryRecord {
  final int id;
  final String mac;
  final String? minerName;
  final String? zone;
  final String? reporter;
  final double? distM;
  final double? tempC;
  final int? battery;
  final double? rssi;
  final bool? outdoor;
  final bool? moving;
  final bool? registered;
  final DateTime? createdAt;
  const TelemetryRecord({
    required this.id,
    required this.mac,
    this.minerName,
    this.zone,
    this.reporter,
    this.distM,
    this.tempC,
    this.battery,
    this.rssi,
    this.outdoor,
    this.moving,
    this.registered,
    this.createdAt,
  });

  static TelemetryRecord fromJson(Map<String, dynamic> json) => TelemetryRecord(
        id: (json['id'] as num?)?.toInt() ?? 0,
        mac: (json['mac'] as String?) ?? '?',
        minerName: json['miner_name'] as String?,
        zone: json['zone'] as String?,
        reporter: json['reporter'] as String?,
        distM: (json['dist_m'] as num?)?.toDouble(),
        tempC: (json['temp_c'] as num?)?.toDouble(),
        battery: (json['battery'] as num?)?.toInt(),
        rssi: (json['rssi'] as num?)?.toDouble(),
        outdoor: json['outdoor'] as bool?,
        moving: json['moving'] as bool?,
        registered: json['registered'] as bool?,
        createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      );
}

/// System snapshot from GET /api/stats.
class StatsSnapshot {
  final double uptimeSeconds;
  final double serverTime; // epoch seconds, for clock-offset correction
  final int liveMiners;
  final int activeGateways;
  final int wsClients;
  final int personnelCount;
  final int tagCount;
  final int alertLogCount;
  final int telemetryCount;
  static const empty =
      StatsSnapshot(0, 0, 0, 0, 0, 0, 0, 0, 0);

  const StatsSnapshot(this.uptimeSeconds, this.serverTime, this.liveMiners,
      this.activeGateways, this.wsClients, this.personnelCount, this.tagCount,
      this.alertLogCount, this.telemetryCount);

  static StatsSnapshot? fromJson(Map<String, dynamic> json) {
    if (json['live_miners'] is! num) return null;
    return StatsSnapshot(
      (json['uptime_seconds'] as num?)?.toDouble() ?? 0,
      (json['server_time'] as num?)?.toDouble() ?? 0,
      (json['live_miners'] as num?)?.toInt() ?? 0,
      (json['active_gateways'] as num?)?.toInt() ?? 0,
      (json['ws_clients'] as num?)?.toInt() ?? 0,
      (json['personnel_count'] as num?)?.toInt() ?? 0,
      (json['tag_count'] as num?)?.toInt() ?? 0,
      (json['alert_log_count'] as num?)?.toInt() ?? 0,
      (json['telemetry_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Full state_update payload from the /ws/state WebSocket.
class LiveState {
  final int totalMiners;
  final List<ZoneSummary> zones;
  final List<LiveAlert> alerts;
  final List<MinerEntry> miners;
  final List<GatewayEntry> gateways;
  static const empty = LiveState(0, [], [], [], []);

  const LiveState(this.totalMiners, this.zones, this.alerts, this.miners, this.gateways);

  static LiveState? fromJson(Map<String, dynamic> json) {
    if (json['total_miners'] is! num) return null;
    return LiveState(
      (json['total_miners'] as num).toInt(),
      (json['zones'] as List?)?.whereType<Map<String, dynamic>>().map(ZoneSummary.fromJson).toList() ?? const [],
      (json['alerts'] as List?)?.whereType<Map<String, dynamic>>().map(LiveAlert.fromJson).toList() ?? const [],
      (json['miners'] as List?)?.whereType<Map<String, dynamic>>().map(MinerEntry.fromJson).toList() ?? const [],
      (json['gateways'] as List?)?.whereType<Map<String, dynamic>>().map(GatewayEntry.fromJson).toList() ?? const [],
    );
  }
}