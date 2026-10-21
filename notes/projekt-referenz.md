# Karriko – Projektreferenz

**Stand:** 21. Oktober 2026 (an die Entscheidungen im Factsheet angeglichen, T-1.9)
**Zweck:** Das fachliche Nachschlagewerk des Projekts. Was Karriko sein soll, welche Regeln gelten, welche Grenzwerte einzuhalten sind.

Diese Datei fasst vierzehn ältere Notizen zusammen, die zwischen März und Juni 2026 entstanden sind. Alles Überholte ist entfernt, alles fachlich Gültige übernommen.

**Wichtige Abgrenzung:** Dieses Dokument beschreibt **Anforderungen**, nicht den Umsetzungsstand. Was tatsächlich gebaut ist, steht in `notes/aufgaben-erledigt.md`, was offen ist, in `notes/aufgaben-offen.md`; die früheren Berichte liegen in `notes/archiv/`.

**Zum Factsheet:** Bei Widersprüchen gilt `FACTSHEET.md`. Die Abschnitte zu Börse, Bewertungsaufbau, Gewichtung, Anonymität, Löschen und Export sind auf dessen Stand gebracht; wo eine Regel aus einer Entscheidung stammt, steht die Nummer dabei.

**Zum Technologie-Wechsel:** Die Ursprungsdokumente beschrieben durchgehend einen Next.js-/Supabase-Stack mit tRPC, Prisma und Vercel. Davon ist nichts mehr gültig — die Anwendung ist eine **Flutter-App mit Appwrite als Backend**. Alle stack-spezifischen Vorgaben wurden beim Zusammenführen entfernt; die fachlichen Regeln dahinter gelten unverändert weiter, weil sie nichts mit der Technik zu tun haben.

---

## 1. Produkt

### 1.1 Vision

Karriko ermöglicht Auszubildenden im DACH-Raum, ihre Ausbildungsbetriebe transparent und strukturiert zu bewerten. Ausbildungsbetriebe erhalten ein professionelles Profil, auf dem sie sich darstellen und auf Bewertungen antworten können. Ziel ist Transparenz auf dem Ausbildungsmarkt — beide Seiten sollen sich vor einer Entscheidung ein realistisches Bild machen können.

| Rahmenbedingung | Detail |
|---|---|
| Zielmarkt | DACH (Deutschland, Österreich, Schweiz) |
| Sprache | Deutsch, i18n-fähig angelegt |
| Recht | DSGVO, BDSG, österreichisches DSG, schweizerisches DSG |
| Geräte | Desktop, Tablet, Smartphone — Mobile-First |

### 1.2 Rollen und Rechte

| Rolle | Darf | Voraussetzung |
|---|---|---|
| **Besucher** | Startseite, Suche, Betriebsprofile und Bewertungen lesen | kein Account |
| **Auszubildender** | zusätzlich: bewerten, merken, melden | Account + E-Mail bestätigt |
| **Ausbildungsbetrieb** | zusätzlich: eigenes Profil verwalten, auf Bewertungen antworten | Account + Verifizierung als Betrieb |
| **Admin** | Moderation, Benutzerverwaltung | interner Account |

Ein Betrieb darf **niemals** Daten eines anderen Betriebs sehen. Jeder Zugriff auf Bewerberdaten, Auswertungen und Nutzerdaten ist serverseitig an die eigene `company_id` zu binden — eine Prüfung im Client genügt nicht.

### 1.3 Was das Produkt ausdrücklich *nicht* ist

**Kein Ort für gekaufte Platzierungen.** Bewertungen und ihre Reihenfolge sind nicht käuflich, auch nicht über Premium (E-29).

**Die Ausbildungsbörse ist entschieden (E-28):** Betriebe schreiben Ausbildungsstellen selbst aus; sie stehen auf dem Betriebsprofil, auf einer eigenen Stellenseite und in der Suche. Geschrieben wird nur über die Function `job_posting`, öffentlich wird eine Stelle erst, wenn der Betrieb verifiziert ist (T-4.31). Offen ist der Umfang: Online-Bewerbung, Datei-Upload und Statusverfolgung (T-8.5).

---

## 2. Das Bewertungssystem

Der fachliche Kern der Plattform. Diese Regeln sind unabhängig von der Technik einzuhalten.

### 2.1 Aufbau einer Bewertung

Ein strukturierter Fragebogen in Phasen (Spezifikation: `notes/karriko-fragebogen.md`), keine freien Sternekategorien. Ausgewertet wird in **sechs Dimensionen** (E-23):

