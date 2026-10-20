import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

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

/// Zeigt [bytes] in einem neuen Tab an, etwa einen Nachweis als PDF oder Bild
/// (T-2.20). Die Daten bleiben im Browser; die Objekt-Adresse wird nach einer
/// Minute freigegeben, dann hat der Tab sie geladen.
Future<void> openBytesInNewTab(List<int> bytes,
    {required String mimeType}) async {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final adresse = web.URL.createObjectURL(blob);
  web.window.open(adresse, '_blank', 'noopener');
  Future<void>.delayed(
    const Duration(minutes: 1),
    () => web.URL.revokeObjectURL(adresse),
  );
}
