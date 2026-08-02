/// Antworttyp einer Bewertungsfrage.
enum QuestionType {
  /// Sternebewertung von 1 bis 5.
  rating,

  /// Ja/Nein-Frage.
  yesNo,

  /// Freitextantwort.
  text;

  static QuestionType fromString(String? value) => switch (value) {
        'yes_no' => QuestionType.yesNo,
        'text' => QuestionType.text,
        _ => QuestionType.rating,
      };
}

/// Eine Frage, die dem Azubi zu seinem Betrieb gestellt wird.
///
/// Die Fragen liegen in der Datenbank (Appwrite-Collection `questions`) und
/// werden von dort geladen, damit sie ohne App-Update angepasst werden können.
class QuestionModel {
  final String id;
  final String category;
  final String text;
  final String? hint;
  final QuestionType type;
  final bool isRequired;
  final int sortOrder;

  const QuestionModel({
    required this.id,
    required this.category,
    required this.text,
    this.hint,
    required this.type,
    required this.isRequired,
    required this.sortOrder,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: (json['\$id'] ?? json['id']) as String,
      category: json['category'] as String? ?? 'Allgemein',
      text: json['text'] as String? ?? '',
      hint: json['hint'] as String?,
      type: QuestionType.fromString(json['type'] as String?),
      isRequired: json['is_required'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
