/// Eine eigene abgeschickte Bewertung, so wie `my_reviews` sie ausliefert.
///
/// Das ist **nicht** die ganze Zeile aus `reviews`. Die Qualitätsmarkierungen,
/// die Bearbeitungszeiten, der Gerätehash und die gerechneten Werte bleiben
/// serverseitig — die Begründung je Feld steht in `withheldFromAuthor` im Paket
/// `karriko_functions`. Was hier fehlt, fehlt absichtlich.
class OwnReview {
  final String reviewId;
  final String companyId;
  final String? companyName;
  final String? companySlug;

  /// `pending_moderation`, `scheduled`, `approved` oder `rejected`.
  final String status;

  final DateTime submittedAt;

  final String? berufName;
  final int? startYear;
  final int? endYear;

  final String? freitextGut;
  final String? freitextSchlecht;

  /// Das Ausbildungsverhältnis wurde nachgewiesen.
  final bool verified;

  /// Bei `scheduled`: ab wann sie in die Moderation geht.
  final DateTime? publishAfter;

  /// Bei `scheduled` ohne bekanntes Enddatum: Es geht erst nach dem
  /// Ausbildungsende weiter, und wann das ist, weiß niemand hier.
  final bool publishAfterTrainingEnd;

  /// Bei `approved`: die Kennung der öffentlichen Zeile, auf die verlinkt wird.
  final String? publicReviewId;
  final DateTime? publishedAt;

  /// Bei `rejected`: die Begründung der Moderation. **Ohne** den Namen dessen,
  /// der entschieden hat.
  final String? rejectionReason;

  const OwnReview({
    required this.reviewId,
    required this.companyId,
    required this.status,
    required this.submittedAt,
    this.companyName,
    this.companySlug,
    this.berufName,
    this.startYear,
    this.endYear,
    this.freitextGut,
    this.freitextSchlecht,
    this.verified = false,
    this.publishAfter,
    this.publishAfterTrainingEnd = false,
    this.publicReviewId,
    this.publishedAt,
    this.rejectionReason,
  });

  bool get istFreigegeben => status == 'approved';
  bool get istAbgelehnt => status == 'rejected';
  bool get istZurueckgestellt => status == 'scheduled';
  bool get liegtInModeration => status == 'pending_moderation';

  /// Der Zeitraum, wie er in der Liste steht.
  String get zeitraum {
    if (startYear == null) return '';
    if (endYear == null || endYear == startYear) return '$startYear';
    return '$startYear bis $endYear';
  }

  static OwnReview? fromJson(Object? roh) {
    if (roh is! Map) return null;
    final id = roh['review_id'];
    if (id is! String || id.isEmpty) return null;

    DateTime? zeit(Object? wert) =>
        wert is String ? DateTime.tryParse(wert) : null;

    return OwnReview(
      reviewId: id,
      companyId: roh['company_id'] as String? ?? '',
      companyName: roh['company_name'] as String?,
      companySlug: roh['company_slug'] as String?,
      status: roh['status'] as String? ?? 'pending_moderation',
      submittedAt: zeit(roh['submitted_at']) ?? DateTime.now(),
      berufName: roh['beruf_name'] as String?,
      startYear: (roh['start_year'] as num?)?.toInt(),
      endYear: (roh['end_year'] as num?)?.toInt(),
      freitextGut: roh['freitext_gut'] as String?,
      freitextSchlecht: roh['freitext_schlecht'] as String?,
      verified: roh['verified'] as bool? ?? false,
      publishAfter: zeit(roh['publish_after']),
      publishAfterTrainingEnd:
          roh['publish_after_training_end'] as bool? ?? false,
      publicReviewId: roh['public_review_id'] as String?,
      publishedAt: zeit(roh['published_at']),
      rejectionReason: roh['rejection_reason'] as String?,
    );
  }
}
