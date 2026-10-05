<div align="center">

# Karriko

**Die Bewertungsplattform für die duale Ausbildung im DACH-Markt.**

Azubis bewerten ihren Ausbildungsbetrieb. Betriebe sehen, was wirklich über sie gesagt wird.

[![Flutter CI](https://github.com/dresogo/Karriko/actions/workflows/flutter.yml/badge.svg)](https://github.com/dresogo/Karriko/actions/workflows/flutter.yml)
[![Dart CI](https://github.com/dresogo/Karriko/actions/workflows/dart.yml/badge.svg)](https://github.com/dresogo/Karriko/actions/workflows/dart.yml)
[![Passkey-Dienst](https://github.com/dresogo/Karriko/actions/workflows/passkey-rp.yml/badge.svg)](https://github.com/dresogo/Karriko/actions/workflows/passkey-rp.yml)
[![CodeQL](https://github.com/dresogo/Karriko/actions/workflows/codeql.yml/badge.svg)](https://github.com/dresogo/Karriko/actions/workflows/codeql.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)
![Appwrite](https://img.shields.io/badge/Appwrite-25.4-FD366E?logo=appwrite&logoColor=white)
![Plattformen](https://img.shields.io/badge/Web%20·%20iOS%20·%20Android-lightgrey)

</div>

---

## ⚠️ Projektstand

**Karriko ist in aktiver Entwicklung und nicht produktionsreif.** Seit August trägt die Datenschicht deutlich mehr: Betriebe bekommen bei der Registrierung ein echtes Unternehmen, Bewertungen entstehen über einen strukturierten Fragebogen und laufen serverseitig durch Moderation und Auswertung, und das Schema ist in Appwrite eingespielt. Was weiterhin fehlt:

- **„Konto löschen" ist ein Stub** — Art. 17 DSGVO ist damit nicht erfüllt. Dasselbe gilt für das Löschen einer einzelnen Bewertung.
- **Das Kontaktformular verschickt nichts.**
- **Analytics, Team und Abonnement im Betriebsbereich sind statische Attrappen**, das Betriebs-Dashboard hängt noch nicht an `company_scores`.
- **Der Abnahmetest gegen die echte Instanz steht aus.** Die Bewertungsstrecke ist eingespielt und einzeln angestoßen, aber nicht mit allen vier Personas von Ende zu Ende durchgespielt.
- **Rechtstexte und acht Punkte der Bewertungsstrecke sind juristisch ungeprüft**, im Fragebogen stehen noch fünf Platzhaltertexte. Vor den ersten echten Bewertungen ist das blockierend.

**Zur Anmeldung:** Alle vier zusätzlichen Verfahren sind eingebaut, aber **keines ist je gegen die echte Appwrite-Instanz gelaufen**. Was fehlt, ist überwiegend Konfiguration in der Appwrite Console, nicht Code. Siehe [Schnellstart](#schnellstart).

Die Dokumentation hat feste Aufgaben:

| Datei | Beantwortet |
|---|---|
| [`notes/projekt-referenz.md`](notes/projekt-referenz.md) | Was **soll** Karriko sein? Fachliche Regeln, Grenzwerte, Rollen |
| [`notes/reports/`](notes/reports/) | Was **ist** gebaut? Statusbericht und Sicherheitsbericht |
| [`notes/todo.md`](notes/todo.md) | Was steht **an**? Priorisiert, nach Art der Arbeit sortiert |
| [`notes/APPWRITE_SETUP.md`](notes/APPWRITE_SETUP.md) | Wie ist das Backend aufgebaut? Tabellen, Rechte, Functions, Fristen |
| [`notes/APPWRITE_EINSPIELEN.md`](notes/APPWRITE_EINSPIELEN.md) | In welcher Reihenfolge wird es eingespielt und abgenommen? |
| [`notes/projektstruktur.md`](notes/projektstruktur.md) | Wo liegt was im Repository? |

Wer hier einsteigt, fängt am besten mit der Todo-Liste an und liest bei Bedarf im Statusbericht nach.

---

## Was die App kann

| Bereich | Umfang | Stand |
|---|---|---|
| **Öffentlich** | Startseite, Suche, Unternehmensprofile, Stellenseiten, Bewertungsdetails, Blog mit Artikelseiten, FAQ, Rechtstexte | Oberfläche fertig; Blog und Rechtstexte mit statischen Inhalten |
| **Bewerten** | Fragebogen mit Phasen, Bedingungen und Entwurfsspeicherung; Auswertung, Moderation und Aggregation auf dem Server | eingespielt, Abnahmetest offen |
| **Anmeldung** | E-Mail/Passwort, Passkeys, Magic Links, Social Login, Zwei-Faktor über TOTP | eingebaut, gegen die echte Instanz ungetestet |
| **Azubi-Bereich** | Dashboard, Profil, eigene Bewertungen, Lesezeichen, Benachrichtigungen, Einstellungen | eigene Bewertungen angebunden, Rest lückenhaft |
| **Betriebs-Bereich** | Dashboard, Unternehmensprofil, Ausbildungsstellen, Bewertungen, Meldungen, Team, Analytics, Abonnement | Profil und Stellen angebunden, Analytics/Team/Abo Attrappen |
| **Admin-Bereich** | Übersicht, Moderations-Warteschlange, Meldungen, Protokoll, Betriebe, System | unter `/#/admin`, prüft die Teams `admins` und `moderators` |

**48 Routen** über GoRouter, mit rollenbasierten Weiterleitungen (Azubi ↔ Betrieb) und einem Wächter, dessen Reihenfolge festliegt: **Laden → zweiter Faktor → E-Mail-Bestätigung → Rolle.** Wer sie umstellt, baut sich eine Weiterleitungsschleife, weil die späteren Tore eine vollständige Sitzung voraussetzen, die die früheren erst herstellen. Der Admin-Bereich steht bewusst außerhalb der Rollenregeln: Er meldet selbst an und prüft selbst die Teams; vorher muss nur der zweite Faktor erledigt sein.

### Die Bewertungsstrecke

Eine Bewertung entsteht an genau einer Stelle: in der Function `submit_review`. Sie nimmt Nutzer und Betrieb aus dem geprüften JWT, nicht aus der Anfrage. Danach trennt sich der Weg:

```
Fragebogen (Client) ──► submit_review ──► reviews            Rohantworten, nie öffentlich
                                            │
                              moderate_review (Freigabe)
                                            ▼
                                       public_reviews       ohne user_id
                                            │
                                    aggregate_company
                                            ▼
                                       company_scores       erst ab 3 Bewertungen ein Wert
```

Client und Server rechnen mit **demselben Paket** [`questionnaire_core`](packages/questionnaire_core/). Dass beide zum selben Ergebnis kommen, ist deshalb keine Absprache zwischen zwei Umsetzungen. Die Fragendefinition liegt in der App und unter `appwrite/questionnaires/` und muss Zeichen für Zeichen übereinstimmen; die CI prüft das.

| Function | Auslöser | Wofür |
|---|---|---|
| `submit_review` | Aufruf | die einzige Stelle, an der eine Bewertung entsteht |
| `my_reviews` | Aufruf | der einzige Weg zu den eigenen abgeschickten Bewertungen |
| `moderate_review` | Aufruf (`moderators`, `admins`) | freigeben oder ablehnen |
| `moderation_desk` | Aufruf (`moderators`, `admins`) | Daten für den Admin-Bereich, ohne `user_id`, Gerätehash und Rohantworten |
| `aggregate_company` | Änderung an `public_reviews` | rechnet `company_scores` neu |
| `publish_scheduled` | stündlich | gibt zurückgestellte Bewertungen in die Moderation |
| `recompute_all` | Aufruf (`admins`) | rechnet alles mit aktuellen Parametern neu |
| `cleanup` | täglich | verwaiste Entwürfe und geprüfte Nachweise |

Mehr dazu in [`appwrite/functions/README.md`](appwrite/functions/README.md).

### Anmeldeverfahren im Detail

| Verfahren | Für wen | Bemerkung |
|---|---|---|
| **E-Mail / Passwort** | beide Rollen | mindestens 8 Zeichen, ein Großbuchstabe, eine Ziffer |
| **Passkeys** (WebAuthn) | beide Rollen | über einen **eigenen** Dienst, siehe unten |
| **MFA / TOTP** | beide Rollen | Wiederherstellungscodes werden vor dem Scharfschalten erzwungen |
| **Magic Links** | nur Azubis | |
| **Social Login** (Google, Apple) | nur Azubis | |

Social Login und Magic Links bleiben Azubis vorbehalten, weil Betriebe eine menschliche Firmenprüfung durchlaufen. Wer sich per Anmeldelink oder Anbieter anmeldet und dabei als Betriebskonto erkannt wird, wird sofort wieder abgemeldet.

**Passkeys laufen über einen eigenen WebAuthn-Dienst** ([`services/passkey-rp/`](services/passkey-rp/)), weil Appwrite keine WebAuthn-API hat. Ein fertiges Auth-SDK eines Drittanbieters kam bewusst nicht in Frage: Genau so eines war zuvor eingebunden und wurde als Lieferketten-Befund wieder entfernt.

---

## Tech-Stack

| | |
|---|---|
| **Framework** | Flutter 3.44 (Web, iOS, Android — Desktop-Targets sind generiert, aber ungetestet) |
| **State** | Riverpod (`flutter_riverpod`) |
| **Routing** | GoRouter mit zentralem Redirect-Wächter |
| **Backend** | Appwrite Cloud (Region Frankfurt), SDK 25.4 — Auth, `TablesDB`, Realtime, Teams, Storage |
| **Serverlogik** | acht Appwrite Functions in Dart (Runtime `dart-3.11`), gemeinsame Pakete unter `packages/` |
| **Passkey-Dienst** | Node 22, TypeScript, `node:http`, zwei Laufzeit-Abhängigkeiten |
| **Design** | Swiss Design: strenges Raster, keine abgerundeten Ecken, Rot als einziger Akzent |

> **Zu `pubspec.yaml`:** Dort stehen weiterhin sieben Pakete, die **nirgends verwendet** werden — `dio`, `reactive_forms`, `flutter_svg`, `flutter_animate`, `cached_network_image`, `riverpod_annotation`, `cupertino_icons`, dazu `build_runner` und `riverpod_generator` als Dev-Abhängigkeiten. Ihre Entfernung schrumpft die Lieferkette von 150 auf 85 Pakete und ist als offener Punkt notiert. Wer sie entfernt: **`flutter clean` nicht vergessen**, sonst kompiliert der inkrementelle Compiler gegen einen Paketstand, den es nicht mehr gibt.

<details>
<summary><strong>Farbpalette</strong></summary>

| Rolle | Wert |
|---|---|
| Ink (Text) | `#111111` |
| Muted | `#5F625F` |
| Paper (Hintergrund) | `#F7F7F2` |
| Surface | `#FFFFFF` |
| Line | `#D8D8D2` |
| Akzent | `#E3342F` |
| Akzent dunkel | `#B91F1A` |
| Grün | `#526B58` |
| Beige | `#F1F0E8` |

**Bekannter Mangel:** Der Akzent kommt gegen Weiß auf 4,47:1 und verfehlt damit WCAG AA (4,5:1) für Text unter 18,66 px — betroffen sind alle Kicker und jede rote Schaltfläche. `#B91F1A` liegt bei 6,5:1 und ist der naheliegende Ersatz; die Umstellung gehört ins Theme, nicht in einzelne Seiten.

</details>

---

## Schnellstart

**Voraussetzungen:** Flutter 3.44 oder neuer, ein Appwrite-Projekt. Für Passkeys und die Werkzeuge unter `tools/` zusätzlich Node 20 oder neuer, für das Einspielen die Appwrite-CLI.

```bash
git clone https://github.com/dresogo/Karriko.git
cd Karriko/karriko_flutter
flutter pub get
flutter run -d chrome
```

Damit läuft die App mit E-Mail/Passwort gegen das konfigurierte Appwrite-Projekt. Alles Weitere ist Konfiguration.

### Appwrite-Konfiguration

Endpoint, Projekt-ID und die Tabellen-IDs stehen in [`lib/core/constants/appwrite_constants.dart`](karriko_flutter/lib/core/constants/appwrite_constants.dart) und müssen zu deinem Appwrite-Projekt passen.

**Alle Rückleitungen** — Bestätigungsmail, Passwort-Reset, Magic Link, OAuth-Callback — leiten sich aus einer einzigen Konstante `appOrigin` ab. Sie fällt auf `http://localhost:8080` zurück:

```bash
flutter run -d chrome --dart-define=APP_ORIGIN=https://deine-domain.example
```

Dieselbe Adresse muss im Appwrite-Projekt **als Web-Plattform hinterlegt** sein — sonst weist Appwrite die Ziel-URLs zurück und es kommt weder Bestätigungsmail noch Reset noch Magic Link an. Für einen Produktions-Build ist das Dart-Define zwingend.

### Alle Dart-Defines

| Define | Standard | Wofür |
|---|---|---|
| `APP_ORIGIN` | `http://localhost:8080` | Basis aller Rückleitungs-URLs |
| `OAUTH_ENABLED` | `false` | Schaltet Google und Apple scharf |
| `PASSKEY_SERVICE_URL` | localhost | Adresse des WebAuthn-Dienstes |

### Schema und Functions einspielen

Tabellen, Indizes und Rechte legt ein idempotentes Skript an. Es ergänzt nur, was fehlt, und fasst bestehende Spalten und Daten nicht an:

```bash
APPWRITE_API_KEY=… node tools/appwrite-setup.mjs --dry-run           # zeigt Abweichungen
APPWRITE_API_KEY=… node tools/appwrite-setup.mjs --fix-permissions   # legt an und setzt Rechte
```

Vor jedem Push einer Function kommen drei Schritte: gemeinsame Pakete kopieren (`dart run tools/vendor_core.dart`), CLI-Konfiguration erzeugen (`node tools/appwrite-config.mjs`) und die Variablen je Function (`node tools/appwrite-function-env.mjs`). Die erzeugten Dateien tragen echte Kennungen und das Salz für den Gerätehash und stehen deshalb in der `.gitignore`. Die vollständige Reihenfolge samt Abnahmetest steht in [`notes/APPWRITE_EINSPIELEN.md`](notes/APPWRITE_EINSPIELEN.md).

> **⚠️ Tabellen nie per `appwrite push table` mit `-f` oder einer gekürzten Konfiguration einspielen.** Die CLI gleicht dann gegen die Datei ab und löscht alles, was dort fehlt. Am 4. Oktober 2026 hat genau das alle Tabellen bis auf eine entfernt; Backups gab es keine. [`tools/appwrite-wiederherstellen.mjs`](tools/appwrite-wiederherstellen.mjs) stellt Schema und bekannte Zeilen auf den Stand vom 2. Oktober wieder her. Für Tabellen ist `tools/appwrite-setup.mjs` der Weg, die CLI bleibt für Teams, Functions und Datei-Uploads.

Für den Admin-Bereich legt `node tools/appwrite-dev-admin.mjs` ein Entwicklungskonto an und trägt es in die Teams `admins` und `moderators` ein. Das Passwort wird zufällig erzeugt und nur einmal im Terminal ausgegeben.

### Was in der Appwrite Console fehlt

Die Anmeldeverfahren sind gebaut, aber ohne diese Handgriffe nicht ausprobierbar:

| Verfahren | Nötig |
|---|---|
| **MFA / TOTP** | Reiter **Auth → Security** einschalten — *nicht* unter *Settings*. Ohne den Schalter antworten sämtliche `mfa*`-Endpunkte nicht. |
| **Magic Links** | SMTP einrichten (EU-Standort, SPF, DKIM, DMARC). Der Schalter „Magic URL" ist bereits an; ohne eigenen Mailversand kommt trotzdem nichts an. |
| **Social Login** | Client-Zugangsdaten für Google und Apple, Redirect-URIs **aus der Console kopieren, nicht abtippen**. Danach mit `--dart-define=OAUTH_ENABLED=true` bauen. |
| **Passkeys** | Tabellen `passkeys` und `webauthn_challenges` anlegen — **beide ohne jede Berechtigung**. Dazu ein API-Schlüssel mit *ausschließlich* `users.read` und `users.write`. |

Bis Google und Apple freigeschaltet sind, sind die beiden Schaltflächen bewusst Platzhalter: Sie melden beim Drücken, dass das Verfahren noch nicht bereitsteht, statt die App zu verlassen und auf einer Appwrite-Fehlerseite zu enden.

### Passkey-Dienst starten

```bash
cd services/passkey-rp
npm ci --ignore-scripts
npm run dev
```

`localhost` genügt zum Testen — im WebAuthn-Standard ist es ausdrücklich ein sicherer Kontext, `rpId=localhost` ist gültig. **Solche Passkeys funktionieren produktiv nicht:** Die `rpId` ist an die Domain gebunden und nachträglich nicht migrierbar. In der Aufbauphase ist das folgenlos, vor dem Start aber zu bedenken.

Felder, Indizes und die nötigen Umgebungsvariablen stehen in [`services/passkey-rp/README.md`](services/passkey-rp/README.md).

---

## Projektstruktur

```
karriko_flutter/lib/
├── app/              Router und Wächterlogik
├── core/
│   ├── constants/    Appwrite-IDs, Dart-Defines, App-Konstanten
│   ├── theme/        Farben, Typografie, Abstände
│   └── utils/        Validatoren, Datumsformat
├── data/
│   ├── models/       UserModel, CompanyModel, JobModel, BlogEntry …
│   ├── repositories/ Appwrite-Zugriff pro Domäne, auth_error_mapper
│   ├── services/     Appwrite-Client, Passkey-Client, OAuth-Weiterleitung
│   └── blog_content.dart  Blogartikel und Produkt-Updates
├── presentation/
│   ├── admin/        Admin-Bereich mit sechs Abschnitten
│   ├── auth/         Login, Registrierung, MFA, Magic Link, OAuth-Callback
│   ├── azubi/        Bereich für Auszubildende
│   ├── betrieb/      Bereich für Betriebe
│   ├── common/       Baukasten: AppPage, AppCard, StatTile …
│   ├── public/       Öffentliche Seiten, Blog, Rechtstexte
│   ├── questionnaire/ Fragebogen mit Widget-Registry je Fragetyp
│   └── settings/     MFA-Einrichtung, Passkey-Verwaltung
└── providers/        Riverpod-Provider je Domäne

packages/
├── questionnaire_core/  Ablauf, Prüfung und Scoring des Fragebogens — Client und Server
└── karriko_functions/   Appwrite-Kleber und die entscheidenden Funktionen ohne Netzzugriff

appwrite/
├── functions/        acht Functions, je ein eigenes Dart-Paket
├── questionnaires/   Fragendefinition für den Server
└── appwrite.config.template.json

services/passkey-rp/  WebAuthn-Dienst (src/, test/)
tools/                Schema-Setup, Wiederherstellung, Dev-Admin, Vendoring, Fragebogen-Abgleich
```

131 Dart-Dateien in der App. Die Schichtung ist durchgehend `presentation → providers → repositories → Appwrite`; einzige Ausnahme ist der Benachrichtigungs-Screen, der direkt auf Appwrite zugreift.

Plattformabhängiger Code folgt dem Muster `datei.dart` / `datei_web.dart` / `datei_stub.dart` — betrifft die OAuth-Weiterleitung und den Passkey-Client. Die Brücke zur WebAuthn-API des Browsers liegt als eigene Datei unter [`web/passkey.js`](karriko_flutter/web/passkey.js), nicht inline: Eine spätere Content-Security-Policy mit `script-src 'self'` erlaubt Inline-Skripte nicht.

---

## Qualität

```bash
cd karriko_flutter
dart format --output=none --set-exit-if-changed lib test   # Formatierung
flutter analyze                                            # Analyzer: 0 Hinweise
flutter test                                               # 233 Tests
```

```bash
cd packages/questionnaire_core && dart test                # 287 Tests
cd packages/karriko_functions  && dart test                # 50 Tests
```

```bash
cd services/passkey-rp
npm run typecheck
npm test                                                   # 25 Tests
npm run audit
```

Alles läuft bei jedem Push und Pull Request gegen `main`: die App als [Flutter CI](.github/workflows/flutter.yml), Pakete, Functions und Werkzeuge als [Dart CI](.github/workflows/dart.yml), der [Passkey-Dienst](.github/workflows/passkey-rp.yml) eigenständig. Dart CI prüft außerdem, dass keine erzeugten Dateien mit echten Kennungen eingecheckt sind, dass beide Kopien der Fragendefinition übereinstimmen und dass das Schema-Skript zur CLI-Vorlage passt. [CodeQL](.github/workflows/codeql.yml) scannt alles, was JavaScript oder TypeScript ist.

**Testabdeckung:** 595 Tests über alle Teile. Die Fragebogenlogik ist am dichtesten abgedeckt, darunter vier Personas gegen die **echte** Fragendefinition. In der App liegt der Schwerpunkt auf Layout über vier bis sieben Viewportbreiten und der Wächterlogik des Routers, dazu Tests, die **eine Anforderung statt eines Layouts** prüfen — etwa maschinell, dass falsches Passwort und unbekannte Adresse dieselbe Meldung liefern.

Ein Testtyp lohnt besondere Erwähnung, weil er eine ganze Fehlerklasse abdeckt und nur zwei Zeilen pro Datei kostet: **Rendern unter vergrößerter Systemschrift** (`textScaleFactorTestValue = 1.3`). Er hat auf Anhieb drei Überläufe gefunden, die bei Standardgröße unsichtbar bleiben. Bislang nutzen ihn nur zwei Testdateien.

**Nicht abgedeckt:** Repositories, Ausbildungsstellen, Lesezeichen, Suche, Unternehmensdetail, die restlichen Betriebsseiten. Und grundsätzlich: **Kein Test sieht eine echte Appwrite-Antwort** — die Functions sind über ihre reinen Funktionen geprüft, das Zusammenspiel mit Appwrite zeigt erst der Abnahmetest.

---

## Repository-Aufbau

| Pfad | Inhalt |
|---|---|
| `karriko_flutter/` | die eigentliche Anwendung |
| `packages/` | gemeinsame Dart-Pakete für App und Functions |
| `appwrite/` | Functions, Fragendefinition, CLI-Vorlage |
| `services/passkey-rp/` | WebAuthn-Dienst für Passkeys |
| `tools/` | Skripte für Schema, Wiederherstellung, Dev-Admin, Vendoring und Fragebogen |
| `notes/` | Projektreferenz, Berichte, Todo-Liste, Backend-Anleitungen, Design-Entwurf |
| `old_tsx/` | abgelöster Next.js-Prototyp, nur noch Referenz |

Karriko begann als Next.js-Anwendung und wurde auf Flutter portiert. `old_tsx/` bleibt vorerst als Nachschlagewerk liegen und wird nicht mehr gepflegt.

**Die Dependabot-Warnungen auf `main` stammen sämtlich aus diesem Altbestand** — derzeit rund 30, alle zu Next.js. Solange `old_tsx/` nicht gebaut oder ausgeliefert wird, ist die reale Gefahr gering; der Schaden ist ein anderer. Wer dauerhaft rote Meldungen ignoriert, übersieht die nächste, die echt ist. `old_tsx/` aus `main` zu entfernen steht deshalb auf der Liste — die Historie behält den Code ohnehin.

---

## Mitarbeit

Vor einem Pull Request sollten Format, Analyzer und Tests lokal grün sein — die CI prüft genau das. Wer an Functions oder Paketen arbeitet, lässt zusätzlich `dart run tools/vendor_core.dart --pruefen` laufen.

Wo sich Arbeit am ehesten lohnt, steht in [`notes/todo.md`](notes/todo.md). Zwei Hinweise dazu:

- **Der Abnahmetest mit den vier Personas ist der nächste Schlüsselschritt.** Er zeigt als Erstes, ob die eingespielte Bewertungsstrecke im Zusammenspiel trägt — und hängt nur noch an einem eigenen Moderationskonto.
- **Erledigtes wird abgehakt, nicht gelöscht.** Ein Befund aus dem Juni stand zwei Monate offen, weil ihn niemand weiterführte. Genau deshalb gibt es die Liste.

## Lizenz

Für dieses Repository ist bislang keine Lizenz hinterlegt. Ohne Lizenzangabe gilt das volle Urheberrecht: Nutzung, Vervielfältigung und Verbreitung sind nicht gestattet.
