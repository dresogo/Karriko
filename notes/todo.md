# Karriko – Offene Aufgaben

**Erstellt:** 30. August 2026 · **Fortgeschrieben:** 2. Oktober 2026, nach dem Einspielen des Schemas
**Grundlage:** `notes/projekt-referenz.md`, `notes/reports/status-report-2026-08-02.md` (Stand 2. Oktober), `notes/reports/sicherheitsbericht-2026-08-04.md`, `notes/UMSETZUNG_BERICHT.md`, `notes/APPWRITE_EINSPIELEN.md`
**Branch:** `fragebogen` mit offenem Pull Request #9 · letzter Commit `7cf5b7e` · `main` steht auf `7dcb7b3`

Diese Liste führt zusammen, was in beiden Berichten als offen steht — sortiert nach Art der Arbeit, nicht nach Herkunftsdokument. Die Kürzel in Klammern verweisen auf die Abschnitte dort.

**Wichtig zum Umgang mit dieser Datei:** Erledigtes wird abgehakt, nicht gelöscht. Die Lehre aus dem ZAP-Scan vom Juni (Projektreferenz §4.3) war genau die: Ein Befund verschwindet nicht dadurch, dass ihn niemand mehr weiterführt.

---

## A. Sofort — steht über allem anderen

- [x] **Das Appwrite-Schema einspielen** (Status 14.4, Reihenfolge 0c) — **erledigt am 2. Oktober 2026**

  Eingespielt: sechs neue Tabellen (`reviews` neu, `questionnaire_releases`, `review_drafts`, `public_reviews`, `company_scores`, `moderation_log`), zwei Ablagen, zwei Teams, sieben Functions, die Fragendefinition samt Release-Zeile. Beide nicht umkehrbaren Schritte sind gelaufen: `reviews` gelöscht (vorher `total: 0` bestätigt) und `update("users")` von `companies` entfernt.

  **Anders als in `APPWRITE_EINSPIELEN.md` beschrieben:** Tabellen und Ablagen kamen nicht per `appwrite push table/bucket`, sondern in einem Lauf über `node tools/appwrite-setup.mjs --fix-permissions`. Das Skript deckt dasselbe Schema ab (`--pruefen` belegt es) und vermeidet die zwei Risiken des Push: Umbenennen der Datenbank bei abweichendem Namen und das Angebot, bestehende Spalten zu entfernen. Die CLI blieb für Teams, Functions und den Datei-Upload.

  **Geprüft:**
  - `--dry-run` nach dem Lauf meldet keine Abweichung mehr
  - Row Security je Tabelle wie vorgesehen, `companies` und `review_reports` jetzt `true`
  - Alle sieben Functions `ready` auf `dart-3.11` — die Runtime war vorher ungeprüft
  - `aggregate_company` trägt die drei Ereignisse mit der echten Datenbankkennung; die Scopes `rows.*` und `files.read` wurden angenommen
  - Prüfsumme der Fragendefinition stimmt
  - Durchstich `cleanup` mit `dry_run`: Status 200, `ok: true`

  **Unterwegs festgestellt:**
  - `appwrite push function` legt für jede Function eine **öffentliche Domain** unter `*.appwrite.network` an. Geprüft: Sie hält sich an `execute` und antwortet ohne Anmeldung mit `router_unauthorized_execution`. Kann bleiben.
  - Das Salz für den Gerätehash ist per CLI als Secret markiert, der Wert blieb unverändert. Es liegt außerdem lokal in `appwrite/functions/submit_review/.env` (gitignored) und gehört zusätzlich in den Passwortmanager.
  - Die Release-Zeile trägt die ID `unique` statt einer erzeugten. Schadet nicht, gefunden wird sie über `locale` und `active`.

- [ ] **Eigenes Konto für Moderation und Administration anlegen** — blockiert den Rest der Abnahme
  In der App registrieren, E-Mail bestätigen, dann in die Teams `moderators` und `admins` eintragen (`appwrite teams create-membership`). Bewusst **nicht** eines der beiden Testkonten: Das Azubi-Konto ist Verfasser, und wer die eigene Bewertung freigibt, verwischt genau die Trennung, die die Abnahme zeigen soll.

- [ ] **Abnahmetest mit den vier Personas** — `APPWRITE_SETUP.md` Abschnitt 13, `APPWRITE_EINSPIELEN.md` Abschnitt 8
  Das ist das Erste, was das Zusammenspiel zeigt. Offen: Durchstich `recompute_all`, die vier Personas, Moderation, `my_reviews` mit zwei Konten.
  **Lücke in der Befehlsfolge:** §8.1 und §8.3 rufen `recompute_all` und `moderate_review` per `appwrite functions create-execution` auf. Die CLI läuft aber als Console-Konto, und beide Functions verlangen die Kennung eines **Projektkontos** (`ctx.userId`). So aufgerufen brechen sie mit 401 ab, unabhängig von den Teams. Gangbar: per API-Schlüssel ein JWT für das Moderationskonto ausstellen und damit aufrufen. Eine Moderationsoberfläche in der App gibt es nicht.

