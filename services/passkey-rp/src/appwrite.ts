import { Client, Account, Users } from 'node-appwrite';
import type { Config } from './config.ts';

/** Das Noetigste ueber den angemeldeten Nutzer. */
export type AuthenticatedUser = {
  id: string;
  email: string;
  name: string;
  /**
   * Wann die Sitzung entstand, aus der das JWT stammt (ISO-Zeitpunkt), oder
   * `null`, wenn Appwrite es nicht verraet. Grundlage der Frische-Pruefung vor
   * dem Anlegen eines Passkeys (T-3.26).
   */
  sessionCreatedAt: string | null;
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
    const konto = new Account(client);
    const account = await konto.get();
    let sessionCreatedAt: string | null = null;
    try {
      sessionCreatedAt = (await konto.getSession({ sessionId: 'current' }))
        .$createdAt;
    } catch {
      // Bleibt null; die Frische-Pruefung lehnt dann ab, statt zu raten.
    }
    return {
      id: account.$id,
      email: account.email,
      name: account.name,
      sessionCreatedAt,
    };
  } catch {
    return null;
  }
}

/**
 * Hat das Konto einen aktiven zweiten Faktor (TOTP)?
 *
 * Solange nicht gegen die echte Instanz geprueft ist, ob eine Sitzung aus
 * `users.createToken` danach noch TOTP verlangt, lehnt der Dienst die
 * Passkey-Anmeldung fuer solche Konten ab (T-3.26, E-3.13). Im Zweifel `true`:
 * Lieber eine Anmeldung zu viel abgelehnt als einen Faktor uebersprungen.
 */
export async function hasMfa(config: Config, userId: string): Promise<boolean> {
  const client = new Client()
    .setEndpoint(config.appwriteEndpoint)
    .setProject(config.appwriteProjectId)
    .setKey(config.appwriteApiKey);
  try {
    return (await new Users(client).get({ userId })).mfa;
  } catch {
    return true;
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
