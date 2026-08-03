# Karriko – Statusbericht

**Stand:** 3. August 2026 · Erstfassung: 2. August 2026
**Branch:** `redesign/swiss-style-search-fuer-betriebe`
**Grundlage:** Neu gemessen — automatisierter Layout-Durchlauf über alle 37 Routen in fünf Viewportbreiten, Abgleich Screens ↔ Repositories ↔ Appwrite-Collections, Analyzer- und Testlauf.

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
| Analyzer-Hinweise | 86 | **67** |

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
- **67 Analyzer-Hinweise** (vorher 86), keine Fehler, keine Warnungen — überwiegend `prefer_const_constructors` und `withOpacity`-Veraltung. Mit `dart fix --apply` weitgehend automatisch behebbar.
- `old_tsx/` und `node_modules/` liegen im Repo-Wurzelverzeichnis.
- GitHub meldet **21 Dependabot-Warnungen auf `main`** (11 hoch, 8 mittel, 2 niedrig). Betrifft den Altbestand, nicht diesen Branch.

---

## 7. Tests

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

## 8. Vor Go-Live

- Impressum, Datenschutz und AGB enthalten ausschließlich Platzhaltertexte und müssen anwaltlich geprüft werden.
- Punkt 2.2 (Kontolöschung) ist DSGVO-relevant und braucht eine serverseitige Function.
- Kein Cookie-/Consent-Banner vorhanden.
- Keine gestaltete Fehlerseite — `errorBuilder` im Router zeigt rohen Text auf leerem Scaffold.
- `verificationUrl` und Appwrite-Plattformen konfigurieren, sonst kommt keine Bestätigungsmail an.

---

## 9. Vorgeschlagene Reihenfolge

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
