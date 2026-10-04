import 'dart:convert';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'config.dart';

/// Was eine Appwrite Function bei der Ausführung mitbekommt.
///
/// Die Runtime übergibt ein dynamisches Objekt mit `req`, `res`, `log` und
/// `error`. Das hier packt es in etwas, das sich ohne Runtime bauen lässt —
/// sonst wäre keine dieser Functions testbar.
class RunContext {
  final FunctionConfig config;

  /// Die Kopfzeilen der Anfrage, Namen in Kleinbuchstaben.
  final Map<String, String> headers;

  /// Der Rumpf der Anfrage, sofern es einer ist.
  final Map<String, Object?> body;

  /// Bei einem Ereignis-Auslöser: das ausgelöste Ereignis und die Zeile.
  final String? event;
  final Map<String, Object?>? eventData;

  final void Function(String message) log;
  final void Function(String message) logError;

  const RunContext({
    required this.config,
    required this.headers,
    required this.body,
    required this.log,
    required this.logError,
    this.event,
    this.eventData,
  });

  /// Der dynamische API-Schlüssel, den Appwrite pro Ausführung mitgibt.
  ///
  /// Damit handelt die Function mit den Rechten ihrer **Scopes**, nicht mit
  /// denen eines Nutzers. Ein eigener, dauerhaft hinterlegter Schlüssel wäre
  /// ein Geheimnis mehr, das jemand verwalten müsste.
  String? get dynamicApiKey => headers['x-appwrite-key'];

  /// Das JWT des aufrufenden Nutzers, wenn die Ausführung von einem
  /// angemeldeten Client kommt.
  String? get userJwt => headers['x-appwrite-user-jwt'];

  /// Die Kennung des aufrufenden Nutzers. Setzt Appwrite selbst.
  String? get userId {
    final id = headers['x-appwrite-user-id'];
    return id == null || id.isEmpty ? null : id;
  }

  /// Ein Client mit den Rechten der Function.
  Client adminClient() {
    final key = dynamicApiKey;
    if (key == null || key.isEmpty) {
      throw StateError(
        'Kein dynamischer API-Schluessel in der Anfrage. Die Function wurde '
        'ausserhalb von Appwrite aufgerufen, oder ihr fehlen die Scopes.',
      );
    }
    return Client()
        .setEndpoint(config.endpoint)
        .setProject(config.projectId)
        .setKey(key);
  }

  /// Ein Client, der **als der aufrufende Nutzer** handelt.
  ///
  /// Wird gebraucht, wo die Rechte des Nutzers gelten sollen — etwa beim Lesen
  /// seines eigenen Entwurfs. Mit dem Admin-Schlüssel käme man auch an fremde
  /// Entwürfe, und dann wäre die Zeilenberechtigung eine Zierde.
  Client userClient() {
    final jwt = userJwt;
    if (jwt == null || jwt.isEmpty) {
      throw StateError('Kein Nutzer-JWT in der Anfrage.');
    }
    return Client()
        .setEndpoint(config.endpoint)
        .setProject(config.projectId)
        .setJWT(jwt);
  }

  /// Baut den Kontext aus dem dynamischen Objekt der Runtime.
  static RunContext fromRuntime(
    dynamic context, {
    Map<String, String> environment = const {},
  }) {
    final request = context.req;

    final headers = <String, String>{};
    final rohHeaders = request.headers;
    if (rohHeaders is Map) {
      rohHeaders.forEach((key, value) {
        headers[key.toString().toLowerCase()] = value.toString();
      });
    }

    return RunContext(
      config: FunctionConfig.fromEnvironment(environment),
      headers: headers,
      body: _decodeBody(request),
      event: headers['x-appwrite-event'],
      eventData: _decodeBody(request).isEmpty ? null : _decodeBody(request),
      log: (message) => context.log(message),
      logError: (message) => context.error(message),
    );
  }

  /// Der Rumpf als Zuordnung.
  ///
  /// Die Runtime liefert `bodyJson` nur bei passendem Content-Type; deshalb
  /// notfalls von Hand über `bodyRaw`. Ein Rumpf, der kein JSON ist, ergibt
  /// eine leere Zuordnung — die Function beantwortet das mit einer klaren
  /// Fehlermeldung, nicht mit einem Absturz.
  static Map<String, Object?> _decodeBody(dynamic request) {
    try {
      final json = request.bodyJson;
      if (json is Map) {
        return json.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // weiter unten
    }
    try {
      final roh = request.bodyRaw;
      if (roh is String && roh.isNotEmpty) {
        final decoded = jsonDecode(roh);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }
}
