# Karriko – Offene Aufgaben

**Stand:** 18. Oktober 2026 · **Erledigtes:** [`aufgaben-erledigt.md`](aufgaben-erledigt.md)

154 Aufgaben sind offen, 72 davon blockieren den Launch. Die meisten P1-Punkte liegen bei Datenschicht, Anmeldung und Recht.

Diese Datei und `aufgaben-erledigt.md` sind die einzige Aufgabenliste des Projekts. Sie ersetzen `notes/todo.md` (bis Commit `679bf77` in der Historie) und den Tab „Offene Aufgaben“ im Plan-Dokument, der seitdem nur noch diese Datei spiegelt. Neue Aufgaben kommen hierher, nicht in Berichte oder neue Todo-Dateien.

## Regeln

- **Nummern:** `T-<Abschnitt>.<laufende Nummer>`. Eine Nummer bleibt fest und wird nie neu vergeben. Neues bekommt die nächste freie Nummer seines Abschnitts, ein neuer Abschnitt die nächste freie Abschnittsnummer.
- **Erledigt:** Den Punkt hier löschen und in `aufgaben-erledigt.md` oben in die Tabelle eintragen: Datum, Nummer, Aufgabe, Ergebnis, Beleg (Commit oder PR). Beides im selben Commit, damit die Änderung nachvollziehbar bleibt.
- **Teilweise erledigt:** Der Punkt bleibt hier, darunter eine Zeile „Teilweise erledigt am …“ mit dem, was noch fehlt.
- **Hinfällig:** Wie erledigt behandeln, im Ergebnis steht „hinfällig“ und der Grund.
- **Prioritäten:** P1 blockiert den Launch, P2 gehört in die ersten drei Monate nach dem Start, P3 kommt später.
- **Herkunft** in der Klammer am Ende: todo = ehemals `notes/todo.md` mit Abschnitt, Referenz = `projekt-referenz.md`, Setup = `APPWRITE_SETUP.md`, Plan = Tab Sicherheitsplan, andere Tabnamen = der jeweilige Tab im Plan-Dokument, Chat = Gespräch mit Claude, neu = eigene Recherche.

## Vorgeschlagene Reihenfolge für die P1-Punkte

1. Notizen privat stellen, gitleaks einrichten
2. Staging und Produktion trennen, Backups mit Restore-Test
3. `submit_review` deployen, Moderationskonto anlegen und Abnahmetest mit den vier Personas
4. Rollen serverseitig, Row Security, Feld-Whitelist für Betriebe, „Anonymous“ aus
5. Kontolöschung, Löschverlangen für Bewertungen, Datenexport
6. Unternehmensform, Steuerberater, Versicherung, Marke
7. Anwalt: Rechtstexte, acht Punkte der Bewertungsstrecke, DSFA, Datenschutzbeauftragter, DSA-Verfahren
8. Auslieferung: Domain, SMTP, `rpId`, CSP (CDN aus und Schriften lokal sind erledigt)

## 1 · Repository und Projektorganisation

- [ ] T-1.1 · P1 · Interne Notizen (Todo-Liste, Berichte) in ein privates Repo verschieben oder das Repo auf privat stellen (Chat)
- [ ] T-1.3 · P1 · Branch `fragebogen` mit Pull Request #9 abschließen und mergen (todo)
- [ ] T-1.4 · P2 · GitHub Student Developer Pack aktivieren, damit Branch Protection auch im privaten Repo greift (Chat)
- [ ] T-1.5 · P2 · Unerreichbaren Commit `9d25f8d` beim GitHub-Support purgen lassen (todo A)
  GitHub hält den alten Commit per SHA weiter abrufbar. Hier verzichtbar, weil der Wert bedeutungslos war, aber beim nächsten echten Fund ist das der Schritt, der vergessen wird.
- [ ] T-1.7 · P2 · SonarCloud Automatic Analysis abschalten (todo H)
- [ ] T-1.9 · P2 · `projekt-referenz.md` auf den aktuellen Stand bringen: Die Börse ist entschieden, Löschmodell und Gewichtung stammen noch aus der alten Strecke (neu)
- [ ] T-1.10 · P3 · Lizenz festlegen oder bewusst ohne Lizenz bleiben (README)
- [ ] T-1.15 · P2 · Entscheiden, was mit den lokalen Exporten `notes/claude_plan/` und `notes/Karriko Sitemap.html` passiert: committen (dann öffentlich, darunter Anwaltsfragen, Notfallplan, CEO-Routinen und eine Geschäftsidee), per `.gitignore` lokal halten oder nach git-crypt in `notes/intern/` (Chat)
  Bis dahin nicht eingecheckt; sie erscheinen deshalb als ungespeicherte Änderung. Hängt mit T-1.1 zusammen.

## 2 · Datenschicht und Funktionen

