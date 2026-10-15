# Karriko – Erledigte Aufgaben

**Stand:** 15. Oktober 2026 · **Offenes:** [`aufgaben-offen.md`](aufgaben-offen.md)

Was aus `aufgaben-offen.md` erledigt oder hinfällig ist, steht hier mit Datum, Nummer und Beleg. Neue Einträge kommen oben in die Tabelle, im selben Commit, der den Punkt aus der offenen Liste nimmt. Die Nummern bleiben vergeben und werden nie neu besetzt.

## Seit Einführung der Nummern (T-…)

| Datum | Nummer | Aufgabe | Ergebnis | Beleg |
| --- | --- | --- | --- | --- |
| 15.10.2026 | T-6.20 | README nachziehen: Pakete und Testzahlen | Nachgezählt statt übernommen: 110 Pakete im Lockfile, 661 App-Tests, 287 `questionnaire_core`, 60 `karriko_functions`, 25 Passkey-Dienst, zusammen 1033. W-2.2 und W-2.3 im Factsheet durchgestrichen | dieser Commit |
| 15.10.2026 | T-6.16 | „Bewerten“ auf dem Unternehmensprofil ohne `?company=` | Beide Knöpfe („Betrieb bewerten“, „Jetzt bewerten“) öffnen `/reviews/new?company=<id>`, Test `company_detail_bewerten_test.dart` | dieser Commit |
| 15.10.2026 | T-4.17 | `security.txt` und Meldestelle für Schwachstellen | `karriko_flutter/web/.well-known/security.txt` nach RFC 9116, Kontakt über GitHubs private Schwachstellenmeldung, `SECURITY.md` als Policy. `tools/build_web.dart` bricht ab, wenn die Datei fehlt, kein `Contact` hat oder abgelaufen ist. Rest offen als T-4.28 | dieser Commit |
| 15.10.2026 | T-1.14 | `notes/` aufräumen: zusammenführen, Erledigtes ins Archiv | `APPWRITE_EINSPIELEN.md` in `APPWRITE_SETUP.md` eingearbeitet (Kapitel 15 und 16 neu, `push table` gemäß E-05 ersetzt). Abweichungen A1–A15 und Entscheidungen vom 21.09. nach `UMSETZUNG_BERICHT.md` übernommen. `PLAN_FRAGEBOGEN.md`, `APPWRITE_EINSPIELEN.md` und beide Berichte aus `reports/` liegen in `archiv/`. Export-Ziel des Lösch-Werkzeugs jetzt `notes/exporte/`. Factsheet gemergt und nachgezogen. Neu aufgenommen: T-4.27, T-7.9 | Commits vom 15.10. |
| 15.10.2026 | T-1.8 | `APPWRITE_EINSPIELEN.md` nachziehen | In `APPWRITE_SETUP.md` aufgegangen: Skriptweg statt `push table`, öffentliche Function-Domains, Aufruf der Moderation über den Admin-Bereich oder ein JWT, `ID.unique()`, CLI nur aus `appwrite/`, `--file` statt `--path` beim Upload | mit T-1.14 |
| 15.10.2026 | T-1.13 | Aufgabenlisten zusammenführen | `notes/todo.md` und der Tab „Offene Aufgaben“ sind in `aufgaben-offen.md` und diese Datei überführt; der Tab spiegelt nur noch. Dabei T-2.31, T-4.25, T-4.26 und T-8.10 neu aufgenommen | `411aa1e` |
| 13.10.2026 | T-7.5 | Schriftskalierung 1,3 in allen Layout-Testdateien | Fand 26 Fälle, drei Ursachen behoben, dazu ein neuer Test für die Startseite | `84c8472` |
| 13.10.2026 | T-7.4 | Stellen testen: Formular ohne Titel, Entwurf nicht öffentlich, Zeilenaufteilung | `jobs_test.dart`. Dabei gefunden und behoben: Entwürfe waren öffentlich lesbar. Die Tabellenrechte in Appwrite stehen als T-4.26 offen | `679bf77` |
| 13.10.2026 | T-6.15 | `presentation/common/job_card.dart` entfernen | Entfernt | `8fdbf40` |
| 13.10.2026 | T-6.13 | Flutter-Web bedienbar machen | Text auswählbar, Hand-Cursor, ruhige Seitenwechsel | PR #11, `52a04c9` |
| 13.10.2026 | T-6.12 | Prüfen, ob `review_card` noch offen ist | Hinfällig: `ReviewCard` und `StarRating` sind entfernt | – |
| 13.10.2026 | T-6.10 | Fehlerseite gestalten | `not_found_screen.dart` mit Test | PR #13, `0ae9ac9` |
| 13.10.2026 | T-6.9 | Blog-Detail zeigt für jeden Slug denselben Artikel | Hinfällig, war schon behoben; Test „Jeder Artikel zeigt seinen eigenen Text“ | – |
| 13.10.2026 | T-6.3 | Attrappen für Analytics, Team und Abonnement ausblenden | Kacheln, Einstellungen und Menü weg, die Routen führen aufs Dashboard | `fe561f2`, `88d47e2` |
| 13.10.2026 | T-6.1 | Kopfzeilen-Überlauf bei vergrößerter Systemschrift | Der Umbruchpunkt wächst mit der Schrift; eigener Test für 14 Breiten × 4 Schriftgrößen | `0925f15` |
| 13.10.2026 | T-4.13 | OSV-Scanner und Dependabot | Dependabot für pub, npm und github-actions; OSV-Scanner prüft alle Lockfiles | `c244b50`, PR #13 |
| 13.10.2026 | T-4.12 | `flutter pub get --enforce-lockfile` in der CI | Gesetzt, auch für Pakete und Functions | `c244b50` |
| 13.10.2026 | T-4.11 | GitHub Actions auf Commit-Hashes festnageln | Festgenagelt, `permissions: contents: read`, `persist-credentials: false` | `c244b50` |
| 13.10.2026 | T-4.10 | Ungenutzte Pakete entfernen | Sieben entfernt; `dio` und `cached_network_image` sind inzwischen in Gebrauch. 152 → 107 Pakete | `8fdbf40` |
| 13.10.2026 | T-4.8 | Google Fonts lokal einbetten | Inter 4.1 Regular als Asset, `google_fonts` entfernt. Die Noto-Ersatzschrift lädt weiter von `fonts.gstatic.com`, offen als T-5.26 | PR #13, `0ae9ac9` |
| 13.10.2026 | T-4.7 | Web-Build mit `--no-web-resources-cdn` | `dart run tools/build_web.dart <APP_ORIGIN>` setzt das Flag immer und prüft den Build | PR #13, `0ae9ac9` |
| 13.10.2026 | T-3.11 | Nachweisen, dass unbestätigte Konten nicht bewerten können | Der Nachweis ergab eine Lücke; `submit_review` prüft jetzt selbst (403). Wirkt erst nach dem Deployment, offen als T-2.31 | `2dcb9eb` |
| 13.10.2026 | T-1.12 | Repository-Methoden ohne Aufrufer klären | `isBookmarked` entfernt, `getCompanyById` ist inzwischen in Gebrauch | `b042072` |
| 13.10.2026 | T-1.6 | `old_tsx/` aus `main` entfernen | Entfernt, die Historie behält den Code | `434462b` |

