<div align="center">

# Karriko

**Die Bewertungsplattform für die duale Ausbildung im DACH-Markt.**

Azubis bewerten ihren Ausbildungsbetrieb. Betriebe sehen, was wirklich über sie gesagt wird.

[![Flutter CI](https://github.com/dresogo/Karriko/actions/workflows/flutter.yml/badge.svg)](https://github.com/dresogo/Karriko/actions/workflows/flutter.yml)
[![CodeQL](https://github.com/dresogo/Karriko/actions/workflows/codeql.yml/badge.svg)](https://github.com/dresogo/Karriko/actions/workflows/codeql.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)
![Plattformen](https://img.shields.io/badge/Web%20·%20iOS%20·%20Android-lightgrey)

</div>

---

## ⚠️ Projektstand

**Karriko ist in aktiver Entwicklung und nicht produktionsreif.** Oberfläche und Navigation stehen weitgehend, die Datenschicht ist es nicht. Konkret nicht funktionsfähig:

- Abgesendete Bewertungen landen auf einer Platzhalter-Firma statt am echten Betrieb
- „Konto löschen" ist ein Stub — Art. 17 DSGVO ist damit nicht erfüllt
- Das Kontaktformular verschickt nichts
- Analytics, Team und Abonnement sind statische Attrappen

Der vollständige, ehrliche Stand steht in [`notes/status-report-2026-08-02.md`](notes/status-report-2026-08-02.md) — inklusive offener Sicherheitsbefunde und Layout-Fehler. Wer hier einsteigt, sollte damit anfangen.

---

## Was die App kann

| Bereich | Umfang | Stand |
|---|---|---|
| **Öffentlich** | Startseite, Suche, Unternehmensprofile, Bewertungsdetails, Blog, FAQ, Rechtstexte | Oberfläche fertig, Inhalte teils statisch |
| **Auth** | Registrierung und Login getrennt für Azubis und Betriebe, E-Mail-Bestätigung, Passwort-Reset | funktionsfähig |
| **Azubi-Bereich** | Dashboard, Profil, eigene Bewertungen, Lesezeichen, Benachrichtigungen, Einstellungen | Oberfläche fertig, Datenanbindung lückenhaft |
| **Betriebs-Bereich** | Dashboard, Unternehmensprofil, Bewertungen, Meldungen, Team, Analytics, Abonnement | 3 von 8 Seiten angebunden |

**37 Routen** über GoRouter, mit rollenbasierten Weiterleitungen (Azubi ↔ Betrieb) und einem Wächter für unbestätigte E-Mail-Adressen.

---

## Tech-Stack

| | |
|---|---|
| **Framework** | Flutter (Web, iOS, Android — Desktop-Targets sind generiert, aber ungetestet) |
| **State** | Riverpod (`flutter_riverpod`, `riverpod_annotation`) |
| **Routing** | GoRouter mit zentralem Redirect-Wächter |
| **Backend** | Appwrite Cloud — Auth, Datenbank, Realtime |
| **Formulare** | `reactive_forms` |
| **Design** | Swiss Design: strenges Raster, keine abgerundeten Ecken, Rot als einziger Akzent |

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

</details>

---

## Schnellstart

**Voraussetzungen:** Flutter 3.44 oder neuer, ein Appwrite-Projekt.

```bash
git clone https://github.com/dresogo/Karriko.git
cd Karriko/karriko_flutter
flutter pub get
flutter run -d chrome
```

### Appwrite-Konfiguration

Endpoint, Projekt-ID und die Collection-IDs stehen in [`lib/core/constants/appwrite_constants.dart`](karriko_flutter/lib/core/constants/appwrite_constants.dart) und müssen zu deinem Appwrite-Projekt passen.

Die Ziel-URL für Bestätigungs- und Passwort-Reset-Mails kommt aus einem Dart-Define. **Ohne sie zeigen alle Links auf `http://localhost`:**

```bash
flutter run -d chrome --dart-define=APPWRITE_VERIFICATION_URL=https://deine-domain.example
```

Die gleiche URL muss im Appwrite-Projekt als Plattform hinterlegt sein — sonst schlägt `createVerification` fehl und es kommt keine Bestätigungsmail an.

---

## Projektstruktur

```
karriko_flutter/lib/
├── app/            Router und Wächterlogik
├── core/
│   ├── constants/  Appwrite-IDs, App-Konstanten
│   ├── theme/      Farben, Typografie, Abstände
│   └── utils/      Validatoren
├── data/
│   ├── models/     UserModel, CompanyModel, ReviewModel …
│   ├── repositories/  Appwrite-Zugriff pro Domäne
│   └── services/   Appwrite-Client
├── presentation/
│   ├── auth/       Login, Registrierung, Passwort
│   ├── azubi/      Bereich für Auszubildende
│   ├── betrieb/    Bereich für Betriebe
│   ├── common/     Baukasten: AppPage, AppCard, StatTile …
│   └── public/     Öffentliche Seiten
└── providers/      Riverpod-Provider je Domäne
```

67 Dart-Dateien. Die Schichtung ist durchgehend `presentation → providers → repositories → Appwrite`; einzige Ausnahme ist der Benachrichtigungs-Screen, der direkt auf Appwrite zugreift.

---

## Qualität

```bash
cd karriko_flutter
dart format --output=none --set-exit-if-changed lib test   # Formatierung
flutter analyze                                            # Analyzer
flutter test                                               # 111 Tests
```

Alle drei laufen bei jedem Push und Pull Request gegen `main` als [Flutter CI](.github/workflows/flutter.yml). Zusätzlich scannt CodeQL den Legacy-TypeScript-Bestand.

**Testabdeckung:** 111 Tests über sechs Dateien, Schwerpunkt auf Layout über fünf bis sieben Viewportbreiten sowie der Wächterlogik des Routers. Nicht abgedeckt: Repositories, Bewertungs-Assistent, Lesezeichen, Suche.

---

## Repository-Aufbau

| Pfad | Inhalt |
|---|---|
| `karriko_flutter/` | die eigentliche Anwendung |
| `notes/` | Statusberichte, Implementierungspläne, Design-Entwürfe |
| `old_tsx/` | abgelöster Next.js-Prototyp, nur noch Referenz |

Karriko begann als Next.js-Anwendung und wurde auf Flutter portiert. `old_tsx/` bleibt vorerst als Nachschlagewerk liegen und wird nicht mehr gepflegt — die Dependabot-Warnungen auf `main` stammen aus diesem Altbestand.

---

## Mitarbeit

Vor einem Pull Request sollten Format, Analyzer und Tests lokal grün sein — die CI prüft genau das. Wo sich Arbeit am ehesten lohnt, steht am Ende des [Statusberichts](notes/status-report-2026-08-02.md) als priorisierte Reihenfolge.

## Lizenz

Für dieses Repository ist bislang keine Lizenz hinterlegt. Ohne Lizenzangabe gilt das volle Urheberrecht: Nutzung, Vervielfältigung und Verbreitung sind nicht gestattet.
