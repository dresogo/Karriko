import 'dart:io';

import 'package:questionnaire_core/questionnaire_core.dart';

/// Die Fragebogendefinition, aus der Gewichte, Schrumpfung und
/// Sichtbarkeitsgrenzen kommen. Dieselbe Datei wie für die Functions
/// (E-04); im Prototyp direkt aus dem Repo gelesen, im Betrieb aus dem
/// Bucket `questionnaires`.
final Questionnaire definition = Questionnaire.parseJsonString(
  _definitionsdatei().readAsStringSync(),
);

/// Sucht `appwrite/questionnaires/questionnaire_v1.json` vom Arbeitsverzeichnis
/// aufwärts. `jaspr serve` läuft in `website/`, der gebaute Server in
/// `website/build/jaspr/`.
File _definitionsdatei() {
  var ordner = Directory.current.absolute;
  while (true) {
    final datei = File(
      '${ordner.path}/appwrite/questionnaires/questionnaire_v1.json',
    );
    if (datei.existsSync()) return datei;
    final eltern = ordner.parent;
    if (eltern.path == ordner.path) {
      throw StateError('questionnaire_v1.json nicht gefunden');
    }
    ordner = eltern;
  }
}

/// Anzeigenamen der Dimensionen, wie in der App (`public_review_card.dart`).
String dimensionLabel(String dimension) => switch (dimension) {
  'fachlich' => 'Fachliche Qualität',
  'betreuung' => 'Betreuung',
  'umgang' => 'Umgang',
  'belastung' => 'Arbeitszeit und Belastung',
  'verguetung' => 'Vergütung und Leistungen',
  'perspektive' => 'Perspektive',
  'berufsschule' => 'Berufsschule',
  _ => dimension,
};

/// „3,8“: eine Nachkommastelle mit Komma (Entscheidung F-2 vom 22.10.2026).
String zahl(double wert) => wert.toStringAsFixed(1).replaceAll('.', ',');
