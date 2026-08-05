import { Client, Account, Users } from 'node-appwrite';
import type { Config } from './config.ts';

/** Das Noetigste ueber den angemeldeten Nutzer. */
export type AuthenticatedUser = {
  id: string;
  email: string;
  name: string;
};

/**
 * Prueft das mitgeschickte Appwrite-JWT und liefert den Nutzer.
 *
 * Bewusst **keine** eigene Signaturpruefung: Der Dienst legt einen Client mit
 * dem JWT an und fragt Appwrite nach dem Konto. Appwrite entscheidet, ob das
 * Token gilt. Damit gibt es hier keinen eigenen Krypto-Code und keine
 * Schluesselverwaltung — beides waere zusaetzliche Angriffsflaeche ohne Nutzen.
 *
 * Liefert `null`, wenn kein oder ein ungueltiges Token vorliegt.
 */
export async function userFromJwt(
  config: Config,
  authorizationHeader: string | undefined,
): Promise<AuthenticatedUser | null> {
  const jwt = authorizationHeader?.startsWith('Bearer ')
    ? authorizationHeader.slice('Bearer '.length).trim()
    : null;
  if (!jwt) return null;

  try {
    const client = new Client()
      .setEndpoint(config.appwriteEndpoint)
      .setProject(config.appwriteProjectId)
      .setJWT(jwt);
    const account = await new Account(client).get();
    return { id: account.$id, email: account.email, name: account.name };
  } catch {
    return null;
  }
}

/**
 * Erzeugt einen Custom Token, den der Client gegen eine Sitzung tauscht.
 *
 * Das ist die Bruecke zwischen dem eigenen WebAuthn-Dienst und Appwrite:
 * Der Client ruft anschliessend `account.createSession(userId, secret)` —
 * derselbe Mechanismus, den auch Anmeldelinks und die Anbieter-Anmeldung
 * verwenden.
 *
 * Kurze Gueltigkeit, weil das Geheimnis nur den Weg vom Dienst zum Browser
 * ueberdauern muss.
 */
export async function createSessionToken(
  config: Config,
  userId: string,
): Promise<{ userId: string; secret: string }> {
  const client = new Client()
    .setEndpoint(config.appwriteEndpoint)
    .setProject(config.appwriteProjectId)
    .setKey(config.appwriteApiKey);

  const token = await new Users(client).createToken({
    userId,
    length: 64,
    expire: 60,
  });

  return { userId: token.userId, secret: token.secret };
}
