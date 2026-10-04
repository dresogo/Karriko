import '../condition/condition.dart';

/// Die bisherigen Antworten, unveränderlich.
///
/// Unveränderlich, weil die Ablaufsteuerung eine reine Funktion davon ist: Wer
/// eine Antwort ändert, bekommt einen neuen Stand und lässt den alten
/// unangetastet. Das macht „was wäre, wenn" — etwa die Frage, welche Antworten
/// beim Zurückgehen ungültig werden — zu einem gewöhnlichen Aufruf statt zu
/// einer Zustandsakrobatik.
class Answers {
  final Map<String, Object?> values;

  const Answers(this.values);

  const Answers.empty() : values = const {};

  Answers.from(Map<String, Object?> source) : values = Map.unmodifiable(source);

  Object? operator [](String questionId) => values[questionId];

  bool contains(String questionId) => values.containsKey(questionId);

  /// Ob eine Antwort inhaltlich vorliegt. `0` zählt, `""` und `[]` nicht —
  /// siehe [AnsweredCondition.isAnswered].
  bool isAnswered(String questionId) =>
      AnsweredCondition.isAnswered(values[questionId]);

  Answers set(String questionId, Object? value) =>
      Answers.from({...values, questionId: value});

  Answers setAll(Map<String, Object?> more) =>
      Answers.from({...values, ...more});

  Answers remove(Iterable<String> questionIds) {
    final next = Map<String, Object?>.from(values);
    for (final id in questionIds) {
      next.remove(id);
    }
    return Answers.from(next);
  }

  Iterable<String> get ids => values.keys;

  bool get isEmpty => values.isEmpty;

  int get length => values.length;

  Map<String, Object?> toJson() => Map<String, Object?>.from(values);

  @override
  String toString() => 'Answers(${values.length} Antworten)';
}