- [ ] T-2.1 · P1 · Staging- und Produktionsprojekt in Appwrite trennen (Plan)
- [ ] T-2.2 · P1 · Automatische Backups plus externer Export, Restore einmal testen (Plan, README zum 4. Oktober)
- [ ] T-2.3 · P1 · Eigenes Moderations- und Admin-Konto anlegen, nicht eines der Testkonten (todo A)
- [ ] T-2.4 · P1 · Abnahmetest mit den vier Personas, inklusive JWT-Weg für `moderate_review` und `recompute_all` (todo A, Setup §13)
  Die CLI läuft als Console-Konto und bekommt von `moderate_review` und `recompute_all` eine 401. Der einfachste Weg ist der Admin-Bereich unter `/#/admin` mit dem Moderationskonto, sonst ein JWT für dieses Konto (Setup §13).
- [ ] T-2.5 · P1 · API-Schlüssel nach der Abnahme löschen und in der Console widerrufen (todo A)
  Die Datei unter `karriko_local/` löschen und den Schlüssel widerrufen, nicht nur ablaufen lassen.
- [ ] T-2.6 · P1 · Testzeilen in `companies` löschen, darunter die verwaiste „Test GmbH“ (Setup §11)
- [ ] T-2.7 · P1 · `profiles.last_name` von 10 auf 100 Zeichen erweitern (todo D)
  Der einzige Befund des Datenbank-Abgleichs, der jemanden beim Registrieren kostet.
- [ ] T-2.8 · P1 · Kontolöschung als Function nach Art. 17 DSGVO, Reihenfolge nach Referenz §3.3 (todo B3)
- [ ] T-2.9 · P1 · Löschverlangen für einzelne Bewertungen, inklusive der Zeile in `public_reviews` (todo G, Setup §12)
  Größte offene Lücke der Bewertungsstrecke: `public_reviews` trägt absichtlich keine `user_id`. Braucht wie T-2.8 eine Function, die mit Schlüssel löscht.
- [ ] T-2.10 · P1 · Datenexport nach Art. 20 DSGVO als JSON (todo H)
- [ ] T-2.12 · P2 · Betriebs-Dashboard und Analytics an `company_scores`, mit Erklärung unter drei Bewertungen (todo B5)
  `company_scores` trägt erst ab drei Bewertungen einen Wert, Zahlen erscheinen erst ab fünf und nur in Spannen. Ein leeres Dashboard ist dann richtig und muss das erklären.
- [ ] T-2.13 · P2 · Benachrichtigungen über Repository und Provider, Stellen bauen, die sie erzeugen, Fehlerzustand statt `LateInitializationError` (todo B6)
  Heute erzeugt keine Stelle Benachrichtigungen; ohne initialisierten Client kommt `LateInitializationError`.
  Am 18.10.2026 nach E-30 ausgeblendet: Die Tabelle `notifications` steht weder in der Vorlage noch in `appwrite.config.json`. Menüeintrag entfernt, `/notifications` führt aufs Dashboard, `notifications_screen.dart` gelöscht (in der Historie bis `3c90891`). Zum Bau gehören jetzt auch Tabelle, Seite und die Schalter aus T-2.14.
- [ ] T-2.16 · P2 · Eine Quelle für Profildaten festlegen: `profiles` oder Account-Prefs (todo D)
- [ ] T-2.17 · P2 · Eindeutige Indizes auf `bookmarks(user_id, company_id)` und `review_reports(review_id, reporter_id)` (todo D)
- [ ] T-2.18 · P2 · `jobs`: Pflichtfelder `company_id`, `title`, `is_active` und Formatprüfungen für E-Mail und URLs (todo D)
- [ ] T-2.19 · P2 · `companies.average_rating` und `review_count` mit Wertgrenzen neu anlegen, solange es nur Testdaten gibt (Setup §4a)
- [ ] T-2.20 · P2 · Nachweise für die Moderation über eine Function anzeigen statt nur in der Console (Setup §12)
- [ ] T-2.21 · P2 · Nach `recompute_all` die betroffenen Betriebe automatisch neu aggregieren (Setup §6)
- [ ] T-2.22 · P2 · Specification der Functions festlegen und in die Vorlage eintragen (Setup §6)
- [ ] T-2.23 · P2 · Löschmodell der Referenz (`deleted_at`, Nutzer-ID bleibt bei anonymen Bewertungen) mit Art. 17 und der neuen Strecke abgleichen (Referenz §2.5, neu)
- [ ] T-2.24 · P3 · Betriebskonto löschen: Profil inaktiv, 30 Tage reaktivierbar, Antworten löschen (Referenz §3.4)
- [ ] T-2.25 · P3 · Profilaufrufe zählen, ohne festzuhalten, wer zugesehen hat (Referenz §3.4)

