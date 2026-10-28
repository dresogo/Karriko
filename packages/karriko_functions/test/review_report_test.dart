import 'package:karriko_functions/karriko_functions.dart';
import 'package:test/test.dart';

/// Meldungen über `report_review` (T-4.41, T-3.10).
void main() {
  group('normalizeReportReason', () {
    test('kürzt Leerraum am Rand', () {
      expect(normalizeReportReason('  Beleidigung  '), 'Beleidigung');
    });

    test('leer, kein Text oder zu lang: abgelehnt', () {
      expect(normalizeReportReason(null), isNull);
      expect(normalizeReportReason(42), isNull);
      expect(normalizeReportReason('   '), isNull);
      expect(normalizeReportReason('x' * (maxReportReasonLength + 1)), isNull);
    });

    test('genau an der Grenze: angenommen', () {
      expect(normalizeReportReason('x' * maxReportReasonLength), isNotNull);
    });
  });

  group('buildReportRow', () {
    test('Status immer offen, Melder aus dem Aufruf', () {
      expect(
        buildReportRow(reviewId: 'r1', reporterId: 'u1', reason: 'Spam'),
        {
          'review_id': 'r1',
          'reporter_id': 'u1',
          'reason': 'Spam',
          'status': ReportStatus.open,
        },
      );
    });
  });

  group('Grenze je 24 h', () {
    test('die fünfte geht, die sechste nicht', () {
      expect(reportLimitReached(4), isFalse);
      expect(reportLimitReached(5), isTrue);
    });

    test('Fenster gleitend, 24 h zurück', () {
      expect(
        reportWindowStart(DateTime.utc(2026, 10, 28, 12)),
        DateTime.utc(2026, 10, 27, 12),
      );
    });
  });
}
