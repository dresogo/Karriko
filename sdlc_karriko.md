

**SOFTWARE DEVELOPMENT LIFE CYCLE**

**Karriko**

Bewertungsplattform für Auszubildende und Ausbildungsbetriebe im DACH-Raum

**Version:**  1.0

**Status:**  Entwurf

**Datum:**  Marz 2026

**Zeitrahmen:**  3–6 Monate

**Zielmarkt:**  DACH (Deutschland, Osterreich, Schweiz)

**Tech-Stack:**  Next.js · Node.js · PostgreSQL · Supabase

*Dieses Dokument ist vertraulich und ausschließlich für den internen Gebrauch bestimmt.*

| ABSCHNITT 1 Projektübersicht Ziele, Stakeholder, Projektvision und Rahmenbedingungen |
| :---- |

# **1\. Projektübersicht**

## **1.1 Projektvision**

Karriko ist eine webbasierte Plattform, die Auszubildenden im DACH-Raum ermöglicht, ihre Ausbildungsbetriebe transparent und strukturiert zu bewerten. Gleichzeitig erhalten Ausbildungsbetriebe ein professionelles Profil, auf dem sie Ausbildungsplätze ausschreiben und Bewerbungen entgegennehmen können. Die Plattform fördert Transparenz auf dem Ausbildungsmarkt und erleichtert sowohl Auszubildenden als auch Betrieben die gegenseitige Orientierung.

## **1.2 Stakeholder**

| Stakeholder | Rolle & Beschreibung |
| :---- | :---- |
| Auszubildende | Können Betriebe suchen, Bewertungen lesen und selbst Bewertungen verfassen sowie sich auf Ausbildungsplätze bewerben. |
| Ausbildungsbetriebe | Erstellen und pflegen ein Unternehmensprofil, können Bewertungen kommentieren und Ausbildungsplätze ausschreiben. |
| Besucher (nicht angemeldet) | Können die Plattform ohne Registrierung aufrufen und alle öffentlichen Bewertungen und Profile einsehen. |
| Plattform-Admins | Verantwortlich für Inhaltsmoderation, Benutzerverwaltung und Systembetrieb. |

## **1.3 Projektziele**

* Schaffung einer transparenten Bewertungsplattform für Ausbildungsverhältnisse im DACH-Raum

* Bereitstellung von Unternehmensprofilen für Ausbildungsbetriebe mit Selbstverwaltungsfunktion

* Aufbau eines Ausbildungsbörsenbereichs mit Bewerbungsfunktion

* Gewichtetes Bewertungssystem (anonym 0,5 – namentlich 1,0) zur Sicherung der Datenqualität

* DSGVO-konforme Datenhaltung und Authentifizierung

* Responsives, minimalistisches UI mit flotten Animationen

## **1.4 Rahmenbedingungen**

| Rahmenbedingung | Detail |
| :---- | :---- |
| Zeitrahmen | 3–6 Monate (ca. 24 Wochen max.) |
| Zielmarkt | DACH (Deutschland, Osterreich, Schweiz) |
| Sprache | Deutsch |
| Recht | DSGVO, BDSG, oesterreichisches DSG, schweizer DSG |
| Betrieb | Cloud-Hosting, CI/CD-Pipeline, Auto-Skalierung |
| Geraete | Desktop, Tablet, Smartphone (responsive) |

| ABSCHNITT 2 Anforderungsanalyse Funktionale & nicht-funktionale Anforderungen, User Stories, Use Cases |
| :---- |

# **2\. Anforderungsanalyse**

## **2.1 Benutzerrollen und Rechte**

| Rolle | Berechtigungen | Voraussetzung |
| :---- | :---- | :---- |
| Besucher (Gast) | Startseite, Suche, Betriebsprofile, Bewertungen lesen | Kein Account erforderlich |
| Auszubildender | Alle Gast-Rechte \+ Bewertungen schreiben, auf Stellen bewerben | Account \+ E-Mail-Verifizierung |
| Ausbildungsbetrieb | Alle Gast-Rechte \+ Profil verwalten, Stellen ausschreiben, Bewertungen kommentieren | Account \+ Verifizierung als Betrieb |
| Admin | Vollzugriff, Moderation, Benutzerverwaltung | Interner Admin-Account |

## **2.2 Funktionale Anforderungen**

### **2.2.1 Authentifizierung & Registrierung**

* Registrierung und Anmeldung per E-Mail & Passwort

* Registrierung und Anmeldung per Handynummer (SMS-OTP)

* Social Login: Google OAuth 2.0

* Social Login: Apple Sign-in

