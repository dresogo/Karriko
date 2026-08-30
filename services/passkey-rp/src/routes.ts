import {
  generateRegistrationOptions,
  verifyRegistrationResponse,
  generateAuthenticationOptions,
  verifyAuthenticationResponse,
} from '@simplewebauthn/server';
import type { Config } from './config.ts';
import {
  isCounterAcceptable,
  isExpired,
  type PasskeyStore,
} from './store.ts';
import type { AuthenticatedUser } from './appwrite.ts';

/** Antwort einer Route: Statuscode plus JSON-Rumpf. */
export type RouteResult = {
  status: number;
  body: unknown;
};

export type SessionTokenIssuer = (
  userId: string,
) => Promise<{ userId: string; secret: string }>;

export type Deps = {
  config: Config;
  store: PasskeyStore;
  issueSessionToken: SessionTokenIssuer;
};

const ok = (body: unknown): RouteResult => ({ status: 200, body });
const fehler = (status: number, message: string): RouteResult => ({
  status,
  body: { message },
});

/**
 * Einheitliche Absage fuer alle fehlgeschlagenen Anmeldeversuche.
 *
 * Bewusst derselbe Text und Status fuer „Passkey unbekannt", „Challenge
 * abgelaufen" und „Signatur falsch". Wer die Faelle unterscheiden koennte,
 * haette ein Mittel, vorhandene Passkeys aufzuzaehlen.
 */
const anmeldungAbgelehnt = () =>
  fehler(401, 'Die Anmeldung mit diesem Passkey ist fehlgeschlagen.');

function ablaufZeitpunkt(config: Config): string {
  return new Date(Date.now() + config.challengeTtlSeconds * 1000).toISOString();
}

// --- Registrierung -------------------------------------------------------

export async function registerOptions(
  deps: Deps,
  user: AuthenticatedUser,
): Promise<RouteResult> {
  const vorhandene = await deps.store.listByUser(user.id);

  const options = await generateRegistrationOptions({
    rpName: deps.config.rpName,
    rpID: deps.config.rpId,
    userName: user.email || user.id,
    userDisplayName: user.name || user.email || 'Karriko',
    // Ohne Attestation: Wir wollen wissen, dass der Schluessel gilt, nicht
    // welches Geraetemodell ihn haelt. Letzteres waere ein Datum mehr, das wir
    // weder brauchen noch speichern wollen.
    attestationType: 'none',
    // Verhindert, dass derselbe Authenticator zweimal registriert wird.
    excludeCredentials: vorhandene.map((p) => ({
      id: p.credentialId,
      transports: p.transports as never,
    })),
    authenticatorSelection: {
      // 'preferred' statt 'required': Ein auffindbarer Schluessel erlaubt die
      // Anmeldung ohne Eingabe des Nutzernamens. Geraete, die das nicht
      // koennen, werden dadurch aber nicht ausgeschlossen.
      residentKey: 'preferred',
      userVerification: 'preferred',
    },
  });

  await deps.store.saveChallenge({
    challenge: options.challenge,
    userId: user.id,
    kind: 'registration',
    expiresAt: ablaufZeitpunkt(deps.config),
  });

  return ok(options);
}

export async function registerVerify(
  deps: Deps,
  user: AuthenticatedUser,
  body: { response?: unknown; deviceName?: unknown },
): Promise<RouteResult> {
  const response = body.response as Parameters<
    typeof verifyRegistrationResponse
  >[0]['response'];
  if (!response) {
    return fehler(400, 'Die Antwort des Authenticators fehlt.');
  }

  const erwartet = await deps.store.consumeChallenge(
    // Der Browser liefert die Challenge in den clientDataJSON zurueck; wir
    // suchen sie ueber den vom Client mitgeschickten Wert.
    String((body as { challenge?: unknown }).challenge ?? ''),
  );
  if (!erwartet || erwartet.kind !== 'registration') {
    return fehler(400, 'Die Anfrage ist abgelaufen. Bitte erneut versuchen.');
  }
  if (isExpired(erwartet)) {
    return fehler(400, 'Die Anfrage ist abgelaufen. Bitte erneut versuchen.');
  }
  if (erwartet.userId !== user.id) {
    return fehler(400, 'Die Anfrage gehört nicht zu diesem Konto.');
  }

  let ergebnis;
  try {
    ergebnis = await verifyRegistrationResponse({
      response,
      expectedChallenge: erwartet.challenge,
      expectedOrigin: deps.config.origins,
      expectedRPID: deps.config.rpId,
      requireUserVerification: false,
    });
  } catch {
    return fehler(400, 'Der Passkey konnte nicht geprüft werden.');
  }

  if (!ergebnis.verified) {
    return fehler(400, 'Der Passkey konnte nicht geprüft werden.');
  }

  const info = ergebnis.registrationInfo;
  const name =
    typeof body.deviceName === 'string' && body.deviceName.trim()
      ? body.deviceName.trim().slice(0, 60)
      : 'Unbenanntes Gerät';

  await deps.store.insert({
    userId: user.id,
    credentialId: info.credential.id,
    publicKey: Buffer.from(info.credential.publicKey).toString('base64url'),
    signCount: info.credential.counter,
    transports: info.credential.transports ?? [],
    deviceName: name,
    backedUp: info.credentialBackedUp,
    createdAt: new Date().toISOString(),
    lastUsedAt: null,
    // `aaguid` wird bewusst nicht gespeichert: Es benennt das
    // Authenticator-Modell, ist fuer die Anmeldung ohne Nutzen und waere ein
    // zusaetzliches Merkmal am Nutzer.
  });

  return ok({ verified: true });
}

