#!/usr/bin/env node
//
// Stellt die Datenbank auf den Stand vom 2. Oktober 2026 wieder her.
//
// Warum es das gibt
// -----------------
// Am 4. Oktober hat ein `appwrite push table -f` mit einer gekuerzten
// Konfiguration alle Tabellen ausser `review_reports` geloescht. Backups gab es
// keine. Dieses Skript legt Schema und die bekannten Zeilen neu an.
//
// Woher die Angaben stammen
// -------------------------
// * Alttabellen (`companies`, `profiles`, `bookmarks`, `jobs`): die
//   Schemaanalyse vom 1. Oktober, ergaenzt um das, was
//   `tools/appwrite-setup.mjs --fix-permissions` am 2. Oktober gesetzt hat
//   (Rechte und Row Security von `companies`, Indizes `average_rating` und
//   `industry`).
// * Bewertungsstrecke: `appwrite/appwrite.config.json`, aus der Vorlage
//   erzeugt — dieselbe Quelle, aus der sie am 2. Oktober kam.
// * Zeilen: die beiden Testbetriebe (Abfrage vom 31. August, Felder von
//   „Karriko-Test" aus den Prefs des Betriebskontos) und die Release-Zeile vom
//   2. Oktober. **Mit ihren alten Kennungen** — die Prefs des Betriebskontos
//   zeigen auf `6a956ccca9ad8456c0c0`.
//
// Was es **nie** tut: loeschen, `push`, bestehende Spalten aendern. Es legt nur
// an, was fehlt, und ist deshalb beliebig oft aufrufbar.
//
// Aufruf (aus der Repository-Wurzel, angemeldete CLI, vorher
// `node tools/appwrite-config.mjs`):
//
//   node tools/appwrite-wiederherstellen.mjs              zeigt nur den Plan
//   node tools/appwrite-wiederherstellen.mjs --ausfuehren legt an

import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const AUSFUEHREN = process.argv.includes('--ausfuehren');
const KONFIG = JSON.parse(readFileSync('appwrite/appwrite.config.json', 'utf8'));
const DB = KONFIG.tablesDB?.[0]?.$id ?? process.env.APPWRITE_DATABASE_ID;
if (!DB) {
  console.error('Keine Datenbankkennung. Erst `node tools/appwrite-config.mjs`.');
  process.exit(1);
}

// Die CLI direkt ueber Node, nicht ueber appwrite.cmd: Ohne Shell kommen die
// JSON-Daten der Zeilen unversehrt an.
const CLI = join(process.env.APPDATA ?? '', 'npm', 'node_modules', 'appwrite-cli', 'run.js');

function cli(...args) {
  const r = spawnSync(process.execPath, [CLI, ...args, '--json'], {
    cwd: 'appwrite',
    encoding: 'utf8',
  });
  if (r.status !== 0) {
    throw new Error((r.stderr || r.stdout || '').trim());
  }
  const text = (r.stdout || '').trim();
  return text ? JSON.parse(text) : {};
}

// ── Soll-Zustand ────────────────────────────────────────────────────────────

