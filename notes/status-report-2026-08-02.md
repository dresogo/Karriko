# Karriko – Statusbericht

**Stand:** 3. August 2026 · Erstfassung: 2. August 2026
**Branch:** `main`
**Grundlage:** Neu gemessen — automatisierter Layout-Durchlauf über alle 37 Routen in fünf Viewportbreiten, Abgleich Screens ↔ Repositories ↔ Appwrite-Collections, Analyzer- und Testlauf. Ergänzt um eine **statische Sicherheitsprüfung** (Git-Historie, Dart-Code, Web-Bundle, Plattform-Konfiguration, `.gitignore`) — siehe Abschnitt 7.

---

## Kurzfassung

Seit der Erstfassung ist die **Oberfläche** ein großes Stück vorangekommen: alle sechs Seiten des eingeloggten Bereichs, die dort täglich benutzt werden, laufen jetzt auf dem Swiss-Design, und vier Fehler in Navigation und Auth sind behoben, die Nutzer schlicht ausgesperrt haben.

Die **Datenschicht** steht dagegen fast unverändert da. Der Bruch zwischen Repositories und Oberfläche besteht weiter: `deleteAccount` und `updateCompanyProfile` haben nach wie vor null Aufrufer, und die Kernfunktion der Plattform — eine Bewertung schreiben — schreibt weiterhin in die Datenbank, aber auf eine Firma, die es nicht gibt.

Was sich geändert hat: Die Stellen, die dem Nutzer Erfolg vorgespielt haben, tun das nicht mehr. Sie sagen jetzt, dass sie nicht angebunden sind. Das ist ehrlich, aber keine Lösung — die Arbeit steht noch aus.

| Bereich | 2. August | 3. August |
|---|---|---|
| Routing & Navigation | zwei verwaiste Seiten | **fertig**, alles verlinkt |
| Auth (Login, Registrierung) | Layout bricht auf Mobil | **funktioniert**, Layout offen |
| Öffentliche Seiten | Design fertig, Inhalte statisch | unverändert |
| Azubi-Bereich | Design alt, ein Datenfehler | **Design neu**, Datenfehler offen |
| Betrieb-Bereich | überwiegend Attrappe | **3 von 8 Seiten neu**, Rest Attrappe |
| Datenschicht | nicht überall angebunden | unverändert |
| Tests | 54 | **111** |
| Layout-Befunde | 28 | **24** |
| Analyzer-Hinweise | 86 | **0** |
| Sicherheit | nicht geprüft | **9 Befunde, 2 behoben** |

---

## 1. Erledigt seit der Erstfassung

### Fehler, die Nutzer ausgesperrt haben

- **Weiterleitungsschleife bei unbestätigter E-Mail.** `/verify-email` stand in der Liste der Auth-Pfade und schickte jeden angemeldeten Nutzer aufs Dashboard, das ihn mangels Bestätigung sofort zurückwarf. Ergebnis: Dashboard, Profil und Einstellungen waren **überhaupt nicht erreichbar**, und die Bestätigungsseite selbst auch nicht. Jetzt Sonderfall vor der allgemeinen Regel.
- **Sitzungskonflikt beim Login.** Nach einer abgebrochenen Registrierung blieb eine aktive Appwrite-Sitzung zurück. Jeder weitere Anmeldeversuch scheiterte an `user_session_already_exists` — gemeldet als „Bitte überprüfe deine Zugangsdaten". `signIn()` räumt jetzt vorher auf.
- **Registrierung brach nach dem Konto-Anlegen ab.** Profildokument und Bestätigungsmail hingen in derselben ungeschützten Kette. Schlug einer der beiden fehl, meldete die App „Registrierung fehlgeschlagen", obwohl Konto und Sitzung längst existierten. Beide Schritte sind jetzt entkoppelt und melden ihr Scheitern in der Konsole.
- **`/reviews/new` war nicht erreichbar.** Die Route stand hinter `/reviews/:id` und wurde vom Platzhalter geschluckt.
- **Der Menü-Button der mobilen Kopfzeile lief auf 15 Seiten ins Leere**, weil dort kein `drawer` gesetzt war.

### Fehlende Seiten

