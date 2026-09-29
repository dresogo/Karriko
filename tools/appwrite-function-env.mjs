#!/usr/bin/env node
//
// Schreibt appwrite/functions/<name>/.env aus der Umgebung.
//
// Warum nicht von Hand
// --------------------
// Die CLI liest die Variablen einer Function aus einer `.env` in deren
// Verzeichnis und spielt sie mit `appwrite push function --with-variables` ein.
// Bei sechs Functions waeren das sechs Dateien mit fast demselben Inhalt — und
// eine davon haette irgendwann einen Tippfehler, den man erst an einer
// Fehlermeldung ueber eine nicht vorhandene Datenbank merkt.
//
// Warum nicht jede Function alles bekommt
// ---------------------------------------
// Das Salz fuer den Geraetehash geht nur an `submit_review`. Nur dort wird
// gehasht. Ein Geheimnis, das in sechs Umgebungen liegt, ist an sechs Stellen
// einsehbar — und fuenf davon brauchen es nicht.
//
// Aufruf
// ------
//
//   KARRIKO_DATABASE_ID=… KARRIKO_DEVICE_HASH_SALT=… \
//     node tools/appwrite-function-env.mjs
//
//   node tools/appwrite-function-env.mjs --pruefen
//
// `--pruefen` schreibt nichts und meldet, welche Datei fehlt oder abweicht.
//
// Die erzeugten Dateien stehen in der .gitignore. Alle Variablen stehen mit
// Erklaerung in notes/APPWRITE_SETUP.md.

import { readFileSync, writeFileSync, existsSync } from 'node:fs';

const BASIS = 'appwrite/functions';
const NUR_PRUEFEN = process.argv.includes('--pruefen');

/// Was jede Function braucht.
///
/// `KARRIKO_DATABASE_ID` hat absichtlich keinen Standardwert: Ein geratener Wert
/// liefe gegen eine erfundene Datenbank und erzeugte eine Fehlermeldung, die auf
/// alles andere hindeutet. Die Functions brechen ohne sie beim Start ab und
/// sagen, welche Variable fehlt.
const GEMEINSAM = [
  { name: 'KARRIKO_DATABASE_ID', pflicht: true },
];

/// Alles Weitere hat in `FunctionConfig` einen Standardwert und steht hier nur,
/// wenn es in der Umgebung gesetzt ist. Eine `.env` mit einer Zeile
/// `KARRIKO_TBL_REVIEWS=reviews` sagt nichts, was der Code nicht schon weiss.
const OPTIONAL = [
  'KARRIKO_TBL_REVIEWS',
  'KARRIKO_TBL_PUBLIC_REVIEWS',
  'KARRIKO_TBL_DRAFTS',
  'KARRIKO_TBL_COMPANY_SCORES',
  'KARRIKO_TBL_MODERATION_LOG',
  'KARRIKO_TBL_RELEASES',
  'KARRIKO_TBL_COMPANIES',
  'KARRIKO_BUCKET_QUESTIONNAIRES',
  'KARRIKO_BUCKET_VERIFICATION',
  'KARRIKO_TEAM_MODERATORS',
  'KARRIKO_TEAM_ADMINS',
];

/// Wer was zusaetzlich bekommt. Der Rest der Fristen steht in den
/// Standardwerten; sie sind in notes/APPWRITE_SETUP.md als **juristisch zu
/// pruefen** gekennzeichnet, und wer sie aendert, setzt sie hier.
const JE_FUNCTION = {
  submit_review: [
    // Ohne Salz wird nicht gehasht, statt mit einem eingebauten Ersatzwert
    // weiterzumachen: Ein bekanntes Salz ist kein Salz.
    'KARRIKO_DEVICE_HASH_SALT',
    'KARRIKO_DELAY_DAYS',
    'KARRIKO_SMALL_BUSINESS_DELAY_MONTHS',
  ],
  publish_scheduled: ['KARRIKO_SMALL_BUSINESS_DELAY_MONTHS'],
  cleanup: ['KARRIKO_DRAFT_RETENTION_DAYS', 'KARRIKO_VERIFICATION_RETENTION_DAYS'],
  moderate_review: [],
  aggregate_company: [],
  recompute_all: [],
};

const fehlt = GEMEINSAM.filter(
  (v) => v.pflicht && (process.env[v.name] ?? '').trim() === ''
).map((v) => v.name);

if (fehlt.length > 0) {
  console.error(
    `Es fehlen Pflichtvariablen: ${fehlt.join(', ')}\n\n` +
      'Wo die Datenbankkennung steht, sagt notes/APPWRITE_SETUP.md.\n'
  );
  process.exit(1);
}

function inhaltFuer(name) {
  const zeilen = [
    '# Erzeugt von tools/appwrite-function-env.mjs. Nicht von Hand aendern und',
    '# nicht ins Repository. Eingespielt mit:',
    '#   appwrite push function --with-variables',
    '',
  ];

  const nehmen = [
    ...GEMEINSAM.map((v) => v.name),
    ...OPTIONAL,
    ...(JE_FUNCTION[name] ?? []),
  ];

  let geschrieben = 0;
  for (const variable of nehmen) {
    const wert = (process.env[variable] ?? '').trim();
    if (wert === '') continue;
    zeilen.push(`${variable}=${wert}`);
    geschrieben++;
  }

  return { text: zeilen.join('\n') + '\n', anzahl: geschrieben };
}

const namen = Object.keys(JE_FUNCTION).sort();
let abweichungen = 0;

for (const name of namen) {
  const ordner = `${BASIS}/${name}`;
  if (!existsSync(ordner)) {
    console.error(`✗ ${name}: ${ordner} gibt es nicht.`);
    process.exit(1);
  }

  const ziel = `${ordner}/.env`;
  const { text, anzahl } = inhaltFuer(name);

  if (NUR_PRUEFEN) {
    if (!existsSync(ziel)) {
      console.log(`✗ ${name}: .env fehlt`);
      abweichungen++;
    } else if (readFileSync(ziel, 'utf8') !== text) {
      console.log(`✗ ${name}: .env weicht ab`);
      abweichungen++;
    } else {
      console.log(`· ${name}: .env passt (${anzahl} Variable(n))`);
    }
    continue;
  }

  writeFileSync(ziel, text, 'utf8');
  const mitSalz = (JE_FUNCTION[name] ?? []).includes('KARRIKO_DEVICE_HASH_SALT') &&
    (process.env.KARRIKO_DEVICE_HASH_SALT ?? '').trim() !== '';
  console.log(`+ ${ziel} (${anzahl} Variable(n)${mitSalz ? ', mit Salz' : ''})`);
}

if (NUR_PRUEFEN) {
  if (abweichungen > 0) {
    console.error(
      `\n${abweichungen} Datei(en) weichen ab. Mit ` +
        '`node tools/appwrite-function-env.mjs` angleichen.'
    );
    process.exit(1);
  }
  process.exit(0);
}

if ((process.env.KARRIKO_DEVICE_HASH_SALT ?? '').trim() === '') {
  console.log(
    '\n! KARRIKO_DEVICE_HASH_SALT ist nicht gesetzt. Ohne Salz wird die\n' +
      '  Geraetekennung nicht gehasht, sondern gar nicht gespeichert. Das ist\n' +
      '  eine gueltige Betriebsart — aber dann gibt es auch keinen Hinweis mehr\n' +
      '  darauf, dass zwei Bewertungen vom selben Geraet kamen.'
  );
}

console.log(
  '\nDie Dateien stehen in der .gitignore. Eingespielt werden sie mit\n' +
    '`appwrite push function --with-variables` aus dem Ordner appwrite/.'
);
