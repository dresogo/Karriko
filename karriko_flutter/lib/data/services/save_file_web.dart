import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Bietet [content] als Datei [name] zum Herunterladen an.
///
/// Der Inhalt verlaesst den Browser nicht: Er wird als Blob im Speicher
/// angelegt und ueber eine Objekt-Adresse heruntergeladen, die danach wieder
/// freigegeben wird.
Future<void> saveTextFile({
  required String name,
  required String content,
  String contentType = 'application/json',
}) async {
  final bytes = utf8.encode(content);
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: '$contentType;charset=utf-8'),
  );
  final adresse = web.URL.createObjectURL(blob);
  final link = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = adresse
    ..download = name
    ..style.display = 'none';
  web.document.body?.append(link);
  link.click();
  link.remove();
  web.URL.revokeObjectURL(adresse);
}
