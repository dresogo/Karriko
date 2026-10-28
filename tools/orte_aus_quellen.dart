// Erzeugt eine Ortsliste fuer Betriebsprofil und Suche aus drei offenen
// Quellen: Gemeinden mit Bundesland und Kreis, Postleitzahlen, Koordinaten
// und, wo es sie gibt, Stadtbezirke je PLZ.
//
// Quellen
// -------
//   1. Destatis, Codeliste „Regionalschluessel" (XOeV): alle Gemeinden mit dem
//      12-stelligen Amtlichen Regionalschluessel (ARS). Stammliste. Die
//      Excel-Datei vorher als CSV speichern (Semikolon, UTF-8), Spalten
//      SCHLUESSEL;Bezeichnung;Hinweis. Nutzungsbedingungen noch zu klaeren.
//   2. OpenPLZ, `streets.updated.csv` aus github.com/openpotato/openplzapi.data:
//      Strassen aus OpenStreetMap mit PLZ, 8-stelligem Gemeindeschluessel,
//      Stadtbezirk und Stadtteil. Lizenz ODbL 1.0: Namensnennung
//      („© OpenStreetMap-Mitwirkende") und abgeleitete Datenbanken unter
//      derselben Lizenz.
//   3. GeoNames, `DE.txt` aus download.geonames.org/export/zip/: Koordinaten
//      je PLZ und Kreisnamen. Lizenz CC BY 4.0, Namensnennung mit Link auf
//      www.geonames.org.
//
// Weil die Ausgabe eine aus OpenStreetMap abgeleitete Datenbank ist, gehoert
// sie nicht ungeprueft ins oeffentliche Repository. Standardziel ist deshalb
// `tools/ausgabe/` (gitignoriert).
//
// Aufruf
// ------
//   dart run tools/orte_aus_quellen.dart \
//       --destatis regionalschluessel.csv --openplz streets.updated.csv \
//       --geonames DE.txt [--ziel tools/ausgabe/orte.json]
//
// Ausgabe je Gemeinde: Gemeindeschluessel (AGS), ARS, Name und Zusatz
// („Landeshauptstadt"), Bundesland, Kreisschluessel und Kreisname,
// Mittelpunkt (Durchschnitt ihrer PLZ) und die PLZ mit Koordinaten,
// Stadtbezirken und Stadtteilen samt Anteil der Strassen. Liegt eine PLZ in
// mehreren Bezirken, stehen alle da, der groesste zuerst.
//
// Ohne fremde Pakete (E-07).

import 'dart:convert';
import 'dart:io';

const _standardZiel = 'tools/ausgabe/orte.json';

/// Bundeslaender nach den ersten beiden Stellen des Schluessels.
const _laender = {
  '01': 'Schleswig-Holstein',
  '02': 'Hamburg',
  '03': 'Niedersachsen',
  '04': 'Bremen',
  '05': 'Nordrhein-Westfalen',
  '06': 'Hessen',
  '07': 'Rheinland-Pfalz',
  '08': 'Baden-Württemberg',
  '09': 'Bayern',
  '10': 'Saarland',
  '11': 'Berlin',
  '12': 'Brandenburg',
  '13': 'Mecklenburg-Vorpommern',
  '14': 'Sachsen',
  '15': 'Sachsen-Anhalt',
  '16': 'Thüringen',
};

