# Passkey-Dienst (WebAuthn Relying Party)

Prüft Passkeys und übersetzt eine bestandene Prüfung über einen **Appwrite
Custom Token** in eine Sitzung.

## Warum es diesen Dienst gibt

Appwrite hat **keine** WebAuthn-Unterstützung. Die Prüfung eines Passkeys muss
also außerhalb von Appwrite stattfinden. Das Ergebnis wird anschließend über
`users.createToken()` in ein `{userId, secret}`-Paar übersetzt, das der Browser
mit `account.createSession()` gegen eine Sitzung tauscht — derselbe Mechanismus,
den in dieser App auch die Anmeldelinks und die Anbieter-Anmeldung nutzen.

Ein fertiger Dienst eines Drittanbieters (Corbado) war schon einmal eingebunden
und wurde als Supply-Chain-Risiko wieder entfernt. Deshalb hier: zwei
Laufzeit-Abhängigkeiten, kein Framework, kein eigener Krypto-Code.

## Aufbau

| Datei | Inhalt |
|---|---|
| `src/config.ts` | Umgebung einlesen und **hart prüfen** |
| `src/appwrite.ts` | JWT prüfen, Custom Token erzeugen |
| `src/store.ts` | Passkeys und Challenges in Appwrite |
| `src/routes.ts` | die sechs Endpunkte |
| `src/handler.ts` | Zuordnung Pfad → Route, CORS |
| `src/server.ts` | lokaler HTTP-Server |

`handler.ts` ist eine reine Funktion über ein Anfrage-Objekt. Dadurch ist der
Dienst ohne laufenden Server prüfbar, und derselbe Code kann später hinter einer
Appwrite Function laufen.

## Endpunkte

| Methode | Pfad | Auth | Zweck |
|---|---|---|---|
| POST | `/webauthn/register/options` | JWT | Optionen zum Anlegen |
| POST | `/webauthn/register/verify` | JWT | Antwort prüfen, Passkey speichern |
| POST | `/webauthn/login/options` | — | Optionen zum Anmelden, **ohne Nutzernamen** |
| POST | `/webauthn/login/verify` | — | prüfen, Custom Token ausgeben |
| GET | `/webauthn/credentials` | JWT | eigene Passkeys auflisten |
| DELETE | `/webauthn/credentials/:id` | JWT | eigenen Passkey löschen |

## Entscheidungen, die nicht offensichtlich sind

- **Die JWT-Prüfung läuft über Appwrite**, nicht über eine eigene
  Signaturprüfung: Der Dienst legt einen Client mit dem Token an und ruft
  `account.get()`. Kein eigener Krypto-Code, keine Schlüsselverwaltung.
- **Anmeldung ohne Nutzernamen** (leere `allowCredentials`). Es gibt damit keine
  Eingabe, an der sich prüfen ließe, ob ein Konto existiert.
- **Jeder fehlgeschlagene Anmeldeversuch bekommt dieselbe Antwort** — ob der
  Passkey unbekannt, die Challenge abgelaufen oder die Signatur falsch war.
- **Challenges werden beim Einlösen gelöscht**, nicht als verbraucht markiert,
  und zwar auch bei einem Fehlversuch.
- **`aaguid` wird nicht gespeichert.** Es benennt das Authenticator-Modell, hat
  für die Anmeldung keinen Nutzen und wäre ein zusätzliches Merkmal am Nutzer.
- **Der öffentliche Schlüssel verlässt den Dienst nie.**

## Appwrite-Konfiguration

Zwei Tabellen in der bestehenden Datenbank, **beide ohne jede Berechtigung** —
nur der API-Schlüssel dieses Dienstes darf sie lesen. Hätten Nutzer Leserecht,
ließe sich über die Tabelle aufzählen, welche Konten es gibt.

`passkeys`: `userId` (String, Index), `credentialId` (String, **Unique-Index**),
`publicKey` (String), `signCount` (Integer), `transports` (String[]),
`deviceName` (String), `backedUp` (Boolean), `createdAt` (Datetime),
`lastUsedAt` (Datetime, optional)

`webauthn_challenges`: `challenge` (String, Index), `userId` (String, optional),
`kind` (String), `expiresAt` (Datetime)

Der API-Schlüssel braucht **nur** `users.read` und `users.write` sowie Zugriff
auf diese beiden Tabellen. Kein `sessions.write` auf Projektebene.

## Betrieb

```bash
npm ci --ignore-scripts
cp .env.example .env   # ausfuellen
npm run dev
```

Prüfen:

```bash
npm run typecheck && npm test && npm run audit
```

## Grenzen

- **Nicht gegen eine echte Appwrite-Instanz getestet.** Die Tests laufen gegen
  eine Ablage im Speicher.
- **Abgelaufene Challenges werden nicht aufgeräumt.** Sie werden beim Einlösen
  gelöscht; wer nie einlöst, hinterlässt eine Zeile. Für die Aufbauphase
  hinnehmbar, später über einen geplanten Lauf oder Appwrite-TTL lösen.
- **Keine eigene Ratenbegrenzung.** `notes/projekt-referenz.md` fordert maximal
  fünf Versuche pro IP und Minute. Mit diesem Dienst ließe sich das erstmals
  selbst durchsetzen — umgesetzt ist es noch nicht.
