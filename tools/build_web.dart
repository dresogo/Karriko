// Baut die Web-App so, wie sie ausgeliefert wird, und prueft das Ergebnis.
//
// Zwei Dinge sollen nicht davon abhaengen, dass sich jemand an ein Flag
// erinnert:
//
//   * `--no-web-resources-cdn` (Sicherheitsbericht S1). Ohne das Flag laedt
//     jeder Seitenaufruf CanvasKit von www.gstatic.com: Fremdcode ohne
//     Integritaetspruefung, und die IP jedes Besuchers geht an Google, bevor
//     irgendetwas sichtbar ist.
//   * `APP_ORIGIN`. Ohne ihn zeigen die Links in Bestaetigungs- und
//     Reset-Mails auf den localhost-Rueckfall.
//
// Aufruf aus dem Wurzelverzeichnis:
//
//   dart run tools/build_web.dart https://karriko.dresogo.de
//   dart run tools/build_web.dart https://karriko.de --base-href /app/
//   dart run tools/build_web.dart --pruefen    prueft nur den vorhandenen Build
//
// Alles nach der Adresse geht unveraendert an `flutter build web`, etwa
// weitere `--dart-define`s oder `--base-href`.
//
// Nach dem Bauen prueft das Skript den Ordner build/web: CanvasKit muss darin
// liegen und die Build-Konfiguration muss es lokal laden. Schlaegt das fehl,
// endet es mit Code 1 und der Ordner gehoert nicht auf den Server.

import 'dart:convert';
import 'dart:io';

const _app = 'karriko_flutter';
const _ausgabe = '$_app/build/web';

Future<void> main(List<String> args) async {
  if (args.length == 1 && args.first == '--pruefen') {
    _melden(_pruefen());
    return;
  }

  if (args.isEmpty || args.first.startsWith('-')) {
    stderr.writeln(
      'Aufruf: dart run tools/build_web.dart <APP_ORIGIN> [weitere Flags]\n'
      'Beispiel: dart run tools/build_web.dart https://karriko.dresogo.de',
    );
    exit(64);
  }

  final origin = args.first;
  final uri = Uri.tryParse(origin);
  if (uri == null ||
      !uri.hasScheme ||
      uri.host.isEmpty ||
      uri.path.isNotEmpty && uri.path != '/') {
    stderr.writeln(
      'APP_ORIGIN muss eine reine Adresse ohne Pfad sein, etwa '
      'https://karriko.dresogo.de — bekommen: $origin',
    );
    exit(64);
  }
  if (uri.scheme != 'https' && uri.host != 'localhost') {
    stderr.writeln('APP_ORIGIN braucht https (ausser fuer localhost).');
    exit(64);
  }

  if (!Directory(_app).existsSync()) {
    stderr.writeln(
      'Nicht gefunden: $_app\n'
      'Das Skript laeuft im Wurzelverzeichnis des Repositories.',
    );
    exit(1);
  }

  final flutterArgs = [
    'build',
    'web',
    '--release',
    '--no-web-resources-cdn',
    '--dart-define=APP_ORIGIN=${origin.replaceAll(RegExp(r'/$'), '')}',
    ...args.skip(1),
  ];
  stdout.writeln('flutter ${flutterArgs.join(' ')}\n');

  final prozess = await Process.start(
    'flutter',
    flutterArgs,
    workingDirectory: _app,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await prozess.exitCode;
  if (code != 0) exit(code);

  _melden(_pruefen());
}

void _melden(List<String> fehler) {
  if (fehler.isNotEmpty) {
    stderr.writeln('\nDer Build ist so nicht auslieferbar:');
    for (final f in fehler) {
      stderr.writeln('  - $f');
    }
    exit(1);
  }
  stdout.writeln(
    '\nGeprueft: CanvasKit liegt in $_ausgabe und wird lokal geladen.\n'
    'Den Inhalt von $_ausgabe hochladen.',
  );
}

List<String> _pruefen() {
  final fehler = <String>[];

  if (!File('$_ausgabe/canvaskit/canvaskit.wasm').existsSync()) {
    fehler.add('$_ausgabe/canvaskit/canvaskit.wasm fehlt.');
  }

  fehler.addAll(_pruefeSecurityTxt());

  final bootstrap = File('$_ausgabe/flutter_bootstrap.js');
  if (!bootstrap.existsSync()) {
    fehler.add('$_ausgabe/flutter_bootstrap.js fehlt.');
    return fehler;
  }

  // Flutter schreibt die Build-Konfiguration als JSON-Zuweisung in die Datei.
  // Die gstatic-Adresse steht als Rueckfall immer im Code; entscheidend ist,
  // dass dieser Schalter gesetzt ist.
  final treffer = RegExp(
    r'_flutter\.buildConfig = (\{.*?\});',
  ).firstMatch(bootstrap.readAsStringSync());
  if (treffer == null) {
    fehler.add('Build-Konfiguration in flutter_bootstrap.js nicht gefunden.');
  } else {
    final config = jsonDecode(treffer.group(1)!) as Map<String, dynamic>;
    if (config['useLocalCanvasKit'] != true) {
      fehler.add(
        'useLocalCanvasKit ist nicht gesetzt: CanvasKit kaeme von '
        'www.gstatic.com.',
      );
    }
  }

  return fehler;
}

// RFC 9116: Pflicht sind mindestens ein `Contact` und genau ein `Expires`.
// Eine abgelaufene Datei gilt als veraltet und gehoert nicht auf den Server;
// 30 Tage vorher kommt eine Warnung, damit das Datum rechtzeitig wandert.
List<String> _pruefeSecurityTxt() {
  const pfad = '$_ausgabe/.well-known/security.txt';
  final datei = File(pfad);
  if (!datei.existsSync()) return ['$pfad fehlt.'];

  final felder = datei
      .readAsLinesSync()
      .where((z) => z.isNotEmpty && !z.startsWith('#'))
      .map((z) => z.split(':'))
      .where((t) => t.length > 1)
      .map((t) => MapEntry(t.first.toLowerCase(), t.skip(1).join(':').trim()));

  final fehler = <String>[];
  if (!felder.any((f) => f.key == 'contact')) {
    fehler.add('security.txt: kein Contact-Feld.');
  }
  final expires = felder.where((f) => f.key == 'expires').toList();
  if (expires.length != 1) {
    fehler.add('security.txt: Expires muss genau einmal vorkommen.');
    return fehler;
  }
  final ablauf = DateTime.tryParse(expires.single.value);
  if (ablauf == null) {
    fehler.add('security.txt: Expires ist kein Datum nach RFC 3339.');
  } else if (ablauf.isBefore(DateTime.now())) {
    fehler.add('security.txt ist seit $ablauf abgelaufen.');
  } else if (ablauf.difference(DateTime.now()).inDays < 30) {
    stderr.writeln('Hinweis: security.txt laeuft am $ablauf ab.');
  }
  return fehler;
}
