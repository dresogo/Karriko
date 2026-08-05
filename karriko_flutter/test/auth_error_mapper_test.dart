import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/data/repositories/auth_error_mapper.dart';

/// Baut einen Appwrite-Fehler mit dem gewuenschten Typ.
///
/// Die Rohmeldung ist absichtlich auffaellig: mehrere Tests pruefen, dass sie
/// nicht bis zum Nutzer durchschlaegt.
AppwriteException _error(String? type) => AppwriteException(
      'ROHTEXT_DARF_NICHT_ANGEZEIGT_WERDEN',
      401,
      type,
    );

void main() {
  group('Kontoexistenz bleibt verborgen', () {
    test('falsches Passwort und unbekannte Adresse melden dasselbe', () {
      // Der Kern der Anforderung aus notes/projekt-referenz.md Paragraf 3.2.
      // Sobald sich die beiden Texte unterscheiden, laesst sich damit pruefen,
      // welche E-Mail-Adressen registriert sind.
      final falschesPasswort =
          mapAppwriteError(_error('user_invalid_credentials'), 'Fallback');
      final unbekannteAdresse =
          mapAppwriteError(_error('user_not_found'), 'Fallback');

      expect(falschesPasswort.message, unbekannteAdresse.message);
    });

    test(
        'falscher TOTP-Code und falscher Wiederherstellungscode melden dasselbe',
        () {
      // Unterschiedliche Texte wuerden verraten, ob ein eingegebener Code als
      // Wiederherstellungscode ueberhaupt existiert.
      final totp = mapAppwriteError(
        _error('user_invalid_token'),
        'Fallback',
        context: AuthContext.mfa,
      );
      final recovery =
          mapAppwriteError(_error('user_recovery_code_invalid'), 'Fallback');

      expect(totp.message, recovery.message);
    });
  });

  group('Rohtexte von Appwrite erreichen den Nutzer nicht', () {
    test('unbekannter Fehlertyp liefert den Fallback', () {
      final failure = mapAppwriteError(
          _error('irgendein_neuer_typ'), 'Anmeldung fehlgeschlagen.');

      expect(failure.message, 'Anmeldung fehlgeschlagen.');
      expect(failure.message, isNot(contains('ROHTEXT')));
    });

    test('fehlender Fehlertyp liefert den Fallback', () {
      final failure =
          mapAppwriteError(_error(null), 'Anmeldung fehlgeschlagen.');

      expect(failure.message, 'Anmeldung fehlgeschlagen.');
    });

    test('kein bekannter Fehlertyp gibt die Rohmeldung durch', () {
      const typen = [
        'user_invalid_credentials',
        'user_not_found',
        'user_already_exists',
        'user_blocked',
        'user_session_already_exists',
        'general_rate_limit_exceeded',
        'password_personal_data',
        'user_invalid_token',
        'user_recovery_code_invalid',
        'user_oauth2_unauthorized',
        'user_authenticator_not_found',
        'user_challenge_required',
        'user_more_factors_required',
      ];

      for (final typ in typen) {
        final failure = mapAppwriteError(_error(typ), 'Fallback');
        expect(failure.message, isNot(contains('ROHTEXT')), reason: typ);
      }
    });
  });

  group('Mehrdeutige Fehler haengen am Kontext', () {
    test('verbrauchtes Token liest sich beim Link anders als beim Code', () {
      final amLink = mapAppwriteError(
        _error('user_invalid_token'),
        'Fallback',
        context: AuthContext.link,
      );
      final amCode = mapAppwriteError(
        _error('user_invalid_token'),
        'Fallback',
        context: AuthContext.mfa,
      );

      expect(amLink.message, isNot(amCode.message));
      expect(amLink.message, contains('Link'));
      expect(amCode.message, contains('Code'));
    });

    test('alle OAuth-Fehler teilen sich eine Meldung', () {
      final meldungen = [
        'user_oauth2_unauthorized',
        'user_oauth2_bad_request',
        'user_oauth2_provider_error',
      ].map((t) => mapAppwriteError(_error(t), 'Fallback').message).toSet();

      expect(meldungen, hasLength(1));
    });
  });
}