- [ ] T-2.26 · P1 · Betrieb vorschlagen, wenn er im Fragebogen nicht gefunden wird: Formular, Dublettenprüfung, Freigabe durch die Moderation. Heute endet die Suche mit „dann lässt er sich hier noch nicht bewerten“ (Sitemap)
- [ ] T-2.27 · P1 · Profil beanspruchen: Ein Betrieb übernimmt ein vorgeschlagenes Profil, statt bei der Registrierung ein zweites anzulegen, mit menschlicher Prüfung (Sitemap)
- [ ] T-2.28 · P2 · Admin-Bereich „Nutzer“: Konto suchen, sperren, Rollenfehler beheben; Referenz §1.2 verlangt eine Benutzerverwaltung (Sitemap)
- [ ] T-2.29 · P2 · Admin-Bereich „Anfragen“: ein Eingang für Kontaktformular, Auskunfts- und Löschverlangen und Beanstandungen von Betrieben (Sitemap)
- [ ] T-2.30 · P2 · Vollständige Berufsliste der BA mit `tools/import_berufe.dart` einspielen, heute stehen rund 40 Beispielberufe in der Suche (Plan Fragebogen A12)
- [ ] T-2.31 · P1 · `submit_review` neu deployen (vorher `dart run tools/vendor_core.dart`): Erst dann gelten die Prüfung auf bestätigte Adresse (403) und das Limit von 3 Bewertungen je 24 h (429). Danach mit einem unbestätigten Testkonto gegenprüfen (Export 13.10.)

## 3 · Anmeldung und Konten

- [ ] T-3.1 · P1 · Rollen serverseitig über Teams oder Labels setzen, Prefs nur noch zur Anzeige (todo D)
- [ ] T-3.2 · P1 · Ungenutzte Anmeldeverfahren abschalten, zuerst „Anonymous“ (todo D)
- [ ] T-3.3 · P1 · Anmeldung des Betriebs-Testkontos klären (`user_invalid_credentials`) (todo C)
  Prüfreihenfolge: Projekt-ID (`6a3c45ef003356d7f16d`, Frankfurt)? Hat das Konto überhaupt einen Passwort-Faktor oder entstand es über OAuth, Magic Link, Passkey? Schnellster Test: neues Passwort in der Console setzen.
- [ ] T-3.4 · P1 · MFA in der Console einschalten (Auth → Security) (todo C)
- [ ] T-3.5 · P1 · MFA verpflichtend für Admin- und Moderationskonten (Plan)
- [ ] T-3.6 · P1 · SMTP mit EU-Standort, SPF, DKIM, DMARC und deutschen Vorlagen (todo C)
- [ ] T-3.7 · P1 · `karriko.de` als Web-Plattform eintragen, `APP_ORIGIN` im Produktions-Build setzen (todo C, D)
- [ ] T-3.8 · P1 · Passkey-`rpId` auf die Produktionsdomain festlegen, bevor echte Nutzer Passkeys anlegen; nachträglich nicht migrierbar (README)
- [ ] T-3.9 · P1 · Passwortregel auf Länge umstellen, Password Dictionary und Personal Data Check einschalten (Plan; Referenz nennt noch 8 Zeichen)
- [ ] T-3.10 · P1 · Ratenbegrenzungen aus der Referenz umsetzen oder nachweisen: 3 Bewertungen je 24 h, 5 Meldungen je Betrieb und 24 h, 5 Login-Versuche je IP und Minute (Referenz §2.4)
  Teilweise erledigt am 13.10.2026: 3 Bewertungen je 24 h in `submit_review` (`64c8973`, wirkt nach T-2.31). Offen: Meldungen je Betrieb (laufen direkt in die Tabelle, bräuchten eine Function) und Login-Versuche (Appwrite-Einstellung).
- [ ] T-3.12 · P1 · Nach Passwort-Reset alle Sitzungen beenden, Reset-Link nach 60 Minuten ungültig (Referenz §3.2)
- [ ] T-3.13 · P2 · E-Mail-Änderung nur mit erneuter Bestätigung (Referenz §3.3)
- [ ] T-3.14 · P2 · Sitzungsdauer und Zahl gleichzeitiger Sitzungen begrenzen (Plan)
- [ ] T-3.15 · P2 · Gegen die echte Instanz durchspielen: Registrierungen, Bestätigungsmail, Reset, Realtime-Kanal, Magic Link doppelt öffnen, Social Login in Chrome, Safari und Firefox, Passkeys auf zwei Plattformen, alle TOTP-Pfade (todo C)
- [ ] T-3.16 · P2 · Passkey-Dienst fertigstellen: Tabellen ohne Berechtigung, Schlüssel nur `users.read` und `users.write`, Ratenbegrenzung, abgelaufene Challenges aufräumen, als Function deployen (todo C)
  Tabellen `passkeys` und `webauthn_challenges` ohne jede Berechtigung, Felder und Indizes in `services/passkey-rp/README.md`. Als Appwrite Function, damit kein zweiter Auftragsverarbeiter entsteht.
