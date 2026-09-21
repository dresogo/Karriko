# questionnaire_core

Die Fragebogenlogik von Karriko. Reines Dart, ohne Flutter, ohne
Laufzeitabhängigkeiten.

Derselbe Code läuft im Browser und in der Appwrite Function. Dass Client und
Server zum selben Ergebnis kommen, ist deshalb keine Absprache zwischen zwei
Umsetzungen, sondern dieselbe.

## Drei Schichten, und dies ist die mittlere

| Schicht | Wo | Was |
|---|---|---|
| Inhalt | `questionnaire_v1.json` | Fragetexte, Optionen, Reihenfolge, Bedingungen, Gewichte, Schwellenwerte |
| Darstellung | `karriko_flutter` | ein Widget je Typkennung |
| **Logik** | **hier** | Bedingungen, Ablauf, Prüfung, Werte, Auffälligkeiten |

**In diesem Paket steht kein einziger Fragetext.** Und keine Typkennung: Welche
Widgets es gibt, weiß das Paket nicht und muss es nicht wissen — Prüfung und
Auswertung lesen `options` und `config`, nicht `type`. Ein neuer Widget-Typ in
der Flutter-Schicht erzwingt hier keine Änderung.

Genauso steht **kein Grenzwert im Code**: Schwellen, Untergrenzen, die Stärke
der Schrumpfung und die Alterungsgrenze kommen alle aus der Definition.

## Was drin ist

```dart
final questionnaire = Questionnaire.parseJsonString(json);
final flow = QuestionnaireFlow(questionnaire);

final naechste = flow.nextUnanswered(answers);
final module   = flow.offeredModules(answers);
final verwaist = flow.staleAnswers(answers);

final pruefung = validateSubmission(
  questionnaire: questionnaire,
  answers: answers,
);

final werte = ReviewScores.compute(questionnaire, answers);
final flags = evaluateQuality(
  questionnaire: questionnaire,
  answers: answers,
  timings: timings,
);

final aggregat = CompanyAggregate.compute(
  questionnaire: questionnaire,
  reviews: reviews,
  now: DateTime.now().toUtc(),
);
```

### Die Bedingungssprache

Deklarativ, als JSON, ohne Seiteneffekte.

```jsonc
{ "all": [
    { "gt": [ {"answer": "k3_ueberstunden"}, 0 ] },
    { "eq": [ {"answer": "s8_alltag", "field": "schicht"}, "ja" ] },
    { "ranked_top": [ {"answer": "k12_prioritaeten"}, "ausbilder", 3 ] }
] }
```

Operatoren: `all`, `any`, `not`, `eq`, `neq`, `in`, `gt`, `gte`, `lt`, `lte`,
`answered`, `selected`, `ranked_top`.
Operanden: `{"answer": "…"}` (mit optionalem `"field"` für Wischkarten),
`{"computed": "…"}`, Literale.

**Ein unbekannter Operator oder ein Verweis auf eine Frage, die es nicht gibt,
fliegt beim Laden auf — nicht zur Laufzeit im Formular.** Das ist der Zweck der
Prüfung in `Questionnaire.parse`: Ein verschriebener Verweis liefert sonst still
`null`, die Bedingung ist dann einfach falsch, die Folgefrage erscheint nie, und
niemand erfährt davon.

### Zwei Zahlen, die nicht dasselbe sind

`normalizedAnswer` gibt die **Bedeutung** einer Antwort, immer „höher ist
besser". `optionPosition` gibt die **Stelle** in der Optionsliste. Der
Straightlining-Index braucht die zweite: Wer bei K7 bis K11 immer dieselbe
Position antippt, widerspricht sich, sobald eine der Fragen umgekehrt gepolt ist
— und genau dann, und nur dann, schlägt der Index an.

## Tests

```bash
dart test
```

Neben den Einzeltests je Operator, Prüfregel und Rechenschritt laufen vier
vollständige Durchläufe (`test/personas_test.dart`), je einer pro Persona aus
dem Auftrag. Sie vergleichen die tatsächliche Strecke mit einem Drehbuch: Eine
Frage, die auftaucht und nicht im Drehbuch steht, lässt den Test scheitern —
und eine Frage im Drehbuch, die nie kommt, ebenso.

Der Testfragebogen in `test/fixture.dart` ist bewusst **nicht** die echte v1.
Ein Testfragebogen, der jede Inhaltsänderung mitmacht, prüft die Mechanik nicht
mehr, sondern nur noch sich selbst.