- [ ] **`APPWRITE_EINSPIELEN.md` nachziehen** — nach der Abnahme
  Skriptweg statt `push table/bucket` (§3), die öffentlichen Function-Domains (§5), der JWT-Weg für Moderation und `recompute_all` (§8), `ID.unique()` in PowerShell (§6.4), der doppelte Spiegelstrich in §10. Außerdem: Die CLI kennt das Projekt nur aus dem Ordner `appwrite/` heraus, im Wurzelverzeichnis meldet sie „project is not set".

- [ ] **API-Schlüssel nach der Abnahme entfernen** — die Datei unter `karriko_local/` löschen und den Schlüssel in der Console widerrufen, nicht nur ablaufen lassen.

- [x] **Zugangsdaten-Zeile aus der Git-Historie klären** (Status 7.10, Sicherheit S10) — **erledigt am 30. August 2026**

  **Prüfergebnis: kein Konto dahinter.** Vom Betreiber bestätigt; eine Rotation entfällt damit.

  **Der Befund war trotzdem schwerer als in beiden Berichten beschrieben.** Dort steht, die Zeile liege „in der Historie". Tatsächlich stand sie im **aktuellen Stand von `main`** eines **öffentlichen** Repositories: Hinzugefügt in `9d25f8d` am 4. August, gelöscht erst in `60ec9e6` — und der Commit lag nur auf dem Feature-Branch. Die Datei war damit 26 Tage lang unter `github.com/dresogo/Karriko/blob/main/notes/fehler.md` in der Standardansicht abrufbar. Wäre der Wert echt gewesen, hätte das eine sofortige Rotation erzwungen.

  **Durchgeführt:**
  1. Vollständiges Bundle-Backup aller Refs vor dem Eingriff.
  2. `notes/fehler.md` auf `main` per regulärem Commit entfernt.
  3. `git filter-repo --replace-text` über die eine Zeile — bewusst **nicht** die ganze Datei aus der Historie entfernt: Der Textersatz ändert nur drei Commit-Hashes statt der gesamten Historie ab `4d7d598`.
  4. Gegenprobe über alle erreichbaren Blobs und alle Commit-Diffs: kein Treffer mehr.
  5. Force-Push von `main` und `feat/anmeldeverfahren` mit `--force-with-lease`.

  **Folgewirkung:** Sämtliche Commit-Hashes ab `9d25f8d` haben sich geändert (`main`: `9d25f8d` → `e116bea`, `feat/anmeldeverfahren`: `97338c8` → `568c9e9`). Ältere Commits sind unberührt. **Bestehende Klone müssen neu aufgesetzt werden** — wie schon nach der Bereinigung am 3. August.

