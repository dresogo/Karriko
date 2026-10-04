#!/usr/bin/env node
//
// Legt ein Admin-Konto fuer die Entwicklung an und traegt es in die Teams
// `admins` und `moderators` ein.
//
// Warum ein Skript
// ----------------
// Der Admin-Bereich unter /#/admin prueft die Teams des Kontos. Ein Konto von
// Hand anzulegen und zweimal einem Team zuzuordnen, sind drei Schritte in der
// Console — und der dritte wird vergessen. Ueber die CLI (mit deren
// Server-Rechten) wird das Konto ausserdem direkt Mitglied, ohne Einladungsmail.
//
// Das Passwort
// ------------
// Wird hier zufaellig erzeugt und **nur einmal** im Terminal ausgegeben. Es
// steht nirgends im Repository. Wer es verliert, ruft das Skript mit
// `--neues-passwort` erneut auf.
//
// Aufruf (aus der Repository-Wurzel, angemeldete Appwrite-CLI vorausgesetzt):
//
//   node tools/appwrite-dev-admin.mjs
//   node tools/appwrite-dev-admin.mjs --email ich@example.de --name "Ich"
//   node tools/appwrite-dev-admin.mjs --neues-passwort
//   node tools/appwrite-dev-admin.mjs --pruefen      zeigt nur den Stand
//
// Ein zweiter Aufruf legt nichts doppelt an: Gibt es das Konto schon, werden
// nur die fehlenden Mitgliedschaften ergaenzt.

import { spawnSync } from 'node:child_process';
import { randomInt } from 'node:crypto';

const args = process.argv.slice(2);
const wert = (name, standard) => {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] ? args[i + 1] : standard;
};

const EMAIL = wert('--email', 'admin@karriko.de');
const NAME = wert('--name', 'Dev Admin');
const NEUES_PASSWORT = args.includes('--neues-passwort');
const NUR_PRUEFEN = args.includes('--pruefen');
const TEAMS = [
  process.env.KARRIKO_TEAM_ADMINS || 'admins',
  process.env.KARRIKO_TEAM_MODERATORS || 'moderators',
];

/// Nur Buchstaben und Ziffern: Das Passwort geht als Argument an die CLI, und
/// unter Windows laeuft die ueber eine Shell. Sonderzeichen muessten dort
/// maskiert werden. 24 Zeichen aus 62 sind reichlich.
function passwort() {
  const zeichen =
    'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  return Array.from({ length: 24 }, () => zeichen[randomInt(zeichen.length)])
    .join('');
}

function cli(...befehl) {
  const r = spawnSync('appwrite', [...befehl, '--json'], {
    cwd: 'appwrite',
    encoding: 'utf8',
    shell: process.platform === 'win32',
  });
  if (r.status !== 0) {
    const fehler = (r.stderr || r.stdout || '').trim();
    throw new Error(`appwrite ${befehl.slice(0, 2).join(' ')}: ${fehler}`);
  }
  const text = (r.stdout || '').trim();
  return text ? JSON.parse(text) : {};
}

// ── Konto ──────────────────────────────────────────────────────────────────

const vorhanden = cli('users', 'list', '--limit', '100').users?.find(
  (u) => u.email?.toLowerCase() === EMAIL.toLowerCase()
);

if (NUR_PRUEFEN) {
  console.log(vorhanden
    ? `· Konto ${EMAIL} gibt es (${vorhanden.$id}).`
    : `✗ Konto ${EMAIL} gibt es nicht.`);
  for (const team of TEAMS) {
    const mitglieder =
      cli('teams', 'list-memberships', '--team-id', team).memberships ?? [];
    const drin = vorhanden && mitglieder.some((m) => m.userId === vorhanden.$id);
    console.log(`${drin ? '·' : '✗'} ${team}: ${mitglieder.length} Mitglied(er)` +
      `${vorhanden ? (drin ? ', Konto ist dabei' : ', Konto fehlt') : ''}`);
  }
  process.exit(0);
}

let userId;
let neuesPasswort = null;

if (vorhanden) {
  userId = vorhanden.$id;
  console.log(`· Konto ${EMAIL} gibt es schon (${userId}).`);
  if (NEUES_PASSWORT) {
    neuesPasswort = passwort();
    cli('users', 'update-password', '--user-id', userId, '--password', neuesPasswort);
    console.log('+ Neues Passwort gesetzt.');
  }
} else {
  neuesPasswort = passwort();
  const neu = cli(
    'users', 'create',
    // In Anfuehrungszeichen: Unter Windows laeuft die CLI ueber cmd.exe.
    '--user-id', '"unique()"',
    '--email', EMAIL,
    '--password', neuesPasswort,
    '--name', `"${NAME}"`
  );
  userId = neu.$id;
  console.log(`+ Konto ${EMAIL} angelegt (${userId}).`);
}

// Ohne bestaetigte Adresse schickte die Web-App das Konto auf die
// Bestaetigungsseite, sobald es eine geschuetzte Seite oeffnet.
cli('users', 'update-email-verification', '--user-id', userId, '--email-verification');

// ── Teams ──────────────────────────────────────────────────────────────────

for (const team of TEAMS) {
  const mitglieder = cli('teams', 'list-memberships', '--team-id', team).memberships ?? [];
  if (mitglieder.some((m) => m.userId === userId)) {
    console.log(`· Schon Mitglied in ${team}.`);
    continue;
  }
  cli('teams', 'create-membership', '--team-id', team, '--user-id', userId, '--roles', 'member');
  console.log(`+ Mitglied in ${team}.`);
}

// ── Ergebnis ───────────────────────────────────────────────────────────────

console.log('\nAnmelden unter  http://localhost:8080/#/admin');
console.log(`Nutzername      ${EMAIL}`);
if (neuesPasswort) {
  console.log(`Passwort        ${neuesPasswort}`);
  console.log('\nDas Passwort wird nur dieses eine Mal angezeigt. Nur fuer die');
  console.log('Entwicklung — fuer den Betrieb ein eigenes Konto mit eigenem Passwort.');
} else {
  console.log('Passwort        unveraendert (mit --neues-passwort neu setzen)');
}
