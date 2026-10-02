#!/usr/bin/env node
//
// Erzeugt appwrite/appwrite.config.json aus appwrite/appwrite.config.template.json.
//
// Warum der Umweg
// ---------------
// Die CLI braucht in der Konfiguration die echte Projekt- und Datenbankkennung.
// Die Ereignisnamen tragen die Datenbankkennung sogar mitten im String:
//
//   tablesdb.<DATENBANK>.tables.public_reviews.rows.*.create
//
// Das Repository ist oeffentlich, und dort gehoert keine echte Kennung hinein.
// Also liegt im Repository die Vorlage mit Platzhaltern, und die einzuspielende
// Datei entsteht daraus vor dem Push. Sie steht in der .gitignore.
//
// Aufruf
// ------
//
//   APPWRITE_PROJECT_ID=… APPWRITE_DATABASE_ID=… node tools/appwrite-config.mjs
//   … node tools/appwrite-config.mjs --pruefen
//
// `--pruefen` schreibt nichts und endet mit Code 1, wenn die erzeugte Datei
// fehlt oder nicht zur Vorlage passt. Fuer die CI und fuer den Moment vor einem
// Push: Eine Konfiguration, die aelter ist als die Vorlage, spielt ein
// veraltetes Schema ein.
//
// Alle Variablen stehen mit Erklaerung in notes/APPWRITE_SETUP.md.

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';

const VORLAGE = 'appwrite/appwrite.config.template.json';
const ZIEL = 'appwrite/appwrite.config.json';

const NUR_PRUEFEN = process.argv.includes('--pruefen');

// Was ersetzt wird, und woher es kommt. Ein Standardwert steht nur, wo der Wert
// keine Kennung ist: Namen sind frei waehlbar, Kennungen nicht ratbar.
const WERTE = {
  PROJECT_ID: { env: 'APPWRITE_PROJECT_ID', pflicht: true },
  DATABASE_ID: { env: 'APPWRITE_DATABASE_ID', pflicht: true },
  PROJECT_NAME: { env: 'APPWRITE_PROJECT_NAME', standard: 'Karriko' },
  // Muss genau so heissen wie die bestehende Datenbank, sonst benennt der Push
  // sie um.
  DATABASE_NAME: { env: 'APPWRITE_DATABASE_NAME', standard: 'Karriko' },
  ENDPOINT: {
    env: 'APPWRITE_ENDPOINT',
    standard: 'https://fra.cloud.appwrite.io/v1',
  },
  TEAM_MODERATORS: { env: 'KARRIKO_TEAM_MODERATORS', standard: 'moderators' },
  TEAM_ADMINS: { env: 'KARRIKO_TEAM_ADMINS', standard: 'admins' },
};

function werte() {
  const out = {};
  const fehlt = [];

  for (const [name, regel] of Object.entries(WERTE)) {
    const roh = process.env[regel.env];
    const wert = roh === undefined || roh.trim() === '' ? regel.standard : roh.trim();
    if (wert === undefined) fehlt.push(`${name}  (Umgebungsvariable ${regel.env})`);
    else out[name] = wert;
  }

  if (fehlt.length > 0) {
    console.error(
      'Es fehlen Werte:\n\n' +
        fehlt.map((z) => `  ${z}`).join('\n') +
        '\n\nDiese beiden Kennungen haben absichtlich keinen Standardwert: Ein\n' +
        'geratener Wert wuerde gegen ein fremdes oder nicht vorhandenes Projekt\n' +
        'laufen. Wo sie stehen, sagt notes/APPWRITE_SETUP.md.\n'
    );
    process.exit(1);
  }
  return out;
}

/// Entfernt alle `_hinweis`-Schluessel, rekursiv. Die Vorlage erklaert sich
/// selbst; in der eingespielten Datei hat das nichts zu suchen.
function ohneHinweise(knoten) {
  if (Array.isArray(knoten)) return knoten.map(ohneHinweise);
  if (knoten !== null && typeof knoten === 'object') {
    const out = {};
    for (const [key, value] of Object.entries(knoten)) {
      if (key === '_hinweis') continue;
      out[key] = ohneHinweise(value);
    }
    return out;
  }
  return knoten;
}

function erzeugen(ersetzungen) {
  if (!existsSync(VORLAGE)) {
    console.error(
      `Nicht gefunden: ${VORLAGE}\n` +
        'Das Skript laeuft im Wurzelverzeichnis des Repositories.'
    );
    process.exit(1);
  }

  let text = readFileSync(VORLAGE, 'utf8');

  for (const [name, wert] of Object.entries(ersetzungen)) {
    text = text.replaceAll(`\${${name}}`, wert);
  }

  // Ein uebrig gebliebener Platzhalter waere spaeter ein Fehler der CLI mit
  // einer Meldung, die auf alles andere hindeutet.
  const uebrig = [...text.matchAll(/\$\{([A-Z_]+)\}/g)].map((m) => m[1]);
  if (uebrig.length > 0) {
    console.error(
      `In ${VORLAGE} stehen Platzhalter, die dieses Skript nicht kennt: ` +
        `${[...new Set(uebrig)].join(', ')}\n` +
        'Entweder in WERTE ergaenzen oder in der Vorlage korrigieren.'
    );
    process.exit(1);
  }

  let daten;
  try {
    daten = JSON.parse(text);
  } catch (e) {
    console.error(`${VORLAGE} ist kein gueltiges JSON: ${e.message}`);
    process.exit(1);
  }

  return JSON.stringify(ohneHinweise(daten), null, 2) + '\n';
}

const ersetzungen = werte();
const inhalt = erzeugen(ersetzungen);

if (NUR_PRUEFEN) {
  if (!existsSync(ZIEL)) {
    console.error(
      `${ZIEL} fehlt.\n` +
        'Mit `node tools/appwrite-config.mjs` erzeugen — vor jedem Push.'
    );
    process.exit(1);
  }
  const vorhanden = readFileSync(ZIEL, 'utf8');
  if (vorhanden !== inhalt) {
    console.error(
      `${ZIEL} weicht von der Vorlage ab.\n` +
        'Mit `node tools/appwrite-config.mjs` angleichen, sonst spielt der Push\n' +
        'ein veraltetes Schema ein.'
    );
    process.exit(1);
  }
  console.log(`${ZIEL} ist auf dem Stand der Vorlage.`);
  process.exit(0);
}

writeFileSync(ZIEL, inhalt, 'utf8');

console.log(
  `${ZIEL} geschrieben.\n\n` +
    `  Projekt    ${ersetzungen.PROJECT_ID}\n` +
    `  Datenbank  ${ersetzungen.DATABASE_ID}\n` +
    `  Endpunkt   ${ersetzungen.ENDPOINT}\n` +
    `  Teams      ${ersetzungen.TEAM_MODERATORS}, ${ersetzungen.TEAM_ADMINS}\n\n` +
    'Die Datei steht in der .gitignore und gehoert nicht ins Repository.\n' +
    `Gepusht wird aus ${dirname(join(process.cwd(), ZIEL))}, nicht von hier.\n`
);