// --- Anmeldung -----------------------------------------------------------

export async function loginOptions(deps: Deps): Promise<RouteResult> {
  // Leere `allowCredentials`: Der Browser sucht selbst einen passenden
  // Passkey. Dadurch gibt es keine Eingabe, an der sich pruefen liesse, ob ein
  // Konto existiert — das Verfahren ist von sich aus enumerationssicher.
  const options = await generateAuthenticationOptions({
    rpID: deps.config.rpId,
    userVerification: 'preferred',
  });

  await deps.store.saveChallenge({
    challenge: options.challenge,
    userId: null,
    kind: 'authentication',
    expiresAt: ablaufZeitpunkt(deps.config),
  });

  return ok(options);
}

export async function loginVerify(
  deps: Deps,
  body: { response?: unknown; challenge?: unknown },
): Promise<RouteResult> {
  const response = body.response as Parameters<
    typeof verifyAuthenticationResponse
  >[0]['response'];
  if (!response) return anmeldungAbgelehnt();

  const erwartet = await deps.store.consumeChallenge(String(body.challenge ?? ''));
  if (!erwartet || erwartet.kind !== 'authentication' || isExpired(erwartet)) {
    return anmeldungAbgelehnt();
  }

  const passkey = await deps.store.findByCredentialId(String(response.id));
  if (!passkey) return anmeldungAbgelehnt();

  let ergebnis;
  try {
    ergebnis = await verifyAuthenticationResponse({
      response,
      expectedChallenge: erwartet.challenge,
      expectedOrigin: deps.config.origins,
      expectedRPID: deps.config.rpId,
      credential: {
        id: passkey.credentialId,
        publicKey: new Uint8Array(Buffer.from(passkey.publicKey, 'base64url')),
        counter: passkey.signCount,
        transports: passkey.transports as never,
      },
      requireUserVerification: false,
    });
  } catch {
    return anmeldungAbgelehnt();
  }

  if (!ergebnis.verified) return anmeldungAbgelehnt();

  const neuerZaehler = ergebnis.authenticationInfo.newCounter;
  if (!isCounterAcceptable(passkey.signCount, neuerZaehler)) {
    // Ein nicht gestiegener Zaehler deutet auf eine Kopie des Schluessels hin.
    return anmeldungAbgelehnt();
  }

  await deps.store.touch(passkey.rowId, neuerZaehler);

  const token = await deps.issueSessionToken(passkey.userId);
  return ok(token);
}

// --- Verwaltung ----------------------------------------------------------

export async function listCredentials(
  deps: Deps,
  user: AuthenticatedUser,
): Promise<RouteResult> {
  const passkeys = await deps.store.listByUser(user.id);
  // Der oeffentliche Schluessel wird nicht ausgeliefert: Er hilft der
  // Oberflaeche nicht und muss den Dienst nicht verlassen.
  return ok({
    passkeys: passkeys.map((p) => ({
      id: p.rowId,
      deviceName: p.deviceName,
      createdAt: p.createdAt,
      lastUsedAt: p.lastUsedAt,
      backedUp: p.backedUp,
    })),
  });
}

export async function deleteCredential(
  deps: Deps,
  user: AuthenticatedUser,
  rowId: string,
): Promise<RouteResult> {
  const passkeys = await deps.store.listByUser(user.id);
  const treffer = passkeys.find((p) => p.rowId === rowId);
  // Fremde Passkeys sind nicht loeschbar, und der Unterschied zwischen
  // „gibt es nicht" und „gehoert jemand anderem" bleibt unsichtbar.
  if (!treffer) return fehler(404, 'Dieser Passkey wurde nicht gefunden.');

  await deps.store.remove(rowId);
  return ok({ deleted: true });
}
