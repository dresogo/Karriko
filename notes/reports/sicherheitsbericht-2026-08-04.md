# Karriko – Sicherheitsbericht: Lieferkette und Code-Einschleusung

**Stand:** 4. August 2026
**Branch:** `main`
**Auftrag:** Mögliche Gefahren der Webapp prüfen, insbesondere ungenutzte Pakete und Wege, über die fremder Code in die Anwendung gelangen könnte.
**Art der Prüfung:** Statisch. Quellcode, `pubspec.lock`, gebautes Web-Bundle, CI-Workflows, Plattform-Konfiguration, Git-Historie, Dependabot-Meldungen. Kein Pen-Test, keine Laufzeitanalyse, kein Test der Appwrite-Console.

Ergänzt den Abschnitt 7 des Statusberichts vom 3. August, der Auth, Datenhaltung und `.gitignore` abdeckt. Dieser Bericht hier betrachtet die **Lieferkette**: alles, was ungefragt in den Build oder in die laufende Seite gelangt.

---

## Kurzfassung

Die Anwendung selbst ist im Umgang mit fremdem Code unauffällig — kein `WebView`, kein `dart:html`, kein dynamisch geladenes Skript, keine Auswertung von Zeichenketten als Code, keine Dateisystem- oder Prozessaufrufe. Wenn hier Schadcode hineinkommt, dann **nicht über den Anwendungscode**, sondern über eine der drei Türen daneben:

1. **Die laufende Seite lädt Fremdcode nach.** Das Web-Bundle holt seinen Grafikkern zur Laufzeit von Googles CDN — nachweislich, aus dem gebauten Bundle heraus belegt. Es gibt keine Content-Security-Policy, die begrenzen würde, was eine Seite nachladen darf.
2. **Der Build zieht 150 Pakete.** Nur 13 sind bewusst ausgewählt, 9 davon werden nirgends benutzt. Ein Teil der Kette führt beim Bauen eigenen Code aus.
3. **Die CI vertraut verschiebbaren Markern.** Alle vier verwendeten GitHub-Actions sind über Versions-Tags eingebunden, nicht über feste Commits.

**Die wirksamste Einzelmaßnahme** ist zugleich die billigste: Neun ungenutzte Pakete entfernen. Das wurde für diesen Bericht durchgespielt — die Lieferkette schrumpft von **150 auf 85 Pakete**, Analyzer und alle 134 Tests bleiben grün.

| Nr. | Befund | Schwere | Aufwand |
|---|---|---|---|
| S1 | Grafikkern wird zur Laufzeit von `gstatic.com` geladen | **hoch** | ein Build-Flag |
| S2 | Keine Content-Security-Policy im Web-Build | **hoch** | klein |
| S3 | GitHub-Actions nicht auf Commit festgenagelt | **hoch** | klein |
| S4 | 9 ungenutzte Pakete, 65 Pakete unnötige Lieferkette | mittel | klein |
| S5 | Appwrite-SDK 13 Hauptversionen veraltet | mittel | mittel |
| S6 | Build-Hooks in der transitiven Kette führen Code beim Bauen aus | mittel | keiner (bewusst tragen) |
| S7 | Kein Schwachstellen-Scan für die Flutter-App | mittel | klein |
| S8 | 30 offene Dependabot-Meldungen im Altbestand | mittel | klein |
| S9 | CI erzwingt die Lockdatei nicht | niedrig | eine Zeile |
| S10 | Ungeklärte Zugangsdaten-Zeile in `notes/fehler.md` | **ungeklärt** | ein Handgriff |

---

## Teil A: Wie käme Schadcode in diese Anwendung?

Geordnet danach, wie realistisch der Weg ist — nicht danach, wie spektakulär er klingt.