* Rollenwahl bei der Registrierung: Auszubildender oder Ausbildungsbetrieb

* E-Mail-Verifizierung nach Registrierung

* Passwort-Vergessen-Funktion via E-Mail-Link

* JWT-basierte Session-Verwaltung mit Refresh Tokens

### **2.2.2 Startseite**

* Navbar oben rechts: Anmelden / Registrieren (wenn nicht eingeloggt), Avatar-Menu (wenn eingeloggt)

* Zentrales Suchfeld: Freitextsuche nach Unternehmen mit Live-Vorschau (Autocomplete)

* Bereich „Ausbildungsplaetze“: 4 Cards mit aktuellen Stellenangeboten (Firmenlogo, Berufsbezeichnung, Ort, Datum)

* Bereich „Bewertungen“: 2 Reihen a 3 Cards mit Plattformbewertungen (Nutzerfoto, Name/anonym, Sterne, Kurztext)

* Footer mit rechtlichen Links (Impressum, Datenschutz, AGB) und Sprachauswahl

### **2.2.3 Suche & Betriebsprofil**

* Suchergebnisse werden direkt unterhalb des Suchfeldes als Liste angezeigt

* Klick auf ein Suchergebnis oeffnet die Betriebsprofilseite

* Betriebsprofil: Headerbild, Logo, Unternehmensname, Branche, Durchschnittsbewertung (Sterne \+ Zahl), Gesamtanzahl Bewertungen

* Sortieroptionen fuer Bewertungen: Neueste zuerst / Beste zuerst

* Betriebe koennen ihr Profil selbst gestalten (Farben, Headerbild, Logo, Beschreibungstext, Links)

* Standard-Template wird automatisch angewendet, wenn Betrieb keine Anpassungen vorgenommen hat

### **2.2.4 Bewertungssystem**

* Bewertungsformular mit 5 Kategorien, jeweils 5 Fragen

  * Kategorien: (1) Arbeitsumfeld & Atmosphare, (2) Ausbildungsqualitaet, (3) Verguetung & Benefits, (4) Work-Life-Balance, (5) Karriere & Zukunftsperspektiven

* Frageformate: Stern-Rating (1–5) und Freitext-Antworten je nach Frage

* Veroeffentlichungsoption: Haekchen „Mit Namen veroeffentlichen“ (Gewichtung 1,0) oder „Anonym veroeffentlichen“ (Gewichtung 0,5)

* Durchschnittsbewertung \= Summe(Gewichtung x Note) / Summe(Gewichtungen)

* Betriebe koennen oeffentlich auf Bewertungen antworten (einmalig, nicht nachtraeglich bearbeiten)

* Nutzer koennen Bewertungen als „hilfreich“ markieren

### **2.2.5 Ausbildungsboerse**

* Betriebe koennen Stellenanzeigen erstellen (Titel, Beschreibung, Ort, Ausbildungsbeginn, Anforderungen, Kontaktdaten)

* Auszubildende koennen sich online auf Stellen bewerben (Upload: Lebenslauf, Anschreiben, optionale Anlagen)

* Bewerbungseingang wird dem Betrieb per E-Mail und im Dashboard gemeldet

* Betriebe koennen den Bewerbungsstatus (gesehen, in Pruefung, abgelehnt, eingeladen) setzen

* Auszubildende sehen den Status ihrer Bewerbungen im persoenlichen Dashboard

## **2.3 Nicht-funktionale Anforderungen**

| Anforderung | Beschreibung |
| :---- | :---- |
| Performance | Ladezeit der Startseite \< 2,5 s (LCP), API-Antwortzeiten \< 300 ms (p95) |
| Skalierbarkeit | Horizontale Skalierung, mindestens 10.000 gleichzeitige Nutzer |
| Verfuegbarkeit | 99,9 % Uptime (\< 8,7 h Downtime/Jahr) |
| Sicherheit | OWASP Top 10 beruecksichtigt, HTTPS erzwungen, Input-Validierung, Rate Limiting |
| Datenschutz | DSGVO-konform: Einwilligungsverwaltung, Recht auf Auskunft/Loeschung, Auftragsverarbeitung |
| Barrierefreiheit | WCAG 2.1 Level AA angestrebt |
| Responsivitaet | Mobile-First, Breakpoints: 375 px, 768 px, 1024 px, 1440 px |
| SEO | Server-Side Rendering (SSR) fuer Betriebsprofile und Bewertungsseiten |
| Internationalisierung | i18n-Unterstuetzung; Initialer Launch auf Deutsch |

## **2.4 User Stories (Auswahl)**

