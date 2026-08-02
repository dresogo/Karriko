# Karriko – Statusbericht

**Stand:** 2. August 2026 · Branch `redesign/swiss-style-search-fuer-betriebe`
**Grundlage:** Vollständige Durchsicht von `karriko_flutter/lib`, automatisierter Layout-Sweep über alle 38 Routen in fünf Viewportbreiten, Abgleich Screens ↔ Repositories ↔ Appwrite-Collections.

---

## Kurzfassung

Das Grundgerüst steht: Routing, Auth, Datenmodelle und Repositories sind vorhanden und größtenteils sauber gebaut. Die öffentlichen Seiten sind auf das Swiss-Design umgestellt.

Der Bruch verläuft zwischen **Datenschicht und Oberfläche**. Es existieren Repository-Methoden, die keine einzige Seite aufruft — und es existieren Seiten, die dem Nutzer Erfolg melden, ohne irgendetwas zu speichern. Drei dieser Fälle sind ernst genug, um vor allem anderen behoben zu werden.

Der zweite große Block ist der eingeloggte Bereich: Dashboard, Profil, Analytics, Team, Abo und Berichte sind noch die ursprünglichen Entwürfe — altes Design, feste Layouts, überwiegend erfundene Zahlen.

| Bereich | Zustand |
|---|---|
| Routing & Navigation | weitgehend fertig, zwei verwaiste Seiten |
| Auth (Registrierung, Login, Verifizierung) | funktioniert, Layout bricht auf Mobil |
| Öffentliche Seiten | Design fertig, Inhalte teils statisch |
| Azubi-Bereich | Design alt, ein datenzerstörender Fehler |
| Betrieb-Bereich | überwiegend Attrappe |
| Datenschicht | solide, aber nicht überall angebunden |
| Tests | 54 Tests, nur Login und Blog abgedeckt |

---

## 1. Kritische Fehler

Diese vier täuschen den Nutzer aktiv oder schreiben falsche Daten. Sie sollten vor allem anderen kommen.

### 1.1 Bewertungen werden auf eine nicht existierende Firma geschrieben

`lib/presentation/azubi/new_review_screen.dart:240`

```dart
onTap: () => onSelect('placeholder-id', s),
```

Bei der Betriebsauswahl im Bewertungs-Assistenten wird als Firmen-ID die Zeichenkette `placeholder-id` übergeben. Jede abgesendete Bewertung landet in der Datenbank mit `company_id: 'placeholder-id'` und taucht damit bei keinem Betrieb auf.

**Ursache:** `CompanyRepository.getSearchSuggestions()` gibt nur `List<String>` mit Namen zurück, keine IDs.

**Behebung:** Vorschlagsabfrage auf `List<CompanyModel>` (oder Name+ID-Paare) umstellen und die echte ID durchreichen. Betrifft `company_repository.dart:76`, `company_provider.dart:134` und den Screen.

**Auswirkung:** Kernfunktion der Plattform. Alle bisher erzeugten Bewertungen mit dieser ID sind unbrauchbar und müssen bereinigt werden.

### 1.2 „Konto löschen" löscht kein Konto

`lib/presentation/azubi/settings_screen.dart:110-131`

Der Dialog sagt zu: *„Dein Konto und alle deine Bewertungen werden unwiderruflich gelöscht."* Nach Bestätigung passiert ausschließlich:

```dart
await ref.read(authProvider.notifier).signOut();
if (mounted) context.go('/');
```

`AuthRepository.deleteAccount()` existiert (`auth_repository.dart:196`), wird aber von keiner Stelle aufgerufen.

**Auswirkung:** Der Nutzer glaubt, sein Konto sei gelöscht. Das ist nicht nur ein Bug, sondern berührt Art. 17 DSGVO (Recht auf Löschung). Muss vor Go-Live behoben sein.

### 1.3 Das Unternehmensprofil speichert nicht

`lib/presentation/betrieb/profile_screen.dart:115-120`

```dart
onPressed: () {
  ...
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Profil gespeichert!')));
```

Es wird eine Erfolgsmeldung angezeigt, ohne dass gespeichert wird. `CompanyRepository.updateCompanyProfile()` (`company_repository.dart:86`) wird nirgends aufgerufen. Nach einem Reload sind alle Eingaben weg.

Zum Vergleich: Das Azubi-Profil (`azubi/profile_screen.dart:39`) ruft `updateProfile()` korrekt auf. Nur die Betriebsseite fehlt.

### 1.4 Das Kontaktformular verschickt nichts

`lib/presentation/public/kontakt_screen.dart:31-34`

```dart
void _submit() {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _sent = true);
}
```

Die Bestätigung erscheint, die Nachricht existiert nirgends. Es gibt weder eine Collection noch eine Funktion dafür.

**Behebung:** Entweder eine Appwrite-Collection `contact_messages` plus Repository, oder — als Zwischenlösung — den Formularpfad durch einen `mailto:`-Link ersetzen, der ehrlich ist.

---

## 2. Nicht angebundene Bereiche

### 2.1 Benachrichtigungen

`lib/presentation/azubi/notifications_screen.dart`

