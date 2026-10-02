# Der Bewertungsfragebogen: was gebaut wurde und warum

Stand: 1. Oktober 2026. Sechs Etappen, nichts gegen das Produktivprojekt
ausgeführt. Abschnitt 6 nennt zwei Befunde, die erst mit dem tatsächlichen
Stand der Datenbank sichtbar wurden.

Dieser Bericht ist für den Zeitpunkt geschrieben, an dem jemand — du in einem
halben Jahr, oder jemand anders — wissen will, warum etwas so ist. Er nennt auch,
was nicht funktioniert und was offen ist.

Die fachliche Quelle ist und bleibt [`karriko-fragebogen.md`](karriko-fragebogen.md).
Der freigegebene Plan mit den Abweichungen A1–A15 und den Annahmen steht in
[`PLAN_FRAGEBOGEN.md`](PLAN_FRAGEBOGEN.md). Das *Warum* der Appwrite-Einrichtung
steht in [`APPWRITE_SETUP.md`](APPWRITE_SETUP.md), die Befehlsfolge zum
Abarbeiten in [`APPWRITE_EINSPIELEN.md`](APPWRITE_EINSPIELEN.md).

## Inhalt

1. [Die eine Entscheidung, aus der alles folgt](#1-die-eine-entscheidung-aus-der-alles-folgt)
2. [Was wo liegt](#2-was-wo-liegt)
3. [Die drei Schichten](#3-die-drei-schichten)
4. [Entscheidungen, die Erklärung brauchen](#4-entscheidungen-die-erklärung-brauchen)
5. [Was die Spezifikation verlangt und wie es umgesetzt ist](#5-was-die-spezifikation-verlangt-und-wie-es-umgesetzt-ist)
6. [Die Widersprüche in der Spezifikation](#6-die-widersprüche-in-der-spezifikation)
7. [Was geprüft ist](#7-was-geprüft-ist)
8. [Was nicht geht](#8-was-nicht-geht)
9. [Was offen ist](#9-was-offen-ist)
10. [Wo Vorsicht geboten ist](#10-wo-vorsicht-geboten-ist)

---

## 1. Die eine Entscheidung, aus der alles folgt

**Kein Fragetext steht im Dart-Code.** Der Fragebogen ist eine versionierte
JSON-Datei, und der Code weiß nur, wie man sie liest.

Das war eine Vorgabe, aber es ist auch die Entscheidung, an der fast alles andere
hängt:

* Eine neue Fassung wird ausgerollt, ohne die App neu zu bauen.
* Eine begonnene Bewertung bleibt bei ihrer Fassung. Wer unter v1 angefangen hat,
  füllt v1 zu Ende.
* Der Server prüft eine Einreichung gegen **genau die Fassung**, die der Azubi
  gesehen hat — nicht gegen die aktive. Sonst würden gültige Antworten abgelehnt
  oder ungültige durchgelassen.
* Die Bedingungen, wann eine Frage erscheint, stehen als Daten da und nicht als
  `if`. Es gibt eine kleine Bedingungssprache:
  `all any not eq neq in gt gte lt lte answered selected ranked_top`.
* Und: Was ein Test prüft, ist der echte Fragebogen. Nicht ein Nachbau davon.

Die Folge davon ist, dass `packages/questionnaire_core` alles Wesentliche enthält
und **weder Flutter noch Appwrite kennt**. Es ist reines Dart. Client und Server
binden dasselbe Paket ein. Dass beide zum selben Ergebnis kommen, ist deshalb
keine Absprache zwischen zwei Umsetzungen.

## 2. Was wo liegt

```
packages/questionnaire_core/     Fragebogenlogik. Reines Dart, keine Laufzeit-Abhaengigkeit.
packages/karriko_functions/      Appwrite-Kleber fuer die Functions, ohne Flutter.
appwrite/functions/<sechs>/      Je ein Dart-Paket, je eine lib/main.dart.
appwrite/questionnaires/         Die Definition, wie sie in den Bucket geht.
appwrite/appwrite.config.template.json   CLI-Konfiguration mit Platzhaltern.
karriko_flutter/assets/questionnaire/    Dieselbe Definition als Asset (Rueckfall).
karriko_flutter/lib/presentation/questionnaire/   Die Strecke und 16 Fragetypen.
tools/                           Acht Werkzeuge, sieben davon mit --pruefen.
notes/                           Plan, diese Berichte, die Anleitung.
```

### Die acht Werkzeuge

| Werkzeug | Wofür |
|---|---|
| `sync_questionnaire.dart` | Hält Asset und Storage-Kopie zeichengleich |
| `vendor_core.dart` | Kopiert die gemeinsamen Pakete in jede Function |
| `appwrite-config.mjs` | Erzeugt `appwrite.config.json` aus der Vorlage |
| `appwrite-function-env.mjs` | Schreibt die `.env` je Function |
| `appwrite-setup.mjs` | Legt Tabellen, Spalten, Indizes und Buckets an |
| `appwrite-purge-reviews.mjs` | Löscht die Altdaten, mit Export und zwei Schaltern |
| `import_berufe.dart`, `review_texte.dart` | Berufsliste, Textprüfung |

Sieben davon haben ein `--pruefen`, das nichts ändert und mit Code 1 endet, wenn
etwas veraltet ist. Das achte, `appwrite-purge-reviews.mjs`, ist ohne Schalter
ohnehin ein Probelauf. Vor einem Push von Hand:

```bash
dart run tools/sync_questionnaire.dart --pruefen
dart run tools/vendor_core.dart --pruefen
node tools/appwrite-config.mjs --pruefen
node tools/appwrite-function-env.mjs --pruefen
node tools/appwrite-setup.mjs --pruefen
```

In der CI laufen davon nur die ersten und der letzte im Prüfmodus. Die drei
dazwischen vergleichen gegen Dateien, die in der `.gitignore` stehen und in
einem frischen Checkout nicht existieren; dort laufen sie im Erzeugen-Modus.
Beschrieben in `.github/workflows/dart.yml`.

## 3. Die drei Schichten

**Eins: die Definition.** Eine JSON-Datei, gegen ein JSON-Schema geprüft, in dem
`additionalProperties: false` steht — ein verschriebener Schlüssel fällt beim
Laden auf und nicht im Betrieb. Jede Verweisung auf eine Frage, eine Antwort oder
eine Dimension wird beim Parsen aufgelöst; eine Definition mit einem Tippfehler in
einer Frage-ID lädt nicht.

**Zwei: die Anzeige.** Eine Registry bildet 16 Typschlüssel auf Widgets ab. Der
Typ ist eine Zeichenkette in der Definition, kein Dart-Enum: Ein neuer Fragetyp
ist ein neuer Eintrag in der Registry und eine neue Fassung der Definition, nicht
ein Umbau.

Fünf Typen baut der Bildschirm selbst, weil sie mehr brauchen als die Frage:
`intro`, `anonymity_notice`, `module_teaser`, `preview`, `verification`.

Ein unbekannter Typ zeigt im Debug-Build einen Fehlerkasten und wird im
Release-Build übersprungen und gemeldet. Nicht abgestürzt: Eine unbekannte Frage
soll einen laufenden Bogen nicht anhalten.

**Drei: die Auswertung.** Sie läuft ausschließlich auf dem Server. Der Client
rechnet für die Anzeige mit derselben Funktion, aber was gespeichert wird, rechnet
`submit_review` neu. Ein Score, den man sich selbst setzen kann, sagt nichts.

## 4. Entscheidungen, die Erklärung brauchen

### Der Schieberegler hat keinen Griff, bis man ihn anfasst

`vas_unnumbered` zeigt keine Zahl und keinen Griff, solange niemand ihn berührt,
angeklickt oder mit der Tastatur angesprochen hat. Es gibt nur zwei Endbeschriftungen.

Ein Griff in der Mitte wäre eine Vorgabe, und eine Vorgabe ist eine Antwort, die
niemand gegeben hat — sie zieht jede Bewertung zur Mitte. Eine Zahl wäre eine
Einladung, in Schulnoten zu denken.

Über die Tastatur geht es, und der erste Tastendruck landet auf der Mitte. Das ist
asymmetrisch — mit der Maus landet man dort, wo man klickt — und im Code
vermerkt. Für Screenreader nennt `Semantics` einen Prozentwert; sichtbar ist er
nirgends.

### Es gibt zwei Freitextfelder, nicht eins

Eines für das Gute, eines für das Schlechte. Ein einzelnes Feld füllen Leute
entweder mit Lob oder mit Klage, je nach Tagesform. Zwei Felder fragen nach beidem,
und **auch eine sehr schlechte Bewertung wird nach dem Guten gefragt.** Die
Moderation kann sie außerdem einzeln beanstanden.

### Qualitäts-Flags löschen nie

Sechs Flags: `too_fast`, `straightlining`, `inconsistent_pair`,
`overall_detail_mismatch`, `impossible_combination`, `text_needs_review`. Keines
löscht etwas, keines lehnt etwas ab. Sie leiten in die Moderation.

Automatisches Löschen trifft erfahrungsgemäß vor allem die ausführlichen,
ehrlichen Bewertungen: Wer viel schreibt, schreibt eher etwas, das ein Filter
anspringt.

`straightlining` feuert **nur**, wenn im betrachteten Satz eine umgekehrt gepolte
Frage steckt. Ohne sie wäre es kein Durchklicken, sondern möglicherweise eine
Bewertung, bei der alles wirklich gleich ist.

### Der Gesamtscore steht erst ab drei Bewertungen, Zahlen erst ab fünf

Und Zahlen nur in Spannen. **Der genaue Mittelwert wird nicht gespeichert.** Aus
„durchschnittlich 847 €" und der Zahl der Bewertungen ließe sich eine einzelne
Angabe zurückrechnen, sobald eine dazukommt — und dann wäre die Aggregation keine.

Unter der Schwelle steht `null` in `company_scores`, nicht ein Wert mit
Warnhinweis. Ein Wert, den man nicht zeigen darf, wird nicht berechnet und
weggeblendet, sondern nicht hingeschrieben.

### Die Berufsschule steht getrennt

Sie fließt nicht in den Betriebsscore. Ein Betrieb kann nichts dafür, welche
Berufsschule zuständig ist.

### `public_reviews` ist eine eigene Tabelle, keine gefilterte Sicht

**Appwrite vergibt Rechte pro Zeile, nicht pro Spalte.** Läge alles in `reviews`,
müsste entweder die Nutzerkennung öffentlich lesbar sein oder die Bewertung
unsichtbar. Es gibt keinen Mittelweg.

Also zwei Tabellen. `reviews` hat **keine Rechte** — kein Client liest dort, auch
der Verfasser nicht.

### Das Vendoring

Appwrite lädt beim Deployment nur das Verzeichnis der Function hoch. Eine
Pfadabhängigkeit nach `../../packages/questionnaire_core` zeigt im Build ins
Leere.

Verworfen: eine Git-Abhängigkeit (koppelt jedes Deployment an einen vorher
gepushten Commit, und Pushen braucht deine Ansage), `providerRootDirectory` auf die
Repository-Wurzel (lädt das ganze Repo sechsmal hoch), Veröffentlichen auf pub.dev
(kommt für internen Code nicht infrage).

Gewählt: kopieren, mit einer Inhaltsmarke je Kopie und einem Prüflauf, der mit
Code 1 endet, wenn eine Function mit veralteter Logik laufen würde. Kostet einen
Schritt vor dem Push, braucht kein Netz, ist reproduzierbar.

### `aggregate_company` wird von `public_reviews` ausgelöst, liest aber `reviews`

Sieht nach einem Widerspruch aus und ist keiner. Die Gewichte des Gesamtscores
entstehen aus den aggregierten K12-Prioritäten, und die stehen in den
Rohantworten. Sie nach `public_reviews` zu kopieren hieße, drei von acht
Prioritätskarten je Azubi zu veröffentlichen.

### `recompute_all` merkt sich den Fortschritt nicht

Der Plan sah eine Zeile in `company_scores` dafür vor. Umgesetzt ist ein `offset`
in Aufruf und Antwort: kein Zustand, der zwischen zwei Läufen veralten kann.
Dokumentierte Abweichung vom Plan.

### Die Prüfsumme wird nur serverseitig geprüft

In `questionnaire_releases` steht eine SHA-256-Summe, und `DefinitionLoader`
lehnt eine Datei ab, die nicht dazu passt. Die Versionsnummer allein fängt den
Fall nicht: Zwei Dateien können dieselbe Version nennen und verschiedene
Punktwerte tragen.

Der Client prüft sie **nicht**, und das ist richtig: Seine Fassung bestimmt nur,
was angezeigt wird. Jeder Wert wird serverseitig gegen die Fassung neu gerechnet,
die der Server lädt und verifiziert. Eine Prüfung im Client hätte eine
Abhängigkeit mehr gekostet und nichts gesichert.

Dafür steht in der `.gitattributes` `eol=lf` für die beiden Definitionsdateien.
Ohne das hätte dieselbe Datei unter Windows eine andere Summe als unter Linux, und
die Summe wäre an den Rechner gebunden, auf dem sie berechnet wurde.

### Vier Dinge sind aus dem Code in die Definition gewandert

`publicField` (welche Antwort öffentlich wird), `publishActions` (wann verschoben
wird), `visibility.numberSources` (welche Zahlen in Spannen erscheinen) und
`flow.inviteSources` (welche Einladungsquellen gelten). Sie standen sonst an zwei
Stellen.

Die Einladungsquelle prüft jetzt der Server. Der Client prüfte sie schon, aber
ein Client ist kein Argument: Die Markierung „kam über eine Einladung" ließe sich
sonst über eine selbstgebaute Adresse erschleichen, und angeforderte Bewertungen
fallen systematisch anders aus als spontane.

### Keine Antwort des Betriebs

Abschnitt 11 der Spezifikation lässt offen, ob Betriebe auf eine Bewertung
antworten dürfen. Das zu bauen hieße, die Frage zu entscheiden. Der Client hat
außerdem kein Schreibrecht auf `reviews`, also hätte es eine eigene Tabelle und
eine eigene Function gebraucht.

## 5. Was die Spezifikation verlangt und wie es umgesetzt ist

| Verlangt | Umgesetzt |
|---|---|
| Kein Fragetext im Dart-Code | Definition als JSON, Registry über Typschlüssel |
| Keine Umformulierung der Texte | Texte zeichengleich übernommen; ein Test vergleicht Asset und Storage-Kopie byteweise |
| Keine Secrets im Code | Salz aus der Umgebung, ohne Salz wird nicht gehasht; kein eingebauter Ersatzwert |
| Keine IP-Adressen | Nirgends gespeichert |
| Gerätekennung nur als gesalzener Hash | `hashDeviceKey`, sha256 über `salz:kennung`, gibt ohne Salz `null` |
| Keine echten Schlüssel oder IDs im Repository | Vorlage mit Platzhaltern; die eingebauten Standardwerte in `appwrite-setup.mjs` sind entfernt |
| Jede Interaktion ohne Gesten | Schieberegler per Tastatur, Wischkarten mit sichtbaren Knöpfen, Ranking per Antippen und Listenreihenfolge |
| Hohe Testabdeckung für `questionnaire_core` | 287 Tests |
| Widget-Tests für die drei besonderen Typen | `vas_unnumbered`, `swipe_binary`, `rank_top_n` |
| Rechtliche Aussagen nicht erfinden | Fünf markierte Platzhalter, in der Anleitung namentlich aufgeführt |
| Keine Befehle gegen das Live-Projekt | Nichts ausgeführt, nichts gepusht |

## 6. Die Widersprüche in der Spezifikation

### K10 war falsch gepolt — gemeldet und entschieden

Abschnitt 9 sagt, der Straightlining-Index funktioniere „nur dank der gemischten
Polung". Abschnitt 4 listete die Antworten von K10 aber so, dass Position 1 die
gute Antwort ist — genau wie bei K7 bis K11. Damit hätte der Index nie anspringen
können.

Gemeldet, deine Entscheidung: **K10 umdrehen.** Die Texte stehen unverändert, die
Reihenfolge ist gedreht. Ein Test hält es fest: `k10.options.first.score == 0.0`,
während `k7.options.first.score == 1.0`.

### Die alte `reviews` hätte jede Einreichung abgelehnt

Aufgefallen am 1. Oktober 2026, als der tatsächliche Stand der Datenbank vorlag
— nicht beim Bauen, und das ist der eigentliche Befund.

Die bestehende Tabelle hat fünf Pflichtspalten, die `submit_review` nie
schreibt (`author_id`, `is_anonymous`, `overall_rating`, `title`, `text`), und
ihr `status` ist ein **Enum** mit `pending | published | rejected`. Der Code
schreibt `pending_moderation`, `scheduled`, `approved`, `rejected`. Appwrite
lehnt einen Insert ohne Pflichtspalte ab, und drei der vier Statuswerte sind
ungültig. Es wäre also nicht eine Bewertung durchgekommen.

**`tools/appwrite-setup.mjs` hätte das nicht gemeldet.** Es legt nur fehlende
Spalten an und rührt vorhandene nicht an. Das war als Vorsicht gedacht — nichts
wegnehmen, was da ist — und wurde hier zum Fehler: Danach hätte alles grün
ausgesehen und nichts funktioniert. Eine Prüfung, die nur ergänzt, prüft nicht.

Die Tabelle hat null Zeilen. Entscheidung vom 1. Oktober 2026: **löschen und neu
anlegen.** Damit fallen auch die Namensdopplungen weg (`author_id`/`user_id`,
`pros`/`cons` gegen `freitext_gut`/`freitext_schlecht`, `profession` gegen
`beruf_name`) und `author_name`, das trotz `is_anonymous` gespeichert wurde.

Nebenwirkung: `tools/appwrite-purge-reviews.mjs` hat nichts zu löschen. Das
Werkzeug bleibt als Vorsorge, die Aufgabe ist erledigt, ohne dass etwas gelöscht
werden muss.

### Die Betriebsliste sortierte nach einem toten Feld

Auch am 1. Oktober aufgefallen, und diesmal war es meine Änderung: Etappe C hat
die Anzeige auf `company_scores` umgestellt, aber `company_repository` sortiert
und filtert weiter über `companies.average_rating`. Das schreibt seit der
Umstellung niemand mehr. „Beste zuerst" sortierte also nach dem Anfangswert, und
der Bewertungsfilter filterte auf nichts.

Entscheidung: **`aggregate_company` spiegelt den Score nach `companies`.**
Begründung in `APPWRITE_SETUP.md` Abschnitt 4a, kurz: Appwrite sortiert nicht
über zwei Tabellen hinweg, und der Weg über `company_scores` mit anschließendem
Nachladen würde alle Betriebe unter drei Bewertungen aus der Sortierung werfen —
also die meisten.

Der Preis ist eine Kopie, die gepflegt werden muss, und er wird dadurch höher,
dass `companies` im Bestand `update("users")` ohne Row Security hatte: Jeder
Angemeldete durfte jede Firma ändern. Das Skript zieht das jetzt enger (Recht
weg, Row Security an, Änderungsrecht pro Zeile beim Eigentümer).

**Nicht behoben:** Der Eigentümer kann auf seiner eigenen Zeile `is_verified` und
`average_rating` setzen. Appwrite kennt keine Rechte je Spalte. Gemildert durch
zweierlei und behoben durch keines: `aggregate_company` überschreibt den Wert bei
der nächsten Änderung, und der angezeigte Score kommt aus `company_scores`, das
kein Client schreiben kann. Eine Manipulation wirkt auf die Sortierung und nur
bis zur nächsten Aggregation. Die Lösung wäre, Profiländerungen über eine
Function zu führen — siehe Abschnitt 9.

### Die vier Fragen aus dem Plan

Beantwortet am 21. September 2026, in `PLAN_FRAGEBOGEN.md` Abschnitt 8
festgehalten: Altstrecke ersetzen, alte Zeilen löschen, IDs als eigene Aufgabe,
Dokumentation nach `notes/`.

Bei „alte Zeilen löschen" habe ich widersprochen und es dann so gebaut, wie du
entschieden hast — aber **nicht ausgeführt.** `appwrite-purge-reviews.mjs` ist ein
dokumentierter Schritt von Hand, mit Probelauf als Standard, Pflicht-Export vor dem
Löschen und einer erwarteten Zeilenzahl, die stimmen muss.

Wie sich am 1. Oktober zeigte, gibt es keine alten Zeilen: `reviews` ist leer.
Der Widerspruch war damit gegenstandslos, und das Werkzeug bleibt Vorsorge.

## 7. Was geprüft ist

| | |
|---|---|
| `questionnaire_core` | 287 Tests |
| `karriko_functions` | 36 Tests |
| `karriko_flutter` | 211 Tests |
| Analyse | Beide Pakete, alle sechs Functions, die App: keine Befunde |

Was diese Tests besonders macht: Sie laufen gegen die **echte** v1, nicht gegen
einen Testfragebogen. Vier Personas gehen die Strecke durch und prüfen, welche
Fragen erscheinen, in welcher Zeitform, welche Module angeboten werden, welche
Werte herauskommen und welche Flags feuern.

Die 36 Tests in `karriko_functions` prüfen, **was gespeichert würde, ohne es zu
speichern**: `buildReviewRow`, `buildPublicReviewRow`, `buildCompanyScoresRow`,
`decidePublishing`, `hashDeviceKey` sind reine Funktionen ohne Netzzugriff. Der
wichtigste davon prüft, dass in `public_reviews` **keine** `user_id`, keine
Rohantworten, keine Zeiten, keine Flags und kein Gerätehash landen.

### Was nicht geprüft ist

* **Nichts lief gegen Appwrite.** Kein Push, kein Deployment, keine echte
  Ausführung einer Function. Die CLI-Konfiguration ist aus der Dokumentation und
  aus der installierten CLI 27.3.0 gebaut, nicht aus einem `appwrite pull`.
* **Die Scope-Namen sind teils begründet, nicht belegt.** Dass es `rows.read` und
  `rows.write` heißt und nicht `documents.*`, ist belegt. `files.read`,
  `files.write` und `teams.read` sind plausibel und ungeprüft. Verbindlich ist die
  Liste in der Console.
* **`specification` ist nicht gesetzt**, damit kein erfundener Wert den Push
  scheitern lässt.
* **Eine Function lokal auszuführen** ginge nur mit der open-runtimes-Umgebung in
  Docker. Die Logik dahinter ist ohne Docker geprüft; was ein lokaler Lauf
  zusätzlich zeigt, ist das Zusammenspiel mit Appwrite — und das prüft der
  Abnahmetest in der Anleitung.

## 8. Was nicht geht

Ehrliche Liste.

* **Ein Azubi kann seine abgeschickten Bewertungen nur lokal wiederfinden.** Die
  Liste liegt in `shared_preferences` im Browser. Das ist der Preis dafür, dass
  `public_reviews` keine `user_id` trägt — und diese Verknüpfung darf es nicht
  geben. Wer den Browser wechselt, sieht seine Bewertungen nicht mehr.
* **Es gibt keinen Moderationsbildschirm.** `moderate_review` wird über die
  Console oder einen eigenen Aufruf ausgelöst.
* **Die Moderation sieht den Verifikationsnachweis nur über die Console.** Es gibt
  keine Function, die ihn ausliefert, und das ist gewollt vorsichtig — aber es
  bedeutet, dass die Moderation zwei Werkzeuge braucht.
* **Kein Löschverlangen.** Es gibt keinen Weg, auf Wunsch eines Nutzers seine
  Bewertung zu entfernen. `reviews` findet sie über `user_id`, aber das Löschen
  dort lässt die öffentliche Zeile stehen. **Das ist die größte offene Lücke.**
* **Kein Auskunftsverlangen.** Dasselbe Problem, dieselbe Ursache.
* **Ein Betrieb kann sein eigenes `is_verified` und `average_rating` setzen.**
  Appwrite kennt keine Rechte je Spalte, und die Profilbearbeitung läuft direkt
  gegen die Tabelle. Das Abzeichen soll ein Mensch vergeben; heute kann es sich
  jeder Betrieb selbst geben.
* **`companies` steht nicht in der CLI-Konfiguration**, weil ich die Tabelle
  nicht vollständig kenne. Ein Push würde sie nach einer Teilbeschreibung
  umschreiben. Sie läuft über `tools/appwrite-setup.mjs`, das nur ergänzt.
* **Wertgrenzen auf bestehenden Spalten lassen sich nicht nachtragen.**
  `companies.average_rating` hat keine; das Skript kann eine vorhandene Spalte
  nicht ändern. Dafür müsste man sie löschen und neu anlegen.
* **Ein Betrieb kann nicht antworten.** Siehe Abschnitt 4.
* **`recompute_all` stößt `aggregate_company` nicht selbst an.** Es nennt die
  betroffenen Betriebe in der Antwort; anstoßen muss man sie.

## 9. Was offen ist

### Deine Entscheidung

**`my_reviews` als siebte Function?** Zweimal gefragt, zweimal offen geblieben.
Sie würde die serverseitige Liste der eigenen Bewertungen möglich machen, ohne
`public_reviews` zu ändern: Sie liest `reviews` über die `user_id` aus dem JWT und
gibt nur zurück, was der Verfasser über seine eigene Bewertung wissen darf.

Das ist der saubere Weg. Er ist nicht gebaut, weil sechs Functions beauftragt
waren und eine siebte eine Entscheidung ist.

Sie wäre außerdem die Grundlage für ein Löschverlangen — dieselbe Zuordnung, die
sie braucht.

### Juristisch zu prüfen

Acht Punkte, in `APPWRITE_SETUP.md` Abschnitt 12 mit ⚖️ markiert, hier nur
aufgezählt: die Aufbewahrungsfristen für Nachweise, Entwürfe, Rohantworten, den
Gerätehash und den Export aus der Altdatenlöschung; Löschverlangen und
Auskunftsverlangen; die fünf Platzhaltertexte im Fragebogen.

**Zu keinem dieser Punkte steht im Code oder in der Dokumentation eine rechtliche
Aussage.** Die Fristen haben Standardwerte, weil eine Function ohne Frist nicht
läuft — nicht, weil diese Werte richtig wären.

### Technisch offen

* Das `module_verguetung` ist per Feature-Flag aus.
* Die Berufsliste kommt aus einer Beispielliste. `import_berufe.dart` steht bereit
  für die amtlichen Schlüssel; solange sendet der Client nur den Namen und
  `beruf_code` bleibt leer.
* Kein Bildschirm für die Meldungen aus `review_reports`.

## 10. Wo Vorsicht geboten ist

Die Stellen, an denen eine naheliegende Änderung etwas kaputt macht.

**Alte Versionen der Definition nie löschen.** Weder die Datei im Bucket noch die
Zeile in `questionnaire_releases`. Eine Bewertung mit `schema_version: 1` lässt
sich ohne v1 nicht neu rechnen, und `recompute_all` überspringt sie dann.

**`vendor/` vor jedem Push erneuern.** Sonst läuft eine Function mit veralteter
Logik, und zwar still. Dagegen gibt es `--pruefen` vor dem Push; in der CI wird
kopiert und danach geprüft, weil `vendor/` dort nicht im Checkout liegt.

**Die erzeugten Dateien nicht bearbeiten.** `appwrite/appwrite.config.json` und
die `.env` je Function werden überschrieben. Änderungen gehören in
`appwrite.config.template.json` bzw. in die Umgebung.

**`reviews` vor dem ersten Push löschen.** Steht die alte Tabelle noch da,
schreibt der Push die neuen Spalten daneben, und die Pflichtspalten der alten
Strecke lassen jede Einreichung scheitern. Das Setup-Skript meldet es nicht — es
ergänzt nur.

**`companies` nicht mit der CLI pushen.** Die Tabelle steht nicht in der
Konfiguration, weil ich sie nicht vollständig kenne. Ein Push würde sie nach
einer Teilbeschreibung umschreiben.

**`companies.average_rating` nicht von Hand setzen.** `aggregate_company`
überschreibt es bei der nächsten Änderung. Der verbindliche Wert steht in
`company_scores`.

**Das Salz nicht ohne Grund ändern.** Alte Hashes passen danach nicht mehr zu
neuen. Sie werden nicht falsch, nur unvergleichbar.

**Die beiden Definitionsdateien nur über `sync_questionnaire.dart` gleichhalten**,
und die Prüfsumme immer auf der Datei berechnen, die hochgeladen wird. Sie ist
byteweise.

**Rechte in `reviews` und `public_reviews` nicht weiten.** `reviews` hat
absichtlich keine. Ein Leserecht dort gibt Rohantworten, Bearbeitungszeiten,
Gerätehash und Nutzerkennung mit heraus. `node tools/appwrite-setup.mjs` meldet
es, wenn dort ein Recht steht, das nicht hingehört.

**Keine Pflichtspalte in `reviews` nachrüsten**, solange dort Zeilen ohne Wert
stehen. Es scheitert, und es ergänzt nichts: Geschrieben wird dort nur von
`submit_review`.
