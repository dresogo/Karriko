#!/usr/bin/env node
//
// Loescht die Zeilen der alten Bewertungsstrecke aus `reviews`.
//
// Warum es dieses Skript gibt
// ---------------------------
// Die alte Strecke hat Bewertungen in einem Schema gespeichert, das die neue
// nicht lesen kann: eine Sternebewertung und ein Freitext, ohne Antworten, ohne
// Zeiten, ohne Version. Diese Zeilen in die neue Auswertung zu nehmen hiesse,
// Werte zu erfinden, die niemand angegeben hat. Also gehen sie weg — so war die
// Entscheidung.
//
// Warum es niemand versehentlich ausfuehrt
// ---------------------------------------
// Ein Loeschen ist nicht umkehrbar. Deshalb:
//
//   1. Ohne Schalter ist es ein **Probelauf**. Es wird gezaehlt, nicht geloescht.
//   2. Vor jedem Loeschen entsteht ein **vollstaendiger Export**. Scheitert der,
//      wird nicht geloescht.
//   3. Geloescht wird nur mit `--wirklich-loeschen` **und** `--anzahl=<n>`, und
//      nur wenn n genau der gezaehlten Zahl entspricht. Wer die Zahl nicht
//      kennt, hat den Probelauf nicht gelesen.
//
// Aufruf
// ------
//
//   APPWRITE_API_KEY=… APPWRITE_PROJECT_ID=… APPWRITE_DATABASE_ID=… \
//     node tools/appwrite-purge-reviews.mjs
//
//   … node tools/appwrite-purge-reviews.mjs --wirklich-loeschen --anzahl=137
//
// Weitere Schalter:
//
//   --tabelle=<id>      Standard `reviews`.
//   --nur-alte          Nur Zeilen ohne `schema_version` — also nur die der
//                       alten Strecke. Empfohlen, sobald neue dazukommen.
//   --export-nach=<p>   Standard notes/reports/exporte/.
//
// Der Export landet ausserhalb des Repositories im Sinne der .gitignore: Er
// enthaelt Rohantworten und Nutzerkennungen.

import { writeFileSync, mkdirSync, existsSync } from 'node:fs';

const ENDPOINT = process.env.APPWRITE_ENDPOINT ?? 'https://fra.cloud.appwrite.io/v1';
const PROJECT = process.env.APPWRITE_PROJECT_ID;
const DATABASE = process.env.APPWRITE_DATABASE_ID;
const KEY = process.env.APPWRITE_API_KEY;

const args = process.argv.slice(2);
const flag = (name) => args.includes(`--${name}`);
const wert = (name, standard) => {
  const treffer = args.find((a) => a.startsWith(`--${name}=`));
  return treffer === undefined ? standard : treffer.slice(name.length + 3);
};

const WIRKLICH = flag('wirklich-loeschen');
const NUR_ALTE = flag('nur-alte');
const TABELLE = wert('tabelle', 'reviews');
const EXPORT_NACH = wert('export-nach', 'notes/reports/exporte');
const ERWARTET = wert('anzahl', null);

if (!PROJECT || !DATABASE || !KEY) {
  console.error(
    'Es fehlen Angaben. Alle drei sind Pflicht, keine hat einen Standardwert:\n\n' +
      '  APPWRITE_PROJECT_ID    die Projektkennung\n' +
      '  APPWRITE_DATABASE_ID   die Datenbankkennung\n' +
      '  APPWRITE_API_KEY       ein Schluessel mit rows.read und rows.write\n\n' +
      'Ein geratener Wert wuerde gegen ein fremdes Projekt laufen. Wo die\n' +
      'Kennungen stehen, sagt notes/APPWRITE_SETUP.md.\n'
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
    throw err;
  }
  return json;
}

const query = (...qs) =>
  qs.map((q) => `queries[]=${encodeURIComponent(JSON.stringify(q))}`).join('&');

