# Karriko – Betriebs-Bereich (eingeloggt)
> Auth-Anforderung: `role = 'BETRIEB'` + E-Mail verifiziert · Azubis werden zu ihrem Dashboard weitergeleitet

---

## Allgemeine Prinzipien

- Alle Betriebs-Seiten liegen unter der Route-Gruppe `(betrieb)/`
- `(betrieb)/layout.tsx` prüft Session + Rolle + gibt Betriebskontext (company_id) global weiter
- Server Actions und tRPC-Aufrufe nutzen `betriebProcedure` + zusätzliche Eigentümerprüfung (`company.user_id = ctx.user.id`)
- **Kritisch:** Jeder Zugriff auf Bewerbungsunterlagen, Analytics und Nutzerdaten wird serverseitig an `company_id` gebunden – kein Betrieb kann Daten anderer Betriebe sehen

---

## `/dashboard` – Betriebs-Dashboard

**Zweck:** Überblick über Kennzahlen, Bewertungen und Aktivitäten

**Rendering:** SSR

### Sektionen

| Sektion | Inhalt | Komponenten |
|---|---|---|
| KPI-Kacheln | Gesamtbewertung, Anzahl Bewertungen, Profilaufrufe (7 Tage), Offene Bewerbungen | `<KpiCard>` × 4 |
| Aktuelle Bewertungen | Die 5 neuesten Bewertungen mit Schnellzugriff auf Antworten | `<RecentReviewsList>` |
| Score-Verlauf | Liniendiagramm: Bewertungsdurchschnitt der letzten 30 Tage | `<ScoreChart>` |
| Offene Bewerbungen | Neueste Bewerbungen nach Stelle gruppiert | `<ApplicationSummary>` |
| Profil-Vollständigkeit | Progress-Bar: Wie vollständig ist das Profil? | `<ProfileCompleteness>` |

### API-Aufrufe

```ts
trpc.company.getDashboardData.query()
// Gibt zurück: kpis, recentReviews, applicationCount, scoreHistory
```

---

## `/profile` – Unternehmensprofil verwalten

**Zweck:** Stammdaten, Bilder, Beschreibung, Branding bearbeiten

**Rendering:** SSR (initiale Daten) + CSR (Live-Preview beim Bearbeiten)

### Bearbeitbare Felder

| Feld | Typ | Beschreibung |
|---|---|---|
| Unternehmensname | Text | Pflichtfeld |
| Branche | Dropdown | Aus vordefinierten Kategorien |
| Standort / PLZ | Text + Geocoding | Für Suche und Karte |
| Beschreibungstext | WYSIWYG (max. 2000 Zeichen) | Sanitized HTML |
| Website-URL | URL | Validiert |
| Headerbild | Upload | Max. 5 MB, 1920×480px empfohlen |
| Logo | Upload | Max. 2 MB, quadratisch empfohlen |
| Custom Theme | Farbpicker | Primärfarbe für Profil-Akzente |
| Social Links | Text × 4 | LinkedIn, Instagram, Facebook, Twitter/X |

### Live-Preview

```tsx
// Rechte Seite: Echtzeit-Vorschau der Profilseite
<ProfilePreview company={formValues} />
```

### Upload-Sicherheit

```ts
// Serverseitige MIME-Type-Prüfung (nicht nur Client-Extension)
const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp']
const maxFileSizeBytes = { header: 5_000_000, logo: 2_000_000 }

// Supabase Storage Bucket: 'company-assets' (öffentlich lesbar, Schreiben nur mit Service Role)
const path = `${companyId}/logo.webp`
```

### API-Aufrufe

```ts
trpc.company.updateProfile.mutate({ name, description, industry, location, website, socialLinks, themeColor })
// Upload: direkt zu Supabase Storage, dann URL in DB speichern
```

---

## `/reviews` – Bewertungen verwalten

**Zweck:** Alle Bewertungen einsehen und beantworten

**Rendering:** SSR + CSR (Antwort-Formular)

### Layout

- Filterleiste: Alle / Beantwortet / Unbeantwortet / Gemeldet
- Sortierung: Neueste / Älteste / Schlechteste / Beste
- Pro Bewertung: Vollständige Darstellung + Antwortfeld

### Antwort-Funktionalität

```
Regeln für Betriebsantworten:
├── Pro Bewertung max. 1 Antwort
├── Antwort ist nach Veröffentlichung NICHT mehr bearbeitbar
├── Max. 1000 Zeichen
├── Kein HTML / keine Links (Plain Text)
└── Antwort erscheint öffentlich direkt unter der Bewertung
```

### Bewertung melden

```ts
trpc.review.reportReview.mutate({
  reviewId,
  reason: 'FAKE' | 'OFFENSIVE' | 'WRONG_COMPANY' | 'OTHER',
  description: string, // optional, max. 500 Zeichen
})
// Erstellt einen Eintrag in moderation_reports → sichtbar im Intern-Bereich
```

### API-Aufrufe

```ts
trpc.review.getByCompany.query({ companyId, filter, sort, page })
trpc.review.postReply.mutate({ reviewId, text })
trpc.review.reportReview.mutate({ reviewId, reason, description })
```