| ID | User Story |
| :---- | :---- |
| US-001 | Als Besucher moechte ich die Startseite ohne Anmeldung aufrufen koennen, um Bewertungen zu lesen. |
| US-002 | Als Auszubildender moechte ich nach meinem Ausbildungsbetrieb suchen, um ihn zu finden und zu bewerten. |
| US-003 | Als Auszubildender moechte ich eine Bewertung anonym abgeben koennen, um ehrlich sein zu koennen. |
| US-004 | Als Auszubildender moechte ich mich auf einen Ausbildungsplatz bewerben koennen, ohne die Plattform verlassen zu muessen. |
| US-005 | Als Ausbildungsbetrieb moechte ich mein Profil mit eigenem Headerbild und Logo gestalten koennen. |
| US-006 | Als Ausbildungsbetrieb moechte ich auf Bewertungen oeffentlich antworten koennen, um meinen Standpunkt darzustellen. |
| US-007 | Als Ausbildungsbetrieb moechte ich Stellenanzeigen erstellen und Bewerbungen verwalten koennen. |
| US-008 | Als Nutzer moechte ich mich per Google einloggen koennen, um die Registrierung zu vereinfachen. |
| US-009 | Als Nutzer moechte ich mein Passwort per E-Mail zuruecksetzen koennen. |
| US-010 | Als Admin moechte ich unangemessene Bewertungen loeschen koennen. |

| ABSCHNITT 3 Systemdesign & Architektur Tech-Stack, Datenbankschema, API-Design, UI/UX-Konzept |
| :---- |

# **3\. Systemdesign & Architektur**

## **3.1 Empfohlener Tech-Stack**

| Empfehlung Da keine Tech-Stack-Praeferenz angegeben wurde, wird folgender moderner, produktionserprobter Stack empfohlen, der sich fuer Teams jeder Groesse und einen Zeitrahmen von 3–6 Monaten eignet. |
| :---- |

| Schicht | Technologie | Begruendung |
| :---- | :---- | :---- |
| Frontend | Next.js 14 (App Router) | SSR/SSG, SEO, React 18, TypeScript |
| Styling | Tailwind CSS \+ Framer Motion | Utility-First, einfache Animationen |
| Backend / API | Next.js API Routes \+ tRPC | Type-safe API ohne doppelten Code |
| Datenbank | PostgreSQL (via Supabase) | Relational, DSGVO-Hosting in EU |
| Auth | Supabase Auth | E-Mail, SMS, Google, Apple eingebaut |
| ORM | Prisma | Type-safe DB-Zugriff, Migrationen |
| Datei-Upload | Supabase Storage | Logos, Headerbilder, Bewerbungsunterlagen |
| E-Mail | Resend (oder SendGrid) | Transaktions-E-Mails |
| Hosting | Vercel \+ Supabase | Auto-Skalierung, EU-Region |
| CI/CD | GitHub Actions | Automatisches Testing & Deployment |
| Monitoring | Sentry \+ Vercel Analytics | Fehler-Tracking, Performance |

## **3.2 Systemarchitektur**

Die Anwendung folgt einer modernen 3-Schichten-Architektur mit klarer Trennung von Praesentation, Geschaeftslogik und Datenhaltung.

* Praesentation (Next.js): Server Components fuer SEO-relevante Seiten, Client Components fuer interaktive Elemente (Suchfeld, Formulare, Animationen)

* API-Schicht (tRPC): Type-safe Endpunkte, Validierung mit Zod, Middleware fuer Auth-Pruefung und Rate Limiting

* Datenhaltung (PostgreSQL/Supabase): Relationale Datenbank mit Row Level Security (RLS) fuer DSGVO-konformen Zugriff

* Authentifizierung (Supabase Auth): JWT-Tokens, OAuth 2.0 (Google, Apple), OTP (SMS)

* Datei-Speicher (Supabase Storage): CDN-gestuetzter Objektspeicher fuer Media-Uploads

## **3.3 Datenbankschema (Kerntabellen)**