| Weg | Offen? | Befund |
|---|---|---|
| Fremdskript in `web/index.html` | **nein** | Nur lokale Dateien. Das eingeschleuste Corbado-Bundle wurde am 3. August entfernt (Statusbericht 7.2). |
| Nachladen zur Laufzeit aus dem Netz | **ja** | CanvasKit von `gstatic.com` (S1), Schriften von `fonts.gstatic.com` (Statusbericht 7.5) |
| Kompromittiertes Dart-Paket | **ja** | 150 Pakete, davon 137 transitiv (S4, S5, S6) |
| Kompromittierte GitHub-Action | **ja** | vier Actions über Tags eingebunden (S3) |
| Kompromittiertes npm-Paket | teilweise | `old_tsx/` wird nicht gebaut, liegt aber im Repo (S8) |
| Code-Einschleusung über Nutzereingaben | **nein** | Flutter rendert kein HTML; keine Auswertung von Eingaben als Code |
| Deep-Link-Übernahme (Android) | **nein** | Kein eigenes URL-Schema registriert, nur der Standard-Launcher-Intent |
| Fremdcode über Build-Skripte im Repo | **nein** | Keine `postinstall`-Skripte, keine `build.yaml`, keine Git-Hooks im Repo |

---

## Befunde

### S1 — Der Grafikkern kommt zur Laufzeit von Googles CDN · hoch

Belegt am gebauten Bundle (`flutter build web --release`, `build/web/flutter.js`):

```js
canvasKitBaseUrl ? i.canvasKitBaseUrl : e.engineRevision && !e.useLocalCanvasKit
  ? I("https://www.gstatic.com/flutter-canvaskit" …
```

Jeder Seitenaufruf lädt **CanvasKit** — einen WebAssembly-Grafikkern von mehreren Megabyte — von `https://www.gstatic.com/flutter-canvaskit/<revision>/`. Das ist Flutters Voreinstellung, kein Fehler im Projekt, aber es hat zwei Seiten:

- **Lieferkette:** Fremdcode mit vollem Zugriff auf die Seite und damit auf die Appwrite-Sitzung, geladen von einem Server, den das Projekt nicht kontrolliert, ohne Integritätsprüfung (`integrity`-Hash). Dieselbe Bauart, die bei Befund 7.2 des Statusberichts als inakzeptabel eingestuft wurde — nur diesmal von Google statt von einer GitHub-Release-URL.
- **Datenschutz:** Die IP-Adresse jedes Besuchers geht an Google, bevor irgendetwas auf der Seite sichtbar wird. Das ist derselbe Sachverhalt wie bei Google Fonts (Statusbericht 7.5, LG München I, 3 O 17493/20) — hier sogar zwingend bei jedem Aufruf, nicht nur beim Schriftbedarf.

**Behebung:** ein Flag.

```bash
flutter build web --release --no-web-resources-cdn
```

Damit wird CanvasKit mit ausgeliefert und von der eigenen Domain geladen. Das Bundle wird größer, die Abhängigkeit verschwindet. Zusammen mit der Umstellung der Schriften (7.5) lädt die Seite danach **nichts** mehr von Dritten — und erst dann lässt sich eine strenge CSP (S2) überhaupt sinnvoll setzen.

### S2 — Keine Content-Security-Policy · hoch

`web/index.html` enthält keine CSP, weder als `<meta>` noch dokumentiert als Server-Header.

Die CSP ist die Schicht, die greift, **wenn** etwas schiefgeht: Sie hätte das Corbado-Skript aus 7.2 blockiert, und sie begrenzt, was ein künftig eingeschleustes Skript anrichten kann. Ohne sie ist jede erfolgreiche Injektion sofort vollwertig — Zugriff auf DOM, Sitzung und beliebige ausgehende Verbindungen.

**Behebung** — nach S1 und 7.5, sonst sperrt man die eigene Anwendung aus. Als `<meta>` in `web/index.html` oder besser als Header des ausliefernden Servers:

```
default-src 'self';
script-src 'self' 'wasm-unsafe-eval';
connect-src 'self' https://cloud.appwrite.io;
img-src 'self' data: blob:;
style-src 'self' 'unsafe-inline';
font-src 'self';
object-src 'none';
base-uri 'self';
frame-ancestors 'none';
```

