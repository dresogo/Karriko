import '../flow/answers.dart';
import '../model/questionnaire.dart';
import 'normalize.dart';

/// Die Werte einer einzelnen Bewertung.
///
/// Der Client darf das für die Anzeige rechnen — für den Abgleich in A2 muss
/// er es sogar. Verbindlich ist trotzdem nur, was die Function rechnet: Sie
/// bekommt dieselben Antworten, lädt dieselbe Version der Definition und
/// benutzt diesen Code. Dass beide Seiten dasselbe Ergebnis bekommen, ist
/// keine Absprache, sondern dasselbe Paket.
class ReviewScores {
  /// Die sechs Dimensionen, jeweils 1,0 bis 5,0. Eine Dimension ohne
  /// beantwortete Beiträge fehlt hier, statt mit 0 dazustehen.
  final Map<String, double> subscores;

  /// Getrennt ausgewiesen, fließt nicht in den Betriebsscore: die Berufsschule.
  final Map<String, double> separate;

  /// Der aus den Detailfragen berechnete Gesamtwert, 1,0 bis 5,0.
  final double? detailOverall;

  /// Das frühe Gesamturteil K6, auf dieselbe Skala gebracht.
  final double? overallFromQuestion;

  const ReviewScores({
    required this.subscores,
    this.separate = const {},
    this.detailOverall,
    this.overallFromQuestion,
  });

  /// Wie weit das frühe Urteil und der Detailwert auseinanderliegen.
  ///
  /// Das ist die Zahl, an der A2 hängt: Überschreitet sie den Schwellenwert
  /// aus der Definition, kommt die ruhige Rückfrage, und dieselbe Zahl landet
  /// als Flag in der Moderation.
  double? get overallDelta {
    final a = overallFromQuestion;
    final b = detailOverall;
    if (a == null || b == null) return null;
    return (a - b).abs();
  }

  static ReviewScores compute(Questionnaire questionnaire, Answers answers) {
    final scoring = questionnaire.scoring;
    final subscores = <String, double>{};
    final separate = <String, double>{};

    for (final entry in scoring.items.entries) {
      final key = entry.key;
      if (!_dimensionEnabled(questionnaire, key)) continue;

      var weighted = 0.0;
      var weightSum = 0.0;
      for (final item in entry.value) {
        final question = questionnaire.question(item.questionId);
        if (question == null) continue;
        final value = normalizedAnswer(question, answers[item.questionId]);
        if (value == null) continue;
        weighted += value * item.weight;
        weightSum += item.weight;
      }
      if (weightSum == 0) continue;

      final score = toScale(weighted / weightSum);
      if (scoring.separate.contains(key)) {
        separate[key] = score;
      } else {
        subscores[key] = score;
      }
    }

    return ReviewScores(
      subscores: subscores,
      separate: separate,
      detailOverall: _detailOverall(questionnaire, subscores),
      overallFromQuestion: _overall(questionnaire, answers),
    );
  }

  /// Eine Dimension fällt weg, wenn ihr Merkmalsschalter aus ist. Das ist der
  /// Weg, auf dem `module_verguetung` die Vergütung vollständig aus der
  /// Rechnung nimmt, statt sie mit fehlenden Werten zu verdünnen.
  static bool _dimensionEnabled(Questionnaire questionnaire, String dimension) {
    final flag = questionnaire.scoring.dimensionFlags[dimension];
    return flag == null || questionnaire.flagEnabled(flag);
  }

  /// Gewichtetes Mittel über die Dimensionen, die einen Wert haben.
  ///
  /// Die Gewichte der fehlenden Dimensionen werden nicht auf 0 gesetzt,
  /// sondern aus dem Nenner genommen. Sonst zöge jede unbeantwortete Dimension
  /// den Gesamtwert nach unten, und der Bogen bestrafte, wer ein Modul
  /// überspringt — genau das Gegenteil dessen, was Phase 2 erreichen soll.
  static double? _detailOverall(
    Questionnaire questionnaire,
    Map<String, double> subscores,
  ) {
    final weights = questionnaire.scoring.defaultWeights;
    var weighted = 0.0;
    var weightSum = 0.0;
    for (final dimension in questionnaire.scoring.dimensions) {
      final score = subscores[dimension];
      if (score == null) continue;
      final weight = weights[dimension] ?? 0;
      weighted += score * weight;
      weightSum += weight;
    }
    if (weightSum == 0) return null;
    return weighted / weightSum;
  }

  static double? _overall(Questionnaire questionnaire, Answers answers) {
    final id = questionnaire.scoring.overallQuestionId;
    if (id == null) return null;
    final question = questionnaire.question(id);
    if (question == null) return null;
    final value = normalizedAnswer(question, answers[id]);
    if (value == null) return null;
    return toScale(value);
  }

  Map<String, Object?> toJson() => {
        'subscores': subscores,
        'separate': separate,
        'detail_overall': detailOverall,
        'overall_from_question': overallFromQuestion,
      };
}
