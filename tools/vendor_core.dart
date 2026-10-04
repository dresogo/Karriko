// Kopiert die gemeinsamen Dart-Pakete in jede Appwrite Function.
//
// Warum das nötig ist
// -------------------
// Appwrite laedt beim Deployment **nur das Wurzelverzeichnis der Function**
// hoch und fuehrt dort `dart pub get` aus. Eine Pfadabhaengigkeit nach
// `../../packages/questionnaire_core` zeigt im Build ins Leere, und der Build
// bricht ab.
//
// Die Alternativen und warum nicht
// --------------------------------
//   * Git-Abhaengigkeit auf das oeffentliche Repository: koppelt jedes
//     Deployment an einen vorher gepushten Commit.
//   * `providerRootDirectory` auf die Repository-Wurzel: laedt das ganze Repo
//     fuer jede der sechs Functions hoch.
//   * Auf pub.dev veroeffentlichen: kommt fuer internen Code nicht infrage.
//
// Das Kopieren kostet einen Schritt vor dem Push, braucht dafuer kein Netz und
// ist reproduzierbar.
//
// Aufruf
// ------
//
//   dart run tools/vendor_core.dart            kopiert
//   dart run tools/vendor_core.dart --pruefen  meldet Abweichungen, aendert nichts
//
// Der Probelauf ist fuer die CI und fuer den Moment vor einem Push: Er endet
// mit Code 1, wenn eine Function mit veralteter Logik laufen wuerde.

import 'dart:convert';
import 'dart:io';

const _pakete = ['questionnaire_core', 'karriko_functions'];
const _funktionen = 'appwrite/functions';

/// Was kopiert wird. Tests, Beispiele und Build-Reste bleiben draussen — sie
/// vergroessern das Deployment und werden nie ausgefuehrt.
const _ordner = ['lib'];
const _dateien = ['pubspec.yaml', 'README.md', 'LICENSE'];

void main(List<String> args) {
  final nurPruefen = args.contains('--pruefen');

  final funktionen = Directory(_funktionen);
  if (!funktionen.existsSync()) {
    stderr.writeln(
      'Nicht gefunden: $_funktionen\n'
      'Das Skript laeuft im Wurzelverzeichnis des Repositories.',
    );
    exit(1);
  }

  final ziele =
      funktionen
          .listSync()
          .whereType<Directory>()
          .where((d) => File('${d.path}/pubspec.yaml').existsSync())
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  if (ziele.isEmpty) {
    stderr.writeln('Keine Function unter $_funktionen.');
    exit(1);
  }

  var abweichungen = 0;

  for (final paket in _pakete) {
    final quelle = Directory('packages/$paket');
    if (!quelle.existsSync()) {
      stderr.writeln('Paket fehlt: ${quelle.path}');
      exit(1);
    }

    final inhalt = _sammeln(quelle);
    final stempel = _stempel(inhalt);

    for (final funktion in ziele) {
      final ziel = Directory('${funktion.path}/vendor/$paket');
      final name = funktion.uri.pathSegments.where((s) => s.isNotEmpty).last;

      if (_gleich(ziel, inhalt, stempel)) {
        print('· $name/$paket unveraendert');
        continue;
      }

      abweichungen++;
      if (nurPruefen) {
        print('✗ $name/$paket weicht ab');
        continue;
      }

      if (ziel.existsSync()) ziel.deleteSync(recursive: true);
      ziel.createSync(recursive: true);
      inhalt.forEach((relativ, bytes) {
        final datei = File('${ziel.path}/$relativ')
          ..parent.createSync(recursive: true);
        datei.writeAsBytesSync(bytes);
      });
      // Der Stempel macht sichtbar, aus welchem Stand die Kopie ist. Ohne ihn
      // laesst sich nicht unterscheiden, ob eine Function veraltete Logik
      // traegt oder ob nur die Dateizeiten abweichen.
      File('${ziel.path}/VENDORED').writeAsStringSync('$stempel\n');
      print('+ $name/$paket kopiert');
    }
  }

  if (nurPruefen && abweichungen > 0) {
    stderr.writeln(
      '\n$abweichungen Kopie(n) weichen ab. Mit '
      '`dart run tools/vendor_core.dart` angleichen, sonst laufen die '
      'Functions mit veralteter Logik.',
    );
    exit(1);
  }

  if (!nurPruefen) {
    print(
      '\nHinweis: vendor/ steht in .gitignore und gehoert nicht ins '
      'Repository.\nVor jedem `appwrite push functions` erneut laufen '
      'lassen.',
    );
  }
}

/// Alle zu kopierenden Dateien, relativ zum Paketwurzelverzeichnis.
Map<String, List<int>> _sammeln(Directory paket) {
  final out = <String, List<int>>{};

  for (final name in _dateien) {
    final datei = File('${paket.path}/$name');
    if (datei.existsSync()) out[name] = datei.readAsBytesSync();
  }

  for (final name in _ordner) {
    final ordner = Directory('${paket.path}/$name');
    if (!ordner.existsSync()) continue;
    for (final eintrag in ordner.listSync(recursive: true)) {
      if (eintrag is! File) continue;
      final relativ = eintrag.path
          .substring(paket.path.length + 1)
          .replaceAll(r'\', '/');
      out[relativ] = eintrag.readAsBytesSync();
    }
  }

  return out;
}

/// Ein Fingerabdruck des Inhalts, nicht der Dateizeiten.
///
/// Ohne den waere jede Kopie nach einem Checkout „veraendert", und der
/// Probelauf wuerde bei jedem Lauf meckern.
String _stempel(Map<String, List<int>> inhalt) {
  final teile = inhalt.keys.toList()..sort();
  final puffer = StringBuffer();
  for (final name in teile) {
    puffer.write('$name:${inhalt[name]!.length};');
  }
  return base64Url.encode(utf8.encode(puffer.toString())).substring(0, 32);
}

bool _gleich(Directory ziel, Map<String, List<int>> inhalt, String stempel) {
  final marke = File('${ziel.path}/VENDORED');
  if (!marke.existsSync()) return false;
  if (marke.readAsStringSync().trim() != stempel) return false;

  // Stempel allein reicht nicht: Er kennt nur Namen und Laengen. Bei gleicher
  // Laenge und anderem Inhalt — eine geaenderte Zahl, ein umgedrehtes
  // Vergleichszeichen — waere die Kopie sonst still veraltet.
  for (final eintrag in inhalt.entries) {
    final datei = File('${ziel.path}/${eintrag.key}');
    if (!datei.existsSync()) return false;
    final vorhanden = datei.readAsBytesSync();
    if (vorhanden.length != eintrag.value.length) return false;
    for (var i = 0; i < vorhanden.length; i++) {
      if (vorhanden[i] != eintrag.value[i]) return false;
    }
  }
  return true;
}
