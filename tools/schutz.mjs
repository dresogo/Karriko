// Schutz fuer erzeugte Dateien mit echten Werten (E-1.18).
//
// `appwrite-config.mjs` und `appwrite-function-env.mjs` erzeugen Dateien, die
// nicht im Repository stehen und echte Kennungen und Geheimnisse tragen:
// `appwrite/appwrite.config.json` und `appwrite/functions/*/.env`. Am
// 28.10.2026 wurden sie lokal mit den Platzhaltern aus der CI ueberschrieben;
// dabei fiel auch das Salz fuer den Geraetehash weg. Es gab keine Sicherung,
// zurueck ging es nur ueber die Variablen der deployten Functions.
//
// Deshalb gilt fuer beide Skripte:
//
//   * Eine vorhandene Datei wird nur ueberschrieben, wenn dabei kein
//     vorhandener Wert verschwindet oder sich aendert. Sonst bricht das Skript
//     ab und nennt die betroffenen Schluessel, nie die Werte.
//   * `--ueberschreiben` erlaubt es trotzdem, etwa nach einem Wechsel des
//     Projekts. Vorher wird die alte Datei gesichert.
//   * Gesichert wird nach `appwrite/.sicherung/<Zeitpunkt>/…`, ausserhalb der
//     Function-Ordner: Was in einem Function-Ordner liegt, laedt
//     `appwrite push` mit hoch.
//
// In der CI gibt es die Dateien noch nicht; dort aendert sich nichts.

import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';

export const UEBERSCHREIBEN = process.argv.includes('--ueberschreiben');

const SICHERUNG = 'appwrite/.sicherung';
const zeitpunkt = new Date().toISOString().replace(/[:.]/g, '-');

/// Liest `KEY=WERT`-Zeilen; Kommentare und Leerzeilen zaehlen nicht.
export function envWerte(text) {
  const out = {};
  for (const zeile of text.split(/\r?\n/)) {
    const m = zeile.match(/^([A-Z0-9_]+)=(.*)$/);
    if (m) out[m[1]] = m[2];
  }
  return out;
}

/// Welche Schluessel beim Ersetzen von [alt] durch [neu] verschwinden oder
/// einen anderen Wert bekommen.
export function verloreneWerte(alt, neu) {
  return Object.keys(alt).filter(
    (k) => alt[k] !== '' && (!(k in neu) || neu[k] !== alt[k])
  );
}

/// Schreibt [text] nach [ziel], aber nur, wenn dabei nichts verloren geht
/// oder `--ueberschreiben` gesetzt ist. [werte] bildet einen Dateiinhalt auf
/// die zu schuetzenden Schluessel und Werte ab.
///
/// Liefert `false`, wenn nicht geschrieben wurde; der Aufrufer bricht dann ab.
export function sicherSchreiben(ziel, text, werte) {
  if (existsSync(ziel)) {
    const alt = readFileSync(ziel, 'utf8');
    if (alt === text) return true;

    const verloren = verloreneWerte(werte(alt), werte(text));
    if (verloren.length > 0 && !UEBERSCHREIBEN) {
      console.error(
        `✗ ${ziel}: Diese Werte wuerden verschwinden oder sich aendern: ` +
          `${verloren.join(', ')}.\n` +
          '  Nichts geschrieben. Stimmen die Umgebungsvariablen? Wenn das ' +
          'gewollt ist: mit --ueberschreiben, die alte Datei wird vorher ' +
          'gesichert (E-1.18).'
      );
      return false;
    }

    const sicherung = join(SICHERUNG, zeitpunkt, relative('appwrite', ziel));
    mkdirSync(dirname(sicherung), { recursive: true });
    copyFileSync(ziel, sicherung);
    console.log(`  Gesichert: ${sicherung}`);
  }
  writeFileSync(ziel, text, 'utf8');
  return true;
}
