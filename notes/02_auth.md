# Karriko – Authentifizierungsseiten
> Auth-Anforderung: keiner (nur für nicht eingeloggte Nutzer zugänglich) · Eingeloggte Nutzer werden zu `/dashboard` weitergeleitet

---

## Allgemeine Prinzipien

- Alle Auth-Seiten liegen unter der Route-Gruppe `(auth)/`
- **Middleware-Regel:** Eingeloggte Nutzer, die `/login` oder `/register` aufrufen, werden sofort zu ihrem Dashboard weitergeleitet (kein Flash)
- **Supabase Auth** übernimmt Token-Verwaltung, Session-Handling und OAuth-Flows
- Kein Passwort oder Credentials wird jemals im Frontend-State gespeichert
- Rate Limiting: max. **5 Login-Versuche / Minute / IP** (Upstash Redis)

---

## `/login` – Login

**Zweck:** Gemeinsame Login-Seite für Azubis und Betriebe

**Rendering:** CSR (Client Component, kein SEO-Bedarf)

### Login-Methoden

| Methode | Beschreibung | Komponente |
|---|---|---|
| E-Mail + Passwort | Standard-Anmeldung | `<EmailPasswordForm>` |
| Google OAuth | Ein-Klick-Login via Google | `<OAuthButton provider="google">` |
| Apple Sign-in | Ein-Klick-Login via Apple | `<OAuthButton provider="apple">` |
| SMS-OTP | Anmeldung per Handynummer + Einmalcode | `<SmsOtpForm>` |

### Formular-Validierung

```ts
const loginSchema = z.object({
  email: z.string().email("Ungültige E-Mail-Adresse"),
  password: z.string().min(8, "Mindestens 8 Zeichen"),
})
```

### Fehlerbehandlung

- Falsches Passwort: generische Fehlermeldung (kein Hinweis ob E-Mail existiert → Enumeration-Schutz)
- Account gesperrt: spezifische Meldung mit Support-Link
- Rate-Limit erreicht: „Zu viele Versuche. Bitte warte 60 Sekunden."

### Sicherheit

- `autocomplete="current-password"` für Passwortmanager-Unterstützung
- CSRF-Schutz via Supabase Auth (eingebaut)
- Kein Logging der eingegebenen Passwörter (auch nicht in Sentry)

### Navigation

- Link zu `/register/azubi` und `/register/betrieb`
- Link zu `/forgot-password`

---

## `/register/azubi` – Registrierung Auszubildende

**Zweck:** Eigener Registrierungsflow für Auszubildende

**Rendering:** CSR (Multi-Step-Formular)

### Schritte

```
Schritt 1: Persönliche Daten
  ├── Vorname, Nachname
  ├── E-Mail-Adresse
  ├── Passwort (mit Stärke-Indikator)
  └── Passwort wiederholen

Schritt 2: Ausbildungsinfo (optional, kann übersprungen werden)
  ├── Aktueller Ausbildungsberuf
  ├── Ausbildungsjahr (1 / 2 / 3)
  └── Bundesland

Schritt 3: Einwilligungen
  ├── ✅ Datenschutzerklärung gelesen und akzeptiert (Pflicht)
  ├── ✅ AGB akzeptiert (Pflicht)
  └── ☐ Newsletter (optional)
```

### Validierung

```ts
const azubiRegisterSchema = z.object({
  firstName: z.string().min(2).max(50),
  lastName: z.string().min(2).max(50),
  email: z.string().email(),
  password: z.string()
    .min(8)
    .regex(/[A-Z]/, "Mindestens ein Großbuchstabe")
    .regex(/[0-9]/, "Mindestens eine Zahl"),
  passwordConfirm: z.string(),
  // Optional
  profession: z.string().optional(),
  year: z.enum(["1", "2", "3"]).optional(),
  state: z.string().optional(),
  // Pflicht-Einwilligungen
  acceptPrivacy: z.literal(true),
  acceptTerms: z.literal(true),
  acceptNewsletter: z.boolean().default(false),
}).refine(d => d.password === d.passwordConfirm, {
  message: "Passwörter stimmen nicht überein",
  path: ["passwordConfirm"],
})
```

### Nach Registrierung

