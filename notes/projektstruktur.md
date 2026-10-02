# Karriko – Aufbau des Projekts

**Stand:** 30. August 2026
**Zweck:** Wo liegt was, und warum dort. Gedacht als Landkarte für den Einstieg — nicht als Beschreibung dessen, was funktioniert (das steht in [`reports/`](reports/)) und nicht als fachliche Regel (die steht in [`projekt-referenz.md`](projekt-referenz.md)).

Nicht behandelt, weil Werkzeug- und nicht Projektsache: `.claude/`, `.github/`, `.idea/`, `.vscode/`, `.next/`, `graphify-out/`.

---

## 1. Die Landkarte

```
Karriko/
├── karriko_flutter/     die Anwendung            ← hier passiert 95 % der Arbeit
├── services/            eigene Serverdienste
├── notes/               Dokumentation
├── old_tsx/             abgelöster Prototyp      ← nur Nachschlagewerk
└── README.md
```

| Ordner | Was | Sprache | Wird gebaut? |
|---|---|---|---|
| **`karriko_flutter/`** | Web-, iOS- und Android-App | Dart / Flutter | ja |
| **`services/passkey-rp/`** | WebAuthn-Dienst für Passkeys | TypeScript / Node | ja, getrennt |
| **`notes/`** | Referenz, Berichte, Todo, Design-Entwurf | Markdown | nein |
| **`old_tsx/`** | Next.js-Prototyp von vor der Portierung | TypeScript | **nein** |

**Zwei getrennte Anwendungen, nicht eine.** `karriko_flutter/` und `services/passkey-rp/` haben eigene Abhängigkeiten, eigene Tests und eigene CI-Läufe. Sie sprechen nur über HTTP miteinander.

**Nur lokal, nicht im Repository:** `node_modules/` und `karriko.db` im Wurzelverzeichnis sowie `old_tsx/.env.local` und `old_tsx/karriko.db`. Alle vier sind Reste des Prototyps und über `.gitignore` ausgeschlossen — beim Klonen sind sie nicht da, und das ist richtig so.

---

## 2. `karriko_flutter/` — die Anwendung

```
karriko_flutter/
├── lib/                 der gesamte Anwendungscode      84 Dateien
├── test/                Tests                           15 Dateien, 194 Tests
├── web/                 Einstiegspunkt der Web-Fassung
├── android/ ios/        Plattform-Fassungen
├── linux/ macos/ windows/   generiert, ungetestet
├── pubspec.yaml         Abhängigkeiten
├── pubspec.lock         festgeschriebene Versionen      gehört ins Repo
└── analysis_options.yaml  Regeln des Analyzers
```

### 2.1 `lib/` — der Anwendungscode

Vier Schichten, von unten nach oben:

```
lib/
├── main.dart                 Startpunkt
├── app/
│   ├── app.dart              MaterialApp, Theme
│   └── router.dart           45 Routen + Wächterlogik
│
├── core/                     ⓵ Grundlagen — kennt nichts über sich
│   ├── constants/
│   │   ├── app_constants.dart      Branchen, Listen
│   │   └── appwrite_constants.dart IDs, Dart-Defines, alle URLs
│   ├── theme/app_theme.dart        Farben, Typografie, Abstände
│   └── utils/                      Validatoren, Datumsformate
│
├── data/                     ⓶ Datenschicht — spricht mit Appwrite
│   ├── models/                     UserModel, CompanyModel, ReviewModel …
│   ├── repositories/               ein Repository je Domäne
│   └── services/                   Clients, plattformabhängiger Code
│
├── providers/                ⓷ Zustand — Riverpod, je Domäne einer
│
└── presentation/             ⓸ Oberfläche — 4 Bereiche + Gemeinsames
    ├── auth/                       Anmeldung und Registrierung
    ├── azubi/                      Bereich für Auszubildende
    ├── betrieb/                    Bereich für Betriebe
    ├── settings/                   MFA, Passkeys (beide Rollen)
    ├── public/                     öffentliche Seiten
    └── common/                     Baukasten und geteilte Bauteile
```