const v = (key, size, extra = {}) => ({ key, type: 'varchar', size, required: false, ...extra });
const ALT = [
  {
    $id: 'companies',
    name: 'Companies',
    $permissions: ['read("any")', 'create("users")'],
    rowSecurity: true,
    columns: [
      v('slug', 200, { required: true }),
      v('name', 200, { required: true }),
      { key: 'logo_url', type: 'url', required: false },
      { key: 'description', type: 'text', required: false },
      v('industry', 100),
      v('city', 100),
      v('country', 100),
      { key: 'website', type: 'url', required: false },
      { key: 'average_rating', type: 'double', required: false, min: 0, max: 5 },
      { key: 'review_count', type: 'integer', required: false, default: 0, min: 0 },
      { key: 'is_premium', type: 'boolean', required: false, default: false },
      { key: 'is_verified', type: 'boolean', required: false, default: false },
      v('owner_id', 255),
    ],
    indexes: [
      { key: 'slug_unique', type: 'unique', columns: ['slug'] },
      { key: 'owner_id', type: 'key', columns: ['owner_id'] },
      { key: 'idx_name_fulltext', type: 'fulltext', columns: ['name'] },
      { key: 'idx_city_fulltext', type: 'fulltext', columns: ['city'] },
      { key: 'average_rating', type: 'key', columns: ['average_rating'], orders: ['DESC'] },
      { key: 'industry', type: 'key', columns: ['industry'] },
    ],
  },
  {
    $id: 'profiles',
    name: 'Profiles',
    $permissions: [],
    rowSecurity: false,
    columns: [
      { key: 'email', type: 'email', required: true },
      v('role', 20, { required: true }),
      v('first_name', 100),
      // So stand es da, auch wenn 10 Zeichen fuer Nachnamen zu wenig sind —
      // offener Punkt in notes/todo.md, nicht Teil der Wiederherstellung.
      v('last_name', 10),
      { key: 'avatar_url', type: 'url', required: false },
      v('company_name', 200),
      v('profession', 100),
      v('city', 100),
      v('company_id', 255),
    ],
    indexes: [],
  },
  {
    $id: 'bookmarks',
    name: 'Bookmarks',
    $permissions: [],
    rowSecurity: false,
    columns: [
      v('user_id', 36, { required: true }),
      v('company_id', 36, { required: true }),
    ],
    indexes: [{ key: 'user_id', type: 'key', columns: ['user_id'] }],
  },
  {
    $id: 'jobs',
    name: 'Jobs',
    $permissions: ['read("any")', 'create("users")'],
    rowSecurity: true,
    columns: [
      v('company_id', 255),
      v('company', 255),
      v('company_slug', 255),
      v('company_logo_url', 2048),
      v('title', 255),
      v('location', 255),
      v('profession', 255),
      v('industry', 255),
      v('employment_type', 255),
      v('duration', 255),
      v('salary', 255),
      v('apply_url', 2048),
      v('contact_email', 255),
      // War eine `string`-Spalte mit 20 000 Zeichen. `varchar` endet bei
      // 16 381; Appwrite hatte sie intern ohnehin als Text gefuehrt.
      { key: 'description', type: 'text', required: false },
      v('tasks', 1000, { array: true }),
      v('requirements', 1000, { array: true }),
      v('benefits', 1000, { array: true }),
      { key: 'start_date', type: 'datetime', required: false },
      { key: 'is_active', type: 'boolean', required: false, default: true },
    ],
    indexes: [
      { key: 'company_id', type: 'key', columns: ['company_id'] },
      { key: 'is_active', type: 'key', columns: ['is_active'] },
    ],
  },
];

const STRECKE = KONFIG.tables.filter((t) =>
  ['questionnaire_releases', 'review_drafts', 'reviews', 'public_reviews',
    'company_scores', 'moderation_log'].includes(t.$id)
);

const TABELLEN = [...ALT, ...STRECKE];

const ZEILEN = [
  {
    table: 'companies',
    id: '6a3ec464003c9afa5ca2',
    data: {
      slug: 'test-gmbh', name: 'Test GmbH', industry: 'IT & Technik', city: 'Berlin',
      review_count: 0, is_premium: false, is_verified: false,
      // So stand es da: verwaist, zeigt auf die eigene Zeile.
      owner_id: '6a3ec464003c9afa5ca2',
    },
    // Ursprünglich ohne Zeilenrechte. Leer laesst die CLI nicht zu (sie setzt
    // dann den eigenen Console-Nutzer ein); read("any") wirkt wie vorher, weil
    // die Tabelle es ohnehin vergibt.
    permissions: ['read("any")'],
  },
  {
    table: 'companies',
    id: '6a956ccca9ad8456c0c0',
    data: {
      slug: 'karriko-test', name: 'Karriko-Test', industry: 'Medien & Kreatives', city: 'München',
      review_count: 0, is_premium: false, is_verified: false,
      owner_id: '6a70b575346d3e3e8f92',
    },
    permissions: ['read("any")', 'update("user:6a70b575346d3e3e8f92")'],
  },
  {
    table: 'questionnaire_releases',
    // Am 2. Oktober versehentlich mit der Kennung „unique" angelegt. Gefunden
    // wird die Zeile ueber locale und active, nicht ueber die Kennung.
    id: 'unique',
    data: {
      locale: 'de-DE', version: 1, bucket_id: 'questionnaires', file_id: 'questionnaire-v1',
      checksum: 'f91d22514bb7966362790f5f3b9a59bcc100768cd195efeda9eebffc85277cfe',
      active: true, published_at: '2026-10-02T15:21:36.000Z',
    },
    permissions: ['read("any")'],
  },
];

// ── Ablauf ──────────────────────────────────────────────────────────────────

const plan = [];
const vorhanden = new Set(
  (cli('tables-db', 'list-tables', '--database-id', DB).tables ?? []).map((t) => t.$id)
);