`'wasm-unsafe-eval'` braucht Flutter für WebAssembly. `connect-src` muss den Appwrite-Endpunkt enthalten, sonst schlägt jede Anfrage fehl. **Vor dem Ausrollen im Browser gegentesten** — eine zu strenge CSP zeigt eine weiße Seite.

### S3 — GitHub-Actions sind nicht festgenagelt · hoch

Beide Workflows binden Actions über Versions-Tags ein:

| Action | Eingebunden als | Herkunft |
|---|---|---|
| `actions/checkout` | `@v5` | GitHub |
| `subosito/flutter-action` | `@v2` | **Drittanbieter** |
| `github/codeql-action/init` | `@v3` | GitHub |
| `github/codeql-action/analyze` | `@v3` | GitHub |

Ein Tag ist ein verschiebbarer Zeiger. Wer das jeweilige Repository übernimmt, kann `v2` auf beliebigen Code umbiegen — und der läuft dann in der CI mit Zugriff auf Quellcode und `GITHUB_TOKEN`. `subosito/flutter-action` ist dabei besonders zu beachten: kein GitHub-eigenes Projekt, aber es richtet die komplette Build-Umgebung ein.

Zwei Dinge fehlen zusätzlich in `flutter.yml`:

- **Keine `permissions:`-Angabe.** Damit gilt die Repo-Voreinstellung, die je nach Einstellung Schreibrechte auf Inhalte einschließt. Ein Analyse- und Test-Lauf braucht nur Lesen.
- **`persist-credentials` nicht abgeschaltet.** `actions/checkout` legt das Token standardmäßig in `.git/config` ab, wo jeder folgende Schritt es lesen kann.

**Behebung:**

```yaml
permissions:
  contents: read

steps:
  - uses: actions/checkout@08c6903cd8c0fde910a37f88322edcfb5dd907a8  # v5.0.0
    with:
      persist-credentials: false
```

Der Kommentar hinter dem Hash hält lesbar, welche Version gemeint ist. Dependabot kann festgenagelte Actions weiterhin aktualisieren, wenn `package-ecosystem: github-actions` in `.github/dependabot.yml` eingetragen ist — das fehlt bislang ebenfalls. (Die angegebene SHA ist ein Platzhalter: vor dem Übernehmen die echte Prüfsumme des gewünschten Release abrufen.)

### S4 — Neun ungenutzte Pakete · mittel

Gemessen über alle `import`-Anweisungen und die charakteristischen Symbole in `lib/`:

| Paket | Direkte Importe | Symbolnutzung | Bewertung |
|---|---|---|---|
| `dio` | 0 | kein `Dio(` | ungenutzt — Appwrite bringt seinen eigenen HTTP-Weg mit |
| `reactive_forms` | 0 | kein `ReactiveForm` | ungenutzt — Formulare laufen über `Validators` und `TextFormField` |
| `flutter_svg` | 0 | kein `SvgPicture` | ungenutzt |
| `flutter_animate` | 0 | kein `.animate()` | ungenutzt |
| `cached_network_image` | 0 | kein `CachedNetworkImage` | ungenutzt |
| `riverpod_annotation` | 0 | kein `@riverpod` | ungenutzt — es gibt keine Codegen-Dateien |
| `cupertino_icons` | 0 | kein `CupertinoIcons` | ungenutzt (Schrift-Asset, harmlosestes der neun) |
| `riverpod_generator` (dev) | — | keine `.g.dart` im Projekt | ungenutzt |
| `build_runner` (dev) | — | keine `build.yaml`, keine generierten Dateien | ungenutzt |

**Nachweis, dass sie entfernbar sind.** Für diesen Bericht wurden alle neun testweise aus `pubspec.yaml` gestrichen:

| | vorher | nachher |
|---|---|---|
| Pakete in `pubspec.lock` | **150** | **85** |
| `flutter analyze lib test` | 0 Hinweise | 0 Hinweise |
| `flutter test` | 134 grün | **134 grün** |

