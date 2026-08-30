import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Aufrufe in den Shim `web/passkey.js`.
///
/// Der Umweg über JavaScript ist Absicht: Die JSON-Hilfen des WebAuthn-
/// Standards (`parseCreationOptionsFromJSON`, `toJSON`) erledigen die
/// Umrechnung zwischen base64url und ArrayBuffer. In Dart wäre das
/// Handarbeit, bei der ein Vorzeichenfehler erst beim Nutzer auffällt.
@JS('karrikoPasskey.available')
external JSBoolean _available();

@JS('karrikoPasskey.register')
external JSPromise<JSString> _register(JSString optionsJson);

@JS('karrikoPasskey.authenticate')
external JSPromise<JSString> _authenticate(JSString optionsJson);

/// Kann dieser Browser Passkeys?
///
/// Prüft zuerst, ob der Shim überhaupt geladen wurde. Fehlt er — etwa weil
/// `passkey.js` nicht ausgeliefert wird —, würde der direkte Aufruf mit einem
/// unverständlichen JS-Fehler scheitern.
bool passkeysVerfuegbar() {
  if (!globalContext.has('karrikoPasskey')) return false;
  return _available().toDart;
}

/// Legt einen Passkey an. Erwartet und liefert JSON als Zeichenkette.
Future<String> passkeyAnlegen(String optionsJson) async =>
    (await _register(optionsJson.toJS).toDart).toDart;

/// Meldet mit einem vorhandenen Passkey an.
Future<String> passkeyAbfragen(String optionsJson) async =>
    (await _authenticate(optionsJson.toJS).toDart).toDart;
