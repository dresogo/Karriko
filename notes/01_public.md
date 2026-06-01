# Karriko – Öffentliche Seiten (Public)
> Auth-Anforderung: keine · Sichtbar für alle Besucher (Gast + eingeloggte Nutzer)

---

## `/` – Startseite

**Zweck:** Erster Eindruck, Conversion zu Registrierung/Bewertung, SEO-Einstieg

**Rendering:** SSR (dynamischer Inhalt: aktuelle Bewertungen & Stellen)

### Sektionen

| Sektion | Inhalt | Komponenten |
|---|---|---|
| Navbar | Logo links, Suche (Mitte), Anmelden/Registrieren rechts (oder Avatar wenn eingeloggt) | `<Navbar>`, `<SearchBar>`, `<AuthButtons>` |
| Hero | Headline, Subline, zentrales Suchfeld mit Autocomplete, CTA-Button | `<HeroSection>`, `<SearchBar autoFocus>` |
| Ausbildungsplätze | 4 Job-Cards (Firmenlogo, Berufsbezeichnung, Ort, Datum) | `<JobCard>` × 4 |
| Bewertungen | 2 Reihen × 3 Cards (Nutzerfoto/anonym, Sterne, Kurztext, Betriebsname) | `<ReviewCard>` × 6 |
| USP-Bereich | 3 Feature-Highlights (Icon + Text) | `<FeatureCard>` × 3 |
| CTA-Banner | Betriebe ansprechen → „Jetzt kostenlos Profil anlegen" | `<CtaBanner>` |
| Footer | Impressum, Datenschutz, AGB, Social Links, Sprachauswahl | `<Footer>` |

### API-Aufrufe

```ts
// Aktuelle Stellenanzeigen (max. 4, is_active = true)
trpc.job.getLatest.query({ limit: 4 })

// Aktuelle Bewertungen (max. 6, öffentlich, nach created_at desc)
trpc.review.getLatestPublic.query({ limit: 6 })
```

### SEO

- `<title>` Karriko – Bewertungen für Ausbildungsbetriebe im DACH-Raum
- `description` Meta-Tag mit Keyword-Fokus „Ausbildungsbewertung"
- Structured Data: `WebSite` + `SearchAction` (Sitelinks-Searchbox)

---

## `/company/[slug]` – Unternehmensseite

**Zweck:** Öffentliches Profil eines Ausbildungsbetriebs

**Rendering:** SSR + ISR (revalidate: 60s)

### Sektionen

| Sektion | Inhalt | Komponenten |
|---|---|---|
| Header | Headerbild, Logo, Unternehmensname, Branche, Ort | `<CompanyHeader>` |
| Score-Overview | Gesamtdurchschnitt (Sterne + Zahl), Anzahl Bewertungen, Kategorie-Scores | `<ScoreOverview>`, `<CategoryScoreBar>` × 5 |
| Bewertungs-Feed | Liste aller Bewertungen, sortierbar (Neueste / Beste), Betriebsantworten eingerückt | `<ReviewList>`, `<ReviewItem>`, `<CompanyReply>` |
| Stellenanzeigen | Aktuelle Ausbildungsplätze dieses Betriebs | `<JobListingCard>` |
| Profil-Info | Beschreibungstext, Website-Link, Social Links | `<CompanyDescription>` |
| CTA (Azubi) | „Diesen Betrieb bewerten" (nur wenn eingeloggt als Azubi) | `<WriteReviewButton>` |

### API-Aufrufe

```ts
// Unternehmen anhand Slug laden
trpc.company.getBySlug.query({ slug })

// Bewertungen mit Paginierung
trpc.review.getByCompany.query({ companyId, sort: 'newest' | 'best', page })

// Stellenanzeigen
trpc.job.getByCompany.query({ companyId })
```

### Sicherheit & DSGVO

- `is_anonymous = true` → `author: null` wird übergeben, nie `user_id`
- `user_id` wird vom Server-Router **immer** entfernt vor der API-Response
- Betriebsantworten: nur 1 Antwort pro Bewertung möglich

### SEO

- `<title>` [Unternehmensname] als Ausbildungsbetrieb – Karriko
- Open Graph: Unternehmensname, Bewertungsdurchschnitt, Logo
- Structured Data: `LocalBusiness` + `AggregateRating`
- Canonical URL mit Slug

---

## `/search` – Suche & Entdecken

**Zweck:** Betriebe suchen und filtern

**Rendering:** SSR (Suchergebnisse server-seitig für SEO)

**Query-Parameter:** `?q=[suchbegriff]&branche=[slug]&ort=[plz]&sort=[score|reviews|name]`