1. fachlich
2. betreuung
3. umgang
4. belastung
5. verguetung (per Feature-Flag aus, E-25; das Scoring normiert dann ohne sie)
6. perspektive

Die Berufsschule wird getrennt ausgewiesen. Freitexte sind optional, höchstens 1000 Zeichen (Factsheet §5; der Fragebogen v1 erlaubt noch mehr, T-5.22).

### 2.2 Gewichtung

Gilt nach E-23 und ersetzt die alte Regel „namentlich 1,0, anonym 0,5“ (T-8.2): Namentliche Bewertungen gibt es nicht, jede Bewertung ist anonym.

- **Gewichte der Dimensionen** aus den Prioritäten, die die Azubis selbst angeben.
- **Schrumpfung** gegen `priorMean 3.2` mit Stärke 5: Wenige Bewertungen ziehen den Wert zur Mitte, statt ihn ausschlagen zu lassen.
- **Alterung:** Nach drei Jahren zählt eine Bewertung halb. Maßgeblich ist der Zeitpunkt des Einreichens.
- **Sichtbarkeit (E-22):** Ein Score erst ab drei Bewertungen, Zahlenangaben nur in Bändern und erst ab fünf.

Gerechnet wird mit demselben Paket `questionnaire_core` in App und Functions (E-04).

### 2.3 Anonymität — technisch

> Jede Bewertung ist anonym. Die Nutzer-ID steht nur in `reviews`, für die Eindeutigkeitskontrolle (eine Bewertung je Nutzer und Betrieb) und die Missbrauchsprüfung; diese Tabelle ist für keinen Client lesbar. Öffentlich ist allein `public_reviews`, ohne Nutzer-ID und mit dem Zeitpunkt nur als Quartal (E-21, E-2.12). Wird ein Konto gelöscht, verliert auch `reviews` den Bezug (E-4.5).

**Die Regel, die daraus folgt:** Die Nutzer-ID wird serverseitig aus jeder Antwort entfernt, bevor sie das Backend verlässt — nicht erst im Client ausgeblendet. Ein ausgeblendetes Feld ist kein Datenschutz.

### 2.4 Grenzwerte

| Regel | Wert |
|---|---|
| Bewertungen pro Nutzer und Betrieb | max. 1 (serverseitig geprüft) |
| Bewertungen pro Account und 24 h | max. 3 |
| Betriebsantworten pro Bewertung | max. 1, **nach Veröffentlichung nicht mehr änderbar** |
| Länge einer Betriebsantwort | max. 1000 Zeichen, reiner Text, keine Links |
| Meldungen pro Betrieb und 24 h | max. 5 |
| Login-Versuche pro IP und Minute | max. 5 |

### 2.5 Löschen von Bewertungen

Wer eine eigene Bewertung löscht, löscht sie wirklich: die Zeile in `reviews`, die öffentliche Zeile, Meldungen dazu und den Nachweis; der Score des Betriebs wird neu berechnet (E-4.6). Kein `deleted_at`. Der frühere Grund für einen Zeitstempel, erhaltene Betriebsantworten, entfällt, solange es keine Antworten gibt (T-8.1); kommen sie, wird das neu entschieden (T-2.23).

---

## 3. Seiten und ihre Regeln

Verdichtet aus den vier Anforderungsdokumenten. Routen in der Schreibweise der Flutter-App.

### 3.1 Öffentlich

| Seite | Kern | Besonderheiten |
|---|---|---|
| Startseite | Hero mit Suche, aktuelle Bewertungen | SEO-Einstieg, strukturierte Daten `WebSite` + `SearchAction` |
| `/search` | Suche mit Filtern nach Branche, Ort, Mindestbewertung | Live-Vorschläge ab 3 Zeichen, 300 ms entprellt |
| Unternehmensseite | Kopfbereich, Kategorie-Scores, Bewertungs-Feed, Profiltext | strukturierte Daten `LocalBusiness` + `AggregateRating` |
| Bewertungsdetail | vollständige Bewertung mit allen 25 Antworten | eigene URL zum Teilen; gibt **nie** die Nutzer-ID zurück |
| `/fuer-betriebe` | B2B-Landingpage: Nutzen, Tarife, Registrierung | statisch |
| `/blog`, `/blog/:slug` | Ratgeberinhalte für organischen Traffic | statisch |
| `/ueber-uns`, `/kontakt`, `/faq` | Vertrauen und Erreichbarkeit | Kontaktformular mit Pflicht-Einwilligung nach Art. 6 Abs. 1 lit. a DSGVO |
| `/impressum`, `/datenschutz`, `/agb` | Pflichtseiten | **vor Go-Live anwaltlich prüfen lassen** |

