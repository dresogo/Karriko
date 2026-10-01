# Appwrite einrichten: die Bewertungsstrecke

Diese Anleitung ist zum Durcharbeiten gedacht, von oben nach unten, ohne
Rückfragen. Jeder Schritt sagt, was danach anders ist und woran man merkt, dass
er gewirkt hat.

**Was hier nicht drinsteht:** kein Schlüssel, keine Projekt-ID, keine
Datenbank-ID. Das Repository ist öffentlich. Überall, wo eine Kennung gebraucht
wird, steht, wo sie in der Console zu finden ist.

**Wenn du nur die Befehle brauchst:** [`APPWRITE_EINSPIELEN.md`](APPWRITE_EINSPIELEN.md)
ist dieselbe Einrichtung als Befehlsfolge zum Abarbeiten, ohne die Begründungen.
Diese Datei hier erklärt, warum etwas so eingestellt wird.

**Was ich nicht ausprobiert habe:** nichts davon lief gegen dein Projekt. Die
CLI-Konfiguration entstand aus der Dokumentation und aus der installierten CLI
27.3.0, nicht aus einem `appwrite pull`. An zwei Stellen steht deshalb
ausdrücklich, was die CLI anzeigen sollte, damit du eine Abweichung siehst,
bevor sie eingespielt wird.

## Inhalt

