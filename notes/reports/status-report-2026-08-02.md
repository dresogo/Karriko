# Karriko – Statusbericht

**Stand:** 5. August 2026 · Erstfassung: 2. August 2026
**Branch:** `main`
**Grundlage:** Gemessen am 3. August — automatisierter Layout-Durchlauf über alle 37 Routen in fünf Viewportbreiten, Abgleich Screens ↔ Repositories ↔ Appwrite-Collections, Analyzer- und Testlauf. Ergänzt um eine **statische Sicherheitsprüfung** (Git-Historie, Dart-Code, Web-Bundle, Plattform-Konfiguration, `.gitignore`) — siehe Abschnitt 7. Nachtrag vom 4. August: Umbau der Seite „Für Betriebe", Test- und Analyzer-Lauf neu, zwei neue Befunde (Abschnitt 4 und 5). Nachtrag vom 5. August: Ausbau der Anmeldeverfahren — eigenes Kapitel, siehe **Abschnitt 9**.

---

## Kurzfassung

Seit der Erstfassung ist die **Oberfläche** ein großes Stück vorangekommen: alle sechs Seiten des eingeloggten Bereichs, die dort täglich benutzt werden, laufen jetzt auf dem Swiss-Design, und vier Fehler in Navigation und Auth sind behoben, die Nutzer schlicht ausgesperrt haben.

Die **Datenschicht** steht dagegen fast unverändert da. Der Bruch zwischen Repositories und Oberfläche besteht weiter: `deleteAccount` und `updateCompanyProfile` haben nach wie vor null Aufrufer, und die Kernfunktion der Plattform — eine Bewertung schreiben — schreibt weiterhin in die Datenbank, aber auf eine Firma, die es nicht gibt.

Was sich geändert hat: Die Stellen, die dem Nutzer Erfolg vorgespielt haben, tun das nicht mehr. Sie sagen jetzt, dass sie nicht angebunden sind. Das ist ehrlich, aber keine Lösung — die Arbeit steht noch aus.

**Am 4. August** kam eine einzelne Seite dazu: „Für Betriebe" trägt jetzt dasselbe Layout wie die Startseite. Das ist Oberfläche, keine Substanz — an den offenen Punkten der Datenschicht ändert sich dadurch nichts. Bemerkenswerter ist, was nebenbei aufgefallen ist:

- Prüft man die Seiten mit **vergrößerter Systemschrift**, bricht die Kopfzeile auf jeder Seite der App um (Abschnitt 4). Diese Fehlerklasse war bisher in keinem Test enthalten.
- Die **Akzentfarbe** verfehlt den Kontrastwert der WCAG-Stufe AA — betrifft jeden Kicker und jede rote Schaltfläche (Abschnitt 5).
- In `notes/fehler.md` steht eine **committete Zeile im Format `benutzer:passwort`**. Ob sie echt ist, muss geprüft werden — sie stand außerhalb des Umfangs der Sicherheitsprüfung vom 3. August (Abschnitt 7.10). **Das ist der dringlichste Punkt dieses Nachtrags.**

**Am 5. August** ist die Anmeldung erstmals über E-Mail und Passwort hinausgewachsen. Das Appwrite-SDK wurde von 12.0.1 auf 25.4.0 gehoben, die Fehlerabbildung der Auth-Schicht herausgelöst und testbar gemacht, und **alle vier beschlossenen Verfahren sind eingebaut**: Zwei-Faktor-Bestätigung über TOTP, Magic Links, Social Login über Google und Apple sowie Passkeys. Für die Passkeys ist dabei die **erste eigene Serverkomponente** des Projekts entstanden (`services/passkey-rp/`), weil Appwrite keine WebAuthn-API hat. Das ganze Thema hat ein eigenes Kapitel (Abschnitt 9), weil es quer durch Repository, Zustand, Router, Oberfläche und jetzt auch Infrastruktur schneidet.

Zwei Dinge daran sind bemerkenswert:

- Das **SDK-Upgrade über 13 Hauptversionen war nicht brechend**: null Compile-Fehler, nur Deprecation-Hinweise. Die erwartete große Migration entpuppte sich als 33 Aufrufstellen.
- Beim Einbau der neuen Bildschirme kamen **zwei Fehler im Router-Provider** zutage, die sich gegenseitig verdeckt hatten und die **ganze App** betrafen: Der Provider baute bei jeder Zustandsänderung einen neuen `GoRouter` und warf damit den Navigationsstand weg, und der `refreshListenable` hatte durch eine fehlerhafte `late final`-Initialisierung noch nie gefeuert. Beides behoben — die Testsuite läuft seitdem in 13 statt 44 Sekunden. Siehe 9.7.

| Bereich | 2. August | 3. August | 4. August | 5. August |
|---|---|---|---|---|
| Routing & Navigation | zwei verwaiste Seiten | **fertig**, alles verlinkt | unverändert | **6 Routen dazu, 3 Fehler behoben** (9.8) |
| Auth (Login, Registrierung) | Layout bricht auf Mobil | **funktioniert**, Layout offen | unverändert | **alle vier Verfahren eingebaut** |
| Öffentliche Seiten | Design fertig, Inhalte statisch | unverändert | **„Für Betriebe" im Startseiten-Layout** | unverändert |
| Azubi-Bereich | Design alt, ein Datenfehler | **Design neu**, Datenfehler offen | unverändert | unverändert |
| Betrieb-Bereich | überwiegend Attrappe | **3 von 8 Seiten neu**, Rest Attrappe | unverändert | unverändert |
| Datenschicht | nicht überall angebunden | unverändert | unverändert | **SDK 12 → 25**, sonst unverändert |
| Tests | 54 | 111 | 134 | **185** (+ 25 im Passkey-Dienst) |
| Layout-Befunde | 28 | 24 | **25** (ein neuer, siehe 4.) | unverändert |
| Analyzer-Hinweise | 86 | **0** | 0 | 0 |
| Sicherheit | nicht geprüft | **8 Befunde, 5 behoben** | unverändert | **7.7 entschärft**, siehe dort |

---

## 1. Erledigt seit der Erstfassung

### Nachtrag 4. August: „Für Betriebe"

Die Seite lief zwar schon auf den Design-Tokens, folgte aber einem anderen Bauprinzip als die Startseite — zentrierte `ContentBand`-Spalte, Icon-Karten im Raster, Tarifkarten in der Textspalte. Jetzt trägt sie dasselbe Vokabular: vollflächige Bänder mit Haarlinien, zweispaltiger Hero, nummerierte Merkmalszeilen `01`–`04` statt Icon-Karten, Tarife als eigenständige Karten mit Rand und Gasse.

Der Hero wurde in zwei Schritten nachgeschärft: erst die erzwungene Bildschirmhöhe entfernt (die Höhe folgt jetzt dem Inhalt), dann das rechte Aktionsfeld neu aufgebaut. Aus „Überschrift plus freistehender Knopf" wurde eine Karte mit Kicker, den drei Leistungen des Basis-Tarifs als Haarlinien-Liste und einer einzigen primären Aktion; links stützt eine Kennzahlenzeile den Text. Grundlage war eine Abfrage der Design-Datenbank (`ui-ux-pro-max`), die für dieses Produkt **Swiss Modernism 2.0** und das Muster *Trust & Authority + Conversion* nennt — also genau die Formensprache, die die App ohnehin verwendet.

**Inhaltlich neu** sind dabei nur zwei Kleinigkeiten, beide aus bereits bestehenden Aussagen der Webapp abgeleitet: die Kennzahlenzeile im Hero (2.400+ Bewertungen · DACH Fokusmarkt · DSGVO von Beginn an — die Werte des Kennzahlenbands der Startseite) und die Leistungsliste im Aktionsfeld (die drei Punkte des Basis-Tarifs derselben Seite).

**Ein struktureller Fehler, der dabei aufflog und behoben ist:** Die Hero-Spalten standen zunächst in einem `IntrinsicHeight`. Dessen Höhenmessung ist über `Expanded`-Spalten mit umbrechendem Text prinzipiell ungenau — die Textspalte lief im Browser um 26 px über. Fläche und Trennlinie liegen jetzt als eigene Ebene hinter dem Inhalt (`Stack` mit `Positioned.fill`), die Spalten brauchen keine Höhenschätzung mehr.

Dieselbe Bauart — `IntrinsicHeight` über `Expanded` mit umbrechendem Text — steckt noch an drei weiteren Stellen: im Audience-Band der Startseite (`home_screen.dart:483`), in den Tarifkarten dieser Seite (`fuer_betriebe_screen.dart:586`) und in `login_shell.dart:88`. Dort ist bislang **kein** Überlauf bekannt, auch nicht unter vergrößerter Systemschrift; die Konstruktion bleibt aber anfällig und sollte beim nächsten Anfassen mit umgestellt werden.

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

`lib/presentation/azubi/new_review_screen.dart:273` — **unverändert** (am 4. August nachgeprüft; die Zeilennummer hat sich verschoben, der Code nicht)

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
- ~~Collection `'notifications'` steht als Zeichenkette im Code, fehlt in `AppwriteConstants`.~~ **Behoben:** `AppwriteConstants.notificationsCollection` ergänzt und an allen drei Stellen verwendet, auch im Realtime-Kanal. Der Direktzugriff an der Repository-Schicht vorbei bleibt bestehen.
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

Durchlauf vom 3. August, 37 Routen × fünf Breiten (1440 / 1200 / 900 / 760 / 375 px): **24 Befunde**, vorher 28. Dazu kommt seit dem 4. August ein 25. Befund, den dieser Durchlauf nicht finden konnte, weil er nur bei vergrößerter Systemschrift auftritt — siehe unten.

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

### Neu am 4. August: Die Kopfzeile bricht bei vergrößerter Systemschrift

**Betrifft jede Seite der App.** Bei 1,3-facher Systemschrift und einer Fensterbreite zwischen 981 px und etwa 1150 px läuft die Kopfzeile um **142 px** nach rechts über.

`_WideHeader` in `app_bar_widget.dart` greift ab `width > 980` und legt Markenschriftzug, vier Navigationslinks mit festen 34-px-Abständen und die Aktionsschaltfläche in eine `Row`. Die innere Navigations-`Row` wächst mit der Schriftgröße über ihr `Expanded` hinaus. Unterhalb von 980 px greift `_NarrowHeader` (kein Fehler), ab etwa 1200 px ist genug Platz.

Isoliert nachgewiesen: Ein Testlauf mit ausschließlich der `KarrikoAppBar` und leerem Body erzeugt denselben Überlauf, ganz ohne Seiteninhalt.

**Behebung:** Navigationslinks in `Flexible` mit Ellipse, Abstände relativ statt fix, oder den Umbruchpunkt an die tatsächlich benötigte Breite koppeln statt an feste 980 px.

