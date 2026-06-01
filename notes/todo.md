# Offene Aufgaben / TODO

Die folgenden Punkte habe ich basierend auf dem aktuellen Stand des Repos (Seiten in `src/app`) identifiziert. Aufgaben sind priorisiert nach Bereich.

## Auth
- Supabase Auth: vollständige Integration prüfen und implementieren: Google & Apple OAuth, SMS-OTP (falls noch nicht aktiviert).
- Login-Rate-Limiting (Upstash/Redis) sicherstellen (5 Versuche / Minute pro IP).

## Betriebs- & Bewerbungsfluss
- Supabase Storage: CVs / Anlagen Upload einrichten + serverseitige Zugriffskontrolle (Bucket + Service Role).
- Bewerbungsstatus-Tracking: Endpunkte prüfen/erstellen (Jobs → Bewerbungen → Statuswechsel).

## Admin / Moderation
- Admin-Dashboard `/admin` anlegen (Moderation, Benutzerverwaltung, Moderation-Reports).
- Moderation-Backend: `moderation_reports`-Tabelle + APIs (Report-Listing, Review-Removal, Account-Sperre).
- Internes Verifizierungs-Workflow (`/intern/ops/verification`) implementieren.

## Zahlungen & Subscriptions
- Stripe-Integration für `subscription` (Payments, Webhooks, Invoices) planen und umsetzen (V2).

## Datenschutz & Rechtliches
- Impressum / Datenschutz / AGB rechtlich prüfen vor Go-Live (offen, falls noch nicht geprüft).
- Account-Lösch-Workflow serverseitig überprüfen (DSGVO-konform, Löschfristen, Datenexport).

## Qualität & Betrieb
- Analytics: Backend-Aggregation prüfen (`trpc.analytics.*`) und Datenquellen verifizieren.
- Tests: kritische End-to-end-Tests für Auth, Review-Posting, Datei-Uploads.
- Deployment: Supabase-Projekt in EU-Region sicherstellen; Migration SQLite → Postgres/Prisma.

Wenn du möchtest, markiere ich die einzelnen Punkte als Tickets (Issues) oder implementiere sie nacheinander — was bevorzugst du?

