/// Base URL of the minesafe backend.
///
/// Override at build time for other environments:
///   flutter build web --dart-define=API_BASE_URL=http://localhost:8080
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://minesafe-production-4634.up.railway.app',
);

Uri apiUri(String path, [Map<String, String>? query]) => Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);

/// The /ws/state endpoint speaks wss:// when the API is https.
Uri wsUri() {
  final base = Uri.parse(apiBaseUrl);
  final scheme = base.scheme == 'https' ? 'wss' : 'ws';
  return base.replace(scheme: scheme, path: '${base.path == '/' ? '' : base.path}/ws/state');
}