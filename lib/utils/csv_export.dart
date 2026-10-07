/// Downloads a file in the browser on web; no-op on other platforms.
export 'csv_export_stub.dart' if (dart.library.html) 'csv_export_web.dart';