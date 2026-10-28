// Erzeugt die Berufsliste fuer S3 aus dem DKZ-Verzeichnis der Bundesagentur
// fuer Arbeit (T-2.30).
//
// Quelle
// ------
// Zwei Dateien aus dem Dokumentationskennziffer-Verzeichnis (DKZ) der BA:
//
//   * `DKZ_Ausbildungen_gueltig.xml`: alle gueltigen Ausbildungen, je Eintrag
//     `id`, `codenr` (z. B. „B 26112-90000"), `bezeichnung` und
//     `berufskundlicheGruppe`. Maschinenlesbar, deshalb die Hauptquelle.
//   * optional eine Textliste mit `ID | BKZ | Gruppe | Berufsbezeichnung`.
//     Daraus kommen nur die kurzen Anzeigenamen („Mechatroniker/in" statt
//     „Mechatroniker/Mechatronikerin"), zugeordnet ueber die ID.
//
// Herkunft, Stand und Nutzungsbedingungen stehen in keiner der Dateien. Vor
// einer Veroeffentlichung klaeren (T-2.30).
//
// Welche Gruppen
// --------------
// Standard (entschieden am 28.10.2026): die dualen Ausbildungen und was einem
// Ausbildungsbetrieb entspricht.
//
//   1110  Dual, ohne Fachrichtung
//   1120  Dual mit Fachrichtung
//   1130  Dual mit Schwerpunkt
//   1140  Dual mit Doppelqualifikation
//   1310  Fachpraktiker nach § 66 BBiG / § 42r HwO
//   1210  Berufsfachschule nach Bundesrecht (Pflege, Notfallsanitaeter)
//
// Nicht dabei: rein schulische Landesberufe (1220, darunter Erzieher/in),
// Studium (31xx), Fort- und Weiterbildung (32xx, 33xx), Beamte (51xx) und
// Bundeswehr (61xx). Mit --gruppen laesst sich das aendern.
//
// Aufruf
// ------
//
//   dart run tools/berufe_aus_ba.dart <DKZ.xml> [--namen <liste.txt>]
//       [--gruppen 1110,1120,...] [--ziel karriko_flutter/assets/data/berufe.json]
//
// Das Werkzeug kommt ohne fremde Pakete aus (E-07): Jeder Eintrag der XML
// steht als einzelnes leeres Element in einer Zeile, ein regulaerer Ausdruck
// reicht.

import 'dart:convert';
import 'dart:io';

const _standardZiel = 'karriko_flutter/assets/data/berufe.json';
const _standardGruppen = ['1110', '1120', '1130', '1140', '1310', '1210'];

/// Berufsbereiche der KldB 2010, erste Stelle des Schluessels. Fuer die
/// Gruppierung im Suchfeld.
const _bereiche = {
  '0': 'Militär',
  '1': 'Land-, Forst- und Tierwirtschaft, Gartenbau',
  '2': 'Rohstoffgewinnung, Produktion und Fertigung',
  '3': 'Bau, Architektur, Vermessung und Gebäudetechnik',
  '4': 'Naturwissenschaft, Geografie und Informatik',
  '5': 'Verkehr, Logistik, Schutz und Sicherheit',
  '6': 'Kaufmännische Dienstleistungen, Handel, Vertrieb, Hotel und Tourismus',
  '7': 'Unternehmensorganisation, Buchhaltung, Recht und Verwaltung',
  '8': 'Gesundheit, Soziales, Lehre und Erziehung',
  '9': 'Sprache, Wirtschaft, Medien, Kunst, Kultur und Gestaltung',
};

/// Der Auffangeintrag bleibt immer der letzte: Wessen Beruf fehlt, der soll
/// an S3 nicht haengen bleiben (`SearchSelect`).
const _auffang = {
  'code': 'sonstiger',
  'name': 'Mein Beruf steht nicht in der Liste',
  'bereich': 'Sonstiges',
};

