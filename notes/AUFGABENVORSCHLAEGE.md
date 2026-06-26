# Aufgabenvorschläge aus Codebasis-Review

## 1) Aufgabe: Tippfehler korrigieren
**Problem:** In einem Server-Kommentar steht „über namen“ statt „über Namen“.

**Fundstelle:** `server.js` in der Kommentarzeile vor dem Query auf `companies`.

**Vorschlag:**
- Kommentar sprachlich korrigieren (`namen` → `Namen`), damit die Entwicklerdoku konsistent und professionell bleibt.

**Akzeptanzkriterien:**
- Der Kommentar ist orthografisch korrekt.
- Keine Laufzeitlogik wurde verändert.

---

## 2) Aufgabe: Programmierfehler beheben (Input-Validierung `limit`)
**Problem:** `GET /api/reviews` übernimmt `limit` mit `parseInt`, validiert den Wert aber nicht auf `NaN`, Bereich oder negative Werte.

**Risiko:**
- Ungültige Query-Parameter können zu SQL-Fehlern oder unerwartetem Verhalten führen.

**Vorschlag:**
- `limit` robust validieren (z. B. `Number.isInteger(limit)`, Mindestwert 1, Höchstwert z. B. 100).
- Bei ungültigem Wert mit `400 Bad Request` und klarer Fehlermeldung antworten.

**Akzeptanzkriterien:**
- `?limit=abc`, `?limit=-1`, `?limit=0` liefern `400`.
- `?limit=6` liefert weiterhin `200` mit maximal 6 Einträgen.

---

## 3) Aufgabe: Kommentar-/Doku-Unstimmigkeit korrigieren
**Problem:** Die Endpoint-Nummerierung ist inkonsistent: Sowohl Social-Login als auch Review-Posting sind mit „6.“ kommentiert.

**Risiko:**
- Erschwerte Orientierung bei Wartung, Review und Onboarding.

**Vorschlag:**
- Kommentar-Nummerierung der API-Abschnitte konsistent fortführen (z. B. Reviews als „7.“).
- Optional: Abschnittsübersicht am Datei-Anfang ergänzen.

**Akzeptanzkriterien:**
- Eindeutige, durchgängige Nummerierung über alle Endpoint-Kommentare.
- Keine Änderung am API-Verhalten.

---

## 4) Aufgabe: Tests verbessern (API-Regressionstests)
**Problem:** Es gibt aktuell keine Test-Skripte in `package.json` und keine automatisierten API-Tests.

**Risiko:**
- Hohe Gefahr, dass Validierungs- und Sortierlogik unbemerkt regressiert.

**Vorschlag:**
- Test-Setup ergänzen (z. B. Jest + Supertest).
- Mindestens folgende Fälle automatisieren:
  1. `GET /api/reviews` validiert `limit` korrekt.
  2. `GET /api/companies?search=` liefert erwartete Struktur (`review_count`, `avg_rating`).
  3. `POST /api/register` blockt doppelte E-Mail.

**Akzeptanzkriterien:**
- `npm test` ist vorhanden und läuft lokal durch.
- Die drei genannten Kernfälle sind als Tests implementiert.
