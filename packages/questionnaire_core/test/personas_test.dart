import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// Vier vollständige Durchläufe, je einer pro Persona aus A7.
///
/// Der Kern dieser Tests ist [walk]: Es läuft den Bogen ab, wie ein Azubi ihn
/// abliefe — immer die nächste unbeantwortete Frage —, und vergleicht die
/// Strecke mit einem Drehbuch. Eine Frage, die auftaucht und nicht im Drehbuch
/// steht, lässt den Test scheitern. Eine Frage im Drehbuch, die nie kommt,
/// ebenso. Damit prüft jeder Persona-Test beides zugleich: **welche Fragen
/// erscheinen und welche nicht.**
class Walkthrough {
  final Answers answers;
  final List<String> asked;

  const Walkthrough(this.answers, this.asked);
}

Walkthrough walk(QuestionnaireFlow flow, Map<String, Object?> script) {
  var answers = const Answers.empty();
  final asked = <String>[];

  while (true) {
    final next = flow.nextUnanswered(answers);
    if (next == null) break;
    if (!script.containsKey(next.id)) {
      fail('Unerwartete Frage "${next.id}".\n'
          'Bis dahin: ${asked.join(' → ')}');
    }
    asked.add(next.id);
    answers = answers.set(next.id, script[next.id]);
  }

  final nieGefragt = [
    for (final id in script.keys)
      if (!asked.contains(id)) id,
  ];
  expect(
    nieGefragt,
    isEmpty,
    reason: 'Im Drehbuch, aber nie gefragt: ${nieGefragt.join(', ')}',
  );

  return Walkthrough(answers, asked);
}

