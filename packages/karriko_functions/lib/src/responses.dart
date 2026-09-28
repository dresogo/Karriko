/// Die Antworten, die eine Function gibt.
///
/// Immer dieselbe Form: `ok` als Wahrheitswert, bei einem Fehler zusätzlich
/// `code` und `message`. Der Client unterscheidet am `code`, was zu tun ist,
/// und zeigt `message` an — deshalb richtet sich `message` an den Azubi und
/// nicht an den Entwickler. Was genau nicht stimmte, steht im Log.
class FunctionResponse {
  final int status;
  final Map<String, Object?> payload;

  const FunctionResponse(this.status, this.payload);

  bool get isOk => payload['ok'] == true;

  static FunctionResponse ok([Map<String, Object?> daten = const {}]) =>
      FunctionResponse(200, {'ok': true, ...daten});

  /// Die Einreichung passt nicht zu ihrer Version.
  static FunctionResponse invalid(String message,
          [List<String> details = const []]) =>
      FunctionResponse(400, {
        'ok': false,
        'code': 'validation',
        'message': message,
        if (details.isNotEmpty) 'details': details,
      });

  /// Es gibt schon eine Bewertung dieses Nutzers zu diesem Betrieb.
  static FunctionResponse duplicate(String message) => FunctionResponse(409, {
        'ok': false,
        'code': 'duplicate',
        'message': message,
      });

  /// Nicht angemeldet oder nicht berechtigt.
  static FunctionResponse unauthorized(String message) =>
      FunctionResponse(401, {
        'ok': false,
        'code': 'unauthorized',
        'message': message,
      });

  static FunctionResponse forbidden(String message) => FunctionResponse(403, {
        'ok': false,
        'code': 'forbidden',
        'message': message,
      });

  /// Etwas ist schiefgegangen, das der Nutzer nicht zu verantworten hat.
  ///
  /// Bewusst ohne technische Einzelheiten: Eine Fehlermeldung ist kein Ort für
  /// Interna, und dem Azubi hilft „versuch es gleich nochmal" mehr als der
  /// Name einer Tabelle.
  static FunctionResponse unavailable(String message) => FunctionResponse(503, {
        'ok': false,
        'code': 'unavailable',
        'message': message,
      });
}
