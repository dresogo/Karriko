import { createServer } from 'node:http';
import { loadConfig } from './config.ts';
import { AppwritePasskeyStore } from './store.ts';
import { createSessionToken, userFromJwt } from './appwrite.ts';
import { corsHeaders, handle, type HandlerDeps } from './handler.ts';

/**
 * Lokaler HTTP-Server.
 *
 * Bewusst auf `node:http` statt auf einem Framework: Der Dienst hat sechs
 * Routen. Jede zusaetzliche Abhaengigkeit waere Angriffsflaeche fuer eine
 * Bequemlichkeit, die hier vierzig Zeilen spart.
 */
const config = loadConfig();

const deps: HandlerDeps = {
  config,
  store: new AppwritePasskeyStore(config),
  issueSessionToken: (userId) => createSessionToken(config, userId),
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
    const chunks: Buffer[] = [];
    for await (const chunk of req) chunks.push(chunk as Buffer);
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

server.listen(config.port, () => {
  console.log(
    `Passkey-Dienst laeuft auf http://localhost:${config.port} ` +
      `(rpId=${config.rpId}, Herkuenfte=${config.origins.join(', ')})`,
  );
});