void main(List<String> args) {
  final positional = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      i++; // Wert der Option ueberspringen
    } else {
      positional.add(args[i]);
    }
  }
  if (positional.isEmpty) {
    stderr.writeln(
      'Aufruf: dart run tools/berufe_aus_ba.dart <DKZ.xml> '
      '[--namen <liste.txt>] [--gruppen 1110,…] [--ziel <pfad>]',
    );
    exit(64);
  }

  final xml = File(positional.first);
  if (!xml.existsSync()) {
    stderr.writeln('Nicht gefunden: ${xml.path}');
    exit(1);
  }
  final gruppen = (_option(args, '--gruppen')?.split(',') ?? _standardGruppen)
      .toSet();
  final namenDatei = _option(args, '--namen');
  final kurz = namenDatei == null
      ? const <String, String>{}
      : _kurznamen(File(namenDatei));
  final ziel = File(_option(args, '--ziel') ?? _standardZiel);

  final berufe = berufeAusXml(
    xml.readAsStringSync(encoding: utf8),
    gruppen: gruppen,
    kurznamen: kurz,
  );

  final ausgabe = {
    'quelle':
        'Bundesagentur für Arbeit, DKZ-Verzeichnis '
        '(${xml.uri.pathSegments.last}); Gruppen ${(gruppen.toList()..sort()).join(', ')}',
    'hinweis':
        'Erzeugt mit tools/berufe_aus_ba.dart. Nicht von Hand ändern. '
        'Herkunft, Stand und Nutzungsbedingungen der Quelle sind noch zu '
        'klären (T-2.30).',
    'stand': DateTime.now().toUtc().toIso8601String().substring(0, 10),
    'berufe': [...berufe, _auffang],
  };

  ziel.parent.createSync(recursive: true);
  ziel.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(ausgabe)}\n',
  );
  print(
    '${berufe.length} Berufe (+ Auffangeintrag) nach ${ziel.path} '
    'geschrieben.',
  );
}

/// Liest die Eintraege der XML, filtert nach [gruppen] und sortiert nach
/// Name. Doppelte Schluessel brechen ab: Zwei Berufe mit einer Kennung waeren
/// ein stiller Datenfehler.
List<Map<String, Object>> berufeAusXml(
  String xml, {
  required Set<String> gruppen,
  Map<String, String> kurznamen = const {},
}) {
  final eintrag = RegExp(r'<beruf\s([^>]*?)/>');
  final attribut = RegExp(r'(\w+)="([^"]*)"');
  final berufe = <Map<String, Object>>[];
  final gesehen = <String>{};

  for (final m in eintrag.allMatches(xml)) {
    final a = {
      for (final t in attribut.allMatches(m.group(1)!))
        t.group(1)!: _entities(t.group(2)!),
    };
    if (!gruppen.contains(a['berufskundlicheGruppe'])) continue;
    if (a['zustand'] != null && a['zustand'] != 'E') continue;

    final code = (a['codenr'] ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final langname = a['bezeichnung'] ?? '';
    if (code.length != 10 || langname.isEmpty) {
      throw FormatException('Eintrag ohne gueltige Kennziffer: ${m.group(0)}');
    }
    if (!gesehen.add(code)) {
      throw FormatException('Kennziffer $code kommt mehrfach vor.');
    }
    final kurzname = kurznamen[a['id']];
    berufe.add({
      'code': code,
      'name': kurzname ?? langname,
      'bereich': _bereiche[code[0]] ?? 'Sonstiges',
    });
  }

  berufe.sort((x, y) => (x['name'] as String).compareTo(y['name'] as String));
  return berufe;
}

/// `ID | BKZ | Gruppe | Berufsbezeichnung` → ID auf Bezeichnung.
Map<String, String> _kurznamen(File datei) {
  final out = <String, String>{};
  for (final zeile
      in const LineSplitter()
          .convert(datei.readAsStringSync(encoding: utf8))
          .skip(1)) {
    final teile = zeile.split('|').map((s) => s.trim()).toList();
    if (teile.length == 4 && teile[0].isNotEmpty && teile[3].isNotEmpty) {
      out[teile[0]] = teile[3];
    }
  }
  return out;
}

String _entities(String s) => s
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}
