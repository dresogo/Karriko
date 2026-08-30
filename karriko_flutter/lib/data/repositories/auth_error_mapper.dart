import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

/// Fehler der Anmeldung oder Registrierung mit einer Meldung, die direkt
/// angezeigt werden kann.
class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// Zugangsdaten stimmten, es fehlt aber der zweite Faktor.
///
/// Bewusst **kein** [AuthFailure]: das ist kein Fehler, sondern ein
/// Zwischenschritt. Als [AuthFailure] wuerde der Text auf der Anmeldeseite als
/// rote Fehlermeldung landen, obwohl die Anmeldung gerade planmaessig laeuft.
class MfaRequired implements Exception {
  /// Hinterlegte Verfahren: `totp`, `email`, `phone`, `recoverycode`.
  final List<String> factors;

  const MfaRequired(this.factors);

  @override
  String toString() => 'MfaRequired(${factors.join(', ')})';
}

/// Kontext des fehlgeschlagenen Aufrufs.
///
/// Einige Appwrite-Fehlertypen sind mehrdeutig. `user_invalid_token` entsteht
/// sowohl bei einem abgelaufenen Anmeldelink als auch bei einem falsch
/// getippten Bestaetigungscode. Ein einzelner Text muesste in einem der beiden
/// Faelle danebengreifen, deshalb entscheidet der Aufrufer.
enum AuthContext {
  /// Anmeldung, Registrierung, Profil – alles ohne Einmal-Geheimnis.
  general,

  /// Magic Link oder OAuth-Rueckleitung: das Geheimnis steckt in der URL.
  link,

  /// Zweiter Faktor: der Nutzer hat einen Code eingetippt.
  mfa,
}

/// Uebersetzt Appwrite-Fehler in Meldungen, die dem Nutzer weiterhelfen.
///
/// Zwei Regeln, die hier bewusst ueber der Hilfsbereitschaft stehen:
///
/// 1. Unbekannte Fehler geben **nie** `e.message` durch. Appwrite-Rohtexte sind
///    englisch, nennen interne Bezeichner und koennen verraten, ob ein Konto
///    existiert. Der Rohtext landet nur im Debug-Log.
/// 2. Fehler, die Rueckschluesse auf die Existenz eines Kontos zulassen,
///    bekommen denselben Text wie ihr harmloses Gegenstueck – siehe
///    `user_invalid_credentials` / `user_not_found` und
///    `user_recovery_code_invalid` / falscher TOTP-Code.
AuthFailure mapAppwriteError(
  AppwriteException e,
  String fallback, {
  AuthContext context = AuthContext.general,
}) {
  final failure = switch (e.type) {
    // Gleiche Meldung fuer falsches Passwort und unbekannte Adresse. Wer sie
    // unterscheidet, baut ein Orakel, mit dem sich Konten aufzaehlen lassen.
    'user_invalid_credentials' ||
    'user_not_found' =>
      const AuthFailure('E-Mail-Adresse oder Passwort ist falsch.'),

    // Bewusste Abweichung von notes/projekt-referenz.md Paragraf 3.2: die
    // Registrierung sagt, dass die Adresse belegt ist. Enumerationssicher waere
    // nur eine serverseitige Registrierung, die immer "Mail verschickt" meldet.
    // Solange die Registrierung im Client laeuft, sieht dieser den 409 ohnehin.
    'user_already_exists' || 'user_email_already_exists' => const AuthFailure(
        'Für diese E-Mail-Adresse existiert bereits ein Konto.'),
    'user_blocked' => const AuthFailure('Dieses Konto ist gesperrt.'),
    'user_session_already_exists' => const AuthFailure(
        'Es besteht bereits eine aktive Sitzung. Bitte lade die Seite neu.'),
    'general_rate_limit_exceeded' => const AuthFailure(
        'Zu viele Versuche. Bitte warte einen Moment und versuche es erneut.'),
    'password_personal_data' => const AuthFailure(
        'Das Passwort darf keine persönlichen Daten enthalten.'),

    // Verbrauchtes, abgelaufenes oder falsches Einmal-Geheimnis.
    'user_invalid_token' => switch (context) {
        AuthContext.link => const AuthFailure(
            'Dieser Link ist abgelaufen oder wurde bereits verwendet. '
            'Fordere bitte einen neuen an.'),
        // Gleicher Text wie 'user_recovery_code_invalid', damit nicht
        // unterscheidbar wird, welche Art Code danebenlag.
        AuthContext.mfa => const AuthFailure('Der Code ist ungültig.'),
        AuthContext.general =>
          const AuthFailure('Der Bestätigungslink ist nicht mehr gültig.'),
      },
    'user_recovery_code_invalid' => const AuthFailure('Der Code ist ungültig.'),

    // Der Anbieter hat abgelehnt oder ist falsch konfiguriert. Eine gemeinsame
    // Meldung: die Unterscheidung hilft nur beim Debuggen, nicht dem Nutzer.
    'user_oauth2_unauthorized' ||
    'user_oauth2_bad_request' ||
    'user_oauth2_provider_error' =>
      const AuthFailure('Die Anmeldung über den Anbieter ist fehlgeschlagen.'),
    'user_authenticator_not_found' => const AuthFailure(
        'Für dieses Konto ist kein Verfahren zur Bestätigung hinterlegt.'),
    'user_authenticator_already_verified' =>
      const AuthFailure('Dieses Verfahren ist bereits aktiv.'),
    'user_challenge_required' =>
      const AuthFailure('Bitte bestätige die Aktion erneut.'),

    // Sollte den Mapper nie erreichen: die Anmeldung faengt das vorher ab und
    // fuehrt in die Zwei-Faktor-Abfrage. Als Netz trotzdem ein neutraler Text.
    'user_more_factors_required' =>
      const AuthFailure('Für dieses Konto ist eine weitere Bestätigung nötig.'),
    _ => AuthFailure(fallback),
  };

  if (kDebugMode && e.type != null) {
    debugPrint('Appwrite-Fehler (${e.type}): ${e.message}');
  }
  return failure;
}
