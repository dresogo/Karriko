import '../model/questionnaire.dart';

/// Eine einzelne Bewertung, so wie die Aggregation sie braucht.
///
/// Bewusst nicht die ganze Einreichung: Für den Betriebsscore zählen die
/// Subscores, die Prioritäten und das Alter. Alles andere — Antworten,
/// Freitexte, Zeiten — geht die Aggregation nichts an und hat in ihrer
/// Signatur nichts zu suchen.
class AggregateInput {
  final Map<String, double> subscores;
  final Map<String, double> separate;

  /// Die ersten N aus K12, in der Reihenfolge des Rankings.
  final List<String> priorities;

  final DateTime publishedAt;

  /// K5, 0 bis 10.
  final int? recommend;

  const AggregateInput({
    required this.subscores,
    required this.publishedAt,
    this.separate = const {},
    this.priorities = const [],
    this.recommend,
  });
}

/// Das Ergebnis für einen Betrieb.
class CompanyAggregate {
  /// Die angezeigten Subscores, bereits geschrumpft.
  final Map<String, double> subscores;

  /// Getrennt ausgewiesen, nicht im Gesamtscore: die Berufsschule.
  final Map<String, double> separate;

  /// Die Gewichte, mit denen der Gesamtscore gebildet wurde.
  final Map<String, double> weights;

  final double? overall;

  /// Mittelwert der Weiterempfehlung, 0 bis 10.
  final double? recommendMean;

  final int reviewCount;

  /// Bewertungen nach Alterung gewichtet. Diese Zahl steuert die Schrumpfung,
  /// nicht [reviewCount] — zehn Bewertungen von 2019 sind weniger Grundlage
  /// als zehn von gestern.
  final double effectiveCount;

  /// Wie viele davon als alt gekennzeichnet werden.
  final int agedCount;

  final bool scoreVisible;
  final bool numbersVisible;

  const CompanyAggregate({
    required this.subscores,
    required this.weights,
    required this.reviewCount,
    required this.effectiveCount,
    required this.agedCount,
    required this.scoreVisible,
    required this.numbersVisible,
    this.separate = const {},
    this.overall,
    this.recommendMean,
  });

  /// Ob eine Bewertung dieses Alters gekennzeichnet wird.
  ///
  /// Ausbildungsqualität hängt oft an einzelnen Personen; wechselt die Person,
  /// sagt die alte Bewertung nichts mehr über den heutigen Betrieb.
  static bool isAged(
    Questionnaire questionnaire,
    DateTime publishedAt,
    DateTime now,
  ) =>
      _ageInYears(publishedAt, now) > questionnaire.scoring.agingYears;

  static double _ageInYears(DateTime publishedAt, DateTime now) =>
      now.difference(publishedAt).inDays / 365.25;

  static CompanyAggregate compute({
    required Questionnaire questionnaire,
    required List<AggregateInput> reviews,
    required DateTime now,

    /// Das Branchenmittel, gegen das geschrumpft wird. Fehlt es — und solange
    /// zu wenige Betriebe einer Branche bewertet sind, fehlt es —, greift
    /// `scoring.priorMean` aus der Definition.
    double? industryMean,
  }) {
    final scoring = questionnaire.scoring;
    final dimensions = [
      for (final dimension in scoring.dimensions)
        if (_enabled(questionnaire, dimension)) dimension,
    ];

    final weights = weightsFromPriorities(
      questionnaire: questionnaire,
      rankings: [for (final review in reviews) review.priorities],
      dimensions: dimensions,
    );

    final prior = industryMean ?? scoring.priorMean;
    final strength = scoring.shrinkageStrength;

    final subscores = <String, double>{};
    var effectiveCount = 0.0;
    var agedCount = 0;

    for (final review in reviews) {
      final aged = isAged(questionnaire, review.publishedAt, now);
      if (aged) agedCount++;
      effectiveCount += aged ? scoring.agedWeight : 1.0;
    }

    for (final dimension in dimensions) {
      var weighted = 0.0;
      var weightSum = 0.0;
      for (final review in reviews) {
        final score = review.subscores[dimension];
        if (score == null) continue;
        final weight = isAged(questionnaire, review.publishedAt, now)
            ? scoring.agedWeight
            : 1.0;
        weighted += score * weight;
        weightSum += weight;
      }
      if (weightSum == 0) continue;
      final mean = weighted / weightSum;
      subscores[dimension] = shrink(
        mean: mean,
        count: weightSum,
        prior: prior,
        strength: strength,
      );
    }

    final separate = <String, double>{};
    for (final key in scoring.separate) {
      var weighted = 0.0;
      var weightSum = 0.0;
      for (final review in reviews) {
        final score = review.separate[key];
        if (score == null) continue;
        final weight = isAged(questionnaire, review.publishedAt, now)
            ? scoring.agedWeight
            : 1.0;
        weighted += score * weight;
        weightSum += weight;
      }
      if (weightSum == 0) continue;
      separate[key] = shrink(
        mean: weighted / weightSum,
        count: weightSum,
        prior: prior,
        strength: strength,
      );
    }

    final recommendValues = [
      for (final review in reviews)
        if (review.recommend != null) review.recommend!,
    ];

    return CompanyAggregate(
      subscores: subscores,
      separate: separate,
      weights: weights,
      overall: _overall(subscores, weights),
      recommendMean: recommendValues.isEmpty
          ? null
          : recommendValues.reduce((a, b) => a + b) / recommendValues.length,
      reviewCount: reviews.length,
      effectiveCount: effectiveCount,
      agedCount: agedCount,
      scoreVisible: reviews.length >= questionnaire.visibility.scoreMinReviews,
      numbersVisible:
          reviews.length >= questionnaire.visibility.numbersMinReviews,
    );
  }

