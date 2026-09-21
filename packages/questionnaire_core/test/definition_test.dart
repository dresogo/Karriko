import 'dart:convert';

import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// Lädt den Testfragebogen mit einer gezielten Änderung.
///
/// Der springende Punkt dieser ganzen Gruppe: Jeder dieser Fehler soll **beim
/// Laden** auffliegen. Ein verschriebener Antwortverweis liefert sonst still
/// `null`, die Bedingung ist dann einfach falsch, die Folgefrage erscheint nie
/// — und niemand erfährt davon.
Questionnaire load(void Function(Map<String, Object?> json) change) {
  final json = fixtureJson();
  change(json);
  return Questionnaire.parse(json);
}

List<Object?> questionsOf(Map<String, Object?> json) =>
    json['questions']! as List<Object?>;

Map<String, Object?> questionOf(Map<String, Object?> json, String id) =>
    questionsOf(json).cast<Map<String, Object?>>().firstWhere(
          (question) => question['id'] == id,
        );

void main() {
  group('Der Testfragebogen selbst', () {
    test('lädt', () {
      final questionnaire = fixtureQuestionnaire();
      expect(questionnaire.version, 1);
      expect(questionnaire.locale, 'de-DE');
      expect(questionnaire.modulePhase.id, 'modules');
    });

    test('lädt auch aus einer Zeichenkette', () {
      final questionnaire =
          Questionnaire.parseJsonString(jsonEncode(fixtureJson()));
      expect(questionnaire.id, 'fixture');
    });

    test('kennt seine Fragen und Module über die Kennung', () {
      final questionnaire = fixtureQuestionnaire();
      expect(questionnaire.question('k6_gesamt')?.specRef, 'K6');
      expect(questionnaire.question('gibt_es_nicht'), isNull);
      expect(questionnaire.module('konflikte')?.gated, isTrue);
    });

    test('liefert Texte und Textlisten aus der Definition', () {
      final questionnaire = fixtureQuestionnaire();
      expect(questionnaire.text('anonymity.intro'), isNotNull);
      expect(questionnaire.text('gibt.es.nicht'), isNull);
      expect(questionnaire.textList('help.anlaufstellen'), hasLength(3));
      expect(questionnaire.textList('gibt.es.nicht'), isEmpty);
    });
  });

  group('Verweise', () {
    test('Ein Antwortverweis auf eine unbekannte Frage fliegt auf', () {
      expect(
        () => load((json) {
          questionOf(json, 'k3_1_ausgleich')['condition'] = {
            'gt': [
              {'answer': 'k3_uberstunden'},
              0,
            ],
          };
        }),
        throwsA(
          isA<QuestionnaireFormatException>().having(
            (e) => e.message,
            'message',
            contains('k3_uberstunden'),
          ),
        ),
      );
    });

    test('Auch im Auslöser eines Moduls', () {
      expect(
        () => load((json) {
          (json['modules']! as List<Object?>).cast<Map<String, Object?>>()[0]
              ['trigger'] = {
            'eq': [
              {'answer': 'gibt_es_nicht'},
              'x',
            ],
          };
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });

    test('Auch in einer unmöglichen Kombination', () {
      expect(
        () => load((json) {
          ((json['quality']! as Map<String, Object?>)['impossible']!
                  as List<Object?>)
              .cast<Map<String, Object?>>()[0]['condition'] = {
            'eq': [
              {'answer': 'gibt_es_nicht'},
              1,
            ],
          };
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });

    test('Ein Modul, das auf eine unbekannte Frage zeigt', () {
      expect(
        () => load((json) {
          (json['modules']! as List<Object?>).cast<Map<String, Object?>>()[0]
              ['questions'] = ['gibt_es_nicht'];
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });

    test('Eine Modulfrage, die ihr Modul nicht kennt', () {
      expect(
        () => load((json) {
          questionOf(json, 'm_ausbilder_erreichbar')['module'] = 'berufsschule';
        }),
        throwsA(
          isA<QuestionnaireFormatException>().having(
            (e) => e.message,
            'message',
            contains('m_ausbilder_erreichbar'),
          ),
        ),
      );
    });

    test('Eine unbekannte Phase', () {
      expect(
        () => load((json) =>
            questionOf(json, 'k4_erreichbarkeit')['phase'] = 'zwischendurch'),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });

    test('Ein Subscore, der auf eine unbekannte Frage zeigt', () {
      expect(
        () => load((json) {
          ((json['scoring']! as Map<String, Object?>)['subscores']!
              as Map<String, Object?>)['umgang'] = {
            'items': [
              {'question': 'k9_umgamg'},
            ],
          };
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });

    test('Eine Dimension ohne Gewicht', () {
      expect(
        () => load((json) {
          ((json['scoring']! as Map<String, Object?>)['defaultWeights']!
                  as Map<String, Object?>)
              .remove('umgang');
        }),
        throwsA(
          isA<QuestionnaireFormatException>().having(
            (e) => e.message,
            'message',
            contains('Standardgewicht'),
          ),
        ),
      );
    });

    test('Ein Konsistenzpaar auf eine unbekannte Frage', () {
      expect(
        () => load((json) {
          ((json['quality']! as Map<String, Object?>)['pairs']!
                  as List<Object?>)
              .cast<Map<String, Object?>>()[0]['b'] = 'gibt_es_nicht';
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });
  });

  group('Eindeutigkeit und Struktur', () {
    test('Zwei Fragen mit derselben Kennung', () {
      expect(
        () => load((json) {
          questionsOf(json).add({
            ...questionOf(json, 'k6_gesamt'),
          });
        }),
        throwsA(
          isA<QuestionnaireFormatException>().having(
            (e) => e.message,
            'message',
            contains('k6_gesamt'),
          ),
        ),
      );
    });

    test('Zwei Optionen mit derselben Kennung', () {
      expect(
        () => load((json) {
          final options =
              questionOf(json, 'k9_umgang')['options']! as List<Object?>;
          options.add({
            'id': 'sachlich',
            'label': {'current': 'nochmal sachlich'},
          });
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });

    test('Eine Frage-ID, die einem Modulteaser in die Quere kommt', () {
      expect(
        () => load((json) {
          questionsOf(json).add({
            'id': 'berufsschule__teaser',
            'type': 'intro',
            'phase': 'core',
            'text': {'current': 'x'},
          });
        }),
        throwsA(
          isA<QuestionnaireFormatException>().having(
            (e) => e.message,
            'message',
            contains('reserviert'),
          ),
        ),
      );
    });

    test('Keine Modulphase', () {
      expect(
        () => load((json) {
          for (final phase in (json['phases']! as List<Object?>)
              .cast<Map<String, Object?>>()) {
            phase.remove('holdsModules');
          }
        }),
        throwsA(
          isA<QuestionnaireFormatException>().having(
            (e) => e.message,
            'message',
            contains('holdsModules'),
          ),
        ),
      );
    });

    test('Zwei Modulphasen', () {
      expect(
        () => load((json) {
          (json['phases']! as List<Object?>).cast<Map<String, Object?>>()[1]
              ['holdsModules'] = true;
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });
  });

  group('Werte', () {
    test('Ein Punktwert außerhalb von 0 bis 1', () {
      expect(
        () => load((json) {
          (questionOf(json, 'k9_umgang')['options']! as List<Object?>)
              .cast<Map<String, Object?>>()[0]['score'] = 5;
        }),
        throwsA(
          isA<QuestionnaireFormatException>().having(
            (e) => e.message,
            'message',
            contains('0,0 und 1,0'),
          ),
        ),
      );
    });

    test('Ein fehlendes Pflichtfeld nennt den Pfad', () {
      try {
        load((json) => questionOf(json, 'k9_umgang').remove('type'));
        fail('Sollte werfen.');
      } on QuestionnaireFormatException catch (e) {
        expect(e.message, contains('type'));
        expect(e.path, startsWith(r'$.questions['));
      }
    });

    test('Ein Text ohne "current"', () {
      expect(
        () => load((json) {
          questionOf(json, 'k9_umgang')['text'] = {'past': 'nur Vergangenheit'};
        }),
        throwsA(
          isA<QuestionnaireFormatException>().having(
            (e) => e.message,
            'message',
            contains('current'),
          ),
        ),
      );
    });

    test('Ein Text darf auch eine nackte Zeichenkette sein', () {
      final questionnaire = load((json) {
        questionOf(json, 'k9_umgang')['text'] = 'Nur Präsens';
      });
      final question = questionnaire.question('k9_umgang')!;
      expect(question.text.forTense(Tense.current), 'Nur Präsens');
      expect(question.text.forTense(Tense.past), 'Nur Präsens');
      expect(question.text.hasPast, isFalse);
    });
  });

  group('Durchsicht', () {
    test('reviewFlagged sammelt, was ich ergänzt habe', () {
      final questionnaire = load((json) {
        questionOf(json, 'k9_umgang')['review'] = true;
        (questionOf(json, 'k7_anleitung')['options']! as List<Object?>)
            .cast<Map<String, Object?>>()[2]['review'] = true;
      });
      expect(
        questionnaire.reviewFlagged,
        containsAll(['k9_umgang', 'k7_anleitung.mittel']),
      );
    });

    test('Der Testfragebogen selbst hat nichts Offenes', () {
      expect(fixtureQuestionnaire().reviewFlagged, isEmpty);
    });
  });
}