### Layout

| Bereich | Inhalt | Komponenten |
|---|---|---|
| Suchleiste | Suchfeld oben, Autocomplete-Dropdown | `<SearchBar>` |
| Filterleiste | Branche (Dropdown), Ort/PLZ (Freitext), Mindestbewertung (Slider), Sortierung | `<FilterBar>`, `<FilterChips>` |
| Ergebnisliste | Company-Cards (Logo, Name, Branche, Ort, Score, Anzahl Bewertungen) | `<CompanyCard>` |
| Karte (optional, V2) | Geografische Darstellung | — |
| Leerer Zustand | „Keine Ergebnisse" + Alternativvorschläge | `<EmptyState>` |

### API-Aufrufe

```ts
trpc.company.search.query({
  q: string,
  branche?: string,
  ort?: string,
  minScore?: number,
  sort: 'score' | 'reviews' | 'name',
  page: number,
})
```

---

## `/reviews/[id]` – Bewertungsdetailseite

**Zweck:** Einzelne Bewertung vollständig einsehbar (SEO-Link, Teilen)

**Rendering:** SSR + ISR

### Inhalt

- Vollständige Bewertung mit allen 25 Antworten (Sterne + Freitext)
- Kategorie-Aufschlüsselung
- Betriebsantwort (falls vorhanden)
- Breadcrumb: Startseite → [Unternehmensname] → Bewertung
- „Hilfreich"-Button (nur für eingeloggte Nutzer)

### API-Aufrufe

```ts
trpc.review.getById.query({ id })
// Gibt NIEMALS user_id zurück wenn is_anonymous = true
```

---

## `/fuer-betriebe` – B2B Landing Page

**Zweck:** Ausbildungsbetriebe als Kunden gewinnen (Freemium → Premium)

**Rendering:** SSG (statisch, kein dynamischer Inhalt)

### Sektionen

| Sektion | Inhalt |
|---|---|
| Hero | Headline, USPs für Betriebe, CTA „Kostenloses Profil erstellen" |
| Features | Profil verwalten, auf Bewertungen antworten, Stellen ausschreiben |
| Pricing | Freemium vs. Premium Vergleich |
| Social Proof | Anzahl registrierter Betriebe, Regionen |
| FAQ | Häufige Fragen von Betrieben |
| CTA Footer | Registrierungsbutton |

---

## `/blog` – Blog / Ratgeber

**Zweck:** SEO-Content, organischer Traffic

**Rendering:** SSG (statische Seiten aus CMS/Markdown)

### Unterseiten

- `/blog` → Übersicht aller Artikel (Kategorien: Azubis, Betriebe, Markt)
- `/blog/[slug]` → Einzelartikel

### Artikel-Frontmatter (Markdown)

```yaml
---
title: "10 Fragen, die du bei deiner Ausbildung stellen solltest"
description: "..."
date: "2026-04-01"
category: "azubis"
author: "Karriko Redaktion"
image: "/blog/images/artikel-header.jpg"
---
```

---

## `/ueber-uns` – Über uns

**Rendering:** SSG

### Inhalt

- Mission & Vision von Karriko
- Gründerteam (Fotos, Namen, Rollen)
- Story / Wie es entstand
- Presse-Bereich (optional)
- Kontakt-CTA

---

## `/kontakt` – Kontakt

**Rendering:** SSR (Formular-Verarbeitung)

### Inhalt

- Kontaktformular: Name, E-Mail, Betreff, Nachricht, Datenschutz-Checkbox
- Pflichtfeld: Einwilligung zur Verarbeitung (Art. 6 Abs. 1 lit. a DSGVO)
- Bestätigungsmail via Resend

```ts
// Formular-Validierung (Zod)
const contactSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  subject: z.string().min(5).max(200),
  message: z.string().min(20).max(2000),
  consent: z.literal(true),
})
```

---

## Rechtliche Pflichtseiten

### `/impressum`
- Angaben nach § 5 TMG
- Verantwortlicher, Anschrift, E-Mail, USt-ID (wenn vorhanden)
- Rendering: SSG

### `/datenschutz`
- Datenschutzerklärung nach Art. 13/14 DSGVO
- Abschnitte: Verantwortlicher, Datenarten, Rechtsgrundlagen, Betroffenenrechte, Cookies, Drittanbieter
- Rendering: SSG · **Pflicht: Vor Go-Live rechtlich prüfen lassen**

### `/agb`
- Allgemeine Geschäftsbedingungen
- Rendering: SSG · **Pflicht: Vor Go-Live rechtlich prüfen lassen**