### 3.2 Anmeldung und Registrierung

Getrennte Registrierungswege für Azubis und Betriebe — die erhobenen Daten unterscheiden sich zu stark für ein gemeinsames Formular.

**Azubi:** persönliche Daten → Ausbildungsinfo (überspringbar) → Einwilligungen (Datenschutz und AGB Pflicht, Newsletter optional).

**Betrieb:** Unternehmensangaben → Ansprechpartner → Zugangsdaten → Einwilligungen. Das Profil entsteht mit `verified: false`; das Verifizierungs-Abzeichen vergibt ein Mensch.

**Sicherheitsregeln, die nicht verhandelbar sind:**

- **Schutz vor Konto-Erkundung.** Falsches Passwort und unbekannte E-Mail erzeugen **dieselbe** Meldung. Auch „Passwort vergessen" antwortet immer gleich: „Falls ein Account existiert, wurde eine E-Mail versendet."
- **Passwörter** landen nie im Frontend-Zustand und nie in einem Log — auch nicht in der Fehlerüberwachung.
- **Reset-Token** sind einmalig verwendbar und laufen nach 60 Minuten ab. Nach erfolgreichem Zurücksetzen werden alle aktiven Sitzungen des Nutzers ungültig.
- **Unbestätigte Konten** dürfen lesen, aber **nicht bewerten**.

Passwortregel: mindestens 8 Zeichen, ein Großbuchstabe, eine Ziffer.

### 3.3 Azubi-Bereich

| Seite | Kern |
|---|---|
| Dashboard | Begrüßung, eigene Bewertungen, Merkliste, Benachrichtigungen |
| Profil | Stammdaten; eine E-Mail-Änderung muss erneut bestätigt werden (T-3.13) |
| Bewertung schreiben | Betrieb suchen → Fragebogen in Phasen → Zusammenfassung; nur mit bestätigter Adresse (E-3.12) |
| Meine Bewertungen | Status und Begründung einer Ablehnung, löschen (E-4.6); Bearbeiten des Freitexts offen (T-6.17) |
| Merkliste | gemerkte Betriebe |
| Benachrichtigungen | Antwort erhalten, Bewertung gemeldet, Bewertung entfernt, System |
| Einstellungen | Konto, Datenschutz, Benachrichtigungen, Konto löschen |

**Konto löschen (Art. 17 DSGVO, E-50, E-4.5):** Beantragt in den Einstellungen; 14 Tage lang lässt sich die Löschung nach der Anmeldung zurücknehmen, mehr zeigt das Konto in dieser Zeit nicht (E-3.11). Danach löscht der tägliche Lauf endgültig:

1. Veröffentlichte Bewertungen bleiben stehen, ohne Nutzer-ID und Gerätehash.
2. Nicht veröffentlichte Bewertungen, Entwürfe, Merkliste, Profil und Nachweise werden gelöscht.
3. Eigene Meldungen bleiben für die Moderation, ohne Nutzer-ID.
4. Das Konto selbst wird gelöscht; es bleibt keine Zeile, die es nennt.

Betriebskonten folgen eigenen Regeln (§3.4, T-2.24).

**Datenexport (Art. 20 DSGVO, E-4.7):** Konto, Profil, eigene Bewertungen mit Antworten und Freitexten, Entwürfe, Merkliste und eigene Meldungen als JSON. Interne Prüfmerkmale gehören nicht dazu; ob eine Auskunft nach Art. 15 mehr umfassen muss, ist juristisch offen (T-5.27).

### 3.4 Betriebs-Bereich

| Seite | Kern |
|---|---|
| Dashboard | Kennzahlen, neueste Bewertungen, Score-Verlauf, Profil-Vollständigkeit |
| Unternehmensprofil | Stammdaten, Logo, Beschreibung, Social Links |
| Bewertungen | filtern nach beantwortet/unbeantwortet/gemeldet, antworten |
| Analytics | Score-Verlauf, Anzahl, Kategorie-Scores, Branchenvergleich (Premium) |
| Team | Ansprechpartner; Kontaktdaten nur sichtbar bei ausdrücklichem Opt-in |
| Abonnement | Basis kostenlos / Premium |
| Meldungen | Bewertung melden: Grund, Beschreibung, optional Belege |
| Einstellungen | Konto, Benachrichtigungen, Datenschutz |

