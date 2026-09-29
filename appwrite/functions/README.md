# Die Appwrite Functions von Karriko

Sechs Functions in Dart. Jede ist ein eigenes Dart-Paket, weil Appwrite pro
Deployment **nur ein Verzeichnis** hochlädt.

| Function | Auslöser | Wer darf | Wofür |
|---|---|---|---|
| `submit_review` | Aufruf | angemeldete Nutzer | Die einzige Stelle, an der eine Bewertung entsteht |
| `moderate_review` | Aufruf | `moderators`, `admins` | Freigeben oder ablehnen; bei Freigabe entsteht die öffentliche Zeile |
| `aggregate_company` | Änderung an `public_reviews` | — | Rechnet `company_scores` neu |
| `publish_scheduled` | Cron, stündlich | — | Gibt zurückgestellte Bewertungen in die Moderation |
| `recompute_all` | Aufruf | `admins` | Rechnet alles mit den aktuellen Parametern neu, in Etappen |
| `cleanup` | Cron, täglich | — | Verwaiste Entwürfe und geprüfte Nachweise |

Runtime, Entrypoint, Variablen, Scopes und Cron-Ausdrücke stehen in
[`appwrite.config.template.json`](../appwrite.config.template.json) und mit
Erklärung in [`notes/APPWRITE_SETUP.md`](../../notes/APPWRITE_SETUP.md).

## Vor jedem Push: drei Schritte

```bash
dart run tools/vendor_core.dart
node tools/appwrite-config.mjs
node tools/appwrite-function-env.mjs
```

Der erste kopiert die gemeinsamen Pakete (unten), der zweite erzeugt
`appwrite/appwrite.config.json` aus der Vorlage, der dritte die `.env` je
Function. Alle drei haben `--pruefen`, und alle drei erzeugen Dateien, die nicht
ins Repository gehören: Die Konfiguration trägt die echte Projekt- und
Datenbankkennung, die `.env` von `submit_review` das Salz für den Gerätehash.

## Das vendoring

Die Functions benutzen zwei gemeinsame Pakete:

* **`questionnaire_core`** — die Fragebogenlogik, dieselbe, die auch der Client
  benutzt. Dass Client und Server dasselbe rechnen, ist deshalb keine
  Absprache zwischen zwei Umsetzungen, sondern dasselbe Paket.
* **`karriko_functions`** — Appwrite-Kleber: Konfiguration, Tabellenzugriff,
  Laden der Definition, Abbildung zwischen Zeilen und Modellen.

Beide liegen unter `packages/` und werden nach `<function>/vendor/` kopiert. Eine
Pfadabhängigkeit auf `../../packages/…` zeigte im Build ins Leere, weil Appwrite
nur das Function-Verzeichnis hochlädt.

`vendor/` steht in `.gitignore` und gehört nicht ins Repository. Damit eine
Function nicht still mit veralteter Logik läuft, trägt jede Kopie eine Marke, und

```bash
dart run tools/vendor_core.dart --pruefen
```

endet mit Code 1, wenn eine davon abweicht. Das gehört vor jeden Push und in
die CI.

## Was hier absichtlich nicht steht

Die Teile, die etwas **entscheiden**, stehen in `packages/karriko_functions` als
reine Funktionen ohne Netzzugriff: `buildReviewRow`, `buildPublicReviewRow`,
`buildCompanyScoresRow`, `aggregateInputFromRow`, `decidePublishing`,
`hashDeviceKey`. Nur so lässt sich prüfen, was gespeichert würde, ohne es zu
speichern — und genau das tut `packages/karriko_functions/test/`.

Was in `lib/main.dart` einer Function steht, ist Reihenfolge: prüfen, laden,
rechnen lassen, schreiben, antworten.

## Lokal prüfen

```bash
cd appwrite/functions/submit_review
dart pub get
dart analyze
```

Ausführen lässt sich eine Function lokal nur mit der open-runtimes-Umgebung
(Docker). Die Logik dahinter ist über `packages/karriko_functions` ohne Docker
geprüft; was ein lokaler Lauf zusätzlich zeigt, ist das Zusammenspiel mit
Appwrite selbst — und das prüft der Abnahmetest in der Anleitung.
