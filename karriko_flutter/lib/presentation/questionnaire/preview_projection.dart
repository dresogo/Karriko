import 'package:questionnaire_core/questionnaire_core.dart';

import '../../data/models/public_review.dart';

/// Baut aus dem aktuellen Antwortstand das, was später öffentlich dastehen
/// wird.
///
/// Die Zuordnung steht **in der Definition**, nicht hier: Jede Frage mit
/// `"public": true` trägt in `config.publicField` das Zielfeld. Damit lässt
/// sich eine Angabe veröffentlichen oder zurückziehen, ohne den Dart-Code
/// anzufassen — und eine Frage, die versehentlich `public` trägt, fällt beim
/// Laden auf, weil ihr das Zielfeld fehlt.
///
/// Was hier herauskommt, ist eine Behauptung des Clients. Verbindlich ist, was
/// die Function nach derselben Regel in `public_reviews` schreibt. Beide lesen
/// dieselbe Definition; dass sie dasselbe Ergebnis haben, ist deshalb keine
/// Absprache.
class PreviewProjection {
  final Questionnaire questionnaire;
  final Answers answers;
  final String companyId;
  final String? companyName;

  /// Blöcke, die der Azubi in der Vorschau zurückgenommen hat. Ihre Angaben
  /// werden nicht veröffentlicht.
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
          if (question.public && _hatAntwort(question))
            (id: question.id, label: question.text.forTense(_tense)),
      ];

  bool istZurueckgenommen(String id) => zurueckgenommen.contains(id);

  Tense get _tense => QuestionnaireFlow(questionnaire).tense(answers);

  bool _hatAntwort(Question question) =>
      AnsweredCondition.isAnswered(answers[question.id]);

  /// Was nicht sichtbar wird. Steht als Liste in der Definition.
  List<String> get nichtSichtbar => [
        for (final text in questionnaire.textList('preview.nicht_sichtbar'))
          text.forTense(_tense),
      ];

  PublicReview build() {
    final scores = ReviewScores.compute(questionnaire, answers);

    int? startYear;
    int? endYear;
    String? berufName;
    int? recommend;
    int? overall;
    String? freitextGut;
    String? freitextSchlecht;

    for (final question in questionnaire.questions) {
      if (!question.public) continue;
      if (zurueckgenommen.contains(question.id)) continue;

      final feld = question.config['publicField'];
      final wert = answers[question.id];
      if (feld is! String || !AnsweredCondition.isAnswered(wert)) continue;

      switch (feld) {
        case 'start_year':
          startYear = _int(wert);
        case 'end_year':
          endYear = _int(wert);
        case 'beruf_name':
          berufName = wert as String?;
        case 'k5_recommend':
          recommend = _int(wert);
        case 'k6_overall':
          // Der Korrekturregler aus A2 steht in der Definition hinter K6 und
          // überschreibt ihn deshalb hier — genau das ist sein Zweck.
          overall = _int(wert) ?? overall;
        case 'freitext':
          final felder = _felder(question);
          if (wert is Map) {
            freitextGut = wert[felder.elementAtOrNull(0)] as String?;
            freitextSchlecht = wert[felder.elementAtOrNull(1)] as String?;
          }
      }
    }

    return PublicReview(
      id: 'vorschau',
      reviewId: 'vorschau',
      companyId: companyId,
      companyName: companyName,
      berufName: berufName,
      startYear: startYear,
      endYear: endYear,
      recommend: recommend,
      overall: overall,
      subscores: scores.subscores,
      berufsschule: scores.separate['berufsschule'],
      freitextGut: freitextGut,
      freitextSchlecht: freitextSchlecht,
      publishedAt: DateTime.now(),
    );
  }

  /// Die Feld-Kennungen eines Textfeldpaars, in der Reihenfolge der Definition.
  /// Das erste ist das gute, das zweite das schlechte — so steht es in A1.
  List<String> _felder(Question question) {
    final roh = question.config['fields'];
    if (roh is! List) return const [];
    return [
      for (final eintrag in roh)
        if (eintrag is Map && eintrag['id'] is String) eintrag['id']! as String,
    ];
  }

  int? _int(Object? wert) => wert is num ? wert.round() : null;
}