| Tabelle | Wichtige Felder | Zweck |
| :---- | :---- | :---- |
| users | id, email, phone, role, created\_at, avatar\_url | Alle Nutzer (Auszubildende \+ Betriebe) |
| companies | id, user\_id, name, slug, description, industry, location, logo\_url, header\_url, custom\_theme\_json, verified | Ausbildungsbetriebe |
| reviews | id, company\_id, user\_id, is\_anonymous, weight (0.5/1.0), overall\_score, created\_at | Bewertungskoepfe |
| review\_answers | id, review\_id, question\_id, star\_value (null|1-5), text\_value (null|text) | Einzelne Fragenantworten |
| review\_categories | id, name, sort\_order | 5 Bewertungskategorien |
| review\_questions | id, category\_id, text, type (stars|text), sort\_order | 25 Bewertungsfragen |
| review\_comments | id, review\_id, company\_id, text, created\_at | Betriebsantworten auf Bewertungen |
| job\_listings | id, company\_id, title, description, location, start\_date, requirements, is\_active | Ausbildungsstellenanzeigen |
| applications | id, job\_id, user\_id, status (new/reviewing/rejected/invited), cv\_url, cover\_url | Bewerbungen |
| review\_helpful | review\_id, user\_id, created\_at | Hilfreich-Markierungen |

## **3.4 Bewertungs-Gewichtungsformel**

| Berechnungslogik Durchschnittsbewertung \= SUMME(review.weight \* review.overall\_score) / SUMME(review.weight)  Dabei gilt: Anonyme Bewertung \-\> weight \= 0.5  |  Namentliche Bewertung \-\> weight \= 1.0  Die overall\_score ergibt sich aus dem Durchschnitt aller Sterne-Fragen der 25 Bewertungsfragen (Textfragen fliessen nicht in den Score ein). |
| :---- |

## **3.5 UI/UX-Konzept**

### **3.5.1 Design-Prinzipien**

* Minimalistisch: Viel Weissraum, reduzierte Farbpalette (Primaerfarbe \+ Akzentfarbe \+ Neutrale Graustufen)

* Mobile-First: Alle Komponenten zunaechst fuer Smartphones entworfen, dann fuer groessere Viewports erweitert

* Animationen: Dezente Transitions (Framer Motion): Seitenuebergaenge, Card-Hover-Effekte, Skeleton-Loaders

* Konsistenz: Design-System mit wiederverwendbaren Komponenten (Button, Card, Input, Modal, Badge)

### **3.5.2 Seitenstruktur**

| Route | Inhalt |
| :---- | :---- |
| / (Startseite) | Suchfeld, 4 Job-Cards, 6 Bewertungs-Cards, Hero-Bereich |
| /search?q=\[query\] | Suchergebnisse als Liste mit Filteroptionen |
| /company/\[slug\] | Betriebsprofil: Header, Logo, Bewertungen, Stellenanzeigen |
| /company/\[slug\]/review/new | Bewertungsformular (authentifiziert) |
| /jobs | Uebersicht aller aktuellen Ausbildungsplaetze |
| /jobs/\[id\] | Detailseite einer Stellenanzeige |
| /jobs/\[id\]/apply | Bewerbungsformular (authentifiziert) |
| /dashboard | Nutzer-Dashboard: Meine Bewertungen, Bewerbungen |
| /dashboard/company | Betriebsdashboard: Profil bearbeiten, Stellen verwalten, Bewerbungen |
| /auth/login | Login-Seite (alle Methoden) |
| /auth/register | Registrierungs-Seite (Rollenwahl) |
| /admin | Admin-Bereich (geschuetzt) |

| ABSCHNITT 4 Implementierung Sprint-Planung, Meilensteine, Implementierungsreihenfolge |
| :---- |

# **4\. Implementierung**

## **4.1 Entwicklungsmethodik**

Die Entwicklung erfolgt nach einem agilen Vorgehen mit zweiwochigen Sprints. Jeder Sprint endet mit einem Review und einem kurzen Retro-Meeting. Das Backlog wird in einem Ticket-System (GitHub Issues oder Linear) gepflegt.

| Aspekt | Detail |
| :---- | :---- |
| Sprints | 2-Wochen-Sprints, je mit Sprint-Planning, Daily Standup, Review, Retro |
| Versionskontrolle | Git (GitHub), Feature-Branch-Workflow, Pull Requests mit Code-Review |
| Definition of Done | Feature implementiert \+ Unit-Tests \+ Review durch zweite Person \+ Deployment auf Staging |
| Code-Qualitaet | ESLint \+ Prettier, TypeScript strict mode, Pre-Commit Hooks (Husky) |
| Branching | main (Produktion), develop (Integration), feature/\*, fix/\* |

## **4.2 Meilensteine & Sprint-Plan**

