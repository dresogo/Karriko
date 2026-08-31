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
//
// `--fix-permissions` setzt zusaetzlich die Rechte bestehender Sammlungen auf
// „Lesen fuer alle, Anlegen fuer angemeldete Nutzer". Bewusst nicht Standard:
// Rechte zu weiten ist eine Entscheidung, keine Reparatur. Ohne den Schalter
// meldet das Skript nur, was abweicht.

const ENDPOINT = process.env.APPWRITE_ENDPOINT ?? 'https://fra.cloud.appwrite.io/v1';
const PROJECT = process.env.APPWRITE_PROJECT_ID ?? '6a3c45ef003356d7f16d';
const DATABASE = process.env.APPWRITE_DATABASE_ID ?? '6a3ea0a4002b4cf10630';
const KEY = process.env.APPWRITE_API_KEY;

const DRY_RUN = process.argv.includes('--dry-run');
const FIX_PERMISSIONS = process.argv.includes('--fix-permissions');

if (!KEY) {
  console.error(
    'APPWRITE_API_KEY fehlt.\n' +
      'In der Console unter Overview → Integrations → API Keys einen Schluessel\n' +
      'mit Scope "databases.read" und "databases.write" anlegen und setzen:\n\n' +
      '  APPWRITE_API_KEY=… node tools/appwrite-setup.mjs\n'
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
  },
};

const p = () => paths[api];

// ─── Gewuenschter Zustand ────────────────────────────────────────────────────

const str = (key, size = 255, extra = {}) => ({ kind: 'string', key, size, required: false, ...extra });

const SCHEMA = [
  {
    id: 'companies',
    name: 'Companies',
    // Unternehmensprofile sind der oeffentliche Teil der Plattform; ohne
    // Leserecht fuer alle faende die Suche sie fuer Besucher nicht. Anlegen
    // duerfen angemeldete Nutzer – sonst scheitert die Betriebsregistrierung.
    permissions: ['read("any")', 'create("users")'],
    createIfMissing: false,
    columns: [
      // Der eigentliche Ausloeser des Fehlers.
      str('owner_id'),
    ],
    indexes: [
      { key: 'owner_id', type: 'key', columns: ['owner_id'] },
      // Der Client prueft die Slug-Kollision selbst, das ist aber ein Rennen.
      // Verbindlich ist nur der Index.
      { key: 'slug_unique', type: 'unique', columns: ['slug'], optional: true },
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
];

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
      // Der Client setzt Rechte je Dokument (Lesen fuer alle, Aendern und
      // Loeschen nur fuer den Eigentuemer). Ohne diesen Schalter waeren sie
      // wirkungslos.
      [p().securityField]: true,
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
    const body = { key: col.key, required: col.required ?? false };
    if (col.kind === 'string') {
      body.size = col.size;
      if (col.array) body.array = true;
    }
    // Ein Standardwert ist bei Pflichtfeldern und Arrays nicht erlaubt.
    if (col.default !== undefined && !col.array) body.default = col.default;
    await call('POST', p().column(spec.id, col.kind), body);
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
        orders: idx.columns.map(() => 'ASC'),
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
  if (missing.length === 0) return;

  if (!FIX_PERMISSIONS) {
    log('!', `${spec.id}: Rechte fehlen – ${missing.join(', ')}. Mit --fix-permissions setzen.`);
    return;
  }
  if (DRY_RUN) {
    log('·', `${spec.id}: Rechte wuerden ergaenzt – ${missing.join(', ')}`);
    return;
  }
  await call('PUT', p().table(spec.id), {
    name: table.name,
    permissions: [...new Set([...current, ...spec.permissions])],
    [p().securityField]: table.rowSecurity ?? table.documentSecurity ?? true,
    enabled: table.enabled ?? true,
  });
  log('+', `${spec.id}: Rechte ergaenzt – ${missing.join(', ')}`);
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

  console.log(
    '\nFertig. Danach im Betriebskonto einmal neu laden: `ensureCompany()` findet\n' +
      'das Unternehmen dann ueber `owner_id` oder legt es an und verknuepft es.'
  );
}

main().catch((e) => {
  console.error(`\nAbgebrochen: ${e.message}${e.type ? ` (${e.type})` : ''}`);
  process.exit(1);
});