## Vor Einführung der Nummern (aus `notes/todo.md`)

Diese Punkte waren schon erledigt, bevor die Liste T-Nummern bekam. Die Nummer ist der alte Abschnitt in `notes/todo.md`. „Statusbericht“ meint `archiv/status-report-2026-08-02.md`.

| Datum | Nummer | Aufgabe | Ergebnis | Beleg |
| --- | --- | --- | --- | --- |
| 02.10.2026 | todo A | Appwrite-Schema einspielen | Sechs Tabellen, zwei Ablagen, zwei Teams, sieben Functions und die Fragendefinition eingespielt, über `node tools/appwrite-setup.mjs --fix-permissions` statt `appwrite push table/bucket`. `--dry-run` meldet keine Abweichung, alle Functions `ready` auf `dart-3.11`. Die Function-Domains unter `*.appwrite.network` halten sich an `execute` | `35b1b22` |
| 02.10.2026 | todo B7 | Antworten des Fragebogens speichern | Eigene Tabelle `reviews` mit Rohantworten, getrennte `public_reviews`, serverseitige Auswertung, Moderation, Aggregation nach `company_scores` | Statusbericht 14.1 |
| 02.10.2026 | todo D | `companies`: `update("users")` entfernen, Row Security einschalten | Tabellenrechte nur noch `read("any")` und `create("users")`, `rowSecurity: true`. Die Testzeile „Test GmbH“ ist seitdem nicht mehr bearbeitbar | `archiv/APPWRITE_EINSPIELEN.md` §9 |
| 02.10.2026 | todo C | `http://localhost:8080` als Web-Plattform | Hinfällig, Plattform „Karriko Web“ bestand seit Juni; Appwrite vergleicht nur den Hostnamen | – |
| 29.09.2026 | todo B2 | Echte Firmen-ID im Bewertungs-Assistenten | Strecke ersetzt: `review_repository.dart` entfällt, `submit_review` setzt `company_id` und `user_id` serverseitig. `reviews` hatte null Zeilen, keine Altdaten. Damit auch der Teil aus todo D zu Rechten aus einem client-übergebenen `authorId` geschlossen | Statusbericht 14.3 |
| 31.08.2026 | todo G | Über die Ausbildungsbörse entscheiden | Sie kommt: eigene Tabelle `jobs`, Betriebe schreiben Stellen selbst aus, eigene Stellenseite | Statusbericht 13.3, 13.4 |
| 31.08.2026 | todo B1c | Tabelle `jobs` anlegen | Mit allen Spalten, Indizes und Rechten über `tools/appwrite-setup.mjs` | Statusbericht 13 |
| 31.08.2026 | todo B1b | Schema in der Console nachziehen | `companies.owner_id` mit Index, eindeutiger Index auf `slug`, `profiles.company_id`, Create-Recht auf `companies`; über `tools/appwrite-setup.mjs`. Die `owner_id` der „Test GmbH“ bewusst von Hand eingetragen | `7dcb7b3` |
| 30.08.2026 | todo B1 | `companies`-Dokument bei der Betriebsregistrierung anlegen | `registerBetrieb()` legt die Firma an, `ensureCompany()` repariert Altkonten über `owner_id`. Der Slug bleibt bei Umbenennung stehen, kein Löschrecht am Firmendokument | Statusbericht 2.3 |
| 30.08.2026 | todo A | Zugangsdaten-Zeile aus der Git-Historie klären | Kein Konto dahinter. Die Zeile stand 26 Tage im öffentlichen `main`; per `git filter-repo --replace-text` entfernt, Force-Push von `main` und `feat/anmeldeverfahren`. Der Purge bei GitHub ist als T-1.5 offen | Statusbericht 7.10 |
