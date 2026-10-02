// Erzeugt die vollstaendige Berufsliste fuer S3 aus einer CSV.
//
// Woher die CSV kommt
// -------------------
// Die Bundesagentur fuer Arbeit veroeffentlicht die „Klassifikation der Berufe"
// (KldB 2010) und die Liste der anerkannten Ausbildungsberufe. Fuer S3 wird die
// Liste der **Ausbildungsberufe** gebraucht, nicht die vollstaendige KldB: Die
// KldB enthaelt jeden Beruf, auch solche, die man nicht erlernen kann.
//
// Bezugswege, Stand September 2026 — bitte vor dem Import gegenpruefen, die
// Adressen aendern sich:
//
//   * BERUFENET der Bundesagentur fuer Arbeit, Ausgabe „Ausbildungsberufe"
//   * Verzeichnis der anerkannten Ausbildungsberufe des BIBB, jaehrlich
//   * Die KldB 2010 selbst, als Schluesselverzeichnis
//
// Welches Format erwartet wird
// ----------------------------
// Eine CSV mit Kopfzeile, UTF-8, Trennzeichen Semikolon oder Komma (wird
// erkannt). Gebraucht werden zwei Spalten, die Reihenfolge ist egal:
//
//   code    amtlicher Schluessel des Berufs, etwa der KldB-Schluessel
//   name    Bezeichnung, wie sie dem Azubi angezeigt wird
//
// Optional:
//
//   bereich  Grobe Zuordnung fuer die Gruppierung im Suchfeld
//
// Die Spaltennamen lassen sich ueber --spalte-code, --spalte-name und
// --spalte-bereich umbiegen, falls die Quelle sie anders nennt.
//
// Aufruf
// ------
//
//   dart run tools/import_berufe.dart <datei.csv>
//   dart run tools/import_berufe.dart <datei.csv> --ziel karriko_flutter/assets/data/berufe.json
//   dart run tools/import_berufe.dart <datei.csv> --spalte-code Schluessel --spalte-name Bezeichnung
//
// Danach den Verweis in questionnaire_v1.json von `berufe_beispiel.json` auf
// die erzeugte Datei umstellen und `dart run tools/sync_questionnaire.dart`
// laufen lassen.

import 'dart:convert';
import 'dart:io';

const _standardZiel = 'karriko_flutter/assets/data/berufe.json';

void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.isEmpty) {
    stderr.writeln(
      'Aufruf: dart run tools/import_berufe.dart <datei.csv> [--ziel <pfad>]',
    );
    exit(64);
  }

  final quelle = File(positional.first);
  if (!quelle.existsSync()) {
    stderr.writeln('Nicht gefunden: ${quelle.path}');
    exit(1);
  }

  final ziel = File(_option(args, '--ziel') ?? _standardZiel);
  final spalteCode = _option(args, '--spalte-code') ?? 'code';
  final spalteName = _option(args, '--spalte-name') ?? 'name';
  final spalteBereich = _option(args, '--spalte-bereich') ?? 'bereich';

  final zeilen = const LineSplitter()
      .convert(quelle.readAsStringSync(encoding: utf8))
      .where((z) => z.trim().isNotEmpty)
      .toList();

  if (zeilen.length < 2) {
    stderr.writeln('Die CSV hat keine Datenzeilen.');
    exit(1);
  }

  final trenner = _trennerErkennen(zeilen.first);
  final kopf = _zeile(
    zeilen.first,
    trenner,
  ).map((s) => s.trim().toLowerCase()).toList();

  int spalte(String name) {
    final index = kopf.indexOf(name.toLowerCase());
    if (index < 0) {
      stderr.writeln(
        'Spalte "$name" fehlt. Gefunden: ${kopf.join(', ')}.\n'
        'Mit --spalte-code, --spalte-name und --spalte-bereich umbiegen.',
      );
      exit(1);
    }
    return index;
  }

  final iCode = spalte(spalteCode);
  final iName = spalte(spalteName);
  final iBereich = kopf.indexOf(spalteBereich.toLowerCase());

  final berufe = <Map<String, String>>[];
  final gesehen = <String>{};
  var uebersprungen = 0;

  for (var i = 1; i < zeilen.length; i++) {
    final felder = _zeile(zeilen[i], trenner);
    if (felder.length <= iCode || felder.length <= iName) {
      uebersprungen++;
      continue;
    }
    final code = felder[iCode].trim();
    final name = felder[iName].trim();
    if (code.isEmpty || name.isEmpty) {
      uebersprungen++;
      continue;
    }
    // Ein doppelter Schluessel waere ein stiller Datenfehler: Zwei Berufe
    // teilten sich eine Kennung, und Bewertungen landeten am falschen.
    if (!gesehen.add(code)) {
      stderr.writeln('Zeile ${i + 1}: Schluessel "$code" kommt mehrfach vor.');
      exit(1);
    }
    berufe.add({
      'code': code,
      'name': name,
      if (iBereich >= 0 &&
          felder.length > iBereich &&
          felder[iBereich].trim().isNotEmpty)
        'bereich': felder[iBereich].trim(),
    });
  }

  berufe.sort((a, b) => a['name']!.compareTo(b['name']!));

  final ausgabe = {
    'quelle': quelle.uri.pathSegments.last,
    'hinweis': 'Erzeugt mit tools/import_berufe.dart. Nicht von Hand aendern.',
    'stand': DateTime.now().toUtc().toIso8601String().substring(0, 10),
    'berufe': berufe,
  };

  ziel.parent.createSync(recursive: true);
  ziel.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(ausgabe)}\n',
  );

  print('${berufe.length} Berufe nach ${ziel.path} geschrieben.');
  if (uebersprungen > 0) {
    print('$uebersprungen unvollstaendige Zeile(n) uebersprungen.');
  }
  print(
    '\nNaechster Schritt: in questionnaire_v1.json bei s3_beruf den Wert\n'
    'config.asset auf "${ziel.path.replaceFirst('karriko_flutter/', '')}"\n'
    'setzen, "review": true entfernen und\n'
    '`dart run tools/sync_questionnaire.dart` laufen lassen.',
  );
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

/// Semikolon oder Komma. Deutsche Behoerdenexporte benutzen ueberwiegend das
/// Semikolon, weil im Komma die Berufsbezeichnungen stecken.
String _trennerErkennen(String kopfzeile) =>
    kopfzeile.split(';').length > kopfzeile.split(',').length ? ';' : ',';

/// Zerlegt eine CSV-Zeile und beachtet dabei Anfuehrungszeichen.
///
/// Ohne das zerfiele „Kaufmann/-frau fuer Gross- und Aussenhandelsmanagement,
/// Fachrichtung Grosshandel" an seinem eigenen Komma in zwei Felder.
List<String> _zeile(String zeile, String trenner) {
  final felder = <String>[];
  final puffer = StringBuffer();
  var inAnfuehrung = false;

  for (var i = 0; i < zeile.length; i++) {
    final zeichen = zeile[i];
    if (zeichen == '"') {
      // Zwei Anfuehrungszeichen hintereinander sind ein echtes Zeichen.
      if (inAnfuehrung && i + 1 < zeile.length && zeile[i + 1] == '"') {
        puffer.write('"');
        i++;
      } else {
        inAnfuehrung = !inAnfuehrung;
      }
    } else if (zeichen == trenner && !inAnfuehrung) {
      felder.add(puffer.toString());
      puffer.clear();
    } else {
      puffer.write(zeichen);
    }
  }
  felder.add(puffer.toString());
  return felder;
}
