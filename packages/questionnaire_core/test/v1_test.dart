import 'dart:io';

import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

/// Die echte Fragendefinition, so wie sie ausgeliefert wird.
///
/// Der Pfad zeigt in die Flutter-App, nicht in dieses Paket: Dort liegt das
/// Original, und die Kopie unter `appwrite/questionnaires/` wird daraus
/// erzeugt. Zwei Originale wären zwei Wahrheiten.
final _v1Pfad =
    File('../../karriko_flutter/assets/questionnaire/questionnaire_v1.json');
final _kopiePfad = File('../../appwrite/questionnaires/questionnaire_v1.json');

void main() {
  late Questionnaire v1;

  setUpAll(() {
    expect(_v1Pfad.existsSync(), isTrue,
        reason: 'Nicht gefunden: ${_v1Pfad.path}');
    v1 = Questionnaire.parseJsonString(_v1Pfad.readAsStringSync());
  });

  group('Laden', () {
    test('v1 lädt und ist in sich schlüssig', () {
      expect(v1.id, 'karriko_ausbildung');
      expect(v1.version, 1);
      expect(v1.locale, 'de-DE');
    });

    test('Die Kopie für den Storage ist Zeichen für Zeichen dieselbe Datei',
        () {
      expect(_kopiePfad.existsSync(), isTrue,
          reason: 'Nicht gefunden: ${_kopiePfad.path}');
      expect(
        _kopiePfad.readAsStringSync().replaceAll('\r\n', '\n'),
        _v1Pfad.readAsStringSync().replaceAll('\r\n', '\n'),
        reason: 'Die Kopie unter appwrite/questionnaires/ weicht ab. Sie wird '
            'mit `dart run tools/sync_questionnaire.dart` neu erzeugt.',
      );
    });
  });

  group('Vollständigkeit gegen die Spezifikation', () {
    test('Alle zehn Steuerfragen sind da', () {
      for (var i = 1; i <= 10; i++) {
        expect(
          v1.questions.any((q) => q.specRef == 'S$i'),
          isTrue,
          reason: 'S$i fehlt.',
        );
      }
    });

    test('Alle zwölf Kernfragen sind da', () {
      for (var i = 1; i <= 12; i++) {
        expect(
          v1.questions.any((q) => q.specRef == 'K$i'),
          isTrue,
          reason: 'K$i fehlt.',
        );
      }
      expect(v1.question('k3_1_ausgleich'), isNotNull);
    });

    test('Alle fünf Abschlussschritte sind da', () {
      for (final ref in ['A1', 'A2', 'A3', 'A4', 'A5']) {
        expect(
          v1.questions.any((q) => q.specRef == ref),
          isTrue,
          reason: '$ref fehlt.',
        );
      }
    });

    test('Alle elf Module aus Abschnitt 5 sind da, plus Geld', () {
      expect(
        [for (final module in v1.modules) module.id],
        containsAll([
          'ausbilder',
          'fachliche_qualitaet',
          'geld',
          'arbeitszeit',
          'pruefung',
          'uebernahme',
          'jugendarbeitsschutz',
          'gesundheit',
          'berufsschule',
          'konflikte',
          'abbruch',
        ]),
      );
    });

    test('K1 hat sechs Karten, K12 acht Optionen, S8 sieben Karten', () {
      final k1 = v1.question('k1_fakten')!;
      expect((k1.config['cards']! as List).length, 6);
      expect(v1.question('k12_prioritaeten')!.options, hasLength(8));
      expect(
        (v1.question('s8_arbeitsalltag')!.config['cards']! as List).length,
        7,
      );
    });

    test('Die sechs Subscores und die getrennte Berufsschule stehen', () {
      expect(v1.scoring.dimensions, [
        'fachlich',
        'betreuung',
        'umgang',
        'belastung',
        'verguetung',
        'perspektive',
      ]);
      expect(v1.scoring.separate, ['berufsschule']);
    });

    test('Die Sichtbarkeitsschwellen stehen wie in Abschnitt 8', () {
      expect(v1.visibility.scoreMinReviews, 3);
      expect(v1.visibility.numbersMinReviews, 5);
      expect(v1.scoring.agingYears, 3);
    });

    test('Die Merkmalsschalter stehen wie verlangt', () {
      expect(v1.flagEnabled('module_verguetung'), isFalse);
      expect(v1.flagEnabled('delayed_publish_small_business'), isTrue);
    });
  });

  group('Formatwahl nach Abschnitt 7', () {
    test('Es gibt genau zwei Regler im ganzen Bogen: K6 und der aus A2', () {
      final regler = [
        for (final q in v1.questions)
          if (q.type == 'vas_unnumbered') q.id,
      ];
      expect(regler, ['k6_gesamt', 'a2_1_korrektur']);
    });

    test('Wischkarten nur bei S8, K1 und im Jugendarbeitsschutz', () {
      final wisch = [
        for (final q in v1.questions)
          if (q.type == 'swipe_binary') q.id,
      ];
      expect(wisch, ['s8_arbeitsalltag', 'k1_fakten', 'mod_jas_fakten']);
    });

    test('Elf Kacheln nur bei K5', () {
      final kacheln = [
        for (final q in v1.questions)
          if (q.type == 'scale_0_10') q.id,
      ];
      expect(kacheln, ['k5_empfehlung']);
    });

    test('Drag and Drop nur bei K12', () {
      final ranking = [
        for (final q in v1.questions)
          if (q.type == 'rank_top_n') q.id,
      ];
      expect(ranking, ['k12_prioritaeten']);
    });

    test('Keine zwei Wischkartenblöcke hintereinander', () {
      // „Abwechslung gegen Durchklicken": gleichförmige Blöcke laden zum
      // Straightlining ein.
      final flow = QuestionnaireFlow(v1);
      final sichtbar = flow.visibleQuestions(const Answers.empty());
      for (var i = 1; i < sichtbar.length; i++) {
        expect(
          sichtbar[i - 1].type == 'swipe_binary' &&
              sichtbar[i].type == 'swipe_binary',
          isFalse,
          reason: '${sichtbar[i - 1].id} und ${sichtbar[i].id} stehen '
              'hintereinander.',
        );
      }
    });
  });

  group('Texte', () {
    test('Jede Frage hat eine Vergangenheitsform', () {
      final ohne = [
        for (final q in v1.questions)
          if (!q.text.hasPast) q.id,
      ];
      expect(ohne, isEmpty, reason: 'Ohne past-Variante: ${ohne.join(', ')}');
    });

    test('Jede Option hat eine Vergangenheitsform', () {
      final ohne = <String>[];
      for (final q in v1.questions) {
        for (final option in q.options) {
          if (!option.label.hasPast) ohne.add('${q.id}.${option.id}');
        }
      }
      expect(ohne, isEmpty, reason: 'Ohne past-Variante: ${ohne.join(', ')}');
    });

    test('Jede Einleitung und jeder Platzhalter ebenso', () {
      final ohne = <String>[];
      for (final q in v1.questions) {
        if (q.intro != null && !q.intro!.hasPast) ohne.add('${q.id}.intro');
        if (q.placeholder != null && !q.placeholder!.hasPast) {
          ohne.add('${q.id}.placeholder');
        }
      }
      expect(ohne, isEmpty, reason: 'Ohne past-Variante: ${ohne.join(', ')}');
    });

    test('Der rechtlich entscheidende Satz steht wörtlich in der Definition',
        () {
      expect(
        v1.text('legal.freitext')!.current,
        'Deine Meinung darfst du frei sagen. Falsche Tatsachenbehauptungen '
        'und Beleidigungen müssen wir löschen.',
      );
    });

    test('Der Platzhalter von A1 steht wörtlich in der Definition', () {
      expect(
        v1.question('a1_freitexte')!.placeholder!.current,
        'Schreib, wie du es erlebt hast. Keine Namen von Kollegen, keine '
        'Behauptungen, die du nicht belegen kannst.',
      );
    });

    test('Rechtliche Aussagen sind Platzhalter, keine Erfindungen', () {
      for (final key in [
        'anonymity.intro',
        'anonymity.sensitive',
        'legal.verifikation',
      ]) {
        expect(
          v1.text(key)!.current,
          startsWith('PLATZHALTER'),
          reason: '$key sollte ein markierter Platzhalter sein.',
        );
      }
    });

    test('Die Anlaufstellen stehen unabhängig von jeder Antwort bereit', () {
      expect(v1.textList('help.anlaufstellen'), hasLength(3));
    });
  });

  group('Sensible Stellen', () {
    test('Das Konfliktmodul steht hinter einem Tor mit eigenen Beschriftungen',
        () {
      final modul = v1.module('konflikte')!;
      expect(modul.gated, isTrue);
      expect(modul.acceptLabel!.current, 'Zeig mir das');
      expect(modul.skipLabel!.current, 'Nein danke');
    });

    test('Die Konfliktfragen sind als sensibel gekennzeichnet', () {
      for (final id in v1.module('konflikte')!.questionIds) {
        final question = v1.question(id)!;
        if (question.type == 'intro') continue;
        expect(question.sensitive, isTrue, reason: '$id ist nicht sensitive.');
      }
    });

    test(
        'Das Konfliktmodul endet mit den Anlaufstellen, unabhängig von den '
        'Antworten', () {
      final letzte = v1.module('konflikte')!.questionIds.last;
      expect(letzte, 'mod_konflikt_anlaufstellen');
      expect(v1.question(letzte)!.condition, isNull);
    });

    test('Keine Antwort aus dem Konfliktmodul wird veröffentlicht', () {
      for (final id in v1.module('konflikte')!.questionIds) {
        expect(v1.question(id)!.public, isFalse, reason: id);
      }
    });

    test('Keine Antwort aus dem Konfliktmodul fließt in einen Score', () {
      final imScoring = <String>{
        for (final items in v1.scoring.items.values)
          for (final item in items) item.questionId,
      };
      for (final id in v1.module('konflikte')!.questionIds) {
        expect(imScoring, isNot(contains(id)), reason: id);
      }
    });

    test('Die Tagesform bleibt intern', () {
      expect(v1.question('a3_tagesform')!.public, isFalse);
      final imScoring = <String>{
        for (final items in v1.scoring.items.values)
          for (final item in items) item.questionId,
      };
      expect(imScoring, isNot(contains('a3_tagesform')));
    });
  });

  group('Qualitätsfilter', () {
    test('Der Straightlining-Index läuft über K7 bis K11', () {
      expect(v1.quality.straightliningQuestions, [
        'k7_anleitung',
        'k8_lernwert',
        'k9_umgang',
        'k10_belastung',
        'k11_planung',
      ]);
    });

    test('Genau eine dieser Fragen ist umgekehrt gepolt', () {
      final umgekehrt = [
        for (final id in v1.quality.straightliningQuestions)
          if (v1.question(id)!.reversePolarity) id,
      ];
      expect(umgekehrt, ['k10_belastung']);
    });

    test(
        'K10 ist so sortiert, dass dieselbe Position dort das Gegenteil '
        'bedeutet', () {
      // Ohne das findet der Index nichts: Wer überall die erste Option
      // antippt, sagte sonst fünfmal dasselbe.
      final k10 = v1.question('k10_belastung')!;
      final k7 = v1.question('k7_anleitung')!;
      expect(k10.options.first.score, 0.0);
      expect(k7.options.first.score, 1.0);
      expect(k10.options.last.score, 1.0);
    });

    test('Das Konsistenzpaar verbindet K4 mit der Ausbilderfrage', () {
      final paar = v1.quality.pairs.single;
      expect(paar.questionA, 'k4_erreichbarkeit');
      expect(paar.questionB, 'mod_ausbilder_erreichbar');
    });

    test('Beide Seiten des Paares haben dieselbe Skala', () {
      // Sonst ist der Abstand zwischen ihnen keine Aussage.
      final a = v1.question('k4_erreichbarkeit')!;
      final b = v1.question('mod_ausbilder_erreichbar')!;
      expect(
        [for (final o in a.options) o.score],
        [for (final o in b.options) o.score],
      );
    });

    test('Die Schwelle in A2 ist dieselbe wie die des Flags', () {
      // Wenn der Azubi die Rückfrage sieht, muss die Bewertung auch markiert
      // werden — und umgekehrt. Zwei Zahlen dafür wären zwei Wahrheiten.
      final bedingung = v1.question('a2_abgleich')!.condition!;
      expect(
        bedingung.evaluate(EvalContext(
          answers: const {},
          computed: {
            'overall_delta': v1.quality.overallMismatchMaxDelta + 0.01
          },
        )),
        isTrue,
      );
      expect(
        bedingung.evaluate(EvalContext(
          answers: const {},
          computed: {'overall_delta': v1.quality.overallMismatchMaxDelta},
        )),
        isFalse,
      );
    });

    test('Beide Freitexte gehen in die Moderation', () {
      expect(v1.quality.freeTextQuestions, ['a1_freitexte', 'mod_abbruch_gut']);
    });
  });

  test('Der Kleinbetriebshinweis hängt am Merkmalsschalter', () {
    final frage = v1.question('a3_2_kleinbetrieb')!;
    expect(frage.featureFlag, 'delayed_publish_small_business');

    final flow = QuestionnaireFlow(v1);
    final antworten = Answers.from({
      's1_status': 'in_ausbildung',
      's6_azubizahl': 'nur_ich',
    });
    expect(
      [for (final q in flow.visibleQuestions(antworten)) q.id],
      contains('a3_2_kleinbetrieb'),
    );
  });

  test('Jeder Scoring-Beitrag hat auch Punktwerte zu holen', () {
    // Ein Beitrag auf eine Frage ohne einen einzigen Punktwert wäre stumm:
    // Der Subscore käme nie zustande, und niemand sähe warum.
    for (final entry in v1.scoring.items.entries) {
      for (final item in entry.value) {
        final question = v1.question(item.questionId)!;
        final hatWerte = question.options.any((o) => o.score != null) ||
            question.config.containsKey('scoreBands') ||
            question.config.containsKey('scoreMin') ||
            question.config.containsKey('cards');
        expect(hatWerte, isTrue,
            reason: '${entry.key} → ${item.questionId} hat keine Punktwerte.');
      }
    }
  });
}