- [ ] **Restpunkt: unerreichbare Objekte bei GitHub purgen lassen**
  Der alte Commit `9d25f8d` ist über die GitHub-API **weiterhin per SHA abrufbar**, samt Dateiinhalt — GitHub räumt unerreichbare Objekte nicht zuverlässig von selbst ab. Ein Force-Push entfernt einen Wert also aus der Ansicht, nicht aus dem Speicher.
  Vollständig beseitigen lässt sich das nur über eine Anfrage an den GitHub-Support („purge unreachable objects"). Hier verzichtbar, weil der Wert bedeutungslos ist — **aber für den nächsten echten Fund ist genau das der Schritt, der sonst vergessen wird.** Forks gab es keine, sonst käme deren Bereinigung hinzu.

---

## B. Datenschicht — die Kernfunktionen tragen noch nicht

Reihenfolge ist hier nicht beliebig: Punkt 1 ist das Schlüsselstück, an dem mehrere andere hängen.

- [x] **1. `companies`-Dokument bei der Betriebsregistrierung anlegen** und die ID im Profil hinterlegen (Status 2.3) — **erledigt am 30. August 2026**

  `registerBetrieb()` legt jetzt vor dem Profil ein `companies`-Dokument an und hinterlegt dessen ID an beiden Orten, an denen die App sie liest: im Profildokument und in den Account-Prefs. Damit ist **2.3 mit erledigt** — das Unternehmensprofil speichert wirklich, der Hinweis „gilt nur für diese Sitzung" ist weg, und `updateCompanyProfile()` hat erstmals einen Aufrufer.

  Drei Entscheidungen, die nicht offensichtlich sind:
  - **`ensureCompany()` als Reparaturweg.** Ohne ihn hätte die Änderung nur neuen Registrierungen geholfen; **bestehende Betriebskonten hätten dauerhaft keine Firma.** Der Weg sucht erst über `owner_id` und legt nur an, wenn nichts gefunden wird — sonst entstünde bei jedem Konto mit verlorener Verknüpfung ein zweites Unternehmen mit eigener Adresse und eigenen Bewertungen. Aufgerufen wird er nicht bei jedem Laden, sondern erst, wenn ein Betrieb seine Daten braucht.
  - **Der Slug bleibt bei Umbenennung stehen.** Er steht in der öffentlichen Adresse; eine Umbenennung ändert die Anzeige, nicht den Link.
  - **Kein Löschrecht am Firmendokument**, auch nicht für den Eigentümer. Beim Löschen eines Betriebskontos bleiben die Bewertungen erhalten (Projektreferenz §3.4) — ein Löschrecht würde genau das aushebeln.

  **Nicht gelöst:** Schlägt das Anlegen bei der Registrierung fehl, läuft sie trotzdem durch (Konto und Sitzung bestehen zu dem Zeitpunkt schon). Die Verknüpfung zieht dann `ensureCompany` nach.

- [x] **1b. Schema in der Appwrite Console nachziehen** — **erledigt am 31. August 2026**
  Der Code schrieb zwei Felder, die es in der Console geben musste:
  - `profiles.company_id` — String
  - `companies.owner_id` — String, **mit Index** (ohne ihn findet `findCompanyByOwner` nichts und der Reparaturweg legt Doppel-Firmen an)

  Dazu die Collection `companies` auf „Create" für angemeldete Nutzer stellen, sonst scheitert die Betriebsregistrierung am Anlegen. Ein eindeutiger Index auf `slug` wäre die einzige verbindliche Absicherung gegen doppelte Adressen — die Kollisionsprüfung im Client ist gegen den realistischen Fall wirksam, aber kein Ersatz.

  **Am 31. August bestätigt, dass es im echten Betrieb nicht greift** (Status 13.5): Das Unternehmensprofil eines Testkontos meldet „Die Unternehmensdaten konnten nicht geladen werden." Damit ist dieser Punkt nicht mehr vorsorglich, sondern ein laufender Fehler — und er blockiert zusätzlich das Ausschreiben von Stellen, denn die Stelle braucht Kennung und Adresse des Unternehmens.

  **Ursache am 31. August direkt gegen die Instanz nachgewiesen:** `companies` hatte keine Spalte `owner_id` — die Abfrage antwortete mit `400 Invalid query: Attribute not found in schema: owner_id`. Sie steht in `findCompanyByOwner()`, an dem `ensureCompany()` hängt; deshalb erschien die Meldung auf *jeder* Betriebsseite, nicht nur im Profil. Der Probelauf zeigte zusätzlich, dass auch `profiles.company_id` fehlte — deshalb scheiterte schon `_createProfileDocument()` bei jeder Betriebsregistrierung, und die Verknüpfung war an *beiden* vorgesehenen Orten leer.

  **Nachgezogen mit [`tools/appwrite-setup.mjs`](../tools/appwrite-setup.mjs)** statt per Hand in der Console: idempotent, legt nur an, was fehlt, und dokumentiert damit den Soll-Zustand des Schemas an einer Stelle, die mit dem Code mitwandert. Rechte ändert es nur mit `--fix-permissions` — Rechte zu weiten ist eine Entscheidung, keine Reparatur. Angelegt wurden `companies.owner_id` samt Index, der eindeutige Index auf `slug`, `profiles.company_id` und das „Create"-Recht für angemeldete Nutzer auf `companies`.

  **Ein Handgriff blieb bewusst manuell:** Die bestehende „Test GmbH" bekam ihre `owner_id` in der Console eingetragen. Ein Skript hätte raten müssen, welches Konto welche Firma besitzt; bei einem einzigen Altbestand ist das die falsche Sorte Automatik.

- [x] **1c. Collection `jobs` in der Console anlegen** — **erledigt am 31. August 2026**
  Der Code schrieb und las sie vollständig, angelegt war sie nicht (bestätigt: `404 table_not_found`). Ohne sie blieben Stellenband, Stellenseite und das Vorschlagsband der Suche leer, und jedes Speichern meldete einen Fehler. Dasselbe Skript legt sie mit allen Spalten, Indizes und Rechten an.
  - String: `company_id`, `company`, `company_slug`, `title`, `location`, `company_logo_url`, `profession`, `industry`, `employment_type`, `duration`, `salary`, `apply_url`, `contact_email`
  - `description` (String, groß), `tasks` / `requirements` / `benefits` (String-Array), `start_date` (Datetime), `is_active` (Boolean)
  - „Create" für angemeldete Nutzer, „Read" für alle
  - Index auf `company_id` und `is_active` — jede Abfrage filtert darüber
- [x] **2. Echte Firmen-ID im Bewertungs-Assistenten** statt `'placeholder-id'` (Status 2.1) — **erledigt am 29. September 2026**

  **Auf anderem Weg als hier vorgesehen.** Nicht die ID durchgereicht, sondern die Strecke ersetzt: `review_repository.dart` existiert nicht mehr, eine Bewertung entsteht nur in der Function `submit_review`, und die setzt `company_id` und `user_id` serverseitig. Eine Platzhalter-ID kann dort nicht mehr entstehen.

  Die Bereinigung der Altdaten entfiel: `reviews` hatte beim Abgleich am 1. Oktober **null Zeilen** (Status 14.3). Es gab nichts zu bereinigen.
- [ ] **3. Kontolöschung umsetzen** — serverseitige Appwrite-Function mit API-Schlüssel (Status 2.2)
  `AuthRepository.deleteAccount()` ist ein Stub. Art. 17 DSGVO ist damit nicht erfüllt. Die Löschreihenfolge steht in `projekt-referenz.md` §3.3; blockiert zusätzlich das Löschen der Passkey-Daten.
- [ ] **4. Kontaktformular anbinden** — Collection `contact_messages` oder als Zwischenlösung ein ehrlicher `mailto:`-Link (Status 2.4)
- [ ] **5. Betrieb-Dashboard und Analytics an echte Bewertungsdaten hängen** (Status 3.2)
  **Seit dem 2. Oktober anders als gedacht:** Die Quelle ist `company_scores`, nicht `reviews`, und sie trägt erst ab drei Bewertungen einen Wert — darunter steht dort `null`. Ein Dashboard, das dann nichts zeigt, ist richtig und muss das erklären. Zahlenangaben erscheinen überhaupt erst ab fünf Bewertungen und nur in Spannen.
- [ ] **6. Benachrichtigungen über Repository und Provider** statt Direktzugriff auf `TablesDB` (Status 3.1, 9.1)
  Dazu fehlt weiterhin **jede Stelle, die Benachrichtigungen erzeugt**, und ein Fehlerzustand im Screen (aktuell `LateInitializationError` bei nicht initialisiertem Client).
- [x] **7. Antworten des Fragebogens speichern** (Status 3.3) — **erledigt am 2. Oktober 2026**

  Deutlich mehr als der Punkt verlangte: eigene Tabelle `reviews` mit Rohantworten und Bearbeitungszeiten, eine getrennte `public_reviews` fuer das, was oeffentlich sein darf, serverseitige Auswertung, Moderation und Aggregation nach `company_scores`. Siehe Status 14.1.
- [ ] **8. Einstellungs-Schalter persistieren** und die Hinweistexte entfernen (Status 3.4)
- [ ] **9. Stelle bearbeiten** (Status 13.4) — anlegen, zurückziehen und löschen gehen; ändern nicht. Ein Tippfehler im Titel heißt derzeit: zurückziehen, neu anlegen. `JobRepository.updateJob` fehlt, das Formular kennt keinen Bearbeitungsmodus.
- [ ] Repository-Methoden ohne Aufrufer klären: `isBookmarked`, `getCompanyById` (Status 3.6) — anbinden oder entfernen

---

## C. Anmeldeverfahren — eingebaut, aber nirgends erprobt

Alle vier Verfahren stehen im Code. Was fehlt, ist überwiegend **Konfiguration in der Appwrite Console** und ein Durchlauf gegen die echte Instanz (Status 9.9, 9.10).

- [ ] **Anmeldung des Betriebs-Testkontos klären** (Status 13.5) — meldet `user_invalid_credentials`. Am Code liegt es nicht: Die App reicht das Passwort unverändert weiter, und derselbe Fehler kommt auch für ein Konto, das es gar nicht gibt — Appwrite unterscheidet beides absichtlich nicht. Zu prüfen, in dieser Reihenfolge: Stimmt die Projekt-ID (`6a3c45ef003356d7f16d`, Region Frankfurt)? Hat das Konto überhaupt einen Passwort-Faktor, oder ist es über OAuth, Magic Link oder Passkey entstanden? Neues Passwort in der Console setzen ist der schnellste Test.
- [ ] **MFA in der Console einschalten** — Reiter **Auth → Security**, *nicht* Settings. Ein Handgriff; ohne ihn antworten sämtliche `mfa*`-Endpunkte nicht.
- [x] **`http://localhost:8080` als Web-Plattform eintragen** — **am 2. Oktober festgestellt: war schon da.** Plattform „Karriko Web" mit Hostname `localhost`, angelegt im Juni. Appwrite vergleicht nur den Hostnamen, der Port spielt keine Rolle. Für den Livegang fehlt noch `karriko.de` (`APPWRITE_EINSPIELEN.md` §7).
- [ ] **SMTP einrichten** (EU-Standort, SPF, DKIM, DMARC) plus deutsches Template — daran hängt der Magic Link mehr als am Schalter. Fallback steht bereit: **Email OTP ist bereits aktiv.**
- [ ] **Google freischalten** — OAuth-Client-ID, Redirect-URI aus der Console kopieren (nicht abtippen), Zugangsdaten hinterlegen.
- [ ] **Apple freischalten** — Developer-Programm (kostenpflichtig), Services ID / Team ID / Key ID / P8-Schlüssel, Domain-Verifikation für den E-Mail-Relay.
- [ ] **Nach der Freischaltung mit `--dart-define=OAUTH_ENABLED=true` bauen** — bis dahin sind die Schaltflächen bewusst Platzhalter.
- [ ] **Passkeys erprobbar machen** — Tabellen `passkeys` und `webauthn_challenges` anlegen (**beide ohne jede Berechtigung**), API-Schlüssel mit *ausschließlich* `users.read` und `users.write`, Dienst starten. Felder und Indizes in `services/passkey-rp/README.md`.
- [ ] **Google-Logo ersetzen** — die von Google gelieferte Datei nach `assets/icons/` legen, **nicht** zur Laufzeit nachladen (Status 9.5). Vor dem Start zwingend.
- [ ] **Ratenbegrenzung im Passkey-Dienst** — mit eigenem Server erstmals selbst durchsetzbar (`projekt-referenz.md` §2.4)
- [ ] **Aufräumen abgelaufener Challenges** — wer nie einlöst, hinterlässt eine Zeile
- [ ] **Passkey-Dienst deployen** — als Appwrite Function geplant, damit kein zweiter Auftragsverarbeiter entsteht

### Durchspielen gegen die echte Instanz (Status 9.10)

Nichts davon ist je gegen Appwrite gelaufen — alle 185 Tests arbeiten gegen Fakes.

- [ ] Anmeldung, beide Registrierungen, Bestätigungsmail, Passwort-Reset **nach** dem SDK-Upgrade
- [ ] Realtime-Kanal der Benachrichtigungen (`notifications_screen.dart:98`) — eine Zeichenkette, die weder Compiler noch Test prüft
- [ ] Magic Link von Ende zu Ende, inklusive zweitem Öffnen desselben Links
- [ ] Social Login in **Chrome, Safari und Firefox** — der Token-Weg ist genau wegen deren Cookie-Sperren gewählt
- [ ] Passkey-Ablauf auf zwei Plattformen (etwa Windows Hello und Touch ID), inklusive zweitem Gerät und Löschen
- [ ] TOTP: Einrichtung mit echter App, Anmeldung mit Code, Anmeldung mit Wiederherstellungscode, Neuladen bei offener Bestätigung, Abbruch-Pfad

---

## D. Sicherheit

### Vor den ersten echten Nutzern

- [ ] **Rollen serverseitig absichern** (Status 9.10, 7.3) — Appwrite Teams (`azubis`, `betriebe`) oder Labels, gesetzt durch eine Function; Collection-Berechtigungen gegen `Role.team(...)`.
  Die Rolle ist derzeit **client-behauptet**: Prefs und Profildokument sind beide vom Nutzer schreibbar. Bei einem Anmeldeweg war das eine bekannte Schwäche, bei vieren vervielfacht sich die Fläche.
- [ ] **Appwrite-Collection-Permissions in der Console prüfen** (Status 7.3) — der einzige serverseitige Zugriffsschutz, aus dem Code nicht verifizierbar. ~~Konkret: `review_repository.dart:94` setzt die Rechte aus dem vom Client übergebenen `authorId`.~~ **Dieser Teil ist am 29. September geschlossen** — die Datei existiert nicht mehr, `submit_review` nimmt die Kennung aus dem geprüften JWT.
  **Der Rest ist seit dem 1. Oktober nicht mehr abstrakt:** Der erste Abgleich mit der echten Datenbank hat einen Befund gefunden, der fünf Wochen unsichtbar dort lag — siehe den nächsten Punkt.
- [x] **`companies`: `update("users")` entfernen, Row Security einschalten** (Status 7.11) — **erledigt am 2. Oktober 2026**
  Mit `node tools/appwrite-setup.mjs --fix-permissions` gesetzt, danach `rowSecurity: true` bestätigt. Die Tabellenrechte sind jetzt nur noch `read("any")` und `create("users")`. Das Änderungsrecht für den Eigentümer setzt der Client beim Anlegen pro Zeile, und das wirkt erst jetzt. Die Testzeile „Test GmbH“ trägt kein solches Zeilenrecht und ist seitdem nicht mehr bearbeitbar (`APPWRITE_EINSPIELEN.md` §9).

- [ ] **Der Eigentümer kann auf seiner eigenen Firmenzeile `is_verified`, `is_premium` und `average_rating` setzen** (Rest von 7.11)
  Appwrite kennt keine Rechte je Spalte. Lösen ließe sich das nur, indem die Profilbearbeitung über eine Function läuft. Das Abzeichen soll laut `projekt-referenz.md` §3.2 ein Mensch vergeben.

- [ ] **`bookmarks` und `profiles` ohne Row Security** — beim Einspielen am 2. Oktober aufgefallen
  Beide Tabellen stehen auf `rowSecurity: false`, also gelten nur die Tabellenrechte. Je nachdem, wie die gesetzt sind, kann jeder angemeldete Nutzer die Merklisten und Profile aller anderen lesen. Das Setup-Skript fasst die beiden nicht an. Rechte in der Console ansehen und dann entscheiden. Hängt mit „`profiles` wird nicht benutzt“ weiter unten zusammen.
- [ ] **`last_name` ist auf 10 Zeichen begrenzt** — in `profiles`
  Für viele Nachnamen zu kurz. Von den Befunden des Datenbank-Abgleichs der einzige, der jemanden **beim Registrieren** kostet, und damit der dringendste der kleinen. Auf 100 erhöhen.
- [ ] **`profiles` wird nicht benutzt** — zwei Nutzer, null Profile
  Die Daten liegen doppelt in den Account-Prefs. Für eine Quelle entscheiden: Wenn `profiles` bleibt, beim Signup anlegen und `role` als Enum führen. Hängt mit dem Punkt zur client-behaupteten Rolle oben zusammen — Prefs sind vom Nutzer schreibbar.
- [ ] **Duplikatsperren fehlen** — eindeutige Indizes auf `bookmarks(user_id, company_id)` und `review_reports(review_id, reporter_id)`
  Ohne sie kann derselbe Betrieb mehrfach gemerkt und dieselbe Bewertung mehrfach von derselben Person gemeldet werden. Für `reviews` ist der eindeutige Index `user_company_unique` seit dem 2. Oktober **eingespielt**. `review_reports` hat seitdem Indizes auf `review_id` und `reporter_id`, aber nur einfache, keinen eindeutigen über beide Spalten.
- [ ] **`jobs` ohne Formatprüfungen** — `contact_email` ohne E-Mail-Format, `apply_url` und `company_logo_url` ohne URL-Format, `employment_type` Freitext, `salary` als Zeichenkette
  Dazu: In `jobs` ist **keine** Spalte Pflichtfeld, es können also leere Anzeigen entstehen. Mindestens `company_id`, `title` und `is_active` sollten Pflicht sein.
- [ ] **Nicht genutzte Anmeldeverfahren abschalten** (Status 9.9) — derzeit alle sieben aktiv. Gebraucht werden vier: Email/Password, Magic URL, JWT, Team Invites.
  **„Anonymous" hat Vorrang:** Jeder kann ohne Zugangsdaten eine echte Sitzung erzeugen, die in Appwrite als `users` zählt — zusammen mit ungeprüften Berechtigungen die Kehrseite von 7.3. „Phone" ist ohne SMS-Anbieter wirkungslos, kann aber als zweiter Faktor auftauchen.
- [ ] **Betriebssperre serverseitig verankern** (Status 9.11) — wirkt derzeit im Client und ersetzt keine echte Regel

### Lieferkette (Sicherheitsbericht Teil C)

- [ ] **Neun ungenutzte Pakete entfernen** (S4) — größte Wirkung pro Aufwand: `dio`, `reactive_forms`, `flutter_svg`, `flutter_animate`, `cached_network_image`, `riverpod_annotation`, `cupertino_icons`, `riverpod_generator`, `build_runner`.
  Lieferkette 150 → 85 Pakete, wurde bereits durchgespielt: Analyzer und Tests bleiben grün. **`flutter clean` nicht vergessen** — sonst kompiliert der inkrementelle Compiler gegen einen Paketstand, den es nicht mehr gibt (Lehre aus 7.8).
- [ ] **`--no-web-resources-cdn` im Web-Build** (S1) — sonst lädt jeder Seitenaufruf CanvasKit von `gstatic.com`: Fremdcode ohne Integritätsprüfung, und die IP jedes Besuchers geht an Google, bevor irgendetwas sichtbar ist.
- [ ] **GitHub-Actions auf Commit-Hashes festnageln** (S3), dazu `permissions: contents: read` und `persist-credentials: false` in `flutter.yml`. Besonders `subosito/flutter-action` — kein GitHub-eigenes Projekt, richtet aber die komplette Build-Umgebung ein.
- [ ] **`flutter pub get --enforce-lockfile` in der CI** (S9) — eine Zeile
- [ ] **Google Fonts lokal einbetten** (Status 7.5) — DSGVO, LG München I, 3 O 17493/20. Zusammen mit `--no-web-resources-cdn` die Voraussetzung für die CSP.
- [ ] **Content-Security-Policy setzen** (S2) — **erst nach** den beiden Punkten darüber, sonst sperrt man die eigene App aus. Entwurf steht im Sicherheitsbericht; `'wasm-unsafe-eval'` und der Appwrite-Endpunkt in `connect-src` sind Pflicht. **Im Browser gegentesten** — eine zu strenge CSP zeigt eine weiße Seite.
- [ ] **OSV-Scanner in `flutter.yml`** und `.github/dependabot.yml` mit `pub` und `github-actions` anlegen (S7)
  Aktuell prüft **kein** Scanner die Flutter-App: CodeQL sieht nur `old_tsx/`, und für `pubspec.lock` kommt keine einzige Dependabot-Meldung — ob geprüft und sauber oder gar nicht geprüft, ist von außen nicht unterscheidbar. **In den Repo-Einstellungen nachsehen.**
- [ ] **`old_tsx/` aus `main` entfernen** (S8) — die Historie behält den Code. Damit verschwinden 30 dauerhaft rote Dependabot-Meldungen, der tote CodeQL-Scan und die Verwechslungsgefahr in einem Schritt. Das Rauschen ist der eigentliche Schaden: Wer 30 tote Meldungen ignoriert, übersieht die 31., die echt ist.
- [ ] **`APP_ORIGIN` im Produktions-Build setzen** (Status 7.7) — der `localhost`-Fallback ist entschärft, aber nicht geschlossen

---

## E. Oberfläche und Barrierefreiheit

Reihenfolge bewusst: erst was jede Seite betrifft, dann Einzelseiten, dann wieder etwas App-Weites.

- [ ] **Kopfzeilen-Überlauf bei vergrößerter Systemschrift** (Status 4) — betrifft **jede Seite**: 142 px bei 1,3-facher Schrift zwischen 981 und ~1150 px Breite. Navigationslinks in `Flexible` mit Ellipse, Abstände relativ, oder Umbruchpunkt an die tatsächlich benötigte Breite koppeln statt an feste 980 px. Danach die Ausnahme für 1000 px in `fuer_betriebe_layout_test.dart` entfernen.
- [ ] **Die 24 Layout-Überläufe abarbeiten** (Status 4) — durchgängig dieselbe Ursache: `Text` direkt in einer `Row` ohne `Expanded`/`Flexible`. Mechanisch. Die größten: `/subscription` @375 (224 px), `/register/betrieb` @375 (154 px), `/kontakt` @375 (137 px).
- [ ] **`review_card` auf Swiss-Design** — wirkt auf Startseite und Suche gleichzeitig, deshalb der beste Anfang
- [ ] **`presentation/common/job_card.dart` entfernen** — seit dem 31. August toter Code: Die Suche bringt ihre eigene Karte mit, das Betriebsprofil ebenfalls. Die Datei verweist zudem noch aufs Betriebsprofil statt auf die Stellenseite und wäre beim nächsten Einsatz eine Falle.
- [ ] **Auth-Seiten umstellen** — `register_azubi`, `register_betrieb`, `forgot_password`, `reset_password`, `verify_email`; diese fünf haben zudem **gar keine Kopfzeile**, man landet dort ohne Navigation
- [ ] **Restliche Betriebsseiten:** `analytics`, `subscription`, `team`, `reviews`, `reports`
- [ ] **Restliche Azubi-Seiten:** ~~`new_review`~~, `bookmarks`, ~~`my_reviews`~~, `notifications` — die beiden durchgestrichenen sind am 2. Oktober umgebaut (Status 14.1). Mit `review_card` ist eine der gemeinsamen Dateien weggefallen, weil `ReviewCard` und `StarRating` entfernt sind.
- [ ] **Restliche öffentliche Seiten:** `review_detail`, `blog_detail`, `kontakt`, `ueber_uns` — `company_detail` ist am 31. August umgestellt (Status 13.2)
- [ ] **Akzentfarbe auf `accentDark` umstellen** (Status 5) — `#E3342F` kommt auf 4,47:1, WCAG AA verlangt 4,5:1. Betrifft alle Kicker und jede rote Schaltfläche. Gehört ins Theme (`app_theme.dart`), **nicht** in einzelne Seiten. Vorher am laufenden Build beurteilen, wie der dunklere Ton auf großen Flächen wirkt. Bewusst **nach** den Einzelseiten.
- [ ] **Fehlerseite gestalten** — `errorBuilder` zeigt rohen Text auf leerem Scaffold
- [ ] **Verbleibende `IntrinsicHeight`-Konstruktionen umstellen** — `home_screen.dart:483`, `fuer_betriebe_screen.dart:586`, `login_shell.dart:88` sowie neu `company_detail_screen.dart:109` und `:1248`. Kein Überlauf bekannt, die Bauart bleibt aber anfällig: beim nächsten Anfassen mitnehmen.
  **Am 31. August zum dritten Mal aufgetreten** (Status 13.6): Beide Kennzahlenbänder liefen über, weil `IntrinsicHeight` umbrechenden Text falsch misst. Wo Zellen mit durchgehenden Trennlinien nebeneinanderstehen sollen, ist `Table` das Mittel — es misst die Zeilenhöhe aus den Zellen und zieht die Linien über die volle Höhe.

---

## F. Tests

- [ ] **Schriftskalierung (`textScaleFactorTestValue = 1.3`) in allen Layout-Testdateien ergänzen** — zwei Zeilen pro Datei, deckt eine ganze Fehlerklasse ab, die bisher nirgends geprüft wurde. Hat auf Anhieb drei Überläufe gefunden.
- [ ] **Layout-Durchlauf als dauerhaften Test etablieren** — existiert als Technik, nicht als Test. Scharfstellen, sobald Abschnitt E abgearbeitet ist.
- [ ] **Nicht abgedeckte Bereiche testen:** Repositories, ~~Bewertungs-Assistent~~, Lesezeichen, Suche, Unternehmensdetail, die fünf restlichen Betriebsseiten
  Der Bewertungs-Assistent ist seit dem 2. Oktober abgedeckt: 541 Tests insgesamt (vorher 194), darunter vier Personas gegen die **echte** Fragendefinition und Widget-Tests für die drei Fragetypen, die ohne Gesten bedienbar sein müssen. Der Rest der Liste bleibt.
- [ ] **Die Stellen haben keinen einzigen Test** (Status 13.7) — `JobRepository`, das Formular im Betriebsprofil, Stellenseite und Stellenband entstanden am 31. August ohne Testabdeckung; die Testzahl steht seit dem 30. August unverändert bei 194. Mindestens: Formular ohne Titel speichert nicht, Entwurf erscheint nicht im öffentlichen Band, die Zeilenaufteilung bei Aufgaben und Anforderungen (Leerzeilen und Aufzählungszeichen fallen weg).
- [ ] **Kritische Testfälle aus `projekt-referenz.md` §5 absichern** — insbesondere: anonyme Bewertung gibt **keinerlei** Nutzerdaten preis, auch nicht in der API-Antwort; Gewichtung 0,5 / 1,0 wirkt korrekt; zweite Antwort auf dieselbe Bewertung wird blockiert. Das Muster aus `auth_error_mapper_test.dart` — eine Anforderung prüfen statt eines Layouts — gehört hierher ausgeweitet.

---

## G. Produktentscheidungen — nicht technisch, aber blockierend

- [x] **Über die Ausbildungsbörse entscheiden** (`projekt-referenz.md` §1.3) — **entschieden am 31. August: Sie kommt.**

  Die Behelfslösung aus Firmendaten ist weg; Stellen liegen in einer eigenen Ablage, Betriebe schreiben sie selbst aus, und es gibt eine eigene Stellenseite (Status 13.3, 13.4). Der Zwischenzustand, der dem Nutzer etwas versprach, das es nicht gab, ist damit aufgelöst.

- [ ] **Umfang der Börse festlegen** — was jetzt entschieden werden muss, weil die Grundlage steht
  Noch nicht vorhanden: **Bewerbungen** (die Stellenseite verweist auf E-Mail oder Formular des Betriebs), **Datei-Upload** für Lebenslauf und Zeugnisse, **Suche nach Stellen** (die Suche findet weiterhin Betriebe, Stellen erscheinen nur als Vorschlagsband). Jeder dieser drei Punkte ist eine eigene Entscheidung mit eigenen Datenschutzfolgen — Bewerbungsunterlagen sind besondere Daten, der AVV und die Löschfristen aus §3.3 gälten dann auch für sie.
- [ ] **Acht Punkte der Bewertungsstrecke juristisch prüfen lassen** (Status 14.4) — **blockierend vor den ersten echten Bewertungen**
  In `notes/APPWRITE_SETUP.md` Abschnitt 12 mit ⚖️ markiert: die Aufbewahrungsfristen für Verifikationsnachweise, Entwürfe, Rohantworten, Gerätehash und den Datenexport; Lösch- und Auskunftsverlangen; die Texte im Fragebogen.
  **Zu keinem dieser Punkte steht im Code oder in der Dokumentation eine rechtliche Aussage.** Die Fristen haben Standardwerte, weil eine Function ohne Frist nicht läuft — nicht, weil diese Werte richtig wären.
- [ ] **Fünf Platzhaltertexte im Fragebogen ersetzen** (Status 14.4)
  `anonymity.intro`, `anonymity.sensitive`, `legal.verifikation`, `help.anlaufstellen[0]` und `[2]`. Zu finden mit `grep -n PLATZHALTER karriko_flutter/assets/questionnaire/questionnaire_v1.json`.
  **Zwei davon sind die Kontaktwege im Konfliktmodul.** Ein Platzhalter dort ist schwerer als in einem Rechtstext: Wer diesen Bildschirm sieht, sucht vielleicht wirklich eine Anlaufstelle.
  Zu ändern ist die Fassung in der App, danach `dart run tools/sync_questionnaire.dart` — und dann ist es eine neue Version, siehe `APPWRITE_SETUP.md` Abschnitt 10.
- [ ] **Über die Antwort des Betriebs entscheiden** (Spezifikation Abschnitt 11, Status 14.4)
  Dürfen Betriebe auf eine Bewertung antworten? Die Spalten `betrieb_reply` und `betrieb_replied_at` standen in der alten `reviews` schon — das Schema hatte die Frage halb beantwortet, der Code nicht. Nicht gebaut, weil es die Frage entschieden hätte.
- [ ] **Löschverlangen für eine Bewertung** (Status 14.4) — die größte offene Lücke der Bewertungsstrecke
  `public_reviews` trägt keine `user_id`, und das ist Absicht. Seit `my_reviews` ist die Zuordnung herstellbar, aber nur lesend; zu löschen hieße, die öffentliche Zeile mit zu entfernen, und dafür gibt es keine Function. Hängt mit B.3 zusammen: Beides braucht eine Function, die mit Schlüssel löscht.
- [ ] **Blog-Detail:** zeigt für jeden Slug denselben Artikel — echte Inhalte oder Seite zurückbauen

---

## H. Vor Go-Live (Status 10)

- [ ] **Impressum, Datenschutz, AGB anwaltlich prüfen lassen** — enthalten ausschließlich Platzhaltertexte
- [ ] **Cookie-/Consent-Banner** — existiert nicht
- [ ] **AVV mit jedem Dienstleister** (`projekt-referenz.md` §4.2) — Appwrite (Frankfurt, also keine Drittlandsübermittlung), SMTP-Anbieter, Google und Apple beim Social Login
- [ ] **Datenexport nach Art. 20 DSGVO** — Profil, Bewertungen, Merkliste, Benachrichtigungen als JSON (`projekt-referenz.md` §3.3); im Statusbericht bislang nirgends als umgesetzt geführt
- [ ] **SonarCloud Automatic Analysis in der Oberfläche abschalten** — die Konfiguration ist aus dem Repository entfernt, die Analyse läuft ohne diesen Schritt mit Defaults weiter
- [ ] **`dart fix --apply`, Migrationsreste entfernen**

---

## Was gerade *nicht* ansteht

Damit die Liste nicht künstlich wächst:

- **Roadmap nach dem Start** (`projekt-referenz.md` §6): Verifikations-Abzeichen, Branchenvergleich, Empfehlungen, Mobile App, öffentliche API. Erst relevant, wenn die Grundfunktionen aus Abschnitt B tragen.
- **Conditional UI für Passkeys** — nicht machbar, solange die App auf Flutter Web läuft (Textfelder liegen auf einer Canvas). Keine offene Aufgabe, sondern eine Plattformgrenze.
- **Registrierung als Konto-Orakel** — bewusste, im Mapper dokumentierte Abweichung von §3.2. Nur mit serverseitiger Registrierung lösbar; erst dann wieder aufmachen.
- **Build-Hooks in der transitiven Kette** (S6) — lässt sich nicht wegkonfigurieren, solange Appwrite genutzt wird. Bewusst getragen; die Hebel darauf sind S4 und aktuelle Versionen.