void main() {
  final questionnaire = fixtureQuestionnaire();
  final flow = QuestionnaireFlow(questionnaire);

  List<String> offered(Answers answers) =>
      [for (final module in flow.offeredModules(answers)) module.id];

  void erwarteGueltig(Answers answers) {
    final result =
        validateSubmission(questionnaire: questionnaire, answers: answers);
    expect(result.isValid, isTrue, reason: result.issues.join('\n'));
  }

  // ───────────────────────────────────────────────────────────────────────────
  group(
      'Persona 1 — aktueller Azubi, 1. Lehrjahr, einziger Azubi im '
      'Kleinbetrieb, minderjährig, Schichtarbeit', () {
    final script = <String, Object?>{
      's1_status': 'in_ausbildung',
      's4_lehrjahr': '1',
      's6_azubis': 'nur_ich',
      's7_form': 'dual',
      's8_alltag': {
        'schicht': 'ja',
        'wochenende': 'nein',
        'koerperlich': 'ja',
      },
      's9_minderjaehrig': 'ja',
      'k3_ueberstunden': 0,
      'k4_erreichbarkeit': 'meistens',
      'k5_empfehlung': 6,
      'k6_gesamt': 55,
      'k7_anleitung': 'gut',
      'k8_lernwert': 'mittel',
      'k9_umgang': 'freundlich',
      'k10_belastung': 'oft',
      'k11_planung': 'schlecht',
      'k12_prioritaeten': ['fachlich', 'umgang', 'arbeitszeit'],
      'arbeitszeit__teaser': 'ja',
      'm_arbeitszeit_planbarkeit': 'woche_vorher',
      'jugendarbeitsschutz__teaser': 'ja',
      'm_jas_karten': {
        'berufsschultag': 'ja',
        'nach20uhr': 'nein',
        'samstag': 'weiss_nicht',
      },
      'berufsschule__teaser': 'ja',
      'm_schule_interesse': 'ja_aktiv',
      'a1_freitext': {'gut': '', 'schlecht': ''},
      'a3_tagesform': 'mittel',
    };

    late final Walkthrough run;
    setUpAll(() => run = walk(flow, script));

    test('läuft genau die Strecke des Drehbuchs', () {
      expect(run.asked, script.keys.toList());
      erwarteGueltig(run.answers);
    });

    test('bleibt im Präsens', () {
      expect(flow.tense(run.answers), Tense.current);
      expect(
        questionnaire.question('k3_ueberstunden')!.text.forTense(Tense.current),
        contains('letzten vier Wochen'),
      );
    });

    test('wird nach dem Lehrjahr gefragt', () {
      expect(run.asked, contains('s4_lehrjahr'));
    });

    test('bekommt das Jugendarbeitsschutzmodul über S9', () {
      expect(offered(run.answers), contains('jugendarbeitsschutz'));
    });

    test('bekommt das Arbeitszeitmodul über K12 und die Schichtarbeit', () {
      expect(offered(run.answers), contains('arbeitszeit'));

      // Auch ohne K12 käme es — die Schichtkarte allein reicht.
      final ohneK12 = run.answers
          .set('k12_prioritaeten', const ['fachlich', 'umgang', 'team']);
      expect(flow.offeredModules(ohneK12).map((m) => m.id),
          contains('arbeitszeit'));
    });

    test('bekommt kein Prüfungs-, Übernahme- oder Abbruchmodul', () {
      expect(
        offered(run.answers),
        isNot(anyOf(
          contains('pruefung'),
          contains('uebernahme'),
          contains('abbruch'),
          contains('konflikte'),
        )),
      );
    });

    test('ist ein Kleinbetriebsfall, für den die Schutzoption greift', () {
      expect(run.answers['s6_azubis'], 'nur_ich');
      expect(
          questionnaire.flagEnabled('delayed_publish_small_business'), isTrue);
    });

    test('ergibt die erwarteten Werte', () {
      final scores = ReviewScores.compute(questionnaire, run.answers);
      // fachlich: (0,5·1 + 0,25·0,5) / 1,5
      expect(scores.subscores['fachlich'], closeTo(2.6667, 0.001));
      expect(scores.subscores['betreuung'], closeTo(4.0, 1e-9));
      expect(scores.subscores['umgang'], closeTo(4.0, 1e-9));
      // belastung: (0,25·1 + 1,0·0,5 + 0,5·0,5) / 2,0
      expect(scores.subscores['belastung'], closeTo(3.0, 1e-9));
      // Ohne Übernahmemodul gibt es keine Perspektive-Dimension.
      expect(scores.subscores.containsKey('perspektive'), isFalse);
      // Die Berufsschule steht daneben, nicht darin.
      expect(scores.separate['berufsschule'], closeTo(5.0, 1e-9));
      expect(scores.detailOverall, closeTo(3.4444, 0.001));
      expect(scores.overallFromQuestion, closeTo(3.2, 1e-9));
    });

    test('ist unauffällig', () {
      expect(
        evaluateQuality(questionnaire: questionnaire, answers: run.answers),
        isEmpty,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group(
      'Persona 2 — ausgelernt und geblieben, großer Betrieb, Ausbilder und '
      'Prüfung im Ranking', () {
    final script = <String, Object?>{
      's1_status': 'ausgelernt_geblieben',
      's6_azubis': 'mehr',
      's7_form': 'dual',
      's8_alltag': {
        'schicht': 'nein',
        'wochenende': 'nein',
        'koerperlich': 'nein',
      },
      's9_minderjaehrig': 'nein',
      'k3_ueberstunden': 15,
      'k3_1_ausgleich': 'abgefeiert',
      'k4_erreichbarkeit': 'immer',
      'k5_empfehlung': 9,
      'k6_gesamt': 85,
      'k7_anleitung': 'gut',
      'k8_lernwert': 'sehr_gut',
      'k9_umgang': 'augenhoehe',
      'k10_belastung': 'fast_nie',
      'k11_planung': 'gut',
      'k12_prioritaeten': ['ausbilder', 'pruefung', 'fachlich'],
      'ausbilder__teaser': 'ja',
      'm_ausbilder_gespraeche': 4,
      'm_ausbilder_erreichbar': 'immer',
      'pruefung__teaser': 'ja',
      'm_pruefung_lernzeit': 'ja_geregelt',
      'uebernahme__teaser': 'ja',
      'm_uebernahme_zeitpunkt': 'frueh',
      'berufsschule__teaser': 'ja',
      'm_schule_interesse': 'wenn_ich_erzaehle',
      'a1_freitext': {'gut': '', 'schlecht': ''},
      'a3_tagesform': 'gut',
    };

    late final Walkthrough run;
    setUpAll(() => run = walk(flow, script));

    test('läuft genau die Strecke des Drehbuchs', () {
      expect(run.asked, script.keys.toList());
      erwarteGueltig(run.answers);
    });

    test('wird durchgehend in der Vergangenheit gefragt', () {
      expect(flow.tense(run.answers), Tense.past);
      expect(
        questionnaire.question('k3_ueberstunden')!.text.forTense(Tense.past),
        contains('typischen Monat'),
      );
    });

    test('wird nicht nach dem Lehrjahr gefragt', () {
      expect(run.asked, isNot(contains('s4_lehrjahr')));
    });

    test('bekommt Ausbilder und Prüfung über das Ranking', () {
      expect(offered(run.answers), containsAll(['ausbilder', 'pruefung']));
    });

    test('bekommt die Übernahme über den Auslöser, nicht über das Ranking', () {
      expect(offered(run.answers), contains('uebernahme'));
      expect(run.answers['k12_prioritaeten'], isNot(contains('uebernahme')));
    });

    test('bekommt K3.1, weil es Überstunden gab', () {
      expect(run.asked, contains('k3_1_ausgleich'));
    });

    test('ergibt die erwarteten Werte', () {
      final scores = ReviewScores.compute(questionnaire, run.answers);
      // fachlich: (1,0·1 + 0,75·0,5 + 1,0·0,5) / 2,0
      expect(scores.subscores['fachlich'], closeTo(4.75, 1e-9));
      expect(scores.subscores['umgang'], closeTo(5.0, 1e-9));
      expect(scores.subscores['perspektive'], closeTo(5.0, 1e-9));
      expect(scores.separate['berufsschule'], closeTo(3.0, 1e-9));
      expect(scores.detailOverall, closeTo(4.7089, 0.001));
    });

    test('das Konsistenzpaar passt zusammen und schlägt nicht an', () {
      final codes = [
        for (final flag in evaluateQuality(
          questionnaire: questionnaire,
          answers: run.answers,
        ))
          flag.code,
      ];
      expect(codes, isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Persona 3 — Abbrecher, Konflikt-Tor angenommen', () {
    final script = <String, Object?>{
      's1_status': 'abgebrochen',
      's6_azubis': '2_5',
      's7_form': 'dual',
      's8_alltag': {
        'schicht': 'nein',
        'wochenende': 'nein',
        'koerperlich': 'ja',
      },
      's9_minderjaehrig': 'nein',
      'k3_ueberstunden': 0,
      'k4_erreichbarkeit': 'selten',
      'k5_empfehlung': 1,
      'k6_gesamt': 20,
      'k7_anleitung': 'schlecht',
      'k8_lernwert': 'schlecht',
      'k9_umgang': 'respektlos',
      'k10_belastung': 'oft',
      'k11_planung': 'sehr_schlecht',
      'k12_prioritaeten': ['umgang', 'fachlich', 'team'],
      'ausbilder__teaser': 'ja',
      'm_ausbilder_gespraeche': 0,
      'm_ausbilder_erreichbar': 'selten',
      'berufsschule__teaser': 'ja',
      'm_schule_interesse': 'nein',
      'konflikte__teaser': 'ja',
      'm_konflikt_haeufigkeit': 'mehrfach',
      'abbruch__teaser': 'ja',
      'm_abbruch_ausschlag': ['betrieb', 'beruf'],
      'a1_freitext': {
        'gut': 'Die Kollegen in der Werkstatt.',
        'schlecht': 'Ich hatte das Gefühl, nicht ernst genommen zu werden.',
      },
      'a3_tagesform': 'schlecht',
    };

    late final Walkthrough run;
    setUpAll(() => run = walk(flow, script));

    test('läuft genau die Strecke des Drehbuchs', () {
      expect(run.asked, script.keys.toList());
      erwarteGueltig(run.answers);
    });

    test('bekommt das Abbruchmodul und kein Übernahmemodul', () {
      expect(offered(run.answers), contains('abbruch'));
      expect(offered(run.answers), isNot(contains('uebernahme')));
      expect(offered(run.answers), isNot(contains('pruefung')));
    });

    test('bekommt das Konfliktmodul nur hinter einem Tor', () {
      final modul = questionnaire.module('konflikte')!;
      expect(modul.gated, isTrue);
      expect(offered(run.answers), contains('konflikte'));

      // Ohne Zustimmung bleibt die Frage zu.
      final abgelehnt = run.answers.set('konflikte__teaser', 'nein');
      expect(
        [for (final q in flow.visibleQuestions(abgelehnt)) q.id],
        isNot(contains('m_konflikt_haeufigkeit')),
      );
    });

    test('die Konfliktfrage ist als sensibel gekennzeichnet', () {
      expect(
          questionnaire.question('m_konflikt_haeufigkeit')!.sensitive, isTrue);
    });

    test('die Anlaufstellen hängen nicht an der Antwort', () {
      // Am Ende des Moduls stehen sie unabhängig davon, was jemand angegeben
      // hat — auch bei „nie".
      expect(questionnaire.textList('help.anlaufstellen'), hasLength(3));
    });

    test('ergibt die erwarteten Werte', () {
      final scores = ReviewScores.compute(questionnaire, run.answers);
      expect(scores.subscores['fachlich'], closeTo(1.6667, 0.001));
      expect(scores.subscores['betreuung'], closeTo(1.8, 1e-9));
      expect(scores.subscores['umgang'], closeTo(1.0, 1e-9));
      // Null Überstunden heben die Belastung trotz allem an.
      expect(scores.subscores['belastung'], closeTo(3.0, 1e-9));
      expect(scores.detailOverall, closeTo(1.7911, 0.001));
    });

    test('das frühe Urteil und der Detailwert passen zusammen', () {
      final scores = ReviewScores.compute(questionnaire, run.answers);
      expect(scores.overallDelta!, lessThan(0.1));
    });

    test(
        'der Freitext geht in die Moderation, sonst gibt es nichts zu '
        'beanstanden', () {
      final codes = [
        for (final flag in evaluateQuality(
          questionnaire: questionnaire,
          answers: run.answers,
        ))
          flag.code,
      ];
      expect(codes, [QualityFlag.textNeedsReview]);
    });

    test(
        'eine einzelne harte Bewertung schlägt nicht voll auf den Betrieb '
        'durch', () {
      final scores = ReviewScores.compute(questionnaire, run.answers);
      final aggregate = CompanyAggregate.compute(
        questionnaire: questionnaire,
        reviews: [
          AggregateInput(
            subscores: scores.subscores,
            priorities: const ['umgang', 'fachlich', 'team'],
            publishedAt: DateTime.utc(2026, 9, 1),
          ),
        ],
        now: DateTime.utc(2026, 9, 21),
      );
      expect(aggregate.subscores['umgang'], greaterThan(1.0));
      expect(aggregate.scoreVisible, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group(
      'Persona 4 — ausgelernt und gegangen, duales Studium, alle Module '
      'übersprungen', () {
    final script = <String, Object?>{
      's1_status': 'ausgelernt_gegangen',
      's6_azubis': '6_20',
      's7_form': 'duales_studium',
      's8_alltag': {
        'schicht': 'nein',
        'wochenende': 'nein',
        'koerperlich': 'nein',
      },
      's9_minderjaehrig': 'nein',
      'k3_ueberstunden': 0,
      'k4_erreichbarkeit': 'meistens',
      'k5_empfehlung': 7,
      'k6_gesamt': 70,
      'k7_anleitung': 'gut',
      'k8_lernwert': 'gut',
      'k9_umgang': 'freundlich',
      'k10_belastung': 'selten',
      'k11_planung': 'mittel',
      'k12_prioritaeten': ['fachlich', 'umgang', 'team'],
      'pruefung__teaser': 'nein',
      'uebernahme__teaser': 'nein',
      'berufsschule__teaser': 'nein',
      'a1_freitext': {'gut': '', 'schlecht': ''},
      'a3_tagesform': 'gut',
    };

    late final Walkthrough run;
    setUpAll(() => run = walk(flow, script));

    test('läuft genau die Strecke des Drehbuchs', () {
      expect(run.asked, script.keys.toList());
      erwarteGueltig(run.answers);
    });

    test('bekommt drei Module angeboten und beantwortet keines', () {
      expect(offered(run.answers), ['pruefung', 'uebernahme', 'berufsschule']);
      expect(
        run.asked.where((id) => id.startsWith('m_')),
        isEmpty,
      );
    });

    test('der Teaser nennt vorab, worauf man sich einlässt', () {
      final teaser =
          flow.teaserFor(questionnaire.module('pruefung')!, run.answers);
      expect(teaser.questionCount, 1);
      expect(teaser.estimatedSeconds, 10);
    });

    test('ist nach Phase 1 trotzdem veröffentlichungsfähig', () {
      final scores = ReviewScores.compute(questionnaire, run.answers);
      expect(scores.subscores.keys,
          containsAll(['fachlich', 'betreuung', 'umgang', 'belastung']));
      expect(scores.subscores['fachlich'], closeTo(3.6667, 0.001));
      expect(scores.subscores['belastung'], closeTo(4.3333, 0.001));
      expect(scores.detailOverall, closeTo(3.9778, 0.001));
      expect(scores.overallFromQuestion, closeTo(3.8, 1e-9));
    });

    test('übersprungene Module drücken den Wert nicht', () {
      final ohneModule = ReviewScores.compute(questionnaire, run.answers);
      final mitModulen = ReviewScores.compute(
        questionnaire,
        run.answers
            .set('pruefung__teaser', 'ja')
            .set('m_pruefung_lernzeit', 'nein')
            .set('uebernahme__teaser', 'ja')
            .set('m_uebernahme_zeitpunkt', 'gar_nicht'),
      );
      // Wer die Module beantwortet und dort schlecht bewertet, landet
      // niedriger. Wer sie überspringt, wird dafür nicht bestraft — die
      // fehlenden Dimensionen fallen aus dem Nenner.
      expect(mitModulen.detailOverall!, lessThan(ohneModule.detailOverall!));
    });

    test('ist unauffällig', () {
      expect(
        evaluateQuality(questionnaire: questionnaire, answers: run.answers),
        isEmpty,
      );
    });
  });
}
