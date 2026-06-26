# ✅ Karriko Seitenstruktur - Umsetzung Abgeschlossen

**Datum:** Mai 3, 2026  
**Status:** ✅ Vollständig implementiert

---

## 📊 Implementierungszahlen

### Neue Seiten erstellt: **33**

| Route Group | Seiten | Details |
|---|---|---|
| **(public)** | 12 | Home + 11 öffentliche Seiten |
| **(auth)** | 6 | Login, Register (2×), Password Recovery (2×), Verify |
| **(azubi)** | 7 | Dashboard, Profile, Reviews (2×), Bookmarks, Notifications, Settings |
| **(betrieb)** | 8 | Dashboard, Profile, Reviews, Analytics, Team, Subscription, Reports, Settings |

### Zusätzlich: **4 Layout-Dateien**

- `(public)/layout.tsx`
- `(auth)/layout.tsx`
- `(azubi)/layout.tsx`
- `(betrieb)/layout.tsx`

### Documentation: **2 Dateien**

- `src/app/STRUCTURE.md` - Detaillierte Übersicht
- `IMPLEMENTATION_GUIDE.md` - Diese Datei

---

## 📁 Verzeichnisstruktur

```
src/app/
├── (public)/                      # Öffentliche Seiten
│   ├── layout.tsx
│   ├── page.tsx                  # Startseite
│   ├── company/[slug]/
│   │   └── page.tsx              # Unternehmensseite
│   ├── search/
│   │   └── page.tsx              # Suche & Filter
│   ├── reviews/[id]/
│   │   └── page.tsx              # Bewertungsdetail
│   ├── fuer-betriebe/
│   │   └── page.tsx              # B2B Landing
│   ├── blog/
│   │   ├── page.tsx              # Blog-Übersicht
│   │   └── [slug]/
│   │       └── page.tsx          # Blog-Artikel
│   ├── ueber-uns/
│   │   └── page.tsx
│   ├── kontakt/
│   │   └── page.tsx
│   ├── impressum/
│   │   └── page.tsx
│   ├── datenschutz/
│   │   └── page.tsx
│   └── agb/
│       └── page.tsx
│
├── (auth)/                        # Authentifizierung
│   ├── layout.tsx
│   ├── login/
│   │   └── page.tsx
│   ├── register/
│   │   ├── azubi/
│   │   │   └── page.tsx
│   │   └── betrieb/
│   │       └── page.tsx
│   ├── forgot-password/
│   │   └── page.tsx
│   ├── reset-password/
│   │   └── page.tsx
│   └── verify-email/
│       └── page.tsx
│
├── (azubi)/                       # Auszubildende (protegiert)
│   ├── layout.tsx
│   ├── dashboard/
│   │   └── page.tsx
│   ├── profile/
│   │   └── page.tsx
│   ├── reviews/
│   │   └── new/
│   │       └── page.tsx
│   ├── my-reviews/
│   │   └── page.tsx
│   ├── bookmarks/
│   │   └── page.tsx
│   ├── notifications/
│   │   └── page.tsx
│   └── settings/
│       └── page.tsx
│
├── (betrieb)/                     # Ausbildungsbetriebe (protegiert)
│   ├── layout.tsx
│   ├── dashboard/
│   │   └── page.tsx
│   ├── profile/
│   │   └── page.tsx
│   ├── reviews/
│   │   └── page.tsx
│   ├── analytics/
│   │   └── page.tsx
│   ├── team/
│   │   └── page.tsx
│   ├── subscription/
│   │   └── page.tsx
│   ├── reports/
│   │   └── page.tsx
│   └── settings/
│       └── page.tsx
│
├── layout.tsx                     # Root Layout (Navbar + Footer)
├── globals.css
└── STRUCTURE.md                   # Detaillierte Dokumentation
```

---

## 🔒 Schutzkonzept

### (public) - Keine Authentifizierung
- Sichtbar für alle Besucher
- Keine Session-Checks erforderlich