**65 Pakete weniger — 43 Prozent der Lieferkette**, ohne eine einzige Codeänderung. Der Zustand wurde anschließend wiederhergestellt; `pubspec.yaml` und `pubspec.lock` stehen unverändert auf dem Stand von `HEAD`.

Jedes dieser Pakete ist Code, der mitgeladen, mitgebaut und bei Schwachstellen mitgepatcht werden muss — für eine Funktion, die niemand nutzt. `flutter_animate` und `cached_network_image` ziehen dabei die längsten Ketten.

**Vorgehen:** Die neun Zeilen aus `pubspec.yaml` entfernen, dann `flutter clean`, `flutter pub get`, `flutter analyze`, `flutter test`. Das `flutter clean` ist Pflicht — nach dem Entfernen von `flutter_secure_storage` am 3. August kompilierte der Build gegen einen Paketstand, den es nicht mehr gab (siehe Statusbericht, Abschnitt 7.8).

### S5 — Das Appwrite-SDK ist 13 Hauptversionen zurück · mittel

`pubspec.yaml` fordert `appwrite: ^12.0.0`, aufgelöst auf **12.0.1**. Aktuell ist **25.3.0**.

Das ist das Paket, das Anmeldung, Sitzungen und sämtliche Datenzugriffe abwickelt — ausgerechnet dort ist der Abstand am größten. Bei einem Abstand dieser Größe ist nicht die Frage, ob Fehler behoben wurden, sondern welche.

Ein Sprung über 13 Hauptversionen ist kein Handgriff: Die Appwrite-SDKs haben in dieser Spanne Namen und Signaturen geändert, betroffen sind alle vier Repositories und `appwrite_service.dart`. Er gehört geplant, nicht nebenbei gemacht — aber er gehört auf die Liste. Insgesamt melden 54 der 150 Pakete neuere Versionen.

### S6 — Teile der Kette führen beim Bauen Code aus · mittel

Aus `flutter pub deps` — die Herkunft ist eindeutig:

```
appwrite 12.0.1
├── flutter_web_auth_2 → url_launcher (7 Plattform-Pakete)
├── device_info_plus
└── package_info_plus → jni, jni_flutter, objective_c → hooks 2.0.2
```

`hooks`, `jni` und `objective_c` bringen **native Build-Hooks** mit: Dart-Code, der beim Bauen auf dem Rechner ausgeführt wird — nicht in der App, sondern auf dem Entwickler- oder CI-System. Ein kompromittiertes Paket in diesem Zweig braucht keinen Nutzer, der die App öffnet; es genügt ein `flutter build`.

Das ist kein Fehler und lässt sich nicht wegkonfigurieren, solange Appwrite genutzt wird. Es ist der Grund, warum die beiden anderen Punkte zählen: **Weniger Pakete (S4) und aktuelle Versionen (S5) sind die einzigen Hebel**, die auf diese Fläche wirken.

Bemerkenswert am Rande: Ein einziges gewolltes Paket — `appwrite` — zieht OAuth-Browserintegration, URL-Launcher für sieben Plattformen, Geräte- und Paketinformationen samt JNI- und Objective-C-Brücken nach. Das meiste davon braucht diese Anwendung nicht.

### S7 — Für die Flutter-App läuft kein Schwachstellen-Scan · mittel

- **CodeQL** analysiert `javascript-typescript` — und damit ausschließlich `old_tsx/`, also toten Code. Die eigentliche Anwendung ist für CodeQL unsichtbar; ein Dart-Analysemodul gibt es nicht.
- **Dependabot** meldet 30 Schwachstellen, alle im Altbestand (S8). Für `pubspec.lock` kommt **keine einzige** Meldung. Ob das bedeutet, dass keine der 150 Abhängigkeiten betroffen ist, oder dass sie schlicht nicht geprüft werden, lässt sich von außen nicht unterscheiden — **das gehört in den Repo-Einstellungen nachgesehen.**

Die Flutter-CI prüft Format, Analyzer und Tests. Das ist Qualität, keine Sicherheit.

