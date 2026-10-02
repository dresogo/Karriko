# Einspielen per CLI: die Befehlsfolge

Diese Datei ist zum Abarbeiten gedacht, von oben nach unten. Jeder Schritt sagt,
was er tut, was danach anders ist und was die CLI ausgeben sollte.

**Ich habe keinen dieser Befehle ausgeführt.** Sie laufen gegen dein
Produktivprojekt, und das ist deine Hand.

Das *Warum* zu jedem Schritt steht in [`APPWRITE_SETUP.md`](APPWRITE_SETUP.md).
Hier steht nur das *Was* und in welcher Reihenfolge.

Die Befehle sind für PowerShell geschrieben, weil das deine Standardshell ist.
Unter Git Bash ersetze `$env:NAME = "wert"` durch `export NAME=wert` und
`$env:NAME` durch `$NAME`.

## Inhalt

1. [Vorbereitung](#1-vorbereitung)
2. [Destruktiv: `reviews` löschen](#2-destruktiv-reviews-löschen)
3. [Tabellen, Ablagen und Teams einspielen](#3-tabellen-ablagen-und-teams-einspielen)
4. [`companies` nachziehen](#4-companies-nachziehen)
5. [Die Functions](#5-die-functions)
6. [Die Fragendefinition](#6-die-fragendefinition)
7. [Web-Plattform](#7-web-plattform)
8. [Abnahme](#8-abnahme)
9. [Testdaten aufräumen](#9-testdaten-aufräumen)
10. [Was die CLI nicht kann](#10-was-die-cli-nicht-kann)

---

## 1. Vorbereitung

### 1.1 Kennungen setzen

Alle drei stehen in der Console. Projekt-ID oben links neben dem Projektnamen
oder unter Settings → General; Datenbank-ID und -Name unter Databases → die
Datenbank.

**Der Name muss genau stimmen.** Ein abweichender Name benennt beim Push die
Datenbank um.

```powershell
$env:APPWRITE_PROJECT_ID   = "…"
$env:APPWRITE_DATABASE_ID  = "…"
$env:APPWRITE_DATABASE_NAME = "…"
$env:KARRIKO_DATABASE_ID   = $env:APPWRITE_DATABASE_ID
```

Das Salz für den Gerätehash, einmal erzeugt und danach nie geändert:

```powershell
$env:KARRIKO_DEVICE_HASH_SALT = [Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Max 256 }))
```

> Notiere es an einem sicheren Ort, **bevor** du die Shell schließt. Ein neues
> Salz macht alte Gerätehashes unvergleichbar.

### 1.2 Anmelden

```powershell
appwrite login
appwrite whoami
```

`whoami` muss dein Konto und den richtigen Endpunkt zeigen. Steht dort ein
anderes Projekt, hilft `appwrite client --help`.

### 1.3 Erzeugte Dateien bauen

```powershell
dart run tools/vendor_core.dart
node tools/appwrite-config.mjs
node tools/appwrite-function-env.mjs
```

Erwartete Ausgabe des zweiten Befehls: `appwrite/appwrite.config.json
geschrieben`, mit deiner Projekt- und Datenbankkennung in der Zusammenfassung.
Der dritte schreibt sechs `.env`, davon eine mit Salz.

### 1.4 Prüfläufe

Keiner geht ins Netz. Alle müssen mit Code 0 enden.

```powershell
dart run tools/sync_questionnaire.dart --pruefen
dart run tools/vendor_core.dart --pruefen
node tools/appwrite-config.mjs --pruefen
node tools/appwrite-function-env.mjs --pruefen
node tools/appwrite-setup.mjs --pruefen
```

Der letzte vergleicht das Schema im Setup-Skript mit dem in der Vorlage und muss
melden: `beschreiben dasselbe Schema. 7 Tabelle(n), 2 Bucket(s) verglichen.`

Die fünf setzen voraus, dass Schritt 1.3 gelaufen ist: Drei von ihnen prüfen
gegen Dateien, die dort erst entstehen. Deshalb laufen sie hier und nicht in der
CI — dort gibt es diese Dateien nicht, und `.github/workflows/dart.yml` prüft
stattdessen, dass sie sich erzeugen lassen.

### 1.5 Ein Blick auf den Bestand, bevor etwas passiert

```powershell
appwrite tables-db list-tables --database-id $env:APPWRITE_DATABASE_ID
```

Erwartet: `profiles`, `companies`, `reviews`, `bookmarks`, `review_reports`,
`jobs`.

```powershell
appwrite tables-db list-rows --database-id $env:APPWRITE_DATABASE_ID --table-id reviews
```

**Erwartet: `total: 0`.** Steht dort eine andere Zahl, halte an — dann gibt es
Altdaten, und Abschnitt 11 von `APPWRITE_SETUP.md` gilt doch. Ohne diese
Prüfung nicht weiter.

---

## 2. Destruktiv: `reviews` löschen

Ab hier wird gelöscht. **Dieser Schritt ist nicht umkehrbar.**

Warum überhaupt: Die bestehende Tabelle hat fünf Pflichtspalten, die
`submit_review` nie schreibt, und ihr `status` ist ein Enum mit drei Werten, von
denen der Code nur einen benutzt. Es käme keine einzige Bewertung durch. Ein Enum
lässt sich nicht erweitern, nur löschen und neu anlegen — und dann ist die ganze
Tabelle der kürzere Weg als zehn Spalten einzeln.

Noch einmal nachsehen, dass sie leer ist:

```powershell
appwrite tables-db list-rows --database-id $env:APPWRITE_DATABASE_ID --table-id reviews
```

Erst wenn dort `total: 0` steht:

```powershell
appwrite tables-db delete-table --database-id $env:APPWRITE_DATABASE_ID --table-id reviews
```

Danach:

```powershell
appwrite tables-db list-tables --database-id $env:APPWRITE_DATABASE_ID
```

`reviews` darf nicht mehr auftauchen. Taucht es auf, hat das Löschen nicht
gegriffen, und der nächste Schritt würde die neuen Spalten neben die alten
schreiben.

---

## 3. Tabellen, Ablagen und Teams einspielen

Aus dem Ordner `appwrite/`, **nicht** aus dem Wurzelverzeichnis: Die
`path`-Angaben der Functions sind relativ zur Konfigurationsdatei.

```powershell
cd appwrite
```

### 3.1 Tabellen

**Ohne `-f`.** Die CLI zeigt dann, was sie ändern würde, und fragt.

```powershell
appwrite push table
```

Was sie anzeigen sollte:

| | |
|---|---|
| **Anlegen** | `reviews`, `questionnaire_releases`, `review_drafts`, `public_reviews`, `company_scores`, `moderation_log` |
| **Ändern** | `review_reports` — Row Security von aus auf an, Rechte dazu. Null Zeilen, also unkritisch |
| **Nicht dabei** | `companies`, `profiles`, `bookmarks`, `jobs` |

Meldet sie bei `reviews` **Änderungen statt Anlegen**, steht die alte Tabelle
noch da: zurück zu Abschnitt 2.

Meldet sie eine Änderung an der Datenbank selbst, stimmt
`APPWRITE_DATABASE_NAME` nicht mit dem echten Namen überein. Abbrechen,
korrigieren, `node tools/appwrite-config.mjs` erneut.

Appwrite legt Spalten im Hintergrund an. Danach kontrollieren:

```powershell
appwrite tables-db list-columns --database-id $env:APPWRITE_DATABASE_ID --table-id reviews
```

Jede Spalte muss `status: available` tragen. Steht irgendwo `processing`, warte
und frage erneut; steht `failed`, lege die Spalte einzeln nach.

### 3.2 Ablagen

```powershell
appwrite push bucket
```

Erwartet: `questionnaires` und `verification_documents` werden angelegt.

Prüfen, dass `verification_documents` den Schalter trägt, auf dem alles hängt:

```powershell
appwrite storage get-bucket --bucket-id verification_documents
```

`fileSecurity` muss `true` sein. Ist er `false`, gelten die Bucket-Rechte statt
der leeren Dateirechte, und die Nachweise wären lesbar.

### 3.3 Teams

```powershell
appwrite push team
```

Erwartet: `moderators` und `admins`. **Die Kennungen müssen genau so lauten** —
die Ausführungsrechte der Functions heißen `team:moderators` und `team:admins`.

```powershell
appwrite teams list
```

Mitglieder fügst du danach in der Console hinzu (Auth → Teams) oder mit
`appwrite teams create-membership`.

> Ein fehlendes Team heißt „niemand", nicht „alle". Wenn `moderate_review`
> später jeden abweist, fehlt vermutlich das Team.

---

## 4. `companies` nachziehen

`companies` steht **absichtlich nicht** in der Konfiguration: Die Tabelle hat
Spalten und Indizes, die die Vorlage nicht vollständig beschreibt, und ein Push
würde sie nach dieser Teilbeschreibung umschreiben.

Zurück ins Wurzelverzeichnis:

```powershell
cd ..
```

### 4.1 Erst sehen, was abweicht

```powershell
$env:APPWRITE_API_KEY = "…"
```

Der Schlüssel kommt aus Console → Overview → Integrations → API Keys, mit
`databases.*`, `tables.*`, `rows.*`, `buckets.*`, `files.*`. **Setze ein
Ablaufdatum.** Er gehört in keine Datei.

```powershell
node tools/appwrite-setup.mjs --dry-run
```

Erwartet bei `companies`: der Hinweis, dass `update("users")` zu viel ist, und
zwei fehlende Indizes. Die Spalten `average_rating` und `review_count` bestehen
schon und werden übersprungen.

### 4.2 Die Rechte engerziehen

Im Bestand darf **jeder angemeldete Nutzer jede Firma ändern** — auch
`is_verified`, `is_premium`, `owner_id` und den Score, nach dem die Suche
sortiert. Der Client setzt beim Anlegen schon ein Änderungsrecht für den
Eigentümer pro Zeile; das wirkt aber erst mit Row Security.

```powershell
node tools/appwrite-setup.mjs --fix-permissions
```

Oder, wenn du es ohne das Skript machen willst — **beide Schalter zusammen**:

```powershell
appwrite tables-db update-table --database-id $env:APPWRITE_DATABASE_ID --table-id companies --name Companies --permissions 'read("any")' --permissions 'create("users")' --row-security
```

> `--row-security` ist ein Schalter ohne Wert. Lässt man ihn weg, kann die CLI
> ihn als „aus" senden. Gib bei jedem `update-table` **immer beide** mit und
> prüfe danach das Ergebnis.

```powershell
appwrite tables-db get-table --database-id $env:APPWRITE_DATABASE_ID --table-id companies
```

Erwartet: `rowSecurity: true`, und in `$permissions` nur `read("any")` und
`create("users")`.

**Was dabei kaputtgeht:** Firmenzeilen ohne Zeilenrechte sind danach nicht mehr
bearbeitbar. Das betrifft die verwaiste Testzeile „Test GmbH" — siehe
Abschnitt 9.

**Was damit nicht behoben ist:** Der Eigentümer kann auf seiner eigenen Zeile
`is_verified` und `average_rating` setzen. Appwrite kennt keine Rechte je Spalte.
Die Lösung wäre, Profiländerungen über eine Function zu führen; das ist nicht
gebaut.

### 4.3 Die zwei Indizes

Das Skript legt sie mit an. Einzeln wäre es:

```powershell
appwrite tables-db create-index --database-id $env:APPWRITE_DATABASE_ID --table-id companies --key average_rating --type key --columns average_rating --orders DESC
```

```powershell
appwrite tables-db create-index --database-id $env:APPWRITE_DATABASE_ID --table-id companies --key industry --type key --columns industry --orders ASC
```

Beide bedienen Abfragen, die die Suche schon stellt — Sortierung nach Bewertung
und Filter nach Branche. Ohne Index liest Appwrite dafür die Tabelle durch.

---

## 5. Die Functions

```powershell
cd appwrite
```

**`--with-variables` ist nicht optional.** Ohne das Flag werden die Variablen
nicht mitgeschickt, und jede Function bricht beim Start mit „Die
Umgebungsvariable KARRIKO_DATABASE_ID fehlt" ab.

```powershell
appwrite push function --with-variables
```

Die CLI baut jede der sechs einzeln und zeigt das Build-Log. `dart pub get` muss
durchlaufen. Findet es ein Paket nicht, fehlt `vendor/` im Upload — zurück zu
Schritt 1.3.

Danach kontrollieren:

```powershell
appwrite functions list
```

Erwartet: sechs Functions, jede mit `runtime: dart-3.11` und einem aktiven
Deployment.

Dann je Function die Einstellungen, die der Push gesetzt haben sollte:

```powershell
appwrite functions get --function-id aggregate_company
```

| Function | Prüfen |
|---|---|
| `submit_review` | `execute: ["users"]`, Timeout 30 |
| `moderate_review` | `execute` enthält `team:moderators` und `team:admins` |
| `aggregate_company` | drei `events` auf `public_reviews`, **mit deiner Datenbankkennung im String**, `execute` leer |
| `publish_scheduled` | `schedule: "0 * * * *"`, `execute` leer |
| `recompute_all` | `execute: ["team:admins"]` |
| `cleanup` | `schedule: "30 3 * * *"`, `execute` leer |

**Die Scopes prüfe in der Console** (Functions → *Function* → Settings →
Scopes). Dass es `rows.read` und `rows.write` heißt und nicht `documents.*`, ist
belegt; `files.read`, `files.write` und `teams.read` sind begründet und
ungeprüft. Lehnt die CLI einen Namen ab, zeigt die Console die gültige Liste —
dann den Wert in `appwrite.config.template.json` korrigieren und
`node tools/appwrite-config.mjs` erneut laufen lassen, **nicht** in der erzeugten
Datei.

`specification` steht absichtlich nicht in der Konfiguration, damit kein
erfundener Wert den Push scheitern lässt. Es gilt die Voreinstellung des
Projekts. Läuft etwas ins Timeout, setze sie in der Console nach und trage sie in
die Vorlage ein.

---

## 6. Die Fragendefinition

Sie liegt nicht in der Datenbank, sondern als Datei im Storage. In
`questionnaire_releases` steht nur der Verweis.

```powershell
cd ..
```

### 6.1 Die beiden Kopien gleichhalten

```powershell
dart run tools/sync_questionnaire.dart
```

### 6.2 Prüfsumme berechnen

```powershell
(Get-FileHash appwrite/questionnaires/questionnaire_v1.json -Algorithm SHA256).Hash.ToLower()
```

Erwartet, solange v1 unverändert ist:

```
f91d22514bb7966362790f5f3b9a59bcc100768cd195efeda9eebffc85277cfe
```

**Berechne sie auf genau der Datei, die du hochlädst.** Eine Prüfsumme ist
byteweise. Die `.gitattributes` legt `eol=lf` für diese Datei fest, damit sie
unter Windows und Linux gleich ausfällt — ohne das wäre die Summe an den Rechner
gebunden.

### 6.3 Hochladen

```powershell
appwrite storage create-file --bucket-id questionnaires --file-id questionnaire-v1 --file appwrite/questionnaires/questionnaire_v1.json
```

Das Flag heißt `--file`, nicht `--path`. Eine sprechende File-ID ist bequemer als
eine erzeugte.

Keine Dateirechte setzen. Die CLI vergibt zwar standardmäßig alle Rechte an dein
Konto, aber `questionnaires` hat `fileSecurity: false` — damit gelten
ausschließlich die Bucket-Rechte, und die sind `read("any")`.

### 6.4 Die Release-Zeile

Setze die Summe aus 6.2 ein und einen Zeitstempel in ISO 8601 mit `Z`:

```powershell
appwrite tables-db create-row --database-id $env:APPWRITE_DATABASE_ID --table-id questionnaire_releases --row-id "ID.unique()" --data '{\"locale\":\"de-DE\",\"version\":1,\"bucket_id\":\"questionnaires\",\"file_id\":\"questionnaire-v1\",\"checksum\":\"f91d22514bb7966362790f5f3b9a59bcc100768cd195efeda9eebffc85277cfe\",\"active\":true,\"published_at\":\"2026-10-01T12:00:00.000Z\"}'
```

Die Zeichenkette für eine erzeugte Kennung ist `ID.unique()`, nicht `unique()`.

Zeilenrechte braucht die Zeile nicht: `questionnaire_releases` hat Row Security
aus, also gelten allein die Tabellenrechte.

> Das Maskieren der Anführungszeichen in PowerShell ist lästig. Wenn der Befehl
> an der Zeichenkette scheitert, lege die Zeile in der Console an — Databases →
> `questionnaire_releases` → Create row. Die sieben Felder stehen in
> `APPWRITE_SETUP.md` Abschnitt 9.4.

Kontrolle:

```powershell
appwrite tables-db list-rows --database-id $env:APPWRITE_DATABASE_ID --table-id questionnaire_releases
```

Genau eine Zeile, `active: true`, `version: 1`.

---

## 7. Web-Plattform

Ohne diesen Schritt antwortet Appwrite auf jeden Aufruf aus dem Browser mit
einem CORS-Fehler, und die App zeigt „Verbindung fehlgeschlagen" — obwohl alles
andere stimmt.

Der Hostname kommt **ohne** Protokoll und ohne Pfad und ohne Port.

```powershell
appwrite project create-web-platform --platform-id "ID.unique()" --name "Karriko Web" --hostname karriko.de
```

Für die Entwicklung eine zweite:

```powershell
appwrite project create-web-platform --platform-id "ID.unique()" --name "Karriko lokal" --hostname localhost
```

```powershell
appwrite project list-platforms
```

Dazu passend muss die App gebaut werden, sonst zeigen die Links aus
Bestätigungsmails ins Leere:

```powershell
flutter build web --dart-define=APP_ORIGIN=https://karriko.de
```

---

## 8. Abnahme

Die Reihenfolge ist wichtig: Erst der technische Durchstich, dann die vier
Personas.

### 8.1 Durchstich

```powershell
appwrite functions create-execution --function-id cleanup --body '{\"dry_run\":true}'
```

Erwartet eine Antwort mit `ok: true` und `dry_run: true`, keine 503. Eine 503
mit „Nicht eingerichtet" heißt: Variablen fehlen, also `--with-variables`
vergessen.

```powershell
appwrite functions create-execution --function-id recompute_all --body '{\"offset\":0,\"dry_run\":true}'
```

Erwartet `recomputed: 0`, `done: true` — es gibt noch keine Bewertungen. Eine
403 heißt, dein Konto ist nicht im Team `admins`.

### 8.2 Die vier Personas

Von Hand in der App, nach dem Drehbuch in `APPWRITE_SETUP.md` Abschnitt 13. Der
wichtigste Teil davon, kurz:

* **Persona 1** wählt beim Kleinbetriebshinweis „erst nach Ausbildungsende". Die
  Bewertung muss danach auf `scheduled` stehen und **nicht** in der Moderation
  liegen.
* **Persona 3** bekommt das Konfliktmodul nur über das Tor, und ihr Freitext geht
  in die Moderation — er wird nicht gelöscht und nicht abgelehnt.
* **Persona 4** lehnt alle vier Module ab und ist trotzdem
  veröffentlichungsfähig. Das Überspringen kostet keinen Punkt.
* Bei jeder: Die Vorschau zeigt genau das, was danach öffentlich steht, und es
  stehen keine Sterne dort.

Nach dem Absenden:

```powershell
appwrite tables-db list-rows --database-id $env:APPWRITE_DATABASE_ID --table-id reviews
```

Status `pending_moderation` oder `scheduled`. In `public_reviews` steht noch
nichts.

### 8.3 Die Moderation

```powershell
appwrite functions create-execution --function-id moderate_review --body '{\"review_id\":\"…\",\"action\":\"approve\",\"verified\":false}'
```

Danach prüfen:

```powershell
appwrite tables-db list-rows --database-id $env:APPWRITE_DATABASE_ID --table-id public_reviews
```

Die Zeile muss `company_name` und `company_slug` tragen und **keine** `user_id`,
`answers_json`, `timings_json`, `quality_flags` und keinen `device_hash`. Das ist
die Prüfung, auf die es ankommt — sieh sie wirklich an.

```powershell
appwrite tables-db list-rows --database-id $env:APPWRITE_DATABASE_ID --table-id company_scores
```

`review_count: 1`, `score_visible: false`, `overall: null` — unter drei
Bewertungen steht dort kein Score.

```powershell
appwrite tables-db get-row --database-id $env:APPWRITE_DATABASE_ID --table-id companies --row-id "…"
```

`average_rating: null` und `review_count: 1`: Die Spiegelung hat gegriffen, und
sie hält sich an dieselbe Schwelle.

Dann eine zweite Bewertung **ohne** `reason` ablehnen — der Aufruf muss
zurückgewiesen werden. Eine Ablehnung ohne Begründung ist für den Verfasser nicht
nachvollziehbar.

---

## 9. Testdaten aufräumen

Zwei Zeilen in `companies`, beide Testdaten. „Test GmbH" ist verwaist: Ihr
`owner_id` zeigt auf ihre eigene Zeilen-ID und zu keinem Nutzer. Nach Schritt 4.2
ist sie ohnehin nicht mehr bearbeitbar.

Erst ansehen, dann löschen:

```powershell
appwrite tables-db list-rows --database-id $env:APPWRITE_DATABASE_ID --table-id companies
```

```powershell
appwrite tables-db delete-row --database-id $env:APPWRITE_DATABASE_ID --table-id companies --row-id "…"
```

> Lösche sie erst **nach** der Abnahme, falls du sie als Testbetrieb brauchst.
> Und lösche keine Firma, zu der schon eine Bewertung existiert: In
> `public_reviews` bliebe eine Zeile mit `company_id` ins Leere stehen.

Nicht vergessen, falls du Testbewertungen angelegt hast: Sie gehören vor dem
Livegang weg, und dafür ist `tools/appwrite-purge-reviews.mjs` da — Probelauf als
Standard, Export vor dem Löschen, erwartete Zeilenzahl.

```powershell
node tools/appwrite-purge-reviews.mjs
```

---

## 10. Was die CLI nicht kann

Vollständig, damit nichts unbemerkt liegen bleibt.

| Schritt | Warum von Hand |
|---|---|
| **Scopes der Functions prüfen** | Die gültigen Namen stehen nur in der Console. Der Push setzt sie; ob sie angenommen wurden, zeigt die Console. |
| **`KARRIKO_DEVICE_HASH_SALT` als Secret markieren** | Der Schalter „Secret" bei einer Variablen ist ein Console-Schalter. Ohne ihn zeigt die Console den Wert im Klartext. Functions → `submit_review` → Settings → Variables. |
| **Mitglieder in die Teams** | Geht mit `appwrite teams create-membership`, braucht aber die Nutzerkennungen. Über die Console ist es weniger fehleranfällig. |
| **Wertgrenzen auf bestehenden Spalten** | `companies.average_rating` hat keine `min`/`max`. Eine bestehende Spalte lässt sich so nicht ändern — nur löschen und neu anlegen. Bei zwei Testzeilen billig, später nicht. |
| **Den Nachweis einer Bewertung ansehen** | Es gibt keine Function dafür. Die Moderation öffnet die Datei in der Console. |
| **Die fünf Platzhaltertexte** | `PLATZHALTER — juristisch zu prüfen` im Fragebogen. Sie werden in der App geändert, dann `sync_questionnaire.dart`, dann als neue Version ausgerollt. Siehe `APPWRITE_SETUP.md` Abschnitte 10 und 12. |

### Und was gar nicht geht

* **Ein Löschverlangen eines Nutzers umsetzen.** Es gibt keinen Weg dafür.
  `reviews` findet die Bewertung über `user_id`, aber das Löschen dort lässt die
  öffentliche Zeile stehen. Die größte offene Lücke.
* **Ein Azubi kann seine abgeschickten Bewertungen nur lokal wiederfinden.** Die
  Liste liegt im Browser. Dafür wäre eine siebte Function `my_reviews` nötig —
  dieselbe Zuordnung, die auch ein Löschverlangen bräuchte.

---

## Kurzfassung

Wenn alles vorbereitet ist und du nur die Reihenfolge brauchst:

```
1.  Kennungen und Salz setzen, appwrite login
2.  dart run tools/vendor_core.dart
    node tools/appwrite-config.mjs
    node tools/appwrite-function-env.mjs
    … jeweils --pruefen
3.  list-rows reviews  →  muss 0 sein
4.  delete-table reviews
5.  cd appwrite
    appwrite push table      (ohne -f, Ausgabe lesen)
    appwrite push bucket
    appwrite push team
6.  cd ..
    node tools/appwrite-setup.mjs --dry-run
    node tools/appwrite-setup.mjs --fix-permissions
7.  cd appwrite
    appwrite push function --with-variables
8.  cd ..
    dart run tools/sync_questionnaire.dart
    Get-FileHash …
    appwrite storage create-file
    appwrite tables-db create-row  (questionnaire_releases, active: true)
9.  appwrite project create-web-platform
10. Abnahme: Abschnitt 8
11. In der Console: Salz als Secret markieren, Teams besetzen, Scopes prüfen
```
