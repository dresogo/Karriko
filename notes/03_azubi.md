# Karriko – Azubi-Bereich (eingeloggt)
> Auth-Anforderung: `role = 'AZUBI'` + E-Mail verifiziert · Middleware leitet nicht-autorisierte Nutzer zu `/login` weiter

---

## Allgemeine Prinzipien

- Alle Azubi-Seiten liegen unter der Route-Gruppe `(azubi)/`
- Layout-Datei `(azubi)/layout.tsx` prüft Session + Rolle bei jedem Seitenaufruf
- Betriebe landen bei Zugriffsversuch auf Azubi-Routen auf ihrer eigenen Dashboard-Seite
- Alle Server Actions und tRPC-Aufrufe setzen `azubiProcedure` voraus (serverseitige Rollenprüfung)

---

## `/dashboard` – Azubi-Dashboard

**Zweck:** Persönliche Übersicht, Einstiegspunkt nach Login

**Rendering:** SSR

### Sektionen

| Sektion | Inhalt | Komponenten |
|---|---|---|
| Begrüßung | „Hallo [Vorname]" + Datum | `<WelcomeBanner>` |
| Aktivitäts-Feed | Neueste Aktionen (Bewertung geschrieben, Betrieb gespeichert) | `<ActivityFeed>` |
| Meine Bewertungen | Letzte 3 Bewertungen mit Schnellzugriff | `<RecentReviews>` |
| Empfehlungen | Betriebe in meiner Region / Branche | `<RecommendedCompanies>` |
| Merkliste (Vorschau) | Erste 3 gespeicherte Betriebe | `<BookmarkPreview>` |
| Benachrichtigungen | Ungelesene Benachrichtigungen (Badge) | `<NotificationBadge>` |

### API-Aufrufe

```ts
trpc.user.getDashboardData.query()
// Gibt zurück: recentReviews, bookmarkCount, unreadNotifications, recommendations
```

---

## `/profile` – Eigene Profilseite

**Zweck:** Profil anzeigen und bearbeiten

**Rendering:** SSR (initiale Daten) + Client (Bearbeitung)

### Anzeigefelder

| Feld | Bearbeitbar | Beschreibung |
|---|---|---|
| Profilbild | ✅ | Upload via Supabase Storage, max. 2 MB, JPG/PNG/WebP |
| Vorname, Nachname | ✅ | |
| E-Mail | ✅ | Änderung erfordert erneute Verifizierung |
| Ausbildungsberuf | ✅ | Freitext |
| Ausbildungsjahr | ✅ | 1 / 2 / 3 |
| Bundesland | ✅ | Dropdown |
| Öffentliches Profil | ✅ | Toggle: Profil für andere sichtbar machen |
| Mitglied seit | ❌ | `created_at` (schreibgeschützt) |

### API-Aufrufe

```ts
// Profil laden
trpc.user.getProfile.query()

// Profil speichern
trpc.user.updateProfile.mutate({ firstName, lastName, profession, year, state, isPublic })

// Profilbild hochladen (direkt zu Supabase Storage)
supabase.storage.from('avatars').upload(`${userId}/avatar.webp`, file)
```

### DSGVO-Hinweis

- Profilbild-URL wird in `users.avatar_url` gespeichert
- Beim Account-Löschen: Avatar aus Storage löschen + `avatar_url = null`

---

## `/reviews/new` – Bewertung schreiben

**Zweck:** Ausbildungsbetrieb bewerten (Kernfunktion der Plattform)

**Rendering:** CSR (interaktives Multi-Step-Formular)

### Voraussetzungen

- Nutzer muss eingeloggt sein (`role = 'AZUBI'`)
- E-Mail verifiziert
- Max. 1 Bewertung pro Betrieb pro Nutzer (serverseitig geprüft)
- Rate Limit: max. 3 Bewertungen pro 24h pro Account

### Formular-Schritte

```
Schritt 1: Betrieb suchen
  └── Autocomplete-Suche → Betrieb auswählen
      (Falls nicht gefunden: "Betrieb hinzufügen" → creates pending company)

Schritt 2: Anonymität wählen
  ├── "Mit Namen veröffentlichen" (Gewichtung: 1.0)
  └── "Anonym veröffentlichen" (Gewichtung: 0.5)
      + Hinweis: "Intern wird deine ID gespeichert, um Missbrauch zu verhindern"

Schritt 3–7: 5 Kategorien (je 5 Fragen)
  Kategorie 1: Arbeitsumfeld & Atmosphäre
  Kategorie 2: Ausbildungsqualität
  Kategorie 3: Vergütung & Benefits
  Kategorie 4: Work-Life-Balance
  Kategorie 5: Karriere & Zukunftsperspektiven

  Pro Kategorie:
  ├── Kategorie-Überschrift + Beschreibung
  ├── 3–4 Sterne-Fragen (1–5 Sterne)
  └── 1–2 Freitext-Fragen (optional)

Schritt 8: Zusammenfassung
  ├── Übersicht aller Antworten
  ├── Gesamtbewertung (berechnet)
  ├── Einwilligung zur Veröffentlichung (Checkbox, Pflicht)
  └── "Bewertung veröffentlichen"-Button
```

### Validierung

```ts
const reviewSchema = z.object({
  companyId: z.string().uuid(),
  isAnonymous: z.boolean(),
  answers: z.array(z.object({
    questionId: z.string().uuid(),
    starValue: z.number().min(1).max(5).nullable(),
    textValue: z.string().max(1000).nullable(),
  })).length(25),
  consent: z.literal(true),
})
```

### Gewichtungsberechnung (serverseitig)