### (auth) - Nur für nicht-eingeloggte Nutzer
- Automatische Umleitung zu Dashboard wenn eingeloggt
- 5 Login-Versuche pro Minute/IP Rate Limit
- Sichere Token-Validierung

### (azubi) - Rolle-basiert (role = 'AZUBI')
- Betriebe werden zu `/betrieb/dashboard` weitergeleitet
- E-Mail-Verifizierung erforderlich
- Soft-Delete bei Datenlöschung (DSGVO)

### (betrieb) - Rolle-basiert (role = 'BETRIEB')
- Azubis werden zu `/azubi/dashboard` weitergeleitet
- E-Mail-Verifizierung erforderlich
- **Kritisch:** Eigentümerprüfung bei Datenzugriff

---

## 🎯 Nächste Implementierungsschritte

### 1. Middleware (Priorität: HOCH)
```tsx
// middleware.ts
- Session-Check bei geschützten Routes
- Rolle-basierte Umleitung
- company_id Context für Betriebe
```

### 2. Komponenten & Formulare (Priorität: HOCH)
- `<Navbar>` - Navigation mit Role-Detection
- `<AuthButtons>` - Dynamische Auth-Links
- `<CompanyCard>`, `<ReviewCard>`, `<JobCard>`
- Form-Komponenten mit Zod-Validierung

### 3. API-Integration (Priorität: HOCH)
- tRPC Router Setup
- Server Actions für Formulare
- Supabase Client-Konfiguration
- Prisma Schema Validation

### 4. Datenschutz-Compliance (Priorität: KRITISCH)
- ⚠️ `/datenschutz` & `/agb` von Anwalt prüfen lassen
- DSGVO Art. 13/14 Anforderungen erfüllen
- Cookie-Consent Banner
- Datenschutz-Richtlinien implementieren

### 5. Design & UX (Priorität: MITTEL)
- Tailwind CSS Templates
- Responsive Layouts
- Dark Mode (optional)
- Loading States & Error Handling

---

## 📋 Checkliste für nächste Phase

- [ ] Middleware Setup
- [ ] Supabase Auth Integration
- [ ] tRPC Router Struktur
- [ ] Komponenten-Bibliothek
- [ ] Form-Validierung (Zod)
- [ ] Database Schema (Prisma)
- [ ] Rechtliche Dokumente überprüfen
- [ ] Design System (Tailwind)
- [ ] Error Handling
- [ ] Analytics Setup

---

## 🔗 Referenzen

### Anforderungsdokumente
- `notes/01_public.md` - Öffentliche Seiten
- `notes/02_auth.md` - Authentifizierung
- `notes/03_azubi.md` - Azubi-Bereich
- `notes/04_betrieb.md` - Betrieb-Bereich

### Weitere Dokumentation
- [Next.js App Router Docs](https://nextjs.org/docs/app)
- [Route Groups Documentation](https://nextjs.org/docs/app/building-your-application/routing/route-groups)
- [DSGVO Compliance Guide](https://ec.europa.eu/info/law/law-topic/data-protection_en)

---

## 📞 Support & Notizen

### Bekannte Anforderungen
- ⚠️ Alle `// TODO:` Kommentare sind Platzhalter für Implementierung
- ⚠️ Rechtliche Seiten MÜSSEN vor Go-Live von Anwalt freigegeben werden
- ⚠️ Middleware für Route Guards ist noch zu erstellen
- ⚠️ Supabase / Prisma Setup erforderlich

### Best Practices
✅ Alle Seiten haben:
- Aussagekräftige `// TODO:` Kommentare
- Richtige Metadata (SEO)
- Security Dokumentation
- Component-Struktur-Vorschlag
- Rate Limit Hinweise wo relevant

---

**Status:** Ready for Backend Integration ✅  
**Erstellt:** Mai 3, 2026  
**Struktur:** 33 page.tsx + 4 layout.tsx
