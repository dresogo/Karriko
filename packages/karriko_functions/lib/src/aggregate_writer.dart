import 'dart:convert';

import 'package:questionnaire_core/questionnaire_core.dart';

import 'review_row.dart';

/// Baut aus einer `public_reviews`-Zeile die Eingabe für die Aggregation.
///
/// Reine Funktion, damit sich prüfen lässt, was aus einer Zeile wird, ohne eine
/// Zeile zu haben.
AggregateInput? aggregateInputFromRow(
  Map<String, Object?> row, {
  required List<String> priorities,
}) {
  final subscores = <String, double>{};
  subscoreColumns.forEach((dimension, spalte) {
    final wert = row[spalte];
    if (wert is num) subscores[dimension] = wert.toDouble();
  });

  final separate = <String, double>{};
  separateColumns.forEach((dimension, spalte) {
    final wert = row[spalte];
    if (wert is num) separate[dimension] = wert.toDouble();
  });

  final veroeffentlicht = row['published_at'];
  final zeitpunkt =
      veroeffentlicht is String ? DateTime.tryParse(veroeffentlicht) : null;
  if (zeitpunkt == null) return null;

  final empfehlung = row['k5_recommend'];

  return AggregateInput(
    subscores: subscores,
    separate: separate,
    priorities: priorities,
    recommend: empfehlung is num ? empfehlung.round() : null,
    publishedAt: zeitpunkt,
  );
}

/// Baut die Zeile für `company_scores`.
Map<String, Object?> buildCompanyScoresRow(
  CompanyAggregate aggregat, {
  required Questionnaire questionnaire,
  required Map<String, num> zahlenangaben,
}) {
  return {
    'overall': aggregat.scoreVisible ? aggregat.overall : null,
    for (final eintrag in subscoreColumns.entries)
      eintrag.value:
          aggregat.scoreVisible ? aggregat.subscores[eintrag.key] : null,
    for (final eintrag in separateColumns.entries)
      eintrag.value:
          aggregat.scoreVisible ? aggregat.separate[eintrag.key] : null,
    'recommend_mean': aggregat.scoreVisible ? aggregat.recommendMean : null,
    'weights_json': jsonEncode(aggregat.weights),
    'review_count': aggregat.reviewCount,
    'aged_count': aggregat.agedCount,
    'score_visible': aggregat.scoreVisible,
    'numbers_visible': aggregat.numbersVisible,
    'bands_json': jsonEncode(
      aggregat.numbersVisible
          ? _spannen(questionnaire, zahlenangaben)
          : const <String, String>{},
    ),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}

/// Zahlenangaben erscheinen nur in Spannen, und die Spannen stehen in der
/// Definition.
///
/// Der genaue Mittelwert wird nicht gespeichert. Aus „durchschnittlich 847 €"
/// und der Zahl der Bewertungen liessen sich einzelne Angaben zurückrechnen,
/// sobald eine dazukommt — und dann wäre die Aggregation keine.
Map<String, String> _spannen(
  Questionnaire questionnaire,
  Map<String, num> zahlenangaben,
) {
  final out = <String, String>{};
  zahlenangaben.forEach((schluessel, wert) {
    final band = questionnaire.visibility.bandFor(schluessel, wert);
    if (band != null) out[schluessel] = band.label.current;
  });
  return out;
}
