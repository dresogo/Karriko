import 'dart:convert';

/// Die Aggregate eines Betriebs, so wie `aggregate_company` sie berechnet hat.
///
/// Der Client rechnet das **nicht** nach. Er koennte es — die Logik liegt in
/// `questionnaire_core` —, aber er kaeme gar nicht an die Grundlage heran: Die
/// Einzelbewertungen, aus denen sich der Score speist, sind zum Teil nicht
/// oeffentlich, und die Gewichte haengen an den K12-Prioritaeten aller
/// Bewerter. Was hier steht, ist das Ergebnis, und es ist verbindlich.
class CompanyScores {
  final String id;
  final String companyId;

  /// Gesamtscore auf 1,0 bis 5,0. `null`, solange zu wenige Bewertungen da
  /// sind.
  final double? overall;

  /// Die sechs Subscores, jeweils 1,0 bis 5,0.
  final Map<String, double> subscores;

  /// Getrennt ausgewiesen: die Berufsschule fliesst nicht in [overall] ein.
  final double? berufsschule;

  /// Mittelwert der Weiterempfehlung, 0 bis 10.
  final double? recommendMean;

  /// Die Gewichte, mit denen [overall] gebildet wurde. Aus den aggregierten
  /// K12-Prioritaeten aller Bewerter dieses Betriebs.
  final Map<String, double> weights;

  final int reviewCount;

  /// Wie viele davon als alt gekennzeichnet sind.
  final int agedCount;

  /// Ab drei Bewertungen.
  final bool scoreVisible;

  /// Ab fuenf Bewertungen, und dann nur in Spannen.
  final bool numbersVisible;

  /// Die Spannen, die veroeffentlicht werden duerfen: `{"verguetung": "700 bis
  /// 900 €"}`. Leer, solange [numbersVisible] falsch ist.
  final Map<String, String> bands;

  final DateTime updatedAt;

  const CompanyScores({
    required this.id,
    required this.companyId,
    required this.reviewCount,
    required this.updatedAt,
    this.overall,
    this.subscores = const {},
    this.berufsschule,
    this.recommendMean,
    this.weights = const {},
    this.agedCount = 0,
    this.scoreVisible = false,
    this.numbersVisible = false,
    this.bands = const {},
  });

  static const _subscoreSpalten = <String, String>{
    'sub_fachlich': 'fachlich',
    'sub_betreuung': 'betreuung',
    'sub_umgang': 'umgang',
    'sub_belastung': 'belastung',
    'sub_verguetung': 'verguetung',
    'sub_perspektive': 'perspektive',
  };

  factory CompanyScores.fromJson(Map<String, dynamic> json) {
    final subscores = <String, double>{};
    _subscoreSpalten.forEach((spalte, dimension) {
      final wert = (json[spalte] as num?)?.toDouble();
      if (wert != null) subscores[dimension] = wert;
    });

    return CompanyScores(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      overall: (json['overall'] as num?)?.toDouble(),
      subscores: subscores,
      berufsschule: (json['sub_berufsschule'] as num?)?.toDouble(),
      recommendMean: (json['recommend_mean'] as num?)?.toDouble(),
      weights: _decodeDoubles(json['weights_json']),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      agedCount: (json['aged_count'] as num?)?.toInt() ?? 0,
      scoreVisible: json['score_visible'] as bool? ?? false,
      numbersVisible: json['numbers_visible'] as bool? ?? false,
      bands: _decodeStrings(json['bands_json']),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static Map<String, Object?> _decode(Object? raw) {
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      return const {};
    }
    return const {};
  }

  static Map<String, double> _decodeDoubles(Object? raw) {
    final out = <String, double>{};
    _decode(raw).forEach((key, value) {
      if (value is num) out[key] = value.toDouble();
    });
    return out;
  }

  static Map<String, String> _decodeStrings(Object? raw) {
    final out = <String, String>{};
    _decode(raw).forEach((key, value) {
      if (value is String) out[key] = value;
    });
    return out;
  }
}
