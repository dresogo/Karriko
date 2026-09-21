import '../condition/condition.dart';
import 'json_reader.dart';
import 'question.dart';

/// Eine Phase des Ablaufs.
///
/// Der Fortschritt wird pro Phase angezeigt, nicht als Gesamtprozent: Die
/// Länge des Bogens hängt an den gewählten Modulen, ein Gesamtbalken würde
/// bei jeder Modulentscheidung springen.
class Phase {
  final String id;
  final TextVariants label;
  final int estimatedSeconds;

  /// In dieser Phase laufen die Module. Es gibt genau eine davon.
  final bool holdsModules;

  const Phase({
    required this.id,
    required this.label,
    this.estimatedSeconds = 0,
    this.holdsModules = false,
  });

  static Phase parse(JsonNode node) => Phase(
        id: node.require('id').asString,
        label: TextVariants.parse(node.require('label')),
        estimatedSeconds: node.child('estimatedSeconds').intOr(0),
        holdsModules: node.child('holdsModules').boolOr(false),
      );
}

/// Steuerung des Ablaufs, soweit sie Daten ist.
class FlowConfig {
  /// Frage, aus der die Zeitform folgt (S1).
  final String tenseQuestionId;

  /// Antworten auf [tenseQuestionId], die Vergangenheit bedeuten.
  final Set<String> pastValues;

  /// Prioritätenfrage (K12).
  final String priorityQuestionId;

  /// Wie viele der Prioritäten Module anbieten.
  final int priorityTopN;

  /// Schätzung pro Frage, wenn ein Modul keine eigene Angabe hat.
  final int secondsPerQuestion;

  const FlowConfig({
    required this.tenseQuestionId,
    required this.pastValues,
    required this.priorityQuestionId,
    this.priorityTopN = 3,
    this.secondsPerQuestion = 10,
  });

  static FlowConfig parse(JsonNode node) => FlowConfig(
        tenseQuestionId: node.require('tenseQuestion').asString,
        pastValues: node.require('pastValues').asStringList.toSet(),
        priorityQuestionId: node.require('priorityQuestion').asString,
        priorityTopN: node.child('priorityTopN').intOr(3),
        secondsPerQuestion: node.child('secondsPerQuestion').intOr(10),
      );
}

/// Ein Beitrag einer Frage zu einem Subscore.
class ScoringItem {
  final String questionId;
  final double weight;

  const ScoringItem({required this.questionId, this.weight = 1});

  static ScoringItem parse(JsonNode node) => ScoringItem(
        questionId: node.require('question').asString,
        weight: node.child('weight').doubleOr(1),
      );
}

/// Alles, was die Berechnung steuert. Kein einziger Grenzwert steht im Code.
class ScoringConfig {
  /// Die sechs Dimensionen des Betriebsscores, in fester Reihenfolge.
  final List<String> dimensions;

  /// Werte, die getrennt ausgewiesen werden und nicht in den Betriebsscore
  /// eingehen — die Berufsschule.
  final List<String> separate;

  /// Beiträge je Subscore, auch für die getrennten.
  final Map<String, List<ScoringItem>> items;

  /// Gewichte, solange keine K12-Prioritäten vorliegen.
  final Map<String, double> defaultWeights;

  /// Untergrenze je Dimension, damit kein Bereich ganz herausfällt.
  final double weightFloor;

  /// Wohin bei wenigen Bewertungen geschrumpft wird, solange es kein
  /// Branchenmittel gibt.
  final double priorMean;

  /// Stärke der Schrumpfung, gemessen in „so vielen gedachten Bewertungen".
  final double shrinkageStrength;

  /// Ab diesem Alter in Jahren zählt eine Bewertung weniger und wird
  /// gekennzeichnet.
  final double agingYears;

  /// Restgewicht einer gealterten Bewertung.
  final double agedWeight;

  /// Merkmalsschalter, an dem eine Dimension hängt. Steht er aus, fällt die
  /// Dimension aus der Gewichtung und die übrigen werden neu normiert.
  final Map<String, String> dimensionFlags;

  /// Die frühe Gesamtfrage K6. Ihr Wert wird veröffentlicht; der berechnete
  /// Detailwert dient dem Abgleich in A2 und der Qualitätsprüfung.
  final String? overallQuestionId;