// Wie in tools/appwrite-setup.mjs: Welcher Pfad bedient wird, haengt an der
// Version der Instanz — einmal ausprobieren statt raten.
async function ermittleApi() {
  try {
    await call('GET', `/tablesdb/${DATABASE}/tables/${TABELLE}/rows?${query({ method: 'limit', values: [1] })}`);
    return 'tablesdb';
  } catch (e) {
    if (e.status !== 404) throw e;
    return 'databases';
  }
}

let api = null;
const pfade = {
  tablesdb: {
    rows: () => `/tablesdb/${DATABASE}/tables/${TABELLE}/rows`,
    row: (id) => `/tablesdb/${DATABASE}/tables/${TABELLE}/rows/${id}`,
    listKey: 'rows',
  },
  databases: {
    rows: () => `/databases/${DATABASE}/collections/${TABELLE}/documents`,
    row: (id) => `/databases/${DATABASE}/collections/${TABELLE}/documents/${id}`,
    listKey: 'documents',
  },
};
const p = () => pfade[api];

// ─── Lesen ───────────────────────────────────────────────────────────────────

/// Liest alles seitenweise. Ueber `offset` und nicht ueber einen Cursor: Beim
/// Loeschen verschiebt sich die Seite, deshalb wird erst vollstaendig gelesen
/// und danach geloescht — nicht abwechselnd.
async function alleZeilen() {
  const out = [];
  let offset = 0;
  const seitengroesse = 100;

  for (;;) {
    const qs = [
      { method: 'limit', values: [seitengroesse] },
      { method: 'offset', values: [offset] },
    ];
    const seite = await call('GET', `${p().rows()}?${query(...qs)}`);
    const zeilen = seite[p().listKey] ?? seite.rows ?? seite.documents ?? [];
    out.push(...zeilen);
    if (zeilen.length < seitengroesse) break;
    offset += seitengroesse;
    process.stdout.write(`\r  ${out.length} gelesen …`);
  }
  if (out.length > 100) process.stdout.write('\r');
  return out;
}

/// Eine Zeile der alten Strecke hat keine `schema_version`. Das ist das
/// verlaesslichste Unterscheidungsmerkmal: Jede Zeile, die `submit_review`
/// angelegt hat, traegt sie, und zwar als Pflichtfeld.
const istAlt = (zeile) => {
  const daten = zeile.data ?? zeile;
  return daten.schema_version === undefined || daten.schema_version === null;
};

// ─── Ausfuehrung ─────────────────────────────────────────────────────────────