| Seite | Route |
|---|---|
| Login-Auswahl (Azubi / Betrieb) | `/login` |
| Login Azubi / Login Betrieb | `/login/azubi`, `/login/betrieb` |
| Häufige Fragen | `/faq` |
| Fragebogen „Fragen bewerten" | `/fragen-bewerten` |

### Design

Auf Swiss-Design umgestellt: Login (drei Seiten), Blog als Blog- und Neuigkeiten-Stream, Impressum/Datenschutz/AGB auf gemeinsamem Gerüst, Profil-Dropdown der Kopfzeile — und der komplette **tägliche Arbeitsbereich**: Azubi-Dashboard, -Profil, -Einstellungen sowie Betrieb-Dashboard, -Unternehmensprofil, -Einstellungen.

Dabei entstand ein Baukasten in `presentation/common/app_page.dart` (`AppPage`, `AppCard`, `AppRowGroup`, `AppRow`, `AppSwitchRow`, `StatTile`, `AppEmptyState`), auf dem die restlichen Seiten aufsetzen können.

### Weitere behobene Layoutfehler

- Kopfzeile lief bei schmaler Breite über (Markenschriftzug ohne `Flexible`).
- Footer lief ab 720 px über — vier Spalten in fester `Row`, jetzt `Wrap`. Betraf jede Seite mit Footer.
- `/team` und `/reports` sind über Betriebs-Dashboard und -Einstellungen verlinkt; die Erreichbarkeitslücke ist geschlossen.

### Selbst verursacht und behoben

Ein Bulk-Edit über `Get-Content`/`Set-Content` (PowerShell 5.1 liest mit ANSI-Codepage) hat in 12 Dateien sämtliche Umlaute doppelt kodiert. Rückgängig gemacht, per `git diff` verifiziert. **Lehre:** keine Bulk-Edits mehr über diese Cmdlets.

---

## 2. Kritische Fehler — weiterhin offen

### 2.1 Bewertungen werden auf eine nicht existierende Firma geschrieben

`lib/presentation/azubi/new_review_screen.dart:240` — **unverändert**

```dart
onTap: () => onSelect('placeholder-id', s),
```

Jede abgesendete Bewertung landet mit `company_id: 'placeholder-id'` in der Datenbank und taucht bei keinem Betrieb auf.

**Ursache:** `CompanyRepository.getSearchSuggestions()` liefert nur `List<String>` mit Namen, keine IDs.

**Behebung:** Vorschlagsabfrage auf Name+ID umstellen und die echte ID durchreichen — `company_repository.dart:76`, `company_provider.dart:134`, Screen.

**Auswirkung:** Kernfunktion der Plattform. Bestehende Datensätze mit dieser ID sind unbrauchbar und müssen bereinigt werden.

### 2.2 „Konto löschen" löscht kein Konto

**Status geändert: ehrlich, aber weiterhin nicht funktional.**

Die Seite spielt keine Löschung mehr vor. Nach der Bestätigung erscheint ein Hinweis, dass die Löschung nicht freigeschaltet ist, mit Link zum Kontakt. Vorher wurde der Nutzer stillschweigend abgemeldet und glaubte, sein Konto sei weg.

Der eigentliche Mangel bleibt: `AuthRepository.deleteAccount()` ist ein Stub —

```dart
throw UnimplementedError('Account deletion requires a server-side Appwrite Function.');
```

**Auswirkung:** Art. 17 DSGVO (Recht auf Löschung) ist nicht erfüllt. Braucht eine serverseitige Appwrite-Function mit API-Schlüssel. Muss vor Go-Live stehen.

### 2.3 Das Unternehmensprofil speichert nicht

**Status geändert: ehrlich, aber weiterhin nicht funktional.**

Die falsche Erfolgsmeldung „Profil gespeichert!" ist weg; der Knopf heißt „Übernehmen" und sagt, dass die Eingaben nur für die Sitzung gelten. Der erfundene Startwert „Musterbetrieb GmbH" wurde durch den echten Firmennamen ersetzt (dafür wanderte `companyName` ins `UserModel`).

**Tiefere Ursache, jetzt klar benannt:** `registerBetrieb()` legt **kein `companies`-Dokument** an, sondern schreibt den Namen nur ins Profil. Damit fehlt dem Betriebskonto jede Verknüpfung zu einer Firma — `updateCompanyProfile()` hat gar keine ID, gegen die es schreiben könnte. Das ist auch der Grund, warum das Betriebs-Dashboard keine echten Bewertungen zeigen kann.