  /// Die Weiterempfehlungsfrage K5.
  final String? recommendQuestionId;

  /// Welche Option der Prioritätenfrage K12 auf welche Dimension zeigt.
  ///
  /// K12 hat acht Karten, der Betriebsscore sechs Dimensionen — die beiden
  /// Listen decken sich nicht. „Mein Ausbilder" und „Stimmung im Team" zielen
  /// etwa auf dieselbe Dimension wie „Wie mit mir umgegangen wird". Ohne diese
  /// Zuordnung wären die Gewichte aus K12 nicht zu berechnen.
  final Map<String, String> priorityToDimension;

  const ScoringConfig({
    required this.dimensions,
    required this.items,
    required this.defaultWeights,
    this.separate = const [],
    this.overallQuestionId,
    this.recommendQuestionId,
    this.priorityToDimension = const {},
    this.weightFloor = 0.05,
    this.priorMean = 3.2,
    this.shrinkageStrength = 5,
    this.agingYears = 3,
    this.agedWeight = 0.5,
    this.dimensionFlags = const {},
  });

  static ScoringConfig parse(JsonNode node) {
    final items = <String, List<ScoringItem>>{};
    for (final entry in node.require('subscores').entries) {
      items[entry.key] = [
        for (final item in entry.value.require('items').items)
          ScoringItem.parse(item),
      ];
    }

    final weights = <String, double>{};
    for (final entry in node.require('defaultWeights').entries) {
      weights[entry.key] = entry.value.asDouble;
    }

    final flags = <String, String>{};
    for (final entry in node.child('dimensionFlags').entries) {
      flags[entry.key] = entry.value.asString;
    }

    final priorityMap = <String, String>{};
    for (final entry in node.child('priorityToDimension').entries) {
      priorityMap[entry.key] = entry.value.asString;
    }

    final shrinkage = node.child('shrinkage');
    final aging = node.child('aging');

    return ScoringConfig(
      dimensions: node.require('dimensions').asStringList,
      separate: node.child('separate').exists
          ? node.child('separate').asStringList
          : const [],
      overallQuestionId: node.child('overallQuestion').exists
          ? node.child('overallQuestion').asString
          : null,
      recommendQuestionId: node.child('recommendQuestion').exists
          ? node.child('recommendQuestion').asString
          : null,
      priorityToDimension: priorityMap,
      items: items,
      defaultWeights: weights,
      weightFloor: node.child('weightFloor').doubleOr(0.05),
      priorMean: node.child('priorMean').doubleOr(3.2),
      shrinkageStrength:
          shrinkage.exists ? shrinkage.child('strength').doubleOr(5) : 5,
      agingYears: aging.exists ? aging.child('years').doubleOr(3) : 3,
      agedWeight: aging.exists ? aging.child('weight').doubleOr(0.5) : 0.5,
      dimensionFlags: flags,
    );
  }
}

/// Ab wann was sichtbar wird.
class VisibilityConfig {
  /// Gesamtscore und Subscores.
  final int scoreMinReviews;

  /// Zahlenangaben wie Vergütung oder Überstunden, und nur in Spannen.
  final int numbersMinReviews;

  /// Spannen je Zahlenangabe: `{"verguetung": [{"max": 800, "label": "…"}, …]}`.
  final Map<String, List<NumberBand>> bands;

  const VisibilityConfig({
    this.scoreMinReviews = 3,
    this.numbersMinReviews = 5,
    this.bands = const {},
  });

  static VisibilityConfig parse(JsonNode node) {
    final bands = <String, List<NumberBand>>{};
    if (node.child('numberBands').exists) {
      for (final entry in node.child('numberBands').entries) {
        bands[entry.key] = [
          for (final item in entry.value.items) NumberBand.parse(item),
        ];
      }
    }
    return VisibilityConfig(
      scoreMinReviews: node.child('scoreMinReviews').intOr(3),
      numbersMinReviews: node.child('numbersMinReviews').intOr(5),
      bands: bands,
    );
  }

  /// Die Spanne, in die [value] fällt. `null`, wenn es zu diesem Schlüssel
  /// keine Spannen gibt oder der Wert über der letzten liegt.
  NumberBand? bandFor(String key, num value) {
    final list = bands[key];
    if (list == null) return null;
    for (final band in list) {
      if (band.max == null || value <= band.max!) return band;
    }
    return null;
  }
}