async function main() {
  api = await ermittleApi();
  console.log(
    `Appwrite ${ENDPOINT}\n` +
      `Projekt ${PROJECT} · Datenbank ${DATABASE} · Tabelle ${TABELLE} · API "${api}"\n`
  );

  const alle = await alleZeilen();
  const betroffen = NUR_ALTE ? alle.filter(istAlt) : alle;
  const verschont = alle.length - betroffen.length;

  console.log(`  ${alle.length} Zeile(n) in ${TABELLE}`);
  if (NUR_ALTE) {
    console.log(`  ${betroffen.length} davon ohne schema_version — nur die sind gemeint`);
    console.log(`  ${verschont} Zeile(n) bleiben`);
  }
  if (!NUR_ALTE) {
    const neue = alle.length - alle.filter(istAlt).length;
    if (neue > 0) {
      console.log(
        `\n! ${neue} Zeile(n) tragen eine schema_version, kommen also aus der\n` +
          '  neuen Strecke. Ohne --nur-alte werden sie mit geloescht.\n'
      );
    }
  }

  if (betroffen.length === 0) {
    console.log('\nNichts zu tun.');
    return;
  }

  if (!WIRKLICH) {
    console.log(
      `\n— Probelauf, es wird nichts geloescht —\n\n` +
        'Zum Loeschen, mit genau dieser Zahl:\n\n' +
        `  node tools/appwrite-purge-reviews.mjs${NUR_ALTE ? ' --nur-alte' : ''}` +
        ` --wirklich-loeschen --anzahl=${betroffen.length}\n\n` +
        'Der Export entsteht dann zuerst. Scheitert er, wird nicht geloescht.\n'
    );
    return;
  }

  if (ERWARTET === null) {
    console.error(
      `\nAbgebrochen: --anzahl fehlt.\n\n` +
        `Es wuerden ${betroffen.length} Zeile(n) geloescht. Gib diese Zahl mit:\n\n` +
        `  --wirklich-loeschen --anzahl=${betroffen.length}\n\n` +
        'Der Umweg ist Absicht: Wer die Zahl nicht kennt, hat den Probelauf\n' +
        'nicht gelesen.\n'
    );
    process.exit(1);
  }

  if (Number(ERWARTET) !== betroffen.length) {
    console.error(
      `\nAbgebrochen: --anzahl=${ERWARTET}, gefunden wurden aber ` +
        `${betroffen.length}.\n\n` +
        'Zwischen dem Probelauf und jetzt hat sich der Bestand geaendert.\n' +
        'Probelauf erneut ausfuehren und die neue Zahl pruefen.\n'
    );
    process.exit(1);
  }

  // ── Export ────────────────────────────────────────────────────────────────

  if (!existsSync(EXPORT_NACH)) mkdirSync(EXPORT_NACH, { recursive: true });

  const stempel = new Date().toISOString().replace(/[:.]/g, '-');
  const datei = `${EXPORT_NACH}/${TABELLE}-${stempel}.json`;

  try {
    writeFileSync(
      datei,
      JSON.stringify(
        {
          exportiert_am: new Date().toISOString(),
          endpunkt: ENDPOINT,
          projekt: PROJECT,
          datenbank: DATABASE,
          tabelle: TABELLE,
          nur_alte: NUR_ALTE,
          anzahl: betroffen.length,
          zeilen: betroffen,
        },
        null,
        2
      ),
      'utf8'
    );
  } catch (e) {
    console.error(
      `\nAbgebrochen: Der Export nach ${datei} ist gescheitert — ${e.message}\n\n` +
        'Ohne Export wird nicht geloescht.\n'
    );
    process.exit(1);
  }

  console.log(`\n+ Export: ${datei} (${betroffen.length} Zeile(n))`);
  console.log(
    '  Die Datei enthaelt Rohantworten und Nutzerkennungen. Sie steht ueber\n' +
      '  die .gitignore ausserhalb des Repositories — bitte auch dort so\n' +
      '  aufbewahren, wie es fuer diese Daten vorgesehen ist.\n'
  );

  // ── Loeschen ──────────────────────────────────────────────────────────────

  let geloescht = 0;
  const gescheitert = [];

  for (const zeile of betroffen) {
    try {
      await call('DELETE', p().row(zeile.$id));
      geloescht++;
      if (geloescht % 25 === 0 || geloescht === betroffen.length) {
        process.stdout.write(`\r  ${geloescht}/${betroffen.length} geloescht`);
      }
    } catch (e) {
      gescheitert.push(`${zeile.$id}: ${e.message}`);
    }
  }
  process.stdout.write('\n');

  console.log(`\n${geloescht} Zeile(n) geloescht.`);

  if (gescheitert.length > 0) {
    console.error(
      `\n! ${gescheitert.length} nicht geloescht:\n` +
        gescheitert.slice(0, 10).map((z) => `  ${z}`).join('\n') +
        (gescheitert.length > 10 ? `\n  … und ${gescheitert.length - 10} weitere` : '') +
        '\n\nDas Skript ist wiederholbar: Ein zweiter Lauf nimmt nur noch, was\n' +
        'uebrig ist. Der Export von oben bleibt vollstaendig.\n'
    );
    process.exit(1);
  }

  console.log(
    '\nDanach: Die Aggregate der betroffenen Betriebe stehen noch auf den alten\n' +
      'Zahlen. `recompute_all` und anschliessend `aggregate_company` bringen sie\n' +
      'auf den Stand — der Ablauf steht in notes/APPWRITE_SETUP.md.\n'
  );
}

main().catch((e) => {
  console.error(`\nAbgebrochen: ${e.message}`);
  process.exit(1);
});