| Sprint | Thema | Deliverables |
| :---- | :---- | :---- |
| Sprint 1–2 (Wo 1–4) | Projektsetup & Grundgeruest | Next.js Setup, Supabase, Auth (E-Mail), DB-Schema, CI/CD |
| Sprint 3–4 (Wo 5–8) | Auth & Nutzerprofile | Social Login, SMS-OTP, Registrierung Betrieb/Azubi, Dashboard-Grundgeruest |
| Sprint 5–6 (Wo 9–12) | Betriebsprofile & Suche | Unternehmensprofil, Suchfunktion mit Autocomplete, Profil-Editor fuer Betriebe |
| Sprint 7–8 (Wo 13–16) | Bewertungssystem | Bewertungsformular (25 Fragen), Gewichtungslogik, Kommentarfunktion |
| Sprint 9–10 (Wo 17–20) | Ausbildungsboerse | Stellenanzeigen erstellen/verwalten, Bewerbungsformular, Datei-Upload, Status-Tracking |
| Sprint 11–12 (Wo 21–24) | Polish & Launch | UI-Feinschliff, Animationen, Performance-Optimierung, Security Audit, Beta-Test, Go-Live |

## **4.3 Implementierungsdetails**

### **4.3.1 Authentifizierung**

Supabase Auth wird als zentrale Auth-Loesung eingesetzt. Die Implementierung umfasst:

* E-Mail/Passwort: Standard-Flow mit E-Mail-Verifizierung und Passwort-Reset

* SMS/OTP: Twilio-Integration ueber Supabase fuer Handy-Authentifizierung

* Google OAuth: Google Cloud Console App-Konfiguration, Redirect-URL auf /auth/callback

* Apple Sign-in: Apple Developer Account, Service ID, Private Key, Redirect-URL

* Session: JWT Access Token (15 min), Refresh Token (30 Tage), automatische Erneuerung im Client

### **4.3.2 Bewertungsformular**

Das Formular wird in 5 Schritte aufgeteilt (eine Kategorie pro Schritt). Ein Fortschrittsbalken zeigt den aktuellen Status. Jede Frage wird per API aus der Datenbank geladen. Die Antworten werden im Local State gehalten und erst beim abschliessenden Absenden als Transaktion in der Datenbank gespeichert.

### **4.3.3 Such-Implementierung**

Die Suche wird als Postgres Full-Text-Search implementiert (tsvector/tsquery) mit deutschem Woerterbuch (pg\_catalog.german). Suchergebnisse werden debounced (300 ms) abgerufen. Bei mehr als 3 Zeichen Eingabe werden Live-Vorschlaege angezeigt. Ergebnisse werden nach Relevanzscore und Anzahl der Bewertungen sortiert.

## **4.4 Datenbank-Migrationen**

Alle Schemaanderungen werden mit Prisma Migrate versioniert. Die Migration-Dateien werden ins Git-Repository eingecheckt. Auf Produktion werden Migrationen automatisch beim Deployment via GitHub Actions ausgefuehrt (zero-downtime bei additiven Aenderungen).

| ABSCHNITT 5 Testing & Qualitaetssicherung Teststrategie, Testfaelle, Testumgebungen |
| :---- |

# **5\. Testing & Qualitaetssicherung**

## **5.1 Teststrategie**

Es wird eine mehrschichtige Teststrategie nach der Test-Pyramide verfolgt:

| Testart | Beschreibung & Tools |
| :---- | :---- |
| Unit Tests | Isolation einzelner Funktionen und Komponenten. Tools: Vitest, React Testing Library. Ziel: \>80 % Coverage fuer Geschaeftslogik (Gewichtungsformel, Validierungen). |
| Integrationstests | Testen der API-Endpunkte mit echter Testdatenbank. Tools: Vitest \+ Supabase Test Utilities. Alle CRUD-Operationen und Berechtigungen. |
| End-to-End-Tests | Testen kompletter Nutzerflows. Tool: Playwright. Kern-Flows: Registrierung, Bewertung schreiben, Stelle ausschreiben, Bewerbung absenden. |
| Manuelle Tests | Exploratives Testen vor jedem Release. Fokus auf UI/UX, Responsivitaet und Edge Cases. |
| Security-Tests | OWASP ZAP Scan, Dependency-Audit (npm audit), Input-Fuzzing auf kritischen Endpunkten. |
| Performance-Tests | Lighthouse CI (LCP \< 2,5 s, CLS \< 0,1), k6 Load-Test (1000 vUsers fuer 5 Minuten). |

## **5.2 Kritische Testfaelle**

