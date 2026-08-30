// Brücke zwischen Dart und der WebAuthn-API des Browsers.
//
// Dart hat keine WebAuthn-Bindung. Diese Datei nutzt die JSON-Hilfen des
// Standards (parseCreationOptionsFromJSON / toJSON), damit die Umrechnung
// zwischen base64url und ArrayBuffer im Browser bleibt — in Dart wären das
// rund zweihundert Zeilen fehleranfälliger Handarbeit.
//
// Verfügbar ab Chrome 119, Safari 17.4 und Firefox 119. Ältere Browser melden
// sich über `available()` ab; die Schaltfläche erscheint dort gar nicht.
//
// Liegt bewusst als eigene Datei vor und nicht als Inline-Skript: Die geplante
// CSP erlaubt `script-src 'self'`, ein Inline-Skript wäre davon nicht gedeckt.
(function () {
  'use strict';

  function unterstuetzt() {
    return (
      typeof window.PublicKeyCredential === 'function' &&
      typeof window.PublicKeyCredential.parseCreationOptionsFromJSON ===
        'function' &&
      typeof window.PublicKeyCredential.parseRequestOptionsFromJSON ===
        'function'
    );
  }

  window.karrikoPasskey = {
    available: function () {
      return unterstuetzt();
    },

    // Legt einen neuen Passkey an. Erwartet und liefert JSON als Zeichenkette.
    register: async function (optionsJson) {
      const options = window.PublicKeyCredential.parseCreationOptionsFromJSON(
        JSON.parse(optionsJson),
      );
      const credential = await navigator.credentials.create({
        publicKey: options,
      });
      if (!credential) throw new Error('Der Browser hat nichts geliefert.');
      return JSON.stringify(credential.toJSON());
    },

    // Meldet mit einem vorhandenen Passkey an.
    authenticate: async function (optionsJson) {
      const options = window.PublicKeyCredential.parseRequestOptionsFromJSON(
        JSON.parse(optionsJson),
      );
      const credential = await navigator.credentials.get({
        publicKey: options,
      });
      if (!credential) throw new Error('Der Browser hat nichts geliefert.');
      return JSON.stringify(credential.toJSON());
    },
  };
})();