- Greift als einziger Screen **direkt** auf Appwrite zu, an der Repository-Schicht vorbei (`Databases(AppwriteService.client)` im Widget).
- Die Collection `'notifications'` steht als Zeichenkette im Code und fehlt in `AppwriteConstants` — es ist unklar, ob sie im Backend überhaupt existiert.
- Kein Fehlerzustand: Schlägt der Client fehl, fliegt die Exception ungefangen durch. Im Testlauf reicht ein nicht initialisierter Client, um den Screen zu sprengen (`LateInitializationError`).
- Es gibt keine Stelle, die Benachrichtigungen **erzeugt**.

**Behebung:** `NotificationRepository` anlegen, Collection in `AppwriteConstants` aufnehmen, über einen Provider mit `AsyncValue` einbinden — wie überall sonst.

### 2.2 Reine Attrappen (erfundene Zahlen)

| Seite | Route | Zustand |
|---|---|---|
| Betrieb-Dashboard | `/betrieb-dashboard` | KPIs (4.2 ⌀, 24 Bewertungen, 1.2k Aufrufe) und Score-Verlauf fest verdrahtet |
| Analytics | `/analytics` | vollständig statisch |
| Team | `/team` | statisch, keine Mitgliederverwaltung |
| Abonnement | `/subscription` | statisch, keine Zahlungsanbindung |
| Blog-Detail | `/blog/:slug` | zeigt für **jeden** Slug denselben Artikel |
| FAQ | `/faq` | statisch (bewusst so gebaut) |
| Blog-Übersicht | `/blog` | statisch, Modell dafür vorbereitet |

Das Betrieb-Dashboard verdient besondere Erwähnung: Ein Betrieb sieht dort Kennzahlen, die nichts mit seinen echten Bewertungen zu tun haben.

### 2.3 Fragebogen speichert keine Antworten

`lib/presentation/azubi/fragen_bewerten_screen.dart`

Die Fragen kommen korrekt aus der Datenbank (bzw. aus dem Platzhalterkatalog). Das Absenden zeigt nur den Fortschritt an — es gibt weder eine Collection für Antworten noch eine Schreibfunktion.

### 2.4 Einstellungs-Schalter ohne Wirkung

`azubi/settings_screen.dart:51-75` — „Öffentliches Profil", „E-Mail-Benachrichtigungen", „Push-Benachrichtigungen" sind reiner lokaler `setState`. Nach Reload alles zurückgesetzt. Dasselbe in den Betriebs-Einstellungen.

### 2.5 Stellenanzeigen sind eine Behelfslösung

`lib/providers/company_provider.dart:146` — der Kommentar sagt es selbst: Die Einträge werden aus Firmendaten abgeleitet, es gibt keine echte Jobs-Collection. `job_model.dart` und `job_card.dart` existieren bereits.

---

## 3. Layout- und Responsive-Fehler

Automatisierter Durchlauf aller 38 Routen in fünf Breiten (1440 / 1200 / 900 / 760 / 375 px), Überlauf-Exceptions mitgeschnitten. **28 Befunde.**

> **Einordnung:** Im Widget-Test steht die Ersatzschrift zur Verfügung, nicht Inter. Deren Glyphen sind breiter, kleine Werte (1–20 px) reproduzieren sich real womöglich nicht. Die großen Befunde sind eindeutig echt.

| Route | Breite | Überlauf |
|---|---|---|
| `/betrieb-dashboard` | 375 | **303 px** rechts (+133 px, +16 px unten) |
| `/dashboard` | 375 | **237 px** rechts |
| `/subscription` | 375 | **224 px** rechts (+4 weitere) |
| `/betrieb-profile` | 375 | **157 px** rechts (+2 weitere) |
| `/kontakt` | 375 | **137 px** rechts |
| `/register/betrieb` | 375 | 154 px rechts (+4 weitere) |
| `/register/azubi` | 375 | 77 px rechts (+3 weitere) |
| `/profile` | 375 | 73 px rechts (+1) |
| `/reports` | 375 | 56 px rechts |
| `/reviews/new` | 375 | 16 px rechts |
| `/register/azubi` | alle | 14 px rechts |
| `/register/betrieb` | alle | 1,5 px rechts |

**Durchgängige Ursache:** `Text` direkt in einer `Row`, ohne `Expanded`/`Flexible`. Beispiel `kontakt_screen.dart:140`:

```dart
Row(children: [
  Icon(icon, size: 18, ...),
  const SizedBox(width: 8),
  Text(label, ...),   // E-Mail-Adresse — bricht nie um
])
```

Dasselbe Muster in Dashboard-Kacheln, Profilzeilen und Abo-Karten. Die Behebung ist mechanisch und gleichförmig.

**Zusätzlich:** `/faq` meldet auf allen Breiten eine Flutter-Warnung — die `ExpansionTile`-Elemente liegen in einer `DecoratedBox` mit Hintergrundfarbe, dadurch bleiben Ripple und Hintergrund unsichtbar. Kosmetisch, aber schnell behoben (eigenes `Material` um die Kacheln).

---

## 4. Design-Konsistenz

