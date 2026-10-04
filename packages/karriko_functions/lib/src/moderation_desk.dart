/// Was die Moderation im Admin-Bereich zu sehen bekommt.
///
/// Die Moderation sieht mehr als der Verfasser — sie muss die Qualitäts-Flags
/// kennen, um zu entscheiden, und die Freitexte, um sie zu prüfen. Sie sieht
/// aber **nicht alles**: Ein paar Spalten bleiben auch hier draußen, weil sie
/// für die Entscheidung nichts beitragen und die Anonymität aufheben würden.
///
/// Was zurückgeht, steht in [buildQueueEntry] und [buildReportEntry]. Was
/// absichtlich fehlt, steht in [withheldFromModeration] — mit dem Grund, damit
/// es niemand später „der Vollständigkeit halber" ergänzt.
library;

/// Die Spalten, die auch die Moderation **nicht** zu sehen bekommt, und warum.
///
/// Prüfgegenstand wie `withheldFromAuthor`: Ein Test stellt sicher, dass keine
/// davon in einem Eintrag landet.
const withheldFromModeration = <String, String>{
  'user_id':
      'Die Bewertung ist anonym, auch gegenueber der Moderation. Fuer die '
          'Entscheidung genuegen Inhalt und Flags; wer sie geschrieben hat, '
          'aendert nichts daran, ob sie veroeffentlicht werden darf.',
  'device_hash':
      'Dient nur dem Erkennen von Mehrfachabgaben, und das steht bereits als '
          'Flag in quality_flags. Der Hash selbst sagt einem Menschen nichts.',
  'answers_json':
      'Die Rohantworten sind gross und stecken verdichtet in den Werten. Wer '
          'sie fuer einen Einzelfall braucht, liest sie in der Console.',
  'timings_json':
      'Aus den Zeiten entsteht das Flag too_fast. Das Flag genuegt.',
  'verification_file_id':
      'Die Dateikennung allein hilft nicht; ob ein Nachweis vorliegt, sagt '
          'has_verification. Geoeffnet wird er in der Console.',
};

/// Status einer Meldung. Zeilen von vor der Einführung der Spalte haben
/// keinen Wert und gelten als offen.
abstract final class ReportStatus {
  static const open = 'open';

  /// Geprüft, kein Handlungsbedarf.
  static const dismissed = 'dismissed';

  /// Geprüft, die Bewertung wurde abgelehnt.
  static const actioned = 'actioned';

  static const resolved = [dismissed, actioned];

  static bool isOpen(Object? status) =>
      status == null || status == '' || status == open;
}

/// Ein Eintrag der Moderations-Warteschlange.
///
/// Reine Funktion über die Zeile und ein paar nachgeladene Angaben — kein
/// Appwrite, kein Netz.
Map<String, Object?> buildQueueEntry({
  required String reviewId,
  required Map<String, Object?> reviewRow,
  required String submittedAt,
  String? companyName,
  String? companySlug,
  int reportCount = 0,
}) {
  return {
    'review_id': reviewId,
    'status': reviewRow['status'],
    'submitted_at': submittedAt,
    'company_id': reviewRow['company_id'],
    'company_name': companyName,
    'company_slug': companySlug,
    'beruf_name': reviewRow['beruf_name'],
    'respondent_status': reviewRow['respondent_status'],
    'start_year': reviewRow['start_year'],
    'end_year': reviewRow['end_year'],
    'invited': reviewRow['invited'] ?? false,

    // Die Grundlage der Entscheidung.
    'freitext_gut': reviewRow['freitext_gut'],
    'freitext_schlecht': reviewRow['freitext_schlecht'],
    'quality_flags': _strings(reviewRow['quality_flags']),
    'quality_notes': _strings(reviewRow['quality_notes']),

    // Werte zur Einordnung: Eine 1 bei überschwänglichem Text ist ein Hinweis.
    'k5_recommend': reviewRow['k5_recommend'],
    'k6_overall': reviewRow['k6_overall'],
    'detail_overall': reviewRow['detail_overall'],

    'verified': reviewRow['verified'] ?? false,
    'has_verification': switch (reviewRow['verification_file_id']) {
      final String id when id.isNotEmpty => true,
      _ => false,
    },
    if (reviewRow['publish_after'] != null)
      'publish_after': reviewRow['publish_after'],
    'report_count': reportCount,
  };
}

