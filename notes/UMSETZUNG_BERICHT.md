# Der Bewertungsfragebogen: was gebaut wurde und warum

Stand: 2. Oktober 2026, überarbeitet am 15. Oktober 2026. Sechs Etappen; das
Schema ist seit dem 2. Oktober eingespielt. Abschnitt 6 nennt zwei Befunde, die
erst mit dem tatsächlichen Stand der Datenbank sichtbar wurden.

Dieser Bericht ist für den Zeitpunkt geschrieben, an dem jemand — du in einem
halben Jahr, oder jemand anders — wissen will, warum etwas so ist. Er nennt auch,
was nicht funktioniert und was offen ist.

Die fachliche Quelle ist und bleibt [`karriko-fragebogen.md`](karriko-fragebogen.md).
Die Abweichungen A1–A15 und die Entscheidungen vom 21. September 2026 stehen in
den Abschnitten 11 und 12; der Plan, aus dem sie stammen, liegt in
[`archiv/PLAN_FRAGEBOGEN.md`](archiv/PLAN_FRAGEBOGEN.md). Die Appwrite-Einrichtung
mit Begründungen und Befehlen steht in [`APPWRITE_SETUP.md`](APPWRITE_SETUP.md).
Offene Punkte führt allein [`aufgaben-offen.md`](aufgaben-offen.md).

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
11. [Abweichungen von der Spezifikation (A1–A15)](#11-abweichungen-von-der-spezifikation-a1a15)
12. [Entscheidungen vom 21. September 2026](#12-entscheidungen-vom-21-september-2026)

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
appwrite/functions/<sieben>/     Je ein Dart-Paket, je eine lib/main.dart.
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
Repository-Wurzel (lädt das ganze Repo je Function einmal hoch), Veröffentlichen auf pub.dev
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

### `my_reviews` liest, und zwar nur

Gebaut am 2. Oktober 2026, nach dreimaligem Nachfragen entschieden.

Der Widerspruch, den sie auflöst: `public_reviews` darf keine `user_id` tragen,
sonst wäre eine veröffentlichte Bewertung keine anonyme. Auf `reviews` hat kein
Client Zugriff. Also konnte ein Azubi seine abgeschickten Bewertungen nur in dem
Browser wiederfinden, aus dem er sie abgeschickt hatte.

Die Function stellt die Zuordnung her, **ohne sie in die Datenbank zu
schreiben**: Sie entsteht aus dem geprüften JWT, nur für die Dauer eines Aufrufs.
Es gibt keinen Parameter für eine Nutzerkennung, und es darf keinen geben — das
wäre eine Einladung, die Bewertungen anderer zu lesen.

**Ihr Schlüssel hat nur `rows.read`.** Kein `files.read`, weil sie keine
Definition lädt; kein `teams.read`, weil sie keine Mitgliedschaft prüft. Eine
Function, die nur liest, kann keine Bewertung verändern. Das ist hier keine
Sparsamkeit, sondern die Eigenschaft, die sie harmlos macht.

**Die schwierigere Hälfte war, was sie nicht ausliefert.** Die Zeile enthält
mehr, als dem Verfasser gehört:

* **Keine Qualitätsmarkierungen.** Wer erfährt, dass er als Durchklicker
  markiert wurde, weiß beim nächsten Mal, wie er es vermeidet. Flags leiten in
  die Moderation; sie sind keine Rückmeldung.
* **Keine Bearbeitungszeiten.** Aus ihnen entsteht `too_fast`. Sie
  zurückzugeben hieße, die Schwelle verhandelbar zu machen.
* **Keine gerechneten Werte.** Vor der Freigabe sind sie nicht endgültig, nach
  der Freigabe stehen sie in der öffentlichen Ansicht, die der Verfasser wie
  jeder andere sieht. Zwei Darstellungen desselben Werts wären eine zu viel.
* **Nicht den Namen des Moderators.** Die Begründung einer Ablehnung gehört dem
  Verfasser, der Name nicht.

Die Begründung je Spalte steht als `withheldFromAuthor` im Code, nicht in diesem
Bericht — und ein Test geht sie durch: Jede genannte Spalte muss fehlen, und
jeder Grund muss einer sein. Der Test hat beim ersten Lauf meine eigene
Abkürzung erwischt, drei Wörter, die nichts erklärten.

**Die Begründung einer Ablehnung kommt damit erstmals beim Verfasser an.**
`moderate_review` verlangt sie seit Teil D, weil eine Ablehnung ohne Begründung
für ihn nicht nachvollziehbar wäre. Bis jetzt lag sie im `moderation_log` und
niemand sah sie.

Die lokale Liste bleibt als Rückfall, wenn der Server nicht antwortet — und der
Bildschirm sagt dann, dass sie nur dieses Gerät kennt. Zwei ungleiche Quellen
als dieselbe darzustellen wäre eine Behauptung, die nicht stimmt.

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

Beantwortet am 21. September 2026, in Abschnitt 12 festgehalten: Altstrecke ersetzen, alte Zeilen löschen, IDs als eigene Aufgabe,
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
| `karriko_functions` | 43 Tests |
| `karriko_flutter` | 211 Tests |
| Analyse | Beide Pakete, alle sieben Functions, die App: keine Befunde |

Was diese Tests besonders macht: Sie laufen gegen die **echte** v1, nicht gegen
einen Testfragebogen. Vier Personas gehen die Strecke durch und prüfen, welche
Fragen erscheinen, in welcher Zeitform, welche Module angeboten werden, welche
Werte herauskommen und welche Flags feuern.

Die 43 Tests in `karriko_functions` prüfen, **was gespeichert würde, ohne es zu
speichern**: `buildReviewRow`, `buildPublicReviewRow`, `buildCompanyScoresRow`,
`decidePublishing`, `hashDeviceKey` sind reine Funktionen ohne Netzzugriff. Der
wichtigste davon prüft, dass in `public_reviews` **keine** `user_id`, keine
Rohantworten, keine Zeiten, keine Flags und kein Gerätehash landen.

Die Zahlen sind der Stand vom 2. Oktober 2026. Aktuelle Testzahlen nennt das
README.

### Was nicht geprüft ist

* **Das Zusammenspiel mit Appwrite** über den Durchstich hinaus. Eingespielt ist
  seit dem 2. Oktober, `cleanup` lief als Probelauf durch. Der Abnahmetest mit
  den vier Personas steht aus (T-2.4).
* **`specification` ist nicht gesetzt**, damit kein erfundener Wert den Push
  scheitern lässt (T-2.22).
* **Eine Function lokal auszuführen** ginge nur mit der open-runtimes-Umgebung in
  Docker. Die Logik dahinter ist ohne Docker geprüft.

## 8. Was nicht geht

Ehrliche Liste.

* **Ein Löschverlangen bleibt offen.** `my_reviews` stellt die Zuordnung
  zwischen Konto und Bewertung her, aber nur lesend. Zu löschen hieße, die
  öffentliche Zeile mit zu entfernen, und dafür gibt es keinen Weg. Das ist
  weiter die größte offene Lücke — aber sie ist jetzt kleiner: Die Zuordnung,
  an der es fehlte, ist gebaut.
* ~~**Es gibt keinen Moderationsbildschirm.**~~ Inzwischen gibt es ihn: den
  Admin-Bereich unter `/#/admin` mit der Function `moderation_desk`.
* **Die Moderation sieht den Verifikationsnachweis nur über die Console.** Es gibt
  keine Function, die ihn ausliefert, und das ist gewollt vorsichtig — aber es
  bedeutet, dass die Moderation zwei Werkzeuge braucht.
* **Kein Auskunftsverlangen.** `my_reviews` liefert dem Verfasser, was er über
  seine eigene Bewertung wissen soll — aber bewusst nicht alles, was gespeichert
  ist. Ein Auskunftsverlangen will genau das andere, und dafür gibt es keinen
  Weg.
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

Seit dem 15. Oktober 2026 führt das allein
[`aufgaben-offen.md`](aufgaben-offen.md). Die Punkte, die hier standen:

| Punkt | Nummer |
|---|---|
| Acht Punkte juristisch prüfen (Fristen, Lösch- und Auskunftsverlangen, Fragebogentexte) | T-5.2 |
| Fünf Platzhaltertexte im Fragebogen | T-5.3 |
| Löschverlangen für einzelne Bewertungen | T-2.9 |
| Vergütungsmodul an oder aus | T-8.10 |
| Vollständige Berufsliste mit `import_berufe.dart` | T-2.30 |

**Zu keinem der juristischen Punkte steht im Code oder in der Dokumentation eine
rechtliche Aussage.** Die Fristen haben Standardwerte, weil eine Function ohne
Frist nicht läuft — nicht, weil diese Werte richtig wären.

Der Bildschirm für die Meldungen aus `review_reports` ist inzwischen der
Admin-Bereich.

## 10. Wo Vorsicht geboten ist

Seit dem 15. Oktober 2026 in [`APPWRITE_SETUP.md`](APPWRITE_SETUP.md) Abschnitt
16, weil die Warnungen beim Arbeiten am Backend gebraucht werden. Was dort
fehlt, weil es nur die Erstaufbauten betraf:

**`reviews` vor dem ersten Push löschen.** Am 2. Oktober 2026 erledigt.

## 11. Abweichungen von der Spezifikation (A1–A15)

Übernommen am 15. Oktober 2026 aus `PLAN_FRAGEBOGEN.md` §5, der seitdem im
Archiv liegt. Die Nummern bleiben, das Kürzel A ist im Factsheet (Abschnitt 10)
dafür reserviert. Die Tabelle ist der Stand vom 21. September 2026, Verweise wie
„(3.2)“ zeigen in den archivierten Plan. Was daraus geworden ist:

- **A4:** Die Schrumpfung läuft gegen `priorMean 3.2` (Factsheet E-23), ein
  echtes Branchenmittel gibt es noch nicht.
- **A5:** Umgesetzt, jeder nicht leere Freitext geht durch die Moderation
  (Factsheet E-24).
- **A6:** Umgesetzt, das Vergütungsmodul ist aus (E-25). Die Entscheidung steht
  als T-8.10 offen.
- **A7:** Offen als T-8.1.
- **A12:** Die vollständige Berufsliste steht als T-2.30 offen.
- **A14:** Umgesetzt, `ReviewCard` und `StarRating` sind entfernt (E-27).

| # | Stelle | Abweichung | Grund |
|---|---|---|---|
| A1 | Teil D, Functions in Dart | **Keine Abweichung.** Dart-Runtime `dart-3.11` ist verfügbar und passt zum lokalen SDK. | — |
| A2 | Teil A, Ort des Pakets | `packages/questionnaire_core` wie vorgeschlagen, mit Vendoring in die Functions (3.2) | Appwrite lädt nur das Function-Verzeichnis hoch |
| A3 | Teil E, CLI-Konfiguration | Ich liefere **beides**: `appwrite/appwrite.config.json` für den CLI-Push *und* die Erweiterung von `tools/appwrite-setup.mjs`. | Die CLI ist hier nicht installiert, und ein `push` gegen eine bereits befüllte Datenbank überschreibt Rechte. Das bestehende Skript legt nur an, was fehlt. |
| A4 | Abschnitt 8, „Branchenmittel" | Ohne Daten gibt es noch kein Branchenmittel. Ich implementiere die Schrumpfung gegen einen **Parameter `priorMean` aus der Definition** (Standard 3.2, `review: true`) und bereite die Ablösung durch einen echten Branchenwert vor: `aggregate_company` liest ihn aus `company_scores` aller Betriebe derselben `industry`, sobald genug da sind. | Nicht erfindbar, aber vorbereitbar |
| A5 | Abschnitt 9, „Textprüfung auf Namen, Beleidigungen" | Ich baue **kein** Text-Klassifikat. Stattdessen setzt `submit_review` das Flag `text_needs_review` immer, wenn ein Freitext nicht leer ist — jeder Freitext geht also durch die Moderation. | Eine automatische Namens- und Beleidigungserkennung auf Deutsch ist ein eigenes Projekt; ein schlechter Filter ist schlimmer als keiner, weil er Vertrauen vortäuscht. In der Anleitung als offener Punkt markiert. |
| A6 | Abschnitt 11, Vergütung | Feature-Flag `module_verguetung`, Standard **aus**. Modul und Scoring-Dimension existieren vollständig, werden nur nicht angeboten. Der Subscore `sub_verguetung` fällt dann aus der Gewichtung heraus und die übrigen fünf werden neu normiert. | So verlangt |
| A7 | Abschnitt 11, Antwort des Betriebs | `public_reviews` bekommt **keine** Antwortspalte. Die bestehende `reviews.betrieb_reply` bleibt unangetastet am alten Modell. | Offene Frage laut Spezifikation — ich entscheide sie nicht |
| A8 | Abschnitt 6, A5 Verifikation | Es gibt noch keine Verifikation im Projekt (1.4). Ich baue sie neu: Upload in `verification_documents`, pseudonyme Ablage (Dateiname = Hash aus `review_id` + Salz), `reviews.verification_file_id`. **Keine** automatische Prüfung — ein Moderator sieht das Dokument und setzt `verified`. | Rechtlich ist die Prüfbarkeit gefordert, nicht die Automatik |
| A9 | Abschnitt 10, Kleinbetriebe | Variante 1 als Grundeinstellung (Hinweis + Wahl), Variante 2 als Angebot im selben Dialog — wie empfohlen. Gesteuert über `delayed_publish_small_business`, Standard **an**. | So verlangt |
| A10 | Rechtstexte | Der Satz aus A1 („Deine Meinung darfst du frei sagen…") steht wörtlich in der Definition, weil er in der Spezifikation wörtlich steht. **Alle anderen** rechtlichen Aussagen (Anonymitätszusage im Detail, Aufbewahrungsfristen, Hinweis für Minderjährige) bleiben als `PLATZHALTER — juristisch zu prüfen` in der Definition und in `docs/REVIEW_TEXTE.md`. | Rechtliche Aussagen erfinde ich nicht |
| A11 | Anlaufstellen (Modul Konflikte) | Kammer-Ausbildungsberatung, JAV, Gewerkschaftsberatung sind in der Spezifikation namentlich genannt und kommen in die Definition. **Ohne** Telefonnummern und URLs — die stehen als Platzhalter mit `review: true`. | Kontaktdaten, die ich nicht prüfen kann, sind schlimmer als keine |
| A12 | Berufsliste (S3) | Kleine Beispielliste als Asset (ca. 40 Berufe, `review: true`), dazu `tools/import_berufe.dart` für die vollständige Liste aus einer CSV. In der Anleitung steht, woher die CSV kommt (BERUFENET/Klassifikation der Berufe der BA) und welche Spalten das Skript erwartet. | So verlangt |
| A13 | `vas_unnumbered` auf dem Web | „Griff erscheint erst bei Berührung" wird zu „bei Berührung **oder Klick oder Tastenfokus**". Auf dem Desktop gibt es keine Berührung. Der Zustand „nicht beantwortet" bleibt davon unberührt. | Die App ist zuerst Flutter Web |
| A15 | A2, Operanden der Bedingungssprache | Der Auftrag nennt als Operanden `{"answer": "<id>"}`, `{"computed": "<key>"}` und Literale. Ich habe den Antwortverweis um ein optionales `"field"` erweitert: `{"answer": "s8_alltag", "field": "schicht"}`. | Die Wischkarten S8 und K1 liefern **eine** Antwort in Form einer Zuordnung Karte → Ja/Nein/Weiß-ich-nicht. Das Arbeitszeitmodul hängt laut Abschnitt 5 an genau einer davon („S8 Schicht oder Wochenende"). Ohne den Feldzugriff müsste jede Karte eine eigene Frage sein — aus einem Bildschirm würden sieben, und das Wischformat wäre hin. Kein neuer Operator, nur ein zweiter Schlüssel am vorhandenen Operanden; für die Prüfung beim Laden zählt er weiterhin als Verweis auf die ganze Frage. |
| A14 | A4 Vorschau / öffentliche Einzelansicht | Neues `PublicReviewCard` gegen ein `PublicReview`-Modell, an beiden Stellen benutzt. Das bestehende `ReviewCard` samt `StarRating` wird **entfernt**, sobald die letzte Verwendung auf `PublicReviewCard` umgestellt ist. | Folgt zwingend aus den Entscheidungen 1 und 2: Titel, Fließtext und Sterne erzeugt der neue Fragebogen nicht mehr, und alte Zeilen gibt es nach der Leerung nicht mehr. Betroffen sind Dashboard, Suche, Unternehmensprofil, Detailseite und `my_reviews`. |

## 12. Entscheidungen vom 21. September 2026

Übernommen aus `PLAN_FRAGEBOGEN.md` §8, gekürzt. Die vier Fragen des Plans, so
beantwortet:

1. **Die alte Bewertungsstrecke wird ersetzt.** Der neue Fragebogen übernimmt
   `/reviews/new`, `/fragen-bewerten` leitet dorthin weiter. Der alte Assistent,
   `QuestionModel`, `QuestionRepository` und `ReviewRepository.createReview`
   wurden entfernt; die Leseabfragen zeigen auf `public_reviews`.
2. **Die bestehenden Zeilen in `reviews` werden gelöscht**, damit die Functions
   nur ein Schema kennen. Dafür `tools/appwrite-purge-reviews.mjs` mit Probelauf
   als Standard, Export vor dem Löschen und erwarteter Zeilenzahl. Am 1. Oktober
   zeigte sich, dass es keine Zeilen gab (Abschnitt 6).
3. **Projekt-ID und Datenbank-ID im öffentlichen Repository** sind eine eigene
   Aufgabe. Neue Konstanten sind von vornherein umgebungsabhängig; die beiden
   alten in `appwrite_constants.dart` stehen weiter fest im Code (T-4.27).
4. **Die Dokumente liegen in `notes/`.**

Als Folge mitentschieden: `PublicReviewCard` ersetzt `ReviewCard` überall (A14).
