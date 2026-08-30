/**
 * Konfiguration des Relying-Party-Dienstes.
 *
 * Wird beim Start hart geprueft. Ein Dienst mit falscher `rpId` erzeugt
 * Passkeys, die sich spaeter von niemandem mehr einloesen lassen — die rpId ist
 * an die Domain gebunden und nicht migrierbar. Deshalb lieber gar nicht starten
 * als mit einem geratenen Wert.
 */
export type Config = {
  /** WebAuthn Relying Party ID. Muss registrierbares Suffix der Origins sein. */
  rpId: string;
  /** Anzeigename in der Betriebssystem-Abfrage. */
  rpName: string;
  /** Erlaubte Herkuenfte. Alles andere wird abgelehnt. */
  origins: string[];
  appwriteEndpoint: string;
  appwriteProjectId: string;
  /** Nur `users.read`, `users.write` und die beiden Passkey-Tabellen. */
  appwriteApiKey: string;
  databaseId: string;
  passkeysTableId: string;
  challengesTableId: string;
  /** Gueltigkeit einer Challenge in Sekunden. */
  challengeTtlSeconds: number;
  port: number;
};

class ConfigError extends Error {}

function required(env: NodeJS.ProcessEnv, key: string): string {
  const value = env[key]?.trim();
  if (!value) {
    throw new ConfigError(
      `${key} fehlt. Ohne diesen Wert startet der Dienst nicht — siehe .env.example.`,
    );
  }
  return value;
}

/**
 * Liest und prueft die Konfiguration.
 *
 * Als Funktion mit uebergebener Umgebung, damit die Pruefung testbar bleibt,
 * ohne `process.env` zu veraendern.
 */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const rpId = required(env, 'RP_ID');
  const origins = required(env, 'EXPECTED_ORIGINS')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  if (origins.length === 0) {
    throw new ConfigError('EXPECTED_ORIGINS enthaelt keine gueltige Herkunft.');
  }

  // Eine Origin, deren Host nicht zur rpId passt, wuerde jede Anmeldung
  // scheitern lassen — und zwar erst zur Laufzeit beim Nutzer. Lieber hier.
  for (const origin of origins) {
    let host: string;
    try {
      host = new URL(origin).hostname;
    } catch {
      throw new ConfigError(`EXPECTED_ORIGINS: "${origin}" ist keine URL.`);
    }
    if (host !== rpId && !host.endsWith(`.${rpId}`)) {
      throw new ConfigError(
        `Herkunft "${origin}" passt nicht zu RP_ID "${rpId}". ` +
          'Die rpId muss der Host selbst oder eine seiner Oberdomains sein.',
      );
    }
  }

  return {
    rpId,
    rpName: env.RP_NAME?.trim() || 'Karriko',
    origins,
    appwriteEndpoint: required(env, 'APPWRITE_ENDPOINT'),
    appwriteProjectId: required(env, 'APPWRITE_PROJECT_ID'),
    appwriteApiKey: required(env, 'APPWRITE_API_KEY'),
    databaseId: required(env, 'APPWRITE_DATABASE_ID'),
    passkeysTableId: env.APPWRITE_PASSKEYS_TABLE?.trim() || 'passkeys',
    challengesTableId:
      env.APPWRITE_CHALLENGES_TABLE?.trim() || 'webauthn_challenges',
    challengeTtlSeconds: Number(env.CHALLENGE_TTL_SECONDS ?? 300),
    port: Number(env.PORT ?? 3000),
  };
}

export { ConfigError };
