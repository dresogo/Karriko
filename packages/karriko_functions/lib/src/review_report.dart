/// Meldungen zu veröffentlichten Bewertungen (T-4.41, T-3.10).
///
/// Bis Oktober 2026 schrieb der Client direkt in `review_reports` und setzte
/// dabei `reporter_id` und `status` selbst. Eine Meldung ließ sich so einem
/// anderen Konto zuschreiben oder gleich als erledigt anlegen. Jetzt entsteht
/// sie nur in der Function `report_review`, und was hier steht, entscheidet,
/// welche Zeile sie schreibt.
library;

import 'moderation_desk.dart' show ReportStatus;

/// Längste Begründung einer Meldung, wie Freitexte (Factsheet §5).
const maxReportReasonLength = 1000;

/// Höchstens so viele Meldungen je Konto in [reportWindow] (Referenz §2.4:
/// „Meldungen je Betrieb und 24 h: 5“). Gezählt wird je meldendem Konto; ein
/// Betrieb meldet über sein Konto.
const maxReportsPerWindow = 5;

/// Das Zeitfenster für [maxReportsPerWindow]: gleitend.
const reportWindow = Duration(hours: 24);

/// Ab wann das Fenster für eine Meldung zum Zeitpunkt [now] zählt.
DateTime reportWindowStart(DateTime now) => now.toUtc().subtract(reportWindow);

/// Ob eine weitere Meldung das Limit überschreiten würde. [recentCount] ist
/// die Zahl der Meldungen im Fenster **vor** dieser.
bool reportLimitReached(int recentCount) => recentCount >= maxReportsPerWindow;

/// Die Begründung, bereinigt, oder `null`, wenn sie leer oder zu lang ist.
///
/// Zu lang wird abgelehnt statt gekürzt: Eine abgeschnittene Begründung
/// verliert womöglich genau den Satz, um den es geht.
String? normalizeReportReason(Object? raw) {
  if (raw is! String) return null;
  final text = raw.trim();
  if (text.isEmpty || text.length > maxReportReasonLength) return null;
  return text;
}

/// Die Zeile für `review_reports`.
///
/// [reporterId] kommt aus dem geprüften Aufruf, nie aus dem Rumpf. Der Status
/// ist immer [ReportStatus.open]; erledigt wird eine Meldung nur über
/// `moderation_desk`.
Map<String, Object?> buildReportRow({
  required String reviewId,
  required String reporterId,
  required String reason,
}) =>
    {
      'review_id': reviewId,
      'reporter_id': reporterId,
      'reason': reason,
      'status': ReportStatus.open,
    };
