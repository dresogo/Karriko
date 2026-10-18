# Karriko – Factsheet

**Zweck:** Eine Seite, die jede KI und jeder Mensch liest, bevor am Projekt etwas entschieden wird. Sie hält fest, *was gilt* und *warum*. Neue Entscheidungen werden hier eingetragen, alte nicht gelöscht, sondern als abgelöst markiert.

**Stand:** 15. Oktober 2026, abgeglichen mit `main` @ `7076495` und den PRs #11–#17; Abschnitte 7, 8, 9 und 10 an die neue Ordnung in `notes/` angepasst · **Verantwortlich:** Sebastian Demharter

**Rangfolge bei Widersprüchen:** Code (`app_theme.dart`, Fragendefinition, Functions) → dieses Factsheet → `notes/projekt-referenz.md` → ältere Notizen und Chats. Steht etwas im Factsheet, das der Code anders macht, ist das ein Befund für Abschnitt 9, keine stille Korrektur.

---

## 1. Produkt in drei Sätzen

Karriko ist eine Bewertungsplattform für die duale Ausbildung im DACH-Raum. Azubis bewerten ihren Ausbildungsbetrieb über einen strukturierten Fragebogen, Betriebe bekommen ein Profil und sehen, was über sie gesagt wird. Ziel ist Transparenz vor der Entscheidung, auf beiden Seiten.

| | |
|---|---|
| Früherer Name | AusbildungsCheck |
| Zielmarkt | Deutschland, Österreich, Schweiz; Sprache Deutsch, i18n-fähig |
| Domain | **karriko.de** (Ziel). `karriko.dresogo.de` ist nur Übergang – Code, URLs und Konfiguration immer auf karriko.de ausrichten |
| Repository | github.com/dresogo/Karriko |
| Geschäftsmodell | Für Azubis kostenlos. Einnahmen über Premium für Betriebe und Stellenanzeigen |
| Rechtsform | UG geplant |

**Rollen:** Besucher (lesen) · Azubi (bewerten, merken, melden; E-Mail bestätigt) · Betrieb (eigenes Profil, Stellen; menschlich verifiziert) · Admin/Moderator (Teams `admins`, `moderators`).

---

## 2. Corporate Design

**Stil:** Swiss Design. Strenges Raster, viel Weißraum, linksbündig, keine Dekoration, keine Verläufe. Rot ist der einzige Akzent.

### 2.1 Farben (verbindlich, aus `lib/core/theme/app_theme.dart`)

| Token | Hex | Verwendung |
|---|---|---|
| `ink` | `#111111` | Text, Linien mit Gewicht, Outline-Buttons |
| `muted` | `#5F625F` | Fließtext zweiter Ebene, Metadaten |
| `paper` | `#F7F7F2` | Seitenhintergrund |
| `surface` | `#FFFFFF` | Karten, Eingabefelder |
| `line` | `#D8D8D2` | Haarlinien, Rahmen, Trenner |
| `accent` | `#E3342F` | Primäre Buttons, Links, Kicker, aktive Zustände |
| `accentDark` | `#B91F1A` | Hover/gedrückt; Ersatz für `accent` bei kleinem Text (Kontrast) |
| `green` | `#526B58` | Sekundärfarbe, sparsam |
| `audienceBeige` | `#F1F0E8` | Flächen für Zielgruppen-Bänder |

**Abgelöst:** Die Palette aus der `design.md` vom Mai 2026 (Blau-Grau `#2E4156`, Rot `#D61727`, Grau `#CDCDCD`) gilt nicht mehr. Wer sie in alten Dateien oder Entwürfen findet, ersetzt sie.

### 2.2 Schrift