**Behebung:** Bei der Registrierung ein `companies`-Dokument anlegen und dessen ID im Profil hinterlegen. Danach lassen sich Profil-Speichern, Dashboard-Kennzahlen und Bewertungszuordnung in einem Zug lösen.

### 2.4 Das Kontaktformular verschickt nichts

`lib/presentation/public/kontakt_screen.dart:33` — **unverändert**

```dart
setState(() => _sent = true);
```

Die Bestätigung erscheint, die Nachricht existiert nirgends. Weder Collection noch Funktion.

**Behebung:** Appwrite-Collection `contact_messages` plus Repository, oder als Zwischenlösung ein ehrlicher `mailto:`-Link.

---

## 3. Nicht angebundene Bereiche

### 3.1 Benachrichtigungen — unverändert

`lib/presentation/azubi/notifications_screen.dart`

- Greift als einziger Screen **direkt** auf Appwrite zu, an der Repository-Schicht vorbei.
- Collection `'notifications'` steht als Zeichenkette im Code, fehlt in `AppwriteConstants`.
- Kein Fehlerzustand — im Testlauf reicht ein nicht initialisierter Client, um den Screen zu sprengen (`LateInitializationError`, reproduzierbar auf allen fünf Breiten).
- Es gibt keine Stelle, die Benachrichtigungen **erzeugt**.

### 3.2 Attrappen

| Seite | Route | Zustand |
|---|---|---|
| Analytics | `/analytics` | vollständig statisch |
| Team | `/team` | statisch, keine Mitgliederverwaltung |
| Abonnement | `/subscription` | statisch, keine Zahlungsanbindung |
| Blog-Detail | `/blog/:slug` | zeigt für **jeden** Slug denselben Artikel |
| Blog-Übersicht | `/blog` | statisch, Modell vorbereitet |
| FAQ | `/faq` | statisch (bewusst so gebaut) |

**Vom Vorbericht gestrichen:** Das Betrieb-Dashboard zeigt keine erfundenen Kennzahlen mehr. Die Kacheln (4,2 ⌀ / 24 Bewertungen / 1.2k Aufrufe) und der Score-Verlauf aus sieben fest verdrahteten Werten sind ersetzt durch leere Kennzahlen mit dem Hinweis, dass die Auswertung fehlt.

### 3.3 Fragebogen speichert keine Antworten — unverändert

Die Fragen kommen aus der Datenbank bzw. dem Platzhalterkatalog. Für die Antworten gibt es weder Collection noch Schreibfunktion.

### 3.4 Einstellungs-Schalter ohne Wirkung

**Status geändert: ausgewiesen, aber weiterhin ohne Wirkung.** Unter den Schaltern in beiden Einstellungsseiten steht jetzt, dass sie nach dem Neuladen zurückspringen. Persistenz fehlt weiter.

### 3.5 Stellenanzeigen sind eine Behelfslösung — unverändert

`lib/providers/company_provider.dart:146` — Einträge werden aus Firmendaten abgeleitet, es gibt keine Jobs-Collection.

### 3.6 Repository-Methoden ohne Aufrufer

Gemessen über `lib/presentation` und `lib/providers`:

| Methode | Aufrufe |
|---|---|
| `deleteAccount` | 0 (zudem Stub) |
| `updateCompanyProfile` | 0 |
| `isBookmarked` | 0 |
| `getCompanyById` | 0 |

`updatePassword`, `resendVerificationEmail`, `reportReview` und `addBetriebReply` sind angebunden.

---

## 4. Layout- und Responsive-Fehler

Neuer Durchlauf, 37 Routen × fünf Breiten (1440 / 1200 / 900 / 760 / 375 px): **24 Befunde**, vorher 28.

> **Einordnung:** Im Widget-Test steht Inter nicht zur Verfügung, die Ersatzschrift läuft breiter. Kleine Werte (1–20 px) reproduzieren sich real womöglich nicht; die dreistelligen sind eindeutig.

**Behoben** — diese vier standen im Vorbericht ganz oben und sind weg:

| Route | vorher |
|---|---|
| `/betrieb-dashboard` @375 | 303 px |
| `/dashboard` @375 | 237 px |
| `/betrieb-profile` @375 | 157 px |
| `/profile` @375 | 73 px |

**Noch offen:**

| Route | Breite | Überlauf |
|---|---|---|
| `/subscription` | 375 | **224 px** rechts (+4 weitere) |
| `/register/betrieb` | 375 | **154 px** rechts (+4 weitere) |
| `/kontakt` | 375 | **137 px** rechts |
| `/register/azubi` | 375 | 77 px rechts (+3 weitere) |
| `/reports` | 375 | 56 px rechts |
| `/reviews/new` | 375 | 16 px rechts |
| `/register/azubi` | alle | 14 px rechts |
| `/register/betrieb` | alle | 1,5 px rechts |

**Durchgängige Ursache:** `Text` direkt in einer `Row` ohne `Expanded`/`Flexible`. Beispiel `kontakt_screen.dart:140` — Icon, Abstand, dann eine E-Mail-Adresse, die nie umbricht. Die Behebung ist mechanisch und in allen Fällen gleich.

**Zusätzlich, unverändert:** `/faq` meldet auf allen Breiten eine Flutter-Warnung — die `ExpansionTile`-Elemente liegen in einer `DecoratedBox` mit Hintergrundfarbe, dadurch bleiben Ripple und Hintergrund unsichtbar. Ein eigenes `Material` um die Kacheln behebt es.

---

## 5. Design-Konsistenz

Auf Swiss-Design: alle öffentlichen Seiten, alle Login-Seiten, der Blog, die Rechtstexte, das Profil-Dropdown und die sechs Seiten des täglichen Arbeitsbereichs.

**21 Dateien** nutzen noch die alte Formensprache (vorher 25) — abgerundete Ecken mit festen Zahlen, `cardShadow`, Farbverläufe, rosa Pillen-Badges:

- **Gemeinsam:** `review_card`, `job_card` — wirken auf viele Seiten gleichzeitig, **hier lohnt sich der Anfang**
- **Auth:** `register_azubi`, `register_betrieb`, `forgot_password`, `reset_password`, `verify_email` — diese fünf haben zudem **gar keine Kopfzeile** (`KarrikoAppBar` fehlt), man landet dort ohne Navigation
- **Betrieb:** `analytics`, `subscription`, `team`, `reviews`, `reports`
- **Azubi:** `new_review`, `bookmarks`, `my_reviews`, `notifications`
- **Öffentlich:** `company_detail`, `review_detail`, `blog_detail`, `kontakt`, `ueber_uns`

Empfehlung unverändert: `review_card`/`job_card` → Auth → restliche Betriebsseiten → restliche Azubi-Seiten.

---

## 6. Technische Schulden

- `lib/data/services/supabase_service.dart` — Restdatei der Migration, 2 Zeilen. Kann weg.
- `AppwriteConstants.verificationUrl` fällt ohne `--dart-define` auf `http://localhost` zurück. In einem Produktions-Build zeigen alle Bestätigungs-E-Mails dorthin. Muss im Build gesetzt und als Web-Plattform im Appwrite-Projekt eingetragen sein — sonst schlägt `createVerification` fehl (siehe 1., Registrierungsabbruch).
- **Analyzer: 0 Hinweise** (vorher 67, davor 86). `dart fix --apply` in zwei Durchläufen hat 62 Fixes in 17 Dateien erledigt (`prefer_const_constructors`, `withOpacity` → `withValues`, `curly_braces_in_flow_control_structures`), dazu `dart format` über 61 Dateien. Drei Restbefunde von Hand: toter `?? false`-Operand in `company_model.dart:34`, `mounted` → `context.mounted` in `reports_screen.dart:107`, `_NavLink` → `_navLink` in `app_bar_widget.dart:153`.
- **CI umgestellt.** SonarCloud analysierte nur noch toten Legacy-Code und lieferte ein dauerhaft rotes Quality Gate — Sonar hat keinen Dart-Analyzer, die eigentliche App war unsichtbar. `sonar-project.properties` entfernt (zeigte ohnehin auf das nicht mehr existierende `src/`), stattdessen `.github/workflows/flutter.yml`: Format-Prüfung, `flutter analyze`, `flutter test` gegen `karriko_flutter`. Die Automatic Analysis muss zusätzlich in der SonarCloud-Oberfläche abgeschaltet werden, sonst läuft sie mit Defaults weiter.
- `old_tsx/` und `node_modules/` liegen im Repo-Wurzelverzeichnis. `codeql.yml` scannt `javascript-typescript` und deckt damit ebenfalls nur `old_tsx/` ab — CodeQL kann Dart genauso wenig wie Sonar.
- GitHub meldet **21 Dependabot-Warnungen auf `main`** (11 hoch, 8 mittel, 2 niedrig). Betrifft den Altbestand, nicht die Flutter-App.