---

## `/analytics` – Analytics

**Zweck:** Bewertungstrends, Profilaufrufe, Vergleichsdaten

**Rendering:** SSR + CSR (Charts)

### Widgets

| Widget | Zeitraum | Beschreibung |
|---|---|---|
| Gesamtbewertung Verlauf | 7 / 30 / 90 Tage | Liniendiagramm: Score-Entwicklung |
| Bewertungsanzahl | 7 / 30 / 90 Tage | Balkendiagramm: neue Bewertungen pro Zeitraum |
| Kategorie-Scores | aktuell | Radardiagramm: alle 5 Kategorien |
| Profilaufrufe | 7 / 30 Tage | Liniendiagramm: tägliche Aufrufe |
| Branchenvergleich (Premium) | aktuell | Wie schneidet der Betrieb vs. Branchendurchschnitt ab? |

### Datenschutz-Hinweis

> Analytics-Daten sind aggregiert und enthalten **keine personenbezogenen Daten** (kein Tracking einzelner Nutzer-IDs in der Betriebsansicht). Profilaufrufe werden ohne Nutzer-Identifikation gezählt.

### API-Aufrufe

```ts
trpc.analytics.getCompanyStats.query({ companyId, range: '7d' | '30d' | '90d' })
```

---

## `/team` – Mitarbeiter / Ansprechpartner

**Zweck:** Kontaktpersonen für das Betriebsprofil pflegen

**Rendering:** SSR

### Felder pro Ansprechpartner

| Feld | Beschreibung |
|---|---|
| Name | Vor- und Nachname |
| Rolle | z.B. „Ausbildungsleiter", „HR-Manager" |
| E-Mail | Öffentlich sichtbar auf Profil (opt-in) |
| Telefon | Optional, öffentlich (opt-in) |
| Profilbild | Optional, max. 1 MB |

### DSGVO-Hinweis

- E-Mail und Telefon werden nur angezeigt wenn `isPublic = true`
- Ansprechpartner können Eintrag jederzeit entfernen lassen (Betriebsadmin)

---

## `/subscription` – Abonnement verwalten

**Zweck:** Plan einsehen, Upgrade, Rechnungen

**Rendering:** SSR

### Plan-Übersicht (Freemium-Modell)

| Feature | Free | Premium |
|---|---|---|
| Öffentliches Profil | ✅ | ✅ |
| Auf Bewertungen antworten | ✅ | ✅ |
| Stellenanzeigen (max.) | 2 | Unbegrenzt |
| Branchenvergleich | ❌ | ✅ |
| Hervorgehobenes Profil | ❌ | ✅ |
| Analytics (erweitert) | ❌ | ✅ |
| Support-Priorität | Standard | Priorität |

### Rechnungen

- Liste vergangener Rechnungen (Datum, Betrag, Download-Link)
- Stripe-Integration (geplant für V2)
- Kündigung: Subscription läuft bis Periodenende

---

## `/reports` – Meldungen einreichen

**Zweck:** Verdächtige oder falsche Bewertungen melden

**Rendering:** CSR (Formular)

### Meldungs-Flow

```
1. Betrieb wählt Bewertung aus (aus /reviews)
   → Direkt-Link: /reviews?report=[reviewId]

2. Formular:
   ├── Grund: Gefälschte Bewertung / Beleidigung / Falscher Betrieb / Sonstiges
   ├── Beschreibung (max. 500 Zeichen)
   └── Beweise (optional: Screenshot-Upload, max. 2 Dateien)

3. Submit → moderation_reports Eintrag
4. Bestätigung: "Meldung eingegangen, wir prüfen innerhalb von 5 Werktagen"
```

### Rate Limiting

- Max. 5 Meldungen pro Betrieb pro 24 Stunden

---

## `/settings` – Einstellungen

**Rendering:** CSR (Tabs)

### Tab-Struktur

```
Tab 1: Account
  ├── E-Mail des Hauptaccounts ändern
  ├── Passwort ändern
  └── Zwei-Faktor-Authentifizierung

Tab 2: Benachrichtigungen
  ├── E-Mail bei neuer Bewertung
  ├── E-Mail bei neuer Bewerbung
  └── Wochenbericht (Zusammenfassung)

Tab 3: Datenschutz
  ├── Datenschutzerklärung (Link)
  └── "Account und Profil löschen" (⚠️ irreversibel)

Tab 4: API (Premium, V2)
  └── API-Key für Jobbörsen-Syndikation
```

### Account-Löschlogik (Betrieb)

```ts
// deleteCompanyAccount():
// 1. Profil auf is_active = false setzen (öffentlich nicht mehr sichtbar)
// 2. Bewertungen bleiben erhalten (anonym) – Betriebsantworten werden gelöscht
// 3. Stellenanzeigen: is_active = false
// 4. Bewerbungsunterlagen: aus Storage löschen + Bewerber benachrichtigen
// 5. Account in Supabase Auth löschen
// 30-Tage-Frist: Profil reaktivierbar, danach physische Löschung
```