/// Eine Spanne, in der eine Zahl veröffentlicht wird. Der Text kommt aus der
/// Definition, nicht aus dem Code.
class NumberBand {
  final num? max;
  final TextVariants label;

  const NumberBand({this.max, required this.label});

  static NumberBand parse(JsonNode node) => NumberBand(
        max: node.child('max').exists ? node.child('max').asDouble : null,
        label: TextVariants.parse(node.require('label')),
      );
}

/// Ein Konsistenzpaar: zwei Fragen, deren Antworten zusammenpassen sollten.
class ConsistencyPair {
  final String id;
  final String questionA;
  final String questionB;

  /// Zulässiger Abstand auf der normalisierten Skala 0 bis 1.
  final double maxDelta;

  final TextVariants? reason;

  const ConsistencyPair({
    required this.id,
    required this.questionA,
    required this.questionB,
    this.maxDelta = 0.5,
    this.reason,
  });

  static ConsistencyPair parse(JsonNode node) => ConsistencyPair(
        id: node.require('id').asString,
        questionA: node.require('a').asString,
        questionB: node.require('b').asString,
        maxDelta: node.child('maxDelta').doubleOr(0.5),
        reason: TextVariants.parseOrNull(node.child('reason')),
      );
}

/// Eine Kombination, die es nicht geben kann.
class ImpossibleCombination {
  final String id;
  final Condition condition;
  final TextVariants? reason;

  const ImpossibleCombination({
    required this.id,
    required this.condition,
    this.reason,
  });

  static ImpossibleCombination parse(JsonNode node) => ImpossibleCombination(
        id: node.require('id').asString,
        condition: Condition.parse(node.require('condition')),
        reason: TextVariants.parseOrNull(node.child('reason')),
      );
}

/// Die Qualitätsfilter aus Abschnitt 9. Alles serverseitig, nichts davon führt
/// zur Löschung.
class QualityConfig {
  /// Unterschreitet ein Bildschirm diese Zeit, wird er markiert.
  final int minScreenMillis;

  /// Die Dimensionsfragen, über die der Straightlining-Index läuft.
  final List<String> straightliningQuestions;

  /// Unterhalb dieser Varianz gilt die Folge als durchgeklickt.
  final double straightliningMaxVariance;

  final List<ConsistencyPair> pairs;

  /// Zulässiger Abstand zwischen K6 und dem berechneten Detailwert, auf der
  /// Skala 1,0 bis 5,0. Derselbe Wert löst in A2 die Rückfrage aus.
  final double overallMismatchMaxDelta;

  final List<ImpossibleCombination> impossible;

  /// Fragen mit Freitext. Ein nicht leerer Freitext geht immer in die
  /// Moderation — siehe Abweichung A5 im Plan.
  final List<String> freeTextQuestions;

  const QualityConfig({
    this.minScreenMillis = 1200,
    this.straightliningQuestions = const [],
    this.straightliningMaxVariance = 0.01,
    this.pairs = const [],
    this.overallMismatchMaxDelta = 1,
    this.impossible = const [],
    this.freeTextQuestions = const [],
  });

  static QualityConfig parse(JsonNode node) {
    final straightlining = node.child('straightlining');
    return QualityConfig(
      minScreenMillis: node.child('minScreenMillis').intOr(1200),
      straightliningQuestions: straightlining.exists
          ? straightlining.require('questions').asStringList
          : const [],
      straightliningMaxVariance: straightlining.exists
          ? straightlining.child('maxVariance').doubleOr(0.01)
          : 0.01,
      pairs: [
        for (final item in node.child('pairs').items)
          ConsistencyPair.parse(item),
      ],
      overallMismatchMaxDelta: node.child('overallMismatch').exists
          ? node.child('overallMismatch').child('maxDelta').doubleOr(1)
          : 1,
      impossible: [
        for (final item in node.child('impossible').items)
          ImpossibleCombination.parse(item),
      ],
      freeTextQuestions: node.child('freeTextQuestions').exists
          ? node.child('freeTextQuestions').asStringList
          : const [],
    );
  }
}
