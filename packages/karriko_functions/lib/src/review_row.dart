import 'dart:convert';

import 'package:questionnaire_core/questionnaire_core.dart';

/// Status einer Bewertung in `reviews`.
class ReviewStatus {
  ReviewStatus._();

  /// Fertig eingereicht, wartet auf die Moderation.
  static const pendingModeration = 'pending_moderation';

  /// Auf Wunsch des Azubis zurückgestellt. Bis [publishAfterField] erreicht ist,
  /// bleibt sie bearbeitbar und geht nicht in die Moderation.
  static const scheduled = 'scheduled';

  /// Freigegeben. Erst jetzt steht sie in `public_reviews`.
  static const approved = 'approved';

  static const rejected = 'rejected';
}

const publishAfterField = 'publish_after';

/// Die sechs Subscores und die getrennte Berufsschule, als Spaltennamen.
///
/// Typisierte Spalten und nicht ein JSON-Klumpen, weil danach gefiltert und
/// aggregiert wird. Was nur gelesen und nie durchsucht wird — Rohantworten,
/// Zeiten — steht als JSON daneben.
const subscoreColumns = <String, String>{
  'fachlich': 'sub_fachlich',
  'betreuung': 'sub_betreuung',
  'umgang': 'sub_umgang',
  'belastung': 'sub_belastung',
  'verguetung': 'sub_verguetung',
  'perspektive': 'sub_perspektive',
};

const separateColumns = <String, String>{
  'berufsschule': 'sub_berufsschule',
};

/// Baut die Zeile für `reviews`.
///
/// Reine Funktion über Definition, Antworten und Werte — kein Appwrite, kein
/// Netz. Damit lässt sich prüfen, was gespeichert würde, ohne etwas zu
/// speichern.
Map<String, Object?> buildReviewRow({
  required Questionnaire questionnaire,
  required Answers answers,
  required ReviewScores scores,
  required List<QualityFlag> flags,
  required String companyId,
  required String userId,
  required String status,
  Map<String, int> timings = const {},
  String? inviteSource,
  String? verificationFileId,
  String? deviceHash,
  DateTime? publishAfter,
  bool publishAfterTrainingEnd = false,
}) {
  final felder = publicFields(questionnaire, answers);
  final steuerung = _steuerwerte(questionnaire, answers);

  return {
    'company_id': companyId,
    'user_id': userId,
    'schema_version': questionnaire.version,
    'status': status,

    // Alles, wonach gefiltert oder aggregiert wird, bekommt eine eigene Spalte.
    'respondent_status': steuerung.status,
    'beruf_code': steuerung.berufCode,
    'beruf_name': felder['beruf_name'],
    'start_year': felder['start_year'],
    'end_year': felder['end_year'],
    'invited': inviteSource != null,
    'invite_source': inviteSource,
    'k5_recommend': felder['k5_recommend'],
    'k6_overall': felder['k6_overall'],
    'detail_overall': scores.detailOverall,
    for (final eintrag in subscoreColumns.entries)
      eintrag.value: scores.subscores[eintrag.key],
    for (final eintrag in separateColumns.entries)
      eintrag.value: scores.separate[eintrag.key],

    // Flags fuehren nie zur Loeschung, nur zur Moderation.
    'quality_flags': [for (final flag in flags) flag.code],
    'quality_notes': [for (final flag in flags) '${flag.code}: ${flag.reason}'],

    if (publishAfter != null)
      publishAfterField: publishAfter.toUtc().toIso8601String(),
    'publish_after_training_end': publishAfterTrainingEnd,

    // Freitexte einzeln, damit die Moderation sie einzeln beanstanden kann.
    'freitext_gut': felder[freitextGutField],
    'freitext_schlecht': felder[freitextSchlechtField],

    // Rohdaten daneben. Ohne sie liesse sich eine Bewertung nach einer
    // Parameteraenderung nicht neu rechnen — und genau das macht recompute_all.
    'answers_json': jsonEncode(answers.toJson()),
    'timings_json': jsonEncode(timings),

    if (verificationFileId != null) 'verification_file_id': verificationFileId,
    'verified': false,
    if (deviceHash != null) 'device_hash': deviceHash,
  };
}

/// Baut die Zeile für `public_reviews` aus einer freigegebenen Bewertung.
///
/// **Was hier fehlt, ist die eigentliche Aussage:** keine `user_id`, keine
/// Rohantworten, keine Zeiten, keine Qualitäts-Flags, kein Gerätehash, keine
/// Tagesform, nichts aus dem Konfliktmodul. Appwrite vergibt Rechte pro Zeile,
/// nicht pro Spalte — deshalb ist das eine eigene Tabelle und keine gefilterte
/// Sicht.
Map<String, Object?> buildPublicReviewRow({
  required String reviewId,
  required Map<String, Object?> reviewRow,
  required bool isAged,
  DateTime? publishedAt,
}) {
  return {
    'review_id': reviewId,
    'company_id': reviewRow['company_id'],
    'beruf_code': reviewRow['beruf_code'],
    'beruf_name': reviewRow['beruf_name'],
    'start_year': reviewRow['start_year'],
    'end_year': reviewRow['end_year'],
    'respondent_status': reviewRow['respondent_status'],
    'k5_recommend': reviewRow['k5_recommend'],
    'k6_overall': reviewRow['k6_overall'],
    for (final spalte in subscoreColumns.values) spalte: reviewRow[spalte],
    for (final spalte in separateColumns.values) spalte: reviewRow[spalte],
    'freitext_gut': reviewRow['freitext_gut'],
    'freitext_schlecht': reviewRow['freitext_schlecht'],
    'is_aged': isAged,
    'verified': reviewRow['verified'] ?? false,
    'published_at':
        (publishedAt ?? DateTime.now().toUtc()).toUtc().toIso8601String(),
  };
}

/// Die Steuerangaben, die als eigene Spalte gebraucht werden.
///
/// Sie stehen nicht unter `publicField`, weil sie nicht veröffentlicht werden —
/// aber es wird nach ihnen gefiltert. `respondent_status` etwa unterscheidet,
/// ob eine Bewertung von einem aktuellen Azubi oder einem Abbrecher kommt, und
/// das ist für die Auswertung wesentlich.
({String? status, String? berufCode}) _steuerwerte(
  Questionnaire questionnaire,
  Answers answers,
) {
  final statusId = questionnaire.flow.tenseQuestionId;
  final status = answers[statusId];

  // Der Berufscode kommt aus der Frage, die auf `beruf_name` zeigt: In der
  // Beispielliste ist der Code ein Slug, nach dem Import ein amtlicher
  // Schluessel. Solange der Client nur den Namen schickt, bleibt er leer.
  String? berufCode;
  for (final question in questionnaire.questions) {
    if (question.config['publicField'] != 'beruf_name') continue;
    final wert = answers['${question.id}_code'];
    if (wert is String && wert.isNotEmpty) berufCode = wert;
  }

  return (status: status is String ? status : null, berufCode: berufCode);
}