| ID | Testfall | Erwartetes Ergebnis |
| :---- | :---- | :---- |
| TC-001 | Bewertung anonym vs. namentlich | Gewichtung 0,5 bzw. 1,0 korrekt in Durchschnitt |
| TC-002 | Bewerbung nur fuer eingeloggte Azubis | Unangemeldete werden zum Login weitergeleitet |
| TC-003 | Betrieb bearbeitet nur eigenes Profil | Zugriff auf fremde Profile ergibt 403 |
| TC-004 | Betrieb antwortet einmalig auf Bewertung | Zweite Antwort desselben Betriebs wird blockiert |
| TC-005 | Google/Apple Login erstellt Account | Nutzer wird nach erstem Login korrekt registriert |
| TC-006 | Datei-Upload Bewerbungsunterlagen | Nur PDF/DOCX akzeptiert, Max. 10 MB pro Datei |
| TC-007 | Suche findet Betriebe | Volltextsuche liefert relevante Ergebnisse auf Deutsch |
| TC-008 | Anonymitaet schutzt Nutzerdaten | Anonyme Bewertungen zeigen keinerlei Nutzerdaten im Frontend |
| TC-009 | DSGVO: Datenloesch-Request | Nutzerloeschung entfernt alle personenbezogenen Daten |
| TC-010 | Responsive Startseite | Cards stapeln sich korrekt auf Viewport 375 px |

## **5.3 Testumgebungen**

| Umgebung | Konfiguration |
| :---- | :---- |
| Local | Entwickler-Maschine, lokale Supabase-Instanz (Docker), .env.local-Konfiguration |
| Staging | Vercel Preview Deployment, separate Supabase-Staging-Instanz, Testdaten-Seed |
| Production | Vercel Production, Supabase Production (EU-Region), echte Nutzer |

## **5.4 Akzeptanzkriterien fuer Go-Live**

* Alle E2E-Tests bestehen in der Staging-Umgebung

* Lighthouse Performance Score \>= 85 auf Mobile

* Keine kritischen oder hohen Sicherheitsluecken aus OWASP ZAP Scan

* DSGVO-Datenschutzerklaerung und Impressum rechtlich geprueft

* Load-Test besteht mit 500 vUsers ohne Fehlerrate \> 1 %

* Beta-Test mit mind. 10 echten Nutzern (5 Azubis, 5 Betriebe) abgeschlossen

| ABSCHNITT 6 Deployment & Betrieb Infrastruktur, CI/CD, Skalierung, Monitoring |
| :---- |

# **6\. Deployment & Betrieb**

## **6.1 Infrastruktur**

| Komponente | Detail |
| :---- | :---- |
| Hosting | Vercel (Next.js): Edge-Funktionen, automatische Preview-Deployments, globales CDN |
| Datenbank | Supabase PostgreSQL: Hosting in Frankfurt (eu-central-1), automatische Backups (taeglich), Point-in-Time Recovery |
| Dateispeicher | Supabase Storage: S3-kompatibel, CDN-Auslieferung, private/oeffentliche Buckets |
| E-Mail | Resend: Transaktions-E-Mails fuer Auth, Bewerbungsbestaetigung, Statusupdates |
| SMS/OTP | Twilio: SMS-Verifizierung fuer Handy-Anmeldung |
| Domain | Eigene Domain mit HTTPS erzwungen (HSTS), www-Redirect |
| DNS | Cloudflare: DDoS-Schutz, DNS-Management, WAF |

## **6.2 CI/CD-Pipeline**

Jeder Push auf einen Feature-Branch loest automatisch folgende Schritte aus:

1. Lint & Type Check (ESLint, TypeScript) – Abbruch bei Fehlern

2. Unit & Integrationstests (Vitest) – Abbruch bei Testfehlern

3. Build (next build) – Abbruch bei Build-Fehlern

4. Preview Deployment auf Vercel (automatische URL)

5. E2E-Tests (Playwright) gegen Preview Deployment

6. Security Scan (npm audit \--audit-level=high)

Bei Merge in main zusaetzlich:

7. Datenbank-Migration auf Produktion (prisma migrate deploy)

8. Production Deployment auf Vercel

9. Smoke-Tests gegen Produktion

10. Slack/E-Mail-Notification an Team

## **6.3 Monitoring & Alerting**

| Bereich | Tool & Beschreibung |
| :---- | :---- |
| Fehler-Tracking | Sentry: Automatisches Erfassen von Exceptions, Breadcrumbs, Release-Tracking |
| Performance | Vercel Analytics \+ Web Vitals: LCP, FID, CLS in Echtzeit |
| Uptime | UptimeRobot: HTTP-Pruefung alle 5 min, Alert bei Downtime |
| Datenbank | Supabase Dashboard: Query Performance, Connection Pool, Speicherverbrauch |
| Logs | Vercel Logs: Serverless Function Logs, Structured Logging via Pino |
| Alerting | Pagerduty oder Slack-Webhook: Kritische Fehler und Downtime sofort benachrichtigt |

