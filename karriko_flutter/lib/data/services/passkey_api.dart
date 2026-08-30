import 'package:dio/dio.dart';
import '../../core/constants/appwrite_constants.dart';
import '../models/passkey_credential.dart';
import '../repositories/auth_error_mapper.dart';

/// HTTP-Zugriff auf den eigenen WebAuthn-Dienst (`services/passkey-rp`).
///
/// Der Dienst antwortet im Fehlerfall mit `{"message": "..."}` in deutscher
/// Sprache; diese Meldungen sind für die Anzeige gedacht und werden
/// durchgereicht. Alles andere bekommt einen allgemeinen Text — eine rohe
/// Netzwerkmeldung hilft niemandem und kann verraten, was serverseitig
/// existiert.
class PasskeyApi {
  final Dio _dio;

  PasskeyApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppwriteConstants.passkeyServiceUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 20),
                // Fehlerstatus selbst auswerten, statt Dio werfen zu lassen:
                // So kommt die Meldung des Dienstes beim Nutzer an.
                validateStatus: (_) => true,
              ),
            );

  Options _mitJwt(String jwt) => Options(
        headers: {'Authorization': 'Bearer $jwt'},
      );

  Never _fehler(Response<dynamic> response, String fallback) {
    final data = response.data;
    final message = data is Map && data['message'] is String
        ? data['message'] as String
        : fallback;
    throw AuthFailure(message);
  }

  Future<Map<String, dynamic>> registrierungsOptionen(String jwt) async {
    final response = await _dio.post<dynamic>(
      '/webauthn/register/options',
      options: _mitJwt(jwt),
    );
    if (response.statusCode != 200) {
      _fehler(response, 'Die Einrichtung konnte nicht gestartet werden.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> registrierungBestaetigen({
    required String jwt,
    required String challenge,
    required Map<String, dynamic> antwort,
    required String geraetename,
  }) async {
    final response = await _dio.post<dynamic>(
      '/webauthn/register/verify',
      options: _mitJwt(jwt),
      data: {
        'challenge': challenge,
        'response': antwort,
        'deviceName': geraetename,
      },
    );
    if (response.statusCode != 200) {
      _fehler(response, 'Der Passkey konnte nicht gespeichert werden.');
    }
  }

  Future<Map<String, dynamic>> anmeldeOptionen() async {
    final response = await _dio.post<dynamic>('/webauthn/login/options');
    if (response.statusCode != 200) {
      _fehler(response, 'Die Anmeldung konnte nicht gestartet werden.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Liefert das Paar, das gegen eine Appwrite-Sitzung getauscht wird.
  Future<({String userId, String secret})> anmeldungBestaetigen({
    required String challenge,
    required Map<String, dynamic> antwort,
  }) async {
    final response = await _dio.post<dynamic>(
      '/webauthn/login/verify',
      data: {'challenge': challenge, 'response': antwort},
    );
    if (response.statusCode != 200) {
      _fehler(response, 'Die Anmeldung mit dem Passkey ist fehlgeschlagen.');
    }
    final data = response.data as Map;
    return (userId: data['userId'] as String, secret: data['secret'] as String);
  }

  Future<List<PasskeyCredential>> auflisten(String jwt) async {
    final response = await _dio.get<dynamic>(
      '/webauthn/credentials',
      options: _mitJwt(jwt),
    );
    if (response.statusCode != 200) {
      _fehler(response, 'Die Passkeys konnten nicht geladen werden.');
    }
    final liste = (response.data as Map)['passkeys'] as List;
    return liste
        .map((e) => PasskeyCredential.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> loeschen({required String jwt, required String id}) async {
    final response = await _dio.delete<dynamic>(
      '/webauthn/credentials/${Uri.encodeComponent(id)}',
      options: _mitJwt(jwt),
    );
    if (response.statusCode != 200) {
      _fehler(response, 'Der Passkey konnte nicht entfernt werden.');
    }
  }
}