void main(List<String> args) {
  final destatis = _datei(args, '--destatis');
  final openplz = _datei(args, '--openplz');
  final geonames = _datei(args, '--geonames');
  final ziel = File(_option(args, '--ziel') ?? _standardZiel);

  final gemeinden = gemeindenAusDestatis(destatis.readAsStringSync());
  final strassen = plzAusOpenPlz(openplz.openRead());
  final geo = koordinatenAusGeoNames(geonames.readAsStringSync());

  strassen.then((plzJeGemeinde) {
    final orte = zusammenfuehren(gemeinden, plzJeGemeinde, geo);
    final ausgabe = {
      'quellen': [
        'Destatis, Codeliste Regionalschlüssel (${destatis.uri.pathSegments.last})',
        '© OpenStreetMap-Mitwirkende, über OpenPLZ (ODbL 1.0)',
        'GeoNames, www.geonames.org (CC BY 4.0)',
      ],
      'hinweis':
          'Erzeugt mit tools/orte_aus_quellen.dart. Abgeleitete '
          'Datenbank aus OpenStreetMap-Daten (ODbL 1.0).',
      'stand': DateTime.now().toUtc().toIso8601String().substring(0, 10),
      'orte': orte,
    };
    ziel.parent.createSync(recursive: true);
    ziel.writeAsStringSync(jsonEncode(ausgabe));
    final ohnePlz = orte.where((o) => (o['plz'] as List).isEmpty).length;
    final mitBezirk = orte
        .where(
          (o) => (o['plz'] as List).any(
            (p) => ((p as Map)['bezirke'] as List).isNotEmpty,
          ),
        )
        .length;
    print(
      '${orte.length} Gemeinden nach ${ziel.path} geschrieben '
      '(${(ziel.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB).',
    );
    print('$ohnePlz ohne PLZ in OpenStreetMap, $mitBezirk mit Stadtbezirken.');
  });
}

/// Gemeinde aus der Destatis-Liste.
typedef Gemeinde = ({String ars, String ags, String name, String? zusatz});

/// Liest die Destatis-CSV. Stadt- und Ortsteile der Stadtstaaten (Hinweis
/// gesetzt) und gemeindefreie Gebiete fallen weg: Dort sitzt kein Betrieb,
/// und die Stadtstaaten stehen als Gemeinde selbst in der Liste.
List<Gemeinde> gemeindenAusDestatis(String csv) {
  final out = <Gemeinde>[];
  for (final zeile in const LineSplitter().convert(csv).skip(1)) {
    final teile = zeile.split(';');
    if (teile.length < 2) continue;
    final ars = teile[0].trim();
    final bezeichnung = teile[1].trim();
    final hinweis = teile.length > 2 ? teile[2].trim() : '';
    if (!RegExp(r'^\d{12}$').hasMatch(ars) || hinweis.isNotEmpty) continue;
    if (bezeichnung.contains('gemfr. Gebiet')) continue;
    final komma = bezeichnung.indexOf(', ');
    out.add((
      ars: ars,
      ags: ars.substring(0, 5) + ars.substring(9, 12),
      name: komma < 0 ? bezeichnung : bezeichnung.substring(0, komma),
      zusatz: komma < 0 ? null : bezeichnung.substring(komma + 2),
    ));
  }
  return out;
}

