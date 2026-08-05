import { Client, TablesDB, ID, Query } from 'node-appwrite';
import type { Config } from './config.ts';

/** Ein gespeicherter Passkey. */
export type StoredPasskey = {
  rowId: string;
  userId: string;
  /** base64url, wie von WebAuthn geliefert. */
  credentialId: string;
  /** base64url-kodierter COSE-Schluessel. */
  publicKey: string;
  signCount: number;
  transports: string[];
  deviceName: string;
  backedUp: boolean;
  createdAt: string;
  lastUsedAt: string | null;
};

export type StoredChallenge = {
  challenge: string;
  userId: string | null;
  kind: 'registration' | 'authentication';
  expiresAt: string;
};

/**
 * Ablage fuer Passkeys und Challenges.
 *
 * Als Schnittstelle, damit die Routen ohne laufendes Appwrite pruefbar sind.
 */
export interface PasskeyStore {
  listByUser(userId: string): Promise<StoredPasskey[]>;
  findByCredentialId(credentialId: string): Promise<StoredPasskey | null>;
  insert(passkey: Omit<StoredPasskey, 'rowId'>): Promise<StoredPasskey>;
  touch(rowId: string, signCount: number): Promise<void>;
  remove(rowId: string): Promise<void>;

  saveChallenge(challenge: StoredChallenge): Promise<void>;
  /**
   * Liest die Challenge **und loescht sie**.
   *
   * Einmalverwendung ist Teil des Verfahrens: Eine Challenge, die zweimal
   * gilt, macht einen aufgezeichneten Anmeldeversuch wiederholbar. Deshalb
   * loeschen statt als verbraucht markieren.
   */
  consumeChallenge(challenge: string): Promise<StoredChallenge | null>;
}

/** Appwrite-gestuetzte Ablage. */
export class AppwritePasskeyStore implements PasskeyStore {
  private readonly tables: TablesDB;

  constructor(private readonly config: Config) {
    const client = new Client()
      .setEndpoint(config.appwriteEndpoint)
      .setProject(config.appwriteProjectId)
      .setKey(config.appwriteApiKey);
    this.tables = new TablesDB(client);
  }

  async listByUser(userId: string): Promise<StoredPasskey[]> {
    const result = await this.tables.listRows({
      databaseId: this.config.databaseId,
      tableId: this.config.passkeysTableId,
      queries: [Query.equal('userId', userId), Query.limit(50)],
    });
    return result.rows.map(toPasskey);
  }

  async findByCredentialId(credentialId: string): Promise<StoredPasskey | null> {
    const result = await this.tables.listRows({
      databaseId: this.config.databaseId,
      tableId: this.config.passkeysTableId,
      queries: [Query.equal('credentialId', credentialId), Query.limit(1)],
    });
    const row = result.rows[0];
    return row ? toPasskey(row) : null;
  }

  async insert(passkey: Omit<StoredPasskey, 'rowId'>): Promise<StoredPasskey> {
    const row = await this.tables.createRow({
      databaseId: this.config.databaseId,
      tableId: this.config.passkeysTableId,
      rowId: ID.unique(),
      data: {
        userId: passkey.userId,
        credentialId: passkey.credentialId,
        publicKey: passkey.publicKey,
        signCount: passkey.signCount,
        transports: passkey.transports,
        deviceName: passkey.deviceName,
        backedUp: passkey.backedUp,
        createdAt: passkey.createdAt,
        lastUsedAt: passkey.lastUsedAt,
      },
      // Bewusst ohne Berechtigungen: Nur der API-Schluessel dieses Dienstes
      // darf lesen. Haetten Nutzer Leserecht, liesse sich ueber die Tabelle
      // aufzaehlen, welche Konten es gibt.
      permissions: [],
    });
    return { ...passkey, rowId: row.$id };
  }

  async touch(rowId: string, signCount: number): Promise<void> {
    await this.tables.updateRow({
      databaseId: this.config.databaseId,
      tableId: this.config.passkeysTableId,
      rowId,
      data: { signCount, lastUsedAt: new Date().toISOString() },
    });
  }

  async remove(rowId: string): Promise<void> {
    await this.tables.deleteRow({
      databaseId: this.config.databaseId,
      tableId: this.config.passkeysTableId,
      rowId,
    });
  }

  async saveChallenge(challenge: StoredChallenge): Promise<void> {
    await this.tables.createRow({
      databaseId: this.config.databaseId,
      tableId: this.config.challengesTableId,
      rowId: ID.unique(),
      data: {
        challenge: challenge.challenge,
        userId: challenge.userId,
        kind: challenge.kind,
        expiresAt: challenge.expiresAt,
      },
      permissions: [],
    });
  }

  async consumeChallenge(challenge: string): Promise<StoredChallenge | null> {
    const result = await this.tables.listRows({
      databaseId: this.config.databaseId,
      tableId: this.config.challengesTableId,
      queries: [Query.equal('challenge', challenge), Query.limit(1)],
    });
    const row = result.rows[0];
    if (!row) return null;

    await this.tables.deleteRow({
      databaseId: this.config.databaseId,
      tableId: this.config.challengesTableId,
      rowId: row.$id,
    });

    return {
      challenge: String(row.challenge),
      userId: (row.userId as string | null) ?? null,
      kind: row.kind as StoredChallenge['kind'],
      expiresAt: String(row.expiresAt),
    };
  }
}

function toPasskey(row: Record<string, unknown>): StoredPasskey {
  return {
    rowId: String(row.$id),
    userId: String(row.userId),
    credentialId: String(row.credentialId),
    publicKey: String(row.publicKey),
    signCount: Number(row.signCount ?? 0),
    transports: (row.transports as string[] | undefined) ?? [],
    deviceName: String(row.deviceName ?? 'Unbenanntes Gerät'),
    backedUp: Boolean(row.backedUp),
    createdAt: String(row.createdAt ?? row.$createdAt),
    lastUsedAt: (row.lastUsedAt as string | null) ?? null,
  };
}

/** Ist die Challenge abgelaufen? */
export function isExpired(challenge: StoredChallenge, now = new Date()): boolean {
  return new Date(challenge.expiresAt).getTime() <= now.getTime();
}

/**
 * Ist der gemeldete Zaehler plausibel?
 *
 * Authenticatoren zaehlen bei jeder Verwendung hoch. Ein Zaehler, der nicht
 * groesser geworden ist, deutet auf eine Kopie des Schluessels hin — also auf
 * einen wiedereingespielten Anmeldeversuch. Ausnahme: Bleibt der Zaehler
 * konstant bei 0, fuehrt der Authenticator gar keinen (bei Passkeys in der
 * Cloud der Normalfall), dann ist die Pruefung nicht anwendbar.
 */
export function isCounterAcceptable(gespeichert: number, neu: number): boolean {
  if (gespeichert === 0 && neu === 0) return true;
  return neu > gespeichert;
}
