import { describe, expect, it } from 'vitest';
import { loadConfig, type Config } from '../src/config.ts';
import { corsHeaders, handle, type HandlerDeps } from '../src/handler.ts';
import { FRISCHE_SITZUNG_SEKUNDEN, sitzungFrisch } from '../src/routes.ts';
import {
  isCounterAcceptable,
  isExpired,
  type PasskeyStore,
  type StoredChallenge,
  type StoredPasskey,
} from '../src/store.ts';

const config: Config = loadConfig({
  RP_ID: 'localhost',
  EXPECTED_ORIGINS: 'http://localhost:8080',
  APPWRITE_ENDPOINT: 'https://fra.cloud.appwrite.io/v1',
  APPWRITE_PROJECT_ID: 'projekt',
  APPWRITE_API_KEY: 'schluessel',
  APPWRITE_DATABASE_ID: 'datenbank',
});

/** Ablage im Speicher, damit die Routen ohne Appwrite pruefbar sind. */
class SpeicherStore implements PasskeyStore {
  passkeys: StoredPasskey[] = [];
  challenges: StoredChallenge[] = [];

  async listByUser(userId: string) {
    return this.passkeys.filter((p) => p.userId === userId);
  }
  async findByCredentialId(credentialId: string) {
    return this.passkeys.find((p) => p.credentialId === credentialId) ?? null;
  }
  async insert(passkey: Omit<StoredPasskey, 'rowId'>) {
    const gespeichert = { ...passkey, rowId: `row-${this.passkeys.length}` };
    this.passkeys.push(gespeichert);
    return gespeichert;
  }
  async touch(rowId: string, signCount: number) {
    const treffer = this.passkeys.find((p) => p.rowId === rowId);
    if (treffer) treffer.signCount = signCount;
  }
  async remove(rowId: string) {
    this.passkeys = this.passkeys.filter((p) => p.rowId !== rowId);
  }
  async saveChallenge(challenge: StoredChallenge) {
    this.challenges.push(challenge);
  }
  async consumeChallenge(challenge: string) {
    const index = this.challenges.findIndex((c) => c.challenge === challenge);
    if (index === -1) return null;
    return this.challenges.splice(index, 1)[0] ?? null;
  }
}

function deps(overrides: Partial<HandlerDeps> = {}): HandlerDeps {
  return {
    config,
    store: new SpeicherStore(),
    issueSessionToken: async (userId) => ({ userId, secret: 'geheim' }),
    hasMfa: async () => false,
    authenticate: async () => ({
      id: 'u1',
      email: 'azubi@example.com',
      name: 'Test Nutzer',
      sessionCreatedAt: new Date().toISOString(),
    }),
    ...overrides,
  };
}

const req = (
  method: string,
  path: string,
  body: unknown = {},
  authorization = 'Bearer token',
) => ({ method, path, headers: { authorization }, body });

describe('Zugangsschutz', () => {
  it.each([
    ['POST', '/webauthn/register/options'],
    ['POST', '/webauthn/register/verify'],
    ['GET', '/webauthn/credentials'],
    ['DELETE', '/webauthn/credentials/row-0'],
  ])('%s %s verlangt ein gueltiges Token', async (method, path) => {
    const d = deps({ authenticate: async () => null });

    const antwort = await handle(d, req(method, path, {}, ''));

    expect(antwort.status).toBe(401);
  });

  it('laesst die Anmeldung ohne Token zu', async () => {
    // Sonst koennte sich niemand per Passkey anmelden, der nicht schon
    // angemeldet ist – der ganze Zweck des Verfahrens.
    const antwort = await handle(deps(), req('POST', '/webauthn/login/options'));

    expect(antwort.status).toBe(200);
  });

  it('meldet unbekannte Pfade als 404', async () => {
    const antwort = await handle(deps(), req('GET', '/webauthn/irgendwas'));

    expect(antwort.status).toBe(404);
  });
});

