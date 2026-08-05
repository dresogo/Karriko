/// Ersatz für Plattformen ohne Browser-WebAuthn.
///
/// [passkeysVerfuegbar] meldet `false`, sodass die Oberfläche die Schaltfläche
/// gar nicht erst anzeigt. Die beiden anderen Aufrufe dürften damit nie
/// erreicht werden; sie scheitern trotzdem ausdrücklich, statt still nichts zu
/// tun.
bool passkeysVerfuegbar() => false;

Future<String> passkeyAnlegen(String optionsJson) =>
    throw UnsupportedError('Passkeys sind hier nicht verfügbar.');

Future<String> passkeyAbfragen(String optionsJson) =>
    throw UnsupportedError('Passkeys sind hier nicht verfügbar.');