**Die Regel dahinter:** `presentation → providers → repositories → Appwrite`. Jede Schicht kennt nur die unter ihr. Ein Bildschirm greift nie direkt auf Appwrite zu.

> **Eine Ausnahme, und sie ist ein bekannter Mangel:** `presentation/azubi/notifications_screen.dart` spricht direkt mit `TablesDB`, an Provider und Repository vorbei. Steht als offener Punkt in der [Todo-Liste](todo.md), Abschnitt B.6.

### 2.2 Die vier Bereiche der Oberfläche

| Ordner | Wer sieht das | Beispiele |
|---|---|---|
| `public/` | alle, ohne Konto | Startseite, Suche, Unternehmensprofil, Blog, FAQ |
| `public/legal/` | alle | Impressum, Datenschutz, AGB — auf gemeinsamem Gerüst |
| `auth/` | Nicht-Angemeldete | Login, Registrierung, MFA-Abfrage, Callback-Seiten |
| `azubi/` | Rolle Azubi | Dashboard, Bewertung schreiben, Merkliste |
| `betrieb/` | Rolle Betrieb | Dashboard, Unternehmensprofil, Analytics, Team |
| `settings/` | beide Rollen | MFA-Einrichtung, Passkey-Verwaltung |
| `common/` | — | `AppPage`, `AppCard`, Kopfzeile, Fußzeile, Karten |

`common/app_page.dart` ist der Baukasten, auf dem die Seiten des eingeloggten Bereichs aufsetzen: `AppPage`, `AppCard`, `AppRowGroup`, `AppRow`, `AppSwitchRow`, `StatTile`, `AppEmptyState`. Wer eine neue Seite baut, fängt dort an.

### 2.3 Wo die Daten herkommen

| Repository | Zuständig für |
|---|---|
| `auth_repository.dart` | Konto, Sitzung, alle fünf Anmeldeverfahren, Firmen-Verknüpfung |
| `company_repository.dart` | Unternehmen, Suche, Merkliste |
| `review_repository.dart` | Bewertungen, Antworten, Meldungen |
| `question_repository.dart` | Fragenkatalog |
| `auth_error_mapper.dart` | **kein Repository** — übersetzt Appwrite-Fehler in deutsche Texte |

`auth_error_mapper.dart` liegt bewusst getrennt: Als private Methode im Repository war die Regel „falsches Passwort und unbekannte Adresse melden dasselbe" nicht prüfbar. Jetzt ist sie eine freie Funktion mit eigenem Test.

### 2.4 Plattformabhängiger Code

Drei Dateien mit demselben Namensmuster gehören zusammen:

```
passkey_client.dart        wählt aus
passkey_client_web.dart    Fassung für den Browser
passkey_client_stub.dart   Fassung für alles andere (scheitert mit klarer Meldung)
```

Betrifft zwei Themen: den Passkey-Client und die Weiterleitung beim Anbieter-Login (`oauth_redirect*.dart`). Dart wählt beim Bauen anhand der Zielplattform aus.

### 2.5 `test/` — 15 Dateien, 194 Tests

Nach Prüfgegenstand, nicht nach Quellcode-Ordner benannt:

| Muster | Prüft | Dateien |
|---|---|---|
| `*_layout_test.dart` | kein Überlauf über 5–7 Viewportbreiten | 6 |
| `router_guard*_test.dart` | Weiterleitungen und Rollen-Tore | 2 |
| `*_callback_test.dart` | Einlösen von Anmeldelink und OAuth | 2 |
| `auth_error_*_test.dart` | Fehlertexte und Enumerationssicherheit | 2 |
| übrige | MFA-Zustand, Passkeys, Firmen-Verknüpfung | 3 |

**Alle Tests laufen gegen Fakes.** Kein Test sieht eine echte Appwrite-Antwort — die wichtigste Einschränkung des gesamten Projekts.

### 2.6 `web/` — der Einstiegspunkt der Web-Fassung