describe('Anmeldung', () => {
  it('fragt keinen Nutzernamen ab', async () => {
    // Leere allowCredentials heisst: Der Browser sucht den Passkey selbst.
    // Damit gibt es keine Eingabe, an der sich Kontoexistenz pruefen liesse.
    const antwort = await handle(deps(), req('POST', '/webauthn/login/options'));
    const body = antwort.body as { allowCredentials?: unknown[] };

    expect(body.allowCredentials ?? []).toHaveLength(0);
  });

  it('legt zu jeder Anfrage eine Challenge ab', async () => {
    const store = new SpeicherStore();

    await handle(deps({ store }), req('POST', '/webauthn/login/options'));

    expect(store.challenges).toHaveLength(1);
    expect(store.challenges[0]?.kind).toBe('authentication');
  });

  it('lehnt unbekannte Zugangsdaten mit derselben Meldung ab wie alles andere',
    async () => {
      const store = new SpeicherStore();
      const d = deps({ store });
      await handle(d, req('POST', '/webauthn/login/options'));
      const challenge = store.challenges[0]!.challenge;

      const unbekannt = await handle(
        d,
        req('POST', '/webauthn/login/verify', {
          challenge,
          response: { id: 'gibt-es-nicht' },
        }),
      );
      const ohneChallenge = await handle(
        d,
        req('POST', '/webauthn/login/verify', {
          challenge: 'nie-vergeben',
          response: { id: 'egal' },
        }),
      );

      expect(unbekannt.status).toBe(401);
      expect(unbekannt.body).toEqual(ohneChallenge.body);
    });

  it('verbraucht die Challenge auch bei einem Fehlversuch', async () => {
    // Sonst liesse sich derselbe aufgezeichnete Versuch beliebig wiederholen.
    const store = new SpeicherStore();
    const d = deps({ store });
    await handle(d, req('POST', '/webauthn/login/options'));
    const challenge = store.challenges[0]!.challenge;

    await handle(
      d,
      req('POST', '/webauthn/login/verify', {
        challenge,
        response: { id: 'gibt-es-nicht' },
      }),
    );

    expect(store.challenges).toHaveLength(0);
  });
});

describe('Passkey anlegen (T-3.26)', () => {
  const nutzer = (sessionCreatedAt: string | null) => async () => ({
    id: 'u1',
    email: 'azubi@example.com',
    name: 'Test Nutzer',
    sessionCreatedAt,
  });

  it('frische Sitzung: Optionen mit PIN oder Biometrie als Pflicht', async () => {
    const antwort = await handle(deps(), req('POST', '/webauthn/register/options'));
    const body = antwort.body as {
      authenticatorSelection?: { userVerification?: string };
    };

    expect(antwort.status).toBe(200);
    expect(body.authenticatorSelection?.userVerification).toBe('required');
  });

  it('Sitzung aelter als zehn Minuten: neu anmelden', async () => {
    const alt = new Date(
      Date.now() - (FRISCHE_SITZUNG_SEKUNDEN + 60) * 1000,
    ).toISOString();
    const store = new SpeicherStore();
    const d = deps({ store, authenticate: nutzer(alt) });

    for (const pfad of ['/webauthn/register/options', '/webauthn/register/verify']) {
      const antwort = await handle(d, req('POST', pfad, { response: {} }));
      expect(antwort.status).toBe(403);
      expect(antwort.body).toMatchObject({ code: 'reauth_required' });
    }
    expect(store.challenges).toHaveLength(0);
  });

  it('Alter der Sitzung unbekannt: abgelehnt statt geraten', async () => {
    const antwort = await handle(
      deps({ authenticate: nutzer(null) }),
      req('POST', '/webauthn/register/options'),
    );
    expect(antwort.status).toBe(403);
  });

  it('sitzungFrisch an der Grenze', () => {
    const jetzt = new Date('2026-10-28T12:10:00Z');
    const mit = (iso: string) => ({
      id: 'u1',
      email: '',
      name: '',
      sessionCreatedAt: iso,
    });
    expect(sitzungFrisch(mit('2026-10-28T12:00:00Z'), jetzt)).toBe(true);
    expect(sitzungFrisch(mit('2026-10-28T11:59:59Z'), jetzt)).toBe(false);
    expect(sitzungFrisch(mit('kein Datum'), jetzt)).toBe(false);
  });

  it('auch die Anmeldung verlangt PIN oder Biometrie', async () => {
    const antwort = await handle(deps(), req('POST', '/webauthn/login/options'));
    expect((antwort.body as { userVerification?: string }).userVerification).toBe(
      'required',
    );
  });
});

