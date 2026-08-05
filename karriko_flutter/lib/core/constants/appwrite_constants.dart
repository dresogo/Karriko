class AppwriteConstants {
  // Regionaler Endpunkt des Projekts (Frankfurt). Der generische Host
  // cloud.appwrite.io antwortet zwar weiterhin, leitet die Aufrufe aber erst
  // ueber den globalen Router in die Region.
  static const endpoint = 'https://fra.cloud.appwrite.io/v1';

  static const projectId = '6a3c45ef003356d7f16d';

  /// Basisadresse, unter der die App laeuft.
  ///
  /// Alle Rueckleitungen von Appwrite (Bestaetigungsmail, Passwort-Reset,
  /// Magic Link, OAuth) werden daraus abgeleitet, damit sie nicht einzeln
  /// auseinanderlaufen. Der Wert muss in der Appwrite Console als Web-Plattform
  /// eingetragen sein, sonst weist Appwrite die Ziel-URL zurueck.
  ///
  /// Der Standard passt zum Entwicklungsserver aus .claude/launch.json.
  /// Produktiv per `--dart-define=APP_ORIGIN=https://…` setzen.
  static const appOrigin = String.fromEnvironment(
    'APP_ORIGIN',
    defaultValue: 'http://localhost:8080',
  );

  /// Ziel der Bestaetigungsmail.
  static const verificationUrl = '$appOrigin/verify-email';

  /// Ziel des Passwort-Reset-Links.
  ///
  /// Zeigte frueher auf [verificationUrl] und damit auf die Startseite – der
  /// Link fuehrte also nirgendwohin, wo sich ein Passwort setzen laesst.
  static const recoveryUrl = '$appOrigin/reset-password';

  /// Ziel des Anmeldelinks (Magic Link).
  static const magicLinkUrl = '$appOrigin/auth/magic';

  /// Rueckleitungen des OAuth2-Token-Flows.
  static const oauthSuccessUrl = '$appOrigin/auth/oauth';
  static const oauthFailureUrl = '$appOrigin/auth/oauth?error=1';

  /// Sind Google und Apple in der Appwrite Console freigeschaltet?
  ///
  /// Standardmaessig `false`. Ohne hinterlegte Client-Zugangsdaten wuerde ein
  /// Klick die App verlassen und auf einer Appwrite-Fehlerseite landen — von
  /// dort findet niemand zurueck. Solange der Schalter aus ist, bleiben die
  /// Schaltflaechen sichtbar, aber inaktiv, mit einem Hinweis darunter.
  ///
  /// Nach dem Hinterlegen der Zugangsdaten mit
  /// `--dart-define=OAUTH_ENABLED=true` bauen.
  static const oauthEnabled = bool.fromEnvironment(
    'OAUTH_ENABLED',
    defaultValue: false,
  );

  /// Basisadresse des WebAuthn-Dienstes (eigener Relying Party Service).
  static const passkeyServiceUrl = String.fromEnvironment(
    'PASSKEY_SERVICE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Database & collection IDs (must match what you create in the Appwrite console)
  static const databaseId = '6a3ea0a4002b4cf10630';
  static const profilesCollection = 'profiles';
  static const companiesCollection = 'companies';
  static const reviewsCollection = 'reviews';
  static const bookmarksCollection = 'bookmarks';
  static const reviewReportsCollection = 'review_reports';
  static const questionsCollection = 'questions';
  static const notificationsCollection = 'notifications';
}
