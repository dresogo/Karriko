import 'package:karriko_functions/karriko_functions.dart';
import 'package:test/test.dart';

/// Kennungen aus dem Rumpf von `submit_review` (T-2.41, T-2.42).
///
/// Die Function handelt mit ihrem eigenen Schlüssel. Was hier „nein“ ergibt,
/// fasst sie nicht an.
void main() {
  group('draftOwnedBy', () {
    test('eigener Entwurf: ja', () {
      expect(draftOwnedBy({'user_id': 'anna'}, 'anna'), isTrue);
    });

    test('fremder Entwurf: nein', () {
      expect(draftOwnedBy({'user_id': 'ben'}, 'anna'), isFalse);
    });

    test('Entwurf ohne Nutzerkennung oder nicht vorhanden: nein', () {
      expect(draftOwnedBy(const {}, 'anna'), isFalse);
      expect(draftOwnedBy(null, 'anna'), isFalse);
    });
  });

  group('checkVerificationFile', () {
    test('ohne Kennung: kein Nachweis, egal was sonst gemeldet wird', () {
      for (final id in [null, '']) {
        expect(
          checkVerificationFile(
              fileId: id, exists: true, usedByOtherReview: true),
          VerificationFileCheck.none,
        );
      }
    });

    test('vorhanden und frei: verwendbar', () {
      expect(
        checkVerificationFile(
            fileId: 'datei', exists: true, usedByOtherReview: false),
        VerificationFileCheck.usable,
      );
    });

    test('nicht vorhanden: abgelehnt', () {
      expect(
        checkVerificationFile(
            fileId: 'datei', exists: false, usedByOtherReview: false),
        VerificationFileCheck.missing,
      );
    });

    test('hängt schon an einer Bewertung: abgelehnt', () {
      expect(
        checkVerificationFile(
            fileId: 'datei', exists: true, usedByOtherReview: true),
        VerificationFileCheck.alreadyUsed,
      );
    });
  });
}