---

## 7. Sicherheit

Statische Prüfung am 3. August 2026: Git-Historie, Dart-Code unter `lib/`, Web-Bundle, Android-/iOS-Konfiguration, beide `.gitignore`. Kein Pen-Test, keine Laufzeitanalyse — jeder Befund ist aus dem Quellcode ableitbar.

**9 Befunde: 1 kritisch, 1 hoch, 5 mittel, 2 niedrig.** Zwei davon sind mit diesem Stand erledigt.

### 7.1 Zugangsdaten in der öffentlichen Git-Historie — kritisch

`.env.local` wurde in **66afa2e** committet und in **9e92077** wieder entfernt. Das Entfernen aus dem aktuellen Stand hilft nicht: In einem öffentlichen Repository bleibt der Inhalt über `git show 66afa2e:.env.local`, die GitHub-Weboberfläche und jeden Fork abrufbar.

| Variable | Tragweite bei Missbrauch |
|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | umgeht Row Level Security vollständig — Vollzugriff auf alle Daten |
| `DATABASE_URL` | direkter Datenbankzugang inklusive Passwort |
| `NEXTAUTH_SECRET` | Fälschen beliebiger Sitzungen |
| `NEXT_PUBLIC_SUPABASE_URL` / `ANON_KEY` | öffentlich per Design, macht aber das Ziel identifizierbar |

**Maßnahme:** Bereinigung der Historie mit `git filter-repo`, anschließend Force-Push. Rotation der Schlüssel wurde bewusst **nicht** durchgeführt — Einschätzung des Betreibers ist, dass ein Abfluss ausgeschlossen ist. Diese Entscheidung ist hier festgehalten, damit nachvollziehbar bleibt, worauf sie beruht: Sollte sich die Annahme als falsch erweisen, ist Rotation der einzige wirksame Schritt, da ein History-Rewrite bereits kopierte Werte nicht zurückholt.

**Folgewirkung des Rewrites:** Sämtliche Commit-Hashes ändern sich. Bestehende Klone und offene Pull Requests müssen neu aufgesetzt werden; die in diesem Bericht genannten Hashes (`66afa2e`, `9e92077`) verlieren ihre Gültigkeit.

### 7.2 Fremdes JavaScript im Web-Build — hoch, behoben

`web/index.html` lud bei **jedem** Seitenaufruf ein Skript nach:

```html
<script src="https://github.com/corbado/flutter-passkeys/releases/download/2.4.0/bundle.js"></script>
```

Fremdcode von einer GitHub-Release-URL, ohne `integrity`-Hash, mit vollem DOM-Zugriff — und damit Zugriff auf die Appwrite-Sitzung. Release-Assets sind vom jeweiligen Repo-Eigentümer jederzeit austauschbar, ein Wechsel des Inhalts wäre unbemerkt geblieben.

Entscheidend: Das Skript wurde **gar nicht benutzt**. Kein `passkeys`-Paket in `pubspec.yaml` oder `pubspec.lock`, keine Referenz in `lib/`. Reiner Altbestand, **ersatzlos entfernt**.

### 7.3 Autorisierung liegt außerhalb des Repositories — mittel

Die Weiterleitungen in `router.dart:94-111` sind reine Oberflächen-Wächter und clientseitig umgehbar. Das ist erwartbar — die tragende Grenze sind die Collection-Permissions in der Appwrite-Console, und die sind **aus dem Repository heraus nicht prüfbar**. Dieser Befund ist deshalb offen, nicht widerlegt.