**Warum das vorher niemand gesehen hat:** Der Layout-Durchlauf prüfte fünf Breiten bei Standard-Schriftgröße. Vergrößerte Systemschrift war in keinem Test enthalten — die Fehlerklasse war schlicht nicht abgedeckt. Seit dem 4. August prüft `fuer_betriebe_layout_test.dart` sechs Breiten zusätzlich mit 1,3-facher Schrift; die Breite 1000 px ist dort bis zur Behebung ausgenommen und der Grund im Code vermerkt.

**Zusätzlich — behoben:** `/faq` meldete auf allen Breiten eine Flutter-Warnung, weil die `ExpansionTile`-Elemente in einem `Container` mit Hintergrundfarbe lagen und der Ripple keine Zeichenfläche hatte. Die Kacheln stecken jetzt in einem `Material(type: MaterialType.transparency)`, das Erscheinungsbild bleibt unverändert.

---

## 5. Design-Konsistenz

Auf Swiss-Design: alle öffentlichen Seiten, alle Login-Seiten, der Blog, die Rechtstexte, das Profil-Dropdown und die sechs Seiten des täglichen Arbeitsbereichs. Seit dem 4. August folgt „Für Betriebe" zusätzlich demselben **Bauprinzip** wie die Startseite, nicht nur denselben Farben — vollflächige Bänder, Haarlinien-Raster, nummerierte Zeilen.

**21 Dateien** nutzen noch die alte Formensprache (vorher 25, am 4. August nachgemessen: unverändert 21) — abgerundete Ecken mit festen Zahlen, `cardShadow`, Farbverläufe, rosa Pillen-Badges:

- **Gemeinsam:** `review_card`, `job_card` — wirken auf viele Seiten gleichzeitig, **hier lohnt sich der Anfang**
- **Auth:** `register_azubi`, `register_betrieb`, `forgot_password`, `reset_password`, `verify_email` — diese fünf haben zudem **gar keine Kopfzeile** (`KarrikoAppBar` fehlt), man landet dort ohne Navigation
- **Betrieb:** `analytics`, `subscription`, `team`, `reviews`, `reports`
- **Azubi:** `new_review`, `bookmarks`, `my_reviews`, `notifications`
- **Öffentlich:** `company_detail`, `review_detail`, `blog_detail`, `kontakt`, `ueber_uns`

Empfehlung unverändert: `review_card`/`job_card` → Auth → restliche Betriebsseiten → restliche Azubi-Seiten.

### Neu am 4. August: Die Akzentfarbe erreicht den Kontrastwert nicht

