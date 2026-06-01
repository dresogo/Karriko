# Karriko – Überarbeitungsplan gemäß SDLC

## IST-Zustand
Die aktuelle App heißt noch **AzubiCheck** und ist eine einfache Node.js + SQLite + Vanilla JS Webapp mit:
- [index.html](file:///c:/Users/sdemh/Desktop/Karriko/index.html) – Startseite mit Suche, Job-Cards, Bewertungs-Cards
- [company.html](file:///c:/Users/sdemh/Desktop/Karriko/company.html) / [company.js](file:///c:/Users/sdemh/Desktop/Karriko/company.js) – Betriebsprofil mit Bewertungen
- [search.html](file:///c:/Users/sdemh/Desktop/Karriko/search.html) – Suchergebnisse
- [company_dashboard.html](file:///c:/Users/sdemh/Desktop/Karriko/company_dashboard.html) – Betriebsdashboard (Profil anlegen/bearbeiten)
- [azubi_profile.html](file:///c:/Users/sdemh/Desktop/Karriko/azubi_profile.html) – Azubi-Profil bearbeiten
- [server.js](file:///c:/Users/sdemh/Desktop/Karriko/server.js) – Express-API mit SQLite

## SOLL-Zustand (aus SDLC)
Das SDLC beschreibt eine umfassende Plattform **Karriko** mit:
1. **Branding**: Name "Karriko" statt "AzubiCheck"
2. **Design**: Minimalistisch, premium, Animationen, Mobile-First, Glasmorphism
3. **Auth**: E-Mail, Social (Google/Apple), Rollenwahl
4. **Startseite**: Hero + Suche + 4 Job-Cards + 6 Bewertungs-Cards + Footer
5. **Suche**: Live-Autocomplete, Suchergebnis-Seite mit Filters
6. **Betriebsprofil**: Header, Logo, Bewertungen, Stellen, Profil-Editor
7. **Bewertungssystem**: 5 Kategorien à 5 Fragen, Gewichtung (anonym 0.5 / namentlich 1.0)
8. **Ausbildungsbörse**: Stellenanzeigen erstellen/verwalten, Bewerbungsformular, Status-Tracking
9. **Dashboards**: Azubi- und Betriebsdashboard
10. **Admin-Bereich**: Moderation, Benutzerverwaltung
11. **Footer**: Impressum, Datenschutz, AGB