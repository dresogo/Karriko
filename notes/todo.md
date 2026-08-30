# Karriko – Offene Aufgaben

**Erstellt:** 30. August 2026
**Grundlage:** `notes/projekt-referenz.md`, `notes/reports/status-report-2026-08-02.md` (Stand 5. August), `notes/reports/sicherheitsbericht-2026-08-04.md`
**Branch:** `feat/anmeldeverfahren` · letzter Commit `97338c8`

Die Berichte sind der Stand vom 4./5. August; seitdem ist im Repository nur der Auth-Ausbau dazugekommen. Diese Liste führt zusammen, was in beiden Berichten als offen steht — sortiert nach Art der Arbeit, nicht nach Herkunftsdokument. Die Kürzel in Klammern verweisen auf die Abschnitte dort.

**Wichtig zum Umgang mit dieser Datei:** Erledigtes wird abgehakt, nicht gelöscht. Die Lehre aus dem ZAP-Scan vom Juni (Projektreferenz §4.3) war genau die: Ein Befund verschwindet nicht dadurch, dass ihn niemand mehr weiterführt.

---

## A. Sofort — steht über allem anderen

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

- [ ] **1b. Schema in der Appwrite Console nachziehen** — **blockiert Punkt 1 im echten Betrieb**
  Der Code schreibt zwei Felder, die es in der Console geben muss:
  - `profiles.company_id` — String
  - `companies.owner_id` — String, **mit Index** (ohne ihn findet `findCompanyByOwner` nichts und der Reparaturweg legt Doppel-Firmen an)

  Dazu die Collection `companies` auf „Create" für angemeldete Nutzer stellen, sonst scheitert die Betriebsregistrierung am Anlegen. Ein eindeutiger Index auf `slug` wäre die einzige verbindliche Absicherung gegen doppelte Adressen — die Kollisionsprüfung im Client ist gegen den realistischen Fall wirksam, aber kein Ersatz.
- [ ] **2. Echte Firmen-ID im Bewertungs-Assistenten** statt `'placeholder-id'` (Status 2.1)
  `new_review_screen.dart:273`, dazu `company_repository.dart:76` und `company_provider.dart:134` auf Name+ID umstellen. **Bestehende Datensätze mit `company_id: 'placeholder-id'` müssen bereinigt werden.**
- [ ] **3. Kontolöschung umsetzen** — serverseitige Appwrite-Function mit API-Schlüssel (Status 2.2)
  `AuthRepository.deleteAccount()` ist ein Stub. Art. 17 DSGVO ist damit nicht erfüllt. Die Löschreihenfolge steht in `projekt-referenz.md` §3.3; blockiert zusätzlich das Löschen der Passkey-Daten.
- [ ] **4. Kontaktformular anbinden** — Collection `contact_messages` oder als Zwischenlösung ein ehrlicher `mailto:`-Link (Status 2.4)
- [ ] **5. Betrieb-Dashboard und Analytics an echte Bewertungsdaten hängen** (Status 3.2) — braucht Punkt 1
- [ ] **6. Benachrichtigungen über Repository und Provider** statt Direktzugriff auf `TablesDB` (Status 3.1, 9.1)
  Dazu fehlt weiterhin **jede Stelle, die Benachrichtigungen erzeugt**, und ein Fehlerzustand im Screen (aktuell `LateInitializationError` bei nicht initialisiertem Client).
- [ ] **7. Antworten des Fragebogens speichern** — weder Collection noch Schreibfunktion (Status 3.3)
- [ ] **8. Einstellungs-Schalter persistieren** und die Hinweistexte entfernen (Status 3.4)
- [ ] Repository-Methoden ohne Aufrufer klären: `isBookmarked`, `getCompanyById` (Status 3.6) — anbinden oder entfernen

---

## C. Anmeldeverfahren — eingebaut, aber nirgends erprobt

Alle vier Verfahren stehen im Code. Was fehlt, ist überwiegend **Konfiguration in der Appwrite Console** und ein Durchlauf gegen die echte Instanz (Status 9.9, 9.10).