```ts
// src/server/services/review.service.ts
const calculateOverallScore = (answers: ReviewAnswer[]): number => {
  const starAnswers = answers.filter(a => a.starValue !== null)
  return starAnswers.reduce((sum, a) => sum + a.starValue!, 0) / starAnswers.length
}

// weight: 0.5 (anonym) oder 1.0 (namentlich)
```

### Sicherheit

- Server prüft: Hat dieser Nutzer diesen Betrieb bereits bewertet?
- `user_id` wird immer in DB gespeichert (intern), egal ob anonym
- Bewertung wird erst nach Zod-Validierung in DB geschrieben

---

## `/my-reviews` – Meine Bewertungen

**Zweck:** Übersicht aller eigenen Bewertungen

**Rendering:** SSR

### Tabellen-/Karteninhalt

| Spalte | Beschreibung |
|---|---|
| Betrieb | Logo + Name (verlinkt zu `/company/[slug]`) |
| Datum | `created_at` formatiert |
| Score | Gesamtbewertung (Sterne) |
| Anonymität | „Namentlich" / „Anonym" |
| Aktionen | Bearbeiten (nur Text-Antworten, keine Sterne-Änderung) · Löschen |

### Löschlogik

- Bewertung löschen → Gesamtscore des Betriebs wird neu berechnet
- Keine physische Löschung: `deleted_at`-Timestamp (Soft Delete), damit Betriebsantworten erhalten bleiben
- In der öffentlichen Ansicht nicht mehr sichtbar

### API-Aufrufe

```ts
trpc.review.getMyReviews.query({ page, sort: 'newest' | 'oldest' })
trpc.review.deleteReview.mutate({ reviewId })
trpc.review.updateReview.mutate({ reviewId, textAnswers })
```

---

## `/bookmarks` – Merkliste

**Zweck:** Gespeicherte / gemerkte Betriebe verwalten

**Rendering:** SSR

### Layout

- Grid aus `<CompanyCard>`-Komponenten
- Sortierung: Gespeichert-Datum, Name, Bewertung
- „Aus Merkliste entfernen"-Button pro Card
- Leerer Zustand: „Du hast noch keine Betriebe gespeichert" + CTA zur Suche

### API-Aufrufe

```ts
trpc.bookmark.getBookmarks.query({ sort })
trpc.bookmark.removeBookmark.mutate({ companyId })
```

---

## `/notifications` – Benachrichtigungen

**Zweck:** Systembenachrichtigungen anzeigen

**Rendering:** SSR + Realtime (Supabase Realtime Subscription)

### Benachrichtigungstypen

| Typ | Auslöser | Text |
|---|---|---|
| `REVIEW_REPLY` | Betrieb antwortet auf Bewertung | „[Betrieb] hat auf deine Bewertung geantwortet" |
| `REVIEW_FLAGGED` | Bewertung wurde gemeldet | „Deine Bewertung bei [Betrieb] wurde zur Prüfung markiert" |
| `REVIEW_REMOVED` | Admin entfernt Bewertung | „Deine Bewertung bei [Betrieb] wurde entfernt" + Begründung |
| `SYSTEM` | Plattform-Meldungen | Wartungsankündigung etc. |

### Funktionen

- Als gelesen markieren (einzeln + „alle als gelesen")
- Notification-Badge im Header zeigt ungelesene Anzahl

### API-Aufrufe

```ts
trpc.notification.getAll.query({ unreadOnly: boolean })
trpc.notification.markAsRead.mutate({ notificationId })
trpc.notification.markAllAsRead.mutate()
```

---

## `/settings` – Einstellungen

**Zweck:** Account-Verwaltung, Datenschutz, Account-Löschung

**Rendering:** CSR (Tabs)

### Tab-Struktur

```
Tab 1: Account
  ├── E-Mail ändern (→ erneute Verifizierung)
  ├── Passwort ändern
  └── Zwei-Faktor-Authentifizierung (TOTP) aktivieren/deaktivieren

Tab 2: Datenschutz
  ├── Einwilligung zu Analytics (Cookie) verwalten
  ├── Einwilligung zu Newsletter verwalten
  ├── Profil-Sichtbarkeit (öffentlich / nur ich)
  └── "Meine Daten exportieren" → JSON-Download (Art. 20 DSGVO)

Tab 3: Benachrichtigungen
  ├── E-Mail bei neuer Betriebsantwort
  ├── E-Mail bei Bewertungs-Status
  └── Newsletter (falls aktiviert)

Tab 4: Account löschen ⚠️
  ├── Erklärung was passiert (anonymisieren, nicht löschen bei anonymen Bewertungen)
  ├── Passwort-Bestätigung
  └── Bestätigungstext-Eingabe ("KONTO LÖSCHEN")
```

### Account-Löschlogik (DSGVO Art. 17)

```ts
// src/server/services/user.service.ts – deleteAccount()
// 1. E-Mail → null, Telefon → null, Name → "Gelöschter Nutzer"
// 2. Profilbild aus Supabase Storage löschen
// 3. Namentliche Bewertungen: author_display = "Ehemaliger Azubi"
// 4. Anonyme Bewertungen: user_id bleibt (Missbrauchsschutz), keine Änderung nötig
// 5. Bewerbungsunterlagen aus Storage löschen
// 6. Supabase Auth: deleteUser(userId)
// 7. users-Eintrag: soft-delete (deleted_at Timestamp)
```

### Daten-Export (Art. 20 DSGVO)

```ts
trpc.user.exportData.query()
// Gibt zurück: Profil, alle Bewertungen, alle Bewerbungen, Merkliste, Benachrichtigungen
// Als JSON-Download im Browser
```
