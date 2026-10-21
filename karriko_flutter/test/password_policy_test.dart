import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/core/utils/validators.dart';
import 'package:karriko_flutter/data/repositories/auth_error_mapper.dart';

/// E-3.12: Länge statt Zeichenklassen, dazu Prüfungen auf dem Server, deren
/// Ablehnung verständlich ankommen muss.
void main() {
  group('Validators.password', () {
    test('verlangt mindestens 12 Zeichen', () {
      expect(Validators.password('kurzespw123'), isNotNull, reason: '11');
      expect(Validators.password('lang genug ok'), isNull, reason: '13');
    });

    test('keine Pflicht zu Großbuchstaben, Ziffern oder Sonderzeichen', () {
      expect(Validators.password('nurkleinbuchstaben'), isNull);
    });

    test('leer', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });
  });

  group('Ablehnungen des Servers', () {
    String meldung(String typ) =>
        mapAppwriteError(AppwriteException('roh', 400, typ), 'Fallback')
            .message;

    test('geleaktes Passwort (T-3.20)', () {
      expect(meldung('password_pwned'), contains('Datenleck'));
    });

    test('Leckprüfung nicht erreichbar', () {
      expect(meldung('general_pwned_passwords_unavailable'),
          contains('gerade nicht prüfen'));
    });

    test('kürzlich verwendet', () {
      expect(meldung('password_recently_used'), contains('vor Kurzem'));
    });

    test('nie der englische Rohtext', () {
      for (final typ in [
        'password_pwned',
        'general_pwned_passwords_unavailable',
        'password_recently_used',
        'password_personal_data',
      ]) {
        expect(meldung(typ), isNot(contains('roh')), reason: typ);
      }
    });
  });
}