| Datei | Inhalt |
|---|---|
| `index.html` | lädt **ausschließlich lokale** Ressourcen, kein Fremdskript |
| `passkey.js` | Brücke zur WebAuthn-API des Browsers |
| `manifest.json`, `favicon.png`, `icons/` | PWA-Beiwerk |

`passkey.js` liegt als eigene Datei und nicht inline, weil eine geplante Content-Security-Policy mit `script-src 'self'` Inline-Skripte nicht erlaubt.

### 2.7 Die Plattformordner

`android/` und `ios/` werden gepflegt. `linux/`, `macos/` und `windows/` sind von Flutter erzeugt und **ungetestet** — sie existieren, weil das Werkzeug sie anlegt, nicht weil Desktop ein Ziel wäre.

---

## 3. `services/passkey-rp/` — der WebAuthn-Dienst

Der erste und bislang einzige eigene Serverdienst. Er existiert, weil **Appwrite keine WebAuthn-API hat**.

```
services/passkey-rp/
├── src/
│   ├── server.ts        node:http, kein Framework
│   ├── routes.ts        6 Routen
│   ├── handler.ts       die Logik
│   ├── store.ts         Zugriff auf die beiden Tabellen
│   ├── config.ts        rpId, erlaubte Herkünfte — beim Start hart geprüft
│   └── appwrite.ts      JWT-Prüfung, Token-Erzeugung
├── test/                25 Tests gegen eine Ablage im Speicher
├── package.json         zwei Laufzeit-Abhängigkeiten
├── package-lock.json    committet, `npm ci --ignore-scripts`
└── .env.example         Vorlage — die echte .env bleibt lokal
```

**Was er tut:** Er prüft einen Passkey und übersetzt eine bestandene Prüfung in ein `{userId, secret}`-Paar. Genau dasselbe Paar liefern auch Anmeldelink und Anbieter-Anmeldung — die App tauscht es über denselben Weg gegen eine Appwrite-Sitzung.

**Warum kein Framework:** Bei sechs Routen spart `node:http` vierzig Zeilen und keine Angriffsfläche.

> Der Ordner ist auf der Platte rund **73 MB groß** — das ist `node_modules/`, nicht der Dienst. Der eigentliche Code sind sechs Dateien.

---

## 4. `notes/` — die Dokumentation

Vier Dinge mit klar verschiedenen Aufgaben. Wer sie verwechselt, liest das Falsche:

| Datei | Beantwortet | Kann veralten? |
|---|---|---|
| [`projekt-referenz.md`](projekt-referenz.md) | Was **soll** Karriko sein? Regeln, Grenzwerte, Rollen | kaum — beschreibt Anforderungen |
| [`reports/status-report-2026-08-02.md`](reports/status-report-2026-08-02.md) | Was **ist** gebaut? | ständig |
| [`reports/sicherheitsbericht-2026-08-04.md`](reports/sicherheitsbericht-2026-08-04.md) | Wie kommt Fremdcode herein? | mittel |
| [`todo.md`](todo.md) | Was steht **an**? | ständig |
| `karriko_design_swiss/` | Design-Entwurf als HTML/CSS | nein — Referenz |
| `projektstruktur.md` | *diese Datei* — wo liegt was? | bei Umbauten |

**Der Dateiname des Statusberichts trägt das Datum der Erstfassung**, nicht des letzten Stands. Er ist inzwischen bei Abschnitt 12 und dem 30. August; umbenannt wird er nicht, weil README, Projektreferenz und Todo-Liste darauf verweisen.

**Zur Pflege:** Erledigtes wird in der Todo-Liste abgehakt, nicht gelöscht. Grund steht dort — ein Sicherheitsbefund vom Juni stand zwei Monate offen, weil ihn niemand weiterführte.

---

## 5. `old_tsx/` — der abgelöste Prototyp

Karriko begann als Next.js-Anwendung mit Supabase, tRPC und Prisma. Davon ist **nichts mehr gültig**. Der Code liegt als Nachschlagewerk hier und wird nicht gepflegt.

| | |
|---|---|
| Verfolgte Dateien | 70, davon 38 `page.tsx` |
| Wird gebaut | **nein** |
| Wird ausgeliefert | **nein** |

