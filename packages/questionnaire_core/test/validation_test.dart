import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  final questionnaire = fixtureQuestionnaire();

  ValidationResult check(Map<String, Object?> answers) => validateSubmission(
        questionnaire: questionnaire,
        answers: Answers.from(answers),
      );

  /// Eine vollständige, gültige Einreichung ohne Module.
  Map<String, Object?> gueltig() => {
        's1_status': 'in_ausbildung',
        's4_lehrjahr': '2',
        's6_azubis': '6_20',
        's9_minderjaehrig': 'nein',
        'k3_ueberstunden': 10,
        'k3_1_ausgleich': 'abgefeiert',
        'k4_erreichbarkeit': 'meistens',
        'k5_empfehlung': 8,
        'k6_gesamt': 72,
        'k7_anleitung': 'gut',
        'k8_lernwert': 'gut',
        'k9_umgang': 'freundlich',
        'k10_belastung': 'selten',
        'k11_planung': 'mittel',
        'k12_prioritaeten': ['fachlich', 'umgang', 'arbeitszeit'],
        'berufsschule__teaser': 'nein',
        'a1_freitext': {'gut': 'Vieles.', 'schlecht': ''},
        'a3_tagesform': 'gut',
      };

  test('Eine vollständige Einreichung geht durch', () {
    final result = check(gueltig());
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
    expect(result.isValid, isTrue);
  });

  group('Sichtbarkeit', () {
    test('Eine Antwort auf eine unsichtbare Frage wird beanstandet', () {
      final answers = gueltig()
        ..['s1_status'] = 'abgebrochen'
        ..remove('s4_lehrjahr');
      // S4 ist damit weg, aber das Abbruchmodul kommt hinzu — und dessen
      // Teaser ist unbeantwortet. Hier geht es nur um die eine Frage.
      answers['s4_lehrjahr'] = '2';

      final issues = check(answers).withCode('not_visible');
      expect([for (final issue in issues) issue.questionId],
          contains('s4_lehrjahr'));
    });

    test('K3.1 ohne Überstunden wird beanstandet', () {
      final answers = gueltig()..['k3_ueberstunden'] = 0;
      expect(
        [for (final i in check(answers).withCode('not_visible')) i.questionId],
        ['k3_1_ausgleich'],
      );
    });

    test('Eine Frage, die es in dieser Version gar nicht gibt', () {
      final answers = gueltig()..['k99_erfunden'] = 'x';
      final issues = check(answers).withCode('unknown_question');
      expect(issues, hasLength(1));
      expect(issues.single.message, contains('Version 1'));
    });

    test('Die Antwort auf einen Modulteaser gilt als bekannt', () {
      // Teaserfragen stehen nicht in der Fragenliste. Trotzdem darf ihre
      // Antwort nicht als „unbekannte Frage" durchgehen.
      final answers = gueltig()..['abbruch__teaser'] = 'ja';
      final issues = check(answers);
      expect(issues.withCode('unknown_question'), isEmpty);
      expect(
        [for (final i in issues.withCode('not_visible')) i.questionId],
        contains('abbruch__teaser'),
      );
    });
  });

  group('Pflichtfragen', () {
    test('Eine fehlende Pflichtantwort wird beanstandet', () {
      final answers = gueltig()..remove('k6_gesamt');
      final issues = check(answers).withCode('missing_required');
      expect([for (final i in issues) i.questionId], ['k6_gesamt']);
    });

    test('Eine Pflichtfrage mit leerem Wert zählt als unbeantwortet', () {
      final answers = gueltig()..['k6_gesamt'] = null;
      expect(check(answers).withCode('missing_required'), hasLength(1));
    });

    test('Eine freiwillige Frage darf leer bleiben', () {
      final answers = gueltig()..['k7_anleitung'] = null;
      expect(check(answers).issues, isEmpty);
    });
  });

  group('Werte', () {
    test('Eine unbekannte Option', () {
      final answers = gueltig()..['k9_umgang'] = 'nett';
      final issues = check(answers).withCode('invalid_value');
      expect(issues.single.message, contains('nett'));
    });

    test('Eine Zahl außerhalb der Grenzen', () {
      final answers = gueltig()..['k5_empfehlung'] = 11;
      expect(check(answers).withCode('invalid_value'), hasLength(1));
    });

    test('Eine Zahl neben der Schrittweite', () {
      final answers = gueltig()..['k3_ueberstunden'] = 7;
      final issues = check(answers).withCode('invalid_value');
      expect(issues.single.message, contains('Schrittweite'));
    });

    test('Ein hinterlegter Sonderwert ist erlaubt', () {
      final answers = gueltig()
        ..['k3_ueberstunden'] = 'weiss_nicht'
        ..remove('k3_1_ausgleich');
      expect(check(answers).issues, isEmpty);
    });

    test('Ein nicht hinterlegter Sonderwert ist es nicht', () {
      final answers = gueltig()
        ..['k3_ueberstunden'] = 'keine_ahnung'
        ..remove('k3_1_ausgleich');
      expect(check(answers).withCode('invalid_value'), hasLength(1));
    });

    test('Ein zu langer Freitext', () {
      final answers = gueltig()
        ..['a1_freitext'] = {'gut': 'x' * 4001, 'schlecht': ''};
      final issues = check(answers).withCode('invalid_value');
      expect(issues.single.message, contains('4000'));
    });

    test('Ein unbekanntes Freitextfeld', () {
      final answers = gueltig()..['a1_freitext'] = {'egal': 'x'};
      expect(check(answers).withCode('invalid_value'), hasLength(1));
    });
  });

  group('Rangfolge', () {
    test('Genau drei Ränge sind verlangt', () {
      final zuWenig = gueltig()..['k12_prioritaeten'] = ['fachlich', 'umgang'];
      expect(
        check(zuWenig).withCode('invalid_value').single.message,
        contains('genau 3'),
      );
    });

    test('Eine doppelte Nennung wird beanstandet', () {
      final answers = gueltig()
        ..['k12_prioritaeten'] = ['fachlich', 'fachlich', 'umgang'];
      expect(
        check(answers).withCode('invalid_value').single.message,
        contains('mehrfach'),
      );
    });

    test('Eine unbekannte Karte wird beanstandet', () {
      final answers = gueltig()
        ..['k12_prioritaeten'] = ['fachlich', 'umgang', 'urlaub'];
      expect(check(answers).withCode('invalid_value'), hasLength(1));
    });
  });

  group('Mehrfachauswahl und Wischkarten', () {
    Map<String, Object?> mitAbbruch() => gueltig()
      ..['s1_status'] = 'abgebrochen'
      ..remove('s4_lehrjahr')
      ..['abbruch__teaser'] = 'ja'
      ..['m_abbruch_ausschlag'] = ['betrieb'];

    test('Eine gültige Mehrfachauswahl geht durch', () {
      expect(check(mitAbbruch()).issues, isEmpty);
    });

    test('Die Mindestzahl wird durchgesetzt', () {
      final answers = mitAbbruch()..['m_abbruch_ausschlag'] = <String>[];
      expect(
        check(answers).withCode('invalid_value').single.message,
        contains('Mindestens 1'),
      );
    });

    Map<String, Object?> mitJas() => gueltig()
      ..['s9_minderjaehrig'] = 'ja'
      ..['jugendarbeitsschutz__teaser'] = 'ja'
      ..['m_jas_karten'] = {
        'berufsschultag': 'ja',
        'nach20uhr': 'nein',
        'samstag': 'weiss_nicht',
      };

    test('Gültige Wischkarten gehen durch', () {
      expect(check(mitJas()).issues, isEmpty);
    });

    test('Eine unbekannte Karte wird beanstandet', () {
      final answers = mitJas()..['m_jas_karten'] = {'pausen': 'ja'};
      expect(
        check(answers).withCode('invalid_value').single.message,
        contains('pausen'),
      );
    });

    test('Ein unzulässiger Kartenwert wird beanstandet', () {
      final answers = mitJas()
        ..['m_jas_karten'] = {'berufsschultag': 'vielleicht'};
      expect(
        check(answers).withCode('invalid_value').single.message,
        contains('vielleicht'),
      );
    });
  });

  test('Eine Zuordnung, wo keine vorgesehen ist', () {
    final answers = gueltig()..['k9_umgang'] = {'a': 'b'};
    expect(
      check(answers).withCode('invalid_value').single.message,
      allOf(contains('cards'), contains('fields')),
    );
  });
}