**Bei Uploads** (Logo, Bilder) gilt: MIME-Typ **serverseitig** prüfen, nicht nur die Dateiendung im Client. Größen begrenzen.

**Datenschutz bei Analytics:** aggregierte Werte, keine personenbezogenen Daten. Profilaufrufe werden ohne Nutzer-Identifikation gezählt — ein Betrieb darf nicht sehen, *wer* sein Profil angesehen hat.

**Konto löschen (Betrieb):** Profil auf inaktiv, Bewertungen bleiben erhalten, Betriebsantworten werden gelöscht, 30 Tage reaktivierbar, danach endgültig.

---

## 4. Sicherheit und Datenschutz

### 4.1 Grundsätze

| Risiko | Maßnahme |
|---|---|
| Fehlende Zugriffskontrolle | Serverseitige Berechtigungsprüfung bei **jedem** Zugriff. Client-Weiterleitungen sind Bequemlichkeit, keine Sicherheit. |
| Verschlüsselung | HTTPS erzwungen, Passwort-Hashing durch den Auth-Anbieter |
| Injection | ausschließlich parametrisierte Abfragen |
| Fehlkonfiguration | Sicherheits-Header, CSP, CORS-Whitelist, keine Standard-Zugangsdaten |
| Verwundbare Komponenten | Abhängigkeits-Prüfung in der CI, Dependabot, regelmäßige Updates |
| Auth-Schwächen | Rate Limiting, Sperre nach 5 Fehlversuchen, CSRF-Schutz |
| Integrität | Subresource Integrity für externe Skripte — **oder gar keine externen Skripte** |
| Logging | keine personenbezogenen Daten in Logs, Audit-Log für kritische Aktionen |

### 4.2 DSGVO

- **Rechtsgrundlage:** Einwilligung für Bewertungen, Vertragserfüllung für Kontodaten
- **Datensparsamkeit:** kein Tracking ohne Einwilligung
- **Transparenz:** Datenschutzerklärung und Consent-Banner beim ersten Besuch
- **Betroffenenrechte:** Auskunft (Export), Löschung, Berichtigung
- **Auftragsverarbeitung:** AVV mit jedem eingesetzten Dienstleister
- **Datenhaltung in der EU** — bei jedem Dienst zu prüfen, nicht anzunehmen

### 4.3 Historischer Sicherheitsbefund

Ein **OWASP-ZAP-Scan vom 1. Juni 2026** lief gegen die damalige Next.js-App unter `localhost:3000`. Ergebnis: 0 hohe, 2 mittlere, 2 geringe Befunde. Der vollständige Bericht liegt in der Git-Historie.

Zwei der Befunde sind **nie behoben worden und gelten für die heutige Flutter-Web-App genauso**:

| Befund | Stand 4. August 2026 |
|---|---|
| **Content Security Policy fehlt** | weiterhin offen — T-4.9 |
| **Anti-Clickjacking-Header fehlt** | weiterhin offen — `frame-ancestors 'none'` deckt es mit ab |

Die beiden geringen Befunde (`X-Powered-By`, `X-Content-Type-Options`) betrafen den Express-/Next.js-Server und sind mit dessen Abschaffung gegenstandslos.

**Die Lehre daraus:** Ein Befund von vor zwei Monaten steht immer noch offen, weil er in keiner Liste weitergeführt wurde. Deshalb steht er jetzt im Sicherheitsbericht.

---

## 5. Qualitätsziele

| Ziel | Wert |
|---|---|
| Ladezeit Startseite | LCP < 2,5 s |
| Layoutstabilität | CLS < 0,1 |
| Verfügbarkeit | 99,9 % |
| Barrierefreiheit | **WCAG 2.1 Level AA** |
| Breakpoints | 375 / 768 / 1024 / 1440 px, Mobile-First |
| Testabdeckung Geschäftslogik | > 80 % |

Die Barrierefreiheit ist derzeit an zwei Stellen verfehlt: Die Akzentfarbe erreicht den Kontrastwert nicht, und die Kopfzeile bricht bei vergrößerter Systemschrift. Die Kopfzeile ist am 13.10.2026 behoben; kleiner roter Text nutzt seit 21.10.2026 `accentDark` (T-6.2).

### Kritische Testfälle

Diese Fälle prüfen Regeln, die still brechen können, ohne dass es jemandem auffällt:

