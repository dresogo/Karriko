import '../condition/condition.dart';
import '../flow/answers.dart';
import '../model/question.dart';
import '../model/questionnaire.dart';

/// Die Angaben, die veröffentlicht werden.
///
/// Die Zuordnung steht **in der Definition**: Jede Frage mit `"public": true`
/// trägt in `config.publicField` ihr Zielfeld. Eine Angabe zu veröffentlichen
/// oder zurückzuziehen ist damit eine Änderung an der Definition und keine am
/// Code.
///
/// Steht hier und nicht in der Oberfläche, weil zwei Seiten dasselbe Ergebnis
/// brauchen: Der Client zeigt in A4 die Vorschau, die Function schreibt daraus
/// `public_reviews`. Zwei Umsetzungen wären zwei Ergebnisse — und dann
/// verspräche die Vorschau etwas, das die Veröffentlichung nicht hält.
///
/// [withdrawn] sind die Blöcke, die der Azubi in der Vorschau zurückgenommen
/// hat. „Jeder Block ist einzeln zurücknehmbar" heißt: nicht alles oder nichts.
Map<String, Object?> publicFields(
  Questionnaire questionnaire,
  Answers answers, {
  Set<String> withdrawn = const {},
}) {
  final out = <String, Object?>{};

  for (final question in questionnaire.questions) {
    if (!question.public) continue;
    if (withdrawn.contains(question.id)) continue;

    final feld = question.config['publicField'];
    if (feld is! String) continue;

    final wert = answers[question.id];
    if (!AnsweredCondition.isAnswered(wert)) continue;

    if (feld == freitextField) {
      final felder = _textFelder(question);
      if (wert is! Map) continue;
      final gut = wert[felder.elementAtOrNull(0)];
      final schlecht = wert[felder.elementAtOrNull(1)];
      if (gut is String && gut.trim().isNotEmpty) {
        out[freitextGutField] = gut.trim();
      }
      if (schlecht is String && schlecht.trim().isNotEmpty) {
        out[freitextSchlechtField] = schlecht.trim();
      }
      continue;
    }

    // Die Reihenfolge der Fragen entscheidet bei doppelter Belegung: Der
    // Korrekturregler aus A2 steht hinter K6 und überschreibt ihn deshalb.
    // Genau das ist sein Zweck.
    out[feld] = wert;
  }

  return out;
}

/// Die Feld-Kennungen eines Textfeldpaars, in der Reihenfolge der Definition.
/// Das erste ist das gute, das zweite das schlechte — so steht es in A1.
List<String> _textFelder(Question question) {
  final roh = question.config['fields'];
  if (roh is! List) return const [];
  return [
    for (final eintrag in roh)
      if (eintrag is Map && eintrag['id'] is String) eintrag['id']! as String,
  ];
}

/// Der Wert von `publicField`, der ein Textfeldpaar bezeichnet.
const freitextField = 'freitext';

/// Wohin die beiden Freitexte gehen. Getrennte Felder, weil die Moderation
/// beide einzeln sehen und einzeln beanstanden können muss.
const freitextGutField = 'freitext_gut';
const freitextSchlechtField = 'freitext_schlecht';
