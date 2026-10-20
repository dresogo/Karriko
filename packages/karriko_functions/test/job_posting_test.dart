import 'package:karriko_functions/karriko_functions.dart';
import 'package:test/test.dart';

/// T-4.31: Eine Stelle trägt immer den Betrieb des Aufrufers, und öffentlich
/// wird sie erst mit Abzeichen. Was der Betrieb selbst angibt, wird geprüft.
void main() {
  Map<String, Object?> formular([Map<String, Object?> extra = const {}]) => {
        'title': ' Ausbildung Maurer (m/w/d) ',
        'location': 'Dortmund',
        'is_active': false,
        ...extra,
      };

  group('parseJobPosting', () {
    test('übernimmt das Formular, leere Felder werden null', () {
      final e = parseJobPosting(formular({
        'salary': '   ',
        'tasks': ['Mauern', ' ', ' Putzen '],
      }));

      expect(e.isValid, isTrue);
      expect(e.data['title'], 'Ausbildung Maurer (m/w/d)');
      expect(e.data['salary'], isNull);
      expect(e.data.containsKey('salary'), isTrue,
          reason: 'Beim Überschreiben muss ein geleertes Feld null werden.');
      expect(e.data['tasks'], ['Mauern', 'Putzen']);
      expect(e.data['requirements'], isEmpty);
      expect(e.data['start_date'], isNull);
      expect(e.isActive, isFalse);
    });

    for (final feld in [
      'company_id',
      'company',
      'company_slug',
      'company_logo_url',
      'industry',
    ]) {
      test('weist $feld ab', () {
        final e = parseJobPosting(formular({feld: 'fremd'}));
        expect(e.isValid, isFalse);
        expect(e.errors, contains('Feld nicht erlaubt: $feld'));
      });
    }

    test('Titel und Ort sind Pflicht', () {
      expect(parseJobPosting(formular({'title': ''})).isValid, isFalse);
      expect(parseJobPosting(formular({'location': ' '})).isValid, isFalse);
    });

    test('is_active muss gesetzt sein', () {
      final e = parseJobPosting({'title': 'A', 'location': 'B'});
      expect(e.isValid, isFalse);
    });

    for (final link in [
      'javascript:alert(1)',
      'www.firma.de',
      'mailto:a@b.de'
    ]) {
      test('Bewerbungslink „$link“ wird abgewiesen', () {
        expect(parseJobPosting(formular({'apply_url': link})).isValid, isFalse);
      });
    }

    test('Bewerbungslink mit https wird angenommen', () {
      final e =
          parseJobPosting(formular({'apply_url': 'https://firma.de/job'}));
      expect(e.data['apply_url'], 'https://firma.de/job');
    });

    for (final mail in ['keine-adresse', 'a@b', 'a b@c.de']) {
      test('Kontakt-E-Mail „$mail“ wird abgewiesen', () {
        expect(parseJobPosting(formular({'contact_email': mail})).isValid,
            isFalse);
      });
    }

    test('Ausbildungsbeginn als Datum', () {
      expect(
        parseJobPosting(formular({'start_date': '2027-08-01T00:00:00.000'}))
            .data['start_date'],
        startsWith('2027-'),
      );
      expect(
        parseJobPosting(formular({'start_date': 'August'})).isValid,
        isFalse,
      );
    });

    test('zu langer Listenpunkt', () {
      final e = parseJobPosting(formular({
        'benefits': ['x' * 1001],
      }));
      expect(e.isValid, isFalse);
    });
  });

  test('die Angaben zum Betrieb kommen aus der Firmenzeile', () {
    expect(
      jobCompanyFields(companyId: 'c1', company: {
        'name': 'Musterbau GmbH',
        'slug': 'musterbau-gmbh',
        'logo_url': null,
        'industry': 'Handwerk',
        'is_verified': true,
      }),
      {
        'company_id': 'c1',
        'company': 'Musterbau GmbH',
        'company_slug': 'musterbau-gmbh',
        'company_logo_url': null,
        'industry': 'Handwerk',
      },
    );
  });

  group('jobPublishBlocked', () {
    test('Entwurf geht immer', () {
      expect(
          jobPublishBlocked(isActive: false, companyVerified: false), isNull);
    });
    test('veröffentlichen nur verifiziert', () {
      expect(jobPublishBlocked(isActive: true, companyVerified: false),
          contains('verifiziert'));
      expect(jobPublishBlocked(isActive: true, companyVerified: true), isNull);
    });
  });
}
