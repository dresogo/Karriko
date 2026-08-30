import type { Config } from './config.ts';
import type { AuthenticatedUser } from './appwrite.ts';
import {
  deleteCredential,
  listCredentials,
  loginOptions,
  loginVerify,
  registerOptions,
  registerVerify,
  type Deps,
  type RouteResult,
} from './routes.ts';

export type HttpRequest = {
  method: string;
  path: string;
  headers: Record<string, string | undefined>;
  body: unknown;
};

/** Prueft das Bearer-Token und liefert den Nutzer oder `null`. */
export type Authenticator = (
  config: Config,
  authorizationHeader: string | undefined,
) => Promise<AuthenticatedUser | null>;

export type HandlerDeps = Deps & { authenticate: Authenticator };

const nichtGefunden: RouteResult = {
  status: 404,
  body: { message: 'Unbekannter Pfad.' },
};

const nichtAngemeldet: RouteResult = {
  status: 401,
  body: { message: 'Nicht angemeldet.' },
};

/**
 * Ordnet eine Anfrage einer Route zu.
 *
 * Als reine Funktion ueber [HttpRequest], damit sie sich ohne laufenden Server
 * pruefen laesst — und damit derselbe Code lokal wie in einer Appwrite Function
 * laeuft.
 */
export async function handle(
  deps: HandlerDeps,
  req: HttpRequest,
): Promise<RouteResult> {
  const body = (req.body ?? {}) as Record<string, unknown>;

  // Ohne Anmeldung erreichbar. Beides ist Teil des Anmeldevorgangs selbst.
  if (req.method === 'POST' && req.path === '/webauthn/login/options') {
    return loginOptions(deps);
  }
  if (req.method === 'POST' && req.path === '/webauthn/login/verify') {
    return loginVerify(deps, body);
  }

  // Alles Weitere setzt eine bestehende Appwrite-Sitzung voraus.
  const geschuetzt =
    req.path.startsWith('/webauthn/register/') ||
    req.path.startsWith('/webauthn/credentials');
  if (!geschuetzt) return nichtGefunden;

  const user = await deps.authenticate(deps.config, req.headers.authorization);
  if (!user) return nichtAngemeldet;

  if (req.method === 'POST' && req.path === '/webauthn/register/options') {
    return registerOptions(deps, user);
  }
  if (req.method === 'POST' && req.path === '/webauthn/register/verify') {
    return registerVerify(deps, user, body);
  }
  if (req.method === 'GET' && req.path === '/webauthn/credentials') {
    return listCredentials(deps, user);
  }
  if (req.method === 'DELETE' && req.path.startsWith('/webauthn/credentials/')) {
    const rowId = decodeURIComponent(
      req.path.slice('/webauthn/credentials/'.length),
    );
    if (!rowId) return nichtGefunden;
    return deleteCredential(deps, user, rowId);
  }

  return nichtGefunden;
}

/**
 * CORS-Kopfzeilen fuer eine Herkunft.
 *
 * Strikt gegen die konfigurierte Liste, keine Wildcard. `credentials` bleibt
 * aus: Der Dienst arbeitet mit einem Bearer-Token im Kopf, nicht mit Cookies.
 */
export function corsHeaders(
  config: Config,
  origin: string | undefined,
): Record<string, string> {
  if (!origin || !config.origins.includes(origin)) return {};
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '600',
    Vary: 'Origin',
  };
}
