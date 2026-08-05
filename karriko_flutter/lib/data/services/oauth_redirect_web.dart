import 'package:web/web.dart' as web;

/// Verlässt die App und lädt die Anmeldeseite des Anbieters.
///
/// `assign` statt `replace`: Der Zurück-Knopf soll den Nutzer wieder auf die
/// Anmeldeseite bringen, wenn er beim Anbieter abbricht.
void redirectToProvider(Uri url) {
  web.window.location.assign(url.toString());
}