**Behebung:** Den [OSV-Scanner](https://google.github.io/osv-scanner/) in `flutter.yml` aufnehmen — er versteht `pubspec.lock` und gleicht gegen die OSV-Datenbank ab. Ein zusätzlicher Schritt, kein zusätzlicher Dienst. Ergänzend `.github/dependabot.yml` anlegen, mit `pub` für die App und `github-actions` für die Workflows (siehe S3).

### S8 — 30 offene Dependabot-Meldungen, davon 8 auf einem toten Pfad · mittel

Abgefragt am 4. August (der Statusbericht nennt noch 21 — es sind mehr geworden):

| Schwere | Anzahl | Paket | Manifest |
|---|---|---|---|
| hoch | 11 | `next` | `old_tsx/package.json` |
| mittel | 9 | `next` | `old_tsx/package.json` |
| niedrig | 2 | `next` | `old_tsx/package.json` |
| hoch | 3 | `next` | `package.json` — **existiert nicht mehr** |
| mittel | 3 | `next` | `package.json` — **existiert nicht mehr** |
| niedrig | 2 | `next` | `package.json` — **existiert nicht mehr** |

Alle 30 betreffen dasselbe Paket: **Next.js**. Acht zeigen auf ein Wurzel-`package.json`, das in `0219b16` nach `old_tsx/` verschoben wurde — sie sind Karteileichen, vermutlich seit dem Neuschreiben der Historie nicht mehr aktualisiert.

**Die reale Gefahr ist gering**, solange `old_tsx/` nicht gebaut oder ausgeliefert wird: `node_modules/` ist nicht im Repository, `karriko.db` ebenfalls nicht, es gibt keine `postinstall`-Skripte. **Der Schaden ist ein anderer:** 30 dauerhaft rote Meldungen sind Rauschen. Wer sie monatelang ignoriert, übersieht die 31., die echt ist.

**Behebung:** `old_tsx/` archivieren und aus `main` entfernen — die Historie behält den Code. Damit verschwinden Meldungen, CodeQL-Scan und Verwechslungsgefahr in einem Schritt. Falls der Alt-Code bleiben soll: Dependabot dafür stummschalten und die toten Meldungen schließen.

### S9 — Die CI erzwingt die Lockdatei nicht · niedrig

`flutter pub get` darf Abhängigkeiten neu auflösen, wenn die Constraints in `pubspec.yaml` es zulassen. Damit kann ein CI-Lauf gegen andere Versionen bauen als der Entwicklerrechner.

**Behebung:** `flutter pub get --enforce-lockfile` in `flutter.yml`. Der Lauf schlägt dann fehl, statt still abzuweichen.

### S10 — Ungeklärte Zugangsdaten-Zeile · ungeklärt

Die letzte Zeile von `notes/fehler.md` hat die Form `benutzer:passwort` und ist committet. Übernommen aus dem Statusbericht, Abschnitt 7.10 — dort steht der Sachverhalt vollständig. **Erst Echtheit prüfen, dann Schwere festlegen**; solange das offen ist, steht der Punkt über allem anderen in diesem Bericht.

---

## Teil B: Geprüft und unauffällig

Damit die nächste Prüfung weiß, was schon abgeräumt ist:

**Anwendungscode.** Keine Treffer für `WebView`, `dart:html`, `dart:js`, `js_interop`, `eval(`, `Process.`, `File(`, `localStorage`, `sessionStorage` in `lib/`. Es gibt keine Stelle, an der die Anwendung Code oder Inhalte aus einer externen Quelle interpretiert. Flutter rendert Text als Text — die klassische XSS-Fläche von Web-Frameworks existiert hier nicht.

**Web-Einstiegspunkt.** `web/index.html` lädt ausschließlich lokale Ressourcen (`flutter_bootstrap.js`, Favicon, Manifest, Icons). Kein Fremdskript, kein Tracker, kein Tag-Manager.

**Paketquellen.** Alle 150 Einträge in `pubspec.lock` stammen von `pub.dev`. Keine Git-Abhängigkeit, keine Pfad-Abhängigkeit, kein privater Spiegel — also keine Stelle, an der ein Paket an der offiziellen Registrierung vorbei ins Projekt kommt.

**Android.** `allowBackup="false"` gesetzt (am 3. August behoben). Keine gefährlichen Berechtigungen — `INTERNET` steht nur in den Debug- und Profile-Manifesten, wo es hingehört. Nur der Standard-Launcher-Intent, **kein eigenes URL-Schema** und damit keine Angriffsfläche für Deep-Link-Übernahme. Kein `usesCleartextTraffic`.

**Repository.** Keine verfolgten Datenbank-, Schlüssel- oder `.env`-Dateien. `node_modules/` und `old_tsx/karriko.db` liegen nur lokal. `old_tsx/package.json` enthält keine `postinstall`- oder `prepare`-Skripte. Keine Git-Hooks im Repository.

**Verbindung.** `setSelfSigned(status: false)`, Endpunkt fest auf `https://cloud.appwrite.io/v1`. Kein `http://` im Code. Die Appwrite-Projekt-ID ist per Design öffentlich.

**Passwortregel.** Mindestens 8 Zeichen, ein Großbuchstabe, eine Ziffer. Vertretbar. Eine Sperrliste der häufigsten Passwörter wäre wirksamer als weitere Zeichenklassen-Regeln, ist aber kein Mangel im engeren Sinn.

---

## Teil C: Empfohlene Reihenfolge

**Sofort — kostet Minuten**
1. Zugangsdaten-Zeile in `notes/fehler.md` klären (S10)
2. Neun ungenutzte Pakete entfernen (S4) — größte Wirkung pro Aufwand, `flutter clean` nicht vergessen
3. `--no-web-resources-cdn` im Web-Build (S1)
4. Actions auf Commit-Hashes festnageln, `permissions: contents: read`, `persist-credentials: false` (S3)
5. `--enforce-lockfile` in der CI (S9)

**Kurzfristig — kostet Stunden**
6. Schriften lokal einbetten (Statusbericht 7.5) — zusammen mit Schritt 3 die Voraussetzung für Schritt 7
7. Content-Security-Policy setzen und im Browser gegentesten (S2)
8. OSV-Scanner in die CI, `.github/dependabot.yml` mit `pub` und `github-actions` (S7)
9. `old_tsx/` aus `main` entfernen, tote Dependabot-Meldungen schließen (S8)

**Geplant — kostet Tage**
10. Appwrite-SDK aktualisieren (S5) — betrifft alle Repositories, gehört auf einen eigenen Branch mit eigenem Testlauf
11. Appwrite-Collection-Permissions in der Console prüfen (Statusbericht 7.3) — weiterhin der einzige serverseitige Zugriffsschutz und aus dem Code nicht verifizierbar

---

## Teil D: Was dieser Bericht nicht abdeckt

Damit niemand mehr Sicherheit hineinliest, als drinsteht:

- **Die Appwrite-Console.** Collection-Permissions, API-Schlüssel, Plattform-Einträge und OAuth-Anbieter sind aus dem Repository nicht einsehbar. Dort liegt die tragende Zugriffsgrenze der gesamten Anwendung.
- **Laufzeitverhalten.** Kein Pen-Test, kein Fuzzing, keine Beobachtung des tatsächlichen Netzwerkverkehrs im Betrieb.
- **Der Inhalt der 150 Pakete.** Geprüft wurden Herkunft, Anzahl, Alter und Bauart — nicht der Quellcode der Abhängigkeiten selbst.
- **Der ausliefernde Server.** HTTP-Header, TLS-Konfiguration und Hosting waren nicht Gegenstand; ein Teil der CSP-Empfehlung (S2) gehört dorthin.
- **Der Alt-Code in `old_tsx/`.** Nur auf Metadaten geprüft — Skripte, Lockdateien, verfolgte Dateien. Der TypeScript-Code selbst wurde nicht gelesen, weil er nicht ausgeliefert wird.
