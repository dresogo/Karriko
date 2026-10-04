import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  final questionnaire = fixtureQuestionnaire();

  List<String> codes(
    Map<String, Object?> answers, {
    Map<String, int> timings = const {},
  }) =>
      [
        for (final flag in evaluateQuality(
          questionnaire: questionnaire,
          answers: Answers.from(answers),
          timings: timings,
        ))
          flag.code,
      ];

  List<QualityFlag> flags(
    Map<String, Object?> answers, {
    Map<String, int> timings = const {},
  }) =>
      evaluateQuality(
        questionnaire: questionnaire,
        answers: Answers.from(answers),
        timings: timings,
      );

  /// Ein unauffälliger Stand: gestreute Antworten, passendes Gesamturteil.
  Map<String, Object?> unauffaellig() => {
        'k3_ueberstunden': 10,
        'k4_erreichbarkeit': 'meistens',
        'k6_gesamt': 72,
        'k7_anleitung': 'gut',
        'k8_lernwert': 'sehr_gut',
        'k9_umgang': 'freundlich',
        'k10_belastung': 'selten',
        'k11_planung': 'mittel',
      };

  test('Ein unauffälliger Stand bekommt kein Flag', () {
    expect(codes(unauffaellig()), isEmpty);
  });

  group('Bearbeitungszeit', () {
    test('Bildschirme unter der Mindestzeit werden markiert', () {
      final result = flags(
        unauffaellig(),
        timings: const {
          'k7_anleitung': 400,
          'k8_lernwert': 300,
          'k9_umgang': 5000,
        },
      );
      final flag = result.firstWhere((f) => f.code == QualityFlag.tooFast);
      expect(flag.questionIds, ['k7_anleitung', 'k8_lernwert']);
      expect(flag.reason, contains('1200 ms'));
    });

    test('Ausreichend lange Bildschirme nicht', () {
      expect(
        codes(unauffaellig(), timings: const {'k7_anleitung': 3000}),
        isEmpty,
      );
    });
  });

  group('Straightlining', () {
    test('Immer dieselbe Position wird markiert', () {
      // Überall die erste Option: bei K7, K8, K9 und K11 die beste Antwort,
      // bei der umgekehrt gepolten K10 die schlechteste. Das passt nicht
      // zusammen.
      final answers = unauffaellig()
        ..['k7_anleitung'] = 'sehr_gut'
        ..['k8_lernwert'] = 'sehr_gut'
        ..['k9_umgang'] = 'augenhoehe'
        ..['k10_belastung'] = 'fast_taeglich'
        ..['k11_planung'] = 'sehr_gut';
      expect(codes(answers), contains(QualityFlag.straightlining));
    });

    test('Die Begründung nennt die beteiligten Fragen', () {
      final answers = unauffaellig()
        ..['k7_anleitung'] = 'mittel'
        ..['k8_lernwert'] = 'mittel'
        ..['k9_umgang'] = 'sachlich'
        ..['k10_belastung'] = 'manchmal'
        ..['k11_planung'] = 'mittel';
      final flag = flags(answers)
          .firstWhere((f) => f.code == QualityFlag.straightlining);
      expect(flag.questionIds, hasLength(5));
      expect(flag.reason, contains('umgekehrt gepolte'));
    });

    test('Gestreute Antworten werden nicht markiert', () {
      expect(
          codes(unauffaellig()), isNot(contains(QualityFlag.straightlining)));
    });

    test('Zu wenige Antworten ergeben kein Urteil', () {
      final answers = {
        'k7_anleitung': 'sehr_gut',
        'k10_belastung': 'fast_taeglich',
      };
      expect(codes(answers), isNot(contains(QualityFlag.straightlining)));
    });

    test('Ohne eine umgekehrt gepolte Frage greift der Index nicht', () {
      // Ohne K10 ist eine gleichförmige Folge völlig plausibel — jemandem geht
      // es überall gleich gut. Den zu markieren wäre eine Unterstellung.
      final answers = unauffaellig()
        ..['k7_anleitung'] = 'sehr_gut'
        ..['k8_lernwert'] = 'sehr_gut'
        ..['k9_umgang'] = 'augenhoehe'
        ..['k11_planung'] = 'sehr_gut';
      answers.remove('k10_belastung');
      expect(codes(answers), isNot(contains(QualityFlag.straightlining)));
    });
  });

  group('Konsistenzpaar', () {
    test('K4 gegen die Erreichbarkeitsfrage im Ausbildermodul', () {
      final answers = unauffaellig()
        ..['k4_erreichbarkeit'] = 'immer'
        ..['m_ausbilder_erreichbar'] = 'nie';
      final flag = flags(answers)
          .firstWhere((f) => f.code == QualityFlag.inconsistentPair);
      expect(flag.questionIds, ['k4_erreichbarkeit', 'm_ausbilder_erreichbar']);
      expect(flag.reason, contains('k4_vs_ausbilder'));
    });

    test('Ein kleiner Abstand ist kein Widerspruch', () {
      final answers = unauffaellig()
        ..['k4_erreichbarkeit'] = 'immer'
        ..['m_ausbilder_erreichbar'] = 'meistens';
      expect(codes(answers), isNot(contains(QualityFlag.inconsistentPair)));
    });

    test('Ohne die zweite Antwort gibt es nichts zu vergleichen', () {
      expect(
        codes(unauffaellig()),
        isNot(contains(QualityFlag.inconsistentPair)),
      );
    });
  });

  group('Gesamturteil gegen Detailwert', () {
    test('Ein großer Abstand wird markiert', () {
      // Frühes Urteil ganz oben, Detailantworten ganz unten.
      final answers = {
        'k6_gesamt': 100,
        'k4_erreichbarkeit': 'nie',
        'k7_anleitung': 'sehr_schlecht',
        'k8_lernwert': 'sehr_schlecht',
        'k9_umgang': 'respektlos',
        'k10_belastung': 'fast_taeglich',
        'k11_planung': 'schlecht',
        'k3_ueberstunden': 60,
      };
      expect(codes(answers), contains(QualityFlag.overallMismatch));
    });

    test('Ein kleiner Abstand nicht', () {
      expect(
          codes(unauffaellig()), isNot(contains(QualityFlag.overallMismatch)));
    });
  });

  group('Unmögliche Kombinationen', () {
    test('Null Überstunden bei täglicher Erschöpfung durch Mehrarbeit', () {
      final answers = unauffaellig()
        ..['k3_ueberstunden'] = 0
        ..['k10_belastung'] = 'fast_taeglich';
      final flag = flags(answers)
          .firstWhere((f) => f.code == QualityFlag.impossibleCombination);
      expect(flag.reason, contains('Null Überstunden'));
      expect(flag.questionIds, ['k10_belastung', 'k3_ueberstunden']);
    });

    test('Getrennt ist beides unauffällig', () {
      expect(
        codes(unauffaellig()..['k3_ueberstunden'] = 0),
        isNot(contains(QualityFlag.impossibleCombination)),
      );
    });
  });

  group('Freitext', () {
    test('Jeder nicht leere Freitext geht in die Moderation', () {
      final answers = unauffaellig()
        ..['a1_freitext'] = {'gut': 'Die Kollegen.', 'schlecht': ''};
      final flag = flags(answers)
          .firstWhere((f) => f.code == QualityFlag.textNeedsReview);
      expect(flag.questionIds, ['a1_freitext']);
    });

    test('Leere Felder lösen nichts aus', () {
      final answers = unauffaellig()
        ..['a1_freitext'] = {'gut': '', 'schlecht': '   '};
      expect(codes(answers), isNot(contains(QualityFlag.textNeedsReview)));
    });
  });

  test('Ein Flag ist maschinenlesbar und begründet', () {
    final answers = unauffaellig()
      ..['a1_freitext'] = {'gut': 'x', 'schlecht': ''};
    final json = flags(answers).first.toJson();
    expect(json['code'], isA<String>());
    expect(json['reason'], isNotEmpty);
    expect(json['questions'], isA<List<String>>());
  });

  test('Mehrere Auffälligkeiten kommen alle heraus', () {
    // Überall die erste Option angetippt, dazu ein frühes Gesamturteil ganz
    // unten, das dazu nicht passt.
    final answers = {
      'k6_gesamt': 0,
      'k3_ueberstunden': 0,
      'k4_erreichbarkeit': 'immer',
      'm_ausbilder_erreichbar': 'nie',
      'k7_anleitung': 'sehr_gut',
      'k8_lernwert': 'sehr_gut',
      'k9_umgang': 'augenhoehe',
      'k10_belastung': 'fast_taeglich',
      'k11_planung': 'sehr_gut',
      'a1_freitext': {'gut': '', 'schlecht': 'Alles.'},
    };
    expect(
      codes(answers, timings: const {'k9_umgang': 200}),
      containsAll([
        QualityFlag.tooFast,
        QualityFlag.straightlining,
        QualityFlag.inconsistentPair,
        QualityFlag.overallMismatch,
        QualityFlag.impossibleCombination,
        QualityFlag.textNeedsReview,
      ]),
    );
  });
}
