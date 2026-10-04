import 'package:questionnaire_core/questionnaire_core.dart';

import '../../data/models/public_review.dart';

/// Baut aus dem aktuellen Antwortstand das, was später öffentlich dastehen
/// wird.
///
/// Welche Angabe wohin geht, rechnet [publicFields] aus `questionnaire_core`
/// aus — dieselbe Funktion, mit der `submit_review` später `public_reviews`
/// füllt. Hier wird das Ergebnis nur in ein [PublicReview] gegossen, damit
/// dasselbe Widget es anzeigen kann wie die öffentliche Einzelansicht.
///
/// Was hier herauskommt, ist eine Behauptung des Clients. Verbindlich ist, was
/// die Function schreibt. Dass beide dasselbe sagen, liegt nicht an einer
/// Absprache, sondern an derselben Funktion.
class PreviewProjection {
  final Questionnaire questionnaire;
  final Answers answers;
  final String companyId;
  final String? companyName;

  /// Blöcke, die der Azubi in der Vorschau zurückgenommen hat.
  final Set<String> zurueckgenommen;

  const PreviewProjection({
    required this.questionnaire,
    required this.answers,
    required this.companyId,
    this.companyName,
    this.zurueckgenommen = const {},
  });

  /// Welche Blöcke sich einzeln zurücknehmen lassen.
  ///
  /// Das sind genau die öffentlichen Angaben — jede für sich. „Jeder Block ist
  /// einzeln zurücknehmbar" heißt: nicht alles oder nichts.
  List<({String id, String label})> get bloecke => [
        for (final question in questionnaire.questions)
          if (question.public &&
              AnsweredCondition.isAnswered(answers[question.id]))
            (id: question.id, label: question.text.forTense(_tense)),
      ];

  bool istZurueckgenommen(String id) => zurueckgenommen.contains(id);

  Tense get _tense => QuestionnaireFlow(questionnaire).tense(answers);

  /// Was nicht sichtbar wird. Steht als Liste in der Definition.
  List<String> get nichtSichtbar => [
        for (final text in questionnaire.textList('preview.nicht_sichtbar'))
          text.forTense(_tense),
      ];

  PublicReview build() {
    final scores = ReviewScores.compute(questionnaire, answers);
    final felder = publicFields(
      questionnaire,
      answers,
      withdrawn: zurueckgenommen,
    );

    return PublicReview(
      id: 'vorschau',
      reviewId: 'vorschau',
      companyId: companyId,
      companyName: companyName,
      berufName: felder['beruf_name'] as String?,
      startYear: _int(felder['start_year']),
      endYear: _int(felder['end_year']),
      recommend: _int(felder['k5_recommend']),
      overall: _int(felder['k6_overall']),
      subscores: scores.subscores,
      berufsschule: scores.separate['berufsschule'],
      freitextGut: felder[freitextGutField] as String?,
      freitextSchlecht: felder[freitextSchlechtField] as String?,
      publishedAt: DateTime.now(),
    );
  }

  int? _int(Object? wert) => wert is num ? wert.round() : null;
}
