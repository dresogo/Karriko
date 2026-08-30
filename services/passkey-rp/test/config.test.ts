import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.ts';

const vollstaendig = {
  RP_ID: 'karriko.de',
  EXPECTED_ORIGINS: 'https://karriko.de,https://app.karriko.de',
  APPWRITE_ENDPOINT: 'https://fra.cloud.appwrite.io/v1',
  APPWRITE_PROJECT_ID: 'projekt',
  APPWRITE_API_KEY: 'schluessel',
  APPWRITE_DATABASE_ID: 'datenbank',
};

describe('Konfiguration', () => {
  it('nimmt eine vollstaendige Umgebung an', () => {
    const config = loadConfig(vollstaendig);

    expect(config.rpId).toBe('karriko.de');
    expect(config.origins).toEqual([
      'https://karriko.de',
      'https://app.karriko.de',
    ]);
    expect(config.passkeysTableId).toBe('passkeys');
    expect(config.challengeTtlSeconds).toBe(300);
  });

  it('laesst localhost fuer die Entwicklung zu', () => {
    // Im WebAuthn-Standard ist localhost ausdruecklich ein sicherer Kontext.
    const config = loadConfig({
      ...vollstaendig,
      RP_ID: 'localhost',
      EXPECTED_ORIGINS: 'http://localhost:8080',
    });

    expect(config.rpId).toBe('localhost');
  });

  it.each(['RP_ID', 'APPWRITE_API_KEY', 'APPWRITE_DATABASE_ID'])(
    'startet nicht ohne %s',
    (key) => {
      const unvollstaendig = { ...vollstaendig, [key]: '' };

      expect(() => loadConfig(unvollstaendig)).toThrow(key);
    },
  );

  it('lehnt eine Herkunft ab, die nicht zur rpId passt', () => {
    // Der wichtigste Fall: Ein Dienst mit falscher rpId erzeugt Passkeys, die
    // sich spaeter von niemandem einloesen lassen. Das muss beim Start
    // auffallen, nicht beim ersten Nutzer.
    expect(() =>
      loadConfig({
        ...vollstaendig,
        RP_ID: 'karriko.de',
        EXPECTED_ORIGINS: 'https://beispiel.de',
      }),
    ).toThrow(/passt nicht zu RP_ID/);
  });

  it('lehnt eine Herkunft ab, die keine URL ist', () => {
    expect(() =>
      loadConfig({ ...vollstaendig, EXPECTED_ORIGINS: 'karriko.de' }),
    ).toThrow(/keine URL/);
  });

  it('erlaubt Unterdomains der rpId', () => {
    const config = loadConfig({
      ...vollstaendig,
      RP_ID: 'karriko.de',
      EXPECTED_ORIGINS: 'https://app.karriko.de',
    });

    expect(config.origins).toEqual(['https://app.karriko.de']);
  });
});
