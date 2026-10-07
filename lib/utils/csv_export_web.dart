// Web-only CSV download via an anchor click.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileWeb(String name, List<int> bytes) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = name
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}