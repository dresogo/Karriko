import 'package:karriko_functions/karriko_functions.dart';
import 'package:test/test.dart';

/// Projektreferenz §2.4: höchstens drei Bewertungen je Konto und 24 h.
void main() {
  test('die ersten drei gehen durch, die vierte nicht', () {
    expect(reviewLimitReached(0), isFalse);
    expect(reviewLimitReached(1), isFalse);
    expect(reviewLimitReached(2), isFalse);
    expect(reviewLimitReached(3), isTrue);
    expect(reviewLimitReached(7), isTrue);
  });

  test('das Fenster gleitet: genau 24 h zurück, in UTC', () {
    final jetzt = DateTime.utc(2026, 10, 13, 9, 30);
    expect(reviewWindowStart(jetzt), DateTime.utc(2026, 10, 12, 9, 30));
  });

  test('Ortszeit wird vor dem Rechnen nach UTC umgestellt', () {
    final ortszeit = DateTime(2026, 10, 13, 9, 30);
    final start = reviewWindowStart(ortszeit);
    expect(start.isUtc, isTrue);
    expect(ortszeit.toUtc().difference(start), const Duration(hours: 24));
  });

  test('die Antwort ist 429 mit eigenem Code', () {
    final antwort = FunctionResponse.rateLimited('später');
    expect(antwort.status, 429);
    expect(antwort.payload['code'], 'rate_limited');
    expect(antwort.isOk, isFalse);
  });
}