function spalteAnlegen(tabelle, s) {
  const basis = ['--database-id', DB, '--table-id', tabelle, '--key', s.key];
  basis.push(`--required=${Boolean(s.required)}`);
  if (s.array) basis.push('--array');
  const def = s.default !== undefined && !s.required;
  switch (s.type) {
    case 'varchar':
      return cli('tables-db', 'create-varchar-column', ...basis, '--size', String(s.size),
        ...(def ? ['--xdefault', String(s.default)] : []));
    case 'text':
      return cli('tables-db', 'create-text-column', ...basis);
    case 'integer':
      return cli('tables-db', 'create-integer-column', ...basis,
        ...(s.min !== undefined ? ['--min', String(s.min)] : []),
        ...(s.max !== undefined ? ['--max', String(s.max)] : []),
        ...(def ? ['--xdefault', String(s.default)] : []));
    case 'double':
      return cli('tables-db', 'create-float-column', ...basis,
        ...(s.min !== undefined ? ['--min', String(s.min)] : []),
        ...(s.max !== undefined ? ['--max', String(s.max)] : []),
        ...(def ? ['--xdefault', String(s.default)] : []));
    case 'boolean':
      return cli('tables-db', 'create-boolean-column', ...basis,
        ...(def ? [`--xdefault=${s.default}`] : []));
    case 'datetime':
      return cli('tables-db', 'create-datetime-column', ...basis);
    case 'email':
      return cli('tables-db', 'create-email-column', ...basis);
    case 'url':
      return cli('tables-db', 'create-url-column', ...basis);
    default:
      throw new Error(`Unbekannter Spaltentyp ${s.type}`);
  }
}

/// Spalten entstehen asynchron. Indizes und Zeilen scheitern, solange eine
/// Spalte noch `processing` ist.
async function warteAufSpalten(tabelle) {
  for (let i = 0; i < 60; i++) {
    const spalten = cli('tables-db', 'list-columns', '--database-id', DB, '--table-id', tabelle).columns ?? [];
    const offen = spalten.filter((s) => s.status !== 'available');
    if (offen.length === 0) return;
    if (offen.some((s) => s.status === 'failed')) {
      throw new Error(`${tabelle}: Spalte gescheitert: ${offen.map((s) => s.key).join(', ')}`);
    }
    await new Promise((r) => setTimeout(r, 2000));
  }
  throw new Error(`${tabelle}: Spalten nach zwei Minuten nicht bereit.`);
}

for (const t of TABELLEN) {
  if (!vorhanden.has(t.$id)) {
    plan.push(`+ Tabelle ${t.$id} (${t.columns.length} Spalten, ${t.indexes.length} Indizes)`);
    if (AUSFUEHREN) {
      cli('tables-db', 'create-table', '--database-id', DB, '--table-id', t.$id, '--name', t.name,
        ...t.$permissions.flatMap((p) => ['--permissions', p]),
        ...(t.rowSecurity ? ['--row-security'] : []));
    }
  } else {
    plan.push(`· Tabelle ${t.$id} besteht`);
  }
  if (!AUSFUEHREN) continue;

  const da = new Set(
    (cli('tables-db', 'list-columns', '--database-id', DB, '--table-id', t.$id).columns ?? [])
      .map((s) => s.key)
  );
  for (const s of t.columns) {
    if (da.has(s.key)) continue;
    spalteAnlegen(t.$id, s);
    console.log(`  + ${t.$id}.${s.key}`);
  }
  await warteAufSpalten(t.$id);

  const idx = new Set(
    (cli('tables-db', 'list-indexes', '--database-id', DB, '--table-id', t.$id).indexes ?? [])
      .map((i) => i.key)
  );
  for (const i of t.indexes) {
    if (idx.has(i.key)) continue;
    try {
      cli('tables-db', 'create-index', '--database-id', DB, '--table-id', t.$id,
        '--key', i.key, '--type', i.type,
        ...i.columns.flatMap((c) => ['--columns', c]),
        ...(i.orders ?? []).flatMap((o) => ['--orders', o]));
      console.log(`  + Index ${t.$id}.${i.key}`);
    } catch (e) {
      console.log(`  ! Index ${t.$id}.${i.key}: ${e.message.split('\n').pop()}`);
    }
  }
}

for (const z of ZEILEN) {
  if (!AUSFUEHREN) {
    plan.push(`+ Zeile ${z.table}/${z.id}`);
    continue;
  }
  await warteAufSpalten(z.table);
  try {
    cli('tables-db', 'get-row', '--database-id', DB, '--table-id', z.table, '--row-id', z.id);
    console.log(`· Zeile ${z.table}/${z.id} besteht`);
    continue;
  } catch {
    // fehlt — anlegen
  }
  cli('tables-db', 'create-row', '--database-id', DB, '--table-id', z.table, '--row-id', z.id,
    '--data', JSON.stringify(z.data),
    ...z.permissions.flatMap((p) => ['--permissions', p]));
  console.log(`+ Zeile ${z.table}/${z.id}`);
}

if (!AUSFUEHREN) {
  console.log(plan.join('\n'));
  console.log('\nNur der Plan. Mit --ausfuehren wird angelegt (nie geloescht).');
} else {
  console.log('\nFertig.');
}