## **6.4 Backup & Disaster Recovery**

* Datenbank: Taeglich automatische Backups durch Supabase, 7-Tage-Aufbewahrung

* Point-in-Time Recovery bis zu 7 Tage zurueck

* Datei-Uploads: Replikation innerhalb Supabase Storage

* Recovery Time Objective (RTO): \< 4 Stunden

* Recovery Point Objective (RPO): \< 24 Stunden

| ABSCHNITT 7 Sicherheit & Datenschutz DSGVO-Compliance, OWASP, Anonymität, Datenschutz |
| :---- |

# **7\. Sicherheit & Datenschutz**

## **7.1 OWASP Top 10 Maßnahmen**

| Risiko | Maßnahme |
| :---- | :---- |
| Broken Access Control | Row Level Security (RLS) in Supabase, serverseitige Berechtigungspruefung bei jedem Request |
| Cryptographic Failures | HTTPS erzwungen, Passwoerter mit bcrypt (cost 12), sensible Daten verschluesselt at rest |
| Injection | Ausschliesslich parametrisierte Queries (Prisma ORM), kein dynamisches SQL |
| Insecure Design | Threat Modeling vor Implementierung, Secure-by-Default Konfiguration |
| Security Misconfiguration | Helmet.js Headers, CSP, CORS Whitelist, keine Standard-Credentials |
| Vulnerable Components | npm audit in CI, Dependabot Alerts, regelmaessige Dependency-Updates |
| Auth Failures | Rate Limiting (Upstash Redis), Account-Lockout nach 5 Fehlversuchen, CSRF-Schutz |
| Integrity Failures | Signierte JWTs, Subresource Integrity (SRI) fuer externe Scripts |
| Logging Failures | Strukturierte Logs (Pino), Audit-Log für kritische Aktionen, kein Logging personenbezogene Daten |
| SSRF | Kein direktes Weiterleiten von Nutzer-URLs, Whitelist fuer erlaubte externe Ressourcen |

## **7.2 DSGVO-Compliance**

* Rechtsgrundlage: Einwilligung (Art. 6 Abs. 1 lit. a DSGVO) fuer Bewertungen, Vertragserfuellung fuer Account-Daten

* Datensparsamkeit: Nur notwendige Daten werden erfasst (kein Tracking ohne Einwilligung)

* Transparenz: Datenschutzerklaerung und Cookie-Banner beim ersten Besuch

* Recht auf Auskunft: Nutzer koennen alle gespeicherten Daten als JSON exportieren

* Recht auf Loeschung: Account-Loeschung loescht oder anonymisiert alle personenbezogenen Daten

* Anonymitaet: Anonyme Bewertungen intern gespeichert (fuer Missbrauchsschutz), aber nie oeffentlich mit dem Nutzer verknuepft

* Auftragsverarbeitung: AVV mit Supabase, Vercel, Resend, Twilio

* Datenhaltung in der EU: Alle Dienste mit EU-Region (Frankfurt/Dublin)

* Technisch-organisatorische Massnahmen (TOMs) dokumentiert

## **7.3 Anonymitaetssystem**

| Technische Umsetzung der Anonymitaet Beim Speichern einer anonymen Bewertung wird die user\_id in der Datenbank hinterlegt (fuer interne Missbrauchspruefung und Eindeutigkeitskontrolle), aber das is\_anonymous-Flag gesetzt. Die API-Endpunkte und das Frontend geben bei anonymen Bewertungen niemals Nutzernamen, Avatar oder andere identifizierende Daten zurueck. Die user\_id ist ausschliesslich fuer Admins zur Moderation sichtbar. |
| :---- |

| ABSCHNITT 8 Wartung & Weiterentwicklung Betrieb, SLA, Roadmap, Change Management |
| :---- |

# **8\. Wartung & Weiterentwicklung**

## **8.1 Support & SLA**

| Kategorie | SLA |
| :---- | :---- |
| Kritische Fehler (P1) | System nicht erreichbar: Response \< 1 h, Fix \< 4 h |
| Schwerwiegende Fehler (P2) | Kernfunktionalitaet ausgefallen: Response \< 4 h, Fix \< 24 h |
| Mittlere Fehler (P3) | Fehler ohne Workaround: Response \< 1 Werktag, Fix \< 1 Woche |
| Kleinere Fehler (P4) | Kosmetische Issues: Aufnahme ins naechste Sprint-Backlog |
| Updates | Sicherheits-Patches sofort, Dependency-Updates monatlich, Feature-Releases quartalsweise |