1. [Voraussetzungen](#1-voraussetzungen)
2. [Zwei Wege: CLI oder von Hand](#2-zwei-wege-cli-oder-von-hand)
3. [Tabellen](#3-tabellen)
4. [Ablagen](#4-ablagen)
4a. [`companies`: Rechte und die gespiegelte Bewertung](#4a-companies-rechte-und-die-gespiegelte-bewertung)
5. [Teams](#5-teams)
6. [Functions](#6-functions)
7. [Variablen](#7-variablen)
8. [Web-Plattform und CORS](#8-web-plattform-und-cors)
9. [Die Fragendefinition hochladen](#9-die-fragendefinition-hochladen)
10. [Eine neue Version ausrollen](#10-eine-neue-version-ausrollen)
11. [Die Altdaten](#11-die-altdaten)
12. [Datenschutz-Checkliste](#12-datenschutz-checkliste)
13. [Abnahmetest](#13-abnahmetest)
14. [Fehlersuche](#14-fehlersuche)

---

## 1. Voraussetzungen

### Was schon da ist

Das Projekt läuft auf Appwrite Cloud in der Region Frankfurt. Endpunkt:

```
https://fra.cloud.appwrite.io/v1
```

Der generische Host `cloud.appwrite.io` antwortet auch, leitet aber erst über den
globalen Router in die Region. Er gehört nicht in die Konfiguration.

Vorhanden sind sechs Tabellen (Stand 1. Oktober 2026): `profiles`, `companies`,
`reviews`, `bookmarks`, `review_reports`, `jobs`. Gefüllt ist nur `companies`,
mit zwei Testzeilen; alle anderen haben **null Zeilen**.

Davon berührt die Bewertungsstrecke vier:

| Tabelle | Was passiert |
|---|---|
| `reviews` | **Wird gelöscht und neu angelegt.** Siehe unten |
| `review_reports` | Besteht und wird geändert: Row Security an, Rechte dazu |
| `companies` | Wird gelesen; bekommt den Score gespiegelt; Rechte werden engergezogen |
| `profiles` | Unberührt |

### Warum `reviews` neu angelegt wird

Die Tabelle stammt aus der alten Strecke und ist mit der neuen unverträglich —
nicht in Nuancen, sondern so, dass **jede Einreichung scheitern würde**:

* Fünf Pflichtspalten, die `submit_review` nie schreibt: `author_id`,
  `is_anonymous`, `overall_rating`, `title`, `text`. Appwrite lehnt jeden Insert
  ab, dem eine Pflichtspalte fehlt.
* `status` ist ein **Enum** mit `pending | published | rejected`. Der Code
  schreibt `pending_moderation`, `scheduled`, `approved`, `rejected`. Drei von
  vier Werten sind ungültig, und ein Enum lässt sich nicht erweitern — nur
  löschen und neu anlegen.
* `author_id` gegen `user_id`, `pros`/`cons` gegen
  `freitext_gut`/`freitext_schlecht`, `profession` gegen `beruf_name`: dieselbe
  Bedeutung unter zwei Namen.

**Die Tabelle hat null Zeilen.** Es geht also nichts verloren, und Pflichtspalten
lassen sich anlegen, was auf einer gefüllten Tabelle nicht möglich wäre.

Das Löschen ist ein Schritt von Hand: Console → Databases → `reviews` →
Settings → Delete. Danach legt sie der Push oder das Skript neu an.

`tools/appwrite-setup.mjs` hätte das nicht gemerkt. Es legt nur fehlende Spalten
an und rührt vorhandene nicht an — das Enum wäre stehen geblieben und die
Pflichtspalten auch. Danach hätte alles richtig ausgesehen und nichts
funktioniert.

### Was du brauchst

| | |
|---|---|
| Appwrite CLI | 27.3.0 oder neuer — `appwrite --version` |
| Node | 20 oder neuer, für die Werkzeuge unter `tools/` |
| Dart | 3.11 oder neuer, für `vendor_core.dart` und die Tests |
| Flutter | 3.44 oder neuer, für die App |

Die CLI installiert sich mit

```bash
npm install -g appwrite-cli
```

und meldet sich mit `appwrite login` an. Ab da liegt die Sitzung in deinem
Benutzerprofil; sie gehört nicht ins Repository und wird hier nirgends gebraucht.

### Die drei Kennungen

Du brauchst sie für fast jeden Schritt. In der Console:

| Kennung | Wo |
|---|---|
| **Projekt-ID** | Oben links neben dem Projektnamen, oder unter Settings → General |
| **Datenbank-ID** | Databases → die Datenbank anklicken → in der URL und unter Settings |
| **Datenbankname** | Databases → derselbe Ort. Muss **genau** übernommen werden, sonst benennt der Push die Datenbank um |

Setze sie einmal in der Sitzung, dann laufen alle Werkzeuge:

```bash
export APPWRITE_PROJECT_ID=…
export APPWRITE_DATABASE_ID=…
export APPWRITE_DATABASE_NAME=…
```

Unter PowerShell:

```powershell
$env:APPWRITE_PROJECT_ID = "…"
$env:APPWRITE_DATABASE_ID = "…"
$env:APPWRITE_DATABASE_NAME = "…"
```

### Der API-Schlüssel

Console → Overview → Integrations → API Keys → Create API key. Er wird nur für
die Werkzeuge unter `tools/` gebraucht, nicht für die Functions — die bekommen
zur Laufzeit einen eigenen, kurzlebigen Schlüssel.

Scopes:

| Scope | Wofür |
|---|---|
| `databases.read`, `databases.write` | Tabellen und Spalten anlegen |
| `tables.read`, `tables.write` | dasselbe auf Instanzen mit der neuen API |
| `rows.read`, `rows.write` | die Altdaten lesen und löschen |
| `buckets.read`, `buckets.write` | die beiden Ablagen anlegen |
| `files.read`, `files.write` | die Fragendefinition hochladen |

Setze ein Ablaufdatum. Ein Schlüssel ohne Ablauf ist ein Schlüssel, den niemand
zurücknimmt.

```bash
export APPWRITE_API_KEY=…
```

**Der Schlüssel gehört in keine Datei im Repository.** Er steht in der Umgebung
der Sitzung, in der du die Werkzeuge ausführst, und nirgends sonst.

---

## 2. Zwei Wege: CLI oder von Hand

Es gibt zwei Wege, dasselbe Schema einzuspielen. Beide sind vollständig
beschrieben; du brauchst nur einen.

| | CLI | Von Hand |
|---|---|---|
| Aufwand | ein Befehl je Ressourcenart | rund 120 Spalten anklicken |
| Nachvollziehbar | die Konfiguration ist die Beschreibung | nur das Ergebnis |
| Wiederholbar | ja | nein |
| Risiko | ein Push kann mehr ändern als gedacht | ein Tippfehler in einem Spaltennamen |

Empfehlung: **CLI für alle sieben Tabellen, die Buckets, die Teams und die
Functions. Das Skript für `companies`.**

Zwei Dinge vorher:

1. **`reviews` in der Console löschen.** Begründung in Abschnitt 1. Ohne das
   schreibt der Push die neuen Spalten neben die alten, und die Pflichtspalten
   der alten Strecke lassen jede Einreichung scheitern.
2. **`companies` steht nicht in der Konfiguration**, absichtlich. Die Tabelle
   hat Spalten und Indizes, die ich nicht vollständig kenne; ein Push würde sie
   nach meiner Teilbeschreibung umschreiben. Dafür ist
   `tools/appwrite-setup.mjs` da — es legt nur an, nimmt nichts weg, und bei den
   Rechten meldet es, was abweicht:

```bash
node tools/appwrite-setup.mjs --dry-run
node tools/appwrite-setup.mjs --fix-permissions
```

Der zweite Aufruf **entfernt** `update("users")` von `companies` und schaltet
Row Security ein. Siehe Abschnitt 4a, bevor du ihn ausführst.

### Vor jedem Push

```bash
dart run tools/vendor_core.dart
node tools/appwrite-config.mjs
node tools/appwrite-function-env.mjs
```

Der erste kopiert die gemeinsamen Dart-Pakete in jede Function — Appwrite lädt
nur das Function-Verzeichnis hoch, eine Pfadabhängigkeit nach `../../packages/`
zeigt im Build ins Leere. Der zweite erzeugt `appwrite/appwrite.config.json` aus
der Vorlage. Der dritte schreibt die `.env` je Function.

Alle drei haben `--pruefen`, gehen dabei nie ins Netz und enden mit Code 1, wenn
etwas veraltet ist. Das gehört in die CI:

```bash
dart run tools/vendor_core.dart --pruefen
node tools/appwrite-config.mjs --pruefen
node tools/appwrite-function-env.mjs --pruefen
node tools/appwrite-setup.mjs --pruefen
dart run tools/sync_questionnaire.dart --pruefen
```

Der vierte vergleicht das Schema im Skript mit dem in der Vorlage. Zwei
Beschreibungen desselben Gegenstands laufen auseinander, sobald eine gepflegt
wird und die andere nicht — und dann hängt es am Weg, welches Schema entsteht.

### Der Push selbst

Aus dem Ordner `appwrite/`, nicht aus dem Wurzelverzeichnis: Die `path`-Angaben
der Functions sind relativ zur Konfigurationsdatei.

```bash
cd appwrite
appwrite push table
appwrite push bucket
appwrite push team
appwrite push function --with-variables
```

**Ohne `-f`.** Die CLI zeigt dann, was sie ändern würde, und fragt. Beim ersten
Mal ist das der Moment, in dem du siehst, ob die Konfiguration stimmt:

* Bei `push table` sollte sie **sechs Tabellen anlegen** — `reviews` darunter,
  wenn du sie vorher gelöscht hast — und bei `review_reports` Änderungen melden:
  Row Security von aus auf an, Rechte dazu. Null Zeilen, also unkritisch, aber es
  soll absichtlich passieren. Meldet sie bei `reviews` Änderungen statt
  Anlegen, steht die alte Tabelle noch da.
* Bei `push function` baut sie jede Function einzeln und zeigt das Build-Log.
  `dart pub get` muss durchlaufen; findet es `vendor/` nicht, hast du
  `vendor_core.dart` vergessen.
* Meldet die CLI einen unbekannten Scope oder eine ungültige `specification`,
  steht die gültige Liste in der Console unter Functions → *deine Function* →
  Settings. Dann den Wert in `appwrite.config.template.json` korrigieren und
  `node tools/appwrite-config.mjs` erneut laufen lassen — nicht in der erzeugten
  Datei, die wird überschrieben.

### Der Weg von Hand

Console → Databases → die Datenbank → Create table. Für jede Tabelle aus
Abschnitt 3: Kennung und Name eintragen, `rowSecurity` setzen, unter Settings →
Permissions die Rechte, dann unter Columns jede Spalte mit Typ, Größe, Pflicht,
Array und Standardwert, dann unter Indexes die Indizes.

Die Spaltenart heißt in der Console wie in der Tabelle: `varchar` mit Größe,
`text` ohne, `double` für Kommazahlen, `integer`, `boolean`, `datetime`.

Zwei Dinge, die von Hand leicht untergehen:

* **Die Reihenfolge der Spalten in einem Index ist verbindlich.** Ein Index auf
  `company_id, published_at` bedient die Abfrage; einer auf
  `published_at, company_id` nicht.
* **Ein Standardwert ist bei Pflichtspalten und bei Arrays nicht erlaubt.** Die
  Console blendet das Feld dann aus.

---

## 3. Tabellen

Sieben Tabellen. Sechs sind neu, `reviews` besteht.

### Warum es zwei Tabellen für Bewertungen gibt

`reviews` trägt alles: Rohantworten, Bearbeitungszeiten, Qualitäts-Flags, den
Gerätehash, die Nutzerkennung. `public_reviews` trägt, was jeder sehen darf.

Das ist keine Verdopplung aus Bequemlichkeit. **Appwrite vergibt Rechte pro
Zeile, nicht pro Spalte.** Läge alles in einer Tabelle, müsste entweder der
Nutzerbezug öffentlich lesbar sein oder die Bewertung unsichtbar. Eine gefilterte
Sicht gibt es nicht.

Deshalb hat `reviews` **keine Rechte**. Kein Client liest dort, auch der
Verfasser nicht. Geschrieben wird nur von den Functions.

Das hat einen Preis, und er ist Absicht: Weil `public_reviews` keine `user_id`
trägt, kann niemand serverseitig auflisten, welche Bewertungen ein bestimmter
Azubi abgeschickt hat — auch er selbst nicht. Die App merkt sich das lokal.
Die Alternative wäre genau die Verknüpfung, die es nicht geben darf.

### Die Spalten

Alle Angaben sind aus `appwrite/appwrite.config.template.json` erzeugt. Wenn
Anleitung und Vorlage auseinandergehen, gilt die Vorlage.

#### `questionnaire_releases`

rowSecurity: false — Rechte: `read("any")`

| Spalte | Typ | Größe | Pflicht | Array | Standard | Bereich |
|---|---|---|---|---|---|---|
| `locale` | varchar | 10 | ja |  |  |  |
| `version` | integer |  | ja |  |  | 1– |
| `bucket_id` | varchar | 36 | ja |  |  |  |
| `file_id` | varchar | 36 | ja |  |  |  |
| `checksum` | varchar | 64 |  |  |  |  |
| `active` | boolean |  |  |  | false |  |
| `published_at` | datetime |  | ja |  |  |  |

| Index | Typ | Spalten | Reihenfolge |
|---|---|---|---|
| `locale_version_unique` | unique | `locale`, `version` | ASC, ASC |
| `locale_active_version` | key | `locale`, `active`, `version` | ASC, ASC, DESC |

#### `review_drafts`

rowSecurity: true — Rechte: `create("users")`

| Spalte | Typ | Größe | Pflicht | Array | Standard | Bereich |
|---|---|---|---|---|---|---|
| `user_id` | varchar | 36 | ja |  |  |  |
| `company_id` | varchar | 36 | ja |  |  |  |
| `schema_version` | integer |  | ja |  |  | 1– |
| `answers_json` | text |  |  |  |  |  |
| `timings_json` | text |  |  |  |  |  |
| `current_question_id` | varchar | 64 |  |  |  |  |
| `invite_source` | varchar | 64 |  |  |  |  |
| `updated_at` | datetime |  | ja |  |  |  |

| Index | Typ | Spalten | Reihenfolge |
|---|---|---|---|
| `user_company_unique` | unique | `user_id`, `company_id` | ASC, ASC |
| `user_updated` | key | `user_id`, `updated_at` | ASC, DESC |
| `updated_at` | key | `updated_at` | ASC |

#### `reviews`

rowSecurity: false — Rechte: _keine_

| Spalte | Typ | Größe | Pflicht | Array | Standard | Bereich |
|---|---|---|---|---|---|---|
| `company_id` | varchar | 36 | ja |  |  |  |
| `user_id` | varchar | 36 | ja |  |  |  |
| `schema_version` | integer |  | ja |  |  | 1– |
| `status` | varchar | 32 | ja |  |  |  |
| `respondent_status` | varchar | 32 |  |  |  |  |
| `beruf_code` | varchar | 32 |  |  |  |  |
| `beruf_name` | varchar | 128 |  |  |  |  |
| `start_year` | integer |  |  |  |  | 1950–2100 |
| `end_year` | integer |  |  |  |  | 1950–2100 |
| `invited` | boolean |  |  |  | false |  |
| `invite_source` | varchar | 64 |  |  |  |  |
| `k5_recommend` | integer |  |  |  |  | 0–10 |
| `k6_overall` | integer |  |  |  |  | 0–100 |
| `detail_overall` | double |  |  |  |  | 1–5 |
| `sub_fachlich` | double |  |  |  |  | 1–5 |
| `sub_betreuung` | double |  |  |  |  | 1–5 |
| `sub_umgang` | double |  |  |  |  | 1–5 |
| `sub_belastung` | double |  |  |  |  | 1–5 |
| `sub_verguetung` | double |  |  |  |  | 1–5 |
| `sub_perspektive` | double |  |  |  |  | 1–5 |
| `sub_berufsschule` | double |  |  |  |  | 1–5 |
| `quality_flags` | varchar | 64 |  | ja |  |  |
| `quality_notes` | varchar | 512 |  | ja |  |  |
| `publish_after` | datetime |  |  |  |  |  |
| `publish_after_training_end` | boolean |  |  |  | false |  |
| `freitext_gut` | text |  |  |  |  |  |
| `freitext_schlecht` | text |  |  |  |  |  |
| `answers_json` | text |  |  |  |  |  |
| `timings_json` | text |  |  |  |  |  |
| `verification_file_id` | varchar | 36 |  |  |  |  |
| `verified` | boolean |  |  |  | false |  |
| `verification_cleared_at` | datetime |  |  |  |  |  |
| `device_hash` | varchar | 64 |  |  |  |  |

| Index | Typ | Spalten | Reihenfolge |
|---|---|---|---|
| `user_company_unique` | unique | `user_id`, `company_id` | ASC, ASC |
| `status` | key | `status` | ASC |
| `status_publish_after` | key | `status`, `publish_after` | ASC, ASC |
| `company_id` | key | `company_id` | ASC |

#### `public_reviews`

rowSecurity: false — Rechte: `read("any")`

| Spalte | Typ | Größe | Pflicht | Array | Standard | Bereich |
|---|---|---|---|---|---|---|
| `review_id` | varchar | 36 | ja |  |  |  |
| `company_id` | varchar | 36 | ja |  |  |  |
| `company_name` | varchar | 200 |  |  |  |  |
| `company_slug` | varchar | 200 |  |  |  |  |
| `beruf_code` | varchar | 32 |  |  |  |  |
| `beruf_name` | varchar | 128 |  |  |  |  |
| `start_year` | integer |  |  |  |  | 1950–2100 |
| `end_year` | integer |  |  |  |  | 1950–2100 |
| `respondent_status` | varchar | 32 |  |  |  |  |
| `k5_recommend` | integer |  |  |  |  | 0–10 |
| `k6_overall` | integer |  |  |  |  | 0–100 |
| `sub_fachlich` | double |  |  |  |  | 1–5 |
| `sub_betreuung` | double |  |  |  |  | 1–5 |
| `sub_umgang` | double |  |  |  |  | 1–5 |
| `sub_belastung` | double |  |  |  |  | 1–5 |
| `sub_verguetung` | double |  |  |  |  | 1–5 |
| `sub_perspektive` | double |  |  |  |  | 1–5 |
| `sub_berufsschule` | double |  |  |  |  | 1–5 |
| `freitext_gut` | text |  |  |  |  |  |
| `freitext_schlecht` | text |  |  |  |  |  |
| `is_aged` | boolean |  |  |  | false |  |
| `verified` | boolean |  |  |  | false |  |
| `published_at` | datetime |  | ja |  |  |  |

| Index | Typ | Spalten | Reihenfolge |
|---|---|---|---|
| `review_id_unique` | unique | `review_id` | ASC |
| `company_published` | key | `company_id`, `published_at` | ASC, DESC |
| `published_at` | key | `published_at` | DESC |

#### `company_scores`

rowSecurity: false — Rechte: `read("any")`

| Spalte | Typ | Größe | Pflicht | Array | Standard | Bereich |
|---|---|---|---|---|---|---|
| `company_id` | varchar | 36 | ja |  |  |  |
| `overall` | double |  |  |  |  | 1–5 |
| `sub_fachlich` | double |  |  |  |  | 1–5 |
| `sub_betreuung` | double |  |  |  |  | 1–5 |
| `sub_umgang` | double |  |  |  |  | 1–5 |
| `sub_belastung` | double |  |  |  |  | 1–5 |
| `sub_verguetung` | double |  |  |  |  | 1–5 |
| `sub_perspektive` | double |  |  |  |  | 1–5 |
| `sub_berufsschule` | double |  |  |  |  | 1–5 |
| `recommend_mean` | double |  |  |  |  | 0–10 |
| `weights_json` | text |  |  |  |  |  |
| `review_count` | integer |  |  |  | 0 | 0– |
| `aged_count` | integer |  |  |  | 0 | 0– |
| `score_visible` | boolean |  |  |  | false |  |
| `numbers_visible` | boolean |  |  |  | false |  |
| `bands_json` | text |  |  |  |  |  |
| `updated_at` | datetime |  | ja |  |  |  |

| Index | Typ | Spalten | Reihenfolge |
|---|---|---|---|
| `company_id_unique` | unique | `company_id` | ASC |
| `overall` | key | `overall` | DESC |

#### `moderation_log`

rowSecurity: false — Rechte: `read("team:moderators")`

| Spalte | Typ | Größe | Pflicht | Array | Standard | Bereich |
|---|---|---|---|---|---|---|
| `review_id` | varchar | 36 | ja |  |  |  |
| `moderator_id` | varchar | 36 | ja |  |  |  |
| `action` | varchar | 16 | ja |  |  |  |
| `reason` | text |  |  |  |  |  |
| `flags` | varchar | 64 |  | ja |  |  |
| `created_at` | datetime |  | ja |  |  |  |

| Index | Typ | Spalten | Reihenfolge |
|---|---|---|---|
| `review_created` | key | `review_id`, `created_at` | ASC, DESC |
| `moderator_id` | key | `moderator_id` | ASC |

#### `review_reports`

rowSecurity: true — Rechte: `create("users")`, `read("team:moderators")`

| Spalte | Typ | Größe | Pflicht | Array | Standard | Bereich |
|---|---|---|---|---|---|---|
| `review_id` | varchar | 36 | ja |  |  |  |
| `reporter_id` | varchar | 36 | ja |  |  |  |
| `reason` | text |  | ja |  |  |  |

| Index | Typ | Spalten | Reihenfolge |
|---|---|---|---|
| `review_id` | key | `review_id` | ASC |
| `reporter_id` | key | `reporter_id` | ASC |

### Was an diesen Spalten wichtig ist

**`text` statt `varchar` bei den JSON-Spalten und Freitexten.** Eine
MariaDB-Zeile darf zusammen 64 KB nicht überschreiten, und `varchar` zählt mit
seiner volle Größe darauf. `text` zählt mit 20 Byte, weil nur ein Zeiger in der
Zeile steht. `answers_json` allein wäre als `varchar` schon die halbe Zeile.

**`answers_json` ist keine Bequemlichkeit.** Ohne die Rohantworten ließe sich
eine Bewertung nach einer Parameteränderung nicht neu rechnen — und genau das
macht `recompute_all`. Typisierte Spalten bekommt, wonach gefiltert und
aggregiert wird; alles andere steht als JSON daneben.

**`status` ist ein `varchar` und kein Enum.** Die Zustände stehen in
`ReviewStatus` im Code. Ein Enum in der Datenbank wäre eine zweite Liste davon,
und zwei Listen laufen auseinander — die alte Strecke hatte hier ein Enum mit
drei Werten, und genau daran wäre jede Einreichung gescheitert. Ein Enum lässt
sich außerdem nicht erweitern, nur löschen und neu anlegen.

**Kennungen sind durchgehend `varchar(36)`.** Eine Appwrite-Kennung ist höchstens
36 Zeichen lang, und der Bestand hält es schon so. `device_hash` ist die
Ausnahme: 64 Hexzeichen aus SHA-256.

**`device_hash` ist ein gesalzener Hash und nichts anderes.** Die Rohkennung
verlässt den Client, wird gehasht und fällt weg. Ohne Salz in der Umgebung wird
gar nicht gehasht — ein bekanntes Salz ist kein Salz. **Eine IP-Adresse wird
nirgends gespeichert.**

**`start_year` und `end_year` sind Jahre, keine Monate.** Ein Monat würde eine
einzelne Bewertung in einem kleinen Betrieb zuordenbar machen.

**Der eindeutige Index auf `user_id` + `company_id` ist der verbindliche Teil der
Dublettenprüfung.** `submit_review` fragt vorher nachweislich nach, damit der
Azubi eine verständliche Meldung bekommt statt eines Indexfehlers — aber
durchsetzen tut es der Index. Er steht im Skript als `optional`: Bei bereits
doppelten Altzeilen legt Appwrite ihn nicht an, und das ist ein Datenbefund,
kein Skriptfehler. Dann erst Abschnitt 11, danach das Skript erneut.

---

## 4. Ablagen

Zwei Buckets.

### `questionnaires`

| | |
|---|---|
| Rechte | `read("any")` |
| fileSecurity | aus |
| Maximale Dateigröße | 5 MB |
| Erlaubte Endungen | `json` |
| Komprimierung | gzip |
| Verschlüsselung | aus |
| Virenprüfung | ein |

Hier liegt die Fragendefinition. Öffentlich lesbar, weil der Client sie lädt —
die Fragen sind ohnehin sichtbar, sobald jemand den Bogen aufruft. Schreiben darf
nur ein Schlüssel.

Verschlüsselung ist aus, weil hier nichts Schützenswertes liegt und eine
verschlüsselte Datei nicht komprimiert wird.

### `verification_documents`

| | |
|---|---|
| Rechte | `create("users")` |
| fileSecurity | **ein** |
| Maximale Dateigröße | 10 MB |
| Erlaubte Endungen | `pdf`, `jpg`, `jpeg`, `png`, `webp` |
| Komprimierung | keine |
| Verschlüsselung | **ein** |
| Virenprüfung | ein |

Hier liegen die Nachweise über ein Ausbildungsverhältnis. Hochladen darf jeder
Angemeldete, **lesen niemand**: Der Client setzt beim Upload leere Rechte, und
`fileSecurity` macht das verbindlich. Wäre `fileSecurity` aus, würden die
Tabellenrechte gelten und die leeren Dateirechte wären wirkungslos.

Der Dateiname wird beim Upload auf `nachweis.<endung>` gesetzt. Ein Dateiname wie
`Ausbildungsvertrag_Mustermann_Müller-GmbH.pdf` ist selbst eine Angabe.

**Daraus folgt, dass die Moderation den Nachweis nur über die Console sieht.**
Es gibt keine Function, die ihn ausliefert, und keinen Bildschirm dafür. Das ist
der heutige Stand und in Abschnitt 12 als offener Punkt vermerkt.

Komprimierung aus: Bilder und PDF sind komprimiert, und auf verschlüsselte
Dateien wirkt gzip ohnehin nicht.

### Ein bestehender Bucket wird nicht umgeschrieben

`tools/appwrite-setup.mjs` legt einen fehlenden Bucket an und meldet bei einem
vorhandenen nur, was abweicht. Größengrenzen, Endungen und Verschlüsselung eines
Buckets, in dem schon Dateien liegen, sind eine Entscheidung und keine
Reparatur — Verschlüsselung nachträglich einzuschalten gilt zum Beispiel nicht
rückwirkend für die Dateien, die schon drin sind.

---

## 4a. `companies`: Rechte und die gespiegelte Bewertung

Zwei Änderungen an einer bestehenden Tabelle. Beide macht
`tools/appwrite-setup.mjs`, die zweite nur mit `--fix-permissions`.

### Der Score wird gespiegelt

`aggregate_company` schreibt den Gesamtscore an **zwei** Stellen:
`company_scores` ist der verbindliche Ort, und `companies.average_rating` plus
`companies.review_count` sind eine Kopie.

Der Grund ist unspektakulär: Die Suche sortiert absteigend nach der Bewertung
und filtert mit einer Untergrenze, und **Appwrite sortiert nicht über zwei
Tabellen hinweg.** Ohne die Kopie bräuchte die Liste zwei Abfragen, und Betriebe
ohne Score fielen aus der Sortierung — bei unter drei Bewertungen sind das die
meisten.

Angezeigt wird immer der Wert aus `company_scores`. Unter der
Sichtbarkeitsschwelle steht in beiden `null`: Ein Betrieb mit zwei Bewertungen
soll nicht nach einem Score sortiert werden, den niemand sehen darf.

Das Skript legt die beiden Spalten an, falls sie fehlen. Im Bestand sind sie
schon da — **ohne Wertgrenzen**, und das kann das Skript nicht nachtragen:
Appwrite ändert eine bestehende Spalte nicht auf diesem Weg. Wer `min: 0` und
`max: 5` haben will, löscht die Spalte in der Console und legt sie neu an. Auf
zwei Testzeilen ist das billig, später nicht mehr.

### Das Änderungsrecht muss enger werden

Im Bestand hat `companies` auf Tabellenebene `update("users")`, und Row Security
ist aus. Das heißt: **Jeder angemeldete Nutzer darf jede Firma ändern** — auch
`is_verified`, `is_premium`, `owner_id` und, nach der Spiegelung, den Score, nach
dem die Suche sortiert.

Der Client setzt beim Anlegen einer Firma schon ein Änderungsrecht für den
Eigentümer **pro Zeile**. Das wirkt nur mit Row Security. Also beides:

```bash
node tools/appwrite-setup.mjs --fix-permissions
```

Danach sind die Tabellenrechte `read("any")` und `create("users")`, Row Security
ist an, und ein Betrieb bearbeitet weiter sein eigenes Profil.

**Was dabei kaputtgeht:** Die Testzeile „Test GmbH" hat keine Zeilenrechte — ihr
`owner_id` zeigt auf ihre eigene Zeilen-ID und zu keinem Nutzer. Sie wird nach
der Umstellung unbearbeitbar. Da sie verwaiste Testdaten ist, ist das kein
Verlust; lösche sie.

**Was damit nicht behoben ist:** Der Eigentümer kann auf seiner eigenen Zeile
`is_verified` und `average_rating` setzen. **Appwrite kennt keine Rechte je
Spalte.** Ein Betrieb kann sich also sein Verifizierungs-Abzeichen selbst geben
und sich in der Sortierung nach vorn schreiben.

Zwei Dinge mildern das und keines behebt es: `aggregate_company` überschreibt
`average_rating` bei der nächsten Änderung wieder, und der **angezeigte** Score
kommt aus `company_scores`, das kein Client schreiben kann. Eine Manipulation
wirkt also nur auf die Sortierung und nur bis zur nächsten Aggregation.

Die eigentliche Lösung wäre, Profiländerungen über eine Function zu führen, die
nur die Stammdaten durchlässt. Das ist nicht gebaut und steht in
[`UMSETZUNG_BERICHT.md`](UMSETZUNG_BERICHT.md) als offener Punkt.

## 5. Teams

Zwei Teams. Sie steuern, wer welche Function ausführen darf.

| Kennung | Name | Wofür |
|---|---|---|
| `moderators` | Moderation | `moderate_review` ausführen, `moderation_log` und `review_reports` lesen |
| `admins` | Administration | `recompute_all` ausführen, und alles, was Moderatoren dürfen |

Console → Auth → Teams → Create team. **Die Kennung muss `moderators` bzw.
`admins` sein**, nicht der Anzeigename: Die Rechte in der Konfiguration lauten
`team:moderators`, und `TeamGuard` im Code fragt nach derselben Kennung.

Andere Kennungen sind möglich, dann aber überall: in
`appwrite.config.template.json` über `KARRIKO_TEAM_MODERATORS` und
`KARRIKO_TEAM_ADMINS`, und in den `.env` der Functions über dieselben Variablen.

Mitglieder fügst du über Auth → Teams → *Team* → Members hinzu.

**Ein fehlendes Team heißt „niemand", nicht „alle".** `TeamGuard` gibt bei einem
Fehler beim Nachfragen `false` zurück. Eine Function, deren Team es nicht gibt,
lehnt jeden ab — das ist die richtige Richtung, aber es sieht wie ein Rechtefehler
aus. Wenn `moderate_review` jeden mit „Diese Aktion ist der Moderation
vorbehalten" abweist, fehlt vermutlich das Team.

---

## 6. Functions

Sechs Functions, alle in Dart.

### Gemeinsam für alle sechs

| | |
|---|---|
| Runtime | `dart-3.11` |
| Entrypoint | `lib/main.dart` |
| Build-Befehl | `dart pub get` |
| Logging | ein |
| Specification | **nicht gesetzt** — es gilt die Voreinstellung des Projekts |

Die Specification steht absichtlich nicht in der Konfiguration: Welche Größen dein
Tarif zulässt, weiß ich nicht, und ein erfundener Wert lässt den Push scheitern.
Wenn eine Function ins Timeout läuft oder der Speicher nicht reicht, setzt du sie
in der Console unter Settings → Runtime und trägst sie danach in die Vorlage
nach.

Dass alle sechs dieselbe Runtime haben, ist kein Zufall: Sie binden dasselbe
`questionnaire_core` ein wie der Client. Dass Server und Client zum selben
Ergebnis kommen, ist damit keine Absprache zwischen zwei Umsetzungen.

### Die sechs im Einzelnen

#### `submit_review`

| | |
|---|---|
| Ausführen darf | `users` |
| Auslöser | Aufruf |
| Timeout | 30 s |
| Scopes | `rows.read`, `rows.write`, `files.read` |

**Die einzige Stelle, an der eine Bewertung entsteht.** Der Client hat auf
`reviews` kein Schreibrecht — nicht aus Misstrauen, sondern weil ein Score, den
man sich selbst setzen kann, nichts sagt.

Sie lädt genau die Version, mit der die Einreichung begonnen wurde, prüft dagegen,
rechnet Werte und Qualitäts-Flags **neu**, legt die Zeile an und löscht den
Entwurf. `files.read` braucht sie, um die Definition aus dem Bucket zu laden.

#### `moderate_review`

| | |
|---|---|
| Ausführen darf | `team:moderators`, `team:admins` |
| Auslöser | Aufruf |
| Timeout | 30 s |
| Scopes | `rows.read`, `rows.write`, `files.read`, `teams.read` |

Gibt frei oder lehnt ab. **Bei der Freigabe entsteht die öffentliche Zeile** —
erst hier, nicht beim Einreichen: Was in `public_reviews` steht, hat ein Mensch
gesehen.

`teams.read` braucht sie, um die Mitgliedschaft des Aufrufers selbst
nachzuprüfen. Die Ausführungsrechte würden den Aufruf schon schützen; diese
zweite Prüfung liefert die Nutzerkennung, die dann im `moderation_log` steht.
Eine Moderation ohne nachvollziehbaren Urheber ist keine.

Aufruf:

```json
{ "review_id": "…", "action": "approve", "verified": true }
{ "review_id": "…", "action": "reject", "reason": "…" }
```

`verified` ist freiwillig und quittiert den Nachweis; ohne die Angabe bleibt es
beim bisherigen Stand. **Eine Ablehnung ohne Begründung wird zurückgewiesen** —
sie wäre für den Verfasser nicht nachvollziehbar und für die Moderation nicht
überprüfbar.

**Ablehnen löscht nicht.** Die Bewertung bleibt mit Status `rejected` stehen,
die öffentliche Zeile verschwindet. Löschen träfe erfahrungsgemäß vor allem die
ausführlichen, ehrlichen Bewertungen.

#### `aggregate_company`

| | |
|---|---|
| Ausführen darf | niemand |
| Auslöser | Ereignis |
| Timeout | 120 s |
| Scopes | `rows.read`, `rows.write`, `files.read` |

Ereignisse — mit **deiner** Datenbankkennung, die `appwrite-config.mjs` einsetzt:

```
tablesdb.<DATENBANK>.tables.public_reviews.rows.*.create
tablesdb.<DATENBANK>.tables.public_reviews.rows.*.update
tablesdb.<DATENBANK>.tables.public_reviews.rows.*.delete
```

Rechnet `company_scores` neu und spiegelt den Score nach
`companies.average_rating`/`review_count`, damit die Suche danach sortieren kann
— siehe Abschnitt 4a. Scheitert das Spiegeln, bricht sie nicht ab: Der
verbindliche Wert steht dann schon, veraltet ist nur die Sortierung. Die Antwort
sagt es mit `"mirrored": false`.

Idempotent: Zweimal für dieselbe Änderung zu laufen ändert nichts, denn gerechnet
wird immer von den Zeilen aus, nie von einem vorherigen Ergebnis.

**Sie wird von `public_reviews` ausgelöst, liest aber auch `reviews`.** Das sieht
nach einem Widerspruch aus und ist keiner: Die Gewichte des Gesamtscores entstehen
aus den aggregierten K12-Prioritäten, und die stehen in den Rohantworten. Sie nach
`public_reviews` zu kopieren hieße, drei von acht Prioritätskarten je Azubi zu
veröffentlichen — eine Angabe mehr, die niemand gebraucht hätte.

#### `publish_scheduled`

| | |
|---|---|
| Ausführen darf | niemand |
| Auslöser | Cron `0 * * * *` (stündlich) |
| Timeout | 300 s |
| Scopes | `rows.read`, `rows.write`, `files.read` |

Gibt zurückgestellte Bewertungen in die Moderation, sobald ihre Frist abgelaufen
ist. Zurückgestellt wird, wer in A3 darum bittet, und in Kleinbetrieben, wer
„erst nach Ausbildungsende" wählt.

#### `recompute_all`

| | |
|---|---|
| Ausführen darf | `team:admins` |
| Auslöser | Aufruf |
| Timeout | 600 s |
| Scopes | `rows.read`, `rows.write`, `files.read`, `teams.read` |

Rechnet alle Bewertungen mit den aktuellen Parametern neu. Gebraucht, wenn sich an
der Definition etwas geändert hat, was die Auswertung betrifft: ein Punktwert, ein
Gewicht, die Schrumpfungsstärke, die Alterungsgrenze. Ohne diesen Lauf stünden
alte und neue Bewertungen auf verschiedenen Maßstäben.

**In Etappen von 100.** Die Antwort enthält `next_offset`, solange nicht alles
durch ist:

```json
{ "offset": 0, "dry_run": true }
```

Danach mit dem zurückgegebenen `next_offset` erneut, bis `done: true`. Die Antwort
nennt unter `companies` die betroffenen Betriebe; für die läuft
`aggregate_company` nicht automatisch — sie werden erst neu gerechnet, wenn sich
eine ihrer öffentlichen Zeilen ändert. Bei einer Parameteränderung also einmal
selbst anstoßen.

Steht in der Antwort `unusable_versions`, ließ sich eine Fassung des Fragebogens
nicht laden; siehe Abschnitt 14.

#### `cleanup`

| | |
|---|---|
| Ausführen darf | niemand |
| Auslöser | Cron `30 3 * * *` (täglich) |
| Timeout | 600 s |
| Scopes | `rows.read`, `rows.write`, `files.write` |

Löscht verwaiste Entwürfe und geprüfte Verifikationsnachweise. `files.write`
braucht sie zum Löschen der Nachweisdateien; `files.read` braucht sie nicht.

Ein Probelauf, der nur zählt:

```json
{ "dry_run": true }
```

**Die Fristen stehen in der Umgebung, nicht im Code**, und sind in Abschnitt 12
als juristisch zu prüfen gekennzeichnet.

### Wenn du die Functions von Hand anlegst

Console → Functions → Create function → Manual. Dann je Function:

1. **Settings → Name und ID** wie oben.
2. **Settings → Runtime** `Dart 3.11`, Entrypoint `lib/main.dart`, Build command
   `dart pub get`.
3. **Settings → Execute access** die Rolle aus der Tabelle. „niemand" heißt: das
   Feld leer lassen. Nicht `any`.
4. **Settings → Events** nur bei `aggregate_company`.
5. **Settings → Schedule** nur bei `publish_scheduled` und `cleanup`.
6. **Settings → Timeout** wie oben.
7. **Settings → Scopes** wie oben. Findet sich ein Name dort nicht, gilt die
   Liste in der Console.
8. **Settings → Variables** siehe Abschnitt 7.
9. Code hochladen: im Function-Verzeichnis `dart run tools/vendor_core.dart`
   vorher laufen lassen, dann den Ordner als Tar-Archiv hochladen — oder eben
   `appwrite push function`, was genau das tut.

---

## 7. Variablen

Appwrite setzt zwei davon selbst: `APPWRITE_FUNCTION_API_ENDPOINT` und
`APPWRITE_FUNCTION_PROJECT_ID`. Sie stehen hier nur, damit die Liste vollständig
ist.

### Pflicht

| Variable | Wer | Bedeutung |
|---|---|---|
| `KARRIKO_DATABASE_ID` | alle sechs | Die Datenbankkennung. **Kein Standardwert.** Ein geratener Wert liefe gegen eine erfundene Datenbank und erzeugte eine Fehlermeldung, die auf alles andere hindeutet. Fehlt sie, bricht die Function beim Start ab und sagt, welche Variable fehlt. |

### Das Geheimnis

| Variable | Wer | Bedeutung |
|---|---|---|
| `KARRIKO_DEVICE_HASH_SALT` | nur `submit_review` | Salz für den Hash der Gerätekennung. Eine lange Zufallszeichenkette, einmal erzeugt, danach nie geändert. |

**Nur `submit_review` bekommt es.** Nur dort wird gehasht. Ein Geheimnis, das in
sechs Umgebungen liegt, ist an sechs Stellen einsehbar, und fünf davon brauchen es
nicht.

Ohne diese Variable wird **nicht** gehasht. Es gibt keinen eingebauten
Ersatzwert — ein bekanntes Salz ist kein Salz. Das ist eine gültige Betriebsart:
Dann steht in `device_hash` nichts, und es gibt keinen Hinweis mehr darauf, dass
zwei Bewertungen vom selben Gerät kamen.

**Wird das Salz geändert, passen die alten Hashes nicht mehr zu den neuen.** Sie
werden dadurch nicht falsch, nur unvergleichbar. Ein Grund, es zu ändern, wäre,
dass es bekannt geworden ist — und dann ist der Verlust der Vergleichbarkeit der
kleinere Schaden.

Erzeugen:

```bash
openssl rand -base64 48
```

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Max 256 }))
```

### Fristen

Alle vier haben einen Standardwert und stehen nur in der `.env`, wenn du sie
ändern willst. **Alle vier sind in Abschnitt 12 als juristisch zu prüfen
gekennzeichnet.**

| Variable | Standard | Wer | Bedeutung |
|---|---|---|---|
| `KARRIKO_DRAFT_RETENTION_DAYS` | 90 | `cleanup` | Nach wie vielen Tagen ohne Änderung ein Entwurf verfällt |
| `KARRIKO_VERIFICATION_RETENTION_DAYS` | 30 | `cleanup` | Nach wie vielen Tagen nach der Moderationsentscheidung der Nachweis gelöscht wird |
| `KARRIKO_DELAY_DAYS` | 3 | `submit_review` | Um wie viele Tage die Veröffentlichung verschoben wird, wenn jemand in A3 darum bittet |
| `KARRIKO_SMALL_BUSINESS_DELAY_MONTHS` | 6 | `submit_review`, `publish_scheduled` | Um wie viele Monate bei einem Kleinbetrieb verschoben wird, wenn „erst nach Ausbildungsende" gewählt ist und kein Enddatum bekannt ist |

### Kennungen, die man überschreiben kann

Alle haben einen sprechenden Standardwert und stehen nur in der `.env`, wenn deine
Tabelle anders heißt. Eine Zeile `KARRIKO_TBL_REVIEWS=reviews` sagt nichts, was
der Code nicht schon weiß.

| Variable | Standard |
|---|---|
| `KARRIKO_TBL_REVIEWS` | `reviews` |
| `KARRIKO_TBL_PUBLIC_REVIEWS` | `public_reviews` |
| `KARRIKO_TBL_DRAFTS` | `review_drafts` |
| `KARRIKO_TBL_COMPANY_SCORES` | `company_scores` |
| `KARRIKO_TBL_MODERATION_LOG` | `moderation_log` |
| `KARRIKO_TBL_RELEASES` | `questionnaire_releases` |
| `KARRIKO_TBL_COMPANIES` | `companies` |
| `KARRIKO_BUCKET_QUESTIONNAIRES` | `questionnaires` |
| `KARRIKO_BUCKET_VERIFICATION` | `verification_documents` |
| `KARRIKO_TEAM_MODERATORS` | `moderators` |
| `KARRIKO_TEAM_ADMINS` | `admins` |

### Einspielen

```bash
export KARRIKO_DATABASE_ID=…
export KARRIKO_DEVICE_HASH_SALT=…
node tools/appwrite-function-env.mjs
cd appwrite && appwrite push function --with-variables
```

Das Werkzeug schreibt `appwrite/functions/<name>/.env`. Diese Dateien stehen in
der `.gitignore`.

**Ohne `--with-variables` werden die Variablen nicht mitgeschickt**, und eine
Function, die eben noch lief, bricht nach dem Push mit „Die Umgebungsvariable
KARRIKO_DATABASE_ID fehlt" ab.

Von Hand: Console → Functions → *Function* → Settings → Variables. Bei
`KARRIKO_DEVICE_HASH_SALT` den Schalter **Secret** setzen; danach zeigt die Console
den Wert nicht mehr an.

### Was die App braucht

Die App liest ihre Kennungen zur Bauzeit. Standard sind sprechende Namen, keine
echten Kennungen:

```bash
flutter build web \
  --dart-define=APP_ORIGIN=https://… \
  --dart-define=TBL_PUBLIC_REVIEWS=public_reviews \
  --dart-define=TBL_COMPANY_SCORES=company_scores \
  --dart-define=TBL_REVIEW_DRAFTS=review_drafts \
  --dart-define=TBL_QUESTIONNAIRE_RELEASES=questionnaire_releases \
  --dart-define=BUCKET_QUESTIONNAIRES=questionnaires \
  --dart-define=BUCKET_VERIFICATION=verification_documents \
  --dart-define=FN_SUBMIT_REVIEW=submit_review
```

Solange du die Standardnamen benutzt, reicht `APP_ORIGIN`.

---

## 8. Web-Plattform und CORS

Ohne diesen Schritt antwortet Appwrite auf jeden Aufruf aus dem Browser mit einem
CORS-Fehler, und die App zeigt „Verbindung fehlgeschlagen" — obwohl alles andere
richtig eingerichtet ist.

Console → Overview → Integrations → Platforms → Add platform → **Web**.

| Feld | Wert |
|---|---|
| Name | frei, z. B. `Karriko Web` |
| Hostname | die Domain **ohne** Protokoll und ohne Pfad, z. B. `karriko.de` |

Für die Entwicklung eine zweite Plattform mit `localhost`. Der Port gehört nicht
dazu, Appwrite prüft nur den Hostnamen.

Bei einer Subdomain: entweder eine Plattform je Subdomain oder ein Platzhalter wie
`*.karriko.de`. Nimm den Platzhalter nur, wenn alle Subdomains dir gehören.

### `APP_ORIGIN` muss dazu passen

Die App leitet alle Rückleitungen von Appwrite aus `APP_ORIGIN` ab:
Bestätigungsmail, Passwort-Reset, Anmeldelink, OAuth. Steht dort eine Adresse,
deren Hostname nicht als Plattform eingetragen ist, weist Appwrite die Ziel-URL
zurück — und der Nutzer bekommt eine Mail mit einem Link, der nicht funktioniert.

Der Standard ist `http://localhost:8080` und passt zum Entwicklungsserver.
Produktiv unbedingt setzen.

### Prüfen

Öffne die App im Browser und schau in die Netzwerkansicht der
Entwicklerwerkzeuge. Der erste Aufruf gegen `fra.cloud.appwrite.io` muss mit 200
oder 401 antworten. Ein Fehler in der Konsole, der `Access-Control-Allow-Origin`
erwähnt, heißt: Plattform fehlt oder Hostname stimmt nicht.

---

## 9. Die Fragendefinition hochladen

Die Definition steht nicht in der Datenbank, sondern als Datei im Storage. In
`questionnaire_releases` steht nur der Verweis. So lässt sich eine neue Version
ausrollen, ohne die App neu zu bauen, und alte Versionen bleiben abrufbar.

### Schritt 1 — die beiden Kopien gleichhalten

```bash
dart run tools/sync_questionnaire.dart
```

Es gibt zwei Dateien, weil sie zwei Wege gehen: `karriko_flutter/assets/…` wird
als Asset in die App gebaut und ist der Rückfall, wenn der Storage nicht
erreichbar ist; `appwrite/questionnaires/…` wird hochgeladen und ist im Betrieb
die Quelle. Sie müssen Zeichen für Zeichen übereinstimmen, sonst rechnet der
Server mit einer anderen Fassung als der Client anzeigt. Original ist immer die
Fassung in der App.

### Schritt 2 — die Prüfsumme berechnen

```bash
sha256sum appwrite/questionnaires/questionnaire_v1.json
```

```powershell
(Get-FileHash appwrite/questionnaires/questionnaire_v1.json -Algorithm SHA256).Hash.ToLower()
```

Für v1 im Stand dieses Commits:

```
f91d22514bb7966362790f5f3b9a59bcc100768cd195efeda9eebffc85277cfe
```

**Berechne sie auf genau der Datei, die du hochlädst, unmittelbar davor.** Eine
Prüfsumme ist byteweise. Deshalb steht in der `.gitattributes` `eol=lf` für diese
beiden Dateien: Ohne das hätte dieselbe Datei unter Windows eine andere Summe als
unter Linux, weil `core.autocrlf` beim Auschecken CRLF daraus macht — und die
Summe wäre an den Rechner gebunden, auf dem sie berechnet wurde.

### Schritt 3 — hochladen

Console → Storage → `questionnaires` → Create file. Die Datei
`appwrite/questionnaires/questionnaire_v1.json` auswählen, Rechte leer lassen
(die Bucket-Rechte gelten). Die vergebene **File-ID** notieren.

Mit der CLI:

```bash
appwrite storage create-file \
  --bucket-id questionnaires \
  --file-id questionnaire-v1 \
  --path appwrite/questionnaires/questionnaire_v1.json
```

Eine sprechende File-ID wie `questionnaire-v1` ist bequemer als eine erzeugte.

### Schritt 4 — die Release-Zeile anlegen

Console → Databases → `questionnaire_releases` → Create row:

| Spalte | Wert |
|---|---|
| `locale` | `de-DE` |
| `version` | `1` |
| `bucket_id` | `questionnaires` |
| `file_id` | die File-ID aus Schritt 3 |
| `checksum` | die Summe aus Schritt 2 |
| `active` | **true** |
| `published_at` | jetzt, ISO 8601 mit Z, z. B. `2026-09-29T12:00:00.000Z` |

Rechte der Zeile leer lassen.

### Schritt 5 — prüfen

Ruf die App auf und öffne den Fragebogen. Er sollte laden, und in der Konsole
sollte **keine** Meldung über eine nicht ladbare Definition stehen.

Der Client geht in dieser Reihenfolge: aktive Release-Zeile → Datei aus dem
Storage → lokaler Zwischenspeicher → mitgeliefertes Asset. Wenn du das Asset
bekommst, obwohl der Storage erreichbar ist, merkst du es an dieser Stelle nicht —
deshalb ist Schritt 6 wichtiger, als er aussieht.

### Schritt 6 — die Prüfsumme wirklich prüfen lassen

Schick eine Testbewertung ab (Abschnitt 13). `submit_review` lädt die Definition
über die Release-Zeile und **prüft die Summe**. Stimmt sie nicht, antwortet sie
mit einer Meldung, dass die Fassung nicht abrufbar ist, und im Function-Log steht
der Vergleich beider Summen.

Das ist die einzige Stelle, an der die Summe überhaupt geprüft wird. Der Client
prüft sie nicht, und das ist richtig: Seine Fassung bestimmt nur, was angezeigt
wird. Jeder Wert wird serverseitig gegen die Fassung neu gerechnet, die der Server
lädt und verifiziert.

---

## 10. Eine neue Version ausrollen

**Alte Versionen werden nie gelöscht.** Nicht die Datei, nicht die Release-Zeile.
Eine Bewertung, die unter v1 eingereicht wurde, wird für immer gegen v1 geprüft
und gerechnet — `recompute_all` lädt genau die Version, die in
`schema_version` steht. Fehlt sie, lässt sich die Bewertung nicht mehr neu rechnen.

Ein begonnener Entwurf bleibt ebenfalls bei seiner Version. Wer unter v1
angefangen hat, füllt v1 zu Ende, auch wenn inzwischen v2 aktiv ist.

### Der Ablauf

1. `karriko_flutter/assets/questionnaire/questionnaire_v2.json` anlegen, mit
   `"version": 2`.
2. `dart run tools/sync_questionnaire.dart`
3. Tests laufen lassen. Die Definition wird beim Laden gegen
   `packages/questionnaire_core/schema/questionnaire.schema.json` geprüft, und
   jede Verweisung — auf eine Frage, eine Antwort, eine Dimension — beim Parsen
   aufgelöst. Ein Tippfehler in einer Frage-ID fällt dort auf und nicht im
   Betrieb.
4. Prüfsumme berechnen.
5. Datei in denselben Bucket hochladen, neue File-ID.
6. Neue Zeile in `questionnaire_releases` mit `version: 2`, `active: true`.
7. **Bei der alten Zeile `active` auf `false` setzen.** Der Client nimmt die
   höchste aktive Version, also würde v1 auch mit zwei aktiven Zeilen nicht mehr
   ausgeliefert — aber zwei aktive Versionen sind eine Aussage, die niemand
   gemeint hat.
8. `QuestionnaireConstants.bundledVersion` und `bundledAsset` in der App
   nachziehen und neu bauen. Sonst liefert der Rückfall weiter v1, obwohl v2
   aktiv ist.

### Wenn sich an der Auswertung etwas geändert hat

Also an einem Punktwert, einem Gewicht, der Schrumpfungsstärke oder der
Alterungsgrenze:

```json
{ "offset": 0, "dry_run": true }
```

gegen `recompute_all`, um zu sehen, wie viele Zeilen betroffen sind. Dann ohne
`dry_run`, in Etappen, bis `done: true`. Danach für jeden Betrieb aus der
`companies`-Liste `aggregate_company` anstoßen.

**Ohne diesen Lauf stehen alte und neue Bewertungen auf verschiedenen Maßstäben**,
und der Gesamtscore eines Betriebs mischt beide.

---

## 11. Die Altdaten

**Es gibt keine.** `reviews` hat null Zeilen (Stand 1. Oktober 2026), ebenso
`review_reports`, `bookmarks` und `profiles`. Die alte Bewertungsstrecke hat ein
Schema hinterlassen, aber keine Daten.

Dieser Abschnitt bleibt trotzdem stehen, aus zwei Gründen: Die Lage kann sich
ändern, bevor die neue Strecke live geht, und wer das hier liest, soll nicht
rätseln, wo die Löschanleitung geblieben ist.

**Prüfe zuerst, ob es überhaupt etwas zu tun gibt.** Der Probelauf ist genau
dafür da und ändert nichts:

```bash
node tools/appwrite-purge-reviews.mjs --nur-alte
```

Meldet er `Nichts zu tun`, überspringe den Rest und lösche die Tabelle
stattdessen in der Console — so, wie Abschnitt 1 es beschreibt. Ein Löschen der
Tabelle ist dem Löschen einzelner Zeilen vorzuziehen, solange sie leer ist: Es
nimmt auch das Enum und die Pflichtspalten mit, die sonst jede Einreichung
scheitern lassen.

Die zwei Testzeilen in `companies` gehören ebenfalls weg. „Test GmbH" ist
verwaist — `owner_id` zeigt auf die eigene Zeilen-ID und zu keinem Nutzer.

### Der Ablauf, falls doch Zeilen da sind

Eine Zeile der alten Strecke erkennt man daran, dass ihr die `schema_version`
fehlt: Jede Zeile, die `submit_review` anlegt, trägt sie als Pflichtfeld.
`--nur-alte` filtert genau darauf; ohne den Schalter wären auch neue Zeilen
dabei, und das Skript weist dann darauf hin.

Der Probelauf von oben endet mit dem Befehl zum Löschen, samt der gefundenen
Zahl:

```bash
node tools/appwrite-purge-reviews.mjs --nur-alte --wirklich-loeschen --anzahl=137
```

Drei Sicherungen, und alle drei sind Absicht:

1. Ohne `--wirklich-loeschen` passiert nichts.
2. Vor dem Löschen entsteht ein vollständiger Export nach
   `notes/reports/exporte/`. **Scheitert er, wird nicht gelöscht.**
3. Die Zahl in `--anzahl` muss genau der gefundenen entsprechen. Wer sie nicht
   kennt, hat den Probelauf nicht gelesen. Stimmt sie nicht, hat sich der Bestand
   zwischen Probelauf und Löschen geändert, und dann willst du erst nachsehen.

### Der Export

Er liegt in `notes/reports/exporte/` und steht über die `.gitignore` außerhalb
des Repositories. **Er enthält Rohantworten und Nutzerkennungen.** Bewahre ihn so
auf, wie es für diese Daten vorgesehen ist, und nicht länger — auch dieser Punkt
steht in Abschnitt 12.

### Danach

* Die Aggregate der betroffenen Betriebe stehen noch auf den alten Zahlen.
  `recompute_all`, dann `aggregate_company`.
* In `review_reports` können Meldungen zu nun gelöschten Bewertungen
  übrigbleiben. Sie schaden nicht, zeigen in der Moderation aber ins Leere.
* Der eindeutige Index auf `user_id` + `company_id`, den Appwrite wegen doppelter
  Altzeilen vielleicht abgelehnt hat, lässt sich jetzt anlegen:
  `node tools/appwrite-setup.mjs`.
* Die alten Spalten in `reviews` — `author_id`, `is_anonymous`,
  `overall_rating`, `title`, `text`, `pros`, `cons`, `author_name`,
  `betrieb_reply`, `betrieb_replied_at` — bleiben stehen, wenn du die Tabelle
  nicht gelöscht hast. Die Pflichtspalten darunter lassen weiterhin jede
  Einreichung scheitern. Nach dem Leeren ist das Löschen und Neuanlegen der
  Tabelle der kürzere Weg als zehn Spalten einzeln wegzuklicken.

---

## 12. Datenschutz-Checkliste

**Alles in diesem Abschnitt, was mit ⚖️ markiert ist, ist juristisch zu prüfen.
Ich habe dazu keine Aussage getroffen und keine erfunden.** An den betroffenen
Stellen im Fragebogen steht `PLATZHALTER — juristisch zu prüfen`; sie sind unten
namentlich aufgeführt.

### Was technisch durchgesetzt ist

| | |
|---|---|
| ✅ | **Keine IP-Adresse wird gespeichert.** Nirgends, in keiner Tabelle, in keinem Log der Anwendung. |
| ✅ | **Die Gerätekennung nur als gesalzener Hash.** Das Salz kommt aus der Umgebung; ohne Salz wird gar nicht gehasht. Kein eingebauter Ersatzwert. |
| ✅ | **`reviews` ist für keinen Client lesbar.** Rohantworten, Bearbeitungszeiten, Qualitäts-Flags, Gerätehash und Nutzerkennung erreichen keinen Browser. |
| ✅ | **`public_reviews` trägt keine `user_id`.** Es gibt keine Verknüpfung zwischen einer veröffentlichten Bewertung und einem Konto — auch nicht für den Betreiber über die API. |
| ✅ | **Jahre, keine Monate.** Ein Monat würde eine einzelne Bewertung in einem kleinen Betrieb zuordenbar machen. |
| ✅ | **Zahlenangaben nur in Spannen, und erst ab fünf Bewertungen.** Der genaue Mittelwert wird nicht gespeichert: Aus ihm und der Zahl der Bewertungen ließen sich einzelne Angaben zurückrechnen, sobald eine dazukommt. |
| ✅ | **Scores erst ab drei Bewertungen.** Darunter steht in `company_scores` `null`, nicht ein Wert mit Warnhinweis. |
| ✅ | **Nachweise sind für niemanden lesbar** und tragen einen neutralen Dateinamen. `fileSecurity` ist ein, die Dateirechte sind leer. |
| ✅ | **Qualitäts-Flags löschen nichts.** Sie leiten in die Moderation. Automatisches Löschen trifft erfahrungsgemäß vor allem die ausführlichen, ehrlichen Bewertungen. |
| ✅ | **Eine Ablehnung braucht eine Begründung**, und sie steht im `moderation_log` mit dem Namen dessen, der entschieden hat. |

### Was du entscheiden musst

| | |
|---|---|
| ⚖️ | **Aufbewahrungsfrist für Verifikationsnachweise.** Standard 30 Tage nach der Moderationsentscheidung (`KARRIKO_VERIFICATION_RETENTION_DAYS`). Wie lange man einen solchen Nachweis aufbewahren **darf** und aufbewahren **muss**, ist keine Entwicklungsfrage. |
| ⚖️ | **Aufbewahrungsfrist für Entwürfe.** Standard 90 Tage ohne Änderung (`KARRIKO_DRAFT_RETENTION_DAYS`). Ein Entwurf enthält Antworten zu einem Betrieb, die nie abgeschickt wurden. |
| ⚖️ | **Aufbewahrung der Rohantworten.** `answers_json` bleibt unbefristet stehen, weil `recompute_all` sie braucht. Ob das zulässig ist und ob es eine Obergrenze braucht, ist offen. Es gibt heute keine Frist dafür. |
| ⚖️ | **Aufbewahrung des Exports aus Abschnitt 11.** Er enthält Rohantworten und Nutzerkennungen. Wie lange und wo. |
| ⚖️ | **Löschverlangen eines Nutzers.** Es gibt heute keinen Weg dafür. Eine Bewertung in `public_reviews` ist nicht mit einem Konto verknüpft — was Absicht ist und diesen Fall schwierig macht: Über `reviews` wäre sie auffindbar, aber das Löschen dort lässt die öffentliche Zeile stehen. **Das ist die größte offene Lücke dieser Einrichtung.** |
| ⚖️ | **Die Texte im Fragebogen.** Fünf Stellen tragen einen Platzhalter, siehe unten. |
| ⚖️ | **Aufbewahrung des Gerätehashes.** Er hat heute keine Frist. |
| ⚖️ | **Auskunftsverlangen.** Dasselbe Problem wie beim Löschverlangen, mit derselben Ursache. |

### Die fünf Platzhalter im Fragebogen

In `karriko_flutter/assets/questionnaire/questionnaire_v1.json` unter `texts`:

| Schlüssel | Was dort hingehört |
|---|---|
| `anonymity.intro` | Was der Betrieb sieht und was nicht: welche Angaben in der Einzelansicht erscheinen, welche nur aggregiert, ab wie vielen Bewertungen überhaupt etwas sichtbar wird |
| `anonymity.sensitive` | Kurzfassung der Anonymitätszusage, die vor jedem sensiblen Block erneut erscheint |
| `legal.verifikation` | Wofür der Nachweis gebraucht wird, wie lange er bleibt, wer ihn sieht, dass er pseudonym abgelegt wird |
| `help.anlaufstellen[0]` | Kontaktweg der Ausbildungsberatung der Kammer |
| `help.anlaufstellen[2]` | Kontaktweg der gewerkschaftlichen Beratung für Auszubildende |

Zu finden mit:

```bash
grep -n PLATZHALTER karriko_flutter/assets/questionnaire/questionnaire_v1.json
```

Die beiden Anlaufstellen erscheinen im Konfliktmodul; der dritte Eintrag der
Liste trägt keinen Platzhalter. Ein Platzhalter dort ist schlimmer als in einem
Rechtstext: Wer diesen Bildschirm sieht, sucht vielleicht wirklich eine
Anlaufstelle.

Zu ändern ist immer die Fassung in der App, danach
`dart run tools/sync_questionnaire.dart`, danach Abschnitt 10 — es ist eine neue
Version.

### Offene Punkte ohne Rechtsfrage

* **Ein Betrieb kann sein eigenes `is_verified` und `average_rating` setzen.**
  Appwrite kennt keine Rechte je Spalte, und die Profilbearbeitung läuft direkt
  gegen die Tabelle. Siehe Abschnitt 4a. Das Verifizierungs-Abzeichen soll ein
  Mensch vergeben; heute kann es sich jeder Betrieb selbst geben.
* **Die Moderation sieht den Nachweis nur über die Console.** Es gibt keine
  Function, die ihn ausliefert.
* **Es gibt keinen Moderationsbildschirm.** `moderate_review` wird heute über die
  Console oder einen eigenen Aufruf ausgelöst.
* **Ein Azubi kann seine abgeschickten Bewertungen nur lokal wiederfinden.** Die
  Liste liegt im Browser, nicht auf dem Server. Der Preis dafür, dass
  `public_reviews` keine `user_id` trägt.

---

## 13. Abnahmetest

Vier Durchläufe. Es sind dieselben vier, die in
`packages/questionnaire_core/test/v1_personas_test.dart` gegen die echte v1 laufen
— dort mechanisch, hier von Hand, weil ein Test nicht sieht, ob ein Bildschirm
lesbar ist.

Vorher: ein Testkonto als Azubi, ein Betrieb in `companies`, und ein Konto im Team
`moderators`.

### Vor allen vier

Öffne den Fragebogen mit Tastatur und Maus. **Jede Interaktion muss ohne Gesten
gehen.** Insbesondere:

* Der Schieberegler ohne Zahlen: Er hat **keinen Griff**, bis er angefasst,
  angeklickt oder mit der Tastatur angesprochen wird. Das ist Absicht — eine
  Vorgabe wäre eine Antwort, die niemand gegeben hat. Mit Tab hineinspringen, dann
  Pfeiltasten. Der erste Tastendruck landet in der Mitte.
* Die Wischkarten: Es gibt immer sichtbare Knöpfe für Ja, Nein und Weiß ich nicht,
  und einen zum Zurücknehmen.
* Die Reihenfolge-Frage: Sie geht per Tastatur über die Listenreihenfolge **und**
  per Antippen. Der vierte Klick ersetzt den letzten Platz.

### Persona 1 — aktueller Azubi, 1. Lehrjahr, einziger Azubi im Betrieb

Erwartet:

* Alle Fragen im **Präsens**.
* Gefragt wird nach dem **Lehrjahr**, nicht nach dem Ausbildungsende.
* Es kommen die Module Jugendarbeitsschutz, Arbeitszeit und Gesundheit.
* Es kommt **kein** Prüfungs-, Übernahme-, Abbruch- und Konfliktmodul.
* Der Hinweis auf den Kleinbetrieb (`a3_2_kleinbetrieb`) erscheint. Wähle dort
  **„erst nach Ausbildungsende"** — dann muss die Bewertung nach dem Absenden auf
  `scheduled` stehen und **nicht** in der Moderation liegen. Das ist der einzige
  Durchlauf, der das prüft.
* Die Bewertung ist veröffentlichungsfähig, die Belastungsdimension fällt
  niedriger aus.
* **A2 erscheint nicht**: Das frühe Gesamturteil und der gerechnete Detailwert
  passen zusammen, also gibt es nichts zu korrigieren.

Danach `publish_scheduled` von Hand ausführen. Solange die Frist nicht abgelaufen
ist, muss sie die Bewertung **stehen lassen** — das ist die richtige Antwort und
sieht wie „nichts passiert" aus.

### Persona 2 — ausgelernt und geblieben, 250 Mitarbeiter

Erwartet:

* Durchgehend **Vergangenheit**.
* Gefragt wird nach dem **Ende**, nicht nach dem Lehrjahr.
* Ausbilder- und Prüfungsmodul kommen über das Ranking.
* Das Übernahmemodul kommt über den Auslöser, nicht über das Ranking.
* Als Gebliebener wird er **nicht** gefragt, warum er gegangen ist.
* **Kein** Kleinbetriebshinweis.
* Durchweg hohe Werte, keine Qualitäts-Flags, auch das Konsistenzpaar passt.

### Persona 3 — Abbrecher, Konflikt-Tor angenommen

Erwartet:

* Das Abbruchmodul kommt, ein Prüfungs- oder Übernahmemodul nicht.
* Ins Konfliktmodul kommt er **nur über das Tor** — nie ungefragt.
* Die Nachfrage zur Reaktion des Betriebs kommt nur, weil er den Konflikt
  angesprochen hat.
* Er wird gefragt, ob der Betrieb etwas **gut** gemacht hat. Auch eine sehr
  schlechte Bewertung wird nach dem Guten gefragt.
* Durchweg niedrige Werte.
* Der Freitext trägt ein Flag und geht in die Moderation — **er wird nicht
  gelöscht und nicht abgelehnt**. Das ist der Unterschied.
* Hier erscheinen die beiden Hilfsangebote. Wenn dort noch `PLATZHALTER` steht,
  siehst du es an dieser Stelle.

### Persona 4 — ausgelernt und gegangen, duales Studium, alle Module abgelehnt

Erwartet:

* Vier Module werden angeboten, keines beantwortet.
* Jeder Teaser nennt **vorab** die Anzahl der Fragen und die geschätzte Dauer.
* Die Bewertung ist nach Phase 1 **trotzdem veröffentlichungsfähig**.
* **Das Überspringen kostet keinen Punkt.** Wer ein Modul ablehnt, wird nicht
  schlechter bewertet.
* Keine Qualitäts-Flags.

### Die Vorschau und das Absenden

Bei jeder Persona vor dem Absenden:

* Die Vorschau zeigt **genau** das, was danach öffentlich steht. Sie wird aus
  derselben Funktion gebildet wie die öffentliche Zeile, nicht nachgebaut.
* Es stehen **keine Sterne** dort. Balken mit einer Dezimalstelle.
* Nach dem Absenden: Status in `reviews` prüfen. Erwartet `pending_moderation`,
  oder `scheduled`, wenn A3 eine Verschiebung wollte.
* In `public_reviews` steht **noch nichts**.

### Die Moderation

Mit dem Konto aus `moderators` `moderate_review` aufrufen:

```json
{ "review_id": "…", "action": "approve", "verified": false }
```

Danach:

* `public_reviews` hat eine Zeile. Sie trägt `company_name` und `company_slug`,
  und in der Einzelansicht führt ein Knopf zum Betrieb.
* Sie trägt **keine** `user_id`, keine `answers_json`, keine `timings_json`,
  keine `quality_flags`, keinen `device_hash`. Sieh es in der Console nach.
* `moderation_log` hat einen Eintrag mit deiner Nutzerkennung.
* `company_scores` wurde neu gerechnet — `aggregate_company` lief durch das
  Ereignis. Bei weniger als drei Bewertungen steht `overall` auf `null` und
  `score_visible` auf `false`.
* `companies.average_rating` und `review_count` tragen dieselben Werte.
  Unter drei Bewertungen also `null` und die Zahl der Bewertungen. Unter
  Executions muss die Antwort `"mirrored": true` enthalten.
* Der Entwurf in `review_drafts` ist weg.

Dann eine zweite Bewertung ablehnen, ohne `reason` — der Aufruf muss
zurückgewiesen werden. Mit `reason` muss die öffentliche Zeile verschwinden und
der Status auf `rejected` stehen.

### Die Nichtdublette

Dieselbe Bewertung mit demselben Konto zum selben Betrieb noch einmal abschicken.
Erwartet: eine verständliche Meldung, dass dieser Betrieb schon bewertet wurde —
nicht ein Indexfehler.

---

## 14. Fehlersuche

### „Die Umgebungsvariable KARRIKO_DATABASE_ID fehlt"

Die Function lief ohne Variablen. `node tools/appwrite-function-env.mjs`, dann
`appwrite push function --with-variables` — **ohne** `--with-variables` werden sie
nicht mitgeschickt.

### Jede Einreichung wird abgelehnt, das Log nennt eine Spalte

Dann steht die alte `reviews` noch da. Sie hat fünf Pflichtspalten, die
`submit_review` nie schreibt, und ihr `status` ist ein Enum mit drei Werten, von
denen der Code nur einen benutzt. Abschnitt 1 beschreibt, warum die Tabelle
gelöscht und neu angelegt wird.

Nachsehen: Console → Databases → `reviews` → Columns. Steht dort `author_id`
oder ist `status` ein Enum, ist es die alte.

### Die Suche sortiert nicht nach Bewertung

`companies.average_rating` wird von `aggregate_company` gespiegelt. Prüfe in der
Antwort der Function `"mirrored": true`; steht dort `false`, fehlt dem Schlüssel
der Function das Schreibrecht auf `companies` oder die Spalte selbst. Der
angezeigte Score ist davon nicht betroffen — der kommt aus `company_scores`.

### Ein Betrieb kann sein Profil nicht mehr bearbeiten

Nach `--fix-permissions` gilt für `companies` Row Security, und das Änderungsrecht
steht pro Zeile. Zeilen, die vor dieser Umstellung ohne Zeilenrechte angelegt
wurden, sind damit gesperrt. Console → die Zeile → Permissions → `update` für
`user:<owner_id>` setzen. Bei verwaisten Testzeilen ist Löschen der richtige Weg.

### Der Build einer Function schlägt fehl, `dart pub get` findet ein Paket nicht

`vendor/` fehlt im hochgeladenen Verzeichnis. `dart run tools/vendor_core.dart`,
dann erneut pushen. Der Prüflauf sagt, welche Kopie veraltet ist:

```bash
dart run tools/vendor_core.dart --pruefen
```

### „Die Fassung des Fragebogens ist nicht abrufbar"

Vier Ursachen, und das Function-Log unterscheidet sie:

| Meldung im Log | Ursache |
|---|---|
| „ist nicht abrufbar … Alte Versionen duerfen nie geloescht werden" | Es gibt keine Release-Zeile für diese Version, oder die Datei ist weg |
| „Die Pruefsumme … stimmt nicht" | Im Bucket liegt eine andere Datei, oder die Summe in der Zeile ist falsch |
| „Das Release verweist auf Version X, die Datei enthaelt aber Version Y" | Die Datei wurde unter der Kennung einer anderen Version hochgeladen |
| „Fuer de-DE ist keine Version als aktiv markiert" | `active` steht nirgends auf `true` |

Bei der Prüfsumme: Hast du sie auf der Datei berechnet, die du hochgeladen hast?
Ein Windows-Checkout ohne die `.gitattributes` liefert eine andere.

### `moderate_review` weist jeden ab

Das Team `moderators` fehlt, oder es heißt anders als die Kennung in den Rechten.
Ein fehlendes Team heißt „niemand", nicht „alle". Console → Auth → Teams.

### `recompute_all` gibt `skipped` gleich der Stapelgröße zurück

Steht dabei `unusable_versions`, ließ sich diese Fassung nicht laden — siehe oben.
Ohne `unusable_versions` fehlt den Zeilen die `schema_version`; das sind Zeilen der
alten Strecke, siehe Abschnitt 11.

### `aggregate_company` läuft nicht

Die Ereignisnamen tragen die Datenbankkennung mitten im String. Prüfe in der
Console unter Functions → `aggregate_company` → Settings → Events, ob dort **deine**
Kennung steht. Hast du `node tools/appwrite-config.mjs` mit gesetztem
`APPWRITE_DATABASE_ID` laufen lassen?

Zum Prüfen genügt eine Zeile in `public_reviews` von Hand ändern; unter Executions
muss ein Lauf erscheinen.

### Ein eindeutiger Index lässt sich nicht anlegen

Es gibt schon doppelte Werte. Das ist ein Datenbefund, kein Fehler des Skripts.
Bei `reviews` und `user_id` + `company_id`: erst Abschnitt 11, dann
`node tools/appwrite-setup.mjs` erneut.

### Die App zeigt „Verbindung fehlgeschlagen", alles andere sieht richtig aus

Web-Plattform fehlt, siehe Abschnitt 8. In der Browserkonsole steht dann etwas
über `Access-Control-Allow-Origin`.

### Ein Index wurde übersprungen, „Spalten noch nicht bereit"

Appwrite legt Spalten im Hintergrund an. Das Skript wartet 60 Sekunden; bei vielen
Spalten auf einmal reicht das nicht immer. Einfach erneut laufen lassen — es ist
idempotent.

### Der Fragebogen lädt das mitgelieferte Asset statt der Fassung aus dem Storage

Sichtbar daran, dass eine Änderung im Bucket nicht ankommt. Mögliche Ursachen: die
Release-Zeile steht nicht auf `active`, die Bucket-Rechte lassen `read("any")`
nicht zu, oder der lokale Zwischenspeicher hält eine ältere Fassung. Der
Zwischenspeicher liegt in `shared_preferences` und lässt sich über die
Anwendungsdaten des Browsers leeren.

### Etwas stimmt, aber du weißt nicht was

Die vier Prüfläufe finden das meiste, und keiner von ihnen geht ins Netz:

```bash
dart run tools/sync_questionnaire.dart --pruefen
dart run tools/vendor_core.dart --pruefen
node tools/appwrite-config.mjs --pruefen
node tools/appwrite-setup.mjs --pruefen
```

Und ein Probelauf gegen das Projekt, der nichts ändert:

```bash
node tools/appwrite-setup.mjs --dry-run
```