describe('Verwaltung', () => {
  it('liefert den oeffentlichen Schluessel nicht aus', async () => {
    const store = new SpeicherStore();
    await store.insert({
      userId: 'u1',
      credentialId: 'cred-1',
      publicKey: 'GEHEIMER-SCHLUESSEL',
      signCount: 0,
      transports: ['internal'],
      deviceName: 'Laptop',
      backedUp: true,
      createdAt: '2026-08-05T10:00:00.000Z',
      lastUsedAt: null,
    });

    const antwort = await handle(
      deps({ store }),
      req('GET', '/webauthn/credentials'),
    );

    expect(JSON.stringify(antwort.body)).not.toContain('GEHEIMER-SCHLUESSEL');
    expect(JSON.stringify(antwort.body)).toContain('Laptop');
  });

  it('loescht keinen fremden Passkey und verraet nicht, dass es ihn gibt',
    async () => {
      const store = new SpeicherStore();
      await store.insert({
        userId: 'jemand-anderes',
        credentialId: 'cred-fremd',
        publicKey: 'x',
        signCount: 0,
        transports: [],
        deviceName: 'Fremdes Gerät',
        backedUp: false,
        createdAt: '2026-08-05T10:00:00.000Z',
        lastUsedAt: null,
      });

      const antwort = await handle(
        deps({ store }),
        req('DELETE', '/webauthn/credentials/row-0'),
      );

      expect(antwort.status).toBe(404);
      expect(store.passkeys).toHaveLength(1);
    });
});

describe('Zaehlerpruefung', () => {
  it('lehnt einen nicht gestiegenen Zaehler ab', () => {
    // Ein gleichbleibender oder gefallener Zaehler deutet auf eine Kopie des
    // Schluessels hin, also auf einen wiedereingespielten Anmeldeversuch.
    expect(isCounterAcceptable(5, 5)).toBe(false);
    expect(isCounterAcceptable(5, 4)).toBe(false);
    expect(isCounterAcceptable(5, 6)).toBe(true);
  });

  it('laesst Authenticatoren ohne Zaehler zu', () => {
    // Passkeys in der Cloud fuehren haeufig gar keinen Zaehler und melden
    // dauerhaft 0. Eine strenge Pruefung schloesse sie komplett aus.
    expect(isCounterAcceptable(0, 0)).toBe(true);
  });
});

describe('Ablauf der Challenge', () => {
  it('erkennt eine abgelaufene Challenge', () => {
    const abgelaufen = {
      challenge: 'x',
      userId: null,
      kind: 'authentication' as const,
      expiresAt: new Date(Date.now() - 1000).toISOString(),
    };

    expect(isExpired(abgelaufen)).toBe(true);
  });
});

describe('CORS', () => {
  it('gibt fremden Herkuenften keine Kopfzeilen', () => {
    expect(corsHeaders(config, 'https://boese.example')).toEqual({});
  });

  it('erlaubt die konfigurierte Herkunft, ohne Wildcard', () => {
    const headers = corsHeaders(config, 'http://localhost:8080');

    expect(headers['Access-Control-Allow-Origin']).toBe('http://localhost:8080');
    expect(Object.values(headers)).not.toContain('*');
  });
});
