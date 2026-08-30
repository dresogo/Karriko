/// Zugriff auf die WebAuthn-API des Browsers, je Plattform.
///
/// Auf Web über den Shim `web/passkey.js`. Auf allen anderen Plattformen nicht
/// verfügbar — dort würde ein Passkey über die Betriebssystem-API des Geräts
/// laufen, nicht über den Browser. Die App zielt derzeit auf Web.
library;

export 'passkey_client_stub.dart'
    if (dart.library.js_interop) 'passkey_client_web.dart';
