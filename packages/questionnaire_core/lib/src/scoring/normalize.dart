import '../condition/condition.dart';
import '../model/question.dart';

/// Übersetzt eine Antwort in einen Wert zwischen 0,0 und 1,0.
///
/// Immer „höher ist besser". Die umgekehrte Polung von K10 steckt in den
/// Punktwerten der Optionen; hier wird nichts gedreht. Wer das ändert, dreht
/// den Straightlining-Index mit um, und der lebt davon, dass die Polung
/// *nicht* wegnormalisiert ist.
///
/// `null` heißt „trägt nichts bei" — nicht „null Punkte". Der Unterschied
/// entscheidet, ob ein „weiß ich nicht" einen Subscore drückt oder ihn
/// unberührt lässt. Es lässt ihn unberührt.
double? normalizedAnswer(Question question, Object? answer) {
  if (answer == null) return null;

  if (answer is Map) return _fromCards(question, answer);
  if (answer is Iterable) return _fromSelection(question, answer);

  if (question.options.isNotEmpty) {
    return question.optionForValue(answer)?.score;
  }

  final bands = question.config['scoreBands'];
  if (bands is List) return _fromBands(bands, answer);

  return _linear(question, answer);
}

/// Wischkarten: der Anteil der Ja-Antworten. „Weiß ich nicht" zählt weder für
/// noch gegen den Betrieb und fällt aus dem Nenner.
double? _fromCards(Question question, Map<Object?, Object?> answer) {
  final yes = question.config['yesValue'] ?? 'ja';
  final no = question.config['noValue'] ?? 'nein';

  var counted = 0;
  var positive = 0;
  for (final value in answer.values) {
    if (deepEquals(value, yes)) {
      counted++;
      positive++;
    } else if (deepEquals(value, no)) {
      counted++;
    }
  }
  if (counted == 0) return null;
  return positive / counted;
}

/// Mehrfachauswahl.
///
/// Standardmäßig das **Mittel** der Punktwerte der gewählten Optionen. Mit
/// `config.selectionScoring: "sum"` stattdessen die **Summe**, gedeckelt bei
/// 1,0.
///
/// Der Unterschied entscheidet mehr, als er aussieht. „Was übernimmt der
/// Betrieb?" mit sechs Häkchen: Beim Mittel bekäme ein Betrieb, der nur die
/// Fahrtkosten zahlt, denselben vollen Wert wie einer, der alles zahlt — denn
/// beide Male ist das Mittel der angekreuzten Punkte 1,0. Bei der Summe zählt,
/// wie viel tatsächlich übernommen wird. Umgekehrt ist das Mittel richtig, wo
/// die Optionen Alternativen sind und nicht Bausteine.
double? _fromSelection(Question question, Iterable<Object?> answer) {
  final scores = <double>[];
  for (final value in answer) {
    final score = question.optionForValue(value)?.score;
    if (score != null) scores.add(score);
  }
  if (scores.isEmpty) return null;
  final sum = scores.reduce((a, b) => a + b);
  if (question.config['selectionScoring'] == 'sum') {
    return sum.clamp(0.0, 1.0).toDouble();
  }
  return sum / scores.length;
}

/// Stufen für Zahlen, bei denen der Zusammenhang nicht linear ist — etwa
/// Überstunden, wo die ersten fünf weniger wiegen als die zwanzigsten.
double? _fromBands(List<Object?> bands, Object? answer) {
  final value = answer is num ? answer : null;
  // Sonderwerte wie „weiß ich nicht genau" sind keine Zahl und tragen nichts
  // bei — nicht null Punkte, sondern gar nichts.
  if (value == null) return null;

  for (final band in bands) {
    if (band is! Map) continue;
    final max = band['max'];
    final score = band['score'];
    if (score is! num) continue;
    if (max == null || (max is num && value <= max)) return score.toDouble();
  }
  return null;
}

/// Lineare Skalen: elf Kacheln (0 bis 10), der Regler (0 bis 100), Stepper mit
/// Grenzen. Die Grenzen stehen in `config`, nicht im Code.
double? _linear(Question question, Object? answer) {
  if (answer is! num) return null;
  final min = question.config['scoreMin'] ?? question.config['min'];
  final max = question.config['scoreMax'] ?? question.config['max'];
  if (min is! num || max is! num || max == min) return null;
  final ratio = (answer - min) / (max - min);
  return ratio.clamp(0.0, 1.0).toDouble();
}

/// Die Position der gewählten Option in der Optionsliste, auf 0,0 bis 1,0
/// gestreckt.
///
/// Das ist die Größe, die der Straightlining-Index braucht: *wo* jemand tippt,
/// nicht *was* das bedeutet. Wer bei fünf Fragen immer die erste Option nimmt,
/// hat hier fünfmal 0,0 — und zwar auch dann, wenn die fünfte Frage umgekehrt
/// gepolt ist und diese Antwort inhaltlich das Gegenteil der ersten vier sagt.
double? optionPosition(Question question, Object? answer) {
  if (answer == null) return null;
  if (question.options.length < 2) return null;
  final index = question.options
      .indexWhere((option) => deepEquals(option.storedValue, answer));
  if (index < 0) return null;
  return index / (question.options.length - 1);
}

/// Vom normalisierten Wert auf die Skala 1,0 bis 5,0.
double toScale(double normalized) => 1 + 4 * normalized;

/// Zurück von der Skala 1,0 bis 5,0 auf 0,0 bis 1,0.
double fromScale(double score) => (score - 1) / 4;