**Zwei Dinge, die man dazu wissen muss:**

- **Alle Dependabot-Warnungen des Repositories stammen von hier** — derzeit 22, sämtlich zu Next.js. Solange nichts davon gebaut wird, ist die reale Gefahr gering. Der Schaden ist ein anderer: Wer zwei Dutzend dauerhaft rote Meldungen ignoriert, übersieht die nächste, die echt ist.
- **CodeQL scannt ausschließlich diesen Ordner.** Es analysiert JavaScript und TypeScript, kann aber kein Dart — die eigentliche Anwendung ist für die Sicherheitsanalyse unsichtbar.

Den Ordner aus `main` zu entfernen steht auf der Todo-Liste. Die Historie behielte den Code.

---

## 6. Wo gehört was hin?

Die häufigsten Fälle:

| Ich will … | … dann hierhin |
|---|---|
| eine neue Seite bauen | `presentation/<bereich>/`, dazu eine Route in `app/router.dart` |
| eine Seite ins Menü hängen | `presentation/common/app_bar_widget.dart` |
| ein neues Datenfeld lesen | Model in `data/models/`, dann Repository |
| eine neue Appwrite-Tabelle ansprechen | ID in `core/constants/appwrite_constants.dart`, dann Repository |
| eine Farbe oder einen Abstand ändern | `core/theme/app_theme.dart` — **nie** in einer einzelnen Seite |
| eine neue Umgebungsvariable | `core/constants/appwrite_constants.dart` als `fromEnvironment` |
| einen Fehlertext von Appwrite übersetzen | `data/repositories/auth_error_mapper.dart` |
| einen wiederverwendbaren Baustein | `presentation/common/app_page.dart` |
| etwas am Passkey-Ablauf | `services/passkey-rp/src/` **und** `data/services/passkey_*` |

---

## 7. Konventionen

- **Sprache:** Oberflächentexte, Kommentare und Commit-Nachrichten auf Deutsch; Dateinamen und Bezeichner überwiegend englisch. Neuerer Code verwendet auch deutsche Bezeichner (`geraetename`, `_befuellen`) — beides kommt vor.
- **Dateinamen:** `snake_case.dart`, Bildschirme enden auf `_screen.dart`, Tests auf `_test.dart`.
- **Umlaute in Kommentaren** werden oft umschrieben (`Rueckleitung`), weil ein Bulk-Edit über PowerShell einmal 12 Dateien doppelt kodiert hat. Seitdem gilt: **keine Bulk-Edits über `Get-Content`/`Set-Content`.**
- **Freie Funktionen für prüfbare Regeln.** Was ohne Appwrite entscheidbar ist, steht als Top-Level-Funktion statt als private Methode — `companySlug()`, `oauth2TokenUrl()`, `mapAppwriteError()`. Der Grund ist immer derselbe: Als private Methode lässt sich eine Regel nicht testen.

---

## 8. Was das Repository *nicht* enthält

Damit niemand danach sucht:

- **Keine Appwrite-Zugangsdaten.** Projekt-ID und Endpunkt stehen im Code — die ID ist per Design öffentlich. Alles Geheime lebt ausschließlich in der Appwrite Console.
- **Keine Datenbank-Schemadefinition.** Tabellen, Felder, Indizes und Berechtigungen werden in der Console gepflegt und sind aus dem Repository weder ablesbar noch prüfbar. Das ist die größte blinde Stelle des Projekts: Dort liegt die tragende Zugriffsgrenze.
- **Keine Ausbildungsbörse.** Keine Jobs-Tabelle, keine Bewerbungen, kein Datei-Upload. Die Stellenanzeigen in der Oberfläche werden aus Firmendaten abgeleitet — eine Behelfslösung, über die noch zu entscheiden ist.
- **Keine `.gitattributes`.** Deshalb erscheinen fünf generierte Plattform-Dateien nach jedem `flutter test` als geändert, ohne Inhaltsunterschied. Kosmetisch, aber verwirrend.