- [ ] T-3.17 · P2 · Google freischalten, Logo als Asset statt zur Laufzeit geladen (todo C)
  Die von Google gelieferte Datei nach `assets/icons/`, nicht zur Laufzeit nachladen. Vor dem Start zwingend. Die Schritte in der Google Cloud Console (Redirect-URI aus der Appwrite Console kopieren, nicht abtippen) stehen in `archiv/status-report-2026-08-02.md` §9.9.
- [ ] T-3.18 · P3 · Apple freischalten (kostenpflichtiges Developer-Programm, Domain-Verifikation) (todo C)
- [ ] T-3.19 · P3 · Nach der Freischaltung mit `OAUTH_ENABLED=true` bauen (todo C)

## 4 · Sicherheit, Rechte und Lieferkette

- [ ] T-4.1 · P1 · Row Security für `bookmarks` und `profiles`, Zeilenrechte nur für den Eigentümer (todo D)
  `bookmarks` und `profiles` stehen auf `rowSecurity: false`. Je nach Tabellenrechten liest jeder angemeldete Nutzer Merklisten und Profile aller anderen. Das Setup-Skript fasst beide nicht an.
- [ ] T-4.2 · P1 · Profiländerungen von Betrieben über eine Function mit Feld-Whitelist, damit `is_verified`, `is_premium` und `average_rating` gesperrt sind (todo D, Setup §4a)
  Appwrite kennt keine Rechte je Spalte. Das Abzeichen soll laut Referenz §3.2 ein Mensch vergeben.
- [ ] T-4.3 · P1 · Betriebssperre serverseitig verankern (todo D)
- [ ] T-4.4 · P1 · Rechte aller Tabellen in der Console gegen das Soll prüfen (todo D)
- [ ] T-4.5 · P1 · Je Function ein eigener Schlüssel mit minimalen Scopes, Liste aller Schlüssel mit Zweck und Ablaufdatum (Plan)
- [ ] T-4.6 · P1 · Salz für den Gerätehash zusätzlich im Passwortmanager ablegen (todo A)
  Liegt lokal in `appwrite/functions/submit_review/.env` (gitignored).
- [ ] T-4.9 · P1 · Content-Security-Policy und Security-Header setzen, offen seit dem ZAP-Scan vom 1. Juni (S2, Referenz §4.3)
  Voraussetzungen erledigt (T-4.7, T-4.8). `'wasm-unsafe-eval'` und der Appwrite-Endpunkt in `connect-src` sind Pflicht; die Noto-Ersatzschrift lädt noch von `fonts.gstatic.com` (T-5.26). Im Browser gegentesten, eine zu strenge CSP zeigt eine weiße Seite.
- [ ] T-4.14 · P2 · Protokollierung kritischer Aktionen ohne personenbezogene Daten in Logs (Plan, Referenz §4.1)
- [ ] T-4.15 · P2 · Verfügbarkeitsüberwachung für das Ziel 99,9 % (Referenz §5, neu)
- [ ] T-4.16 · P2 · Notfallplan auf einer Seite: Entwurf steht im Tab Notfallplan (Plan)
- [ ] T-4.18 · P2 · Erkennung gefälschter Bewertungen: gleicher Gerätehash, kurze Bearbeitungszeit, Häufung (Plan)
- [ ] T-4.19 · P2 · Uploads von Logos und Bildern: MIME-Typ serverseitig prüfen, Größe begrenzen (Referenz §3.4)
- [ ] T-4.20 · P3 · Admin-Bereich als eigener Build unter eigener Subdomain (Plan)
- [ ] T-4.21 · P3 · Ein Team je Betrieb, sobald Team und Analytics echt sind (Plan)
- [ ] T-4.22 · P3 · Externer Penetrationstest nach OWASP ASVS (Plan)
- [ ] T-4.23 · P3 · ISMS-Grundlagen: Risikoliste und Erklärung zur Anwendbarkeit (Plan)

- [ ] T-4.24 · P2 · Major-Updates als eigene Migration mit Tests: `flutter_riverpod` 3, `go_router` 18, `cached_network_image` 4, `flutter_lints` 6; der Sammel-PR #16 wurde deshalb geschlossen (Factsheet E-11)
- [ ] T-4.25 · P1 · `create("users")` auf `users/verified` umstellen, wo nur bestätigte Konten schreiben sollen: `review_reports`, `review_drafts`, `companies`, `bookmarks` u. a.; Vorlage, `appwrite-setup.mjs` und Console gemeinsam (Export 13.10.)
- [ ] T-4.26 · P1 · Tabelle `jobs`: `read("any")` auf Tabellenebene entfernen (`node tools/appwrite-setup.mjs --fix-permissions`), erst nach Auslieferung der App; alte Entwürfe einmal veröffentlichen und zurückziehen (Export 13.10., Folge aus `679bf77`)
- [ ] T-4.27 · P3 · Projekt- und Datenbank-ID aus `appwrite_constants.dart` über `--dart-define` beziehen wie die übrigen Kennungen. Kein Geheimnis, sie stehen ohnehin im ausgelieferten Web-Bundle, aber ein Staging-Projekt (T-2.1) braucht sie umschaltbar (`UMSETZUNG_BERICHT.md` §12)
- [ ] T-4.28 · P2 · `security.txt` fertigstellen: auf dem Server mit `Content-Type: text/plain; charset=utf-8` ausliefern und prüfen, bei `--base-href /app/` an die Wurzel der Domain legen, OpenPGP-Signatur (RFC 9116 §2.3) und `Expires` vor dem 15.04.2027 verlängern (neu)