- **Inter** (v4.1), einzige Schriftfamilie. Fallback im Web: `Inter, Arial, Helvetica, sans-serif`.
- **Lokal eingebettet** (`assets/fonts/inter/`), nie über Google Fonts zur Laufzeit. Grund: LG München I, 3 O 17493/20 – dynamisches Laden überträgt die IP an Google. Gilt auch für Website, Landingpages und Mails.
- **Eingebettet ist bewusst nur Inter Regular** (PR #13). So sah die Web-App tatsächlich schon immer aus: Google lieferte Inter als variable Schrift, deren Stärke Flutter nicht einstellt. Fette Schnitte (~1,6 MB für vier) kommen erst mit einer eigenen Entscheidung.
- Größen laut Theme: Display 64/48/36 px, Zeilenhöhe ≈ 1; Fließtext 17/15 px, Zeilenhöhe 1,55; Labels 12 px, Sperrung 0,11 em. Die Gewichte 700/800 im Theme sind vorbereitet und wirken erst mit echten Schnitten.

### 2.3 Form und Raster

- **Ecken:** Karten, Container, Eingabefelder, Chips, Dialoge eckig (`radius 0`). Buttons `AppRadius.button = 10`.
- **Schatten:** keine. Karten tragen eine 1-px-Linie in `line`.
- **Abstände:** nur die Skala 8 · 16 · 24 · 32 · 48 · 64.
- **Inhaltsbreite:** max. 1200 px, zentriert. Randabstand 24 / 48 / 64 px (unter 600 / ab 600 / ab 1024 px).
- **Breakpoints:** 375 / 768 / 1024 / 1440 px, Mobile First.
- **Bewegung:** keine Material-Welle, im Browser keine Seitenübergänge. Hover nur per Farbwechsel.
- **Fokus in Eingabefeldern:** Rahmen wird `ink`, 2 px.

### 2.4 Logo

Noch nicht final. In der engeren Wahl: **„Treppe"** (K aus aufsteigenden Stufen, Varianten 1b/1c in den GitHub-Farben) und **17b**. Regel aus der Logo-Runde: Farben immer aus `app_theme.dart`, nie aus Annahmen.

### 2.5 Ton

Sachlich, vertrauenswürdig, präzise. Du-Ansprache gegenüber Azubis. Keine erfundenen Zahlen, Zitate oder Kontaktdaten – lieber ein sichtbarer Platzhalter.

---

## 3. Technik

| Ebene | Wahl |
|---|---|
| App | Flutter 3.44 (Web, iOS, Android), Dart 3.11 |
| State | Riverpod |
| Routing | GoRouter, ein zentraler Wächter |
| Backend | Appwrite Cloud, **Region Frankfurt**, SDK 25.4 |
| Serverlogik | Acht Appwrite Functions in Dart, gemeinsame Pakete in `packages/` |
| Passkeys | Eigener WebAuthn-Dienst `services/passkey-rp` (Node 22, TypeScript, zwei Laufzeit-Abhängigkeiten) |
| Hosting | Eigenes Webhosting bei Hetzner |
| Öffentliche Seiten (geplant) | Serverseitiges HTML (Next.js), Flutter-App unter `/app` |

**Schichtung:** `presentation → providers → repositories → Appwrite`. Neuer Code hält sich daran.

---

## 4. Entscheidungsprotokoll

Format: Nummer · Datum · Entscheidung · Grund. Neue Einträge unten anhängen. Wird eine Entscheidung ersetzt, bekommt sie den Vermerk **„abgelöst durch E-xx"** und bleibt stehen.

### Architektur und Stack

| Nr | Datum | Entscheidung | Grund |
|---|---|---|---|
| E-01 | 06/2026 | **Wechsel von Next.js/Supabase/Prisma/tRPC/Vercel zu Flutter + Appwrite.** Alter Code `old_tsx/` seit 13.10.2026 aus `main` entfernt. | Eine Codebasis für Web und Mobile. Mit dem Altcode verschwanden ~30 Dependabot-Warnungen. Alle stack-spezifischen Vorgaben aus alten Dokumenten (SDLC, tRPC, Zod, RLS-Policies) sind ungültig; die fachlichen Regeln gelten weiter. |
| E-02 | 06/2026 | Appwrite in **Frankfurt**. | Keine Drittlandsübermittlung, AVV einfacher. Bei jedem neuen Dienst EU-Datenhaltung prüfen, nicht annehmen. |
| E-03 | 08/2026 | **Passkeys über eigenen Dienst**, kein fertiges Auth-SDK eines Drittanbieters. | Appwrite hat keine WebAuthn-API. Ein Dritt-SDK war schon eingebunden und wurde als Lieferketten-Befund entfernt. |
| E-04 | 09/2026 | **Client und Server rechnen mit demselben Paket** `questionnaire_core`. Fragendefinition liegt in App und `appwrite/questionnaires/` und muss zeichengleich sein (CI prüft). | Kein Auseinanderlaufen zweier Umsetzungen. |
| E-05 | 10/2026 | **Tabellen nur über `tools/appwrite-setup.mjs`**, nie `appwrite push table` mit `-f` oder gekürzter Konfiguration. | Am 4.10.2026 hat ein Push alle Tabellen bis auf eine gelöscht, ohne Backup. CLI bleibt für Teams, Functions, Uploads. |
| E-06 | 10/2026 | **Keine Laufzeit-Ressourcen von Dritt-CDNs**: Schrift lokal, Web-Build immer mit `--no-web-resources-cdn` über `tools/build_web.dart`. | DSGVO (IP-Übertragung) und spätere CSP mit `script-src 'self'`. Deshalb auch JS-Brücken als eigene Datei, nie inline. |
| E-07 | 10/2026 | **Lieferkette klein halten**: ungenutzte Pakete entfernt, Actions festgenagelt, Lockfile erzwungen, Dependabot, CodeQL, OSV-Scanner. | Jede Abhängigkeit ist ein Risiko. Neue Pakete nur mit Begründung. |
| E-08 | 10/2026 | **SEO: öffentliche Seiten als serverseitiges HTML** (Next.js), getrennt von der Flutter-App, die unter `/app` läuft. Routing per Pfad (nginx/Caddy). | Flutter Web rendert auf Canvas, Suchmaschinen sehen keinen Inhalt. Vorbild: kununu. |
| E-09 | 10/2026 | **Zieldomain karriko.de**. Vor dem Umzug beachten: Passkey-`rpId` ist an die Domain gebunden und nicht migrierbar; `APP_ORIGIN` und Appwrite-Web-Plattform müssen karriko.de kennen. | Übergangsdomain soll keine Altlasten erzeugen. |
| E-10 | 10/2026 | Im Browser **kein Ripple, keine Seitenübergänge, Text markierbar, Hand-Cursor** (PR #11). Umsetzung: globale `SelectionArea` im `builder` der App; Navigation, Karten, Buttons und Fragebogen per `SelectionContainer.disabled` ausgenommen. Klickziele immer über `TapTarget` (`presentation/common/tap_target.dart`), nicht über `GestureDetector`. Native Apps behalten ihre Übergänge. | Die App soll sich wie eine Website anfühlen; `TapTarget` bringt Cursor, Hover, Fokus, Tastaturbedienung und Button-Semantik mit. |
| E-11 | 10/2026 | **Major-Updates von Abhängigkeiten nie über einen Dependabot-Sammel-PR**, sondern als eigene Migration mit Tests. Anstehend: `flutter_riverpod` 2→3, `go_router` 14→18, `cached_network_image` 3→4, `flutter_lints` 4→6 (PR #16 deshalb geschlossen). | Brechende Änderungen brauchen eigene Prüfung. |
| E-12 | 10/2026 | **Passkey-Dienst läuft ohne Build-Schritt** über Nodes Type-Stripping. `tsconfig` mit `erasableSyntaxOnly`: keine Parameter-Properties, Enums o. ä. (PR #17). | `npm start` brach an nicht entfernbarer TS-Syntax ab; die Tests (vitest) merkten es nicht. |
| E-13 | 10/2026 | **Squash-Merge**, wenn Zwischenstände eines PRs Ballast enthalten (z. B. große Binärdateien). | Was nie nach `main` kommt, muss nicht aus der Historie entfernt werden. |
| E-1.14 | 10/2026 | **Eine Aufgabenliste in zwei Dateien:** `notes/aufgaben-offen.md` und `notes/aufgaben-erledigt.md`. Erledigtes wandert mit Datum, Nummer und Commit in die zweite Datei, im selben Commit. Abgeschlossene Berichte und Pläne kommen mit `git mv` nach `notes/archiv/`, mit Grund und Nachfolger in `archiv/README.md`. Die Tabs im Artefakt „Karriko: Plan“ spiegeln die Dateien nur. | Vorher lagen offene Punkte in `todo.md`, im Tab und in mehreren Berichten und liefen auseinander (T-1.13, T-1.14). |

### Bewertungen und Daten

| Nr | Datum | Entscheidung | Grund |
|---|---|---|---|
| E-20 | 09/2026 | **Eine Bewertung entsteht nur in der Function `submit_review`.** Nutzer und Betrieb kommen aus dem geprüften JWT, nie aus der Anfrage. | Manipulationsschutz. |
| E-21 | 09/2026 | **Zwei Tabellen:** `reviews` (Rohantworten, Nutzerkennung, Gerätehash; für keinen Client lesbar) und `public_reviews` (ohne `user_id`). | Anonymität serverseitig, nicht durch Ausblenden im Client. |
| E-22 | 09/2026 | **Sichtbarkeit:** Score erst ab **3** Bewertungen, Zahlenangaben (z. B. Vergütung, nur in Bändern) erst ab **5**. Darunter steht der Score auch in der Sortierkopie auf `null`. | Re-Identifikation in kleinen Betrieben verhindern. |
| E-23 | 09/2026 | **Scoring:** sechs Dimensionen (fachlich, betreuung, umgang, belastung, verguetung, perspektive), Gewichte aus den Prioritäten der Azubis, Schrumpfung gegen `priorMean 3.2` (Stärke 5), Alterung: nach 3 Jahren Gewicht 0,5. Berufsschule separat. | Faire Werte auch bei wenigen Bewertungen. **Löst** die alte Regel „5 Kategorien × 5 Fragen, anonym = Gewicht 0,5" aus `projekt-referenz.md` §2 **ab**. |
| E-24 | 09/2026 | **Jeder nicht leere Freitext geht durch die Moderation.** Kein automatischer Text-Filter. | Ein schlechter Filter täuscht Sicherheit vor. |
| E-25 | 09/2026 | **Vergütungsmodul per Feature-Flag aus** (`module_verguetung`). | Rechtlich und fachlich noch offen; Scoring normiert ohne die Dimension neu. |
| E-26 | 09/2026 | **Verzögerte Veröffentlichung**: auf Wunsch 3 Tage; in Kleinbetrieben „erst nach Ausbildungsende" (ohne Enddatum 6 Monate). | Schutz vor Rückschluss auf die Person. |
| E-27 | 09/2026 | **Alte Bewertungsstrecke ersetzt**, Altzeilen gelöscht (vorher JSON-Export). `PublicReviewCard` ersetzt `ReviewCard`. | Keine Sonderlogik für Altdaten. |
| E-28 | 08/2026 | **Ausbildungsbörse kommt.** Betriebe schreiben Stellen selbst aus, eigene Stellenseite. Umfang (Bewerbungen, Upload, Stellensuche) noch offen. | Behelfslösung aus Firmendaten versprach etwas, das es nicht gab. |
| E-29 | 08/2026 | **Bewertungen und ihre Reihenfolge sind nicht käuflich**, auch nicht über Premium. Premium darf bessere Selbstdarstellung bieten, nie Ranking-Vorteile; keine Konkurrenzwerbung auf Profilen nicht zahlender Betriebe. | Glaubwürdigkeit; BGH-Rechtsprechung zu Jameda (2018, 2021). |
| E-30 | 10/2026 | **Attrappen ausblenden statt zeigen**: Analytics, Team, Abo im Betriebsbereich sind ausgeblendet, Routen führen aufs Dashboard. | Nichts versprechen, was nicht funktioniert. |
| E-2.12 | 18.10.2026 | **`public_reviews.published_at` ist nur der Quartalsbeginn** (UTC, z. B. `2026-10-01T00:00Z`), die Karte zeigt „Q4 2026“. Die Alterung rechnet weiter mit dem Einreichen in `reviews`. | Die Tabelle ist für jeden lesbar; ein genauer Zeitpunkt erlaubt in kleinen Betrieben den Rückschluss auf die Person, und die Vorschau sagt zu, dass der Monat nicht sichtbar wird (T-5.21). |

### Anmeldung und Sicherheit

| Nr | Datum | Entscheidung | Grund |
|---|---|---|---|
| E-40 | 08/2026 | **Magic Link und Social Login nur für Azubis.** Wird ein Betriebskonto erkannt, sofort abmelden. | Betriebe durchlaufen eine menschliche Firmenprüfung. |
| E-41 | 08/2026 | **Router-Wächter-Reihenfolge fest:** Laden → zweiter Faktor → E-Mail-Bestätigung → Rolle. Admin-Bereich außerhalb der Rollenregeln, prüft selbst die Teams. | Andere Reihenfolge erzeugt Weiterleitungsschleifen. |
| E-42 | – | **Keine Konto-Erkundung:** falsches Passwort und unbekannte E-Mail geben dieselbe Meldung, „Passwort vergessen" antwortet immer gleich. Bekannte Ausnahme: Registrierung (erst mit serverseitiger Registrierung lösbar). | Schutz der Nutzer. |
| E-43 | – | Passwort: min. 8 Zeichen, ein Großbuchstabe, eine Ziffer. Unbestätigte Konten dürfen lesen, nicht bewerten. | – |
| E-44 | – | **Jede Berechtigung serverseitig.** Client-Weiterleitungen sind Bequemlichkeit, keine Sicherheit. Ein Betrieb sieht nie Daten eines anderen. | – |
| E-45 | 10/2026 | **`companies` mit Row Security**: Tabellenrechte nur `read("any")`, `create("users")`; Änderungsrecht pro Zeile für den Eigentümer. | Vorher durfte jeder Angemeldete jede Firma ändern. |
| E-46 | 10/2026 | **Von Betrieben eingegebene URLs werden nicht verlinkt** (Website, Bewerbungs-URL, Kontakt-Mail), bis eine Prüfung auf `http`/`https` existiert. | Sonst wird eine `javascript:`-URL zum Einfallstor (PR #11). |
| E-47 | 10/2026 | **Die Fehlerseite zeigt nur den Pfad, nie die Query.** | Die alte Fassung gab mögliche Einmal-Codes aus Mail-Links aus (PR #13). |
| E-48 | 08/2026 | **Zugangsdaten nie ins Repo.** Fund im öffentlichen Repo → sofort rotieren, `git filter-repo --replace-text`, Force-Push, danach GitHub-Support um Purge unerreichbarer Objekte bitten. API-Schlüssel nach Gebrauch widerrufen, nicht ablaufen lassen. | Fall `notes/fehler.md`: 26 Tage öffentlich lesbar; alte Commits bleiben per SHA abrufbar. |

### Datenschutz und Löschkonzept

| Nr | Datum | Entscheidung | Grund |
|---|---|---|---|
| E-50 | 10/2026 | **Kontolöschung:** Nutzerbezug wird aus erhaltenen Bewertungen entfernt. Einheitliche **14-Tage-Widerrufsfrist** für jede Kontolöschung. | Art. 17 DSGVO, Schutz vor versehentlichem Löschen. |
| E-51 | 10/2026 | Öffentliche Bewertungen ohne Höchstspeicherdauer. **Entwürfe 30 Tage, Verifikationsnachweise 14 Tage.** | Löschkonzept nach DIN 66398. Siehe Abschnitt 9: Code-Standard weicht noch ab. |
| E-52 | 10/2026 | **Inaktive Konten** nach 3 Jahren löschen, vorher drei Warnungen (30 / 14 / 3 Tage). | Datensparsamkeit. |
| E-53 | – | Kein Tracking ohne Einwilligung, AVV mit jedem Dienstleister, keine personenbezogenen Daten in Logs. | DSGVO. |

---

## 5. Grenzwerte

| Regel | Wert |
|---|---|
| Bewertungen je Nutzer und Betrieb | 1 |
| Bewertungen je Konto und 24 h | 3 |
| Meldungen je Betrieb und 24 h | 5 |
| Login-Versuche je IP und Minute | 5 |
| Freitext | max. 1000 Zeichen |
| Reset-Token | einmalig, 60 Minuten |

---

## 6. Qualitätsziele

WCAG 2.1 AA · LCP < 2,5 s · CLS < 0,1 · Geschäftslogik-Testabdeckung > 80 % · bei 375 px kein horizontaler Überlauf · Layouts auch mit `textScaleFactor 1.3` testen.

Vor jedem PR: `dart format`, `flutter analyze` (0 Hinweise), alle Tests grün. Bei Functions/Paketen zusätzlich `dart run tools/vendor_core.dart --pruefen`.

---

## 7. Arbeitsregeln für die KI

1. **Vor jeder Entscheidung** zu Design, Architektur, Daten, Rechten oder Abhängigkeiten dieses Factsheet lesen und sich daran halten.
2. **Widerspricht ein Vorschlag einer Entscheidung**, das offen sagen und die Nummer nennen (z. B. „widerspricht E-06"). Nicht still abweichen.
3. **Nach einer neuen Entscheidung** einen Eintrag in Abschnitt 4 vorschlagen: nächste freie Nummer im passenden Block, Datum, Entscheidung, Grund. Bei Ersatz die alte Zeile mit „abgelöst durch E-xx" markieren.
4. **Farben, Schrift, Abstände** nur aus `app_theme.dart` bzw. Abschnitt 2. Keine neuen Farbwerte ohne Eintrag hier.
5. **Rechtliche Aussagen, Kontaktdaten, Zahlen** nie erfinden. Platzhalter `PLATZHALTER — juristisch zu prüfen` verwenden.
6. **Nichts Destruktives** an Appwrite-Daten ohne Probelauf und ausdrückliche Freigabe.
7. Erledigtes aus `notes/aufgaben-offen.md` nehmen und mit Datum, Nummer und Commit in `notes/aufgaben-erledigt.md` eintragen, im selben Commit (E-1.14). Neue Aufgaben nur dort, nicht in Berichte oder eigene Todo-Dateien.

---

## 8. Wo was steht

| Datei | Inhalt |
|---|---|
| `FACTSHEET.md` | Was gilt und warum (diese Datei); Nummernsystem in Abschnitt 10 |
| `notes/projekt-referenz.md` | Fachliche Anforderungen (Teile durch E-23 überholt) |
| `notes/aufgaben-offen.md` | Offene Aufgaben T-x.y, priorisiert |
| `notes/aufgaben-erledigt.md` | Erledigte Aufgaben mit Datum und Commit |
| `notes/APPWRITE_SETUP.md` | Tabellen, Rechte, Functions, Fristen; Einspielen und Abnahmetest |
| `notes/UMSETZUNG_BERICHT.md` | Warum der Fragebogen so gebaut ist; Abweichungen A1–A15 und Entscheidungen vom 21.09. |
| `notes/karriko-fragebogen.md` | Fachliche Spezifikation des Fragebogens |
| `notes/archiv/` | Abgeschlossene Berichte und Pläne, nicht mehr maßgeblich |
| `karriko_flutter/lib/core/theme/app_theme.dart` | Design-Tokens im Code |
| `notes/karriko_design_swiss/` | HTML/CSS-Referenz des Swiss-Designs |

---

## 9. Offene Widersprüche

Bekannte Stellen, an denen Code, Doku und Entscheidungen nicht übereinstimmen. Aufgelöste Punkte werden durchgestrichen, nicht gelöscht, und die Lösung kommt als Entscheidung in Abschnitt 4.

**W-1 · Design**

- **W-1.1 · Button-Ecken:** README sagt „keine abgerundeten Ecken", das Theme setzt 10 px, die alte `design.md` 25 px. Gilt heute: 10 px (Code).
- ~~**W-1.2 · Schatten:** `AppColors.cardShadow` existiert und wird in `bookmarks_screen.dart` benutzt. Widerspricht „keine Schatten".~~ Behoben am 18.10.2026: Merkliste ausgeblendet (E-30), Token entfernt (T-6.7, `803a15e`).
- **W-1.3 · Akzent-Kontrast:** `#E3342F` auf Weiß 4,47:1, verfehlt WCAG AA für kleinen Text. Umstellung auf `#B91F1A` gehört ins Theme (T-6.2).
- **W-1.4 · Fehler-/Warnfarben** (`#EF4444`, `#F59E0B`, `#22C55E`) sind Tailwind-Standards und nicht ins Swiss-Design eingepasst.
- **W-1.5 · Schriftschnitte:** Theme definiert 700/800, eingebettet ist nur Regular (bewusst, siehe Abschnitt 2.2). Offen: fette Schnitte aufnehmen oder Gewichte im Theme bereinigen.
- **W-1.6 · Design-Referenz** `notes/karriko_design_swiss/styles.css` nutzt im Header `backdrop-filter: blur`, das Theme nicht.
- **W-1.7 · Social-Media-Vorlagen** (10/2026) wurden mit Archivo und `#D42A1B` gebaut. Für Karriko gelten Inter und `#E3342F`.

**W-2 · Technik und Doku**

- **W-2.1 · Noto-Fallback:** Für Zeichen außerhalb von Inter (z. B. Emojis) lädt Flutter weiter von `fonts.gstatic.com`. Widerspricht E-06, relevant für die CSP (T-5.26).
- ~~**W-2.2 · README veraltet bei Paketen:** nennt `dio` und `cached_network_image` als ungenutzt und „150 → 85 Pakete". Laut PR #12 sind beide in Gebrauch, Stand 107 Pakete (T-6.20).~~ Behoben am 15.10.2026: README nennt 110 Pakete laut Lockfile (T-6.20).
- ~~**W-2.3 · Testzahlen:** README nennt 233 App-Tests, nach PR #13 sind es 250 (T-6.20).~~ Behoben am 15.10.2026: README auf 661 App-Tests und 1033 insgesamt gezählt (T-6.20).

**W-3 · Daten und Recht**

- **W-3.1 · Löschfristen:** Code-Standard Entwürfe 90 Tage / Nachweise 30 Tage, Löschkonzept 30 / 14 Tage (E-51). Werte in `.env` der Functions anpassen; beides noch juristisch zu prüfen.

**Offene Produktentscheidungen** (Details in `notes/aufgaben-offen.md` Abschnitt 8): Umfang der Börse · Antwortrecht für Betriebe · Löschverlangen für einzelne Bewertungen · finales Logo · Preisstufen Premium · fette Inter-Schnitte ja/nein.

**Nächster Schlüsselschritt laut `notes/aufgaben-offen.md`:** `submit_review` deployen (T-2.31), eigenes Moderationskonto anlegen (T-2.3), dann Abnahmetest mit den vier Personas (T-2.4).

---

## 10. Nummernsystem

Jede Liste im Projekt hat einen eigenen Buchstaben. Ein Buchstabe steht nur für eine Art von Liste.

**Aufbau:** `<Buchstabe>-<Abschnitt>.<laufende Nummer>`, zum Beispiel `T-2.3`. Abschnitte zählen fortlaufend: erster Abschnitt 1, zweiter 2 und so weiter. Die laufende Nummer beginnt in jedem Abschnitt bei 1 und hat keine Obergrenze.

**Regeln:**

1. Eine vergebene Nummer bleibt für immer und wird nie umnummeriert oder neu besetzt. Erledigtes wird nicht gelöscht: Aufgaben wandern nach `notes/aufgaben-erledigt.md` (E-1.14), Einträge anderer Listen werden durchgestrichen.
2. Neues bekommt die nächste freie Nummer seines Abschnitts, auch wenn es inhaltlich weiter oben stünde.
3. Ein neuer Abschnitt bekommt die nächste freie Abschnittsnummer, auch wenn er inhaltlich zwischen zwei bestehenden steht.
4. Verweise immer mit voller Nummer und Buchstabe, auch über Dokumente hinweg („siehe T-6.17", „widerspricht E-06").

| Buchstabe | Liste | Wo | Stand |
|---|---|---|---|
| **E** | Entscheidungen | Abschnitt 4 | Altbestand E-01 bis E-53 behält seine Nummern; neue Einträge im Format `E-<Abschnitt>.<Nr.>` |
| **T** | Aufgaben (To-do) | `notes/aufgaben-offen.md`, Erledigtes in `notes/aufgaben-erledigt.md`; der Tab „Offene Aufgaben“ spiegelt nur | eingeführt, T-1 bis T-10 |
| **W** | Widersprüche zwischen Code, Doku und Entscheidungen | Abschnitt 9 | eingeführt |
| **R** | Risiken | Tab „Website-Umbau SEO", `projekt-referenz.md` §7 | reserviert |
| **J** | Fragen an den Anwalt (juristisch) | Tab „Fragen an den Anwalt" | reserviert |
| **V** | Verarbeitungstätigkeiten nach Art. 30 DSGVO | Tab „Verarbeitungsverzeichnis" | reserviert |
| **L** | Löschfristen | Tab „Löschkonzept" | reserviert |
| **N** | Schritte im Notfall | Tab „Notfallplan" | reserviert |
| **Z** | Wiederkehrende Routinen | Tab „Routinen" | reserviert |
| **B** | Fehler (Bugs) | Tab „Fehlerreport Website" | reserviert |

**Nicht vergeben, weil schon belegt:** **A** (Abweichungen A1–A15 in `notes/UMSETZUNG_BERICHT.md` §11, Abschluss-Fragen a1–a5), **K** (Kernfragen k1–k12), **S** (Steuerfragen s1–s10, Sicherheitsbefunde S1–S10), **P** (Priorität P1–P3). Diese Kürzel sind älter und stehen im Code oder in der Fragendefinition.