Konkret nachzuhalten: `review_repository.dart:94` setzt die Dokumentrechte aus dem vom Client übergebenen `authorId`. Erlaubt die Collection „Create" für alle angemeldeten Nutzer und wird `author_id` nicht serverseitig erzwungen, lassen sich Bewertungen unter fremder Identität anlegen. Absicherung über eine Appwrite Function, die `author_id` aus der Sitzung setzt.

### 7.4 Meldungen werden mit einem Platzhalter gespeichert — mittel

`lib/presentation/betrieb/reports_screen.dart:102`

```dart
reporterId: 'current-user',
```

Der literale Zeichenkettenwert statt der echten Nutzer-ID. Zwei Folgen: `Permission.read(Role.user('current-user'))` vergibt Leserechte an eine nicht existierende Rolle, der Melder kommt an seine eigene Meldung nicht heran — und Missbrauchsmuster lassen sich keiner Person zuordnen.

### 7.5 Google Fonts zur Laufzeit — mittel, DSGVO

`google_fonts` lädt Schriften von `fonts.gstatic.com` nach und überträgt dabei die IP-Adressen der Nutzer an Google. Für eine Plattform mit DACH-Zielgruppe einschlägig (LG München I, 3 O 17493/20). Schriften lokal einbetten.

### 7.6 `android:allowBackup` nicht gesetzt — mittel

`android/app/src/main/AndroidManifest.xml` setzt das Attribut nicht, der Android-Standard ist `true`. Damit lassen sich App-Daten per `adb backup` auslesen. Explizit auf `false` setzen.

### 7.7 `verificationUrl` fällt auf localhost zurück — mittel

Bereits unter Abschnitt 6 als technische Schuld geführt, hat aber eine Sicherheitsseite: Ohne `--dart-define` zeigen **auch die Passwort-Reset-Links** auf `http://localhost`, nicht nur die Bestätigungsmails.

### 7.8 Ungenutzte Abhängigkeit `flutter_secure_storage` — niedrig

In `pubspec.yaml` deklariert, in `lib/` nirgends verwendet. Unnötige Angriffsfläche und irreführend, weil sie sichere Ablage suggeriert, wo keine stattfindet. Entfernen oder tatsächlich nutzen.

### 7.9 `debugPrint` in der Auth-Schicht — niedrig

`auth_repository.dart:206` und `:222` geben Appwrite-Fehlertexte aus, keine Token und keine personenbezogenen Daten. Die Aufrufe bleiben allerdings auch im Release-Build aktiv.

### Unauffällig

Kein `http://` im Code, `setSelfSigned(status: false)`, keine hartkodierten Schlüssel in Dart — die Appwrite-Project-ID ist per Design öffentlich. Keine JWTs oder Verbindungszeichenfolgen in verfolgten Dateien. Passwortregel mit Mindestlänge 8 plus Großbuchstabe plus Ziffer.

### `.gitignore`

Die Abdeckung ist solide. Gegengeprüft wurde besonders das häufigste Flutter-Leck — generierte Dateien, die `--dart-define`-Werte enthalten: `Generated.xcconfig`, `flutter_export_environment.sh` und `local.properties` sind über `ios/.gitignore` und `android/.gitignore` ausgeschlossen, keine davon wird verfolgt. Ebenfalls abgedeckt: `.env*`, Keystores, Zertifikate, `key.properties`, `google-services.json`, Datenbank-Abzüge, `coverage/`, `build/`.

Drei Anmerkungen:

1. **`package-lock.json`, `yarn.lock` und `Pipfile.lock` werden ignoriert** (`.gitignore:88-90`). Das ist ein Fehlgriff: Lockdateien gehören ins Repository, sonst gibt es weder reproduzierbare Installationen noch eine Grundlage für Dependabot, transitive Schwachstellen zu melden. Für `old_tsx/` derzeit folgenlos, als Dauerregel falsch. `pubspec.lock` wird korrekt verfolgt.
2. Release-Artefakte fehlen: `*.apk`, `*.aab`, `*.ipa` ergänzen.
3. Für eine dokumentierende `.env.example` braucht es wegen der breiten `.env.*`-Regel eine Ausnahme (`!.env.example`).

**Grenze der Regel:** `.gitignore` wirkt nur nach vorn. Für 7.1 ändert keine Regel etwas.

---

## 8. Tests