`AppColors.accent` (#E3342F) kommt gegen Weiß auf **4,47:1**. WCAG AA verlangt 4,5:1 für Text unter 18,66 px — betroffen sind damit **alle Kicker** (12 px, fett) und **jede rote Schaltfläche** (14 px, fett) der App. Der Abstand ist klein, die Regel aber eindeutig verfehlt.

`AppColors.accentDark` (#B91F1A) liegt bei 6,5:1 und wäre der naheliegende Ersatz. Die Änderung gehört ins Theme (`app_theme.dart`), nicht in einzelne Seiten — ein Wechsel an nur einer Stelle macht die Oberfläche inkonsistent. Ungeprüft ist bislang, wie sich der dunklere Ton auf großen Flächen anfühlt; das sollte einmal am laufenden Build beurteilt werden, bevor es umgestellt wird.

---

## 6. Technische Schulden

- ~~`lib/data/services/supabase_service.dart` — Restdatei der Migration, 2 Zeilen.~~ **Entfernt.** War unreferenziert und exportierte nur `appwrite_service.dart` weiter.
- ~~`AppwriteConstants.verificationUrl` fällt ohne `--dart-define` auf `http://localhost` zurück.~~ **Umgebaut am 5. August** (Abschnitt 9.2): Alle Rückleitungen leiten sich jetzt aus einer einzigen Konstante `appOrigin` ab, Standard `http://localhost:8080`. Der Fallback besteht damit weiter, ist aber bewusst gesetzt, solange es keine Domain gibt — **für einen Produktions-Build muss `--dart-define=APP_ORIGIN=…` gesetzt und der Host als Web-Plattform eingetragen sein.** Dabei fiel ein echter Fehler auf: Der Passwort-Reset-Link zeigte auf dieselbe URL wie die Bestätigungsmail, also auf die Startseite statt auf `/reset-password`. Behoben.
- **Appwrite-SDK am 5. August von 12.0.1 auf 25.4.0 gehoben**, `Databases` → `TablesDB` migriert. Die Instanz läuft auf 1.9.6, das Projekt in Frankfurt. Details in Abschnitt 9.1. Der Endpunkt zeigt jetzt auf `fra.cloud.appwrite.io` statt auf den generischen Host.
- **Neue Abhängigkeiten:** `qr_flutter ^4.1.0` für die TOTP-Einrichtung (9.3) und `web ^1.1.1` für die Seitenweiterleitung beim Anbieter-Login (9.5) — letzteres lag ohnehin transitiv vor und ist jetzt nur noch ausdrücklich deklariert.
- **Neue Komponente im Repository:** `services/passkey-rp/` — der erste Serverdienst des Projekts (9.6). Eigener CI-Workflow `passkey-rp.yml`; CodeQL erfasst ihn ohne Umbau, weil es `javascript-typescript` ohne Pfadfilter scannt.
- **Analyzer: 0 Hinweise** (vorher 67, davor 86). `dart fix --apply` in zwei Durchläufen hat 62 Fixes in 17 Dateien erledigt (`prefer_const_constructors`, `withOpacity` → `withValues`, `curly_braces_in_flow_control_structures`), dazu `dart format` über 61 Dateien. Drei Restbefunde von Hand: toter `?? false`-Operand in `company_model.dart:34`, `mounted` → `context.mounted` in `reports_screen.dart:107`, `_NavLink` → `_navLink` in `app_bar_widget.dart:153`.
- **CI umgestellt.** SonarCloud analysierte nur noch toten Legacy-Code und lieferte ein dauerhaft rotes Quality Gate — Sonar hat keinen Dart-Analyzer, die eigentliche App war unsichtbar. `sonar-project.properties` entfernt (zeigte ohnehin auf das nicht mehr existierende `src/`), stattdessen `.github/workflows/flutter.yml`: Format-Prüfung, `flutter analyze`, `flutter test` gegen `karriko_flutter`. Die Automatic Analysis muss zusätzlich in der SonarCloud-Oberfläche abgeschaltet werden, sonst läuft sie mit Defaults weiter.
- **Nachtrag 4. August:** `actions/checkout` in beiden Workflows auf `v5` gehoben (`9d25f8d`). `v4` zielt auf Node.js 20, GitHub hebt das zwangsweise auf Node 24 und erzeugte bei jedem Lauf eine Annotation. Ebenfalls neu: eine `README.md` im Wurzelverzeichnis (`720ba53`).
- `old_tsx/` und `node_modules/` liegen im Repo-Wurzelverzeichnis. `codeql.yml` scannt `javascript-typescript` und deckt damit ebenfalls nur `old_tsx/` ab — CodeQL kann Dart genauso wenig wie Sonar.
- GitHub meldet **21 Dependabot-Warnungen auf `main`** (11 hoch, 8 mittel, 2 niedrig). Betrifft den Altbestand, nicht die Flutter-App.

---

## 7. Sicherheit

Statische Prüfung am 3. August 2026: Git-Historie, Dart-Code unter `lib/`, Web-Bundle, Android-/iOS-Konfiguration, beide `.gitignore`. Kein Pen-Test, keine Laufzeitanalyse — jeder Befund ist aus dem Quellcode ableitbar.

**8 Befunde: 1 hoch, 5 mittel, 2 niedrig.** **Fünf davon sind mit diesem Stand erledigt** (7.2, 7.4, 7.6, 7.8, 7.9), dazu alle drei `.gitignore`-Anmerkungen. Offen bleiben die drei, die nicht im Code liegen oder mehr als einen Handgriff kosten: 7.3 (Appwrite-Console), 7.5 (Schriften lokal einbetten), 7.7 (Build-Konfiguration). Ein neunter, zunächst als kritisch eingestufter Punkt hat sich bei genauer Prüfung als gegenstandslos erwiesen — siehe 7.1.

**Nachtrag 4. August:** Ein weiterer Punkt ist beim Aktualisieren dieses Berichts aufgefallen und **noch nicht eingestuft** — siehe 7.10. Er lag außerhalb des am 3. August geprüften Umfangs.

### 7.1 `.env.local` in der Historie — geprüft, kein Leak

**Ausgangsverdacht:** `.env.local` wurde in `66afa2e` committet und in `9e92077` wieder entfernt. Eine Notiz in `notes/fehler.md` führte das als offenen kritischen Punkt mit den Worten „Rotieren ist der einzige wirksame Schritt".

**Prüfergebnis: Der Verdacht trifft nicht zu.** Die Datei enthielt ausschließlich Platzhalter aus einer Vorlage:

```
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
DATABASE_URL=your_postgresql_url
NEXTAUTH_SECRET=your_nextauth_secret
NEXTAUTH_URL=http://localhost:3000
```

Es waren nie echte Zugangsdaten im Repository. Damit entfällt der Befund, und eine Rotation ist gegenstandslos. ~~Die Notiz in `notes/fehler.md` ist sachlich falsch und sollte korrigiert oder gelöscht werden~~ — **erledigt am 4. August** (`9d25f8d`): Der Eintrag wurde durchgestrichen und mit dem Prüfergebnis versehen; inzwischen ist er ganz aus der Datei entfernt.

**Trotzdem durchgeführt:** Die Historie wurde mit `git filter-repo --invert-paths --path .env.local` bereinigt und per Force-Push übertragen. Das war zum Zeitpunkt der Entscheidung als Sicherheitsmaßnahme gedacht; als Repo-Hygiene ist es weiterhin sinnvoll — eine `.env`-Datei gehört auch mit Platzhaltern nicht in die Historie, weil sie genau solche Fehlalarme erzeugt.

**Folgewirkung des Rewrites:** Sämtliche Commit-Hashes haben sich geändert. Bestehende Klone müssen neu aufgesetzt werden; alle in älteren Notizen genannten Hashes (`66afa2e`, `9e92077`, `0be2d68`) sind ungültig. Offene Pull Requests gab es zum Zeitpunkt des Pushs keine.

**Methodischer Hinweis für die nächste Prüfung:** Der Fehlalarm entstand, weil die Werte beim ersten Auslesen zum Schutz maskiert wurden — die Maskierung verdeckte, dass es Platzhalter waren. Bei Fundverdacht in der Historie gehört die Echtheitsprüfung des Werts **vor** die Einstufung der Schwere.

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

### 7.4 Meldungen werden mit einem Platzhalter gespeichert — mittel, behoben

`lib/presentation/betrieb/reports_screen.dart` schrieb den literalen Wert `'current-user'` statt der echten Nutzer-ID. Zwei Folgen: `Permission.read(Role.user('current-user'))` vergab Leserechte an eine nicht existierende Rolle, der Melder kam an seine eigene Meldung nicht heran — und Missbrauchsmuster ließen sich keiner Person zuordnen.

Die ID kommt jetzt aus `currentUserProvider`. Besteht keine Sitzung, bleibt der Absendeknopf gesperrt, statt einen Platzhalter in die Datenbank zu schreiben.

### 7.5 Google Fonts zur Laufzeit — mittel, DSGVO

`google_fonts` lädt Schriften von `fonts.gstatic.com` nach und überträgt dabei die IP-Adressen der Nutzer an Google. Für eine Plattform mit DACH-Zielgruppe einschlägig (LG München I, 3 O 17493/20). Schriften lokal einbetten.

### 7.6 `android:allowBackup` nicht gesetzt — mittel, behoben

`android/app/src/main/AndroidManifest.xml` setzte das Attribut nicht, der Android-Standard ist `true` — App-Daten waren damit per `adb backup` auslesbar. Steht jetzt explizit auf `false`.

### 7.7 `verificationUrl` fällt auf localhost zurück — mittel, entschärft

Bereits unter Abschnitt 6 als technische Schuld geführt, hat aber eine Sicherheitsseite: Ohne `--dart-define` zeigen **auch die Passwort-Reset-Links** auf `http://localhost`, nicht nur die Bestätigungsmails.

**Nachtrag 5. August — entschärft, nicht geschlossen.** Alle Rückleitungen leiten sich jetzt aus einer einzigen Konstante `appOrigin` ab (Abschnitt 9.2). Das nimmt dem Befund die Streuung: Vorher konnten Bestätigung und Reset unbemerkt auseinanderlaufen, jetzt gibt es eine Stelle, die im Build gesetzt werden muss. **Der Fallback auf localhost besteht weiter** und ist in der Aufbauphase beabsichtigt — für einen Produktions-Build bleibt `--dart-define=APP_ORIGIN=…` zwingend.

Dabei kam heraus, dass der Befund noch einen Zahn schärfer war als beschrieben: Der Reset-Link zeigte nicht nur auf `localhost`, sondern auf die **Wurzel** statt auf `/reset-password` — `createRecovery` bekam schlicht die Verifizierungs-URL übergeben. Der Link führte also selbst mit korrekt gesetzter Domain nirgendwohin, wo sich ein Passwort ändern lässt. Behoben.

### 7.8 Ungenutzte Abhängigkeit `flutter_secure_storage` — niedrig, behoben

War in `pubspec.yaml` deklariert, in `lib/` nirgends verwendet — unnötige Angriffsfläche und irreführend, weil sie sichere Ablage suggerierte, wo keine stattfand. Aus `pubspec.yaml` entfernt, `pubspec.lock` neu aufgelöst.

**Nachtrag 4. August — Stolperstein beim nächsten Lauf:** `flutter run -d chrome` brach danach mit „Couldn't resolve the package 'flutter_secure_storage_web'" ab. Ursache waren zwei Kernel-Caches in `build/`, die den alten Plugin-Registranten noch enthielten; pubspec, Lock und `.flutter-plugins-dependencies` waren bereits sauber. `flutter clean` plus `flutter pub get` behebt es. **Merke:** Nach dem Entfernen eines Plugins gehört ein `flutter clean` dazu, sonst kompiliert der inkrementelle Compiler gegen einen Paketstand, den es nicht mehr gibt.

### 7.9 `debugPrint` in der Auth-Schicht — niedrig, behoben

`auth_repository.dart` gibt Appwrite-Fehlertexte aus, keine Token und keine personenbezogenen Daten. Die Aufrufe blieben allerdings auch im Release-Build aktiv; beide sind jetzt in `if (kDebugMode)` gefasst und werden im Release wegoptimiert.

### 7.10 Zugangsdaten-Zeile in `notes/fehler.md` — neu am 4. August, ungeprüft

Die letzte Zeile von `notes/fehler.md` hat die Form `benutzer:passwort`. Sie ist **verfolgt und committet**, liegt also in der Historie des Repositories.

Der Wert wird hier bewusst nicht wiederholt — er steht in der Datei, Zeile 10.

**Noch nicht eingestuft**, und zwar absichtlich: Ob es sich um echte Zugangsdaten, ein Wegwerf-Testkonto oder eine bedeutungslose Notiz handelt, lässt sich aus dem Repository heraus nicht entscheiden. Genau hier greift die methodische Lehre aus 7.1 — **erst die Echtheit prüfen, dann die Schwere festlegen**. Führt die Zeile zu einem echten Konto, gehört sie rotiert und aus der Historie entfernt; ist sie bedeutungslos, gehört sie trotzdem gelöscht, weil sie bei jeder künftigen Prüfung Aufwand erzeugt.

Der bisherige Prüflauf hat die Datei nicht erfasst: Er suchte in `lib/`, im Web-Bundle, in der Plattform-Konfiguration und in der Historie nach `.env`-Dateien — Notizdateien im Repo-Wurzelverzeichnis standen nicht auf der Liste. **Für den nächsten Durchgang: `notes/` einschließen.**

### Unauffällig

Kein `http://` im Code, `setSelfSigned(status: false)`, keine hartkodierten Schlüssel in Dart — die Appwrite-Project-ID ist per Design öffentlich. Keine JWTs oder Verbindungszeichenfolgen in verfolgten Dateien. Passwortregel mit Mindestlänge 8 plus Großbuchstabe plus Ziffer.

### `.gitignore`

Die Abdeckung ist solide. Gegengeprüft wurde besonders das häufigste Flutter-Leck — generierte Dateien, die `--dart-define`-Werte enthalten: `Generated.xcconfig`, `flutter_export_environment.sh` und `local.properties` sind über `ios/.gitignore` und `android/.gitignore` ausgeschlossen, keine davon wird verfolgt. Ebenfalls abgedeckt: `.env*`, Keystores, Zertifikate, `key.properties`, `google-services.json`, Datenbank-Abzüge, `coverage/`, `build/`.

Drei Anmerkungen — **alle drei umgesetzt**:

1. **`package-lock.json`, `yarn.lock` und `Pipfile.lock` wurden ignoriert.** Ein Fehlgriff: Lockdateien gehören ins Repository, sonst gibt es weder reproduzierbare Installationen noch eine Grundlage für Dependabot, transitive Schwachstellen zu melden. Die drei Regeln sind entfernt, an ihrer Stelle steht ein Kommentar, der die Absicht festhält. `pubspec.lock` wurde ohnehin korrekt verfolgt.
2. Release-Artefakte ergänzt: `*.apk`, `*.aab`, `*.ipa`.
3. Ausnahme `!.env.example` ergänzt, damit eine dokumentierende Vorlage trotz der breiten `.env.*`-Regel möglich bleibt.

**Grenze der Regel:** `.gitignore` wirkt nur nach vorn. Für 7.1 ändert keine Regel etwas.

---

## 8. Tests

**185 Tests, alle grün** (vorher 134, davor 111, davor 54), verteilt auf vierzehn Dateien; dazu **25 Tests im Passkey-Dienst** (vitest, eigener Workflow). Die sechs neuen Flutter-Dateien vom 5. August stehen unten und gehören zum Ausbau der Anmeldeverfahren (Abschnitt 9):

| Datei | Tests | Inhalt |
|---|---|---|
| `login_layout_test.dart` | 30 | Login über sieben Breiten, vertikale Ausrichtung, `next`-Parameter |
| `betrieb_pages_layout_test.dart` | 24 | drei Betriebsseiten über sechs Breiten, plus Prüfung, dass die erfundenen Werte nicht zurückkehren |
| `blog_layout_test.dart` | 24 | drei Filter über sechs Breiten, Deep-Linking, Artikel-Navigation |
| `azubi_pages_layout_test.dart` | 23 | Dashboard/Profil/Einstellungen über sechs Breiten, Dropdown |
| `fuer_betriebe_layout_test.dart` | 23 | **neu** — sieben Breiten, davon sechs zusätzlich mit 1,3-facher Systemschrift; Inhaltserhalt, Hero-Aufbau, Tarif-Ränder, beide Handlungswege |
| `router_guard_test.dart` | 6 | Wächterlogik: unbestätigte Adresse, Rollen, Rückziel |
| `auth_error_mapper_test.dart` | 7 | **neu** — Enumerationssicherheit, Rohtext-Sperre, Kontextabhängigkeit |
| `router_guard_mfa_test.dart` | 6 | **neu** — Wächter bei offener Zwei-Faktor-Bestätigung, keine Schleife |
| `auth_state_mfa_test.dart` | 4 | **neu** — halbe Sitzung gilt nicht als Anmeldung, `clearMfa` |
| `magic_link_callback_test.dart` | 6 | **neu** — Callback mit Geheimnis, Geheimnis verlässt die Adresse, abgelaufener Link, Betriebssperre |
| `oauth_callback_test.dart` | 7 | **neu** — Aufbau der Anbieter-Adresse, Rückleitung, Abbruch, Betriebssperre |
| `passkey_test.dart` | 8 | **neu** — Sichtbarkeit je Browser und Rolle, Anmeldung, Abbruch, Verwaltung |
| `register_azubi_layout_test.dart` | 11 | **neu** — Überlauf über sechs Breiten, Reihenfolge der Schritte, kein Passkey-Knopf |
| `auth_error_message_test.dart` | 4 | Fehlermeldungen werden nicht durch pauschalen Text ersetzt |

Das Generator-Template `widget_test.dart` ist entfernt — sein Compile-Fehler ließ die gesamte Suite scheitern.

**Zwei Tests prüfen jetzt erstmals eine Anforderung statt eines Layouts.** `auth_error_mapper_test.dart` weist maschinell nach, dass falsches Passwort und unbekannte Adresse dieselbe Meldung liefern (`projekt-referenz.md` §3.2) — bislang stand das nur als Absicht im Code. Und dass kein bekannter Fehlertyp den Appwrite-Rohtext durchreicht, wird über alle abgebildeten Typen zugleich geprüft, nicht stichprobenartig.

**Der Wert der bestehenden Wächter-Tests hat sich beim SDK-Upgrade gezeigt:** `router_guard_test.dart` und `auth_error_message_test.dart` fassen das SDK nicht an, weil sie gegen ein Fake-Repository laufen. Sie mussten für den Sprung über 13 Hauptversionen nicht angefasst werden und blieben grün — genau das war ihre Aufgabe.

**Neuer Testtyp seit dem 4. August:** Rendern unter vergrößerter Systemschrift (`textScaleFactorTestValue = 1.3`). Er hat sofort drei Überläufe gefunden, die bei Standardgröße unsichtbar bleiben — zwei in der neuen Aktionskarte (beide behoben) und den Kopfzeilenfehler aus Abschnitt 4. **Empfehlung:** diesen Testtyp auf die bestehenden Layout-Testdateien ausweiten; er kostet nur zwei Zeilen pro Datei und deckt eine ganze Fehlerklasse ab, die bisher nirgends geprüft wurde.

Zwei weitere Erkenntnisse aus dem Umbau, die für künftige Layout-Tests gelten:

- **Die Ersatzschrift verfälscht Höhenmessungen.** Ein Test, der eine Pixelhöhe gegen die Viewporthöhe prüft, misst die breitere Testschrift mit. Robuster ist es, die *Eigenschaft* zu prüfen: Die Hero-Höhe wird bei 900 px und 1400 px Fensterhöhe verglichen — sind beide gleich, folgt die Höhe dem Inhalt und nicht dem Bildschirm.
- **Nicht jeder Überlauf gehört der geprüften Seite.** Der Kopfzeilenfehler tauchte zuerst als Fehlschlag im Seitentest auf. Erst ein Testlauf mit ausschließlich der `KarrikoAppBar` hat gezeigt, wo er wirklich sitzt.

**Nicht abgedeckt:** Repositories, Bewertungs-Assistent, Lesezeichen, Suche, Unternehmensdetail, die fünf restlichen Betriebsseiten.

Der Layout-Durchlauf aus diesem Bericht existiert als Technik, aber nicht als dauerhafter Test. Sobald die Befunde aus Abschnitt 4 abgearbeitet sind, sollte er scharf gestellt werden.

---

## 9. Anmeldeverfahren — neu am 5. August

Bis zum 4. August gab es genau einen Weg ins Konto: E-Mail und Passwort. Beschlossen ist der Ausbau um vier weitere Verfahren — **Passkeys (FIDO2), Social Login (OAuth 2.0 / OIDC), Magic Links und MFA/TOTP**. Dieses Kapitel hält fest, was davon steht, was bewusst anders gebaut wurde als geplant, und was zum Ausprobieren noch fehlt.

Der Vollplan liegt außerhalb des Repositories unter `~/.claude/plans/f-r-karriko-sollen-folgende-prancy-puppy.md`.

### 9.0 Stand auf einen Blick

| Verfahren | Stand | Was fehlt zum Ausprobieren |
|---|---|---|
| **MFA / TOTP** | **eingebaut**, beide Rollen | Schalter in der Appwrite Console (siehe 9.9) |
| **Magic Links** | **eingebaut**, nur Azubis | SMTP in der Console — ohne eigenen Mailversand kommt kein Link an |
| **Social Login** (Google, Apple) | **eingebaut**, nur Azubis | Client-Zugangsdaten in der Console (9.9). Bis dahin Platzhalter-Schaltflächen |
| **Passkeys / WebAuthn** | **eingebaut**, beide Rollen | Zwei Tabellen und ein API-Schlüssel in der Console, dazu ein laufender Dienst |

Vier Festlegungen stehen und sind nicht mehr zur Diskussion gestellt:

1. **Passkeys über einen eigenen WebAuthn-Dienst**, nicht über einen Drittanbieter. Corbado war schon einmal eingebunden und wurde am 3. August als Supply-Chain-Befund entfernt (7.2) — externe Auth-SDKs sind damit grundsätzlich abgelehnt.
2. **SDK-Upgrade zuerst**, als eigener Schritt ohne Funktion. Erledigt, siehe 9.1.
3. **Social Login und Magic Links nur für Azubis.** Betriebe bleiben bei E-Mail und Passwort, weil sie eine menschliche Firmenprüfung durchlaufen.
4. **Social-Provider: nur Google und Apple.**

Das Projekt läuft weiterhin auf `localhost`, ohne Domain und ohne Hosting. Das ist bewusst so entschieden: Die Verfahren sollen zunächst entstehen; dass einzelne davon mangels Domain oder Provider noch nicht durchlaufen, ist in der Aufbauphase hinnehmbar. Ein Nebeneffekt davon ist erfreulich — **`localhost` ist im WebAuthn-Standard ausdrücklich ein sicherer Kontext**, Passkeys lassen sich dort also echt testen. Und weil in der Aufbauphase keine echten Passkeys entstehen, entschärft sich die sonst härteste Randbedingung: Die WebAuthn-`rpID` ist an die Domain gebunden und nachträglich nicht migrierbar.

### 9.1 Vorarbeit: Appwrite-SDK 12.0.1 → 25.4.0

Die Instanz läuft auf **Appwrite 1.9.6** (am Health-Endpunkt abgefragt), das Projekt liegt in der Region **Frankfurt**. Letzteres ist mehr als eine Randnotiz: Das Backend selbst ist damit keine Drittlandsübermittlung, der DSGVO-Aufwand konzentriert sich auf das, was tatsächlich hinausgeht — Google und Apple beim Social Login, der SMTP-Anbieter bei den Magic Links, und `fonts.gstatic.com`, solange 7.5 offen ist.

**Das Upgrade war nicht brechend.** Erwartet wurde ein großer, unübersichtlicher Schritt; tatsächlich meldete der Analyzer null Fehler und ausschließlich Deprecation-Hinweise. Drei Annahmen des Plans haben sich als falsch erwiesen, alle zugunsten des Aufwands:

- **33 Aufrufstellen** statt der geschätzten 75.
- **Kein Dart-SDK-Bump nötig** — `appwrite 25.4.0` verlangt `>=2.17.0 <4.0.0`, `^3.4.0` genügt.
- **`setSelfSigned` ist nicht entfallen** und bleibt unverändert stehen.

Geändert wurde:

| | |
|---|---|
| `Databases` → `TablesDB` | `createDocument`→`createRow`, `collectionId`→`tableId`, `documentId`→`rowId`, `models.Document`→`models.Row`, `.documents`→`.rows` — 33 Stellen in vier Repositories und in `notifications_screen.dart` |
| `createVerification` | → `createEmailVerification` |
| MFA-Methoden | durchgehend die großgeschriebenen Nachfolger: `listMFAFactors`, `createMFAChallenge`, `createMFAAuthenticator`, `createMFARecoveryCodes`, `updateMFAChallenge`, `updateMFAAuthenticator` |
| Endpunkt | `cloud.appwrite.io` → **`fra.cloud.appwrite.io`** (der generische Host antwortet weiterhin, leitet aber erst über den globalen Router in die Region) |
| Realtime-Kanal | `databases.X.collections.Y.documents` → `databases.X.tables.Y.rows` |

**Der Realtime-Kanal ist der einzige Punkt dieser Migration, den weder Compiler noch Test prüfen** — er ist eine Zeichenkette. Laden die Benachrichtigungen nicht mehr live nach, ist das die erste Stelle zum Nachsehen (`notifications_screen.dart:98`).

**Nebenbefund, nicht behoben:** `notifications_screen.dart` greift weiterhin direkt auf `TablesDB` zu — ein Bildschirm mitten in der Datenschicht. Das ist derselbe Punkt, der unter 3.1 schon steht.

### 9.2 Härtung der Auth-Schicht

Vorarbeit, an der drei der vier Verfahren hängen. Der volle Umfang aus dem Plan (CSP, Schriften lokal einbetten, DSGVO-Texte) wurde **bewusst zurückgestellt** — das sind Härtungen für eine Produktion, die es noch nicht gibt. Umgesetzt ist nur, worauf die Verfahren tatsächlich aufbauen:

- **`lib/data/repositories/auth_error_mapper.dart` — neu.** Die Fehlerabbildung lag als private Methode im Repository und war damit nicht testbar; die Anforderung „gleiche Meldung bei falschem Passwort und unbekannter Adresse" (`projekt-referenz.md` §3.2) ließ sich nicht nachweisen. Jetzt eine Top-Level-Funktion mit eigenem Test.
- **Rohtexte von Appwrite erreichen den Nutzer nicht mehr.** Der Default-Zweig gab bisher `e.message` durch — englisch, mit internen Bezeichnern, und potenziell verräterisch. Er liefert jetzt nur noch den Fallback; der Rohtext geht unter `kDebugMode` ins Log.
- **`resetPassword` verrät keine Kontoexistenz mehr.** `user_not_found` wird abgefangen, die Antwort ist in beiden Fällen dieselbe.
- **Ein echter Fehler nebenbei behoben:** `createRecovery` bekam dieselbe URL wie die Bestätigungsmail. Der Passwort-Reset-Link zeigte damit auf die Startseite statt auf `/reset-password` — er führte nirgendwohin, wo sich ein Passwort setzen lässt. Jetzt eigene `recoveryUrl`.
- **`appOrigin` als einzige Quelle** für alle Rückleitungen (`verificationUrl`, `recoveryUrl`, `magicLinkUrl`, `oauthSuccessUrl`, `oauthFailureUrl`). Standard `http://localhost:8080`, passend zum Entwicklungsserver aus `.claude/launch.json`.
- **Test-Naht repariert:** `reset_password_screen.dart` und `verify_email_screen.dart` bauten `AuthRepository()` direkt und waren damit in Tests nicht überschreibbar. Beide hängen jetzt am Provider — sonst hätte sich das Muster in jeden neuen Callback-Bildschirm fortgesetzt.

**Fehlertypen für die kommenden Verfahren sind bereits abgebildet**, damit sie nicht einzeln nachgezogen werden müssen: `user_invalid_token` (kontextabhängig, siehe unten), `user_oauth2_*` (eine gemeinsame Meldung), `user_authenticator_not_found`, `user_authenticator_already_verified`, `user_recovery_code_invalid`, `user_challenge_required`.

Zwei bewusste Entwurfsentscheidungen im Mapper:

- **`user_invalid_token` bekommt einen Kontext-Parameter.** Der Typ entsteht sowohl bei einem verbrauchten Anmeldelink als auch bei einem falsch getippten Code. Ein einzelner Text müsste in einem der beiden Fälle danebengreifen.
- **Falscher TOTP-Code und falscher Wiederherstellungscode melden absichtlich dasselbe.** Unterschiedliche Texte würden verraten, ob ein eingegebener Wert überhaupt als Wiederherstellungscode existiert.

**Offen und dokumentiert:** Die Registrierung meldet weiterhin „Für diese E-Mail-Adresse existiert bereits ein Konto" und ist damit ein Konto-Orakel — eine Abweichung von `projekt-referenz.md` §3.2. Enumerationssicher wäre nur eine serverseitige Registrierung; solange sie im Client läuft, sieht dieser den 409 ohnehin. Die Abweichung steht jetzt als Kommentar im Mapper, statt stillschweigend zu bestehen.

### 9.3 MFA / TOTP — eingebaut

Vollständig für **beide Rollen**. Die Rollen-Einschränkung aus Festlegung 3 betrifft nur Social Login und Magic Links.

**Ablauf.** `createEmailPasswordSession` gelingt, aber jeder Folgeaufruf scheitert mit `user_more_factors_required` — die Sitzung besteht serverseitig, trägt aber keine Berechtigungen. Das Repository fängt das ab und wirft `MfaRequired`, **bewusst kein `AuthFailure`**: Es ist kein Fehler, sondern ein planmäßiger Zwischenschritt, und als `AuthFailure` landete er als rote Fehlermeldung auf der Anmeldeseite.

**`AuthState` wächst um `mfaFactors`, `pendingEmail` und den Getter `mfaRequired`.** `user` bleibt in diesem Zustand `null` — dadurch bleiben `isAuthenticated`, `isAzubi`, `isBetrieb` und `emailVerified` für **alle** bestehenden Aufrufer richtig, ohne dass ein einziger Bildschirm angefasst werden musste. Wer halb angemeldet ist, ist nicht angemeldet.

**Der Fund, der über MFA hinausreicht** — siehe 9.8. Beim Einbau der Bestätigungsseite verschwand die Navigation zu `/mfa-challenge` und landete wieder auf `/`. Die zunächst naheliegende Erklärung (der `refreshListenable` feuert, während go_router die Route installiert) war **falsch**; die tatsächliche Ursache lag im Router-Provider selbst und betraf die ganze App.

Unabhängig davon bleibt die daraus gezogene Konsequenz richtig und ist so umgesetzt: Challenge-ID, Ladezustand und Fehlertext liegen **lokal im Bildschirm**, nicht im `AuthState`. `AuthNotifier.submitMfaChallenge` setzt neuen Zustand ausschließlich im Erfolgsfall und reicht Fehler nach oben durch. Der Grund ist jetzt ein anderer, aber ebenso stichhaltig: Der Wächter interessiert sich nicht dafür, ob ein Formular gerade lädt. Jede Zustandsänderung, die ihn nicht betrifft, ist eine unnötige Neuberechnung der Weiterleitung. Die Callback-Bildschirme für Magic Link und OAuth sind nach demselben Muster gebaut.

**Router.** Der Wächter hat jetzt eine festgelegte Reihenfolge, die als Kommentar über dem `redirect` steht: **Laden → zweiter Faktor → E-Mail-Bestätigung → Rolle.** Wer sie umstellt, baut sich eine Weiterleitungsschleife, weil die späteren Tore eine vollständige Sitzung voraussetzen, die die früheren erst herstellen.

`/mfa-challenge` ist wie `/verify-email` ein Sonderfall **vor** den allgemeinen Blöcken und steht **in keiner der drei Pfadlisten** — genau der Fehler, der schon einmal die Schleife bei `/verify-email` erzeugt hat (Abschnitt 1). Öffentliche Seiten bleiben während einer offenen Bestätigung erreichbar; wer mitten in der Anmeldung steckt, darf trotzdem das Impressum lesen.

**Neue Dateien und Routen:**

| Datei | Route | Inhalt |
|---|---|---|
| `presentation/auth/mfa_challenge_screen.dart` | `/mfa-challenge` | Code-Eingabe im `LoginShell`-Stil, Umschalter auf Wiederherstellungscode, Abbruch |
| `presentation/settings/mfa_setup_screen.dart` | `/settings/mfa`, `/betrieb-settings/mfa` | Einrichtung in vier Schritten, Abschalten |
| `data/repositories/auth_error_mapper.dart` | — | Fehlerabbildung, `AuthFailure`, `MfaRequired` |

Beide Einstellungsseiten haben eine Zeile „Zwei-Faktor-Bestätigung" mit Status *Aktiv/Inaktiv*. `UserModel` trägt dafür ein neues Feld `mfaEnabled` aus `account.get()`.

**Zwei Details, die absichtlich so sind:**

- **Die Wiederherstellungscodes kommen vor dem Scharfschalten.** Der Aktivieren-Knopf bleibt gesperrt, bis die Codes angezeigt und per Häkchen bestätigt wurden. Ohne diese Reihenfolge wäre die Einrichtung ein Weg, sich selbst auszusperren.
- **Abbrechen meldet serverseitig ab.** Die halbfertige Sitzung existiert bei Appwrite weiter; ohne `signOut()` liefe der nächste Anmeldeversuch in `user_session_already_exists` — derselbe Fehler, der schon einmal Nutzer ausgesperrt hat (Abschnitt 1). Aus demselben Grund erkennt `_initAuth()` beim Neuladen der Seite eine offene Bestätigung und stellt sie wieder her, statt den Nutzer als abgemeldet zu behandeln.

**Neue Abhängigkeit:** `qr_flutter ^4.1.0` für den Einrichtungs-Code. Zieht nur `qr` nach, reines Dart, keine nativen Bindungen, kein Netzwerkzugriff — nach dem Maßstab aus 7.2 vertretbar.

**Barrierefreiheit:** Das Code-Feld hat ein sichtbares Label (nicht nur einen Platzhalter), `autofillHints: [AutofillHints.oneTimeCode]`, und alle Schaltflächen halten 44 px Mindesthöhe. Fehlermeldungen laufen über `LoginErrorBanner`, das bereits eine `liveRegion` ist.

### 9.4 Magic Links — eingebaut

Nur für Azubis. Auf der Anmeldeseite steht unter dem Passwortfeld ein zweiter Weg „Link per E-Mail schicken", der bei Betrieben nicht erscheint.

| Datei | Route | Inhalt |
|---|---|---|
| `presentation/auth/magic_link_screen.dart` | `/login/azubi/magic` | Adresse eingeben, Bestätigung |
| `presentation/auth/magic_link_callback_screen.dart` | `/auth/magic` | löst `?userId=&secret=` ein |

**Ein Mechanismus für drei Verfahren.** Das Repository tauscht das Einmal-Geheimnis über `_signInWithToken()` gegen eine Sitzung — `createSession(userId, secret)`, nicht das ältere `updateMagicURLSession`, das seit Appwrite 1.6 überholt ist. Derselbe Weg trägt später OAuth und den Passkey-Dienst; beide liefern dasselbe Paar aus `userId` und `secret`.

**`_finishTokenSignIn()` erledigt, was der Passwortweg nicht braucht** und was jede Anmeldung ohne Registrierung betrifft:

- **Betriebssperre.** Appwrite verknüpft Identitäten über die E-Mail-Adresse. Ohne diese Prüfung käme ein Betrieb mit passendem Mail- oder Google-Konto ohne Passwort und ohne Firmenprüfung hinein. Wird ein Betriebskonto erkannt, folgt sofort `signOut()` und eine Fehlermeldung.
- **Rollen-Nachzug.** Nach einer Anmeldung ohne Registrierung gibt es weder Profildokument noch Rolle in den Prefs, und `_fetchCurrentUser()` fällt still auf `azubi` zurück — für neue Nutzer das gewünschte Ergebnis, aber aus dem falschen Grund. `_ensureAzubiProfile()` schreibt es fest.

**Enumerationssicherheit.** Die Bestätigungsseite sagt „Falls für … ein Konto existiert, ist der Anmeldelink unterwegs" — derselbe Text in beiden Fällen. Hier entsteht ohnehin kein Orakel, weil `createMagicURLToken` bei unbekannter Adresse ein Konto anlegt statt zu scheitern.

**Das Geheimnis verlässt die Adresszeile.** Nach dem Einlösen navigiert der Callback mit `context.replace('/dashboard')`, nicht mit `go` — sonst bliebe ein Bearer-Credential im Browserverlauf stehen. Ein Test prüft das: Die Zieladresse darf `secret` nicht mehr enthalten.

**Der Wächter lässt `/auth/magic` unberührt durch**, und zwar noch vor der Ladeprüfung (`callbackPaths`). Jede Weiterleitung von dieser Route würde das Geheimnis verschlucken, bevor es benutzt wurde — der Link wäre verbraucht, die Anmeldung gescheitert.

**Was zum Ausprobieren fehlt:** SMTP in der Appwrite Console. Der Schalter „Magic URL" ist bereits an (9.9), aber ohne eigenen Mailversand kommt nichts an. Das ist der eigentliche Aufwand dieses Verfahrens — EU-Standort, SPF, DKIM, DMARC. Landen die Links im Spam, ist es unbenutzbar. Ein zweiter, nicht lösbarer Fallstrick bleibt: Unternehmens-Mailfilter klicken Links vorab an und verbrauchen den Token. Der Fehlertext benennt das und bietet „Neuen Link anfordern" an.

### 9.5 Social Login (Google, Apple) — eingebaut

Nur für Azubis, wie die Anmeldelinks. Auf der Azubi-Anmeldeseite stehen unter dem Passwortfeld drei Alternativen: Anmeldelink, Google, Apple.

| Datei | Route | Inhalt |
|---|---|---|
| `presentation/auth/widgets/social_sign_in_buttons.dart` | — | Anbieter-Schaltflächen |
| `presentation/auth/oauth_callback_screen.dart` | `/auth/oauth` | löst `?userId=&secret=` ein, behandelt `?error=1` |
| `data/services/oauth_redirect{,_web,_stub}.dart` | — | Seitenweiterleitung, plattformabhängig |

**Token-Flow statt Session-Flow.** `createOAuth2Session` setzt ein Cookie auf der Appwrite-Domain — aus Sicht der App ein Third-Party-Cookie, das Safari und Firefox blockieren. Stattdessen der Token-Weg, der in `_signInWithToken()` aus 9.4 mündet: derselbe Mechanismus wie beim Anmeldelink, inklusive Betriebssperre und Rollen-Nachzug ohne eine Zeile neuen Code.

**Das SDK wird an dieser Stelle bewusst umgangen.** `Account.createOAuth2Token` baut zwar dieselbe Adresse, ruft sie auf Web aber über `FlutterWebAuth2` in einem **Popup** auf. Browser blockieren das regelmäßig, und es passt nicht zu einem Ablauf, der über eine Rückleitungs-URL zurückkommt. Die App baut die Adresse deshalb selbst (`oauth2TokenUrl()`, eine freie Funktion mit eigenem Test) und führt eine echte Seitenweiterleitung aus. Auf Nicht-Web-Plattformen scheitert der Aufruf mit klarer Meldung, statt einen halb funktionierenden Pfad vorzutäuschen — dort bräuchte es einen Deep-Link-Rückweg.

**Es wird nichts von einem fremden Server geladen** — weder Logos noch Skripte. Sonst entstünde allein durch das Anzeigen der Anmeldeseite eine Datenübermittlung an Google, die einwilligungspflichtig wäre. Das Apple-Zeichen liegt in den Material Icons, die mit Flutter ausgeliefert werden.

**Offener Punkt beim Google-Zeichen:** Derzeit steht dort ein neutraler Platzhalter. Googles Markenrichtlinien für „Sign in with Google" verlangen das von Google bereitgestellte Logo in unveränderter Form; ein nachgezeichnetes wäre weder richtlinienkonform noch markenrechtlich sauber. Die Datei gehört heruntergeladen, unter `assets/icons/` abgelegt und eingesetzt — **nicht** zur Laufzeit von Google geladen. Im Code als solcher markiert.

**Eine Layout-Regression, die der Testlauf gefangen hat.** Mit drei zusätzlichen Schaltflächen passte das Anmeldepanel nicht mehr in einen 900 px hohen Viewport, und `login_layout_test.dart` meldete, dass es seine vertikale Mitte um 83 px verfehlt. Behoben durch kompakteren Aufbau statt durch Aufweichen der Schwelle: Die beiden Anbieter stehen nebeneinander statt untereinander (sichtbar nur „Google" und „Apple", für Screenreader die vollständige Handlung), die Alternativen sind 48 statt 52 px hoch, und der Trenner hat engere Abstände.

**Was zum Ausprobieren fehlt:** Client-Zugangsdaten in der Appwrite Console. Beide Anbieter stehen dort auf `disabled`; die Schritte dafür stehen in 9.9.

**Bis dahin sind die Schaltflächen Platzhalter.** Ein Klick würde sonst die App verlassen und auf einer Appwrite-Fehlerseite enden, von der niemand zurückfindet. Stattdessen bleiben sie bedienbar und melden beim Drücken, dass das Verfahren noch nicht bereitsteht — mit Verweis auf Passwort, Passkey und E-Mail-Link. Der Hinweis kostet vorher **keine Höhe**; ein dauerhafter Text hätte die Anmeldeseite erneut aus der vertikalen Mitte geschoben, wie der Layout-Test prompt gemeldet hat. Umgeschaltet wird über `--dart-define=OAUTH_ENABLED=true`.

### 9.6 Passkeys — eingebaut, mit eigenem Serverdienst

Für **beide Rollen**. Passkeys sind phishingresistent und gerade für Betriebe wertvoll; die Rollen-Einschränkung betrifft nur Anmeldelink und Anbieter-Anmeldung.

**Appwrite hat keine WebAuthn-API.** Deshalb entsteht hier die erste eigene Serverkomponente des Projekts: `services/passkey-rp/`. Sie prüft den Passkey und übersetzt eine bestandene Prüfung über `users.createToken()` in ein `{userId, secret}`-Paar — dasselbe, was der Client schon von Anmeldelink und Anbieter-Anmeldung kennt und mit `account.createSession()` gegen eine Sitzung tauscht. Genau deshalb kamen die beiden vorher.

#### Der Dienst

Node 22, TypeScript, **zwei Laufzeit-Abhängigkeiten**: `@simplewebauthn/server` und `node-appwrite`. Kein Framework — bei sechs Routen spart `node:http` vierzig Zeilen und keine Angriffsfläche. Kein eigener Krypto-Code: Die JWT-Prüfung läuft darüber, dass der Dienst einen Appwrite-Client mit dem Token anlegt und `account.get()` ruft; Appwrite entscheidet, ob es gilt.

Der Maßstab ist derselbe, an dem Corbado gescheitert ist (7.2): `package-lock.json` committet, `npm ci --ignore-scripts`, `npm audit` als CI-Gate, eigener Workflow `passkey-rp.yml`. **CodeQL greift ohne Umbau** — es scannt `javascript-typescript` bereits ohne Pfadfilter.

| Methode | Pfad | Auth |
|---|---|---|
| POST | `/webauthn/register/options` | JWT |
| POST | `/webauthn/register/verify` | JWT |
| POST | `/webauthn/login/options` | — |
| POST | `/webauthn/login/verify` | — |
| GET | `/webauthn/credentials` | JWT |
| DELETE | `/webauthn/credentials/:id` | JWT |

**Entscheidungen, die nicht offensichtlich sind:**

- **Anmeldung ohne Nutzernamen** (leere `allowCredentials`). Es gibt damit keine Eingabe, an der sich prüfen ließe, ob ein Konto existiert — das Verfahren ist von sich aus enumerationssicher.
- **Jeder fehlgeschlagene Anmeldeversuch bekommt dieselbe Antwort**, ob der Passkey unbekannt, die Challenge abgelaufen oder die Signatur falsch war. Ein Test prüft, dass sich die Antworten nicht unterscheiden.
- **Challenges werden beim Einlösen gelöscht**, nicht als verbraucht markiert — und zwar auch bei einem Fehlversuch, sonst ließe sich derselbe aufgezeichnete Versuch wiederholen.
- **Der Zählerstand wird geprüft.** Ein nicht gestiegener Zähler deutet auf eine Kopie des Schlüssels hin. Ausnahme: Bleibt er konstant bei 0, führt der Authenticator gar keinen — bei Cloud-Passkeys der Normalfall, eine strenge Prüfung schlösse sie komplett aus.
- **`aaguid` wird nicht gespeichert.** Es benennt das Authenticator-Modell, hat für die Anmeldung keinen Nutzen und wäre ein zusätzliches Merkmal am Nutzer.
- **Der öffentliche Schlüssel verlässt den Dienst nie**, auch nicht in der Liste für die Einstellungen.
- **Die `rpId` wird beim Start hart geprüft**, samt Abgleich gegen jede erlaubte Herkunft. Ein Dienst mit falscher `rpId` erzeugt Passkeys, die sich später von niemandem einlösen lassen — das muss beim Start auffallen, nicht beim ersten Nutzer.
- **Die beiden Tabellen bekommen keine Berechtigungen.** Nur der API-Schlüssel des Dienstes darf lesen; hätten Nutzer Leserecht, ließe sich über die Tabelle aufzählen, welche Konten es gibt.

**25 Tests** (vitest) gegen eine Ablage im Speicher, Typecheck sauber, `npm audit` ohne Befund.

#### Die App-Seite

| Datei | Zweck |
|---|---|
| `web/passkey.js` | Brücke zur WebAuthn-API des Browsers |
| `data/services/passkey_client{,_web,_stub}.dart` | JS-Interop, plattformabhängig |
| `data/services/passkey_api.dart` | HTTP zum Dienst |
| `presentation/auth/widgets/passkey_button.dart` | Anmeldung, beide Rollen |
| `presentation/settings/passkey_manage_screen.dart` | `/settings/passkeys`, `/betrieb-settings/passkeys` |

**Der JS-Shim ist Absicht, keine Notlösung.** Dart hat keine WebAuthn-Bindung. Der Shim nutzt die JSON-Hilfen des Standards (`parseCreationOptionsFromJSON`, `toJSON`), sodass die Umrechnung zwischen base64url und ArrayBuffer im Browser bleibt — in Dart wären das rund zweihundert Zeilen, bei denen ein Vorzeichenfehler erst beim Nutzer auffällt. Er liegt als eigene Datei vor und nicht inline, weil die geplante CSP `script-src 'self'` erlaubt, ein Inline-Skript aber nicht.

**Conditional UI ist nicht machbar** — der Passkey-Vorschlag direkt im Anmeldefeld setzt ein echtes DOM-`<input autocomplete="username webauthn">` voraus; Flutter Web zeichnet Textfelder auf eine Canvas. Es gibt deshalb eine ausdrückliche Schaltfläche. Das ist eine spürbare Einbuße gegenüber nativen Implementierungen und wird nicht besser, solange die App auf Flutter Web läuft.

**Die Betriebssperre gilt hier nicht.** `_signInWithToken()` wurde aufgeteilt: Anmeldelink und Anbieter-Anmeldung laufen weiter durch die Sperre, Passkeys über `_createSessionFromToken()` daran vorbei. Ein Betrieb, der einen Passkey eingerichtet hat, muss sich damit auch anmelden können — die Sperre soll verhindern, dass jemand die Firmenprüfung umgeht, nicht dass Betriebe ein sicheres Verfahren nutzen.

**Ein Entwurfsfehler, den der Testlauf aufgedeckt hat.** Die Frage „kann dieser Browser Passkeys?" hing zunächst als Getter am `AuthRepository`. Damit stürzten **21 bestehende Tests** ab: Alle Fake-Repositories nutzen `noSuchMethod`, das für einen `bool`-Getter `null` liefert. Der Fehler war aber nicht der Test, sondern die Zuordnung — eine Plattformeigenschaft ist keine Frage an die Datenschicht. Sie liegt jetzt in einem eigenen `passkeySupportProvider`, den Tests umschalten können, ohne dass jedes Fake ihn kennen muss.

**Eine zweite Layout-Regression**, gleiche Art wie bei den Anbieter-Schaltflächen: Der neue „Passkeys"-Eintrag in den Betriebs-Einstellungen schob den Team-Eintrag unter die Sichtkante, ein Test tippte ins Leere. Behoben, indem der Test vorher hinscrollt — die Zusicherung bleibt unverändert.

**Was zum Ausprobieren fehlt:** Die beiden Tabellen in der Appwrite Console, ein API-Schlüssel mit **ausschließlich** `users.read` und `users.write`, und ein laufender Dienst (`npm run dev`). `localhost` genügt: Im WebAuthn-Standard ist es ausdrücklich ein sicherer Kontext, `rpId=localhost` ist gültig. Solche Passkeys funktionieren produktiv nicht — in der Aufbauphase ist das richtig so.

### 9.7 Registrierung für Azubis — neu geordnet

Die alternativen Wege standen bisher nur auf den Anmeldeseiten. Wer sich neu registriert, sah sie nicht — obwohl Anmeldelink und Anbieter-Anmeldung bei unbekannter Adresse ein Konto **anlegen** und damit genauso zum Registrieren taugen.

**Neue Reihenfolge der drei Schritte:** Zugangsdaten → Persönliche Daten → Ausbildungsinfo. Vorher standen die Zugangsdaten am Ende. Das war die falsche Reihenfolge, sobald es Alternativen gibt: Wer per Google einsteigen will, hätte erst zwei Schritte ausfüllen müssen, die danach hinfällig sind.

**Auf dem ersten Schritt stehen jetzt** E-Mail/Passwort, darunter ein Trenner „oder ohne Passwort" und die drei anderen Wege: E-Mail-Link, Google, Apple (letztere beide bis zur Freischaltung als Platzhalter, siehe 9.5).

**Passkeys werden dort bewusst nicht angeboten.** Ein Passkey hängt an einem bestehenden Konto — der eigene Dienst verlangt ein JWT, also eine Sitzung. „Mit Passkey registrieren" gibt es in diesem Aufbau nicht. Statt eines Knopfes, der scheitern müsste, steht dort ein Satz: einrichten geht direkt nach der Registrierung in den Einstellungen.

**Die AGB-Zustimmung ist mit umgezogen** — vom früheren letzten Schritt (Zugangsdaten) auf den neuen letzten Schritt. Die Zustimmung gehört zu der Schaltfläche, die sie auslöst; am Anfang abgehakt läge sie zwei Schritte vor dem Absenden.

**Drei Layout-Fehler nebenbei behoben**, alle vorbestehend und in Abschnitt 4 als offen geführt. Sichtbar wurden sie erst durch den neuen Test — für diese Seite gab es bis dahin keinen:

- Die **Beschriftungen im Fortschrittsband** standen neben der Verbindungslinie in derselben Zeile und bekamen dort keine Breitenbegrenzung. Je nach Wortlänge lief die Zeile über. Kreis und Linie liegen jetzt in einer eigenen Zeile, die Beschriftung darunter über die volle Zellenbreite, mit Umbruch und Auslassung.
- Der **Schrittinhalt** stand in einer Column mit `Spacer`, die auf schmalen Fenstern überlief. Er scrollt jetzt innerhalb des Rahmens.
- Die **Fußzeile** „Bereits ein Konto? Anmelden" war eine `Row` und lief bei 360 px um 92 px über. Jetzt ein `Wrap`, das umbricht.

**Neuer Test `register_azubi_layout_test.dart`** (11 Tests): kein Überlauf über sechs Breiten plus 1,3-fache Systemschrift, dazu die Reihenfolge der Schritte und die Abwesenheit des Passkey-Knopfes.

**Nicht angefasst:** Die Registrierung für Betriebe. Dort gibt es bewusst keine Alternativen — Social Login und Anmeldelink bleiben Azubis vorbehalten, weil Betriebe die Firmenprüfung durchlaufen müssen.

### 9.8 Zwei Fehler im Router-Provider — behoben, betraf die ganze App

Aufgefallen beim Einbau der Magic-Link-Rückleitung: Die Navigation zu einer neuen Route verschwand und landete wieder auf `/`. Zwei Fehler in `lib/app/router.dart` haben sich dabei gegenseitig verdeckt.

**1. `ref.watch(authProvider)` im `routerProvider`.** Damit wurde bei **jeder** Änderung des Anmeldezustands ein **neuer `GoRouter`** erzeugt. Ein neuer Router beginnt bei `initialLocation: '/'` — der Navigationsstand war also weg. Betroffen war jede Anmeldung, jeder Ladewechsel und jede Fehlermeldung, nicht nur die neuen Verfahren.

**2. Der `refreshListenable` hat nie gefeuert.** Das Abonnement lag als `late final _sub = _ref.listen(...)` im Feld. Ein `late final` wird erst beim ersten Lesen ausgewertet — und gelesen wurde `_sub` ausschließlich in `dispose()`. Das Abonnement kam damit nie zustande.

Zusammen ergab das einen Zustand, der funktionierte, aber aus dem falschen Grund: Die Weiterleitung wurde ausschließlich über Fehler 1 neu berechnet — also über genau den Weg, der den Navigationsstand wegwirft. Fehler 2 blieb unsichtbar, weil sein Fehlen durch Fehler 1 kompensiert wurde.

Behoben: `ref.watch` entfernt, das Abonnement im Konstruktor eingerichtet. Der Wächter liest den Zustand weiterhin per `ref.read` zum Zeitpunkt der Auswertung, der `refreshListenable` stößt die Neuberechnung an — so, wie es vorgesehen war.

**Zwei Nebenwirkungen, die den Fund bestätigen:**

- Die Testsuite läuft von **44 auf 13 Sekunden**. Der Router wurde bis dahin bei jeder Zustandsänderung samt aller 40 Routen neu aufgebaut.
- Die vorherige Erklärung in 9.3 („der Listener feuert während der Routeninstallation") war **falsch** — der Listener feuerte überhaupt nicht. Die daraus gezogene Konsequenz, Ladezustände nicht in den `AuthState` zu legen, bleibt trotzdem richtig; nur die Begründung ist eine andere.

**Methodischer Hinweis, gleicher Art wie bei 7.1:** Die erste plausible Erklärung war hier die falsche, und sie hätte gehalten — der Umbau auf lokalen Zustand hat das Symptom ja beseitigt. Sichtbar wurde der wahre Grund erst, als dasselbe Symptom an einer zweiten, ganz anders gebauten Stelle wieder auftrat. **Ein Symptom, das an zwei unabhängigen Stellen auftritt, hat selten zwei Ursachen.**

### 9.9 Was in der Appwrite Console fehlt

Konfiguration, kein Code. Stand der Console am 5. August, vom Betreiber bestätigt:

**Unter *Auth → Settings* sind alle sieben Anmeldeverfahren eingeschaltet** — Email/Password, Email OTP, JWT, Phone, Anonymous, Magic URL, Team Invites. **Alle 30+ OAuth2-Anbieter stehen auf `disabled`**, Google und Apple eingeschlossen; beide sind vorhanden, brauchen aber Client-Zugangsdaten.

#### Google und Apple freischalten

Bis das erledigt ist, sind die beiden Schaltflächen **Platzhalter**: Sie sind sichtbar und bedienbar, sagen beim Drücken aber, dass das Verfahren noch nicht bereitsteht, und verlassen die App nicht (siehe 9.5). Gesteuert über `AppwriteConstants.oauthEnabled`, Standard `false`.

**Google**

1. Google Cloud Console → *APIs & Services* → *Credentials* → OAuth-Client-ID vom Typ *Webanwendung* anlegen.
2. Als **autorisierten Redirect-URI** eintragen, was die Appwrite Console im Google-Dialog anzeigt. Erwartete Form für dieses Projekt:
   `https://fra.cloud.appwrite.io/v1/account/sessions/oauth2/callback/google/6a3c45ef003356d7f16d`
   **Aus der Console kopieren, nicht abtippen** — weicht die URI um ein Zeichen ab, lehnt Google die Anmeldung mit `redirect_uri_mismatch` ab.
3. Client ID und Client Secret in Appwrite unter *Auth → Settings → Google* hinterlegen und den Anbieter aktivieren.

**Apple**

Aufwendiger, weil ein Apple-Developer-Programm nötig ist (kostenpflichtig). Gebraucht werden **Services ID**, **Team ID**, **Key ID** und ein **P8-Schlüssel**. Zusätzlich die Return-URL wie oben eintragen und die Domain für *Sign in with Apple Email Relay* per SPF/DKIM verifizieren — ohne das erreichen keine Mails Nutzer mit „Hide My Email".

**Danach**

Beide Anbieter in Appwrite aktivieren, `http://localhost:8080` als Web-Plattform eintragen, und die App mit `--dart-define=OAUTH_ENABLED=true` bauen. Erst dann lösen die Schaltflächen aus.

**Die Secrets gehören nicht ins Repository** und auch nicht in eine Datei im Projekt — sie leben ausschließlich in der Appwrite Console.

Daraus folgt für die geplanten Verfahren:

- **Magic URL ist bereits an.** In der Console bleiben nur SMTP und ein deutsches Template — daran hängt das Verfahren ohnehin mehr als am Schalter.
- **JWT ist an.** Wichtiger als es aussieht: Der Passkey-Dienst identifiziert den Nutzer über `account.createJWT()` und prüft ihn serverseitig per `setJWT`. Ohne den Schalter hätte das später eine schwer zuzuordnende 401-Wand ergeben.
- **Email OTP ist an.** Der Ersatzweg für Magic Links steht damit ohne weiteren Handgriff bereit (siehe unten).

**Weiterhin offen — der einzige Handgriff zwischen dem aktuellen Stand und benutzbarer Zwei-Faktor-Bestätigung:**

- **MFA auf Projektebene einschalten** — Reiter **Auth → Security**, *nicht* unter *Settings*. Ohne diesen Schalter antworten sämtliche `mfa*`-Endpunkte nicht.
- `http://localhost:8080` als Web-Plattform eintragen, sonst weist Appwrite die Ziel-URLs von Bestätigungsmail, Reset und Magic Link zurück.

**Zwei Verfahren sollten wieder abgeschaltet werden, bevor echte Nutzer dazukommen:**

- **Anonymous.** Damit erzeugt jeder ohne Zugangsdaten per `account.createAnonymousSession()` eine echte Appwrite-Sitzung. Die App ruft das nirgends auf — das Risiko liegt darin, dass der Endpunkt offen steht. In Appwrite zählt eine solche Sitzung als `users`; jede Collection mit `Role.users()` statt `Role.user(...)` wäre für beliebige Fremde erreichbar. **Das ist die Kehrseite von 7.3:** Solange die Berechtigungen nicht geprüft sind, verbreitert dieser Schalter die Angriffsfläche ohne Gegenwert. Ins Dashboard käme so jemand allerdings nicht — der Wächter leitet mangels bestätigter Adresse auf `/verify-email`.
- **Phone.** Ohne SMS-Anbieter wirkungslos, kann aber als zweiter Faktor auftauchen. Der Code behandelt `phone` bereits; die Abfrageseite spricht dann jedoch von „Code aus deiner Authenticator-App" — ungenauer Text, kein Fehler.

Das Muster dahinter: Hier wurde vermutlich einmal „Enable all" geklickt. In der Aufbauphase unkritisch, vor dem ersten echten Nutzer gehört die Liste auf das reduziert, was die App tatsächlich verwendet — Email/Password, Magic URL, JWT und Team Invites.

**Alternative, falls Magic Links an der Zustellbarkeit scheitern:** **Email OTP** ist bereits aktiv — ein sechsstelliger Code per Mail statt eines Links (`createEmailToken`). Er umgeht die beiden Schwächen des Magic Links aus 9.4: kein Bearer-Credential im Browserverlauf, und kein Verbrauch durch vorab klickende Mailfilter. Preis ist ein Tippschritt. Die Fehlerabbildung aus 9.2 deckt beide Wege bereits ab.
- Für Social Login: Google- und Apple-Zugangsdaten, Redirect-URIs bei beiden Anbietern, bei Apple zusätzlich Domain-Verifikation für den E-Mail-Relay.
- Für Passkeys: die Tabellen `passkeys` und `webauthn_challenges` anlegen — **beide ohne jede Berechtigung**, nur der Dienst darf lesen. Dazu ein API-Schlüssel mit **ausschließlich** `users.read` und `users.write`, kein `sessions.write` auf Projektebene. Felder und Indizes stehen in `services/passkey-rp/README.md`.

### 9.10 Was nicht geprüft ist

**Nichts davon ist gegen die echte Appwrite-Instanz gelaufen.** Alle 185 Tests arbeiten gegen Fakes; es gibt weiterhin keinen Test, der eine echte Appwrite-Antwort sieht (Abschnitt 8). Konkret ungeprüft:

- Anmeldung, beide Registrierungen, Bestätigungsmail und Passwort-Reset **nach** dem SDK-Upgrade
- der Realtime-Kanal der Benachrichtigungen (9.1)
- der Anmeldelink von Ende zu Ende: Versand, Zustellung, Einlösen, zweites Öffnen desselben Links
- die Anbieter-Anmeldung von Ende zu Ende, und zwar in **Chrome, Safari und Firefox** — der Token-Weg ist genau wegen der Cookie-Sperren dieser Browser gewählt
- der Passkey-Ablauf gegen den echten Dienst: Einrichten, Anmelden, Löschen, und ein zweiter Passkey auf einem anderen Gerät. Die 25 Dienst-Tests laufen gegen eine Ablage im Speicher, nicht gegen Appwrite
- TOTP-Einrichtung mit einer echten Authenticator-App, Anmeldung mit Code, Anmeldung mit Wiederherstellungscode, Neuladen bei offener Bestätigung, Abbruch-Pfad

**Ein Schuldenposten, der mit jedem neuen Verfahren schwerer wiegt:** Die Rolle ist client-behauptet und serverseitig nicht validiert — Prefs und Profildokument sind beide vom Nutzer schreibbar, Appwrite Teams oder Labels werden nicht verwendet. Bei einem Anmeldeweg war das eine bekannte Schwäche (7.3); bei vier vervielfacht sich die Angriffsfläche. Sauber wären Teams (`azubis`, `betriebe`), gesetzt durch eine Appwrite Function, mit Collection-Berechtigungen gegen `Role.team('betriebe')`. Das ist eine eigene, nicht kleine Aufgabe und gehört spätestens zu den Passkeys, weil dort ohnehin ein Server-SDK mit API-Schlüssel entsteht.

### 9.11 Übersicht

#### Umgesetzt

| Punkt | Wo | Hinweis |
|---|---|---|
| Appwrite-SDK 12.0.1 → 25.4.0, `Databases` → `TablesDB` | 4 Repositories, `notifications_screen.dart` | Nicht brechend, 33 Stellen statt der geschätzten 75 |
| Regionaler Endpunkt | `appwrite_constants.dart` | `fra.cloud.appwrite.io` statt generischem Host |
| Fehlerabbildung ausgelagert | `auth_error_mapper.dart` | Erstmals testbar; Appwrite-Rohtexte erreichen den Nutzer nicht mehr |
| Passwort-Reset enumerationssicher + eigene `recoveryUrl` | `auth_repository.dart` | Der Reset-Link zeigte vorher auf die Startseite statt auf `/reset-password` |
| `appOrigin` als einzige Quelle aller Rückleitungen | `appwrite_constants.dart` | Standard `http://localhost:8080` |
| Test-Naht repariert | `reset_password_screen`, `verify_email_screen` | Bauten `AuthRepository()` direkt |
| **MFA / TOTP** | 3 Routen, beide Rollen | Wiederherstellungscodes werden vor der Aktivierung erzwungen |
| **Magic Links** | 2 Routen, nur Azubis | `createSession` statt des überholten `updateMagicURLSession` |
| **Social Login** (Google, Apple) | 1 Route, nur Azubis | Token-Flow mit echter Seitenweiterleitung statt SDK-Popup; bis zur Freischaltung Platzhalter |
| Registrierung Azubi neu geordnet | 3 Layout-Fehler behoben | Zugangsdaten zuerst, Alternativen dort; Passkeys bewusst nicht (9.7) |
| **Passkeys** | 2 Routen + eigener Dienst | `services/passkey-rp/`: Node, zwei Abhängigkeiten, 25 Tests |
| Betriebssperre + Rollen-Nachzug | `_finishTokenSignIn()` | Trägt OAuth und Passkeys unverändert mit |
| Zwei Router-Fehler behoben | `router.dart` (9.8) | Betraf die ganze App; Testsuite 44 s → 13 s |
| 51 neue Tests | 7 Dateien | 134 → 185, dazu 25 im Passkey-Dienst |

#### Probleme und Einschränkungen

| Punkt | Art | Hinweis |
|---|---|---|
| Nichts gegen die echte Appwrite-Instanz gelaufen | **Prüflücke** | Alle 185 Tests arbeiten gegen Fakes — gilt unverändert seit dem 2. August |
| Rolle ist client-behauptet | **strukturell** | Mit vier Anmeldewegen statt einem vervielfacht sich die Angriffsfläche (7.3, 9.9) |
| „Anonymous" in der Console aktiv | **Angriffsfläche** | Jeder kann ohne Zugangsdaten eine Sitzung erzeugen; zusammen mit ungeprüften Berechtigungen relevant (9.9) |
| Betriebssperre prüft im Client | **Krücke** | Wirkt, ersetzt aber keine serverseitige Regel |
| Registrierung bleibt ein Konto-Orakel | **bewusste Abweichung** | Nur mit serverseitiger Registrierung lösbar; im Mapper dokumentiert (9.2) |
| Realtime-Kanal der Benachrichtigungen | **ungeprüft** | Zeichenkette, die weder Compiler noch Test erfasst (9.1) |
| `localhost`-Fallback besteht weiter | **7.7, entschärft** | Produktiv zwingend `--dart-define=APP_ORIGIN=…` |
| „Phone" kann als zweiter Faktor auftauchen | **kosmetisch** | Der Text spricht dann trotzdem von der Authenticator-App |
| Conditional UI für Passkeys | **nicht machbar** | Flutter Web zeichnet Textfelder auf Canvas; es wird eine ausdrückliche Schaltfläche |
| Abgelaufene Challenges bleiben liegen | **Aufräumen fehlt** | Werden beim Einlösen gelöscht; wer nie einlöst, hinterlässt eine Zeile |
| `rpId` an die Domain gebunden | **unwiderruflich** | Passkeys von `localhost` gelten produktiv nicht. In der Aufbauphase folgenlos |
| Google-Logo ist ein Platzhalter | **vor dem Start ersetzen** | Googles Markenrichtlinien verlangen die von Google gelieferte Datei, lokal eingebunden (9.5) |
| Anbieter-Anmeldung nur im Browser | **Plattformgrenze** | Auf Mobil bräuchte es einen Deep-Link-Rückweg; scheitert dort mit klarer Meldung |

#### Offen

| Punkt | Blockiert durch | Hinweis |
|---|---|---|
| MFA erproben | Schalter in der Console | **Auth → Security**, ein Handgriff — sonst antworten die `mfa*`-Endpunkte nicht |
| Magic Links erproben | SMTP in der Console | EU-Standort, SPF, DKIM, DMARC. Ohne eigenen Versand kommt kein Link an |
| Social Login erproben | Client-Zugangsdaten | Schritte in 9.9. Bis dahin sind die Schaltflächen Platzhalter; danach mit `--dart-define=OAUTH_ENABLED=true` bauen |
| Passkeys erproben | Tabellen + API-Schlüssel in der Console | Dazu den Dienst starten. `localhost` genügt — solche Passkeys gelten produktiv aber nicht |
| Rollen serverseitig absichern | eigene Aufgabe | Appwrite Teams oder Labels; spätestens mit den Passkeys, weil dort ohnehin ein Server-SDK entsteht |
| `deleteAccount` umsetzen | Server mit API-Schlüssel | DSGVO Art. 17; blockiert auch das Löschen von Passkey-Daten (2.2) |
| CSP und lokale Schriften | zurückgestellt | Der Passkey-Shim liegt bereits als eigene Datei vor und ist damit `script-src 'self'`-tauglich (7.5) |
| Passkey-Dienst deployen | Hosting fehlt | Als Appwrite Function geplant, damit kein zweiter Auftragsverarbeiter entsteht |
| Ratenbegrenzung im Dienst | offen | Mit eigenem Server erstmals selbst durchsetzbar (`projekt-referenz.md` §2.4) |
| Console aufräumen | vor den ersten Nutzern | Derzeit alle sieben Anmeldeverfahren aktiv; gebraucht werden vier (9.9) |

---

## 10. Vor Go-Live

- Impressum, Datenschutz und AGB enthalten ausschließlich Platzhaltertexte und müssen anwaltlich geprüft werden.
- Punkt 2.2 (Kontolöschung) ist DSGVO-relevant und braucht eine serverseitige Function.
- Kein Cookie-/Consent-Banner vorhanden.
- Keine gestaltete Fehlerseite — `errorBuilder` im Router zeigt rohen Text auf leerem Scaffold.
- `APP_ORIGIN` im Build setzen und den Host als Appwrite-Web-Plattform eintragen, sonst kommt weder Bestätigungsmail noch Passwort-Reset noch Magic Link an (7.7, Abschnitt 9.2).
- **Rollen serverseitig absichern** (Abschnitt 9.10) — mit vier Anmeldewegen statt einem trägt die client-behauptete Rolle nicht mehr. Appwrite Teams oder Labels, gesetzt durch eine Function.
- **Nicht genutzte Anmeldeverfahren in der Console abschalten** (Abschnitt 9.9) — derzeit sind alle sieben aktiv, darunter „Anonymous". Zusammen mit den ungeprüften Collection-Berechtigungen (7.3) ist das offene Angriffsfläche ohne Gegenwert.
- **Appwrite-Collection-Permissions in der Console prüfen** (7.3) — der einzige serverseitige Zugriffsschutz, aus dem Code nicht verifizierbar.
- **Google Fonts lokal einbetten** (7.5) — sonst fließen Nutzer-IPs an Google ab.
- **Barrierefreiheit:** Die Akzentfarbe verfehlt den WCAG-AA-Kontrast (Abschnitt 5), und die Kopfzeile bricht bei vergrößerter Systemschrift (Abschnitt 4). Beides ist für eine Plattform mit öffentlichem Auftritt in der EU relevant und sollte vor dem Start behoben sein.
- **SonarCloud Automatic Analysis abschalten** — die Konfiguration ist aus dem Repository entfernt, die Analyse läuft ohne diesen Schritt aber mit Defaults weiter (siehe Abschnitt 6).

---

## 11. Vorgeschlagene Reihenfolge

**Vorab — Sicherheit**
0. ~~`reporterId`-Platzhalter (7.4), `allowBackup` (7.6), `flutter_secure_storage` (7.8), `debugPrint` (7.9), `.gitignore`-Korrekturen.~~ **Erledigt.** Die Historienbereinigung (7.1) ebenfalls, war nach Prüfung aber ohnehin nicht sicherheitsrelevant. Offen bleiben drei: die Prüfung der Appwrite-Permissions (7.3) gehört zeitlich vor den ersten echten Nutzer, die Schriften (7.5) und die Build-Konfiguration (7.7) vor den Go-Live.
0b. **Zuerst überhaupt:** die Zugangsdaten-Zeile in `notes/fehler.md` prüfen (7.10) — ein Handgriff, und solange sie ungeklärt ist, steht sie über allem anderen auf dieser Liste.

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

**Parallel — Anmeldeverfahren** (Abschnitt 9)
- MFA in der Appwrite Console einschalten und den eingebauten Ablauf gegen die echte Instanz durchspielen. Ein Handgriff, und ohne ihn ist die fertige Arbeit nicht benutzbar.
- SMTP und die Anbieter-Zugangsdaten hinterlegen, dann Magic Links und Social Login gegen die echte Instanz durchspielen — Social Login in Chrome, Safari und Firefox.
- Für Passkeys die zwei Tabellen und den API-Schlüssel anlegen, dann den Dienst lokal starten und den Ablauf auf zwei Plattformen durchspielen (etwa Windows Hello und Touch ID).
- **Die Rollen-Absicherung (9.10) gehört spätestens vor den ersten echten Nutzer**, nicht erst vor den Go-Live.

**Parallel — Oberfläche**
9. **Kopfzeilen-Überlauf bei vergrößerter Systemschrift** (Abschnitt 4) — betrifft jede Seite, deshalb vor den Einzelseiten
10. Die 24 Layout-Überläufe (mechanisch, gleiches Muster)
11. `review_card` und `job_card` auf Swiss-Design
12. Auth-Seiten inklusive fehlender Kopfzeile
13. Restliche Betriebs- und Azubi-Seiten
14. Akzentfarbe auf `accentDark` umstellen (Abschnitt 5) — Theme-Änderung, betrifft die ganze App, deshalb bewusst nach den Einzelseiten

**Zum Schluss**
15. Fehlerseite gestalten
16. Layout-Durchlauf als dauerhaften Test etablieren, Schriftskalierung in allen Layout-Tests ergänzen
17. Verbleibende `IntrinsicHeight`-Konstruktionen umstellen (Abschnitt 1, Nachtrag)
18. `dart fix --apply`, Migrationsreste entfernen
19. Rechtstexte, Consent, `verificationUrl` im Build
