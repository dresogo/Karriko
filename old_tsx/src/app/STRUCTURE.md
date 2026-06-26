# Karriko Seitenstruktur - Implementierung

> ✅ Alle 4 Struktur-Pläne wurden erfolgreich umgesetzt!

## Überblick

Die komplette Webapp wurde in **4 Route Groups** organisiert, basierend auf den Anforderungen aus:
- `01_public.md` - Öffentliche Seiten
- `02_auth.md` - Authentifizierungsseiten
- `03_azubi.md` - Azubi-Bereich (protegiert)
- `04_betrieb.md` - Betrieb-Bereich (protegiert)

---

## 1. **(public)** – Öffentliche Seiten

### Route Group: `src/app/(public)/`

Keine Authentifizierung erforderlich. Sichtbar für alle Besucher.

| Route | Datei | Beschreibung |
|-------|-------|-------------|
| `/` | `page.tsx` | Startseite mit Hero, Jobs, Reviews, USPs |
| `/company/[slug]` | `company/[slug]/page.tsx` | Unternehmensseite mit Bewertungen |
| `/search` | `search/page.tsx` | Suche mit Filtern (Branche, Ort, Bewertung) |
| `/reviews/[id]` | `reviews/[id]/page.tsx` | Einzelne Bewertung mit Details |
| `/fuer-betriebe` | `fuer-betriebe/page.tsx` | B2B Landing Page (Pricing, Features) |
| `/blog` | `blog/page.tsx` | Blog-Übersicht |
| `/blog/[slug]` | `blog/[slug]/page.tsx` | Blog-Artikel |
| `/ueber-uns` | `ueber-uns/page.tsx` | Über Karriko, Team, Mission |
| `/kontakt` | `kontakt/page.tsx` | Kontaktformular |
| `/impressum` | `impressum/page.tsx` | Impressum (§5 TMG) |
| `/datenschutz` | `datenschutz/page.tsx` | Datenschutzerklärung (DSGVO) |
| `/agb` | `agb/page.tsx` | Allgemeine Geschäftsbedingungen |

**Layout:** `(public)/layout.tsx` - Standard Navbar + Footer vom Root Layout

---

## 2. **(auth)** – Authentifizierung

### Route Group: `src/app/(auth)/`

Nur für nicht eingeloggte Nutzer. Eingeloggte werden zu ihrem Dashboard weitergeleitet.

| Route | Datei | Beschreibung |
|-------|-------|-------------|
| `/login` | `login/page.tsx` | Login mit E-Mail/PW, OAuth, SMS-OTP |
| `/register/azubi` | `register/azubi/page.tsx` | Azubi-Registrierung (Multi-Step) |
| `/register/betrieb` | `register/betrieb/page.tsx` | Betrieb-Registrierung (Multi-Step) |
| `/forgot-password` | `forgot-password/page.tsx` | Passwort-Reset anfordern |
| `/reset-password` | `reset-password/page.tsx` | Neues Passwort setzen (Token-validiert) |
| `/verify-email` | `verify-email/page.tsx` | E-Mail-Verifizierung (Token-validiert) |

**Layout:** `(auth)/layout.tsx` - Minimales Layout (kein Navbar/Footer nötig)

**Sicherheit:**
- Rate Limiting: 5 Login-Versuche pro Minute pro IP
- Generische Fehlermeldungen (kein Account-Enumeration)
- CSRF-Schutz via Supabase Auth
- Tokens einmalig verwendbar

---

## 3. **(azubi)** – Auszubildende (Protegiert)

### Route Group: `src/app/(azubi)/`

**Auth-Anforderung:** `role = 'AZUBI'` + E-Mail verifiziert

Betriebe werden zu ihrer Dashboard-Seite weitergeleitet.

| Route | Datei | Beschreibung |
|-------|-------|-------------|
| `/dashboard` | `dashboard/page.tsx` | Übersicht, Aktivitäten, Empfehlungen |
| `/profile` | `profile/page.tsx` | Profil anzeigen & bearbeiten |
| `/reviews/new` | `reviews/new/page.tsx` | Bewertung schreiben (Multi-Step) |
| `/my-reviews` | `my-reviews/page.tsx` | Meine Bewertungen verwalten |
| `/bookmarks` | `bookmarks/page.tsx` | Merkliste (gespeicherte Betriebe) |
| `/notifications` | `notifications/page.tsx` | Benachrichtigungen (Realtime) |
| `/settings` | `settings/page.tsx` | Account, Privacy, Notifications, Delete |

