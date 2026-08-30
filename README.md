<div align="center">

# Karriko

**Die Bewertungsplattform für die duale Ausbildung im DACH-Markt.**

Azubis bewerten ihren Ausbildungsbetrieb. Betriebe sehen, was wirklich über sie gesagt wird.

[![Flutter CI](https://github.com/dresogo/Karriko/actions/workflows/flutter.yml/badge.svg)](https://github.com/dresogo/Karriko/actions/workflows/flutter.yml)
[![Passkey-Dienst](https://github.com/dresogo/Karriko/actions/workflows/passkey-rp.yml/badge.svg)](https://github.com/dresogo/Karriko/actions/workflows/passkey-rp.yml)
[![CodeQL](https://github.com/dresogo/Karriko/actions/workflows/codeql.yml/badge.svg)](https://github.com/dresogo/Karriko/actions/workflows/codeql.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)
![Appwrite](https://img.shields.io/badge/Appwrite-25.4-FD366E?logo=appwrite&logoColor=white)
![Plattformen](https://img.shields.io/badge/Web%20·%20iOS%20·%20Android-lightgrey)

</div>

---

## ⚠️ Projektstand

**Karriko ist in aktiver Entwicklung und nicht produktionsreif.** Oberfläche, Navigation und Anmeldung stehen weitgehend; die Datenschicht dahinter nicht. Konkret nicht funktionsfähig:

- **Bei der Betriebsregistrierung entsteht kein `companies`-Dokument.** Das ist die Wurzel mehrerer Folgefehler: Das Unternehmensprofil hat keine ID, gegen die es speichern könnte, und das Betriebs-Dashboard keine Datengrundlage.
- Abgesendete Bewertungen landen auf einer Platzhalter-Firma statt am echten Betrieb
- „Konto löschen" ist ein Stub — Art. 17 DSGVO ist damit nicht erfüllt
- Das Kontaktformular verschickt nichts
- Analytics, Team und Abonnement sind statische Attrappen

**Zur Anmeldung:** Alle vier zusätzlichen Verfahren sind eingebaut, aber **keines ist je gegen eine echte Appwrite-Instanz gelaufen** — sämtliche Tests arbeiten gegen Fakes. Was zum Ausprobieren fehlt, ist überwiegend Konfiguration in der Appwrite Console, nicht Code. Siehe [Schnellstart](#schnellstart).

Drei Dokumente beschreiben den Stand, und sie haben unterschiedliche Aufgaben:

| Datei | Beantwortet |
|---|---|
| [`notes/projekt-referenz.md`](notes/projekt-referenz.md) | Was **soll** Karriko sein? Fachliche Regeln, Grenzwerte, Rollen |
| [`notes/reports/`](notes/reports/) | Was **ist** gebaut? Statusbericht und Sicherheitsbericht |
| [`notes/todo.md`](notes/todo.md) | Was steht **an**? Priorisiert, nach Art der Arbeit sortiert |

Wer hier einsteigt, fängt am besten mit der Todo-Liste an und liest bei Bedarf im Statusbericht nach.

---

## Was die App kann

| Bereich | Umfang | Stand |
|---|---|---|
| **Öffentlich** | Startseite, Suche, Unternehmensprofile, Bewertungsdetails, Blog, FAQ, Rechtstexte | Oberfläche fertig, Inhalte teils statisch |
| **Anmeldung** | E-Mail/Passwort, Passkeys, Magic Links, Social Login, Zwei-Faktor über TOTP | eingebaut, gegen die echte Instanz ungetestet |
| **Azubi-Bereich** | Dashboard, Profil, eigene Bewertungen, Lesezeichen, Benachrichtigungen, Einstellungen | Oberfläche fertig, Datenanbindung lückenhaft |
| **Betriebs-Bereich** | Dashboard, Unternehmensprofil, Bewertungen, Meldungen, Team, Analytics, Abonnement | 3 von 8 Seiten angebunden |

**45 Routen** über GoRouter, mit rollenbasierten Weiterleitungen (Azubi ↔ Betrieb) und einem Wächter, dessen Reihenfolge festliegt: **Laden → zweiter Faktor → E-Mail-Bestätigung → Rolle.** Wer sie umstellt, baut sich eine Weiterleitungsschleife, weil die späteren Tore eine vollständige Sitzung voraussetzen, die die früheren erst herstellen.

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
| **Backend** | Appwrite Cloud (Region Frankfurt), SDK 25.4 — Auth, `TablesDB`, Realtime |
| **Passkey-Dienst** | Node 22, TypeScript, `node:http`, zwei Laufzeit-Abhängigkeiten |
| **Design** | Swiss Design: strenges Raster, keine abgerundeten Ecken, Rot als einziger Akzent |

> **Zu `pubspec.yaml`:** Dort stehen derzeit noch sieben Pakete, die **nirgends verwendet** werden — `dio`, `reactive_forms`, `flutter_svg`, `flutter_animate`, `cached_network_image`, `riverpod_annotation`, `cupertino_icons`, dazu `build_runner` und `riverpod_generator` als Dev-Abhängigkeiten. Formulare laufen über `Validators` und `TextFormField`, HTTP über Appwrites eigenen Weg. Ihre Entfernung schrumpft die Lieferkette von 150 auf 85 Pakete und ist als offener Punkt notiert. Wer sie entfernt: **`flutter clean` nicht vergessen**, sonst kompiliert der inkrementelle Compiler gegen einen Paketstand, den es nicht mehr gibt.

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

**Bekannter Mangel:** Der Akzent kommt gegen Weiß auf 4,47:1 und verfehlt damit WCAG AA (4,5:1) für Text unter 18,66 px — betroffen sind alle Kicker und jede rote Schaltfläche. `#B91F1A` liegt bei 6,5:1 und wäre der naheliegende Ersatz; die Umstellung gehört ins Theme, nicht in einzelne Seiten.

</details>

---

## Schnellstart

**Voraussetzungen:** Flutter 3.44 oder neuer, ein Appwrite-Projekt. Für Passkeys zusätzlich Node 20 oder neuer.

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

### Was in der Appwrite Console fehlt

Die Verfahren sind gebaut, aber ohne diese Handgriffe nicht ausprobierbar:

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
├── app/            Router und Wächterlogik
├── core/
│   ├── constants/  Appwrite-IDs, Dart-Defines, App-Konstanten
│   ├── theme/      Farben, Typografie, Abstände
│   └── utils/      Validatoren
├── data/
│   ├── models/     UserModel, CompanyModel, ReviewModel …
│   ├── repositories/  Appwrite-Zugriff pro Domäne, auth_error_mapper
│   └── services/   Appwrite-Client, Passkey-Client, OAuth-Weiterleitung
├── presentation/
│   ├── auth/       Login, Registrierung, MFA, Magic Link, OAuth-Callback
│   ├── azubi/      Bereich für Auszubildende
│   ├── betrieb/    Bereich für Betriebe
│   ├── common/     Baukasten: AppPage, AppCard, StatTile …
│   ├── public/     Öffentliche Seiten, Rechtstexte
│   └── settings/   MFA-Einrichtung, Passkey-Verwaltung
└── providers/      Riverpod-Provider je Domäne

services/passkey-rp/
├── src/            server, routes, handler, store, appwrite, config
└── test/           25 Tests gegen eine Ablage im Speicher
```

84 Dart-Dateien. Die Schichtung ist durchgehend `presentation → providers → repositories → Appwrite`; einzige Ausnahme ist der Benachrichtigungs-Screen, der direkt auf Appwrite zugreift.

Plattformabhängiger Code folgt dem Muster `datei.dart` / `datei_web.dart` / `datei_stub.dart` — betrifft die OAuth-Weiterleitung und den Passkey-Client. Die Brücke zur WebAuthn-API des Browsers liegt als eigene Datei unter [`web/passkey.js`](karriko_flutter/web/passkey.js), nicht inline: Eine spätere Content-Security-Policy mit `script-src 'self'` erlaubt Inline-Skripte nicht.

---

## Qualität

```bash
cd karriko_flutter
dart format --output=none --set-exit-if-changed lib test   # Formatierung
flutter analyze                                            # Analyzer: 0 Hinweise
flutter test                                               # 185 Tests
```

```bash
cd services/passkey-rp
npm run typecheck
npm test                                                   # 25 Tests
npm run audit
```

Beide Suiten laufen bei jedem Push und Pull Request gegen `main` — als [Flutter CI](.github/workflows/flutter.yml) und [Passkey-Dienst](.github/workflows/passkey-rp.yml). Zusätzlich scannt [CodeQL](.github/workflows/codeql.yml) alles, was JavaScript oder TypeScript ist.

**Testabdeckung:** 185 Flutter-Tests über 14 Dateien, dazu 25 im Passkey-Dienst. Schwerpunkt ist weiterhin Layout über fünf bis sieben Viewportbreiten sowie die Wächterlogik des Routers — seit dem Auth-Ausbau kommen Tests hinzu, die **eine Anforderung statt eines Layouts** prüfen: etwa maschinell, dass falsches Passwort und unbekannte Adresse dieselbe Meldung liefern.

Ein Testtyp lohnt besondere Erwähnung, weil er eine ganze Fehlerklasse abdeckt und nur zwei Zeilen pro Datei kostet: **Rendern unter vergrößerter Systemschrift** (`textScaleFactorTestValue = 1.3`). Er hat auf Anhieb drei Überläufe gefunden, die bei Standardgröße unsichtbar bleiben. Bislang nutzen ihn nur zwei Testdateien.

**Nicht abgedeckt:** Repositories, Bewertungs-Assistent, Lesezeichen, Suche, Unternehmensdetail, die fünf restlichen Betriebsseiten. Und grundsätzlich: **Kein Test sieht eine echte Appwrite-Antwort.**

---

## Repository-Aufbau

| Pfad | Inhalt |
|---|---|
| `karriko_flutter/` | die eigentliche Anwendung |
| `services/passkey-rp/` | WebAuthn-Dienst für Passkeys — der erste eigene Serverdienst |
| `notes/` | Projektreferenz, Berichte, Todo-Liste, Design-Entwurf |
| `old_tsx/` | abgelöster Next.js-Prototyp, nur noch Referenz |

Karriko begann als Next.js-Anwendung und wurde auf Flutter portiert. `old_tsx/` bleibt vorerst als Nachschlagewerk liegen und wird nicht mehr gepflegt.

**Die Dependabot-Warnungen auf `main` stammen sämtlich aus diesem Altbestand** — derzeit 22, alle zu Next.js. Solange `old_tsx/` nicht gebaut oder ausgeliefert wird, ist die reale Gefahr gering; der Schaden ist ein anderer. Wer zwei Dutzend dauerhaft rote Meldungen ignoriert, übersieht die nächste, die echt ist. `old_tsx/` aus `main` zu entfernen steht deshalb auf der Liste — die Historie behält den Code ohnehin.

---

## Mitarbeit

Vor einem Pull Request sollten Format, Analyzer und Tests lokal grün sein — die CI prüft genau das.

Wo sich Arbeit am ehesten lohnt, steht in [`notes/todo.md`](notes/todo.md). Zwei Hinweise dazu:

- **Das `companies`-Dokument bei der Betriebsregistrierung ist das Schlüsselstück.** Es löst das Profil-Speichern, ermöglicht echte Dashboard-Kennzahlen und die Bewertungszuordnung — drei Punkte, die einzeln angefasst jeweils an derselben fehlenden Verknüpfung scheitern.
- **Erledigtes wird abgehakt, nicht gelöscht.** Ein Befund aus dem Juni stand zwei Monate offen, weil ihn niemand weiterführte. Genau deshalb gibt es die Liste.

## Lizenz

Für dieses Repository ist bislang keine Lizenz hinterlegt. Ohne Lizenzangabe gilt das volle Urheberrecht: Nutzung, Vervielfältigung und Verbreitung sind nicht gestattet.