- [ ] **MFA in der Console einschalten** — Reiter **Auth → Security**, *nicht* Settings. Ein Handgriff; ohne ihn antworten sämtliche `mfa*`-Endpunkte nicht.
- [ ] **`http://localhost:8080` als Web-Plattform eintragen** — sonst weist Appwrite die Ziel-URLs von Bestätigungsmail, Reset und Magic Link zurück.
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
- [ ] **Appwrite-Collection-Permissions in der Console prüfen** (Status 7.3) — der einzige serverseitige Zugriffsschutz, aus dem Code nicht verifizierbar. Konkret: `review_repository.dart:94` setzt die Rechte aus dem vom Client übergebenen `authorId`.
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
- [ ] **`review_card` und `job_card` auf Swiss-Design** — wirken auf viele Seiten gleichzeitig, deshalb der beste Anfang
- [ ] **Auth-Seiten umstellen** — `register_azubi`, `register_betrieb`, `forgot_password`, `reset_password`, `verify_email`; diese fünf haben zudem **gar keine Kopfzeile**, man landet dort ohne Navigation
- [ ] **Restliche Betriebsseiten:** `analytics`, `subscription`, `team`, `reviews`, `reports`
- [ ] **Restliche Azubi-Seiten:** `new_review`, `bookmarks`, `my_reviews`, `notifications`
- [ ] **Restliche öffentliche Seiten:** `company_detail`, `review_detail`, `blog_detail`, `kontakt`, `ueber_uns`
- [ ] **Akzentfarbe auf `accentDark` umstellen** (Status 5) — `#E3342F` kommt auf 4,47:1, WCAG AA verlangt 4,5:1. Betrifft alle Kicker und jede rote Schaltfläche. Gehört ins Theme (`app_theme.dart`), **nicht** in einzelne Seiten. Vorher am laufenden Build beurteilen, wie der dunklere Ton auf großen Flächen wirkt. Bewusst **nach** den Einzelseiten.
- [ ] **Fehlerseite gestalten** — `errorBuilder` zeigt rohen Text auf leerem Scaffold
- [ ] **Verbleibende `IntrinsicHeight`-Konstruktionen umstellen** — `home_screen.dart:483`, `fuer_betriebe_screen.dart:586`, `login_shell.dart:88`. Kein Überlauf bekannt, die Bauart bleibt aber anfällig: beim nächsten Anfassen mitnehmen.

---

## F. Tests

- [ ] **Schriftskalierung (`textScaleFactorTestValue = 1.3`) in allen Layout-Testdateien ergänzen** — zwei Zeilen pro Datei, deckt eine ganze Fehlerklasse ab, die bisher nirgends geprüft wurde. Hat auf Anhieb drei Überläufe gefunden.
- [ ] **Layout-Durchlauf als dauerhaften Test etablieren** — existiert als Technik, nicht als Test. Scharfstellen, sobald Abschnitt E abgearbeitet ist.
- [ ] **Nicht abgedeckte Bereiche testen:** Repositories, Bewertungs-Assistent, Lesezeichen, Suche, Unternehmensdetail, die fünf restlichen Betriebsseiten
- [ ] **Kritische Testfälle aus `projekt-referenz.md` §5 absichern** — insbesondere: anonyme Bewertung gibt **keinerlei** Nutzerdaten preis, auch nicht in der API-Antwort; Gewichtung 0,5 / 1,0 wirkt korrekt; zweite Antwort auf dieselbe Bewertung wird blockiert. Das Muster aus `auth_error_mapper_test.dart` — eine Anforderung prüfen statt eines Layouts — gehört hierher ausgeweitet.

---

## G. Produktentscheidungen — nicht technisch, aber blockierend

- [ ] **Über die Ausbildungsbörse entscheiden** (`projekt-referenz.md` §1.3)
  Es gibt keine Jobs-Collection, keine Bewerbungen, keinen Datei-Upload. Die Stellenanzeigen sind eine Behelfslösung aus Firmendaten (`company_provider.dart:146`). Entweder die Börse kommt zurück auf die Roadmap, oder die Behelfslösung verschwindet aus der Oberfläche. **Der Zwischenzustand verspricht dem Nutzer etwas, das es nicht gibt.**
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