  /// Zieht den Mittelwert bei wenigen Bewertungen Richtung [prior].
  ///
  /// Das ist die wirksamste Maßnahme gegen die J-Kurve von Bewertungsportalen:
  /// Wer als Einziger eine 1,0 vergibt, drückt den angezeigten Wert nicht auf
  /// 1,0, sondern ein Stück weit — und mit jeder weiteren Bewertung nähert
  /// sich die Anzeige dem, was tatsächlich gemessen wurde.
  ///
  /// [strength] ist in „so vielen gedachten Bewertungen" zu lesen: Bei
  /// `strength: 5` wiegen fünf echte Bewertungen genauso schwer wie die
  /// Vorannahme.
  static double shrink({
    required double mean,
    required double count,
    required double prior,
    required double strength,
  }) {
    if (count + strength == 0) return prior;
    return (count * mean + strength * prior) / (count + strength);
  }

  /// Gewichte aus den aggregierten K12-Prioritäten aller Bewerter.
  ///
  /// Mit Untergrenze je Dimension, damit kein Bereich ganz herausfällt: Auch
  /// wenn niemand „Geld" unter die ersten drei gezogen hat, bleibt die
  /// Vergütung im Gesamtscore sichtbar. Ohne die Untergrenze könnte ein
  /// Betrieb eine Dimension gefahrlos vernachlässigen, sobald sie den Azubis
  /// dort einmal nicht wichtig genug war.
  ///
  /// Liegen gar keine Prioritäten vor, greifen die Standardgewichte.
  static Map<String, double> weightsFromPriorities({
    required Questionnaire questionnaire,
    required List<List<String>> rankings,
    required List<String> dimensions,
  }) {
    final scoring = questionnaire.scoring;
    final counts = <String, double>{for (final d in dimensions) d: 0};

    var total = 0.0;
    for (final ranking in rankings) {
      for (final priority in ranking) {
        final dimension = scoring.priorityToDimension[priority] ?? priority;
        if (!counts.containsKey(dimension)) continue;
        counts[dimension] = counts[dimension]! + 1;
        total++;
      }
    }

    final raw = <String, double>{};
    if (total == 0) {
      for (final dimension in dimensions) {
        raw[dimension] = scoring.defaultWeights[dimension] ?? 0;
      }
    } else {
      for (final dimension in dimensions) {
        raw[dimension] = counts[dimension]! / total;
      }
    }

    final floored = {
      for (final entry in raw.entries)
        entry.key: entry.value < scoring.weightFloor
            ? scoring.weightFloor
            : entry.value,
    };
    return _normalize(floored);
  }

  static double? _overall(
    Map<String, double> subscores,
    Map<String, double> weights,
  ) {
    var weighted = 0.0;
    var weightSum = 0.0;
    for (final entry in subscores.entries) {
      final weight = weights[entry.key];
      if (weight == null) continue;
      weighted += entry.value * weight;
      weightSum += weight;
    }
    if (weightSum == 0) return null;
    return weighted / weightSum;
  }

  static Map<String, double> _normalize(Map<String, double> weights) {
    final sum = weights.values.fold<double>(0, (a, b) => a + b);
    if (sum == 0) return weights;
    return {for (final e in weights.entries) e.key: e.value / sum};
  }

  static bool _enabled(Questionnaire questionnaire, String dimension) {
    final flag = questionnaire.scoring.dimensionFlags[dimension];
    return flag == null || questionnaire.flagEnabled(flag);
  }

  Map<String, Object?> toJson() => {
        'subscores': subscores,
        'separate': separate,
        'weights': weights,
        'overall': overall,
        'recommend_mean': recommendMean,
        'review_count': reviewCount,
        'effective_count': effectiveCount,
        'aged_count': agedCount,
        'score_visible': scoreVisible,
        'numbers_visible': numbersVisible,
      };
}
