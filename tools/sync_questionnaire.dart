// Haelt die Kopie der Fragendefinition fuer den Appwrite-Storage mit dem
// Original in der Flutter-App gleich.
//
// Es gibt zwei Dateien, weil sie zwei Wege gehen: Die eine wird als Asset in
// die App gebaut und ist der Rueckfall, wenn der Storage nicht erreichbar ist;
// die andere wird in den Bucket `questionnaires` hochgeladen und ist im Betrieb
// die Quelle. Sie muessen Zeichen fuer Zeichen uebereinstimmen — sonst rechnet
// der Server mit einer anderen Fassung als der Client anzeigt.
//
// Original ist immer die Fassung in der App. Diese Datei kopiert nur.
//
// Aufruf:
//
//   dart run tools/sync_questionnaire.dart           kopiert
//   dart run tools/sync_questionnaire.dart --pruefen meldet Abweichungen, aendert nichts
//
// Der Probelauf ist fuer die CI gedacht: Er endet mit Code 1, wenn jemand das
// Original geaendert und die Kopie vergessen hat.

import 'dart:convert';
import 'dart:io';

const _original = 'karriko_flutter/assets/questionnaire';
const _kopie = 'appwrite/questionnaires';

void main(List<String> args) {
  final nurPruefen = args.contains('--pruefen');

  final quelle = Directory(_original);
  if (!quelle.existsSync()) {
    stderr.writeln(
      'Nicht gefunden: $_original\n'
      'Das Skript laeuft im Wurzelverzeichnis des Repositories.',
    );
    exit(1);
  }

  final dateien =
      quelle
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  if (dateien.isEmpty) {
    stderr.writeln('Keine JSON-Datei in $_original.');
    exit(1);
  }

  Directory(_kopie).createSync(recursive: true);

  var abweichungen = 0;

  for (final datei in dateien) {
    final name = datei.uri.pathSegments.last;
    final inhalt = datei.readAsStringSync();

    // Erst pruefen, ob es ueberhaupt gueltiges JSON ist. Eine kaputte Datei in
    // den Storage zu laden faellt sonst erst dort auf, und dort ist die
    // Rueckmeldung schlechter.
    try {
      jsonDecode(inhalt);
    } on FormatException catch (e) {
      stderr.writeln('✗ $name ist kein gueltiges JSON: ${e.message}');
      exit(1);
    }

    final ziel = File('$_kopie/$name');
    final gleich = ziel.existsSync() && ziel.readAsStringSync() == inhalt;

    if (gleich) {
      print('· $name unveraendert');
      continue;
    }

    abweichungen++;
    if (nurPruefen) {
      print('✗ $name weicht ab');
      continue;
    }

    ziel.writeAsStringSync(inhalt);
    print('+ $name kopiert');
  }

  if (nurPruefen && abweichungen > 0) {
    stderr.writeln(
      '\n$abweichungen Datei(en) weichen ab. '
      'Mit `dart run tools/sync_questionnaire.dart` angleichen.',
    );
    exit(1);
  }
}