/// Zaehlt je Gemeindeschluessel und PLZ die Strassen je Stadtbezirk und
/// Stadtteil. Stadtteile, die nur Nummern sind (Muenchen: „5.3"), fallen weg.
Future<Map<String, Map<String, _Plz>>> plzAusOpenPlz(
  Stream<List<int>> eingabe,
) async {
  final out = <String, Map<String, _Plz>>{};
  var erste = true;
  await for (final zeile
      in eingabe.transform(utf8.decoder).transform(const LineSplitter())) {
    if (erste) {
      erste = false;
      continue;
    }
    final f = _csvZeile(zeile);
    if (f.length < 6) continue;
    final plz = f[1].trim();
    final ags = f[3].trim();
    if (!RegExp(r'^\d{5}$').hasMatch(plz) ||
        !RegExp(r'^\d{8}$').hasMatch(ags)) {
      continue;
    }
    final eintrag = out.putIfAbsent(ags, () => {}).putIfAbsent(plz, _Plz.new);
    eintrag.strassen++;
    final bezirk = f[4].trim();
    final teil = f[5].trim();
    if (bezirk.isNotEmpty)
      eintrag.bezirke.update(bezirk, (n) => n + 1, ifAbsent: () => 1);
    if (teil.isNotEmpty && !RegExp(r'^[\d.\s]+$').hasMatch(teil)) {
      eintrag.teile.update(teil, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  return out;
}

class _Plz {
  var strassen = 0;
  final bezirke = <String, int>{};
  final teile = <String, int>{};
}

/// Koordinaten je PLZ und Kreisnamen je Kreisschluessel aus GeoNames.
/// Grosskunden- und Postfach-PLZ (leeres Genauigkeitsfeld, Firmennamen als
/// Ort) fallen weg.
({Map<String, (double, double)> plz, Map<String, String> kreise})
koordinatenAusGeoNames(String tsv) {
  final plz = <String, (double, double)>{};
  final kreise = <String, String>{};
  for (final zeile in const LineSplitter().convert(tsv)) {
    final f = zeile.split('\t');
    if (f.length < 12 || f[11].isEmpty) continue;
    final lat = double.tryParse(f[9]);
    final lon = double.tryParse(f[10]);
    if (lat == null || lon == null) continue;
    plz.putIfAbsent(f[1], () => (lat, lon));
    if (f[8].length == 5 && f[7].isNotEmpty)
      kreise.putIfAbsent(f[8], () => f[7]);
  }
  return (plz: plz, kreise: kreise);
}

List<Map<String, Object?>> zusammenfuehren(
  List<Gemeinde> gemeinden,
  Map<String, Map<String, _Plz>> plzJeGemeinde,
  ({Map<String, (double, double)> plz, Map<String, String> kreise}) geo,
) {
  List<Map<String, Object>> anteile(Map<String, int> zaehler, int gesamt) {
    final liste = zaehler.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in liste)
        {
          'name': e.key,
          'anteil': double.parse((e.value / gesamt).toStringAsFixed(2)),
        },
    ];
  }

  final orte = <Map<String, Object?>>[];
  for (final g in gemeinden) {
    final plzListe = <Map<String, Object?>>[];
    var latSumme = 0.0, lonSumme = 0.0, mitKoordinate = 0;
    final eintraege = (plzJeGemeinde[g.ags] ?? const {}).entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in eintraege) {
      final koordinate = geo.plz[e.key];
      if (koordinate != null) {
        latSumme += koordinate.$1;
        lonSumme += koordinate.$2;
        mitKoordinate++;
      }
      plzListe.add({
        'plz': e.key,
        if (koordinate != null) 'lat': koordinate.$1,
        if (koordinate != null) 'lon': koordinate.$2,
        'bezirke': anteile(e.value.bezirke, e.value.strassen),
        if (e.value.teile.isNotEmpty)
          'ortsteile': anteile(e.value.teile, e.value.strassen),
      });
    }
    final kreis = g.ars.substring(0, 5);
    orte.add({
      'ags': g.ags,
      'ars': g.ars,
      'name': g.name,
      if (g.zusatz != null) 'zusatz': g.zusatz,
      'land': _laender[g.ars.substring(0, 2)],
      'kreis': kreis,
      if (geo.kreise[kreis] != null) 'kreisname': geo.kreise[kreis],
      if (mitKoordinate > 0)
        'lat': double.parse((latSumme / mitKoordinate).toStringAsFixed(4)),
      if (mitKoordinate > 0)
        'lon': double.parse((lonSumme / mitKoordinate).toStringAsFixed(4)),
      'plz': plzListe,
    });
  }
  return orte;
}

/// Zerlegt eine CSV-Zeile mit Kommas und Anfuehrungszeichen.
List<String> _csvZeile(String zeile) {
  final felder = <String>[];
  final puffer = StringBuffer();
  var inAnfuehrung = false;
  for (var i = 0; i < zeile.length; i++) {
    final z = zeile[i];
    if (z == '"') {
      if (inAnfuehrung && i + 1 < zeile.length && zeile[i + 1] == '"') {
        puffer.write('"');
        i++;
      } else {
        inAnfuehrung = !inAnfuehrung;
      }
    } else if (z == ',' && !inAnfuehrung) {
      felder.add(puffer.toString());
      puffer.clear();
    } else {
      puffer.write(z);
    }
  }
  felder.add(puffer.toString());
  return felder;
}

File _datei(List<String> args, String name) {
  final pfad = _option(args, name);
  if (pfad == null || !File(pfad).existsSync()) {
    stderr.writeln(
      '$name <datei> fehlt oder existiert nicht. '
      'Aufruf siehe Kopf von tools/orte_aus_quellen.dart.',
    );
    exit(64);
  }
  return File(pfad);
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}
