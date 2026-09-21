import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Eine ausgewaehlte Datei.
class PickedFile {
  final String name;
  final List<int> bytes;
  final String? contentType;

  const PickedFile({
    required this.name,
    required this.bytes,
    this.contentType,
  });

  int get size => bytes.length;
}

/// Oeffnet den Dateidialog des Browsers.
///
/// `null`, wenn abgebrochen wurde. Ein Abbruch meldet sich nicht — der Browser
/// loest kein Ereignis aus, wenn jemand den Dialog schliesst. Deshalb bleibt
/// das Future dann offen, bis das Element aufgeraeumt wird; der aufrufende
/// Bildschirm haelt seinen Ladezustand entsprechend an der Rueckgabe fest und
/// nicht an einem Zeitgeber.
Future<PickedFile?> pickFile({List<String> extensions = const []}) {
  final abschluss = Completer<PickedFile?>();

  final eingabe = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = extensions.isEmpty
        ? ''
        : extensions.map((endung) => '.$endung').join(',')
    ..style.display = 'none';

  void aufraeumen() => eingabe.remove();

  eingabe.onchange = (web.Event _) {
    final dateien = eingabe.files;
    if (dateien == null || dateien.length == 0) {
      aufraeumen();
      if (!abschluss.isCompleted) abschluss.complete(null);
      return;
    }

    final datei = dateien.item(0)!;
    final leser = web.FileReader();

    leser.onload = (web.Event _) {
      aufraeumen();
      final ergebnis = leser.result;
      if (ergebnis == null) {
        if (!abschluss.isCompleted) abschluss.complete(null);
        return;
      }
      final bytes = (ergebnis as JSArrayBuffer).toDart.asUint8List();
      if (!abschluss.isCompleted) {
        abschluss.complete(PickedFile(
          name: datei.name,
          bytes: bytes,
          contentType: datei.type.isEmpty ? null : datei.type,
        ));
      }
    }.toJS;

    leser.onerror = (web.Event _) {
      aufraeumen();
      if (!abschluss.isCompleted) abschluss.complete(null);
    }.toJS;

    leser.readAsArrayBuffer(datei);
  }.toJS;

  web.document.body?.append(eingabe);
  eingabe.click();

  return abschluss.future;
}