## **8.2 Post-Launch Roadmap (V2)**

| Feature | Beschreibung |
| :---- | :---- |
| Empfehlungsalgorithmus | Personalisierte Stellenempfehlungen basierend auf Bewerberprofil und Standort |
| Verifikations-Badge | Bestaetigung, dass Reviewer wirklich Azubi im Betrieb war (z.B. via Ausbildungsvertrag-Upload) |
| Benachrichtigungen | Push-Notifications/E-Mail-Alerts fuer neue Bewerbungen und Bewertungsantworten |
| Branchenvergleich | Benchmark-Funktion: Wie schneidet ein Betrieb im Branchenvergleich ab? |
| Mobile App | React Native App (iOS/Android) auf Basis der bestehenden API |
| Analytics-Dashboard | Betriebe erhalten Einblick in Profilaufrufe und Klickraten auf Stellenanzeigen |
| API fuer Dritte | Oeffentliche REST-API fuer Jobboersen-Syndikation (z.B. Indeed, StepStone) |

3. ## **Change Management**

* Alle Anforderungsänderungen werden als RFC (Request for Change) dokumentiert

* Impact-Analyse vor jeder größeren Änderung (Aufwand, Risiko, Abhängigkeiten)

* Breaking Changes im Datenbankschema erfordern eine Migration und einen Rollback-Plan

* Feature Flags (LaunchDarkly oder Vercel Feature Flags) fuer schrittweise Rollouts

* Semantische Versionierung: MAJOR.MINOR.PATCH

| ABSCHNITT 9 Zeitplan & Ressourcen Gesamtplanung, Teambesetzung, Risikoregister |
| :---- |

# **9\. Zeitplan & Ressourcen**

## **9.1 Empfohlene Teambesetzung**

| Rolle | Verantwortlichkeit |
| :---- | :---- |
| 1x Tech Lead / Full-Stack Dev | Architektur, Core-Backend, Code-Reviews, CI/CD |
| 1x Full-Stack Dev | Frontend-Implementierung, API-Integration, Testing |
| 1x UI/UX Designer | Design-System, Wireframes, Prototypen, User-Testing |
| 0,5x DevOps/Infra | Supabase-Setup, CI/CD-Pipeline, Monitoring (Teilzeit) |
| 0,5x QA Engineer | Testplanung, E2E-Tests, Testdokumentation (Teilzeit) |

## **9.2 Gesamtzeitplan (24 Wochen)**

| Zeitraum | Phase | Schwerpunkte |
| :---- | :---- | :---- |
| Woche 1–4 | Foundation | Setup, Auth, DB-Schema, Design System, Grundseiten |
| Woche 5–8 | Core Features I | Nutzerprofile, Betriebsprofile, Suchfunktion |
| Woche 9–12 | Core Features II | Bewertungssystem, Gewichtungslogik, Kommentare |
| Woche 13–16 | Ausbildungsboerse | Stellenanzeigen, Bewerbungsprozess, Datei-Upload |
| Woche 17–20 | Dashboard & Admin | Nutzer-Dashboard, Betriebsdashboard, Admin-Bereich |
| Woche 21–22 | Testing & Security | E2E-Tests, Security Audit, Performance-Optimierung |
| Woche 23–24 | Beta & Launch | Beta-Test mit echten Nutzern, Bugfixes, Go-Live |

## **9.3 Risikoregister**

| Risiko | W'keit / Impact | Maßnahme |
| :---- | :---- | :---- |
| R-001  Scope Creep | Mittel / Hoch | Striktes Change Management, MVP-First-Ansatz, regelm. Stakeholder-Alignment |
| R-002  DSGVO-Verstoß | Niedrig / Kritisch | Fruhzeitige Einbeziehung eines Datenschutzbeauftragten, DSGVO-Audit vor Launch |
| R-003  Supabase-Ausfall | Niedrig / Hoch | Monitoring \+ Alerting, Backups, Notfall-Runbook, Alternative DB-Provider evaluiert |
| R-004  Missbräuchliche Bewertungen | Mittel / Mittel | Meldungs-Funktion, Admin-Moderation, Rate Limiting fuer Bewertungen |
| R-005  Langsame Apple-Zertifizierung | Mittel / Niedrig | Apple-Developer-Account frueh beantragen (Vorlauf 1–2 Wochen) |
| R-006  Team-Verfügbarkeit | Mittel / Mittel | Dokumentation aller Entscheidungen, Onboarding-Guide, kein Single Point of Knowledge |

*SDLC · Karriko · Version 1.0 · Marz 2026*