import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/core/utils/date_format.dart';

void main() {
  group('Quartal auf öffentlichen Bewertungen (T-5.21)', () {
    test('zeigt das Quartal, nicht den Monat', () {
      expect(quarterLabel(DateTime.utc(2026, 10, 1)), 'Q4 2026');
      expect(quarterLabel(DateTime.utc(2026, 11, 17, 14, 32)), 'Q4 2026');
    });

    test('Quartalsgrenzen', () {
      expect(quarterLabel(DateTime.utc(2026, 1, 1)), 'Q1 2026');
      expect(quarterLabel(DateTime.utc(2026, 3, 31)), 'Q1 2026');
      expect(quarterLabel(DateTime.utc(2026, 4, 1)), 'Q2 2026');
      expect(quarterLabel(DateTime.utc(2026, 7, 1)), 'Q3 2026');
      expect(quarterLabel(DateTime.utc(2026, 12, 31)), 'Q4 2026');
    });

    test('der gespeicherte Quartalsbeginn springt nicht ins Vorquartal', () {
      // Gespeichert wird 00:00 UTC. In Ortszeit westlich von UTC läge das im
      // Vorquartal; die Anzeige rechnet deshalb in UTC.
      final gespeichert = DateTime.parse('2026-10-01T00:00:00.000Z');
      expect(quarterLabel(gespeichert.toLocal()), 'Q4 2026');
    });
  });
}
