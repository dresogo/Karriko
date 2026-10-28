import { createServer } from 'node:http';
import { loadConfig } from './config.ts';
import { AppwritePasskeyStore } from './store.ts';
import { createSessionToken, hasMfa, userFromJwt } from './appwrite.ts';
import { corsHeaders, handle, type HandlerDeps } from './handler.ts';

/**
 * Lokaler HTTP-Server.
 *
 * Bewusst auf `node:http` statt auf einem Framework: Der Dienst hat sechs
 * Routen. Jede zusaetzliche Abhaengigkeit waere Angriffsflaeche fuer eine
 * Bequemlichkeit, die hier vierzig Zeilen spart.
 */
const config = loadConfig();

/**
 * Groesste angenommene Anfrage. Eine WebAuthn-Antwort ist wenige Kilobyte
 * gross; 64 KB lassen reichlich Luft.
 */
const MAX_BODY_BYTES = 64 * 1024;

const deps: HandlerDeps = {
  config,
  store: new AppwritePasskeyStore(config),
  issueSessionToken: (userId) => createSessionToken(config, userId),
  hasMfa: (userId) => hasMfa(config, userId),
  authenticate: userFromJwt,
};

const server = createServer(async (req, res) => {
  const origin = req.headers.origin;
  const cors = corsHeaders(config, origin);

  if (req.method === 'OPTIONS') {
    res.writeHead(204, cors);
    res.end();
    return;
  }

  let body: unknown = {};
  if (req.method === 'POST') {
    // Mit Obergrenze (T-4.42): Die Anmelde-Routen sind ohne Anmeldung
    // erreichbar, ein unbegrenzter Rumpf landete sonst komplett im Speicher.
    const chunks: Buffer[] = [];
    let groesse = 0;
    for await (const chunk of req) {
      groesse += (chunk as Buffer).length;
      if (groesse > MAX_BODY_BYTES) {
        res.writeHead(413, { 'Content-Type': 'application/json', ...cors });
        res.end(JSON.stringify({ message: 'Anfrage zu groß.' }));
        req.destroy();
        return;
      }
      chunks.push(chunk as Buffer);
    }
    const raw = Buffer.concat(chunks).toString('utf8');
    if (raw) {
      try {
        body = JSON.parse(raw);
      } catch {
        res.writeHead(400, { 'Content-Type': 'application/json', ...cors });
        res.end(JSON.stringify({ message: 'Ungültiges JSON.' }));
        return;
      }
    }
  }

  const url = new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`);

  try {
    const result = await handle(deps, {
      method: req.method ?? 'GET',
      path: url.pathname,
      headers: { authorization: req.headers.authorization },
      body,
    });
    res.writeHead(result.status, {
      'Content-Type': 'application/json',
      ...cors,
    });
    res.end(JSON.stringify(result.body));
  } catch (error) {
    // Keine Fehlerdetails nach aussen: Sie koennten verraten, welche Konten
    // oder Passkeys es gibt. Ins Log gehoert die Ursache trotzdem.
    console.error('Unbehandelter Fehler:', error);
    res.writeHead(500, { 'Content-Type': 'application/json', ...cors });
    res.end(JSON.stringify({ message: 'Interner Fehler.' }));
  }
});

// Langsame Anfragen nicht beliebig lange offen halten (T-4.42): Kopf und
// Rumpf muessen innerhalb von zehn Sekunden vollstaendig da sein.
server.headersTimeout = 10_000;
server.requestTimeout = 10_000;

server.listen(config.port, () => {
  console.log(
    `Passkey-Dienst laeuft auf http://localhost:${config.port} ` +
      `(rpId=${config.rpId}, Herkuenfte=${config.origins.join(', ')})`,
  );
});