Die öffentlichen Seiten (Start, Suche, Für Betriebe, Blog, FAQ, Über uns, Rechtliches, Login) laufen auf dem Swiss-Design: scharfe Ecken, Haarlinien, Papier/Tinte, `ContentBand`-Raster.

**25 Dateien** nutzen noch die alte Formensprache — abgerundete Ecken mit festen Zahlen, `cardShadow`, Farbverläufe, rosa Pillen-Badges:

- **Auth:** `register_azubi`, `register_betrieb`, `forgot_password`, `reset_password`, `verify_email` — diese fünf haben zudem **gar keine Kopfzeile** (`KarrikoAppBar` fehlt), man landet dort ohne Navigation.
- **Azubi:** `dashboard` (Farbverlauf-Banner), `profile`, `bookmarks`, `my_reviews`, `new_review`, `notifications`
- **Betrieb:** alle acht Seiten
- **Öffentlich:** `company_detail`, `review_detail`, `blog_detail`, `kontakt`, `ueber_uns`
- **Gemeinsam:** `review_card`, `job_card` — diese beiden wirken auf viele Seiten gleichzeitig, hier lohnt sich der Anfang

Empfehlung: Reihenfolge `review_card`/`job_card` → Auth → Azubi → Betrieb.

---

## 5. Erreichbarkeit

Zwei Seiten sind ausschließlich über direkte URL-Eingabe erreichbar — kein Link, kein Menüeintrag:

- `/team` (Teamverwaltung) — 0 Verweise
- `/reports` (Bewertungen melden) — 0 Verweise

Beide gehören in den Betriebs-Drawer oder in die Betriebs-Einstellungen.

`/reset-password` hat ebenfalls keine Verweise, das ist aber korrekt so — der Einstieg erfolgt über den E-Mail-Link.

---

## 6. Technische Schulden

- `lib/data/services/supabase_service.dart` — Restdatei der Migration, 2 Zeilen, tote Referenz. Kann weg.
- `AppwriteConstants.verificationUrl` fällt ohne `--dart-define` auf `http://localhost` zurück. In einem Produktions-Build zeigen alle Bestätigungs-E-Mails auf localhost. Muss im Build-Prozess gesetzt werden.
- Repository-Methoden ohne Aufrufer: `deleteAccount`, `updateCompanyProfile`, `isBookmarked`, `getCompanyById`, `updatePassword`, `resendVerificationEmail` — teils Folge der Punkte oben, teils tote Fläche.
- 86 Analyzer-Hinweise (keine Fehler, keine Warnungen) — überwiegend `prefer_const_constructors` und `withOpacity`-Veraltung. Mit `dart fix --apply` weitgehend automatisch behebbar.
- `old_tsx/` und `node_modules/` liegen im Repo-Wurzelverzeichnis.

---

## 7. Tests

Aktuell **54 Tests**, alle grün — aber nur Login-Bereich und Blog abgedeckt (Layout über Viewports, Filter-Deep-Linking, Navigation).

Nicht abgedeckt: Repositories, Provider, Auth-Ablauf, Bewertungs-Assistent, Lesezeichen, sämtliche Betriebsseiten.

Der Layout-Sweep aus diesem Bericht existiert als Technik, aber nicht als dauerhafter Test. Sinnvoll wäre, ihn als Regressionsschutz zu etablieren — sobald die 28 Befunde abgearbeitet sind, kann er scharf gestellt werden.

---

## 8. Vor Go-Live

- Impressum, Datenschutz und AGB enthalten ausschließlich Platzhaltertexte und müssen anwaltlich geprüft werden (steht bereits als Hinweiskasten auf den Seiten).
- Punkt 1.2 (Kontolöschung) ist DSGVO-relevant.
- Kein Cookie-/Consent-Banner vorhanden.
- Keine Fehlerseite mit Design — `errorBuilder` im Router zeigt nur rohen Text auf leerem Scaffold (`router.dart:112`).

---

## 9. Vorgeschlagene Reihenfolge

**Zuerst — Dinge, die Daten zerstören oder den Nutzer täuschen**
1. Firmen-ID im Bewertungs-Assistenten (1.1) + Bereinigung der Altdaten
2. Kontolöschung tatsächlich ausführen (1.2)
3. Unternehmensprofil speichern (1.3)
4. Kontaktformular ehrlich machen (1.4)

**Danach — Substanz**
5. Betrieb-Dashboard und Analytics an echte Bewertungsdaten hängen
6. Benachrichtigungen sauber über Repository und Provider
7. Antworten des Fragebogens speichern
8. Einstellungs-Schalter persistieren

**Parallel — Oberfläche**
9. Die 28 Layout-Überläufe (mechanisch, gleiches Muster)
10. `review_card` und `job_card` auf Swiss-Design, danach Auth-Seiten (inklusive fehlender Kopfzeile)
11. Azubi-Bereich, dann Betrieb-Bereich
12. `/team` und `/reports` verlinken

**Zum Schluss**
13. Fehlerseite gestalten
14. Layout-Sweep als dauerhaften Test etablieren
15. `dart fix --apply`, Migrationsreste entfernen
16. Rechtstexte, Consent, `verificationUrl` im Build