**111 Tests, alle grün** (vorher 54), verteilt auf sechs Dateien:

| Datei | Inhalt |
|---|---|
| `login_layout_test.dart` | Login über sieben Breiten, vertikale Ausrichtung, `next`-Parameter |
| `blog_layout_test.dart` | drei Filter über sechs Breiten, Deep-Linking, Artikel-Navigation |
| `azubi_pages_layout_test.dart` | Dashboard/Profil/Einstellungen über sechs Breiten, Dropdown |
| `betrieb_pages_layout_test.dart` | dieselben drei Betriebsseiten, plus Prüfung, dass die erfundenen Werte nicht zurückkehren |
| `router_guard_test.dart` | Wächterlogik: unbestätigte Adresse, Rollen, Rückziel |
| `auth_error_message_test.dart` | Fehlermeldungen werden nicht durch pauschalen Text ersetzt |

Das Generator-Template `widget_test.dart` ist entfernt — sein Compile-Fehler ließ die gesamte Suite scheitern.

**Nicht abgedeckt:** Repositories, Bewertungs-Assistent, Lesezeichen, Suche, Unternehmensdetail, die fünf restlichen Betriebsseiten.

Der Layout-Durchlauf aus diesem Bericht existiert als Technik, aber nicht als dauerhafter Test. Sobald die 24 Befunde abgearbeitet sind, sollte er scharf gestellt werden.

---

## 9. Vor Go-Live

- Impressum, Datenschutz und AGB enthalten ausschließlich Platzhaltertexte und müssen anwaltlich geprüft werden.
- Punkt 2.2 (Kontolöschung) ist DSGVO-relevant und braucht eine serverseitige Function.
- Kein Cookie-/Consent-Banner vorhanden.
- Keine gestaltete Fehlerseite — `errorBuilder` im Router zeigt rohen Text auf leerem Scaffold.
- `verificationUrl` und Appwrite-Plattformen konfigurieren, sonst kommt keine Bestätigungsmail an.
- **Appwrite-Collection-Permissions in der Console prüfen** (7.3) — der einzige serverseitige Zugriffsschutz, aus dem Code nicht verifizierbar.
- **Google Fonts lokal einbetten** (7.5) — sonst fließen Nutzer-IPs an Google ab.
- **`android:allowBackup="false"`** setzen (7.6), bevor eine Android-Fassung ausgeliefert wird.

---

## 10. Vorgeschlagene Reihenfolge

**Vorab — Sicherheit**
0. Historie bereinigen (7.1), danach `reporterId`-Platzhalter (7.4), `allowBackup` (7.6), ungenutztes `flutter_secure_storage` (7.8) und die `.gitignore`-Korrekturen. Alles kleinteilig, keines davon hängt an einer anderen Baustelle. Die Prüfung der Appwrite-Permissions (7.3) gehört zeitlich vor den ersten echten Nutzer.

**Zuerst — Daten und Wahrheit**
1. `companies`-Dokument bei der Betriebsregistrierung anlegen und im Profil verknüpfen. **Schlüsselstück:** löst 2.3, ermöglicht echte Dashboard-Kennzahlen und die Bewertungszuordnung.
2. Firmen-ID im Bewertungs-Assistenten (2.1) + Bereinigung der Altdaten
3. Kontolöschung über eine Appwrite-Function (2.2)
4. Kontaktformular anbinden oder auf `mailto:` umstellen (2.4)

**Danach — Substanz**
5. Betrieb-Dashboard und Analytics an echte Bewertungsdaten hängen
6. Benachrichtigungen über Repository und Provider statt Direktzugriff
7. Antworten des Fragebogens speichern
8. Einstellungs-Schalter persistieren, Hinweise entfernen

**Parallel — Oberfläche**
9. Die 24 Layout-Überläufe (mechanisch, gleiches Muster)
10. `review_card` und `job_card` auf Swiss-Design
11. Auth-Seiten inklusive fehlender Kopfzeile
12. Restliche Betriebs- und Azubi-Seiten
13. `/faq` ListTile-Warnung

**Zum Schluss**
14. Fehlerseite gestalten
15. Layout-Durchlauf als dauerhaften Test etablieren
16. `dart fix --apply`, Migrationsreste entfernen
17. Rechtstexte, Consent, `verificationUrl` im Build
