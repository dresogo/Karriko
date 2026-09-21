# Plan: Bewertungsfragebogen in Karriko

**Stand:** 21. September 2026
**Grundlage:** [`karriko-fragebogen.md`](karriko-fragebogen.md) (fachliche Quelle) und der Auftrag dazu.
**Status:** Entwurf, wartet auf Freigabe. Bis zur Freigabe wird kein Code geschrieben.
**Entschieden am 21. September 2026:** die vier Fragen aus Abschnitt 8 — siehe dort.

---

## 1. Befunde aus der Bestandsaufnahme

### 1.1 Das Repository

```
Karriko/
├── karriko_flutter/     Flutter-App (Web, iOS, Android) — 89 Dart-Dateien, 15 Testdateien
├── services/passkey-rp/ eigener WebAuthn-Dienst, TypeScript/Node, eigene CI
├── tools/               appwrite-setup.mjs — idempotentes Provisionierungsskript
├── notes/               die gesamte Projektdokumentation
├── old_tsx/             abgelöster Next.js-Prototyp, nur Nachschlagewerk
└── README.md
```

Die Dokumentation liegt vollständig in `notes/`, nicht in `docs/`. Der Auftrag nennt zwar `docs/APPWRITE_SETUP.md` und die drei anderen Dateien — **entschieden ist `notes/`**, passend zum Bestand. Die vier Dokumente heißen also `notes/PLAN_FRAGEBOGEN.md`, `notes/APPWRITE_SETUP.md`, `notes/REVIEW_TEXTE.md`, `notes/UMSETZUNG_BERICHT.md` und werden aus `notes/projektstruktur.md` und dem README verlinkt.

### 1.2 Die Anwendung

| Sache | Befund |
|---|---|
| Flutter | 3.44.7 stable, Dart 3.11.4 |
| SDK-Grenze | `sdk: ^3.4.0` in `pubspec.yaml` |
| State-Management | **Riverpod** (`flutter_riverpod` 2.5.1, `riverpod_annotation` + `riverpod_generator` vorhanden, Codegen aber nirgends benutzt — alle Provider sind von Hand geschrieben) |
| Routing | **GoRouter** 14.2, eine flache `routes:`-Liste in `lib/app/router.dart`, plus ein `redirect`-Wächter mit fester Torreihenfolge (Laden → MFA → E-Mail → Rolle) |
| Formulare | `reactive_forms` ist als Abhängigkeit deklariert, wird im Code aber **nirgends benutzt**; alle Formulare laufen über `TextEditingController` + `GlobalKey<FormState>` |
| Appwrite-SDK | `appwrite: ^25.4.0`, Client-Initialisierung zentral in `lib/data/services/appwrite_service.dart` |
| Datenbank-API | Der Code benutzt bereits die **neue** `TablesDB`-API (`listRows`, `createRow`, `tableId`), nicht mehr `Databases`/`collections` |
| Schichten | `core/` → `data/` (models, repositories, services) → `providers/` → `presentation/` |
| Theme | `AppColors`, `AppLayout` (feste Abstandsskala s8…s64), `ContentBand` als Vollbreiten-Band mit gekappter Lesebreite |
| Assets | **Es gibt bisher keinen `assets:`-Block** in der `pubspec.yaml` und keinen `assets/`-Ordner |
| Tests | 15 Dateien, reine Widget-/Logiktests gegen Fakes, keine Mock-Bibliothek (kein `mocktail`); Repositories werden als echte Klassen mit überschriebenen Methoden gefälscht |
| Lints | `flutter_lints` 4.0, sonst unverändert |

### 1.3 Was es zum Fragebogen schon gibt

Das ist der wichtigste Befund: **es gibt bereits zwei konkurrierende Bewertungsstrecken.**

| Datei | Was sie ist |
|---|---|
| [`lib/presentation/azubi/new_review_screen.dart`](../karriko_flutter/lib/presentation/azubi/new_review_screen.dart) | 615 Zeilen, vierstufiger Assistent (Betrieb → 5 Sterneskalen → Titel/Text/Pro/Contra → Bestätigung). Schreibt über `ReviewRepository.createReview` direkt in `reviews`. Route `/reviews/new`. |
| [`lib/presentation/azubi/fragen_bewerten_screen.dart`](../karriko_flutter/lib/presentation/azubi/fragen_bewerten_screen.dart) | 303 Zeilen, Fragenkatalog aus der Collection `questions`, drei Typen (Sterne, Ja/Nein, Freitext), **alles auf einem Bildschirm**. Der Absenden-Knopf zeigt eine SnackBar: „Das Speichern wird noch angebunden." Route `/fragen-bewerten`. |
| [`lib/data/models/question_model.dart`](../karriko_flutter/lib/data/models/question_model.dart) | `id, category, text, hint, type, isRequired, sortOrder`. Keine Bedingungen, keine Module, keine Varianten, keine Gewichte. |
| [`lib/data/repositories/question_repository.dart`](../karriko_flutter/lib/data/repositories/question_repository.dart) | Lädt aus `questions`, fällt auf **acht hartcodierte deutsche Fragetexte im Dart-Code** zurück. |
| [`lib/data/models/review_model.dart`](../karriko_flutter/lib/data/models/review_model.dart) | Flaches Modell mit `overall_rating`, vier Subwerten, `title`, `text`, `pros`, `cons`, `betrieb_reply`. |
| [`lib/data/repositories/review_repository.dart`](../karriko_flutter/lib/data/repositories/review_repository.dart) | **Der Client schreibt direkt in `reviews`** und setzt die Dokumentrechte selbst. |
| [`lib/presentation/common/review_card.dart`](../karriko_flutter/lib/presentation/common/review_card.dart) | `ReviewCard` + `StarRating`. Wird in Dashboard, Suche, Unternehmensprofil und Detailseite benutzt. |