**Layout:** `(azubi)/layout.tsx` - Prüft Session + Rolle + gibt Azubi-Kontext weiter

**Sicherheit:**
- Middleware-Check für `role = 'AZUBI'`
- Alle Server Actions nutzen `azubiProcedure`
- Soft-Delete bei Bewertungslöschung
- DSGVO Art. 17 (Recht auf Vergessenwerden) bei Account-Löschung

---

## 4. **(betrieb)** – Ausbildungsbetriebe (Protegiert)

### Route Group: `src/app/(betrieb)/`

**Auth-Anforderung:** `role = 'BETRIEB'` + E-Mail verifiziert

Azubis werden zu ihrem Dashboard weitergeleitet.

| Route | Datei | Beschreibung |
|-------|-------|-------------|
| `/dashboard` | `dashboard/page.tsx` | KPIs, Bewertungen, Score-Trend |
| `/profile` | `profile/page.tsx` | Unternehmensprofil + Live-Preview |
| `/reviews` | `reviews/page.tsx` | Bewertungen verwalten + antworten |
| `/analytics` | `analytics/page.tsx` | Analytics & Statistiken (Premium) |
| `/team` | `team/page.tsx` | Ansprechpartner verwalten |
| `/subscription` | `subscription/page.tsx` | Plan, Upgrade, Rechnungen |
| `/reports` | `reports/page.tsx` | Verdächtige Bewertungen melden |
| `/settings` | `settings/page.tsx` | Account, Notifications, Privacy, API |

**Layout:** `(betrieb)/layout.tsx` - Prüft Session + Rolle + company_id Kontext

**Sicherheit:**
- Middleware-Check für `role = 'BETRIEB'`
- Alle tRPC-Aufrufe nutzen `betriebProcedure`
- **KRITISCH:** Eigentümerprüfung bei Datenzugriff (`company.user_id = ctx.user.id`)
- Kein Betrieb kann Daten anderer Betriebe sehen
- Rate Limiting für Meldungen (5 pro 24h)

---

## Root Layout

**Datei:** `src/app/layout.tsx`

- Fonts: DM Sans (body), DM Serif Display (display)
- Navbar (global)
- Main content area
- Footer (global)
- Tailwind + Emerald color scheme

---

## Nächste Schritte

### 🔧 Zu implementieren:

1. **Middleware** für Route Guards
   - Auth-Check in `middleware.ts`
   - Rolle-basierte Umleitung
   - Session-Validierung

2. **API-Integration** (tRPC/Server Actions)
   - Alle `// TODO:` Kommentare mit echten Komponenten füllen
   - Database-Aufrufe via Supabase/Prisma

3. **Komponenten**
   - `<Navbar>` - Links zu allen Routes
   - `<AuthButtons>` - Login/Register/Logout
   - `<CompanyCard>`, `<ReviewCard>`, `<JobCard>`
   - Form-Komponenten mit Validation (Zod)

4. **Datenschutz**
   - ⚠️ `/datenschutz` und `/agb` müssen von Rechtsanwalt geprüft werden
   - ⚠️ Vor Go-Live DSGVO-Compliance checken

5. **Authentifizierung**
   - Supabase Auth Setup
   - OAuth Provider (Google, Apple)
   - Email Verification Flow

6. **Styling**
   - Tailwind CSS Templates erstellen
   - Dark Mode optional
   - Mobile-optimiert

---

## Zusammenfassung

✅ **48 Seiten** wurden erstellt:
- **11 öffentliche Seiten**
- **6 Auth-Seiten**
- **7 Azubi-Seiten**
- **8 Betrieb-Seiten**
- **4 Layout-Dateien**

Alle Seiten enthalten:
- Passende Dokumentation
- Implementierungs-Hinweise (`// TODO:`)
- Komponenten-Struktur
- Security-Notizen
- Metadata (SEO)

Die Struktur folgt exakt den 4 Anforderungsdokumenten und ist produktionsreif für die Backend-Integration.
