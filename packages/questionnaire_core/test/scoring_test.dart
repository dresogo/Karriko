import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  final questionnaire = fixtureQuestionnaire();

  Question q(String id) => questionnaire.question(id)!;

  group('Normalisierung', () {
    test('Optionen liefern ihren hinterlegten Punktwert', () {
      expect(normalizedAnswer(q('k9_umgang'), 'augenhoehe'), 1.0);
      expect(normalizedAnswer(q('k9_umgang'), 'sachlich'), 0.5);
      expect(normalizedAnswer(q('k9_umgang'), 'respektlos'), 0.0);
    });

    test('Eine Option ohne Punktwert trägt nichts bei', () {
      // „weiß ich nicht" drückt keinen Subscore — es fällt aus der Rechnung.
      expect(normalizedAnswer(q('m_schule_interesse'), 'weiss_nicht'), isNull);
    });

    test('Eine unbekannte Option trägt nichts bei', () {
      expect(normalizedAnswer(q('k9_umgang'), 'nett'), isNull);
    });

    test('Stufen greifen von unten nach oben', () {
      expect(normalizedAnswer(q('k3_ueberstunden'), 0), 1.0);
      expect(normalizedAnswer(q('k3_ueberstunden'), 5), 0.75);
      expect(normalizedAnswer(q('k3_ueberstunden'), 10), 0.75);
      expect(normalizedAnswer(q('k3_ueberstunden'), 15), 0.5);
      expect(normalizedAnswer(q('k3_ueberstunden'), 60), 0.0);
    });

    test('Ein Sonderwert fällt aus den Stufen heraus', () {
      expect(normalizedAnswer(q('k3_ueberstunden'), 'weiss_nicht'), isNull);
    });

    test('Lineare Skalen rechnen über die Grenzen aus config', () {
      expect(normalizedAnswer(q('k6_gesamt'), 0), 0.0);
      expect(normalizedAnswer(q('k6_gesamt'), 50), 0.5);
      expect(normalizedAnswer(q('k6_gesamt'), 100), 1.0);
      expect(normalizedAnswer(q('k5_empfehlung'), 8), closeTo(0.8, 1e-9));
    });

    test('scoreMin und scoreMax gehen min und max vor', () {
      // Die Vergütungsfrage lässt bis 3000 zu, wertet aber bis 1500.
      expect(normalizedAnswer(q('m_geld_verguetung'), 750), 0.5);
      expect(normalizedAnswer(q('m_geld_verguetung'), 2000), 1.0);
    });

    test('Wischkarten ergeben den Anteil der Ja-Antworten', () {
      expect(
        normalizedAnswer(q('m_jas_karten'), {
          'berufsschultag': 'ja',
          'nach20uhr': 'ja',
          'samstag': 'nein',
        }),
        closeTo(2 / 3, 1e-9),
      );
    });

    test('„Weiß ich nicht" fällt bei Karten aus dem Nenner', () {
      expect(
        normalizedAnswer(q('m_jas_karten'), {
          'berufsschultag': 'ja',
          'nach20uhr': 'nein',
          'samstag': 'weiss_nicht',
        }),
        0.5,
      );
    });

    test('Nur Unbekanntes trägt nichts bei', () {
      expect(
        normalizedAnswer(q('m_jas_karten'), {'samstag': 'weiss_nicht'}),
        isNull,
      );
    });

    test('Eine Mehrfachauswahl mittelt die gewählten Optionen', () {
      expect(
        normalizedAnswer(q('k3_1_ausgleich'), 'teils'),
        0.5,
      );
    });

    test('Eine fehlende Antwort trägt nichts bei', () {
      expect(normalizedAnswer(q('k9_umgang'), null), isNull);
    });
  });

  group('Antwortposition', () {
    test('ist die Stelle in der Optionsliste, nicht die Bedeutung', () {
      // Position 0 ist bei K7 die beste, bei K10 die schlechteste Antwort.
      // Genau darauf baut der Straightlining-Index.
      expect(optionPosition(q('k7_anleitung'), 'sehr_gut'), 0.0);
      expect(optionPosition(q('k10_belastung'), 'fast_taeglich'), 0.0);
      expect(normalizedAnswer(q('k7_anleitung'), 'sehr_gut'), 1.0);
      expect(normalizedAnswer(q('k10_belastung'), 'fast_taeglich'), 0.0);
    });

    test('läuft von 0,0 bis 1,0', () {
      expect(optionPosition(q('k7_anleitung'), 'mittel'), 0.5);
      expect(optionPosition(q('k7_anleitung'), 'sehr_schlecht'), 1.0);
    });

    test('gibt es nicht ohne Optionen', () {
      expect(optionPosition(q('k6_gesamt'), 50), isNull);
    });
  });

  group('Werte einer Bewertung', () {
    Answers basis() => Answers.from({
          'k3_ueberstunden': 10,
          'k4_erreichbarkeit': 'meistens',
          'k5_empfehlung': 8,
          'k6_gesamt': 72,
          'k7_anleitung': 'gut',
          'k8_lernwert': 'gut',
          'k9_umgang': 'freundlich',
          'k10_belastung': 'selten',
          'k11_planung': 'mittel',
        });

    test('rechnet die Subscores auf der Skala 1,0 bis 5,0', () {
      final scores = ReviewScores.compute(questionnaire, basis());
      // fachlich: (0,75·1 + 0,5·0,5) / 1,5 = 0,6667 → 3,667
      expect(scores.subscores['fachlich'], closeTo(3.6667, 0.001));
      // betreuung: (0,75 + 0,75) / 2 = 0,75 → 4,0
      expect(scores.subscores['betreuung'], closeTo(4.0, 1e-9));
      expect(scores.subscores['umgang'], closeTo(4.0, 1e-9));
      // belastung: (0,75·1 + 0,75·0,5) / 1,5 = 0,75 → 4,0
      expect(scores.subscores['belastung'], closeTo(4.0, 1e-9));
    });

    test(
        'lässt eine Dimension ohne Antworten weg, statt sie auf null zu setzen',
        () {
      final scores = ReviewScores.compute(questionnaire, basis());
      expect(scores.subscores.containsKey('perspektive'), isFalse);
      expect(scores.separate, isEmpty);
    });

    test('wer ein Modul überspringt, wird dafür nicht bestraft', () {
      // Die fehlende Perspektive-Dimension fällt aus dem Nenner, statt den
      // Detailwert nach unten zu ziehen.
      final ohneModul = ReviewScores.compute(questionnaire, basis());
      final mitModul = ReviewScores.compute(
        questionnaire,
        basis().set('m_uebernahme_zeitpunkt', 'frueh'),
      );
      expect(ohneModul.detailOverall, closeTo(3.9111, 0.001));
      expect(mitModul.detailOverall, greaterThan(ohneModul.detailOverall!));
    });

    test('bringt das frühe Gesamturteil auf dieselbe Skala', () {
      final scores = ReviewScores.compute(questionnaire, basis());
      expect(scores.overallFromQuestion, closeTo(3.88, 1e-9));
    });

    test('der Abstand zwischen frühem Urteil und Detailwert ist ablesbar', () {
      final scores = ReviewScores.compute(questionnaire, basis());
      expect(scores.overallDelta, closeTo(0.0311, 0.001));
    });

    test('ohne frühes Urteil gibt es keinen Abstand', () {
      final scores = ReviewScores.compute(
        questionnaire,
        basis().remove(const ['k6_gesamt']),
      );
      expect(scores.overallFromQuestion, isNull);
      expect(scores.overallDelta, isNull);
    });

    test('die Berufsschule wird getrennt ausgewiesen', () {
      final scores = ReviewScores.compute(
        questionnaire,
        basis().set('m_schule_interesse', 'ja_aktiv'),
      );
      expect(scores.separate['berufsschule'], 5.0);
      expect(scores.subscores.containsKey('berufsschule'), isFalse);
      // Und fließt nicht in den Betriebswert ein.
      expect(
        scores.detailOverall,
        closeTo(
            ReviewScores.compute(questionnaire, basis()).detailOverall!, 1e-9),
      );
    });
  });

  group('Merkmalsschalter', () {
    Answers mitGeld() => Answers.from({
          'k9_umgang': 'freundlich',
          'm_geld_verguetung': 1200,
        });

    test('Eine abgeschaltete Dimension wird gar nicht erst gerechnet', () {
      final scores = ReviewScores.compute(questionnaire, mitGeld());
      expect(scores.subscores.containsKey('verguetung'), isFalse);
    });

    test('Mit eingeschaltetem Schalter zählt sie mit', () {
      final an = fixtureQuestionnaire(flags: const {'module_verguetung': true});
      final scores = ReviewScores.compute(an, mitGeld());
      expect(scores.subscores['verguetung'], closeTo(1 + 4 * 0.8, 1e-9));
    });
  });

  test('toJson gibt heraus, was die Function speichert', () {
    final scores = ReviewScores.compute(
      questionnaire,
      Answers.from({'k9_umgang': 'augenhoehe', 'k6_gesamt': 100}),
    );
    final json = scores.toJson();
    expect(json['detail_overall'], 5.0);
    expect(json['overall_from_question'], 5.0);
    expect((json['subscores']! as Map)['umgang'], 5.0);
  });
}
