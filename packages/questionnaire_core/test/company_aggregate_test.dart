import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

final _jetzt = DateTime.utc(2026, 9, 21);

AggregateInput review({
  double? fachlich,
  double? betreuung,
  double? umgang,
  double? belastung,
  double? perspektive,
  double? verguetung,
  List<String> priorities = const [],
  int? recommend,
  DateTime? publishedAt,
}) =>
    AggregateInput(
      subscores: {
        if (fachlich != null) 'fachlich': fachlich,
        if (betreuung != null) 'betreuung': betreuung,
        if (umgang != null) 'umgang': umgang,
        if (belastung != null) 'belastung': belastung,
        if (perspektive != null) 'perspektive': perspektive,
        if (verguetung != null) 'verguetung': verguetung,
      },
      priorities: priorities,
      recommend: recommend,
      publishedAt: publishedAt ?? _jetzt.subtract(const Duration(days: 30)),
    );

void main() {
  final questionnaire = fixtureQuestionnaire();

  CompanyAggregate aggregate(
    List<AggregateInput> reviews, {
    double? industryMean,
  }) =>
      CompanyAggregate.compute(
        questionnaire: questionnaire,
        reviews: reviews,
        now: _jetzt,
        industryMean: industryMean,
      );

  group('Schrumpfung', () {
    test('rechnet die gedachten Bewertungen dazu', () {
      // (1·5,0 + 5·3,2) / 6 = 3,5
      expect(
        CompanyAggregate.shrink(mean: 5, count: 1, prior: 3.2, strength: 5),
        closeTo(3.5, 1e-9),
      );
    });

    test('nähert sich mit steigender Zahl dem gemessenen Mittel', () {
      final wenige =
          CompanyAggregate.shrink(mean: 5, count: 1, prior: 3.2, strength: 5);
      final mehr =
          CompanyAggregate.shrink(mean: 5, count: 50, prior: 3.2, strength: 5);
      expect(mehr, greaterThan(wenige));
      expect(mehr, closeTo(4.84, 0.01));
    });

    test('ohne Bewertung bleibt die Vorannahme stehen', () {
      expect(
        CompanyAggregate.shrink(mean: 5, count: 0, prior: 3.2, strength: 5),
        3.2,
      );
    });

    test('Eine einzelne Extrembewertung schlägt nicht voll durch', () {
      final einzeln = aggregate([review(umgang: 1.0)]);
      expect(einzeln.subscores['umgang'], greaterThan(1.0));
      expect(einzeln.subscores['umgang'], closeTo(2.8333, 0.001));
    });

    test('Das Branchenmittel geht der Vorannahme vor', () {
      final ohne = aggregate([review(umgang: 5.0)]);
      final mit = aggregate([review(umgang: 5.0)], industryMean: 4.5);
      expect(mit.subscores['umgang']!, greaterThan(ohne.subscores['umgang']!));
    });
  });

  group('Alterung', () {
    final alt = _jetzt.subtract(const Duration(days: 365 * 4));
    final frisch = _jetzt.subtract(const Duration(days: 60));

    test('erkennt, was älter als die Grenze ist', () {
      expect(CompanyAggregate.isAged(questionnaire, alt, _jetzt), isTrue);
      expect(CompanyAggregate.isAged(questionnaire, frisch, _jetzt), isFalse);
    });

    test('zählt alte Bewertungen und gewichtet sie geringer', () {
      final result = aggregate([
        review(umgang: 5.0, publishedAt: frisch),
        review(umgang: 1.0, publishedAt: alt),
      ]);
      expect(result.reviewCount, 2);
      expect(result.agedCount, 1);
      // 1,0 + 0,5 gedachte Bewertungen.
      expect(result.effectiveCount, closeTo(1.5, 1e-9));
      // Der frische Wert zieht stärker als der alte: ungewichtet wäre das
      // Mittel 3,0, hier liegt es darüber.
      final ungewichtet =
          CompanyAggregate.shrink(mean: 3, count: 2, prior: 3.2, strength: 5);
      expect(result.subscores['umgang']!, greaterThan(ungewichtet));
    });
  });

  group('Gewichte aus den Prioritäten', () {
    List<String> dimensions() => [
          for (final d in questionnaire.scoring.dimensions)
            if (d != 'verguetung') d,
        ];

    test('ohne Prioritäten greifen die Standardgewichte', () {
      final weights = CompanyAggregate.weightsFromPriorities(
        questionnaire: questionnaire,
        rankings: const [],
        dimensions: dimensions(),
      );
      expect(weights.values.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
      // Die Standardgewichte fachlich, betreuung und umgang sind gleich groß.
      expect(weights['fachlich'], closeTo(weights['umgang']!, 1e-9));
      expect(weights['belastung']!, lessThan(weights['fachlich']!));
    });

    test('häufig genannte Dimensionen bekommen mehr Gewicht', () {
      final weights = CompanyAggregate.weightsFromPriorities(
        questionnaire: questionnaire,
        rankings: const [
          ['ausbilder', 'fachlich', 'team'],
          ['ausbilder', 'pruefung', 'umgang'],
        ],
        dimensions: dimensions(),
      );
      // „ausbilder" zeigt zweimal auf betreuung.
      expect(weights['betreuung']!, greaterThan(weights['belastung']!));
      expect(weights.values.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
    });

    test('Keine Dimension fällt ganz heraus', () {
      final weights = CompanyAggregate.weightsFromPriorities(
        questionnaire: questionnaire,
        rankings: const [
          ['ausbilder', 'ausbilder', 'ausbilder'],
        ],
        dimensions: dimensions(),
      );
      for (final dimension in dimensions()) {
        expect(
          weights[dimension],
          greaterThan(0),
          reason: 'Dimension $dimension ist unter den Tisch gefallen.',
        );
      }
      expect(weights.values.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
    });

    test('Eine abgeschaltete Dimension bekommt kein Gewicht', () {
      final result = aggregate([
        review(umgang: 4.0, priorities: const ['geld', 'umgang', 'fachlich']),
      ]);
      expect(result.weights.containsKey('verguetung'), isFalse);
      expect(result.weights.values.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
    });
  });

  group('Gesamtscore', () {
    test('ist das gewichtete Mittel der vorhandenen Subscores', () {
      final result = aggregate([
        review(umgang: 4.0, fachlich: 4.0, betreuung: 4.0),
        review(umgang: 4.0, fachlich: 4.0, betreuung: 4.0),
        review(umgang: 4.0, fachlich: 4.0, betreuung: 4.0),
      ]);
      // Alle drei Dimensionen gleich, also liegt der Gesamtwert genau auf dem
      // geschrumpften Einzelwert.
      final erwartet =
          CompanyAggregate.shrink(mean: 4, count: 3, prior: 3.2, strength: 5);
      expect(result.overall, closeTo(erwartet, 1e-9));
    });

    test('ohne Subscores gibt es keinen Gesamtwert', () {
      expect(aggregate(const []).overall, isNull);
    });

    test('mittelt die Weiterempfehlung', () {
      final result = aggregate([
        review(umgang: 4.0, recommend: 8),
        review(umgang: 4.0, recommend: 6),
        review(umgang: 4.0),
      ]);
      expect(result.recommendMean, closeTo(7.0, 1e-9));
    });
  });

  group('Sichtbarkeit', () {
    test('Score ab drei Bewertungen', () {
      expect(aggregate([review(umgang: 4.0), review(umgang: 4.0)]).scoreVisible,
          isFalse);
      expect(
        aggregate(
                [review(umgang: 4.0), review(umgang: 4.0), review(umgang: 4.0)])
            .scoreVisible,
        isTrue,
      );
    });

    test('Zahlenangaben ab fünf Bewertungen', () {
      final vier = [for (var i = 0; i < 4; i++) review(umgang: 4.0)];
      expect(aggregate(vier).numbersVisible, isFalse);
      expect(
        aggregate([...vier, review(umgang: 4.0)]).numbersVisible,
        isTrue,
      );
    });

    test('Zahlen erscheinen nur in Spannen, und die stehen in der Definition',
        () {
      final bands = questionnaire.visibility;
      expect(bands.bandFor('verguetung', 650)!.label.current, 'unter 700 €');
      expect(bands.bandFor('verguetung', 850)!.label.current, '700 bis 900 €');
      expect(bands.bandFor('verguetung', 1200)!.label.current, 'über 900 €');
      expect(bands.bandFor('ueberstunden', 5), isNull);
    });
  });

  test('toJson gibt heraus, was in company_scores landet', () {
    final json = aggregate([review(umgang: 4.0, recommend: 7)]).toJson();
    expect(json['review_count'], 1);
    expect(json['score_visible'], isFalse);
    expect(json['recommend_mean'], 7.0);
    expect(json['weights'], isA<Map<String, double>>());
  });
}
