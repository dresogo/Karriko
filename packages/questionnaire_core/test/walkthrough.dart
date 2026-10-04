import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

/// Ein vollständiger Durchlauf durch den Bogen, verglichen mit einem Drehbuch.
class Walkthrough {
  final Answers answers;
  final List<String> asked;

  const Walkthrough(this.answers, this.asked);
}

/// Läuft den Bogen ab, wie ein Azubi ihn abliefe: immer die nächste
/// unbeantwortete Frage.
///
/// Das Drehbuch ist die Behauptung, welche Fragen erscheinen. Eine Frage, die
/// auftaucht und nicht darin steht, lässt den Test scheitern — und eine Frage
/// im Drehbuch, die nie kommt, ebenso. Damit prüft ein Aufruf beides zugleich:
/// **was erscheint und was nicht.**
Walkthrough walk(QuestionnaireFlow flow, Map<String, Object?> script) {
  var answers = const Answers.empty();
  final asked = <String>[];

  while (true) {
    final next = flow.nextUnanswered(answers);
    if (next == null) break;
    if (!script.containsKey(next.id)) {
      fail('Unerwartete Frage "${next.id}".\n'
          'Bis dahin: ${asked.join(' → ')}');
    }
    asked.add(next.id);
    answers = answers.set(next.id, script[next.id]);
  }

  final nieGefragt = [
    for (final id in script.keys)
      if (!asked.contains(id)) id,
  ];
  expect(
    nieGefragt,
    isEmpty,
    reason: 'Im Drehbuch, aber nie gefragt: ${nieGefragt.join(', ')}',
  );

  return Walkthrough(answers, asked);
}
