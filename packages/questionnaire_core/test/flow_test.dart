import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

List<String> visibleIds(QuestionnaireFlow flow, Answers answers) =>
    [for (final question in flow.visibleQuestions(answers)) question.id];

void main() {
  final questionnaire = fixtureQuestionnaire();
  final flow = QuestionnaireFlow(questionnaire);

  /// Ein Stand, der die Steuerfragen und den Kern beantwortet hat.
  Answers kernFertig({
    String status = 'in_ausbildung',
    String? lehrjahr = '1',
    Object ueberstunden = 0,
    String erreichbarkeit = 'meistens',
    String umgang = 'freundlich',
    String minderjaehrig = 'nein',
    List<String> prioritaeten = const ['fachlich', 'umgang', 'arbeitszeit'],
  }) =>
      Answers.from({
        's1_status': status,
        if (lehrjahr != null && status == 'in_ausbildung')
          's4_lehrjahr': lehrjahr,
        's6_azubis': '6_20',
        's9_minderjaehrig': minderjaehrig,
        'k3_ueberstunden': ueberstunden,
        if (ueberstunden is num && ueberstunden > 0)
          'k3_1_ausgleich': 'ausgezahlt',
        'k4_erreichbarkeit': erreichbarkeit,
        'k5_empfehlung': 8,
        'k6_gesamt': 72,
        'k7_anleitung': 'gut',
        'k8_lernwert': 'gut',
        'k9_umgang': umgang,
        'k10_belastung': 'selten',
        'k11_planung': 'mittel',
        'k12_prioritaeten': prioritaeten,
      });

  group('Zeitform', () {
    test('folgt aus S1', () {
      expect(flow.tense(const Answers.empty()), Tense.current);
      expect(
        flow.tense(Answers.from({'s1_status': 'in_ausbildung'})),
        Tense.current,
      );
      for (final status in [
        'ausgelernt_geblieben',
        'ausgelernt_gegangen',
        'abgebrochen',
      ]) {
        expect(
          flow.tense(Answers.from({'s1_status': status})),
          Tense.past,
          reason: status,
        );
      }
    });

    test('steht auch in den abgeleiteten Werten für Bedingungen bereit', () {
      final context = flow.context(Answers.from({'s1_status': 'abgebrochen'}));
      expect(context.computed['tense'], 'past');
    });
  });

  group('Bedingte Fragen', () {
    test('S4 erscheint nur für aktuelle Azubis', () {
      expect(
        visibleIds(flow, Answers.from({'s1_status': 'in_ausbildung'})),
        contains('s4_lehrjahr'),
      );
      expect(
        visibleIds(flow, Answers.from({'s1_status': 'abgebrochen'})),
        isNot(contains('s4_lehrjahr')),
      );
    });

    test('K3.1 erscheint erst bei mehr als null Überstunden', () {
      expect(
        visibleIds(flow, Answers.from({'k3_ueberstunden': 0})),
        isNot(contains('k3_1_ausgleich')),
      );
      expect(
        visibleIds(flow, Answers.from({'k3_ueberstunden': 5})),
        contains('k3_1_ausgleich'),
      );
    });

    test('K3.1 erscheint nicht bei „weiß ich nicht genau"', () {
      expect(
        visibleIds(flow, Answers.from({'k3_ueberstunden': 'weiss_nicht'})),
        isNot(contains('k3_1_ausgleich')),
      );
    });
  });

  group('Module', () {
    List<String> offered(Answers answers) =>
        [for (final module in flow.offeredModules(answers)) module.id];

    test('Ein Modul ohne Auslöser und ohne Prioritätsschlüssel ist immer dabei',
        () {
      expect(offered(const Answers.empty()), contains('berufsschule'));
    });

    test('K12 bietet die ersten drei an, nicht die vierte', () {
      final answers = kernFertig(
        prioritaeten: const ['ausbilder', 'uebernahme', 'fachlich'],
      );
      expect(offered(answers), containsAll(['ausbilder', 'uebernahme']));

      final vierter = kernFertig(
        prioritaeten: const ['fachlich', 'umgang', 'team', 'ausbilder'],
      );
      // „ausbilder" steht auf Platz vier und wird über K12 nicht angeboten.
      // Der Auslöser greift hier ebenfalls nicht, weil K4 „meistens" ist.
      expect(offered(vierter), isNot(contains('ausbilder')));
    });

    test('Ein Auslöser bietet auch ohne K12 an', () {
      final answers = kernFertig(
        erreichbarkeit: 'selten',
        prioritaeten: const ['fachlich', 'umgang', 'team'],
      );
      expect(offered(answers), contains('ausbilder'));
    });

    test('Das Vergütungsmodul bleibt aus, solange sein Schalter aus ist', () {
      final answers =
          kernFertig(prioritaeten: const ['geld', 'fachlich', 'umgang']);
      expect(offered(answers), isNot(contains('geld')));

      final mitFlag = QuestionnaireFlow(
        fixtureQuestionnaire(flags: const {'module_verguetung': true}),
      );
      expect(
        [for (final module in mitFlag.offeredModules(answers)) module.id],
        contains('geld'),
      );
    });

    test('Das Abbruchmodul hängt allein an S1', () {
      expect(offered(kernFertig()), isNot(contains('abbruch')));
      expect(
        offered(kernFertig(status: 'abgebrochen')),
        contains('abbruch'),
      );
    });

    test('Jugendarbeitsschutz hängt allein an S9', () {
      expect(
        offered(kernFertig(minderjaehrig: 'ja')),
        contains('jugendarbeitsschutz'),
      );
    });

    test('Modulfragen erscheinen erst nach Zustimmung im Teaser', () {
      final answers = kernFertig(erreichbarkeit: 'selten');
      final ids = visibleIds(flow, answers);
      expect(ids, contains('ausbilder__teaser'));
      expect(ids, isNot(contains('m_ausbilder_gespraeche')));

      final zugestimmt = answers.set('ausbilder__teaser', 'ja');
      expect(
        visibleIds(flow, zugestimmt),
        containsAll(['m_ausbilder_gespraeche', 'm_ausbilder_erreichbar']),
      );
    });

    test('Ein abgelehntes Modul bleibt zu, die übrigen laufen weiter', () {
      final answers = kernFertig(erreichbarkeit: 'selten')
          .set('ausbilder__teaser', 'nein')
          .set('berufsschule__teaser', 'ja');
      final ids = visibleIds(flow, answers);
      expect(ids, isNot(contains('m_ausbilder_gespraeche')));
      expect(ids, contains('m_schule_interesse'));
    });

    test('Das Konfliktmodul ist als Tor gekennzeichnet', () {
      final answers = kernFertig(umgang: 'respektlos');
      expect(
        [for (final module in flow.offeredModules(answers)) module.id],
        contains('konflikte'),
      );
      expect(questionnaire.module('konflikte')!.gated, isTrue);
      final teaser = flow
          .visibleQuestions(answers)
          .firstWhere((q) => q.id == 'konflikte__teaser');
      expect(teaser.config['gated'], isTrue);
    });
  });

  group('Teaser', () {
    test('nennt Fragenzahl und Dauer aus der Definition', () {
      final answers = kernFertig(erreichbarkeit: 'selten');
      final teaser =
          flow.teaserFor(questionnaire.module('ausbilder')!, answers);
      expect(teaser.questionCount, 2);
      expect(teaser.estimatedSeconds, 40);
    });

    test('schätzt über die Fragenzahl, wenn das Modul nichts vorgibt', () {
      final teaser = flow.teaserFor(
        questionnaire.module('berufsschule')!,
        const Answers.empty(),
      );
      expect(teaser.questionCount, 1);
      expect(teaser.estimatedSeconds, 10);
    });

    test('liefert einen Teaser je angebotenem Modul', () {
      final answers = kernFertig(minderjaehrig: 'ja');
      final teasers = flow.teasers(answers);
      expect(
        [for (final teaser in teasers) teaser.module.id],
        [for (final module in flow.offeredModules(answers)) module.id],
      );
    });
  });

  group('Navigation', () {
    test('nextUnanswered geht der Reihe nach', () {
      expect(flow.nextUnanswered(const Answers.empty())!.id, 's1_status');
      expect(
        flow.nextUnanswered(Answers.from({'s1_status': 'in_ausbildung'}))!.id,
        's4_lehrjahr',
      );
    });

    test('after und before sind zueinander umgekehrt', () {
      final answers = kernFertig();
      final next = flow.after(answers, 'k5_empfehlung')!;
      expect(next.id, 'k6_gesamt');
      expect(flow.before(answers, next.id)!.id, 'k5_empfehlung');
    });

    test('after gibt am Ende nichts zurück', () {
      final answers = kernFertig();
      final letzte = flow.visibleQuestions(answers).last;
      expect(flow.after(answers, letzte.id), isNull);
    });

    test('Ein bewusst leer gelassener Bildschirm gilt als erledigt', () {
      // K7 ist keine Pflichtfrage. Wer sie ohne Antwort verlässt, soll nicht
      // beim nächsten Schritt wieder dort landen.
      final answers = Answers.from({
        's1_status': 'in_ausbildung',
        's4_lehrjahr': '1',
        's6_azubis': 'nur_ich',
        's7_form': 'dual',
        's8_alltag': {'schicht': 'nein', 'wochenende': 'nein'},
        's9_minderjaehrig': 'nein',
        'k3_ueberstunden': 0,
        'k4_erreichbarkeit': 'immer',
        'k5_empfehlung': 9,
        'k6_gesamt': 80,
        'k7_anleitung': null,
      });
      expect(flow.nextUnanswered(answers)!.id, 'k8_lernwert');
    });
  });

  group('Ungültig gewordene Antworten', () {
    test('Wer S1 ändert, verliert die Antworten, die daran hingen', () {
      final answers = kernFertig().set('s1_status', 'abgebrochen');
      final stale = flow.staleAnswers(answers);
      expect(stale, contains('s4_lehrjahr'));
      expect(flow.pruned(answers).contains('s4_lehrjahr'), isFalse);
    });

    test('Wer die Überstunden auf null setzt, verliert die Folgefrage', () {
      final answers = kernFertig(ueberstunden: 20).set('k3_ueberstunden', 0);
      expect(flow.staleAnswers(answers), contains('k3_1_ausgleich'));
    });

    test('Das Aufräumen greift über mehrere Stufen', () {
      // Das Ausbildermodul wird nur über K4 angeboten. Fällt der Auslöser weg,
      // fällt der Teaser weg — und mit ihm die Antworten der Modulfragen, die
      // nur hinter einem zugestimmten Teaser sichtbar waren.
      final answers = kernFertig(erreichbarkeit: 'selten')
          .set('ausbilder__teaser', 'ja')
          .set('m_ausbilder_gespraeche', 3)
          .set('m_ausbilder_erreichbar', 'selten')
          .set('k4_erreichbarkeit', 'immer')
          .set('k12_prioritaeten', const ['fachlich', 'umgang', 'team']);

      final stale = flow.staleAnswers(answers);
      expect(
        stale,
        containsAll([
          'ausbilder__teaser',
          'm_ausbilder_gespraeche',
          'm_ausbilder_erreichbar',
        ]),
      );

      // Danach ist der Stand in sich stimmig: kein zweiter Durchgang findet
      // noch etwas.
      expect(flow.staleAnswers(flow.pruned(answers)), isEmpty);
    });

    test('Ein stimmiger Stand verliert nichts', () {
      expect(flow.staleAnswers(kernFertig()), isEmpty);
    });
  });

  group('Fortschritt', () {
    test('zählt je Phase, nicht über den ganzen Bogen', () {
      final answers = Answers.from({
        's1_status': 'in_ausbildung',
        's4_lehrjahr': '2',
      });
      final phase0 = flow.progress(answers, 's');
      expect(phase0.total, 6);
      expect(phase0.answered, 2);
      expect(phase0.fraction, closeTo(1 / 3, 1e-9));

      expect(flow.progress(answers, 'core').answered, 0);
    });

    test('liefert für jede Phase einen Eintrag', () {
      expect(
        [for (final p in flow.allProgress(kernFertig())) p.phaseId],
        ['s', 'core', 'modules', 'close'],
      );
    });
  });
}
