#!/usr/bin/env node
//
// Zieht das Appwrite-Schema auf den Stand nach, den der Flutter-Code erwartet.
//
// Hintergrund: Der Code schreibt und liest Felder, die in der Console nie
// angelegt wurden. Fehlt `companies.owner_id`, scheitert `findCompanyByOwner`
// mit „Attribute not found in schema" – und weil `ensureCompany()` daran
// haengt, meldet jede Betriebsseite „Die Unternehmensdaten konnten nicht
// geladen werden." (Aufgabenliste B.1b und B.1c.)
//
// Das Skript ist idempotent: Es legt nur an, was fehlt, und ruehrt vorhandene
// Spalten, Indizes und Daten nicht an.
//
// Aufruf (API-Schluessel mit Rechten auf `databases`):
//
//   APPWRITE_API_KEY=… node tools/appwrite-setup.mjs
//   APPWRITE_API_KEY=… node tools/appwrite-setup.mjs --fix-permissions
//   APPWRITE_API_KEY=… node tools/appwrite-setup.mjs --dry-run
//   node tools/appwrite-setup.mjs --pruefen
//
// `--pruefen` vergleicht das Schema dieses Skripts mit
// appwrite/appwrite.config.template.json und geht nie ins Netz. Fuer die CI:
// Zwei Beschreibungen desselben Schemas laufen sonst auseinander.
//
// `--fix-permissions` setzt zusaetzlich die Rechte bestehender Sammlungen.
// Bewusst nicht Standard: Rechte zu aendern ist eine Entscheidung, keine
// Reparatur. Ohne den Schalter meldet das Skript nur, was abweicht. Bei
// `reviews` und `public_reviews` kann das auch heissen, dass ein bestehendes
// Recht **weg** muss — dort steht `exactPermissions`.
//
// Seit der Bewertungsstrecke deckt das Skript zusaetzlich ab:
// `questionnaire_releases`, `review_drafts`, `reviews` (ergaenzend),
// `public_reviews`, `company_scores`, `moderation_log`, `review_reports` und die
// beiden Buckets.
//
// Wer die CLI benutzt, braucht es fuer die neuen Tabellen nicht — dafuer gibt es
// appwrite/appwrite.config.template.json. Fuer `reviews` bleibt es der
// empfohlene Weg: Dort wird ergaenzt, und ein Push koennte anbieten, die Spalten
// der alten Strecke zu entfernen.

import { readFileSync } from 'node:fs';

const ENDPOINT = process.env.APPWRITE_ENDPOINT ?? 'https://fra.cloud.appwrite.io/v1';
const PROJECT = process.env.APPWRITE_PROJECT_ID;
const DATABASE = process.env.APPWRITE_DATABASE_ID;
const KEY = process.env.APPWRITE_API_KEY;

const DRY_RUN = process.argv.includes('--dry-run');
const FIX_PERMISSIONS = process.argv.includes('--fix-permissions');
const NUR_PRUEFEN = process.argv.includes('--pruefen');

// Projekt- und Datenbankkennung hatten hier einmal eingebaute Standardwerte.
// Das Repository ist oeffentlich; die Kennungen des Bestands standen damit im
// Klartext darin. Jetzt sind sie Pflicht — und ein Tippfehler laeuft nicht mehr
// still gegen das Produktivprojekt, weil niemand die Variable gesetzt hat.
// `--pruefen` vergleicht dieses Skript mit der CLI-Vorlage und faehrt nie ins
// Netz. Deshalb braucht es weder Projekt noch Schluessel.
const fehlend = NUR_PRUEFEN ? [] : [
  !PROJECT && 'APPWRITE_PROJECT_ID    die Projektkennung',
  !DATABASE && 'APPWRITE_DATABASE_ID   die Datenbankkennung',
  !KEY && 'APPWRITE_API_KEY       ein Schluessel mit databases.read und databases.write',
].filter(Boolean);

if (fehlend.length > 0) {
  console.error(
    'Es fehlen Angaben:\n\n' +
      fehlend.map((z) => `  ${z}`).join('\n') +
      '\n\nDen Schluessel legt die Console unter Overview → Integrations → API Keys\n' +
      'an. Fuer Buckets braucht er zusaetzlich "buckets.read" und "buckets.write".\n' +
      'Wo die Kennungen stehen, sagt notes/APPWRITE_SETUP.md.\n\n' +
      '  APPWRITE_PROJECT_ID=… APPWRITE_DATABASE_ID=… APPWRITE_API_KEY=… \\\n' +
      '    node tools/appwrite-setup.mjs --dry-run\n'
  );
  process.exit(1);
}

// ─── HTTP ────────────────────────────────────────────────────────────────────

