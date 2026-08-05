/// Weiterleitung zur Anmeldeseite des Anbieters, je Plattform.
///
/// Auf Web eine echte Seitenweiterleitung. Der Weg über das SDK
/// (`Account.createOAuth2Token`) wäre der naheliegendere, öffnet dort aber ein
/// Popup über `FlutterWebAuth2` — das blockieren Browser regelmäßig, und es
/// passt nicht zu einem Ablauf, der über eine Rückleitungs-URL zurückkommt.
///
/// Auf allen anderen Plattformen nicht verfügbar: Dort bräuchte es einen
/// Deep-Link-Rückweg statt einer URL. Die App zielt derzeit auf Web (siehe
/// README), deshalb scheitert der Aufruf dort mit klarer Meldung, statt einen
/// halb funktionierenden Pfad vorzutäuschen.
library;

export 'oauth_redirect_stub.dart'
    if (dart.library.js_interop) 'oauth_redirect_web.dart';
