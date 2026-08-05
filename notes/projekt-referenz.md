# Karriko – Projektreferenz

**Stand:** 4. August 2026
**Zweck:** Das fachliche Nachschlagewerk des Projekts. Was Karriko sein soll, welche Regeln gelten, welche Grenzwerte einzuhalten sind.

Diese Datei fasst vierzehn ältere Notizen zusammen, die zwischen März und Juni 2026 entstanden sind. Alles Überholte ist entfernt, alles fachlich Gültige übernommen.

**Wichtige Abgrenzung:** Dieses Dokument beschreibt **Anforderungen**, nicht den Umsetzungsstand. Was tatsächlich gebaut ist, steht in `notes/reports/` — dort liegen der Statusbericht und der Sicherheitsbericht, und nur die sind zum aktuellen Stand aussagekräftig.

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

Die Ausbildungsbörse mit Stellenanzeigen, Online-Bewerbung und Statusverfolgung war in der Ursprungsspezifikation ein Kernbestandteil. In der Flutter-App existiert sie **nicht**: Es gibt keine Jobs-Collection, keine Bewerbungen und keinen Datei-Upload. Die Stellenanzeigen auf der Oberfläche sind eine Behelfslösung, die aus Firmendaten abgeleitet wird.

Das ist eine bewusst zu treffende Produktentscheidung, keine offene Aufgabe: Entweder die Börse kommt zurück auf die Roadmap, oder die Behelfslösung verschwindet aus der Oberfläche. Der derzeitige Zwischenzustand verspricht dem Nutzer etwas, das es nicht gibt.

---

## 2. Das Bewertungssystem

Der fachliche Kern der Plattform. Diese Regeln sind unabhängig von der Technik einzuhalten.

### 2.1 Aufbau einer Bewertung

**Fünf Kategorien mit je fünf Fragen — 25 Fragen insgesamt:**

1. Arbeitsumfeld & Atmosphäre
2. Ausbildungsqualität
3. Vergütung & Benefits
4. Work-Life-Balance
5. Karriere & Zukunftsperspektiven

Pro Kategorie drei bis vier Sterne-Fragen (1–5) und ein bis zwei Freitextfragen (optional, max. 1000 Zeichen).

### 2.2 Gewichtung

```
Durchschnitt = SUMME(gewicht × gesamtscore) / SUMME(gewicht)

namentlich veröffentlicht → gewicht = 1.0
anonym veröffentlicht     → gewicht = 0.5
```

Der `gesamtscore` einer Bewertung ist der Mittelwert **aller Sterne-Antworten**. Freitextantworten fließen nicht in die Berechnung ein.

Der Gedanke dahinter: Wer mit Namen einsteht, wiegt schwerer — ohne dass anonyme Stimmen verstummen müssen.

### 2.3 Anonymität — technisch

> Bei einer anonymen Bewertung wird die Nutzer-ID **immer** in der Datenbank gespeichert: für die Missbrauchsprüfung und die Eindeutigkeitskontrolle. Gesetzt wird zusätzlich das Kennzeichen `is_anonymous`. Weder API noch Oberfläche geben bei anonymen Bewertungen jemals Name, Avatar oder andere identifizierende Daten zurück. Die Nutzer-ID ist ausschließlich für die Moderation sichtbar.

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

Kein physisches Löschen, sondern ein `deleted_at`-Zeitstempel. Grund: Betriebsantworten sollen erhalten bleiben, und der Gesamtscore des Betriebs muss nachvollziehbar neu berechnet werden können. In der öffentlichen Ansicht verschwindet die Bewertung sofort.

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
| Profil | Stammdaten; E-Mail-Änderung erfordert erneute Bestätigung |
| Bewertung schreiben | mehrstufig: Betrieb suchen → Anonymität wählen → 5 Kategorien → Zusammenfassung |
| Meine Bewertungen | bearbeiten (nur Freitext, keine Sterne) und löschen |
| Merkliste | gemerkte Betriebe |
| Benachrichtigungen | Antwort erhalten, Bewertung gemeldet, Bewertung entfernt, System |
| Einstellungen | Konto, Datenschutz, Benachrichtigungen, Konto löschen |

**Konto löschen (Art. 17 DSGVO)** — die Reihenfolge ist Teil der Anforderung:

1. E-Mail und Telefon auf `null`, Name auf „Gelöschter Nutzer"
2. Profilbild aus dem Speicher entfernen
3. namentliche Bewertungen: Anzeigename wird „Ehemaliger Azubi"
4. anonyme Bewertungen: Nutzer-ID bleibt bestehen (Missbrauchsschutz)
5. Auth-Konto löschen
6. Datensatz mit `deleted_at` markieren

**Datenexport (Art. 20 DSGVO):** Profil, alle Bewertungen, Merkliste und Benachrichtigungen als JSON zum Herunterladen.

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
| **Content Security Policy fehlt** | weiterhin offen — siehe Sicherheitsbericht, S2 |
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

Die Barrierefreiheit ist derzeit an zwei Stellen verfehlt: Die Akzentfarbe erreicht den Kontrastwert nicht, und die Kopfzeile bricht bei vergrößerter Systemschrift. Beides steht im Statusbericht.

### Kritische Testfälle

Diese Fälle prüfen Regeln, die still brechen können, ohne dass es jemandem auffällt:

| Fall | Erwartung |
|---|---|
| anonym vs. namentlich | Gewichtung 0,5 bzw. 1,0 wirkt korrekt im Durchschnitt |
| fremdes Profil bearbeiten | wird abgelehnt |
| zweite Antwort auf dieselbe Bewertung | wird blockiert |
| **Anonymität** | anonyme Bewertung gibt **keinerlei** Nutzerdaten preis — auch nicht in der API-Antwort |
| Konto löschen | alle personenbezogenen Daten sind entfernt oder anonymisiert |
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
