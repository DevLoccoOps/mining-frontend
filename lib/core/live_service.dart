import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/api_models.dart';
import 'api_config.dart';

enum ConnStatus { connecting, live, offline }

/// Connects to the minesafe backend:
///
/// - WebSocket `/ws/state` for the 500 ms `state_update` broadcast
///   (live miners, zone summaries, active alerts, gateways), with backoff
///   reconnect.
/// - REST polling (`/api/logs`, `/api/personnel`, `/api/tags`) every 20 s
///   for the persisted registry and alert history.
/// - REST polling (`/api/stats`, `/api/telemetry/recent`) every 10 s for the
///   system snapshot and recent continuous readings.
///
/// Exposes everything as [ChangeNotifier] state for `context.watch`.
class LiveService extends ChangeNotifier {
  ConnStatus _status = ConnStatus.connecting;
  LiveState _state = LiveState.empty;
  List<AlertLogRecord> _logs = const [];
  List<PersonnelRecord> _personnel = const [];
  List<TagRecord> _tags = const [];
  StatsSnapshot _stats = StatsSnapshot.empty;
  List<TelemetryRecord> _telemetry = const [];
  DateTime? _lastUpdate;

  ConnStatus get status => _status;
  LiveState get state => _state;
  List<AlertLogRecord> get logs => _logs;
  List<PersonnelRecord> get personnel => _personnel;
  List<TagRecord> get tags => _tags;
  StatsSnapshot get stats => _stats;
  List<TelemetryRecord> get telemetry => _telemetry;
  DateTime? get lastUpdate => _lastUpdate;

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  bool _disposed = false;
  int _backoffSeconds = 1;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  Timer? _statsTimer;

  LiveService() {
    _connect();
    _refreshRest();
    _refreshStats();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refreshRest());
    _statsTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshStats());
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    if (_disposed) return;
    _status = ConnStatus.connecting;
    _safeNotify();

    try {
      final channel = WebSocketChannel.connect(wsUri());
      await channel.ready.timeout(const Duration(seconds: 10));
      if (_disposed) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _backoffSeconds = 1;
      _status = ConnStatus.live;
      _safeNotify();
      _wsSub = channel.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      if (json is! Map<String, dynamic>) return;
      final next = LiveState.fromJson(json);
      if (next == null) return;
      _state = next;
      _lastUpdate = DateTime.now();
      // The backend broadcasts every 500 ms; throttle repaints to ~1/s.
      final now = DateTime.now();
      if (now.difference(_lastNotify).inMilliseconds >= 900) {
        _lastNotify = now;
        _safeNotify();
      } else {
        scheduleMicrotask(_flushNotify);
      }
    } catch (_) {
      // Malformed frame — ignore; the next tick will replace it.
    }
  }

  void _flushNotify() {
    if (_disposed) return;
    final now = DateTime.now();
    if (now.difference(_lastNotify).inMilliseconds >= 900) {
      _lastNotify = now;
      _safeNotify();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _wsSub?.cancel();
    _wsSub = null;
    _channel = null;
    _status = ConnStatus.offline;
    _safeNotify();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _backoffSeconds), () {
      _backoffSeconds = (_backoffSeconds * 2).clamp(1, 30);
      _connect();
    });
  }

  // ── REST polling ──────────────────────────────────────────────────────────

  Future<void> _refreshRest() async {
    if (_disposed) return;
    final client = http.Client();
    try {
      final results = await Future.wait([
        _getJson(client, '/api/logs'),
        _getJson(client, '/api/personnel'),
        _getJson(client, '/api/tags'),
      ]);
      final logsJson = (results[0] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
      _logs = logsJson.map(AlertLogRecord.fromJson).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      _personnel = (results[1] as List?)?.whereType<Map<String, dynamic>>().map(PersonnelRecord.fromJson).toList() ?? const [];
      _tags = (results[2] as List?)?.whereType<Map<String, dynamic>>().map(TagRecord.fromJson).toList() ?? const [];
      _safeNotify();
    } catch (_) {
      // Backend unreachable — keep the last known data; WS status shows offline.
    } finally {
      client.close();
    }
  }

  Future<dynamic> _getJson(http.Client client, String path) async {
    final resp = await client.get(apiUri(path)).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('GET $path -> ${resp.statusCode}');
    return jsonDecode(resp.body);
  }

  /// System snapshot + recent telemetry, on a faster cadence than the
  /// registry poll (these feed the health and analytics pages).
  Future<void> _refreshStats() async {
    if (_disposed) return;
    final client = http.Client();
    try {
      final statsJson = await _getJson(client, '/api/stats');
      final telemetryJson = await _getJson(client, '/api/telemetry/recent');
      final stats = statsJson is Map<String, dynamic> ? StatsSnapshot.fromJson(statsJson) : null;
      if (stats != null) _stats = stats;
      _telemetry = (telemetryJson as List?)?.whereType<Map<String, dynamic>>().map(TelemetryRecord.fromJson).toList() ?? const [];
      _safeNotify();
    } catch (_) {
      // Endpoint may not exist yet on an older backend deployment — keep the
      // last known values.
    } finally {
      client.close();
    }
  }

  // Registers a personnel member or tag (used by admin pages).
  Future<bool> savePersonnel(PersonnelRecord p) => _postJson('/api/personnel', {
        if (p.id.isNotEmpty) 'id': p.id,
        'name': p.name,
        if (p.role != null) 'role': p.role,
        if (p.shift != null) 'shift': p.shift,
        if (p.assignedMac != null) 'assigned_mac': p.assignedMac,
      });

  Future<bool> saveTag(TagRecord t) => _postJson('/api/tags', {
        'mac': t.mac,
        'type': t.type,
        if (t.assignedTo != null) 'assigned_to': t.assignedTo,
      });

  Future<bool> deleteTag(String mac) => _deleteJson('/api/tags/$mac');

  Future<bool> _deleteJson(String path) async {
    try {
      final client = http.Client();
      try {
        final resp = await client.delete(apiUri(path)).timeout(const Duration(seconds: 10));
        final ok = resp.statusCode == 200 || resp.statusCode == 204;
        if (ok) await _refreshRest();
        return ok;
      } finally {
        client.close();
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> _postJson(String path, Map<String, dynamic> body) async {
    try {
      final client = http.Client();
      try {
        final resp = await client
            .post(apiUri(path), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
            .timeout(const Duration(seconds: 10));
        final ok = resp.statusCode == 200 || resp.statusCode == 201;
        if (ok) await _refreshRest();
        return ok;
      } finally {
        client.close();
      }
    } catch (_) {
      return false;
    }
  }

  // ── Derived helpers for UI ─────────────────────────────────────────────────

  /// Personnel name for a tag MAC, or null when unregistered.
  String? nameForMac(String mac) {
    final normalized = mac.replaceAll(':', '').toUpperCase();
    for (final p in _personnel) {
      final assigned = p.assignedMac?.replaceAll(':', '').replaceAll('-', '').toUpperCase();
      if (assigned != null && assigned == normalized) return p.name;
    }
    return null;
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    _statsTimer?.cancel();
    _wsSub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

/// "45s ago" style label from an epoch-seconds timestamp.
String timeAgoFromEpoch(double epochSeconds) {
  final dt = DateTime.fromMillisecondsSinceEpoch((epochSeconds * 1000).round());
  return timeAgo(dt);
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 5) return 'now';
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}