Beides ist Fragebogen-Gebiet. Der Auftrag sagt „Code, der nichts mit dem Fragebogen zu tun hat, fasst du nicht an" — diese Dateien haben damit zu tun. → **Offene Frage 1**.

### 1.4 Was es noch gar nicht gibt

- **Kein Storage.** Kein `Storage(...)`, kein `bucketId`, kein `createFile` irgendwo in `lib/`. Es gibt also noch keinen Upload-Weg, auf dem A5 aufsetzen könnte.
- **Keine Verifikation eines Ausbildungsverhältnisses.** `is_verified` ist ein Feld an `reviews` und `companies`, das niemand setzt. Der Treffer auf „verif" im Code ist überall die **E-Mail**-Bestätigung.
- **Keine Teams.** Kein `Teams(...)`. Moderatoren und Admins existieren nicht.
- **Keine Appwrite Functions.** Kein `Functions(...)`. Es läuft bisher nichts serverseitig außer Appwrite selbst.
- **Keine Aggregate.** `companies.average_rating` und `companies.review_count` sind Felder, die niemand berechnet.
- **Keine Moderation.** `reviews.status` wird beim Anlegen auf `pending` gesetzt und danach von nichts mehr angefasst; alle Leseabfragen filtern auf `published`.

### 1.5 Appwrite: Werkzeuge und Grenzen

Nachgeschlagen, nicht aus dem Gedächtnis:

