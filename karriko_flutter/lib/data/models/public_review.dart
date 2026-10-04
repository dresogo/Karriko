/// Eine freigegebene Bewertung, so wie sie oeffentlich sichtbar ist.
///
/// Das ist eine **eigene Tabelle**, nicht eine gefilterte Sicht auf `reviews`.
/// Appwrite vergibt Rechte pro Zeile, nicht pro Spalte: Waere alles in einer
/// Tabelle, muesste entweder der Nutzer-Bezug oeffentlich lesbar sein oder die
/// Bewertung unsichtbar. Was hier steht, darf jeder sehen — und was nicht hier
/// steht, sieht niemand ausser der Moderation.
///
/// Nicht enthalten und das mit Absicht: `user_id`, die Rohantworten, die
/// Bearbeitungszeiten, die Qualitaets-Flags, der Geraetehash, die Tagesform
/// und alles aus dem Konfliktmodul.
class PublicReview {
  final String id;

  /// Verweis auf die Zeile in `reviews`, fuer die Moderation.
  final String reviewId;

  final String companyId;
  final String? companyName;
  final String? companySlug;

  final String? berufCode;
  final String? berufName;

  /// Jahr ja, Monat nein. Der Monat wuerde die Einzelbewertung in einem
  /// kleinen Betrieb zuordenbar machen.
  final int? startYear;
  final int? endYear;

  /// `in_ausbildung`, `ausgelernt_geblieben`, `ausgelernt_gegangen`,
  /// `abgebrochen`.
  final String? respondentStatus;

  /// K5, 0 bis 10.
  final int? recommend;

  /// K6, 0 bis 100.
  final int? overall;

  /// Die sechs Subscores auf 1,0 bis 5,0, soweit vorhanden.
  final Map<String, double> subscores;

  /// Getrennt ausgewiesen, nicht im Betriebsscore.
  final double? berufsschule;

  final String? freitextGut;
  final String? freitextSchlecht;

  /// Aelter als die Alterungsgrenze und deshalb gekennzeichnet.
  final bool isAged;

  /// Das Ausbildungsverhaeltnis wurde nachgewiesen.
  final bool verified;

  final DateTime publishedAt;

  const PublicReview({
    required this.id,
    required this.reviewId,
    required this.companyId,
    required this.publishedAt,
    this.companyName,
    this.companySlug,
    this.berufCode,
    this.berufName,
    this.startYear,
    this.endYear,
    this.respondentStatus,
    this.recommend,
    this.overall,
    this.subscores = const {},
    this.berufsschule,
    this.freitextGut,
    this.freitextSchlecht,
    this.isAged = false,
    this.verified = false,
  });

  /// K6 auf der Skala 1,0 bis 5,0, wie die Subscores.
  double? get overallScore => overall == null ? null : 1 + 4 * (overall! / 100);

  bool get hasFreitext =>
      (freitextGut?.trim().isNotEmpty ?? false) ||
      (freitextSchlecht?.trim().isNotEmpty ?? false);

  /// Der Zeitraum, wie er in der Einzelansicht steht.
  String get zeitraum {
    if (startYear == null) return '';
    if (endYear == null || endYear == startYear) return '$startYear';
    return '$startYear bis $endYear';
  }

  static const _subscoreSpalten = <String, String>{
    'sub_fachlich': 'fachlich',
    'sub_betreuung': 'betreuung',
    'sub_umgang': 'umgang',
    'sub_belastung': 'belastung',
    'sub_verguetung': 'verguetung',
    'sub_perspektive': 'perspektive',
  };

  factory PublicReview.fromJson(Map<String, dynamic> json) {
    final subscores = <String, double>{};
    _subscoreSpalten.forEach((spalte, dimension) {
      final wert = (json[spalte] as num?)?.toDouble();
      if (wert != null) subscores[dimension] = wert;
    });

    return PublicReview(
      id: json['id'] as String,
      reviewId: json['review_id'] as String? ?? json['id'] as String,
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String?,
      companySlug: json['company_slug'] as String?,
      berufCode: json['beruf_code'] as String?,
      berufName: json['beruf_name'] as String?,
      startYear: (json['start_year'] as num?)?.toInt(),
      endYear: (json['end_year'] as num?)?.toInt(),
      respondentStatus: json['respondent_status'] as String?,
      recommend: (json['k5_recommend'] as num?)?.toInt(),
      overall: (json['k6_overall'] as num?)?.toInt(),
      subscores: subscores,
      berufsschule: (json['sub_berufsschule'] as num?)?.toDouble(),
      freitextGut: json['freitext_gut'] as String?,
      freitextSchlecht: json['freitext_schlecht'] as String?,
      isAged: json['is_aged'] as bool? ?? false,
      verified: json['verified'] as bool? ?? false,
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }
}
