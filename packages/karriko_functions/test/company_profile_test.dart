import 'package:karriko_functions/karriko_functions.dart';
import 'package:test/test.dart';

/// T-4.2: Ein Betrieb setzt an seinem Profil nur, was ihm gehört. Abzeichen,
/// Premium, Bewertung und Eigentümer setzen Server und Moderation.
void main() {
  group('parseCompanyProfile', () {
    test('übernimmt die erlaubten Felder, getrimmt', () {
      final e = parseCompanyProfile({
        'name': '  Musterbau GmbH ',
        'city': 'Dortmund',
        'website': 'https://musterbau.de',
      }, creating: false);

      expect(e.isValid, isTrue);
      expect(e.data, {
        'name': 'Musterbau GmbH',
        'city': 'Dortmund',
        'website': 'https://musterbau.de',
      });
    });

    for (final feld in [
      'is_verified',
      'is_premium',
      'average_rating',
      'review_count',
      'owner_id',
      'slug',
    ]) {
      test('weist $feld ab', () {
        final e = parseCompanyProfile(
          {'name': 'Musterbau', feld: true},
          creating: false,
        );
        expect(e.isValid, isFalse);
        expect(e.errors, contains('Feld nicht erlaubt: $feld'));
        expect(e.data, isEmpty);
      });
    }

    test('leerer Text leert ein optionales Feld', () {
      final e = parseCompanyProfile(
        {'website': '', 'description': '   '},
        creating: false,
      );
      expect(e.data, {'website': null, 'description': null});
    });

    test('der Name darf nicht leer werden', () {
      final e = parseCompanyProfile({'name': ' '}, creating: false);
      expect(e.isValid, isFalse);
    });

    test('beim Anlegen ist der Name Pflicht', () {
      final e = parseCompanyProfile({'city': 'Dortmund'}, creating: true);
      expect(e.isValid, isFalse);
      expect(e.errors.single, contains('Unternehmensname'));
    });

    test('zu langer Name', () {
      final e = parseCompanyProfile({'name': 'x' * 201}, creating: false);
      expect(e.isValid, isFalse);
    });

    test('kein Text', () {
      final e = parseCompanyProfile({'city': 42}, creating: false);
      expect(e.isValid, isFalse);
    });

    for (final adresse in [
      'javascript:alert(1)',
      'data:text/html,hallo',
      'ftp://musterbau.de',
      'www.musterbau.de',
      'https://',
    ]) {
      test('Website „$adresse“ wird abgewiesen', () {
        final e = parseCompanyProfile({'website': adresse}, creating: false);
        expect(e.isValid, isFalse);
      });
    }

    test('logo_url nur http/https', () {
      expect(
        parseCompanyProfile({'logo_url': 'javascript:x'}, creating: false)
            .isValid,
        isFalse,
      );
      expect(
        parseCompanyProfile({'logo_url': 'http://x.de/l.png'}, creating: false)
            .isValid,
        isTrue,
      );
    });
  });

  test('buildNewCompanyRow setzt die gesperrten Felder selbst', () {
    final zeile = buildNewCompanyRow(
      ownerId: 'b1',
      slug: 'musterbau',
      fields: {'name': 'Musterbau'},
    );
    expect(zeile, {
      'name': 'Musterbau',
      'slug': 'musterbau',
      'owner_id': 'b1',
      'review_count': 0,
      'is_premium': false,
      'is_verified': false,
    });
  });

  // Uebernommen aus der App (company_link_test.dart), seit der Slug nur noch
  // auf dem Server entsteht (T-4.2).
  group('companySlug', () {
    test('schreibt Umlaute aus, statt sie zu verschlucken', () {
      expect(companySlug('Müller GmbH'), 'mueller-gmbh');
      expect(companySlug('Schrödinger & Söhne'), 'schroedinger-soehne');
      expect(companySlug('Weißbier AG'), 'weissbier-ag');
    });

    test('faellt auf Kleinbuchstaben, Ziffern und Bindestriche zurueck', () {
      expect(companySlug('Meyer & Co. KG'), 'meyer-co-kg');
      expect(companySlug('3M Deutschland'), '3m-deutschland');
    });

    test('laesst keine Bindestriche am Rand stehen', () {
      expect(companySlug('  Bosch  '), 'bosch');
      expect(companySlug('- Siemens -'), 'siemens');
    });

    test('liefert nie eine leere Adresse', () {
      expect(companySlug('***'), 'unternehmen');
      expect(companySlug(''), 'unternehmen');
      expect(companySlug('Тест'), 'unternehmen');
    });
  });
}
