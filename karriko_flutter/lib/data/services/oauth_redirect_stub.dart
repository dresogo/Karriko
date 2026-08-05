/// Ersatz für Plattformen ohne Browser-Adresszeile.
///
/// Siehe `oauth_redirect.dart` für die Begründung.
void redirectToProvider(Uri url) {
  throw UnsupportedError(
    'Die Anmeldung über einen Anbieter ist derzeit nur im Browser möglich.',
  );
}
