import 'dart:io';

import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

import 'walkthrough.dart';

/// Dieselben vier Personas aus A7, diesmal gegen die **echte** v1.
///
/// Der Testfragebogen in `personas_test.dart` prüft die Mechanik. Hier geht es
/// um den Inhalt: Kommt jeder durch, erscheinen die richtigen Module, bleibt
/// stehen was stehenbleiben soll. Ein Drehbuch, das nicht mehr aufgeht, ist
/// die erste Meldung darüber, dass eine Änderung an v1 mehr verschoben hat als
/// gedacht.
void main() {
  final v1 = Questionnaire.parseJsonString(
    File('../../karriko_flutter/assets/questionnaire/questionnaire_v1.json')
        .readAsStringSync(),
  );
  final flow = QuestionnaireFlow(v1);

  List<String> offered(Answers answers) =>
      [for (final module in flow.offeredModules(answers)) module.id];

  void erwarteGueltig(Answers answers) {
    final result = validateSubmission(questionnaire: v1, answers: answers);
    expect(result.isValid, isTrue, reason: result.issues.join('\n'));
  }

  /// Was am Ende von Phase 1 mindestens dastehen muss.
  ///
  /// „Nach Phase 1 ist eine veröffentlichungsfähige Bewertung vorhanden" —
  /// das ist die Zusage aus Abschnitt 2, und sie gilt unabhängig davon, ob
  /// jemand ein einziges Modul anfasst.
  void erwarteVeroeffentlichungsfaehig(ReviewScores scores) {
    expect(
      scores.subscores.keys,
      containsAll(['fachlich', 'betreuung', 'umgang', 'belastung']),
    );
    expect(scores.detailOverall, isNotNull);
    expect(scores.overallFromQuestion, isNotNull);
  }

  // ───────────────────────────────────────────────────────────────────────────
  group(
      'Persona 1 — aktueller Azubi, 1. Lehrjahr, einziger Azubi im '
      'Kleinbetrieb, minderjährig, Schichtarbeit', () {
    final script = <String, Object?>{
      'intro_anonymitaet': true,
      's1_status': 'in_ausbildung',
      's2_startjahr': 2025,
      's3_beruf':
          'Anlagenmechaniker/in für Sanitär-, Heizungs- und Klimatechnik',
      's4_lehrjahr': 'jahr_1',
      's5_betriebsgroesse': 'unter_10',
      's6_azubizahl': 'nur_ich',
      's7_ausbildungsform': 'dual',
      's8_arbeitsalltag': {
        'schichtarbeit': 'ja',
        'wochenenddienste': 'nein',
        'montage': 'ja',
        'kundenkontakt': 'ja',
        'fahrerei': 'ja',
        'koerperlich_schwer': 'ja',
        'bildschirm': 'nein',
      },
      's9_minderjaehrig': 'ja',
      's10_berufsschule_form': 'einzelne_tage',
      'k1_fakten': {
        'k1_1_ausbildungsplan': 'nein',
        'k1_2_ansprechpartner': 'ja',
        'k1_3_berichtsheft': 'nein',
        'k1_4_berufsschule': 'ja',
        'k1_5_ausruestung': 'ja',
        'k1_6_gespraeche': 'nein',
      },
      'k2_ausbildungsfremd': '1_3h',
      'k3_ueberstunden': 10,
      'k3_1_ausgleich': 'teils_teils',
      'k4_erreichbarkeit': 'meistens',
      'k5_empfehlung': 6,
      'k6_gesamt': 55,
      'k7_anleitung': 'in_eile',
      'k8_lernwert': 'etwa_haelfte',
      'k9_umgang': 'freundlich',
      'k10_belastung': 'oft',
      'k11_planung': 'kurzfristig',
      'k12_prioritaeten': ['fachlich', 'umgang', 'arbeitszeit'],
      'fachliche_qualitaet__teaser': 'ja',
      'mod_fachlich_fehlende_inhalte': ['einzelne'],
      'mod_fachlich_bekanntes': 'manchmal',
      'arbeitszeit__teaser': 'ja',
      'mod_arbeitszeit_planbarkeit': 'oft',
      'mod_arbeitszeit_freizeit': 'manchmal',
      'mod_arbeitszeit_urlaub_vorlauf': 'einige_wochen',
      'mod_arbeitszeit_urlaub_abgelehnt': 'einmal',
      'jugendarbeitsschutz__teaser': 'ja',
      'mod_jas_fakten': {
        'berufsschultag_frei': 'ja',
        'keine_arbeit_nach_20': 'ja',
        'keine_samstagsarbeit': 'nein',
        'pausen': 'weiss_nicht',
        'aerztliche_untersuchung': 'ja',
      },
      'gesundheit__teaser': 'ja',
      'mod_gesundheit_unterweisung': 'ja_einmal',
      'mod_gesundheit_psa': 'teilweise',
      'mod_gesundheit_grenze': 'oft',
      'berufsschule__teaser': 'ja',
      'mod_schule_interesse': 'wenn_ich_erzaehle',
      'a1_freitexte': {'a1_gut': '', 'a1_schlecht': ''},
      'a3_tagesform': 'mittel',
      'a3_2_kleinbetrieb': 'nach_ausbildungsende',
      'a4_vorschau': true,
      'a5_verifikation': null,
    };

    late final Walkthrough run;
    setUpAll(() => run = walk(flow, script));

    test('läuft genau die Strecke des Drehbuchs', () {
      expect(run.asked, script.keys.toList());
      erwarteGueltig(run.answers);
    });

    test('bleibt im Präsens', () {
      expect(flow.tense(run.answers), Tense.current);
    });

    test('wird nach dem Lehrjahr gefragt, nicht nach dem Ende', () {
      expect(run.asked, contains('s4_lehrjahr'));
      expect(run.asked, isNot(contains('s2_1_endjahr')));
    });

    test('bekommt Jugendarbeitsschutz, Arbeitszeit und Gesundheit', () {
      expect(
        offered(run.answers),
        containsAll(['jugendarbeitsschutz', 'arbeitszeit', 'gesundheit']),
      );
    });

    test('bekommt kein Prüfungs-, Übernahme-, Abbruch- oder Konfliktmodul', () {
      for (final id in ['pruefung', 'uebernahme', 'abbruch', 'konflikte']) {
        expect(offered(run.answers), isNot(contains(id)), reason: id);
      }
    });

    test(
        'bekommt den Kleinbetriebshinweis und wählt die spätere '
        'Veröffentlichung', () {
      expect(run.asked, contains('a3_2_kleinbetrieb'));
      expect(run.answers['a3_2_kleinbetrieb'], 'nach_ausbildungsende');
    });

    test('ist veröffentlichungsfähig, und die Belastung ist gedrückt', () {
      final scores = ReviewScores.compute(v1, run.answers);
      erwarteVeroeffentlichungsfaehig(scores);
      expect(scores.subscores['belastung']!, lessThan(3.0));
      expect(scores.separate['berufsschule'], closeTo(3.0, 1e-9));
    });

    test('frühes Urteil und Detailwert passen zusammen, deshalb kam A2 nicht',
        () {
      final scores = ReviewScores.compute(v1, run.answers);
      expect(scores.overallDelta!,
          lessThanOrEqualTo(v1.quality.overallMismatchMaxDelta));
      expect(run.asked, isNot(contains('a2_abgleich')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group(
      'Persona 2 — ausgelernt und geblieben, 250 Mitarbeiter, Ausbilder und '
      'Prüfung im Ranking', () {
    final script = <String, Object?>{
      'intro_anonymitaet': true,
      's1_status': 'ausgelernt_geblieben',
      's2_startjahr': 2021,
      's2_1_endjahr': 2024,
      's3_beruf': 'Industriekaufmann/-frau',
      's5_betriebsgroesse': 'ab_250',
      's6_azubizahl': 'mehr',
      's7_ausbildungsform': 'dual',
      's8_arbeitsalltag': {
        'schichtarbeit': 'nein',
        'wochenenddienste': 'nein',
        'montage': 'nein',
        'kundenkontakt': 'ja',
        'fahrerei': 'nein',
        'koerperlich_schwer': 'nein',
        'bildschirm': 'ja',
      },
      's9_minderjaehrig': 'nein',
      's10_berufsschule_form': 'block',
      'k1_fakten': {
        'k1_1_ausbildungsplan': 'ja',
        'k1_2_ansprechpartner': 'ja',
        'k1_3_berichtsheft': 'ja',
        'k1_4_berufsschule': 'ja',
        'k1_5_ausruestung': 'ja',
        'k1_6_gespraeche': 'ja',
      },
      'k2_ausbildungsfremd': 'unter_1h',
      'k3_ueberstunden': 15,
      'k3_1_ausgleich': 'abgefeiert',
      'k4_erreichbarkeit': 'immer',
      'k5_empfehlung': 9,
      'k6_gesamt': 85,
      'k7_anleitung': 'in_ruhe',
      'k8_lernwert': 'das_meiste',
      'k9_umgang': 'augenhoehe',
      'k10_belastung': 'fast_nie',
      'k11_planung': 'klar_geregelt',
      'k12_prioritaeten': ['ausbilder', 'pruefung', 'fachlich'],
      'ausbilder__teaser': 'ja',
      'mod_ausbilder_gespraeche': 4,
      'mod_ausbilder_kennt_stand': 'passende_aufgaben',
      'mod_ausbilder_fehler': 'erklaert_nochmal',
      'mod_ausbilder_erreichbar': 'immer',
      'fachliche_qualitaet__teaser': 'ja',
      'mod_fachlich_fehlende_inhalte': ['keine'],
      'mod_fachlich_bekanntes': 'selten',
      'pruefung__teaser': 'ja',
      'mod_pruefung_vorbereitung': 'systematisch',
      'mod_pruefung_lernzeit': 'ja_geregelt',
      'mod_pruefung_unterricht': 'ja',
      'uebernahme__teaser': 'ja',
      'mod_uebernahme_zeitpunkt': 'frueh',
      'berufsschule__teaser': 'ja',
      'mod_schule_interesse': 'ja_aktiv',
      'a1_freitexte': {'a1_gut': '', 'a1_schlecht': ''},
      'a3_tagesform': 'gut',
      'a4_vorschau': true,
      'a5_verifikation': null,
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
        v1.question('k3_ueberstunden')!.text.forTense(Tense.past),
        contains('typischen Monat'),
      );
    });

    test('wird nach dem Ende gefragt, nicht nach dem Lehrjahr', () {
      expect(run.asked, contains('s2_1_endjahr'));
      expect(run.asked, isNot(contains('s4_lehrjahr')));
    });

    test('bekommt Ausbilder und Prüfung über das Ranking', () {
      expect(offered(run.answers), containsAll(['ausbilder', 'pruefung']));
    });

    test('bekommt die Übernahme über den Auslöser, nicht über das Ranking', () {
      expect(offered(run.answers), contains('uebernahme'));
      expect(run.answers['k12_prioritaeten'], isNot(contains('uebernahme')));
    });

    test('wird als Gebliebener nicht gefragt, warum er gegangen ist', () {
      expect(run.asked, isNot(contains('mod_uebernahme_weggang')));
    });

    test('bekommt kein Kleinbetriebshinweis', () {
      expect(run.asked, isNot(contains('a3_2_kleinbetrieb')));
    });

    test('ergibt durchweg hohe Werte', () {
      final scores = ReviewScores.compute(v1, run.answers);
      erwarteVeroeffentlichungsfaehig(scores);
      expect(scores.subscores['umgang'], closeTo(5.0, 1e-9));
      expect(scores.subscores['perspektive'], closeTo(5.0, 1e-9));
      expect(scores.detailOverall!, greaterThan(4.0));
      expect(scores.separate['berufsschule'], closeTo(5.0, 1e-9));
    });

    test('ist unauffällig — auch das Konsistenzpaar passt', () {
      expect(evaluateQuality(questionnaire: v1, answers: run.answers), isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Persona 3 — Abbrecher, Konflikt-Tor angenommen', () {
    final script = <String, Object?>{
      'intro_anonymitaet': true,
      's1_status': 'abgebrochen',
      's2_startjahr': 2025,
      's2_1_endjahr': 2026,
      's3_beruf': 'Kaufmann/-frau im Einzelhandel',
      's4_lehrjahr': 'jahr_1',
      's5_betriebsgroesse': '10_49',
      's6_azubizahl': '2_5',
      's7_ausbildungsform': 'dual',
      's8_arbeitsalltag': {
        'schichtarbeit': 'nein',
        'wochenenddienste': 'nein',
        'montage': 'nein',
        'kundenkontakt': 'ja',
        'fahrerei': 'nein',
        'koerperlich_schwer': 'ja',
        'bildschirm': 'nein',
      },
      's9_minderjaehrig': 'nein',
      's10_berufsschule_form': 'einzelne_tage',
      'k1_fakten': {
        'k1_1_ausbildungsplan': 'nein',
        'k1_2_ansprechpartner': 'nein',
        'k1_3_berichtsheft': 'nein',
        'k1_4_berufsschule': 'ja',
        'k1_5_ausruestung': 'nein',
        'k1_6_gespraeche': 'nein',
      },
      'k2_ausbildungsfremd': 'ueber_3h',
      'k3_ueberstunden': 0,
      'k4_erreichbarkeit': 'selten',
      'k5_empfehlung': 1,
      'k6_gesamt': 15,
      'k7_anleitung': 'selbst_suchen',
      'k8_lernwert': 'eher_wenig',
      'k9_umgang': 'respektlos',
      'k10_belastung': 'oft',
      'k11_planung': 'immer_dasselbe',
      'k12_prioritaeten': ['umgang', 'fachlich', 'team'],
      'ausbilder__teaser': 'ja',
      'mod_ausbilder_gespraeche': 0,
      'mod_ausbilder_kennt_stand': 'kennt_ihn_nicht',
      'mod_ausbilder_fehler': 'wird_laut',
      'mod_ausbilder_erreichbar': 'selten',
      'fachliche_qualitaet__teaser': 'ja',
      'mod_fachlich_fehlende_inhalte': ['groessere_teile'],
      'mod_fachlich_bekanntes': 'oft',
      'gesundheit__teaser': 'nein',
      'berufsschule__teaser': 'ja',
      'mod_schule_interesse': 'nein',
      'konflikte__teaser': 'ja',
      'mod_konflikt_haeufigkeit': 'mehrfach',
      'mod_konflikt_art': ['anschreien', 'herabwuerdigung'],
      'mod_konflikt_angesprochen': 'ja',
      'mod_konflikt_reaktion': 'nichts',
      'mod_konflikt_anlaufstellen': true,
      'abbruch__teaser': 'ja',
      'mod_abbruch_zeitpunkt': 'jahr_1',
      'mod_abbruch_wer': 'ich',
      'mod_abbruch_ausschlag': ['anleitung', 'umgang'],
      'mod_abbruch_gut': {'gut': 'Eine Kollegin hat sich um mich gekümmert.'},
      'a1_freitexte': {
        'a1_gut': 'Eine Kollegin hat sich um mich gekümmert.',
        'a1_schlecht': 'Ich hatte das Gefühl, nicht ernst genommen zu werden.',
      },
      'a3_tagesform': 'schlecht',
      'a3_2_kleinbetrieb': 'sofort',
      'a4_vorschau': true,
      'a5_verifikation': null,
    };

    late final Walkthrough run;
    setUpAll(() => run = walk(flow, script));

    test('läuft genau die Strecke des Drehbuchs', () {
      expect(run.asked, script.keys.toList());
      erwarteGueltig(run.answers);
    });

    test('bekommt das Abbruchmodul, aber kein Prüfungs- oder Übernahmemodul',
        () {
      expect(offered(run.answers), contains('abbruch'));
      expect(offered(run.answers), isNot(contains('pruefung')));
      expect(offered(run.answers), isNot(contains('uebernahme')));
    });

    test('kommt nur über das Tor ins Konfliktmodul', () {
      expect(v1.module('konflikte')!.gated, isTrue);
      final abgelehnt = run.answers.set('konflikte__teaser', 'nein');
      final sichtbar = [for (final q in flow.visibleQuestions(abgelehnt)) q.id];
      for (final id in v1.module('konflikte')!.questionIds) {
        expect(sichtbar, isNot(contains(id)), reason: id);
      }
    });

    test('bekommt die Nachfrage zur Reaktion nur, weil er es angesprochen hat',
        () {
      expect(run.asked, contains('mod_konflikt_reaktion'));
      final nichtAngesprochen =
          run.answers.set('mod_konflikt_angesprochen', 'nein');
      expect(
        [for (final q in flow.visibleQuestions(nichtAngesprochen)) q.id],
        isNot(contains('mod_konflikt_reaktion')),
      );
    });

    test(
        'bekommt die Anlaufstellen am Ende des Moduls, egal was er '
        'geantwortet hat', () {
      expect(run.asked, contains('mod_konflikt_anlaufstellen'));
      final harmlos = run.answers.set('mod_konflikt_haeufigkeit', 'nie');
      expect(
        [for (final q in flow.visibleQuestions(harmlos)) q.id],
        contains('mod_konflikt_anlaufstellen'),
      );
    });

    test('wird gefragt, ob der Betrieb etwas gut gemacht hat', () {
      // Kein Beschwichtigungsversuch: Die Frage erzwingt eine differenzierte
      // Erinnerung und senkt die Extremität des Gesamturteils.
      expect(run.asked, contains('mod_abbruch_gut'));
    });

    test('ergibt durchweg niedrige Werte', () {
      final scores = ReviewScores.compute(v1, run.answers);
      erwarteVeroeffentlichungsfaehig(scores);
      expect(scores.subscores['umgang'], closeTo(1.0, 1e-9));
      expect(scores.subscores['betreuung']!, lessThan(2.0));
      expect(scores.detailOverall!, lessThan(2.5));
    });

    test('der Freitext geht in die Moderation', () {
      final codes = [
        for (final flag
            in evaluateQuality(questionnaire: v1, answers: run.answers))
          flag.code,
      ];
      expect(codes, contains(QualityFlag.textNeedsReview));
    });

    test(
        'eine einzelne harte Bewertung schlägt nicht voll auf den Betrieb '
        'durch', () {
      final scores = ReviewScores.compute(v1, run.answers);
      final aggregat = CompanyAggregate.compute(
        questionnaire: v1,
        reviews: [
          AggregateInput(
            subscores: scores.subscores,
            priorities: const ['umgang', 'fachlich', 'team'],
            publishedAt: DateTime.utc(2026, 9, 1),
          ),
        ],
        now: DateTime.utc(2026, 9, 21),
      );
      expect(aggregat.subscores['umgang']!, greaterThan(1.0));
      expect(aggregat.scoreVisible, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group(
      'Persona 4 — ausgelernt und gegangen, duales Studium, alle Module '
      'übersprungen', () {
    final script = <String, Object?>{
      'intro_anonymitaet': true,
      's1_status': 'ausgelernt_gegangen',
      's2_startjahr': 2020,
      's2_1_endjahr': 2023,
      's3_beruf': 'Fachinformatiker/in für Anwendungsentwicklung',
      's5_betriebsgroesse': '50_249',
      's6_azubizahl': '6_20',
      's7_ausbildungsform': 'duales_studium',
      's8_arbeitsalltag': {
        'schichtarbeit': 'nein',
        'wochenenddienste': 'nein',
        'montage': 'nein',
        'kundenkontakt': 'nein',
        'fahrerei': 'nein',
        'koerperlich_schwer': 'nein',
        'bildschirm': 'ja',
      },
      's9_minderjaehrig': 'nein',
      's10_berufsschule_form': 'block',
      'k1_fakten': {
        'k1_1_ausbildungsplan': 'ja',
        'k1_2_ansprechpartner': 'ja',
        'k1_3_berichtsheft': 'ja',
        'k1_4_berufsschule': 'ja',
        'k1_5_ausruestung': 'ja',
        'k1_6_gespraeche': 'nein',
      },
      'k2_ausbildungsfremd': 'gar_nichts',
      'k3_ueberstunden': 0,
      'k4_erreichbarkeit': 'meistens',
      'k5_empfehlung': 7,
      'k6_gesamt': 70,
      'k7_anleitung': 'in_eile',
      'k8_lernwert': 'das_meiste',
      'k9_umgang': 'freundlich',
      'k10_belastung': 'selten',
      'k11_planung': 'ungefaehr',
      'k12_prioritaeten': ['fachlich', 'umgang', 'team'],
      'fachliche_qualitaet__teaser': 'nein',
      'pruefung__teaser': 'nein',
      'uebernahme__teaser': 'nein',
      'berufsschule__teaser': 'nein',
      'a1_freitexte': {'a1_gut': '', 'a1_schlecht': ''},
      'a3_tagesform': 'gut',
      'a4_vorschau': true,
      'a5_verifikation': null,
    };

    late final Walkthrough run;
    setUpAll(() => run = walk(flow, script));

    test('läuft genau die Strecke des Drehbuchs', () {
      expect(run.asked, script.keys.toList());
      erwarteGueltig(run.answers);
    });

    test('bekommt vier Module angeboten und beantwortet keines', () {
      expect(offered(run.answers),
          ['fachliche_qualitaet', 'pruefung', 'uebernahme', 'berufsschule']);
      expect(run.asked.where((id) => id.startsWith('mod_')), isEmpty);
    });

    test('der Teaser nennt vorab Fragenzahl und Dauer', () {
      final teaser = flow.teaserFor(v1.module('pruefung')!, run.answers);
      expect(teaser.questionCount, 3);
      expect(teaser.estimatedSeconds, 30);
    });

    test('ist nach Phase 1 trotzdem veröffentlichungsfähig', () {
      final scores = ReviewScores.compute(v1, run.answers);
      erwarteVeroeffentlichungsfaehig(scores);
      // Ohne Module gibt es keine Perspektive und keine Berufsschule.
      expect(scores.subscores.containsKey('perspektive'), isFalse);
      expect(scores.separate, isEmpty);
    });

    test('das Überspringen kostet keinen Punkt', () {
      final ohne = ReviewScores.compute(v1, run.answers);
      final mitSchlechtenModulen = ReviewScores.compute(
        v1,
        run.answers
            .set('pruefung__teaser', 'ja')
            .set('mod_pruefung_vorbereitung', 'gar_nicht')
            .set('mod_pruefung_lernzeit', 'nein')
            .set('mod_pruefung_unterricht', 'nein'),
      );
      expect(
          mitSchlechtenModulen.detailOverall!, lessThan(ohne.detailOverall!));
    });

    test('ist unauffällig', () {
      expect(evaluateQuality(questionnaire: v1, answers: run.answers), isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Die beiden Stellen, die an abgeleiteten Werten hängen', () {
    test(
        'A2 erscheint erst, wenn frühes Urteil und Detailwert auseinander '
        'liegen', () {
      final antworten = Answers.from({
        's1_status': 'in_ausbildung',
        'k6_gesamt': 95,
        'k9_umgang': 'respektlos',
      });

      final ohne =
          QuestionnaireFlow(v1, computed: const {'overall_delta': 0.4});
      expect(
        [for (final q in ohne.visibleQuestions(antworten)) q.id],
        isNot(contains('a2_abgleich')),
      );

      final mit = QuestionnaireFlow(v1, computed: const {'overall_delta': 2.1});
      expect(
        [for (final q in mit.visibleQuestions(antworten)) q.id],
        contains('a2_abgleich'),
      );
    });

    test('Der Korrekturregler kommt nur, wenn jemand ihn verlangt', () {
      final flowMitDelta =
          QuestionnaireFlow(v1, computed: const {'overall_delta': 2.1});
      final basis = Answers.from({
        's1_status': 'in_ausbildung',
        'k6_gesamt': 95,
      });

      for (final wahl in ['frueh', 'detail']) {
        expect(
          [
            for (final q in flowMitDelta
                .visibleQuestions(basis.set('a2_abgleich', wahl)))
              q.id,
          ],
          isNot(contains('a2_1_korrektur')),
          reason: wahl,
        );
      }

      expect(
        [
          for (final q
              in flowMitDelta.visibleQuestions(basis.set('a2_abgleich', 'neu')))
            q.id,
        ],
        contains('a2_1_korrektur'),
      );
    });

    test(
        'Das Angebot, in drei Tagen nochmal draufzuschauen, braucht beides: '
        'schlechten Tag und extreme Bewertung', () {
      final basis = Answers.from({'s1_status': 'in_ausbildung'});

      List<String> sichtbar(String tag, double wert) => [
            for (final q
                in QuestionnaireFlow(v1, computed: {'overall_effective': wert})
                    .visibleQuestions(basis.set('a3_tagesform', tag)))
              q.id,
          ];

      expect(sichtbar('sehr_schlecht', 1.2), contains('a3_1_verschieben'));
      expect(sichtbar('sehr_schlecht', 4.8), contains('a3_1_verschieben'));
      // Schlechter Tag, aber gemäßigte Bewertung: kein Angebot.
      expect(
          sichtbar('sehr_schlecht', 3.0), isNot(contains('a3_1_verschieben')));
      // Extreme Bewertung, aber guter Tag: ebenfalls nicht.
      expect(sichtbar('gut', 1.2), isNot(contains('a3_1_verschieben')));
    });
  });
}