| Sache | Befund | Quelle |
|---|---|---|
| Appwrite CLI | **nicht installiert** (weder in PATH noch als npm-Paket im Projekt). Neueste Version: `appwrite-cli@27.3.0`. Das npm-Paket ist seit Kurzem nur noch ein Starter, der eine plattformeigene Binärdatei über `optionalDependencies` zieht. | npm-Registry, entpacktes Paket |
| Konfigurationsdatei | **`appwrite.config.json`** (nicht `appwrite.json`). Ab CLI 20.0.0 lässt sie sich über `includes` auf mehrere Dateien aufteilen. | [CLI-Installation](https://appwrite.io/docs/tooling/command-line/installation) |
| Format Datenbanken | Top-Level `tablesDB[]` und `tables[]`; eine Tabelle hat `$id`, `$permissions`, `databaseId`, `name`, `enabled`, **`rowSecurity`**, `columns[]`, `indexes[]`. Eine Spalte hat `key`, `type`, `status`, `error`, `required`, `array`, `size`, `default`. | [CLI Tables](https://appwrite.io/docs/tooling/command-line/tables) |
| Format Functions | `$id`, `execute[]`, `name`, `enabled`, `logging`, `runtime`, `vars`, `events[]`, `schedule`, `timeout`, `entrypoint`, `commands`, `path`, `scopes` | [CLI Functions](https://appwrite.io/docs/tooling/command-line/functions) |
| **Dart-Runtime** | **verfügbar.** Identifier laut Runtimes-Tabelle: `dart-2.15 … dart-3.3 dart-3.5 dart-3.10 dart-3.11`. Das Basis-Image für 3.12/3.13 existiert bereits in open-runtimes, und Appwrite hat Dart 3.12 angekündigt. **Ich ziele auf `dart-3.11`** — das passt exakt zum lokalen Dart 3.11.4. | [Runtimes](https://appwrite.io/docs/products/functions/runtimes), [open-runtimes](https://github.com/open-runtimes/open-runtimes/tree/main/runtimes/dart/versions), [Dart-3.12-Ankündigung](https://appwrite.io/blog/post/announcing-dart-flutter-runtimes) |
| Dart-Entrypoint | `lib/main.dart` mit `Future<dynamic> main(context) async`, Zugriff über `context.req`, `context.res`, `context.log`, `context.error`. Build-Befehl: `dart pub get`. | [open-runtimes/dart README](https://github.com/open-runtimes/open-runtimes/blob/main/runtimes/dart/README.md), [Develop Functions](https://appwrite.io/docs/products/functions/develop) |
| Server-SDK | `dart_appwrite` 29.0.0 auf pub.dev, `sdk: >=2.17.0 <4.0.0` | pub.dev-API |
| Dynamischer API-Schlüssel | Wird pro Ausführung im Header `x-appwrite-key` mitgeliefert, Rechte über die **Scopes** der Function. Kein eigener Schlüssel im Code nötig. | [Develop Functions](https://appwrite.io/docs/products/functions/develop) |
| Nutzer-JWT | Im Header `x-appwrite-user-jwt`, wenn ein angemeldeter Nutzer die Function aufruft | ebenda |
| Event-Syntax | `tablesdb.<DB_ID>.tables.<TABLE_ID>.rows.*.create` / `.update` / `.delete` / `.upsert` | [Events](https://appwrite.io/docs/advanced/platform/events) |
| Spaltentypen für Text | Vier Typen: `varchar`, `text`, `mediumtext`, `longtext`. **`varchar` zählt auf die 64-KB-Zeilengrenze von MariaDB, `text` nicht** (nur ein 20-Byte-Zeiger in der Zeile). Volltextindex und Sortierung gehen nur bis 768 Zeichen. | [Neue String-Typen](https://appwrite.io/blog/post/new-string-types) |

Ein bestehendes Provisionierungswerkzeug gibt es: [`tools/appwrite-setup.mjs`](../tools/appwrite-setup.mjs), 327 Zeilen, idempotent, mit Probelauf, Erkennung ob die Instanz `tablesdb` oder `databases` spricht, und Warten auf `status: available` vor dem Indexbau. Das ist die etablierte Lösung im Projekt und deutlich robuster als ein CLI-Push gegen eine teilweise befüllte Datenbank.

### 1.6 Zwei Dinge, die mir beim Lesen aufgefallen sind

Beide gehören nicht zum Fragebogen. Ich fasse sie nicht an, nenne sie aber, weil sie die Anleitung betreffen:

1. **Projekt-ID und Datenbank-ID stehen im Klartext im Repository** ([`appwrite_constants.dart:7`](../karriko_flutter/lib/core/constants/appwrite_constants.dart#L7), [`:60`](../karriko_flutter/lib/core/constants/appwrite_constants.dart#L60), und nochmal in `tools/appwrite-setup.mjs`). Das Repository ist öffentlich. Die Qualitätsanforderung „keine echten Schlüssel oder Projekt-IDs im Repository" ist heute also schon verletzt. Meine neuen Konstanten lese ich über `String.fromEnvironment` mit unverfänglichem Standard. Die bestehenden umzustellen ist **entschieden als eigene Aufgabe** und wird hier nicht angefasst; ich vermerke sie in `notes/todo.md`.
2. Die `reviews`-Collection erlaubt dem Client heute das Schreiben. Teil D verlangt ausdrücklich das Gegenteil.

---

## 2. Geplante Ordnerstruktur

```
Karriko/
├── packages/
│   └── questionnaire_core/                    ← NEU, reines Dart, keine Flutter-Abhängigkeit
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── questionnaire_core.dart         öffentliche API, ein einziger Export
│       │   └── src/
│       │       ├── model/                      Questionnaire, Question, Option, Module,
│       │       │                               Phase, ScoringConfig, VisibilityConfig,
│       │       │                               QualityConfig, Texts, FeatureFlags
│       │       ├── condition/                  Bedingungssprache: Parser + Auswertung
│       │       ├── flow/                       Ablaufsteuerung (nächste Frage, Module,
│       │       │                               Teaser-Zahlen, verwaiste Antworten)
│       │       ├── validation/                 Prüfung einer Einreichung gegen ihre Version
│       │       ├── scoring/                    Subscores, Gewichte, Schrumpfung, Alterung,
│       │       │                               Sichtbarkeitsschwellen
│       │       └── quality/                    Flags: Zeit, Straightlining, Konsistenz
│       ├── schema/
│       │   └── questionnaire.schema.json       ← JSON-Schema der Definition
│       └── test/
│           ├── condition_test.dart             jeder Operator einzeln
│           ├── flow_test.dart
│           ├── validation_test.dart
│           ├── scoring_test.dart
│           ├── quality_test.dart
│           ├── schema_test.dart                validiert v1 gegen das Schema
│           └── personas/                       die vier Durchlauftests aus A7
│
├── appwrite/
│   ├── appwrite.config.json                    ← CLI 27.x, Tabellen/Buckets/Functions/Teams
│   ├── questionnaires/
│   │   └── questionnaire_v1.json               identische Kopie für den Storage-Upload
│   └── functions/
│       ├── submit_review/      { pubspec.yaml, lib/main.dart, vendor/ (erzeugt) }
│       ├── moderate_review/
│       ├── aggregate_company/
│       ├── publish_scheduled/
│       ├── recompute_all/
│       └── cleanup/
│
├── tools/
│   ├── appwrite-setup.mjs                      ← bestehend, wird um die neuen Tabellen
│   │                                             und Buckets erweitert
│   ├── appwrite-purge-reviews.mjs              ← NEU, exportiert und leert die alte
│   │                                             reviews-Tabelle; Probelauf ist Standard
│   ├── vendor_core.dart                        ← NEU, kopiert questionnaire_core in die
│   │                                             Functions (siehe 3.2)
│   └── import_berufe.dart                      ← NEU, CSV der BA → berufe.json
│
├── notes/
│   ├── PLAN_FRAGEBOGEN.md                      ← dieses Dokument
│   ├── APPWRITE_SETUP.md                       ← NEU
│   ├── REVIEW_TEXTE.md                         ← NEU
│   └── UMSETZUNG_BERICHT.md                    ← NEU
│
└── karriko_flutter/
    ├── pubspec.yaml                            + assets-Block, + Pfadabhängigkeit
    ├── assets/
    │   ├── questionnaire/questionnaire_v1.json mitgelieferter Rückfall
    │   └── data/berufe_beispiel.json           kleine Beispiel-Berufsliste
    └── lib/
        ├── core/constants/questionnaire_constants.dart
        ├── data/
        │   ├── models/      questionnaire_release.dart, review_draft.dart,
        │   │                public_review.dart, company_scores.dart
        │   ├── repositories/ questionnaire_repository.dart   (Definition laden + cachen)
        │   │                 review_submit_repository.dart   (Function aufrufen)
        │   │                 review_draft_repository.dart
        │   │                 verification_repository.dart    (Upload in den Bucket)
        │   └── services/     questionnaire_cache.dart
        ├── providers/       questionnaire_provider.dart, questionnaire_run_provider.dart
        └── presentation/questionnaire/
            ├── questionnaire_screen.dart        der Ablauf, eine Frage pro Bildschirm
            ├── widget_registry.dart             Typkennung → Widget
            ├── phase_progress.dart
            └── widgets/                         ein Widget je Typkennung (21 Stück)
```

---

## 3. Neue Pakete, und warum

### 3.1 `packages/questionnaire_core`

Reines Dart, `environment: sdk: ^3.4.0` (identisch zur App, damit nichts auseinanderläuft). **Keine** Flutter-Abhängigkeit, weil dasselbe Paket in der Appwrite-Function unter einer nackten Dart-Runtime laufen muss.

Abhängigkeiten: **keine** im Produktivcode. `dev_dependencies`: `test`, `json_schema` (nur für den Schema-Test), `lints`.

Begründung für den Ort `packages/` statt innerhalb von `karriko_flutter/`: Der Bestand kennt bereits zwei getrennte Bauartefakte auf gleicher Höhe (`karriko_flutter/`, `services/passkey-rp/`). Ein drittes daneben passt ins Bild; ein Dart-Paket *innerhalb* der Flutter-App wäre von der Function aus schlechter erreichbar.

**Kein Codegen.** Kein `freezed`, kein `json_serializable`, kein `build_runner`. Der Bestand schreibt `fromJson`/`toJson` von Hand (siehe alle Modelle in `lib/data/models/`), und `riverpod_generator` liegt zwar herum, wird aber nirgends benutzt. Ich führe hier kein neues Werkzeug ein.

### 3.2 Wie die Function an `questionnaire_core` kommt

Das ist die einzige wirklich heikle Stelle der Architektur, deshalb ausführlich:

Appwrite lädt beim Deployment **nur das Wurzelverzeichnis der Function** hoch und führt dort `dart pub get` aus. Eine Pfadabhängigkeit `../../packages/questionnaire_core` zeigt damit ins Leere — der Build bricht ab.

Vier Wege, einer davon meiner:

| Weg | Preis |
|---|---|
| **Vendoring** (gewählt): `tools/vendor_core.dart` kopiert `packages/questionnaire_core` nach `appwrite/functions/<fn>/vendor/questionnaire_core`, die `pubspec.yaml` der Function zeigt per `path: vendor/questionnaire_core` dorthin. `vendor/` steht in `.gitignore`. | Ein Schritt vor jedem Push, der in der Anleitung stehen muss. Dafür: kein Netz nötig, kein Push-Zwang, reproduzierbar. |
| Git-Abhängigkeit auf das öffentliche Repo | Der Build zöge den Code aus GitHub. Funktioniert, koppelt aber jedes Function-Deployment an einen vorher gepushten Commit — und Pushen passiert hier nur auf Ansage. |
| `providerRootDirectory` = Repository-Wurzel | Lädt das ganze Repo für jede der sechs Functions hoch. |
| Paket auf pub.dev veröffentlichen | Kommt für internen Code nicht infrage. |

`vendor_core.dart` prüft zusätzlich, dass die kopierte Fassung mit der Quelle übereinstimmt, und schreibt einen Zeitstempel — damit eine Function nicht stillschweigend mit veralteter Logik läuft.

### 3.3 Neue Abhängigkeiten in `karriko_flutter`

| Paket | Wofür | Alternative geprüft |
|---|---|---|
| `questionnaire_core` (Pfad) | die gemeinsame Logik | — |
| `shared_preferences` | Entwurf lokal speichern (C2: „Entwurf nach jeder Antwort lokal speichern") | `web/localStorage` direkt über `package:web` wäre möglich — die App läuft aber laut `pubspec.yaml` auch auf iOS/Android, und `shared_preferences` ist dort die einzige Fassung, die überall trägt. |

Mehr nicht. Drag-and-Drop für `rank_top_n` baue ich mit `ReorderableListView` aus Material; Wischen für `swipe_binary` mit `Dismissible` bzw. `GestureDetector` — kein `flutter_card_swiper` o. ä., weil beide Typen ohnehin eine vollständige tastaturbedienbare Zweitbedienung brauchen und die Bibliothek dann nur noch die halbe Arbeit macht.

---

## 4. Datenmodell

### 4.1 Die Definition (JSON, versioniert)

```jsonc
{
  "id": "karriko_ausbildung",
  "version": 1,
  "locale": "de-DE",
  "phases":   [ { "id": "s", "label": "…", "estimatedSeconds": 45 }, … ],
  "modules":  [ { "id": "ausbilder", "label": "…", "trigger": <Bedingung>,
                  "offeredBy": ["k12"], "questions": ["m_ausbilder_gespraeche", …] }, … ],
  "questions":[ { "id", "specRef", "type", "phase", "module", "text": {"current","past"},
                  "intro", "placeholder", "options", "config", "condition",
                  "sensitive", "public", "scoringRef", "review" }, … ],
  "scoring":  { "subscores": {…}, "weights": {…}, "shrinkage": {…}, "aging": {…} },
  "visibility": { "scoreMinReviews": 3, "numbersMinReviews": 5, "numberBands": […] },
  "quality":  { "minScreenSeconds": …, "straightliningThreshold": …, "pairs": […] },
  "featureFlags": { "module_verguetung": false, "delayed_publish_small_business": true },
  "texts":    { "anonymity.intro": "…", "anonymity.sensitive": "…",
                "legal.freitext": "…", "help.anlaufstellen": […] }
}
```

Im Dart-Code steht kein einziger Fragetext. Die Widgets bekommen `Question`-Objekte und rendern deren Felder.

### 4.2 Die Bedingungssprache

```jsonc
{ "all": [
    { "gt": [ {"answer": "k3_ueberstunden"}, 0 ] },
    { "not": { "eq": [ {"answer": "s1_status"}, "abgebrochen" ] } },
    { "ranked_top": [ {"answer": "k12_prioritaeten"}, "ausbilder", 3 ] }
] }
```

Operatoren: `all`, `any`, `not`, `eq`, `neq`, `in`, `gt`, `gte`, `lt`, `lte`, `answered`, `selected`, `ranked_top`.
Operanden: `{"answer": "<id>"}`, `{"computed": "<key>"}`, Literale.

Die Auswertung ist eine reine Funktion. **Unbekannte Operatoren und unbekannte Frage-IDs werfen beim Laden der Definition**, nicht zur Laufzeit: `Questionnaire.parse()` läuft einmal über alle Bedingungen, sammelt alle referenzierten IDs und vergleicht sie gegen die Fragenliste. Eine kaputte Definition kommt damit gar nicht erst ins Formular.

### 4.3 Die Appwrite-Tabellen

Rechte gelten in Appwrite pro Zeile, nicht pro Spalte — deshalb die Trennung.

#### `questionnaire_releases`
| Spalte | Typ | Größe | Pflicht | Array |
|---|---|---|---|---|
| `locale` | varchar | 10 | ja | nein |
| `version` | integer | — | ja | nein |
| `file_id` | varchar | 64 | ja | nein |
| `bucket_id` | varchar | 64 | ja | nein |
| `checksum` | varchar | 64 | nein | nein |
| `active` | boolean | — | ja | nein |
| `published_at` | datetime | — | ja | nein |

Rechte: `read("any")`, keine Schreibrechte für Clients. Index: `locale_active` (key, `locale` + `active`).

#### `review_drafts`
| Spalte | Typ | Größe | Pflicht |
|---|---|---|---|
| `user_id` | varchar | 64 | ja |
| `company_id` | varchar | 64 | ja |
| `schema_version` | integer | — | ja |
| `answers_json` | **text** | 100 000 | ja |
| `timings_json` | **text** | 50 000 | nein |
| `current_question_id` | varchar | 64 | nein |
| `invite_source` | varchar | 64 | nein |
| `updated_at` | datetime | — | ja |

`rowSecurity: true`, Tabellenrechte `create("users")`, Zeilenrechte nur für den Eigentümer. Index: `user_company` (unique, `user_id` + `company_id`).

#### `reviews` — kein Client-Zugriff
Typisierte Spalten für alles, wonach gefiltert oder aggregiert wird:
`company_id`, `user_id`, `schema_version`, `status` (enum: `pending_moderation`, `scheduled`, `approved`, `rejected`), `respondent_status`, `beruf_code`, `start_year`, `end_year`, `invited` (bool), `invite_source`, `k5_recommend` (int 0–10), `k6_overall` (int 0–100), `detail_overall` (double), die sechs Subscores (`sub_fachlich`, `sub_betreuung`, `sub_umgang`, `sub_belastung`, `sub_verguetung`, `sub_perspektive`, je double) plus `sub_berufsschule` getrennt, `quality_flags` (varchar 64, array), `publish_after` (datetime), `publish_after_training_end` (bool), `freitext_gut` / `freitext_schlecht` (text), `answers_json` / `timings_json` (text), `device_hash` (varchar 64).

Tabellenrechte: **leer**. Nur Functions schreiben und lesen, über den dynamischen API-Schlüssel.
Indizes: `company_status` (`company_id`+`status`), `user_company` (`user_id`+`company_id`), `status_publish_after` (`status`+`publish_after`).

#### `public_reviews` — nur freigegebene Felder, öffentlich lesbar
Ohne `user_id`, ohne `quality_flags`, ohne `answers_json`, ohne `device_hash`, ohne `timings_json`. Mit `review_id`, `company_id`, `beruf_code`, `start_year`, `end_year`, `respondent_status`, `k5_recommend`, `k6_overall`, den sechs Subscores, den beiden Freitexten, `is_aged` (bool), `published_at`, `verified` (bool).
Rechte: `read("any")`. Index: `company_published` (`company_id` + `published_at`).

#### `company_scores`
`company_id`, `overall`, die sechs Subscores, `berufsschule`, `review_count`, `review_count_recent`, `weights_json`, `numbers_visible` (bool), `bands_json`, `updated_at`.
Rechte: `read("any")`. Index: `company_id` (unique).

#### `moderation_log`
`review_id`, `moderator_id`, `action` (enum: `approve`, `reject`), `reason` (text), `flags` (varchar array), `created_at`. Rechte nur für `team:moderators` und `team:admins`.

### 4.4 Buckets

| Bucket | Rechte | Endungen | Max | Verschlüsselung | Virenscan | Dateisicherheit |
|---|---|---|---|---|---|---|
| `questionnaires` | `read("any")` | `json` | 1 MB | nein | nein | nein |
| `verification_documents` | `create("users")`, **kein** `read` | `pdf jpg jpeg png` | 10 MB | ja | ja | ja (Zeilenrechte je Datei, nur `team:moderators` liest) |

Zur Wahl bei `questionnaires`: **`read("any")`**, nicht `read("users")`. Der Fragebogen enthält nichts Schützenswertes, und ein anonymer Besucher, der auf einem Betriebsprofil sieht, wie eine Bewertung zustande kommt, ist ein Vertrauensgewinn, kein Leck. `read("users")` hätte außerdem den Nebeneffekt, dass die Definition vor der Anmeldung nicht geladen werden kann — der Rückfall aufs Asset würde zur Regel statt zur Ausnahme.

---

## 5. Abweichungen von der Spezifikation

Nichts davon setze ich still um. Jede Zeile ist eine Bitte um Entscheidung oder eine begründete Wahl, die sich zurücknehmen lässt.

| # | Stelle | Abweichung | Grund |
|---|---|---|---|
| A1 | Teil D, Functions in Dart | **Keine Abweichung.** Dart-Runtime `dart-3.11` ist verfügbar und passt zum lokalen SDK. | — |
| A2 | Teil A, Ort des Pakets | `packages/questionnaire_core` wie vorgeschlagen, mit Vendoring in die Functions (3.2) | Appwrite lädt nur das Function-Verzeichnis hoch |
| A3 | Teil E, CLI-Konfiguration | Ich liefere **beides**: `appwrite/appwrite.config.json` für den CLI-Push *und* die Erweiterung von `tools/appwrite-setup.mjs`. | Die CLI ist hier nicht installiert, und ein `push` gegen eine bereits befüllte Datenbank überschreibt Rechte. Das bestehende Skript legt nur an, was fehlt. |
| A4 | Abschnitt 8, „Branchenmittel" | Ohne Daten gibt es noch kein Branchenmittel. Ich implementiere die Schrumpfung gegen einen **Parameter `priorMean` aus der Definition** (Standard 3.2, `review: true`) und bereite die Ablösung durch einen echten Branchenwert vor: `aggregate_company` liest ihn aus `company_scores` aller Betriebe derselben `industry`, sobald genug da sind. | Nicht erfindbar, aber vorbereitbar |
| A5 | Abschnitt 9, „Textprüfung auf Namen, Beleidigungen" | Ich baue **kein** Text-Klassifikat. Stattdessen setzt `submit_review` das Flag `text_needs_review` immer, wenn ein Freitext nicht leer ist — jeder Freitext geht also durch die Moderation. | Eine automatische Namens- und Beleidigungserkennung auf Deutsch ist ein eigenes Projekt; ein schlechter Filter ist schlimmer als keiner, weil er Vertrauen vortäuscht. In der Anleitung als offener Punkt markiert. |
| A6 | Abschnitt 11, Vergütung | Feature-Flag `module_verguetung`, Standard **aus**. Modul und Scoring-Dimension existieren vollständig, werden nur nicht angeboten. Der Subscore `sub_verguetung` fällt dann aus der Gewichtung heraus und die übrigen fünf werden neu normiert. | So verlangt |
| A7 | Abschnitt 11, Antwort des Betriebs | `public_reviews` bekommt **keine** Antwortspalte. Die bestehende `reviews.betrieb_reply` bleibt unangetastet am alten Modell. | Offene Frage laut Spezifikation — ich entscheide sie nicht |
| A8 | Abschnitt 6, A5 Verifikation | Es gibt noch keine Verifikation im Projekt (1.4). Ich baue sie neu: Upload in `verification_documents`, pseudonyme Ablage (Dateiname = Hash aus `review_id` + Salz), `reviews.verification_file_id`. **Keine** automatische Prüfung — ein Moderator sieht das Dokument und setzt `verified`. | Rechtlich ist die Prüfbarkeit gefordert, nicht die Automatik |
| A9 | Abschnitt 10, Kleinbetriebe | Variante 1 als Grundeinstellung (Hinweis + Wahl), Variante 2 als Angebot im selben Dialog — wie empfohlen. Gesteuert über `delayed_publish_small_business`, Standard **an**. | So verlangt |
| A10 | Rechtstexte | Der Satz aus A1 („Deine Meinung darfst du frei sagen…") steht wörtlich in der Definition, weil er in der Spezifikation wörtlich steht. **Alle anderen** rechtlichen Aussagen (Anonymitätszusage im Detail, Aufbewahrungsfristen, Hinweis für Minderjährige) bleiben als `PLATZHALTER — juristisch zu prüfen` in der Definition und in `docs/REVIEW_TEXTE.md`. | Rechtliche Aussagen erfinde ich nicht |
| A11 | Anlaufstellen (Modul Konflikte) | Kammer-Ausbildungsberatung, JAV, Gewerkschaftsberatung sind in der Spezifikation namentlich genannt und kommen in die Definition. **Ohne** Telefonnummern und URLs — die stehen als Platzhalter mit `review: true`. | Kontaktdaten, die ich nicht prüfen kann, sind schlimmer als keine |
| A12 | Berufsliste (S3) | Kleine Beispielliste als Asset (ca. 40 Berufe, `review: true`), dazu `tools/import_berufe.dart` für die vollständige Liste aus einer CSV. In der Anleitung steht, woher die CSV kommt (BERUFENET/Klassifikation der Berufe der BA) und welche Spalten das Skript erwartet. | So verlangt |
| A13 | `vas_unnumbered` auf dem Web | „Griff erscheint erst bei Berührung" wird zu „bei Berührung **oder Klick oder Tastenfokus**". Auf dem Desktop gibt es keine Berührung. Der Zustand „nicht beantwortet" bleibt davon unberührt. | Die App ist zuerst Flutter Web |
| A15 | A2, Operanden der Bedingungssprache | Der Auftrag nennt als Operanden `{"answer": "<id>"}`, `{"computed": "<key>"}` und Literale. Ich habe den Antwortverweis um ein optionales `"field"` erweitert: `{"answer": "s8_alltag", "field": "schicht"}`. | Die Wischkarten S8 und K1 liefern **eine** Antwort in Form einer Zuordnung Karte → Ja/Nein/Weiß-ich-nicht. Das Arbeitszeitmodul hängt laut Abschnitt 5 an genau einer davon („S8 Schicht oder Wochenende"). Ohne den Feldzugriff müsste jede Karte eine eigene Frage sein — aus einem Bildschirm würden sieben, und das Wischformat wäre hin. Kein neuer Operator, nur ein zweiter Schlüssel am vorhandenen Operanden; für die Prüfung beim Laden zählt er weiterhin als Verweis auf die ganze Frage. |
| A14 | A4 Vorschau / öffentliche Einzelansicht | Neues `PublicReviewCard` gegen ein `PublicReview`-Modell, an beiden Stellen benutzt. Das bestehende `ReviewCard` samt `StarRating` wird **entfernt**, sobald die letzte Verwendung auf `PublicReviewCard` umgestellt ist. | Folgt zwingend aus den Entscheidungen 1 und 2: Titel, Fließtext und Sterne erzeugt der neue Fragebogen nicht mehr, und alte Zeilen gibt es nach der Leerung nicht mehr. Betroffen sind Dashboard, Suche, Unternehmensprofil, Detailseite und `my_reviews`. |

---

## 6. Etappen

Nach jeder Etappe: `dart analyze` bzw. `flutter analyze`, Tests, ein Commit. Gepusht wird nichts ohne Ansage.

| Etappe | Inhalt | Prüfbar durch |
|---|---|---|
| **A** | `packages/questionnaire_core`: Modelle, Bedingungen, Ablauf, Validierung, Scoring, Qualität | `dart test` im Paket, inkl. der vier Personas |
| **B** | `questionnaire_v1.json` + JSON-Schema + `berufe_beispiel.json` + `docs/REVIEW_TEXTE.md` | Schema-Test, Personas laufen gegen die echte v1 |
| **C** | Flutter: Widget-Registry, 21 Widgets, Ablauf, Entwurf, Vorschau, öffentliches Profil | `flutter analyze`, Widget-Tests für `vas_unnumbered`, `swipe_binary`, `rank_top_n` |
| **D** | Die sechs Appwrite Functions in Dart + `vendor_core.dart` | `dart analyze` je Function; Logik ist schon in A getestet |
| **E** | `appwrite.config.json`, Erweiterung von `tools/appwrite-setup.mjs`, `import_berufe.dart` | `appwrite.config.json` gegen die CLI validieren (`appwrite push --dry-run`, sofern vorhanden) |
| **F** | `docs/APPWRITE_SETUP.md`, `docs/UMSETZUNG_BERICHT.md` | Durchlesen |

---

## 7. Annahmen

Alles hier ist eine Annahme, die ich getroffen habe, weil der Auftrag sie offenlässt. Jede kann mit einem Satz umgestoßen werden.

1. **Eine Locale.** `de-DE`. Die Struktur trägt mehrere (`locale` steht in Release und Definition), aber v1 gibt es nur auf Deutsch. `flutter_localizations` ist im Projekt nur für die Material-Dialoge da, es gibt keine ARB-Dateien.
2. **Die Zeitform** wird aus S1 abgeleitet: `noch_in_ausbildung` → `current`, alles andere → `past`. Fehlt eine `past`-Variante, greift `current` — und der Schema-Test schlägt fehl, damit das nicht unbemerkt bleibt.
3. **Eine Bewertung pro Nutzer und Betrieb.** Der unique Index `user_company` auf `review_drafts` und die Dublettenprüfung in `submit_review` setzen das durch. Eine zweite Ausbildung im selben Betrieb ist damit nicht abbildbar — halte ich für vertretbar.
4. **Der Fragebogen läuft unter `/reviews/new`.** Also dort, wo heute der alte Assistent liegt. `/fragen-bewerten` leitet dorthin weiter. → entschieden, siehe Abschnitt 8.
5. **Die Bearbeitungszeit** wird pro Bildschirm in Millisekunden gemessen, vom Aufbau des Bildschirms bis zum Verlassen, und bei Rücksprüngen **aufsummiert** statt überschrieben.
6. **Die Geräte-ID** ist `sha256(salz + stabile Browser-Kennung)`. Das Salz kommt aus der Umgebungsvariable `DEVICE_HASH_SALT` der Function. Der Hash wird **serverseitig** gebildet, der Client schickt die Rohkennung. IP-Adressen werden nirgends gespeichert.
7. **`src` als Einladungsquelle** kommt aus dem Query-Parameter, wird gegen eine Liste erlaubter Werte aus der Definition geprüft und sonst verworfen. `invited` ist genau dann wahr, wenn `src` gültig war.
8. **Entwurf-Speicherung:** lokal sofort (`shared_preferences`), nach Appwrite mit 3 Sekunden Verzögerung nach der letzten Änderung.
9. **Aufbewahrungsfristen** (in der Anleitung als juristisch zu prüfen markiert): Entwürfe ohne Änderung 90 Tage, geprüfte Verifikationsnachweise 30 Tage nach der Moderation.
10. **Die alte Collection `questions` bleibt stehen**, samt Inhalt. Sie stört nicht, und ein Löschen wäre nicht umkehrbar. Die alten *Spalten* an `reviews` (`title`, `text`, `pros`, `cons`, `overall_rating`, `training_quality`, `mentoring`, `work_life_balance`, `career_opportunities`, `betrieb_reply`, `betrieb_replied_at`) bleiben ebenfalls stehen — nach dem Leeren der Tabelle (Entscheidung 2) sind sie leer und kosten nichts. Die Anleitung nennt sie und überlässt das Entfernen dir.
11. **`recompute_all` läuft in Batches** von 100 Bewertungen und merkt sich den Fortschritt in einer Zeile in `company_scores` — damit ein Timeout den Lauf nicht von vorn beginnen lässt.
12. **Timeouts:** `submit_review` 30 s, `moderate_review` 15 s, `aggregate_company` 60 s, `publish_scheduled` 60 s, `cleanup` 300 s, `recompute_all` 900 s.
13. **Cron:** `publish_scheduled` stündlich (`0 * * * *`), `cleanup` täglich um 03:15 (`15 3 * * *`).

---

## 8. Entscheidungen vom 21. September 2026

**1. Die alte Bewertungsstrecke wird ersetzt.**
Der neue Fragebogen übernimmt `/reviews/new`. `/fragen-bewerten` leitet dorthin weiter, damit alte Lesezeichen und der Verweis aus dem Azubi-Dashboard nicht ins Leere laufen. [`new_review_screen.dart`](../karriko_flutter/lib/presentation/azubi/new_review_screen.dart) und [`fragen_bewerten_screen.dart`](../karriko_flutter/lib/presentation/azubi/fragen_bewerten_screen.dart) werden entfernt, ebenso `QuestionModel`, `QuestionRepository`, `questionsProvider` und `ReviewRepository.createReview`. Die Leseabfragen bleiben, zeigen aber auf `public_reviews`.

Mit betroffen, weil sie an denselben Modellen hängen: `my_reviews_screen.dart`, `review_detail_screen.dart`, der Bewertungsblock in `company_detail_screen.dart`, `betrieb/reviews_screen.dart`, `home_screen.dart` und `review_provider.dart`. Diese Dateien werden auf `PublicReview` umgestellt, nicht neu gebaut.

**2. Die bestehenden Zeilen in `reviews` werden gelöscht.**
Damit entfällt `schema_version: 0` und jede Sonderbehandlung für Altdaten — die Functions kennen nur noch das neue Schema, was die Logik spürbar vereinfacht.

Zwei Dinge dazu, die verbindlich sind:

- **Ich lösche nichts.** Das Leeren steht als eigener, ausdrücklich als *nicht umkehrbar* gekennzeichneter Schritt in `notes/APPWRITE_SETUP.md`, vor dem Anlegen der neuen Spalten. Dazu liefere ich `tools/appwrite-purge-reviews.mjs` mit Probelauf als Standardverhalten und einem Schalter `--wirklich-loeschen`, der zusätzlich die erwartete Zeilenzahl als Argument verlangt. Ohne beides passiert nichts.
- **Vorher ein Export.** Derselbe Schritt schreibt die alten Zeilen als JSON nach `notes/reports/`, bevor er löscht. Kostet nichts und ist die einzige Rückfahrkarte.

**3. Projekt-ID und Datenbank-ID im öffentlichen Repository: eigene Aufgabe.**
Hier nicht angefasst. Neue Konstanten sind von vornherein umgebungsabhängig. Ich trage den Punkt in `notes/todo.md` ein.

**4. Die Dokumente liegen in `notes/`.**
`notes/PLAN_FRAGEBOGEN.md`, `notes/APPWRITE_SETUP.md`, `notes/REVIEW_TEXTE.md`, `notes/UMSETZUNG_BERICHT.md`. Verlinkt aus `notes/projektstruktur.md` und dem README.

**Als Folge mitentschieden:** `PublicReviewCard` wird neu gebaut und ersetzt `ReviewCard` überall — siehe Abweichung A14. Da es nach Entscheidung 2 keine Altdaten mehr gibt, muss `ReviewCard` nicht übergangsweise weiterleben.

---

## 9. Was ich als Nächstes tue

Etappe A: `packages/questionnaire_core` anlegen und die Logik samt Tests schreiben. Danach Commit und weiter mit B.

*Warte auf deine Freigabe dieses Plans. Bis dahin entsteht kein Code.*
