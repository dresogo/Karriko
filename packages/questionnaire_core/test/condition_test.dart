import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

/// Wertet eine Bedingung aus, wie sie in der Definition stünde.
bool evaluate(
  Map<String, Object?> json, {
  Map<String, Object?> answers = const {},
  Map<String, Object?> computed = const {},
}) =>
    Condition.parse(JsonNode.root(json))
        .evaluate(EvalContext(answers: answers, computed: computed));

void main() {
  group('Operanden', () {
    test('{"answer": …} liest aus den Antworten', () {
      expect(
        evaluate({
          'eq': [
            {'answer': 'a'},
            'x',
          ],
        }, answers: {
          'a': 'x'
        }),
        isTrue,
      );
    });

    test('{"computed": …} liest aus den abgeleiteten Werten', () {
      expect(
        evaluate({
          'gt': [
            {'computed': 'detail_overall'},
            3,
          ],
        }, computed: {
          'detail_overall': 4.2
        }),
        isTrue,
      );
    });

    test('Alles andere ist ein Literal', () {
      expect(
        evaluate({
          'eq': ['x', 'x'],
        }),
        isTrue,
      );
    });

    test('{"answer": …, "field": …} greift in eine Wischkarten-Antwort hinein',
        () {
      expect(
        evaluate({
          'eq': [
            {'answer': 's8', 'field': 'schicht'},
            'ja',
          ],
        }, answers: {
          's8': {'schicht': 'ja', 'wochenende': 'nein'},
        }),
        isTrue,
      );
    });

    test('Ein Feld, das es nicht gibt, ist schlicht nichts', () {
      expect(
        evaluate({
          'eq': [
            {'answer': 's8', 'field': 'montage'},
            'ja',
          ],
        }, answers: {
          's8': {'schicht': 'ja'},
        }),
        isFalse,
      );
    });

    test('Ein Feldzugriff auf eine skalare Antwort ist kein Fehler', () {
      expect(
        evaluate({
          'eq': [
            {'answer': 's8', 'field': 'schicht'},
            'ja',
          ],
        }, answers: {
          's8': 'ja'
        }),
        isFalse,
      );
    });

    test('Ein Feldzugriff zählt für die Prüfung als Verweis auf die Frage', () {
      final ids = <String>{};
      Condition.parse(JsonNode.root({
        'eq': [
          {'answer': 's8_alltag', 'field': 'schicht'},
          'ja',
        ],
      })).collectAnswerIds(ids);
      expect(ids, {'s8_alltag'});
    });

    test('Ein Objekt mit unbekanntem Schlüssel fliegt beim Laden auf', () {
      expect(
        () => evaluate({
          'eq': [
            {'antwort': 'a'},
            'x',
          ],
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });
  });

  group('eq / neq', () {
    test('vergleicht Zahlen über int und double hinweg', () {
      expect(
        evaluate({
          'eq': [
            {'answer': 'a'},
            5,
          ],
        }, answers: {
          'a': 5.0
        }),
        isTrue,
      );
    });

    test('vergleicht Listen elementweise, nicht über die Identität', () {
      expect(
        evaluate({
          'eq': [
            {'answer': 'a'},
            ['x', 'y'],
          ],
        }, answers: {
          'a': ['x', 'y'],
        }),
        isTrue,
      );
    });

    test('unterscheidet die Reihenfolge einer Liste', () {
      expect(
        evaluate({
          'eq': [
            {'answer': 'a'},
            ['x', 'y'],
          ],
        }, answers: {
          'a': ['y', 'x'],
        }),
        isFalse,
      );
    });

    test('neq ist die Verneinung von eq', () {
      expect(
        evaluate({
          'neq': [
            {'answer': 'a'},
            'x',
          ],
        }, answers: {
          'a': 'y'
        }),
        isTrue,
      );
    });

    test('eine fehlende Antwort ist ungleich allem außer null', () {
      expect(
        evaluate({
          'eq': [
            {'answer': 'fehlt'},
            'x',
          ],
        }),
        isFalse,
      );
    });
  });

  group('in', () {
    test('trifft, wenn der Wert in der Liste steht', () {
      expect(
        evaluate({
          'in': [
            {'answer': 'a'},
            ['x', 'y'],
          ],
        }, answers: {
          'a': 'y'
        }),
        isTrue,
      );
    });

    test('trifft nicht, wenn er fehlt', () {
      expect(
        evaluate({
          'in': [
            {'answer': 'a'},
            ['x', 'y'],
          ],
        }, answers: {
          'a': 'z'
        }),
        isFalse,
      );
    });
  });

  group('Zahlenvergleiche', () {
    const answers = {'n': 15};

    test('gt, gte, lt, lte', () {
      expect(
          evaluate({
            'gt': [
              {'answer': 'n'},
              10,
            ],
          }, answers: answers),
          isTrue);
      expect(
          evaluate({
            'gte': [
              {'answer': 'n'},
              15,
            ],
          }, answers: answers),
          isTrue);
      expect(
          evaluate({
            'lt': [
              {'answer': 'n'},
              15,
            ],
          }, answers: answers),
          isFalse);
      expect(
          evaluate({
            'lte': [
              {'answer': 'n'},
              15,
            ],
          }, answers: answers),
          isTrue);
    });

    test('Ein Sonderwert ist keine Zahl und hält den Bogen trotzdem nicht an',
        () {
      // K3 kann „weiß ich nicht genau" sein. Die Folgefrage K3.1 hängt an
      // `gt > 0`; sie soll dann schlicht nicht erscheinen — und nicht das
      // Formular mit einem Fehler abbrechen.
      expect(
        evaluate({
          'gt': [
            {'answer': 'k3'},
            0,
          ],
        }, answers: {
          'k3': 'weiss_nicht'
        }),
        isFalse,
      );
    });

    test('Eine fehlende Antwort ebenso wenig', () {
      expect(
        evaluate({
          'gt': [
            {'answer': 'k3'},
            0,
          ],
        }),
        isFalse,
      );
    });
  });

  group('answered', () {
    test('null, leerer Text und leere Liste zählen nicht', () {
      for (final value in [null, '', '   ', <Object?>[], <String, Object?>{}]) {
        expect(
          evaluate({
            'answered': {'answer': 'a'},
          }, answers: {
            'a': value
          }),
          isFalse,
          reason: 'Wert: $value',
        );
      }
    });

    test('Null zählt', () {
      // Bei K3 ist „null Überstunden" eine Antwort, keine Lücke.
      expect(
        evaluate({
          'answered': {'answer': 'a'},
        }, answers: {
          'a': 0
        }),
        isTrue,
      );
    });

    test('false zählt', () {
      expect(
        evaluate({
          'answered': {'answer': 'a'},
        }, answers: {
          'a': false
        }),
        isTrue,
      );
    });

    test('nimmt auch eine einelementige Liste als Operanden', () {
      expect(
        evaluate({
          'answered': [
            {'answer': 'a'},
          ],
        }, answers: {
          'a': 'x'
        }),
        isTrue,
      );
    });
  });

  group('selected', () {
    test('trifft, wenn die Mehrfachauswahl den Wert enthält', () {
      expect(
        evaluate({
          'selected': [
            {'answer': 'a'},
            'betrieb',
          ],
        }, answers: {
          'a': ['beruf', 'betrieb'],
        }),
        isTrue,
      );
    });

    test('trifft nicht bei einer skalaren Antwort', () {
      expect(
        evaluate({
          'selected': [
            {'answer': 'a'},
            'betrieb',
          ],
        }, answers: {
          'a': 'betrieb'
        }),
        isFalse,
      );
    });
  });

  group('ranked_top', () {
    const ranking = {
      'k12': ['ausbilder', 'geld', 'umgang', 'team'],
    };

    test('trifft innerhalb der ersten N', () {
      expect(
        evaluate({
          'ranked_top': [
            {'answer': 'k12'},
            'umgang',
            3,
          ],
        }, answers: ranking),
        isTrue,
      );
    });

    test('trifft nicht auf Platz vier bei N = 3', () {
      expect(
        evaluate({
          'ranked_top': [
            {'answer': 'k12'},
            'team',
            3,
          ],
        }, answers: ranking),
        isFalse,
      );
    });

    test('trifft nicht ohne Rangliste', () {
      expect(
        evaluate({
          'ranked_top': [
            {'answer': 'k12'},
            'umgang',
            3,
          ],
        }),
        isFalse,
      );
    });

    test('braucht drei Operanden', () {
      expect(
        () => evaluate({
          'ranked_top': [
            {'answer': 'k12'},
            'umgang',
          ],
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });
  });

  group('all / any / not', () {
    test('all verlangt jede Teilbedingung', () {
      expect(
        evaluate({
          'all': [
            {
              'eq': [
                {'answer': 'a'},
                'x',
              ],
            },
            {
              'eq': [
                {'answer': 'b'},
                'y',
              ],
            },
          ],
        }, answers: {
          'a': 'x',
          'b': 'z'
        }),
        isFalse,
      );
    });

    test('any reicht eine', () {
      expect(
        evaluate({
          'any': [
            {
              'eq': [
                {'answer': 'a'},
                'x',
              ],
            },
            {
              'eq': [
                {'answer': 'b'},
                'y',
              ],
            },
          ],
        }, answers: {
          'a': 'x',
          'b': 'z'
        }),
        isTrue,
      );
    });

    test('not dreht um', () {
      expect(
        evaluate({
          'not': {
            'eq': [
              {'answer': 'a'},
              'x',
            ],
          },
        }, answers: {
          'a': 'y'
        }),
        isTrue,
      );
    });

    test('all ohne Teilbedingung ist ein Fehler, kein stilles Wahr', () {
      expect(
        () => evaluate({'all': <Object?>[]}),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });
  });

  group('Fehler beim Laden, nicht zur Laufzeit', () {
    test(
        'Ein unbekannter Operator fliegt beim Parsen auf und zählt die '
        'bekannten auf', () {
      expect(
        () => evaluate({
          'groesser': [
            {'answer': 'a'},
            1,
          ],
        }),
        throwsA(
          isA<QuestionnaireFormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('groesser'), contains('ranked_top')),
          ),
        ),
      );
    });

    test('Zwei Operatoren in einem Objekt sind ein Fehler', () {
      expect(
        () => evaluate({
          'eq': ['a', 'a'],
          'neq': ['a', 'b'],
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });

    test('Die falsche Zahl Operanden ist ein Fehler', () {
      expect(
        () => evaluate({
          'eq': ['a'],
        }),
        throwsA(isA<QuestionnaireFormatException>()),
      );
    });

    test('Der Fehler nennt den Pfad', () {
      try {
        Condition.parse(JsonNode(
          {
            'all': [
              {'unbekannt': 1},
            ],
          },
          r'$.questions[7].condition',
        ));
        fail('Sollte werfen.');
      } on QuestionnaireFormatException catch (e) {
        expect(e.path, r'$.questions[7].condition.all[0]');
      }
    });
  });

  group('collectAnswerIds', () {
    test('sammelt alle referenzierten Fragen, auch verschachtelt', () {
      final condition = Condition.parse(JsonNode.root({
        'all': [
          {
            'eq': [
              {'answer': 's1'},
              'x',
            ],
          },
          {
            'not': {
              'ranked_top': [
                {'answer': 'k12'},
                'geld',
                3,
              ],
            },
          },
        ],
      }));
      final ids = <String>{};
      condition.collectAnswerIds(ids);
      expect(ids, {'s1', 'k12'});
    });
  });
}