/// Ein Eintrag der Meldungsliste.
///
/// [review] ist die interne Zeile der gemeldeten Bewertung, sofern sie sich
/// finden ließ. Eine Meldung kann ins Leere zeigen — dann bleibt sie trotzdem
/// sichtbar, damit sie erledigt werden kann.
Map<String, Object?> buildReportEntry({
  required String reportId,
  required Map<String, Object?> reportRow,
  required String createdAt,
  String? reviewId,
  Map<String, Object?>? review,
  String? publicReviewId,
  String? companyName,
  String? companySlug,
}) {
  final status = reportRow['status'];
  return {
    'report_id': reportId,
    'created_at': createdAt,
    'reason': reportRow['reason'],
    'status': ReportStatus.isOpen(status) ? ReportStatus.open : status,
    if (reportRow['resolved_at'] != null)
      'resolved_at': reportRow['resolved_at'],
    if (reportRow['resolution_note'] != null)
      'resolution_note': reportRow['resolution_note'],
    'reported_id': reportRow['review_id'],
    'review_id': reviewId,
    'review_found': review != null,
    if (review != null) ...{
      'review_status': review['status'],
      'beruf_name': review['beruf_name'],
      'freitext_gut': review['freitext_gut'],
      'freitext_schlecht': review['freitext_schlecht'],
      'quality_flags': _strings(review['quality_flags']),
      'k6_overall': review['k6_overall'],
    },
    'public_review_id': publicReviewId,
    'company_name': companyName,
    'company_slug': companySlug,
  };
}

/// Ein Eintrag des Moderationsprotokolls.
///
/// [moderatorName] ist der Anzeigename, sofern er sich auflösen ließ. Hier —
/// anders als gegenüber dem Verfasser — gehört der Name dazu: Das Protokoll
/// ist genau dafür da, Entscheidungen jemandem zuordnen zu können.
Map<String, Object?> buildLogEntry({
  required String logId,
  required Map<String, Object?> logRow,
  required String fallbackCreatedAt,
  String? companyName,
  String? moderatorName,
}) {
  return {
    'log_id': logId,
    'review_id': logRow['review_id'],
    'moderator_id': logRow['moderator_id'],
    'moderator_name': moderatorName,
    'action': logRow['action'],
    'reason': logRow['reason'],
    'flags': _strings(logRow['flags']),
    'created_at': logRow['created_at'] ?? fallbackCreatedAt,
    'company_name': companyName,
  };
}

/// Ein Betrieb in der Verwaltungsliste.
Map<String, Object?> buildCompanyEntry({
  required String companyId,
  required Map<String, Object?> companyRow,
  required String createdAt,
}) {
  return {
    'company_id': companyId,
    'name': companyRow['name'],
    'slug': companyRow['slug'],
    'city': companyRow['city'],
    'industry': companyRow['industry'],
    'is_verified': companyRow['is_verified'] ?? false,
    'is_premium': companyRow['is_premium'] ?? false,
    'review_count': companyRow['review_count'] ?? 0,
    'average_rating': companyRow['average_rating'],
    'has_owner': switch (companyRow['owner_id']) {
      final String id when id.isNotEmpty => true,
      _ => false,
    },
    'created_at': createdAt,
  };
}

/// Neueste zuerst. Sortiert wird beim Aufrufer statt in der Abfrage: Ein
/// `orderDesc` verlangte je Tabelle einen eigenen Index, und die Listen sind
/// auf wenige hundert Zeilen begrenzt.
void sortNewestFirst(List<Map<String, Object?>> eintraege, String feld) {
  eintraege.sort((a, b) {
    final x = a[feld] as String? ?? '';
    final y = b[feld] as String? ?? '';
    return y.compareTo(x);
  });
}

List<String> _strings(Object? roh) => [
      if (roh is List)
        for (final wert in roh)
          if (wert != null) wert.toString(),
    ];