| Fall | Erwartung |
|---|---|
| Schrumpfung und Alterung | wenige Bewertungen liegen nahe `priorMean`, alte zählen halb (E-23) |
| fremdes Profil bearbeiten | wird abgelehnt |
| zweite Antwort auf dieselbe Bewertung | wird blockiert |
| **Anonymität** | eine Bewertung gibt **keinerlei** Nutzerdaten preis — auch nicht in der API-Antwort |
| Konto löschen | nach 14 Tagen sind alle personenbezogenen Daten entfernt; veröffentlichte Bewertungen tragen keine Nutzer-ID mehr |
| Startseite bei 375 px | Inhalte stapeln sich, kein horizontaler Überlauf |

---

## 6. Roadmap nach dem Start

Aus der Ursprungsspezifikation, weiterhin plausibel — aber erst relevant, wenn die Grundfunktionen tatsächlich tragen:

| Vorhaben | Nutzen |
|---|---|
| Verifikations-Abzeichen | Nachweis, dass ein Bewertender wirklich Azubi im Betrieb war — das stärkste Mittel gegen gefälschte Bewertungen |
| Branchenvergleich | Einordnung statt nackter Zahl |
| Empfehlungen | passende Betriebe nach Region und Beruf |
| Mobile App | auf Basis derselben API |
| Öffentliche API | Syndikation an Jobbörsen |

---

## 7. Risiken

| Risiko | Wahrscheinlichkeit / Wirkung | Gegenmaßnahme |
|---|---|---|
| Ausufernder Umfang | mittel / hoch | MVP zuerst, striktes Änderungsmanagement |
| DSGVO-Verstoß | niedrig / **kritisch** | Datenschutz-Prüfung vor dem Start, Rechtstexte anwaltlich freigeben |
| Ausfall des Backend-Anbieters | niedrig / hoch | Monitoring, Backups, Notfallplan |
| Missbräuchliche Bewertungen | mittel / mittel | Meldefunktion, Moderation, Rate Limiting |
| Wissen nur in einem Kopf | mittel / mittel | Entscheidungen dokumentieren — auch der Grund, warum es diese Datei gibt |

---

## Anhang: Was aus welchen Dateien stammt

Zusammengeführt am 4. August 2026. Alle Quelldateien sind in der Git-Historie erhalten und über `git log --diff-filter=D --name-only` auffindbar.

| Quelldatei | Verbleib |
|---|---|
| `sdlc_karriko.md`, `sdlc.md` | zwei Fassungen desselben SDLC-Dokuments. Fachliches übernommen (Abschnitte 1, 2, 4–7); Tech-Stack, Sprint-Plan, Team- und Infrastrukturkapitel entfernt — sie beschreiben ein Projekt, das so nicht gebaut wurde. |
| `01_public.md`, `02_auth.md`, `03_azubi.md`, `04_betrieb.md` | Seitenanforderungen übernommen (Abschnitt 3); tRPC-Aufrufe, Zod-Schemata und Supabase-Storage-Pfade entfernt. |
| `2026-06-01-ZAP-Report-.md` | die zwei weiterhin gültigen Befunde übernommen (4.3); der Rest betraf den abgeschafften Server. |
| `todo.md` | verwies auf Supabase, `src/app` und Stripe. Die drei bleibenden Punkte (Rechtstexte, Kontolöschung, Analytics) stehen im Statusbericht. |
| `status-sdlc.md` | Fortschrittsliste der Next.js-Umsetzung. Vollständig gegenstandslos. |
| `IMPLEMENTATION_GUIDE.md` | Verzeichnisbaum von 33 `page.tsx`-Dateien. Gegenstandslos; das Schutzkonzept ist in Abschnitt 1.2 aufgegangen. |
| `implementation_plan.md` | beschrieb den Wechsel von „AzubiCheck" (Node + SQLite) zu Karriko. Zwei Stacks veraltet. |
| `AUFGABENVORSCHLAEGE.md` | vier Aufgaben zu `server.js` — die Datei existiert nicht mehr. |
| `karriko_overhaul_summary.md` | Abschlussbericht der HTML-/Node-Fassung, inklusive **Testkonten mit Klartext-Passwörtern**. Ersatzlos entfernt. |
| `KarrikoStartseite.tsx` | React-Prototyp der Startseite mit Emoji-Icons. Die Startseite ist in Flutter umgesetzt und folgt dem Swiss-Design; Alt-Code liegt ohnehin in `old_tsx/`. |

**Nicht angefasst:** `notes/reports/` (aktuelle Berichte) und `notes/karriko_design_swiss/` (Design-Referenz, in Gebrauch).