## 5 · Datenschutz und Recht

Die Punkte mit „neu“ sind Hinweise, keine Rechtsberatung. Sie gehören auf die Liste für das Gespräch mit dem Anwalt.

- [ ] T-5.1 · P1 · Impressum, Datenschutzerklärung und AGB anwaltlich erstellen lassen, derzeit nur Platzhalter (todo H)
- [ ] T-5.2 · P1 · Acht Punkte der Bewertungsstrecke juristisch prüfen: Fristen für Nachweise, Entwürfe, Rohantworten, Gerätehash und Export, Lösch- und Auskunftsverlangen, Fragebogentexte (todo G, Setup §12)
- [ ] T-5.3 · P1 · Fünf Platzhalter im Fragebogen ersetzen: Entwürfe stehen im Tab Fragebogen, danach Prüfung durch den Anwalt und Ausrollen als neue Version (todo G)
  Schlüssel: `anonymity.intro`, `anonymity.sensitive`, `legal.verifikation`, `help.anlaufstellen[0]` und `[2]` (`grep -n PLATZHALTER karriko_flutter/assets/questionnaire/questionnaire_v1.json`). Danach `dart run tools/sync_questionnaire.dart`, neue Version nach `APPWRITE_SETUP.md` §10.
- [ ] T-5.4 · P1 · Löschkonzept nach DIN 66398: Entwurf steht im Tab Löschkonzept, offen ist die Prüfung durch den Anwalt (Plan)
- [ ] T-5.5 · P1 · Datenschutz-Folgenabschätzung erstellen; laut Prüfung Pflicht, Bewertungsportale stehen auf der Muss-Liste (Tab DSFA-Prüfung)
- [ ] T-5.6 · P1 · Externen Datenschutzbeauftragten benennen und der Aufsicht melden; Pflicht nach § 38 BDSG, weil eine DSFA nötig ist (Tab DSFA-Prüfung)
- [ ] T-5.7 · P1 · Verzeichnis der Verarbeitungstätigkeiten nach Art. 30 DSGVO: Entwurf steht im Tab Verarbeitungsverzeichnis, offen sind Verantwortlicher und Prüfung durch den Anwalt (neu)
- [ ] T-5.8 · P1 · AVV mit Appwrite, dem Hosting-Anbieter, SMTP-Anbieter, Google und Apple (todo H)
- [ ] T-5.9 · P1 · Consent-Banner nur, wenn nicht notwendige Dienste laufen; sonst bewusst verzichten und das dokumentieren (todo H, neu)
- [ ] T-5.10 · P1 · Melde- und Abhilfeverfahren nach dem Digital Services Act: Meldeweg für rechtswidrige Inhalte, begründete Entscheidungen, Kontaktstelle (neu)
- [ ] T-5.11 · P1 · Verfahren für Betriebe, die eine Bewertung beanstanden: Prüfung mit Rückfrage beim Verfasser, wie es die Rechtsprechung zu Bewertungsportalen verlangt (neu)
- [ ] T-5.12 · P1 · Anonymität absichern: Mindestzahl für sichtbare Einzelbewertungen, Angaben vergröbern, Veröffentlichung zeitlich streuen (Plan)
- [ ] T-5.13 · P2 · Vollständige Auskunft nach Art. 15 DSGVO, über `my_reviews` hinaus (Setup §12)
- [ ] T-5.14 · P2 · TOM-Dokument nach Art. 32 DSGVO (Plan)
- [ ] T-5.15 · P2 · Transparenzpflichten prüfen lassen: ob Premium Ranking oder Darstellung beeinflusst und wie die Echtheit der Bewertungen geprüft wird (neu)
- [ ] T-5.16 · P3 · Rechtstexte für Österreich und die Schweiz, oder den Start zunächst auf Deutschland beschränken (Referenz §1.1)

- [ ] T-5.17 · P1 · Ausdrückliche, gesonderte Einwilligung am Tor vor dem Konfliktmodul (Art. 9 DSGVO) (Verarbeitungsverzeichnis)
- [ ] T-5.18 · P1 · Umgang mit Nutzern unter 16 klären: Mindestalter, Zustimmung der Eltern oder andere Rechtsgrundlage (Verarbeitungsverzeichnis)
- [ ] T-5.19 · P1 · IP-Adressen in Appwrite-Sitzungen in der Datenschutzerklärung richtig darstellen, Speicherung möglichst begrenzen (Verarbeitungsverzeichnis)
- [ ] T-5.20 · P1 · Moderationsrichtlinie mit Regel für Namen von Privatpersonen in Freitexten (Verarbeitungsverzeichnis)

