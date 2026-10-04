import '../flow/answers.dart';
import '../flow/flow.dart';
import '../model/questionnaire.dart';
import '../scoring/normalize.dart';
import '../scoring/review_scores.dart';

/// Eine Auffälligkeit an einer Einreichung.
///
/// Ein Flag ist **nie** ein Löschgrund. Es schickt die Bewertung in die
/// manuelle Moderation, mehr nicht. Automatisches Löschen trifft erfahrungs-
/// gemäß vor allem die ausführlichen, ehrlichen Bewertungen — also genau die,
/// für die Azubis die Plattform benutzen.
class QualityFlag {
  /// Maschinenlesbar. Wird in `reviews.quality_flags` gespeichert.
  static const tooFast = 'too_fast';
  static const straightlining = 'straightlining';
  static const inconsistentPair = 'inconsistent_pair';
  static const overallMismatch = 'overall_detail_mismatch';
  static const impossibleCombination = 'impossible_combination';
  static const textNeedsReview = 'text_needs_review';

  final String code;

  /// Für den Moderator, nicht für den Azubi. Der Azubi bekommt ein Flag nie zu
  /// sehen — deshalb ist das hier kein Fragetext und darf im Code stehen.
  final String reason;

  /// Woran es hängt.
  final List<String> questionIds;

  const QualityFlag({
    required this.code,
    required this.reason,
    this.questionIds = const [],
  });

  @override
  String toString() => '$code (${questionIds.join(', ')}): $reason';

  Map<String, Object?> toJson() => {
        'code': code,
        'reason': reason,
        'questions': questionIds,
      };
}

/// Die Qualitätsfilter aus Abschnitt 9. Läuft serverseitig, kostet den Azubi
/// keinen Handgriff und keine Sekunde.
List<QualityFlag> evaluateQuality({
  required Questionnaire questionnaire,
  required Answers answers,

  /// Bearbeitungszeit je Bildschirm in Millisekunden.
  Map<String, int> timings = const {},

  /// Die bereits berechneten Werte. Fehlen sie, werden sie hier berechnet.
  ReviewScores? scores,
}) {
  final config = questionnaire.quality;
  final flags = <QualityFlag>[];
  final computed = scores ?? ReviewScores.compute(questionnaire, answers);

  final tooFast = [
    for (final entry in timings.entries)
      if (entry.value < config.minScreenMillis) entry.key,
  ]..sort();
  if (tooFast.isNotEmpty) {
    flags.add(QualityFlag(
      code: QualityFlag.tooFast,
      reason: '${tooFast.length} Bildschirm(e) unter '
          '${config.minScreenMillis} ms Bearbeitungszeit.',
      questionIds: tooFast,
    ));
  }

  final straightlining = _straightlining(questionnaire, answers);
  if (straightlining != null) flags.add(straightlining);

  for (final pair in config.pairs) {
    final a = questionnaire.question(pair.questionA);
    final b = questionnaire.question(pair.questionB);
    if (a == null || b == null) continue;
    final x = normalizedAnswer(a, answers[a.id]);
    final y = normalizedAnswer(b, answers[b.id]);
    if (x == null || y == null) continue;
    final delta = (x - y).abs();
    if (delta > pair.maxDelta) {
      flags.add(QualityFlag(
        code: QualityFlag.inconsistentPair,
        reason: 'Konsistenzpaar "${pair.id}": Abstand '
            '${delta.toStringAsFixed(2)} über der Grenze '
            '${pair.maxDelta.toStringAsFixed(2)}.',
        questionIds: [a.id, b.id],
      ));
    }
  }

  final delta = computed.overallDelta;
  if (delta != null && delta > config.overallMismatchMaxDelta) {
    flags.add(QualityFlag(
      code: QualityFlag.overallMismatch,
      reason: 'Frühes Gesamturteil und Detailwert liegen '
          '${delta.toStringAsFixed(2)} auseinander, erlaubt sind '
          '${config.overallMismatchMaxDelta.toStringAsFixed(2)}.',
      questionIds: [
        if (questionnaire.scoring.overallQuestionId != null)
          questionnaire.scoring.overallQuestionId!,
      ],
    ));
  }

  final context = QuestionnaireFlow(questionnaire).context(answers);
  for (final combination in questionnaire.quality.impossible) {
    if (!combination.condition.evaluate(context)) continue;
    final ids = <String>{};
    combination.condition.collectAnswerIds(ids);
    flags.add(QualityFlag(
      code: QualityFlag.impossibleCombination,
      reason: combination.reason?.current ??
          'Unmögliche Kombination "${combination.id}".',
      questionIds: ids.toList()..sort(),
    ));
  }

  final withText = [
    for (final id in config.freeTextQuestions)
      if (_hasText(answers[id])) id,
  ];
  if (withText.isNotEmpty) {
    // Absichtlich ohne Textklassifikation. Ein halbgarer Filter auf Namen und
    // Beleidigungen täuscht Sicherheit vor; stattdessen sieht ein Mensch jeden
    // Freitext. Siehe Abweichung A5 im Plan.
    flags.add(QualityFlag(
      code: QualityFlag.textNeedsReview,
      reason: 'Freitext vorhanden, geht in jedem Fall in die Moderation.',
      questionIds: withText,
    ));
  }

  return flags;
}

/// Der Straightlining-Index über die Dimensionsfragen.
///
/// Gemessen wird die Streuung der **Position** der gewählten Option, nicht die
/// ihrer Bedeutung. Genau daran hängt, dass die gemischte Polung funktioniert:
/// Wer bei K7 bis K11 immer die zweite Option antippt, hat hier fünfmal
/// dieselbe Position und damit Streuung null — obwohl die umgekehrt gepolte
/// K10 dann inhaltlich das Gegenteil der übrigen vier sagt. Ohne eine einzige
/// umgekehrt gepolte Frage im Satz wäre eine gleichförmige Folge dagegen völlig
/// plausibel, und der Index würde ehrliche Antworten bestrafen — deshalb greift
/// er dann gar nicht.
QualityFlag? _straightlining(Questionnaire questionnaire, Answers answers) {
  final config = questionnaire.quality;
  final positions = <double>[];
  final used = <String>[];
  var hasReversed = false;

  for (final id in config.straightliningQuestions) {
    final question = questionnaire.question(id);
    if (question == null) continue;
    final position = optionPosition(question, answers[id]);
    if (position == null) continue;
    positions.add(position);
    used.add(id);
    if (question.reversePolarity) hasReversed = true;
  }

  if (positions.length < 3 || !hasReversed) return null;

  final mean = positions.reduce((a, b) => a + b) / positions.length;
  final variance = positions
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b) /
      positions.length;

  if (variance > config.straightliningMaxVariance) return null;

  return QualityFlag(
    code: QualityFlag.straightlining,
    reason: 'Streuung der Antwortposition ${variance.toStringAsFixed(4)} liegt '
        'unter ${config.straightliningMaxVariance}, obwohl der Satz eine '
        'umgekehrt gepolte Frage enthält.',
    questionIds: used,
  );
}

bool _hasText(Object? value) {
  if (value is String) return value.trim().isNotEmpty;
  if (value is Map) return value.values.any(_hasText);
  if (value is Iterable) return value.any(_hasText);
  return false;
}
