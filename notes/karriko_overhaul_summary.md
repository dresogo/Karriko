# Karriko – Überarbeitung abgeschlossen ✅

Die gesamte Webapp wurde gemäß des SDLC-Dokuments überarbeitet und erweitert.

## Screenshots

````carousel
![Hero Section – Premium Design mit Gradient-Text, Suchfeld und Trust-Badges](C:\Users\sdemh\.gemini\antigravity\brain\2886fc47-cad6-4cd3-a1ab-f6095736e6eb\homepage_hero_1773653669843.png)
<!-- slide -->
![Job Cards – 4 aktuelle Ausbildungsplätze mit Bildern, Firmenname und Standort](C:\Users\sdemh\.gemini\antigravity\brain\2886fc47-cad6-4cd3-a1ab-f6095736e6eb\homepage_job_cards_1773653679293.png)
<!-- slide -->
![Bewertungen & Statistiken – 6 Review-Cards mit Gewichtungs-Badges und animierte Statistiken](C:\Users\sdemh\.gemini\antigravity\brain\2886fc47-cad6-4cd3-a1ab-f6095736e6eb\homepage_reviews_stats_1773653687947.png)
<!-- slide -->
![Footer – Professioneller dunkler Footer mit Karriko-Branding, Plattform-Links, Rechtliches und Sprachauswahl](C:\Users\sdemh\.gemini\antigravity\brain\2886fc47-cad6-4cd3-a1ab-f6095736e6eb\homepage_footer_1773653696015.png)
````

## Was wurde umgesetzt

### 🎨 Branding & Design
| Vorher | Nachher |
|--------|---------|
| Name: AzubiCheck | Name: **Karriko** |
| Einfarbiges Blau | **Indigo-Violet Gradient** (#6366f1 → #8b5cf6) |
| Basis-CSS | **Vollständiges Design-System** mit 40+ CSS-Variablen |
| Einfache Hover-Effekte | **Glasmorphism**, Micro-Animationen, Shimmer-Skeletons |
| Kein Footer | **Professioneller dunkler Footer** (Impressum, Datenschutz, AGB, Sprache) |

### 📄 Neue & überarbeitete Seiten

| Route | Datei | Status |
|-------|-------|--------|
| Startseite | [index.html](file:///c:/Users/sdemh/Desktop/Karriko/index.html) | ✅ Komplett überarbeitet |
| Suche | [search.html](file:///c:/Users/sdemh/Desktop/Karriko/search.html) | ✅ Überarbeitet mit Sortierung |
| Betriebsprofil | [company.html](file:///c:/Users/sdemh/Desktop/Karriko/company.html) | ✅ Multi-Step-Bewertungsformular |
| Ausbildungsplätze | [jobs.html](file:///c:/Users/sdemh/Desktop/Karriko/jobs.html) | 🆕 Neu erstellt |
| Stellendetail | [job-detail.html](file:///c:/Users/sdemh/Desktop/Karriko/job-detail.html) | 🆕 Neu erstellt |
| Azubi-Dashboard | [dashboard.html](file:///c:/Users/sdemh/Desktop/Karriko/dashboard.html) | 🆕 Neu erstellt |
| Unternehmensbereich | [company_dashboard.html](file:///c:/Users/sdemh/Desktop/Karriko/company_dashboard.html) | ✅ Erweitert (4 Tabs) |
| Admin | [admin.html](file:///c:/Users/sdemh/Desktop/Karriko/admin.html) | 🆕 Neu erstellt |

### 🔧 Backend ([server.js](file:///c:/Users/sdemh/Desktop/Karriko/server.js))

**Neue Datenbank-Tabellen** (gemäß SDLC Abschnitt 3.3):
- `review_categories` – 5 Bewertungskategorien
- `review_questions` – 25 Bewertungsfragen (5 pro Kategorie)
- `review_answers` – Einzelne Fragenauswertungen
- `review_comments` – Betriebsantworten (einmalig pro Review)
- `review_helpful` – Hilfreich-Markierungen
- `job_listings` – Ausbildungsstellenanzeigen
- `applications` – Bewerbungen mit Status-Tracking

**Neue API-Endpunkte**:
- `GET/POST /api/jobs` – Stellen CRUD
- `GET /api/jobs/:id` – Stellendetail
- `PUT/DELETE /api/jobs/:id` – Stellen bearbeiten/löschen
- `GET /api/review-categories` – Kategorien + Fragen
- `POST /api/reviews/:id/comments` – Betriebsantworten
- `POST /api/reviews/:id/helpful` – Hilfreich-Markierung
- `GET/POST /api/applications` – Bewerbungen
- `PUT /api/applications/:id/status` – Bewerbungsstatus ändern
- `GET /api/admin/users` – Alle Nutzer (Admin)
- `DELETE /api/admin/users/:id` – Nutzer löschen
- `DELETE /api/admin/reviews/:id` – Bewertung löschen
- `GET /api/admin/stats` – Plattform-Statistiken

### ⭐ SDLC-Features implementiert

| Feature | SDLC Ref. | Status |
|---------|-----------|--------|
| Branding „Karriko" | 1.1 | ✅ |
| Registrierung mit Rollenwahl | 2.2.1 | ✅ |
| Social Login (Google/Apple simuliert) | 2.2.1 | ✅ |
| Startseite: Hero + Suche + Jobs + Reviews | 2.2.2 | ✅ |
| Live-Autocomplete Suche (Debounce 300ms) | 2.2.3 | ✅ |
| Betriebsprofil mit Headerbild & Logo | 2.2.3 | ✅ |
| Bewertungsformular: 5 Kategorien à 5 Fragen | 2.2.4 | ✅ |
| Gewichtung: anonym 0.5 / namentlich 1.0 | 2.2.4 / 3.4 | ✅ |
| Betrieb antwortet auf Bewertungen (einmalig) | 2.2.4 | ✅ |
| Hilfreich-Markierung | 2.2.4 | ✅ |
| Stellenanzeigen erstellen/verwalten | 2.2.5 | ✅ |
| Online-Bewerbung mit Dateien | 2.2.5 | ✅ |
| Bewerbungsstatus-Tracking | 2.2.5 | ✅ |
| Azubi-Dashboard (Bewertungen + Bewerbungen) | 3.5.2 | ✅ |
| Betriebsdashboard (Profil, Stellen, Bewerbungen, Reviews) | 3.5.2 | ✅ |
| Admin-Bereich (Moderation) | 3.5.2 | ✅ |
| Footer: Impressum, Datenschutz, AGB | 2.2.2 | ✅ |
| Responsive (Mobile-First) | 2.3 | ✅ |
| Animationen (fadeIn, slideUp, shimmer) | 3.5.1 | ✅ |

## Server starten

```bash
node server.js
```

Dann im Browser: **http://localhost:3000**

### Test-Accounts

| E-Mail | Passwort | Rolle |
|--------|----------|-------|
| `admin@karriko.de` | `admin123` | Superadmin |
| `lisa@example.com` | `pass123` | Azubi |
| `tom@example.com` | `pass123` | Azubi |
| `max@technova.de` | `pass123` | Unternehmen |
| `info@globallog.de` | `pass123` | Unternehmen |