- [ ] T-5.21 · P1 · `public_reviews.published_at` nur als Quartal speichern; der genaue Zeitstempel ist öffentlich lesbar, obwohl die Vorschau den Monat als unsichtbar ausweist (Fragebogen)
  Teilweise erledigt am 18.10.2026: `published_at` ist der Quartalsbeginn in UTC, die Karte zeigt „Q4 2026“ statt des Monats (E-2.12). Wirkt erst nach neuem Deploy von `moderate_review` und `publish_scheduled` (vorher `dart run tools/vendor_core.dart`). Offen: `$createdAt` der Zeile in `public_reviews` ist weiter sekundengenau und für jeden lesbar; bestehende Zeilen tragen noch den genauen Zeitpunkt.
- [ ] T-5.22 · P2 · Freitextlänge festlegen: Fragebogen erlaubt 4000 Zeichen, Referenz nennt 1000 (Fragebogen)
- [ ] T-5.23 · P3 · Dateiformate für Nachweise in Fragebogen und Ablage angleichen (Fragebogen)

- [ ] T-5.24 · P1 · Zweck für die Antworten des Konfliktmoduls festlegen; sie fließen heute weder in Scores noch in die öffentliche Fassung, und ohne Zweck dürfen sie nicht gespeichert werden (Fragebogen)

