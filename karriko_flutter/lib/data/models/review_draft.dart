import 'dart:convert';

/// Eine begonnene, noch nicht abgeschickte Bewertung.
///
/// Der Entwurf gehoert dem Nutzer und niemandem sonst: Lesen und Schreiben
/// sind auf den Eigentuemer beschraenkt. Er traegt seine `schemaVersion` mit
/// sich — wer unter v1 angefangen hat, fuellt v1 zu Ende, auch wenn inzwischen
/// v2 aktiv ist.
class ReviewDraft {
  final String? id;
  final String userId;
  final String companyId;
  final int schemaVersion;

  /// Antworten je Frage-ID.
  final Map<String, Object?> answers;

  /// Bearbeitungszeit je Bildschirm in Millisekunden.
  final Map<String, int> timings;

  /// Wo der Nutzer stehengeblieben ist.
  final String? currentQuestionId;

  final String? inviteSource;
  final DateTime updatedAt;

  const ReviewDraft({
    required this.userId,
    required this.companyId,
    required this.schemaVersion,
    required this.answers,
    required this.updatedAt,
    this.id,
    this.timings = const {},
    this.currentQuestionId,
    this.inviteSource,
  });

  ReviewDraft copyWith({
    String? id,
    Map<String, Object?>? answers,
    Map<String, int>? timings,
    String? currentQuestionId,
    DateTime? updatedAt,
  }) {
    return ReviewDraft(
      id: id ?? this.id,
      userId: userId,
      companyId: companyId,
      schemaVersion: schemaVersion,
      answers: answers ?? this.answers,
      timings: timings ?? this.timings,
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      inviteSource: inviteSource,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Wie der Entwurf in Appwrite steht.
  ///
  /// Antworten und Zeiten liegen als JSON-Zeichenkette in einer `text`-Spalte,
  /// nicht als typisierte Spalten: Ihre Form haengt an der Version der
  /// Definition, und ein Schema, das sich mit jeder Fragebogenaenderung aendern
  /// muss, ist keins.
  Map<String, dynamic> toAppwrite() => {
        'user_id': userId,
        'company_id': companyId,
        'schema_version': schemaVersion,
        'answers_json': jsonEncode(answers),
        'timings_json': jsonEncode(timings),
        if (currentQuestionId != null) 'current_question_id': currentQuestionId,
        if (inviteSource != null) 'invite_source': inviteSource,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory ReviewDraft.fromJson(Map<String, dynamic> json) {
    return ReviewDraft(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      schemaVersion: (json['schema_version'] as num).toInt(),
      answers: _decodeMap(json['answers_json']),
      timings: _decodeMap(json['timings_json']).map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
      currentQuestionId: json['current_question_id'] as String?,
      inviteSource: json['invite_source'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Ein kaputter Entwurf ist kein Grund, den Nutzer auszusperren.
  ///
  /// Landet hier etwas, das sich nicht lesen laesst — eine halb geschriebene
  /// Zeichenkette, ein Rest aus einer frueheren Fassung —, faengt der Bogen
  /// eben von vorn an. Das ist aergerlich; eine Fehlerseite waere schlimmer.
  static Map<String, Object?> _decodeMap(Object? raw) {
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
}
