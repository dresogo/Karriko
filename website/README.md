# Karriko – Website (Jaspr)

Grundgerüst der öffentlichen Website nach E-1.17 (vorher Prototyp für T-8.3): ein Betriebsprofil mit
Testdaten, serverseitig gerendert in [Jaspr](https://jaspr.site) 0.23.5. Die
Flutter-App läuft getrennt unter `/app`.

## Starten

```bash
dart pub global activate jaspr_cli 0.23.5
dart pub global run jaspr_cli:jaspr serve      # Entwicklung
dart pub global run jaspr_cli:jaspr build      # Produktion nach build/jaspr/
```

Der gebaute Server liest `PORT` (Standard 8080) und sucht die Fragebogendefinition
`appwrite/questionnaires/questionnaire_v1.json` vom Arbeitsverzeichnis aufwärts.

Seiten: `/` (Liste), `/betrieb/testbetrieb-metallbau` (4 Bewertungen, mit Score),
`/betrieb/testbetrieb-kanzlei` (2 Bewertungen, unter der Grenze), jede andere
`/betrieb/…` liefert 404.

## Prüfbedingungen (Tab „Website-Umbau SEO“), gemessen am 28.10.2026

| Bedingung | Ergebnis |
|---|---|
| CSP ohne Ausnahmen | Header `default-src 'self'; script-src 'self'; style-src 'self'; …` ohne `unsafe-inline` oder fremde Quellen. Keine Verstöße in der Konsole. Balken als SVG mit Breitenattribut statt `style=`. |
| Lesbares HTML ohne JavaScript | 5,8 KB HTML, kein `<script>`, kein `<style>`, kein `style=`. Name, Score, Teilwerte und Freitexte stehen im HTML. |
| LCP unter 2,5 s | Lokal, ohne Drosselung: LCP 1,3 s beim ersten Aufruf (Element `h1`, Schrift 200 KB als TTF), warm TTFB 9 ms, DOM fertig nach 22 ms. CLS 0. Eine Messung mit gedrosseltem Mobilnetz auf dem echten Server steht aus. |
| Regeln aus `packages/` ohne Kopie | `questionnaire_core` als Pfadabhängigkeit: `CompanyAggregate.compute` mit Schrumpfung (E-23), Sichtbarkeitsgrenze 3 (E-22), Vergütung per Flag aus (E-25). |

Außerdem: Inter lokal (E-06), kein Google Fonts; bei 375 px kein horizontaler
Überlauf; `noindex`, solange es ein Prototyp ist.

## Bewusst offen

- Daten aus Appwrite statt Testdaten (T-12.3), Schlüssel nur mit Lesezugriff (T-12.1).
- Schrift als WOFF2 mit Latin-Subset statt 200-KB-TTF, fette Schnitte (W-1.5, F-6).
- JSON-LD, Seiten-Cache, Sitemap (T-12.3, T-12.6).
- Hosting und Pfad-Routing `/` und `/app/` (T-9.10, T-9.14).