- Supabase Auth sendet Bestätigungs-E-Mail
- Weiterleitung zu `/verify-email?type=registration`
- Nutzer-Datensatz in `users`-Tabelle mit `role: 'AZUBI'`

---

## `/register/betrieb` – Registrierung Ausbildungsbetrieb

**Zweck:** Eigener Registrierungsflow für Ausbildungsbetriebe

**Rendering:** CSR (Multi-Step-Formular)

### Schritte

```
Schritt 1: Unternehmensangaben
  ├── Unternehmensname
  ├── Branche (Dropdown)
  ├── Ort / PLZ
  └── Website (optional)

Schritt 2: Ansprechpartner
  ├── Vorname, Nachname
  ├── Funktion (z.B. Ausbildungsleiter)
  ├── Geschäftliche E-Mail
  └── Telefon (optional)

Schritt 3: Account-Daten
  ├── Passwort
  └── Passwort wiederholen

Schritt 4: Einwilligungen & Verifizierung
  ├── ✅ Datenschutzerklärung (Pflicht)
  ├── ✅ AGB inkl. B2B-Nutzungsbedingungen (Pflicht)
  └── Info: Betrieb wird nach Registrierung manuell verifiziert (Badge)
```

### Nach Registrierung

- E-Mail-Bestätigung wird versendet
- Betriebsprofil wird als `verified: false` angelegt
- Internes Team erhält Benachrichtigung zur Verifizierung (→ `/intern/ops/verification`)
- Nutzer kann Profil bereits bearbeiten, aber kein „Verifiziert"-Badge sichtbar

---

## `/forgot-password` – Passwort vergessen

**Rendering:** CSR

### Flow

```
1. Nutzer gibt E-Mail ein
2. POST → Supabase Auth: sendPasswordResetEmail()
3. Immer gleiche Erfolgsmeldung, egal ob E-Mail existiert
   → Verhindert Account-Enumeration
4. E-Mail enthält Link mit Token (gültig 60 Minuten)
```

### Wichtig: Gleiche Antwort immer

```ts
// RICHTIG: Keine Information ob E-Mail existiert
return { message: "Falls ein Account existiert, wurde eine E-Mail versendet." }

// FALSCH: Würde Account-Enumeration ermöglichen
if (!user) return { error: "E-Mail nicht gefunden" }
```

---

## `/reset-password` – Passwort zurücksetzen

**Query-Parameter:** `?token=xyz&type=recovery`

**Rendering:** CSR

### Flow

```
1. Token aus URL wird beim Seitenaufruf validiert
2. Ungültiger/abgelaufener Token → Fehlermeldung + Link zu /forgot-password
3. Gültiger Token → Formular: Neues Passwort + Bestätigung
4. Submit → Supabase Auth: updateUser({ password })
5. Weiterleitung zu /login mit Erfolgsmeldung
```

### Validierung

```ts
const resetPasswordSchema = z.object({
  password: z.string()
    .min(8)
    .regex(/[A-Z]/)
    .regex(/[0-9]/),
  passwordConfirm: z.string(),
}).refine(d => d.password === d.passwordConfirm)
```

### Sicherheit

- Token ist einmalig verwendbar (Supabase invalidiert nach Verwendung)
- Ablaufzeit: 60 Minuten
- Nach erfolgreichem Reset: alle aktiven Sessions des Nutzers invalidieren

---

## `/verify-email` – E-Mail-Verifizierung

**Query-Parameter:** `?token=xyz&type=signup|email_change`

**Rendering:** SSR (Token-Verarbeitung server-seitig)

### Flow

```
1. Nutzer klickt Link in der Bestätigungs-E-Mail
2. Server verarbeitet Token via Supabase Auth
3. Erfolg → Weiterleitung zu /dashboard mit Willkommens-Toast
4. Fehler (Token abgelaufen) → Fehlermeldung + "E-Mail erneut senden"-Button
```

### Sonderfälle

- **Token abgelaufen:** Resend-Button sendet neue Bestätigungs-E-Mail
- **E-Mail-Änderung:** Wenn Nutzer E-Mail in Einstellungen ändert, muss neue E-Mail bestätigt werden
- Unverifizierte Accounts können die Plattform lesen, aber **keine Bewertungen schreiben**