async function call(method, path, body) {
  const res = await fetch(`${ENDPOINT}${path}`, {
    method,
    headers: {
      'X-Appwrite-Project': PROJECT,
      'X-Appwrite-Key': KEY,
      'Content-Type': 'application/json',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = { message: text.slice(0, 200) };
  }
  if (!res.ok) {
    const err = new Error(json.message ?? `HTTP ${res.status}`);
    err.status = res.status;
    err.type = json.type;
    throw err;
  }
  return json;
}

// Appwrite hat die Datenbank-API von `databases/collections/attributes` auf
// `tablesdb/tables/columns` umbenannt. Welcher Pfad bedient wird, haengt an der
// Version der Instanz – deshalb einmal ausprobieren statt raten.
let api = null;

async function detectApi() {
  try {
    await call('GET', `/tablesdb/${DATABASE}/tables?queries[]=${encodeURIComponent(JSON.stringify({ method: 'limit', values: [1] }))}`);
    return 'tablesdb';
  } catch (e) {
    if (e.status !== 404) throw e;
    return 'databases';
  }
}

const paths = {
  tablesdb: {
    tables: () => `/tablesdb/${DATABASE}/tables`,
    table: (t) => `/tablesdb/${DATABASE}/tables/${t}`,
    columns: (t) => `/tablesdb/${DATABASE}/tables/${t}/columns`,
    column: (t, kind) => `/tablesdb/${DATABASE}/tables/${t}/columns/${kind}`,
    indexes: (t) => `/tablesdb/${DATABASE}/tables/${t}/indexes`,
    listKey: 'columns',
    tableListKey: 'tables',
    idField: 'tableId',
    securityField: 'rowSecurity',
    indexColumnsField: 'columns',
    // Die Spaltenart heisst im Aufruf anders als im Schema: `double` wird ueber
    // `columns/float` angelegt.
    kinds: {
      varchar: 'varchar',
      text: 'text',
      double: 'float',
      integer: 'integer',
      boolean: 'boolean',
      datetime: 'datetime',
    },
  },
  databases: {
    tables: () => `/databases/${DATABASE}/collections`,
    table: (t) => `/databases/${DATABASE}/collections/${t}`,
    columns: (t) => `/databases/${DATABASE}/collections/${t}/attributes`,
    column: (t, kind) => `/databases/${DATABASE}/collections/${t}/attributes/${kind}`,
    indexes: (t) => `/databases/${DATABASE}/collections/${t}/indexes`,
    listKey: 'attributes',
    tableListKey: 'collections',
    idField: 'collectionId',
    securityField: 'documentSecurity',
    indexColumnsField: 'attributes',
    // Die aeltere API kennt weder `varchar` noch `text`. Beides ist dort ein
    // `string`; welcher MySQL-Typ daraus wird, entscheidet die Groesse.
    kinds: {
      varchar: 'string',
      text: 'string',
      double: 'float',
      integer: 'integer',
      boolean: 'boolean',
      datetime: 'datetime',
    },
  },
};

const p = () => paths[api];

// ─── Gewuenschter Zustand ────────────────────────────────────────────────────

const str = (key, size = 255, extra = {}) => ({ kind: 'varchar', key, size, required: false, ...extra });

/// Eine lange Zeichenkette. `text` zaehlt nicht auf die 64-KB-Grenze einer
/// MariaDB-Zeile, `varchar` schon — deshalb liegen `answers_json`, die Freitexte
/// und die JSON-Klumpen hier und nicht in einem `varchar`.
const txt = (key, extra = {}) => ({ kind: 'text', key, required: false, ...extra });

const num = (key, extra = {}) => ({ kind: 'double', key, required: false, ...extra });
const int = (key, extra = {}) => ({ kind: 'integer', key, required: false, ...extra });
const bool = (key, extra = {}) => ({ kind: 'boolean', key, required: false, ...extra });
const when = (key, extra = {}) => ({ kind: 'datetime', key, required: false, ...extra });

const TEAM_MODERATORS = process.env.KARRIKO_TEAM_MODERATORS ?? 'moderators';

/// Die sechs Subscores und die getrennte Berufsschule. Muss zu
/// `subscoreColumns` und `separateColumns` in packages/karriko_functions passen.
const SUBSCORES = [
  'sub_fachlich',
  'sub_betreuung',
  'sub_umgang',
  'sub_belastung',
  'sub_verguetung',
  'sub_perspektive',
  'sub_berufsschule',
].map((key) => num(key, { min: 1, max: 5 }));

const SCHEMA = [
  {
    id: 'companies',
    name: 'Companies',
    // Unternehmensprofile sind der oeffentliche Teil der Plattform; ohne
    // Leserecht fuer alle faende die Suche sie fuer Besucher nicht. Anlegen
    // duerfen angemeldete Nutzer – sonst scheitert die Betriebsregistrierung.
    //
    // **Kein `update("users")` auf Tabellenebene.** Das stand dort und hiess:
    // Jeder Angemeldete darf jede Firma aendern, auch `is_verified`,
    // `is_premium`, `average_rating` und `owner_id`. Der Client setzt beim
    // Anlegen schon ein Aenderungsrecht fuer den Eigentuemer **pro Zeile** —
    // das wirkt aber erst mit `rowSecurity`. Also beides: Recht weg, Schalter
    // an. Ein Betrieb bearbeitet danach weiter sein eigenes Profil.
    //
    // Was damit **nicht** behoben ist: Der Eigentuemer kann auf seiner eigenen
    // Zeile `is_verified` und `average_rating` setzen. Appwrite kennt keine
    // Rechte je Spalte. Dagegen hilft nur, Profilaenderungen ueber eine
    // Function zu fuehren — siehe notes/UMSETZUNG_BERICHT.md.
    permissions: ['read("any")', 'create("users")'],
    exactPermissions: true,
    rowSecurity: true,
    createIfMissing: false,
    columns: [
      // Der eigentliche Ausloeser des Fehlers.
      str('owner_id'),
      // Von `aggregate_company` gespiegelt, damit die Suche nach Bewertung
      // sortieren und filtern kann. Der angezeigte Score kommt aus
      // `company_scores`; dies hier ist eine Kopie fuer die Abfrage.
      num('average_rating', { min: 0, max: 5 }),
      int('review_count', { default: 0, min: 0 }),
    ],
    indexes: [
      { key: 'owner_id', type: 'key', columns: ['owner_id'] },
      // Der Client prueft die Slug-Kollision selbst, das ist aber ein Rennen.
      // Verbindlich ist nur der Index.
      { key: 'slug_unique', type: 'unique', columns: ['slug'], optional: true },
      // Die Suche sortiert absteigend danach und filtert mit einer Untergrenze.
      // Ohne Index liest Appwrite dafuer die Tabelle durch.
      { key: 'average_rating', type: 'key', columns: ['average_rating'], orders: ['DESC'] },
      // `Query.equal('industry', …)` im Filter der Suche.
      { key: 'industry', type: 'key', columns: ['industry'] },
    ],
  },
  {
    id: 'profiles',
    name: 'Profiles',
    permissions: null, // Profile gehoeren einzelnen Nutzern – Rechte nicht anfassen.
    createIfMissing: false,
    columns: [str('company_id')],
    indexes: [],
  },
  {
    id: 'jobs',
    name: 'Jobs',
    permissions: ['read("any")', 'create("users")'],
    createIfMissing: true,
    columns: [
      str('company_id'),
      str('company'),
      str('company_slug'),
      str('company_logo_url', 2048),
      str('title'),
      str('location'),
      str('profession'),
      str('industry'),
      str('employment_type'),
      str('duration'),
      str('salary'),
      str('apply_url', 2048),
      str('contact_email'),
      str('description', 20000),
      str('tasks', 1000, { array: true }),
      str('requirements', 1000, { array: true }),
      str('benefits', 1000, { array: true }),
      { kind: 'datetime', key: 'start_date', required: false },
      { kind: 'boolean', key: 'is_active', required: false, default: true },
    ],
    indexes: [
      { key: 'company_id', type: 'key', columns: ['company_id'] },
      { key: 'is_active', type: 'key', columns: ['is_active'] },
    ],
  },

  // ── Fragebogen ────────────────────────────────────────────────────────────
  //
  // Diese sieben kommen mit der Bewertungsstrecke dazu. Sie stehen auch in
  // appwrite/appwrite.config.template.json; wer die CLI benutzt, braucht dieses
  // Skript dafuer nicht. Es bleibt der Weg fuer `reviews`, denn dort wird
  // ergaenzt und nicht neu angelegt — und ein Push koennte anbieten, die
  // Spalten der alten Strecke zu entfernen.

  {
    id: 'questionnaire_releases',
    name: 'Questionnaire Releases',
    // Der Client laedt die aktive Fassung selbst. Die Fragen sind oeffentlich,
    // sobald jemand den Bogen aufruft — hier ist nichts zu schuetzen.
    permissions: ['read("any")'],
    createIfMissing: true,
    rowSecurity: false,
    columns: [
      str('locale', 10, { required: true }),
      int('version', { required: true, min: 1 }),
      str('bucket_id', 36, { required: true }),
      str('file_id', 36, { required: true }),
      str('checksum', 64),
      bool('active', { default: false }),
      when('published_at', { required: true }),
    ],
    indexes: [
      { key: 'locale_version_unique', type: 'unique', columns: ['locale', 'version'] },
      { key: 'locale_active_version', type: 'key', columns: ['locale', 'active', 'version'] },
    ],
  },

  {
    id: 'review_drafts',
    name: 'Review Drafts',
    // Anlegen darf jeder Angemeldete, lesen nur der Eigentuemer — und das steht
    // pro Zeile. Ohne rowSecurity waeren die Rechte, die der Client setzt,
    // wirkungslos.
    permissions: ['create("users")'],
    exactPermissions: true,
    createIfMissing: true,
    rowSecurity: true,
    columns: [
      str('user_id', 36, { required: true }),
      str('company_id', 36, { required: true }),
      int('schema_version', { required: true, min: 1 }),
      txt('answers_json'),
      txt('timings_json'),
      str('current_question_id', 64),
      str('invite_source', 64),
      when('updated_at', { required: true }),
    ],
    indexes: [
      { key: 'user_company_unique', type: 'unique', columns: ['user_id', 'company_id'] },
      { key: 'user_updated', type: 'key', columns: ['user_id', 'updated_at'] },
      { key: 'updated_at', type: 'key', columns: ['updated_at'] },
    ],
  },

  {
    id: 'reviews',
    name: 'Reviews',
    // Leer, und das ist der Punkt: Kein Client liest oder schreibt hier, auch
    // der Verfasser nicht. Was oeffentlich sein darf, steht in
    // `public_reviews`. Appwrite vergibt Rechte pro Zeile, nicht pro Spalte —
    // ein Leserecht hier gaebe die Rohantworten, die Zeiten, den Gerätehash und
    // die Nutzerkennung mit heraus.
    permissions: [],
    exactPermissions: true,
    createIfMissing: true,
    rowSecurity: false,
    // `status` ist bewusst ein `varchar` und kein Enum. Die Zustaende stehen in
    // `ReviewStatus` im Code; ein Enum waere eine zweite Liste davon, und ein
    // neuer Zustand liesse sich nicht ergaenzen, sondern nur durch Loeschen und
    // Neuanlegen der Spalte. Die alte Strecke hatte hier ein Enum mit drei
    // Werten, und genau daran waere jede Einreichung gescheitert.
    columns: [
      str('company_id', 36, { required: true }),
      str('user_id', 36, { required: true }),
      int('schema_version', { required: true, min: 1 }),
      str('status', 32, { required: true }),

      str('respondent_status', 32),
      str('beruf_code', 32),
      str('beruf_name', 128),
      int('start_year', { min: 1950, max: 2100 }),
      int('end_year', { min: 1950, max: 2100 }),
      bool('invited', { default: false }),
      str('invite_source', 64),

      int('k5_recommend', { min: 0, max: 10 }),
      int('k6_overall', { min: 0, max: 100 }),
      num('detail_overall', { min: 1, max: 5 }),
      ...SUBSCORES,

      str('quality_flags', 64, { array: true }),
      str('quality_notes', 512, { array: true }),

      when('publish_after'),
      bool('publish_after_training_end', { default: false }),

      txt('freitext_gut'),
      txt('freitext_schlecht'),
      txt('answers_json'),
      txt('timings_json'),

      str('verification_file_id', 36),
      bool('verified', { default: false }),
      when('verification_cleared_at'),
      str('device_hash', 64),
    ],
    indexes: [
      // Eine Bewertung je Nutzer und Betrieb. Die Function prueft das vorher,
      // damit der Azubi eine verstaendliche Meldung bekommt; verbindlich ist
      // dieser Index.
      { key: 'user_company_unique', type: 'unique', columns: ['user_id', 'company_id'], optional: true },
      { key: 'status', type: 'key', columns: ['status'] },
      { key: 'status_publish_after', type: 'key', columns: ['status', 'publish_after'] },
      { key: 'company_id_key', type: 'key', columns: ['company_id'] },
    ],
  },

  {
    id: 'public_reviews',
    name: 'Public Reviews',
    permissions: ['read("any")'],
    exactPermissions: true,
    createIfMissing: true,
    rowSecurity: false,
    columns: [
      str('review_id', 36, { required: true }),
      str('company_id', 36, { required: true }),
      str('company_name', 200),
      str('company_slug', 200),
      str('beruf_code', 32),
      str('beruf_name', 128),
      int('start_year', { min: 1950, max: 2100 }),
      int('end_year', { min: 1950, max: 2100 }),
      str('respondent_status', 32),
      int('k5_recommend', { min: 0, max: 10 }),
      int('k6_overall', { min: 0, max: 100 }),
      ...SUBSCORES,
      txt('freitext_gut'),
      txt('freitext_schlecht'),
      bool('is_aged', { default: false }),
      bool('verified', { default: false }),
      when('published_at', { required: true }),
    ],
    indexes: [
      { key: 'review_id_unique', type: 'unique', columns: ['review_id'] },
      { key: 'company_published', type: 'key', columns: ['company_id', 'published_at'] },
      { key: 'published_at', type: 'key', columns: ['published_at'] },
    ],
  },

  {
    id: 'company_scores',
    name: 'Company Scores',
    permissions: ['read("any")'],
    exactPermissions: true,
    createIfMissing: true,
    rowSecurity: false,
    columns: [
      str('company_id', 36, { required: true }),
      num('overall', { min: 1, max: 5 }),
      ...SUBSCORES,
      num('recommend_mean', { min: 0, max: 10 }),
      txt('weights_json'),
      int('review_count', { default: 0, min: 0 }),
      int('aged_count', { default: 0, min: 0 }),
      bool('score_visible', { default: false }),
      bool('numbers_visible', { default: false }),
      txt('bands_json'),
      when('updated_at', { required: true }),
    ],
    indexes: [
      { key: 'company_id_unique', type: 'unique', columns: ['company_id'] },
      { key: 'overall', type: 'key', columns: ['overall'] },
    ],
  },

  {
    id: 'moderation_log',
    name: 'Moderation Log',
    // Lesen darf die Moderation. Schreiben nur die Function — ein Eintrag, den
    // ein Client anlegen kann, belegt nichts.
    permissions: [`read("team:${TEAM_MODERATORS}")`],
    exactPermissions: true,
    createIfMissing: true,
    rowSecurity: false,
    columns: [
      str('review_id', 36, { required: true }),
      str('moderator_id', 36, { required: true }),
      str('action', 16, { required: true }),
      txt('reason'),
      str('flags', 64, { array: true }),
      when('created_at', { required: true }),
    ],
    indexes: [
      { key: 'review_created', type: 'key', columns: ['review_id', 'created_at'] },
      { key: 'moderator_id', type: 'key', columns: ['moderator_id'] },
    ],
  },

  {
    id: 'review_reports',
    name: 'Review Reports',
    // Eine Meldung ist kein Urteil: Sie legt eine Zeile an, mehr passiert
    // nicht. Der Melder liest seine eigene, die Moderation alle.
    permissions: ['create("users")', `read("team:${TEAM_MODERATORS}")`],
    createIfMissing: true,
    rowSecurity: true,
    columns: [
      str('review_id', 36, { required: true }),
      str('reporter_id', 36, { required: true }),
      txt('reason', { required: true }),
      str('status', 16, { default: 'open' }),
      str('resolved_by', 36),
      when('resolved_at'),
      txt('resolution_note'),
    ],
    indexes: [
      { key: 'review_id', type: 'key', columns: ['review_id'] },
      { key: 'reporter_id', type: 'key', columns: ['reporter_id'] },
    ],
  },
];

// ─── Ablagen ─────────────────────────────────────────────────────────────────

const BUCKETS = [
  {
    id: process.env.KARRIKO_BUCKET_QUESTIONNAIRES ?? 'questionnaires',
    name: 'Questionnaires',
    // Die Fragendefinition. Oeffentlich lesbar, weil der Client sie laedt;
    // schreiben darf nur ein Schluessel.
    permissions: ['read("any")'],
    fileSecurity: false,
    maximumFileSize: 5 * 1024 * 1024,
    allowedFileExtensions: ['json'],
    compression: 'gzip',
    encryption: false,
    antivirus: true,
  },
  {
    id: process.env.KARRIKO_BUCKET_VERIFICATION ?? 'verification_documents',
    name: 'Verification Documents',
    // Hochladen darf jeder Angemeldete, lesen niemand: Der Client setzt beim
    // Upload leere Rechte, und `fileSecurity` macht sie verbindlich. An den
    // Nachweis kommt nur, wer einen Schluessel hat — die Moderation ueber die
    // Console.
    permissions: ['create("users")'],
    fileSecurity: true,
    maximumFileSize: 10 * 1024 * 1024,
    allowedFileExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    compression: 'none',
    encryption: true,
    antivirus: true,
  },
];

// ─── Abgleich mit der CLI-Vorlage ────────────────────────────────────────────
//
// Es gibt zwei Wege, dasselbe Schema einzuspielen: dieses Skript und
// appwrite/appwrite.config.template.json. Zwei Beschreibungen desselben
// Gegenstands laufen auseinander, sobald eine gepflegt wird und die andere
// nicht — und dann haengt es am Weg, welches Schema entsteht. Dieser Vergleich
// macht daraus einen Fehler statt einer Ueberraschung.
//
// Die Vorlage ist die Wahrheit. Sie ist das, was eingespielt wird.

const VORLAGE = 'appwrite/appwrite.config.template.json';

function vorlageLesen() {
  const text = readFileSync(VORLAGE, 'utf8')
    .replaceAll('${TEAM_MODERATORS}', TEAM_MODERATORS)
    .replaceAll('${TEAM_ADMINS}', process.env.KARRIKO_TEAM_ADMINS ?? 'admins')
    .replaceAll(/\$\{[A-Z_]+\}/g, 'PLATZHALTER');
  return JSON.parse(text);
}

function pruefeGegenVorlage() {
  const vorlage = vorlageLesen();
  const befunde = [];
  const eigene = new Map(SCHEMA.map((s) => [s.id, s]));

  for (const tabelle of vorlage.tables) {
    const spec = eigene.get(tabelle.$id);
    if (!spec) {
      befunde.push(`${tabelle.$id}: in der Vorlage, aber nicht in diesem Skript`);
      continue;
    }

    if ((spec.rowSecurity ?? true) !== tabelle.rowSecurity) {
      befunde.push(
        `${tabelle.$id}: rowSecurity ${spec.rowSecurity ?? true} statt ${tabelle.rowSecurity}`
      );
    }

    const rechteHier = [...(spec.permissions ?? [])].sort().join(', ');
    const rechteDort = [...(tabelle.$permissions ?? [])].sort().join(', ');
    if (rechteHier !== rechteDort) {
      befunde.push(`${tabelle.$id}: Rechte [${rechteHier}] statt [${rechteDort}]`);
    }

    const hier = new Map(spec.columns.map((c) => [c.key, c]));
    for (const spalte of tabelle.columns) {
      const c = hier.get(spalte.key);
      if (!c) {
        befunde.push(`${tabelle.$id}.${spalte.key}: fehlt in diesem Skript`);
        continue;
      }
      hier.delete(spalte.key);
      const abweichung = [
        c.kind !== spalte.type ? `Art ${c.kind}/${spalte.type}` : null,
        (c.size ?? null) !== (spalte.size ?? null) ? `Groesse ${c.size}/${spalte.size}` : null,
        (c.required ?? false) !== (spalte.required ?? false)
          ? `required ${c.required ?? false}/${spalte.required ?? false}`
          : null,
        (c.array ?? false) !== (spalte.array ?? false)
          ? `array ${c.array ?? false}/${spalte.array ?? false}`
          : null,
        (c.min ?? null) !== (spalte.min ?? null) ? `min ${c.min}/${spalte.min}` : null,
        (c.max ?? null) !== (spalte.max ?? null) ? `max ${c.max}/${spalte.max}` : null,
      ].filter(Boolean);
      if (abweichung.length > 0) {
        befunde.push(`${tabelle.$id}.${spalte.key}: ${abweichung.join(', ')}`);
      }
    }
    for (const uebrig of hier.keys()) {
      befunde.push(`${tabelle.$id}.${uebrig}: in diesem Skript, aber nicht in der Vorlage`);
    }

    const indizesHier = new Set(spec.indexes.map((i) => `${i.type}:${i.columns.join('+')}`));
    for (const idx of tabelle.indexes ?? []) {
      const marke = `${idx.type}:${idx.columns.join('+')}`;
      if (!indizesHier.has(marke)) {
        befunde.push(`${tabelle.$id}: Index ${marke} fehlt in diesem Skript`);
      }
      indizesHier.delete(marke);
    }
    for (const uebrig of indizesHier) {
      befunde.push(`${tabelle.$id}: Index ${uebrig} steht nicht in der Vorlage`);
    }
  }

  const bucketsHier = new Map(BUCKETS.map((b) => [b.id, b]));
  for (const bucket of vorlage.buckets ?? []) {
    const b = bucketsHier.get(bucket.$id);
    if (!b) {
      befunde.push(`Bucket ${bucket.$id}: in der Vorlage, aber nicht in diesem Skript`);
      continue;
    }
    const felder = {
      fileSecurity: 'fileSecurity',
      maximumFileSize: 'maximumFileSize',
      compression: 'compression',
      encryption: 'encryption',
      antivirus: 'antivirus',
    };
    for (const feld of Object.keys(felder)) {
      if (b[feld] !== bucket[feld]) {
        befunde.push(`Bucket ${bucket.$id}.${feld}: ${b[feld]} statt ${bucket[feld]}`);
      }
    }
    const endungenHier = [...b.allowedFileExtensions].sort().join(',');
    const endungenDort = [...(bucket.allowedFileExtensions ?? [])].sort().join(',');
    if (endungenHier !== endungenDort) {
      befunde.push(`Bucket ${bucket.$id}: Endungen [${endungenHier}] statt [${endungenDort}]`);
    }
    const rechteHier = [...b.permissions].sort().join(', ');
    const rechteDort = [...(bucket.$permissions ?? [])].sort().join(', ');
    if (rechteHier !== rechteDort) {
      befunde.push(`Bucket ${bucket.$id}: Rechte [${rechteHier}] statt [${rechteDort}]`);
    }
  }

  if (befunde.length === 0) {
    console.log(
      `Skript und ${VORLAGE} beschreiben dasselbe Schema.\n` +
        `  ${vorlage.tables.length} Tabelle(n), ${(vorlage.buckets ?? []).length} Bucket(s) verglichen.`
    );
    process.exit(0);
  }

  console.error(
    `Skript und ${VORLAGE} weichen ab. Die Vorlage ist verbindlich — sie wird\n` +
      'eingespielt. Was hier steht, ist jeweils der Wert im Skript:\n\n' +
      befunde.map((z) => `  ✗ ${z}`).join('\n') +
      '\n'
  );
  process.exit(1);
}

if (NUR_PRUEFEN) pruefeGegenVorlage();

// ─── Ausfuehrung ─────────────────────────────────────────────────────────────

const log = (icon, text) => console.log(`${icon} ${text}`);

async function ensureTable(spec) {
  try {
    const table = await call('GET', p().table(spec.id));
    return { table, created: false };
  } catch (e) {
    if (e.status !== 404) throw e;
    if (!spec.createIfMissing) {
      log('✗', `${spec.id}: Sammlung fehlt und wird nicht automatisch angelegt.`);
      return null;
    }
    if (DRY_RUN) {
      log('·', `${spec.id}: wuerde angelegt`);
      return null;
    }
    const table = await call('POST', p().tables(), {
      [p().idField]: spec.id,
      name: spec.name,
      permissions: spec.permissions ?? [],
      // Rechte je Zeile wirken nur mit diesem Schalter. Er steht nicht
      // ueberall auf `true`: Wo der Client ohnehin nichts schreibt — in
      // `public_reviews`, `company_scores`, `reviews` —, waere er nur eine
      // zusaetzliche Stelle, an der ein Recht entstehen kann.
      [p().securityField]: spec.rowSecurity ?? true,
    });
    log('+', `${spec.id}: Sammlung angelegt`);
    return { table, created: true };
  }
}

async function ensureColumns(spec) {
  const existing = await call('GET', `${p().columns(spec.id)}?queries[]=${encodeURIComponent(JSON.stringify({ method: 'limit', values: [100] }))}`);
  const have = new Set((existing[p().listKey] ?? existing.columns ?? existing.attributes ?? []).map((c) => c.key));

  for (const col of spec.columns) {
    if (have.has(col.key)) continue;
    if (DRY_RUN) {
      log('·', `${spec.id}.${col.key}: wuerde angelegt (${col.kind})`);
      continue;
    }
    const kind = p().kinds[col.kind];
    if (!kind) throw new Error(`Unbekannte Spaltenart "${col.kind}" bei ${spec.id}.${col.key}`);

    const body = { key: col.key, required: col.required ?? false };
    if (col.array) body.array = true;

    if (col.kind === 'varchar') {
      body.size = col.size;
    } else if (col.kind === 'text' && kind === 'string') {
      // Die aeltere API kennt kein `text`. 65535 ist die Groesse, ab der
      // Appwrite dort einen TEXT-Typ waehlt — also genau das Gewuenschte.
      body.size = 65535;
    }

    if (col.min !== undefined) body.min = col.min;
    if (col.max !== undefined) body.max = col.max;

    // Ein Standardwert ist bei Pflichtfeldern und Arrays nicht erlaubt.
    if (col.default !== undefined && !col.array && !body.required) {
      body.default = col.default;
    }

    await call('POST', p().column(spec.id, kind), body);
    log('+', `${spec.id}.${col.key} (${col.kind})`);
  }
}

// Appwrite legt Spalten im Hintergrund an. Ein Index auf eine Spalte, die noch
// „processing" ist, wird abgelehnt – deshalb warten statt hoffen.
async function waitForColumns(spec, keys) {
  const deadline = Date.now() + 60_000;
  while (Date.now() < deadline) {
    const list = await call('GET', `${p().columns(spec.id)}?queries[]=${encodeURIComponent(JSON.stringify({ method: 'limit', values: [100] }))}`);
    const cols = list[p().listKey] ?? list.columns ?? list.attributes ?? [];
    const relevant = cols.filter((c) => keys.includes(c.key));
    if (relevant.length === keys.length && relevant.every((c) => c.status === 'available')) return true;
    await new Promise((r) => setTimeout(r, 1000));
  }
  return false;
}

async function ensureIndexes(spec) {
  if (spec.indexes.length === 0) return;
  const existing = await call('GET', p().indexes(spec.id));
  const have = new Set((existing.indexes ?? []).map((i) => i.key));

  for (const idx of spec.indexes) {
    if (have.has(idx.key)) continue;
    if (DRY_RUN) {
      log('·', `${spec.id}: Index ${idx.key} wuerde angelegt`);
      continue;
    }
    const ready = await waitForColumns(spec, idx.columns);
    if (!ready) {
      log('!', `${spec.id}: Index ${idx.key} uebersprungen – Spalten noch nicht bereit. Skript spaeter erneut laufen lassen.`);
      continue;
    }
    try {
      await call('POST', p().indexes(spec.id), {
        key: idx.key,
        type: idx.type,
        [p().indexColumnsField]: idx.columns,
        orders: idx.orders ?? idx.columns.map(() => 'ASC'),
      });
      log('+', `${spec.id}: Index ${idx.key} (${idx.type})`);
    } catch (e) {
      // Ein eindeutiger Index scheitert an bereits doppelten Werten. Das ist
      // ein Datenbefund, kein Skriptfehler – melden und weitermachen.
      if (idx.optional) log('!', `${spec.id}: Index ${idx.key} nicht angelegt – ${e.message}`);
      else throw e;
    }
  }
}

async function checkPermissions(spec, table) {
  if (!spec.permissions) return;
  const current = table.$permissions ?? [];
  const missing = spec.permissions.filter((perm) => !current.includes(perm));

  // `exactPermissions` heisst: Auch ein Recht **zu viel** ist ein Befund. Fuer
  // `reviews` ist das der ganze Punkt — dort stand in der alten Strecke ein
  // Leserecht fuer alle, und mit den neuen Spalten gaebe das die Rohantworten,
  // die Zeiten, den Geraetehash und die Nutzerkennung heraus.
  const extra = spec.exactPermissions
    ? current.filter((perm) => !spec.permissions.includes(perm))
    : [];

  const gewuenscht = spec.exactPermissions
    ? [...spec.permissions]
    : [...new Set([...current, ...spec.permissions])];

  if (missing.length === 0 && extra.length === 0) return;

  const befund = [
    missing.length > 0 ? `fehlen: ${missing.join(', ')}` : null,
    extra.length > 0 ? `zu viel: ${extra.join(', ')}` : null,
  ]
    .filter(Boolean)
    .join(' · ');

  if (!FIX_PERMISSIONS) {
    log('!', `${spec.id}: Rechte weichen ab – ${befund}. Mit --fix-permissions setzen.`);
    if (extra.length > 0) {
      log(
        ' ',
        `  Das entfernt ein bestehendes Recht. Bitte vorher lesen, wofuer es da war.`
      );
    }
    return;
  }
  if (DRY_RUN) {
    log('·', `${spec.id}: Rechte wuerden gesetzt auf [${gewuenscht.join(', ')}] – ${befund}`);
    return;
  }

  const security = table.rowSecurity ?? table.documentSecurity;
  await call('PUT', p().table(spec.id), {
    name: table.name,
    permissions: gewuenscht,
    [p().securityField]: spec.rowSecurity ?? security ?? true,
    enabled: table.enabled ?? true,
  });
  log('+', `${spec.id}: Rechte gesetzt – ${befund}`);
}

// ─── Buckets ─────────────────────────────────────────────────────────────────

/// Legt einen Bucket an, wenn er fehlt. Ein vorhandener wird **nicht**
/// umgeschrieben: Groessengrenzen, Dateiendungen und Verschluesselung eines
/// Buckets, in dem schon Dateien liegen, sind eine Entscheidung und keine
/// Reparatur. Abweichungen werden gemeldet.
async function ensureBucket(spec) {
  const gewuenscht = {
    bucketId: spec.id,
    name: spec.name,
    permissions: spec.permissions,
    fileSecurity: spec.fileSecurity,
    enabled: true,
    maximumFileSize: spec.maximumFileSize,
    allowedFileExtensions: spec.allowedFileExtensions,
    compression: spec.compression,
    encryption: spec.encryption,
    antivirus: spec.antivirus,
  };

  let bucket = null;
  try {
    bucket = await call('GET', `/storage/buckets/${spec.id}`);
  } catch (e) {
    if (e.status !== 404) throw e;
  }

  if (bucket === null) {
    if (DRY_RUN) {
      log('·', `${spec.id}: Bucket wuerde angelegt`);
      return;
    }
    await call('POST', '/storage/buckets', gewuenscht);
    log('+', `${spec.id}: Bucket angelegt`);
    return;
  }

  const abweichungen = [];
  const vergleich = {
    fileSecurity: bucket.fileSecurity,
    maximumFileSize: bucket.maximumFileSize,
    compression: bucket.compression,
    encryption: bucket.encryption,
    antivirus: bucket.antivirus,
  };
  for (const [feld, ist] of Object.entries(vergleich)) {
    const soll = gewuenscht[feld];
    if (ist !== soll) abweichungen.push(`${feld}: ${ist} statt ${soll}`);
  }

  const endungenIst = [...(bucket.allowedFileExtensions ?? [])].sort().join(',');
  const endungenSoll = [...spec.allowedFileExtensions].sort().join(',');
  if (endungenIst !== endungenSoll) {
    abweichungen.push(`allowedFileExtensions: [${endungenIst}] statt [${endungenSoll}]`);
  }

  const rechteFehlen = spec.permissions.filter(
    (perm) => !(bucket.$permissions ?? []).includes(perm)
  );
  if (rechteFehlen.length > 0) abweichungen.push(`Rechte fehlen: ${rechteFehlen.join(', ')}`);

  if (abweichungen.length === 0) {
    log('·', `${spec.id}: Bucket passt`);
    return;
  }
  log('!', `${spec.id}: Bucket weicht ab —`);
  for (const a of abweichungen) log(' ', `  ${a}`);
  log(' ', '  Bewusst nicht automatisch geaendert. Siehe notes/APPWRITE_SETUP.md.');
}

async function main() {
  api = await detectApi();
  console.log(`Appwrite ${ENDPOINT} · Projekt ${PROJECT} · Datenbank ${DATABASE} · API "${api}"`);
  if (DRY_RUN) console.log('— Probelauf, es wird nichts geaendert —');

  for (const spec of SCHEMA) {
    console.log(`\n── ${spec.id} ──`);
    const result = await ensureTable(spec);
    if (!result) continue;
    await ensureColumns(spec);
    await ensureIndexes(spec);
    await checkPermissions(spec, result.table);
  }

  console.log('\n── Ablagen ──');
  for (const spec of BUCKETS) {
    try {
      await ensureBucket(spec);
    } catch (e) {
      // Ein Schluessel ohne Storage-Rechte soll nicht das ganze Skript
      // abbrechen — die Tabellen sind zu dem Zeitpunkt schon fertig.
      log('✗', `${spec.id}: ${e.message}`);
      log(' ', '  Braucht "buckets.read" und "buckets.write" im Schluessel.');
    }
  }

  console.log(
    '\nFertig.\n\n' +
      'Was dieses Skript nicht tut, und was deshalb noch fehlt:\n' +
      '  · Teams `moderators` und `admins`\n' +
      '  · die sieben Functions samt Variablen, Cron und Ereignissen\n' +
      '  · die Fragendefinition im Bucket und die Zeile in questionnaire_releases\n\n' +
      'Der Weg dahin steht Schritt fuer Schritt in notes/APPWRITE_SETUP.md.\n' +
      'Wer die CLI benutzt, nimmt statt dieses Skripts appwrite.config.json —\n' +
      'nur `reviews` bleibt hier, weil dort ergaenzt und nicht neu angelegt wird.'
  );
}

main().catch((e) => {
  console.error(`\nAbgebrochen: ${e.message}${e.type ? ` (${e.type})` : ''}`);
  process.exit(1);
});