- [ ] T-5.25 · P2 · Barrierefreiheitserklärung: klären lassen, ob das BFSG für Karriko gilt oder die Ausnahme für Kleinstunternehmen greift (Sitemap)
- [ ] T-5.26 · P2 · Die Noto-Ersatzschrift für Zeichen wie Emojis lädt weiter von `fonts.gstatic.com`; lokal einbinden oder abschalten (PR #13, Factsheet §9)

## 6 · Oberfläche und Barrierefreiheit

- [ ] T-6.2 · P1 · Akzentfarbe im Theme auf `accentDark` umstellen, WCAG AA (todo E)
  `#E3342F` kommt auf 4,47:1, verlangt sind 4,5:1. Gehört ins Theme (`app_theme.dart`), nicht in einzelne Seiten; vorher am laufenden Build beurteilen.
- [ ] T-6.4 · P2 · Die 24 Layout-Überläufe abarbeiten, zuerst `/subscription`, `/register/betrieb`, `/kontakt` bei 375 px (todo E)
  Teilweise erledigt am 13.10.2026: Kontakt und Registrierung Betrieb behoben, neuer Layout-Test für neun öffentliche Seiten (`7a02091`); `/subscription` ist ausgeblendet. Ursache durchgängig `Text` in einer `Row` ohne `Expanded`/`Flexible`.
- [ ] T-6.5 · P2 · Auth-Seiten auf Swiss Design umstellen und mit Kopfzeile versehen (todo E)
  Betrifft `register_azubi`, `register_betrieb`, `forgot_password`, `reset_password`, `verify_email`.
- [ ] T-6.6 · P2 · Restliche Betriebsseiten: Analytics, Abonnement, Team, Bewertungen, Meldungen (todo E)
- [ ] T-6.7 · P2 · Restliche Azubi-Seiten: Lesezeichen, Benachrichtigungen (todo E)
  Benachrichtigungen sind seit 18.10.2026 ausgeblendet (T-2.13); offen ist hier nur noch die Merkliste.
- [ ] T-6.8 · P2 · Restliche öffentliche Seiten: Bewertungsdetail, Blogartikel, Kontakt, Über uns (todo E)
- [ ] T-6.11 · P2 · Ladezeit auf dem Smartphone messen: LCP unter 2,5 s, CLS unter 0,1 (Referenz §5)

- [ ] T-6.17 · P1 · Seite „Eigene Bewertung“ unter `/my-reviews/:id`: Status, Begründung bei Ablehnung (Art. 17 DSA), Freitext ändern, zurückziehen. Die Danke-Seite verspricht „Bis dahin kannst du sie noch ändern“, einen Weg dafür gibt es nicht (Sitemap)
- [ ] T-6.18 · P1 · „Melden“ auf jeder Bewertung, auch ohne Konto, etwa unter `/reviews/:id/melden`; heute melden nur Betriebe über `/reports` (Sitemap, Art. 16 DSA)
- [ ] T-6.19 · P2 · Bewertungsrichtlinien als öffentliche Seite, der Entwurf vom August liegt vor (Sitemap)

- [ ] T-6.21 · P2 · Anmeldeschranke umsetzen: gesperrte Teile erst nach Anmeldung vom Server ausliefern, für Google als gesperrt kennzeichnen, Vergleich mit zwei Betrieben ohne Konto, Anonymitätsgrenzen gelten auch angemeldet (Konzept: Tab Anmeldeschranke)

## 7 · Tests

- [ ] T-7.1 · P1 · Kritische Testfälle aus Referenz §5 absichern: Anonymität auch in der API-Antwort, fremdes Profil bearbeiten, zweite Betriebsantwort, Konto löschen (todo F)
  Teilweise erledigt am 13.10.2026: Anonymität abschließend getestet (`dc4e5d2`), Startseite 375 px durch Layout-Test. Offen: fremdes Profil (nur gegen Appwrite prüfbar), zweite Betriebsantwort und Konto löschen (noch nicht gebaut).
- [ ] T-7.2 · P1 · Rechtetests mit zwei echten Konten gegen Staging: fremde Merkliste, fremdes Profil, fremde Firma (Plan, neu)
- [ ] T-7.3 · P2 · Mindestens ein Integrationstest, der eine echte Appwrite-Antwort sieht; heute arbeiten alle Tests gegen Fakes (README)
- [ ] T-7.6 · P2 · Nicht abgedeckte Bereiche: Repositories, Lesezeichen, Suche, Unternehmensdetail, Betriebsseiten (todo F)
  Teilweise erledigt am 18.10.2026: `CompanyRepository` nimmt ein `TablesDB` entgegen und ist damit ohne Appwrite testbar; `company_repository_test.dart` prüft Merkliste, Suchabfragen und Profiländerung. Dabei behoben: ein gemerkter, inzwischen gelöschter Betrieb ließ die ganze Merkliste scheitern. Offen: übrige Repositories nach demselben Muster, Widget-Tests für Merkliste, Suche, Unternehmensdetail und Betriebsseiten.
- [ ] T-7.7 · P3 · Layout-Durchlauf als dauerhaften Test (todo F)
- [ ] T-7.8 · P3 · Testabdeckung der Geschäftslogik messen, Ziel über 80 % (Referenz §5)
- [ ] T-7.9 · P2 · Klickwege auf einem echten Telefon durchspielen; bisher nur in der Mobil-Emulation angesehen, dort blieben Klicks hängen (Statusbericht 13.7, im Archiv)

## 8 · Produktentscheidungen

- [ ] T-8.1 · P1 · Antworten der Betriebe: ja oder nein; falls ja nach den Regeln der Referenz (eine Antwort, 1000 Zeichen, keine Links, danach unveränderlich) (todo G, Referenz §2.4)
  Die Spalten `betrieb_reply` und `betrieb_replied_at` standen in der alten `reviews` schon. Nicht gebaut, weil es die Frage entschieden hätte.
- [ ] T-8.2 · P3 · Gewichtung aus der Referenz streichen: Der Fragebogen kennt keine namentlichen Bewertungen, gewichtet wird nach Alter (Fragebogen)
- [ ] T-8.3 · P2 · Suchmaschinen: Flutter Web zeichnet auf eine Canvas, Crawler sehen wenig Text. Die Referenz setzt auf organischen Traffic und strukturierte Daten; Lösung festlegen, etwa statische Vorschauseiten für Betriebsprofile (neu)
- [ ] T-8.4 · P2 · Preismodell und Abonnement: Leistungen von Premium, Zahlungsanbieter, B2B-AGB (README, neu)
- [ ] T-8.5 · P2 · Umfang der Börse: Bewerbungen, Datei-Upload, Stellensuche, jeweils mit Datenschutzfolgen (todo G)
- [ ] T-8.6 · P3 · Desktop-Targets testen oder entfernen (README)
- [ ] T-8.7 · P3 · Roadmap nach dem Start: Verifikations-Abzeichen, Branchenvergleich, Empfehlungen, Mobile App, öffentliche API (Referenz §6)

- [ ] T-8.8 · P2 · Einladungslinks mit `?src=` (probezeit, jahresbeginn, nach_ende, kammer, schule) sind angelegt: festlegen, wer sie verteilt und ob Einladungen durch den Betrieb zählen (Spezifikation §11, Sitemap)

- [ ] T-8.9 · P2 · Anmeldeschranke festlegen: welche zwei Kategorien und wie viele Bewertungen ohne Konto sichtbar sind, was Betriebskonten bei anderen Betrieben sehen; danach als Entscheidung ins Factsheet (Konzept: Tab Anmeldeschranke)
- [ ] T-8.10 · P2 · Vergütung abfragen oder nicht: `module_verguetung` ist per Feature-Flag aus. Stärkster Vergleichsanreiz für Azubis, zugleich die Angabe, die Betriebe am ehesten zur Löschungsforderung bringt (`UMSETZUNG_BERICHT.md` §9, `karriko-fragebogen.md` §11)

## 9 · Unternehmen und Betrieb (CEO)

- [ ] T-9.1 · P1 · Klären, unter welchem Unternehmen Karriko läuft (eigene Gesellschaft oder bestehendes Gewerbe), danach Impressum, AGB und Verträge darauf ausrichten (neu)
- [ ] T-9.2 · P1 · Markenrecherche und Anmeldung „Karriko“ beim DPMA oder EUIPO prüfen (neu)
- [ ] T-9.3 · P1 · Steuerberater, Geschäftskonto und Buchhaltungssoftware festlegen (neu)
- [ ] T-9.4 · P1 · Betriebshaftpflicht und Cyber-Versicherung prüfen; bei einem Bewertungsportal ist Abmahnrisiko real (neu)
- [ ] T-9.5 · P2 · Finanzierung: EXIST-Gründerstipendium oder andere Förderung weiterverfolgen (neu)
- [ ] T-9.6 · P2 · Ansprechpartner für die Anlaufstellen im Fragebogen gewinnen: Ausbildungsberatung der Kammern, Gewerkschaftsjugend (Setup §12)
- [ ] T-9.7 · P2 · Vertriebsunterlagen: Seite zu Sicherheit und Datenschutz, TOM-Dokument für Betriebe (Chat)
- [ ] T-9.8 · P3 · Gap-Analyse nach ISO/IEC 27001, sobald ein Kunde es verlangt (Chat)
- [ ] T-9.9 · P3 · Zugänge und Notfallunterlagen für eine Vertrauensperson hinterlegen, gegen das Risiko „Wissen in einem Kopf“ (Referenz §7)

- [ ] T-9.10 · P1 · Hosting-Anbieter für die Web-App wählen: EU-Standort, AVV, ISO-27001-Zertifizierung, eigene Security-Header möglich (neu)
- [ ] T-9.11 · P1 · Anwalt für IT- und Datenschutzrecht finden und Ersttermin vereinbaren; Fragenliste steht im Tab Fragen an den Anwalt (neu)
- [ ] T-9.12 · P2 · Vertretung für den Notfall benennen und in die Notbremsen einweisen (Notfallplan)
- [ ] T-9.13 · P2 · Notfallplan vervollständigen: Telefon, Kontakte, Wartungsseite, Bremsen in Staging erprobt (Notfallplan)

## 10 · Vorschaltseite bis zum Launch

- [ ] T-10.1 · P1 · „Kommt bald“-Seite auf karriko.de. Die Sperre sitzt im Reverse Proxy (Caddy oder nginx), nicht in der App, und deckt alle Pfade ab: Website, `/app/` und den Passkey-Dienst (Website-Umbau)
- [ ] T-10.2 · P1 · Zugang per Passwortformular, das ein HttpOnly-Cookie setzt (Caddy `forward_auth` oder Next.js-Middleware), mit Rate-Limit gegen Durchprobieren. Einfachste Übergangslösung: HTTP Basic Auth im Proxy (Website-Umbau)
- [ ] T-10.3 · P1 · Impressum und Datenschutzerklärung auf der Vorschaltseite öffentlich verlinken, sie müssen auch vor dem Launch erreichbar sein (neu)
- [ ] T-10.4 · P1 · Launch-Schritt festlegen: Sperre entfernen, `noindex` abschalten, Sitemap in der Search Console einreichen (Website-Umbau)
- [ ] T-10.5 · P2 · Die Sperre schützt nur die Website. `public_reviews` und `company_scores` sind über die Appwrite-API weiter mit `read("any")` lesbar, also bis zum Launch keine echten Bewertungen veröffentlichen (Website-Umbau)
- [ ] T-10.6 · P2 · Bestätigungsmail, Passwort-Reset, Magic Link und OAuth mit Testkonten durch die Sperre hindurch testen (Website-Umbau)
- [ ] T-10.7 · P3 · Optional: E-Mail-Liste „Zum Start benachrichtigen“ mit Double-Opt-in und Hinweis in der Datenschutzerklärung (neu)

## Bewusst nicht geplant

Damit die Liste nicht künstlich wächst (übernommen aus `notes/todo.md`):

- **Conditional UI für Passkeys:** nicht machbar, solange die App auf Flutter Web läuft (Textfelder liegen auf einer Canvas). Eine Plattformgrenze, keine Aufgabe.
- **Registrierung als Konto-Orakel:** bewusste, im Mapper dokumentierte Abweichung von Referenz §3.2. Nur mit serverseitiger Registrierung lösbar; erst dann wieder aufmachen.
- **Social Login in einer nativen App:** braucht einen Deep-Link-Rückweg. Bis zur Mobile App (T-8.7) scheitert er dort mit klarer Meldung; im Browser läuft er.
- **Build-Hooks in der transitiven Kette** (S6): lassen sich nicht wegkonfigurieren, solange Appwrite genutzt wird. Bewusst getragen; die Hebel darauf sind schlanke Abhängigkeiten und aktuelle Versionen.
