import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw;

import '../../core/constants/questionnaire_constants.dart';
import '../services/appwrite_service.dart';

/// Die Rechte eines Kontos an seinen eigenen Daten, ueber die Function
/// `my_account`: Konto loeschen (T-2.8, Art. 17), eigene Bewertung loeschen
/// (T-2.9) und Daten herunterladen (T-2.10, Art. 20).
///
/// Wie bei `my_reviews` wird **keine Nutzerkennung mitgeschickt**. Die
/// Function nimmt sie aus dem geprueften JWT; ein Parameter dafuer waere eine
/// Einladung, fremde Konten zu loeschen.
class AccountRepository {
  /// [functions] ersetzt in Tests den Zugriff auf Appwrite.
  AccountRepository({Functions? functions}) : _functionsOverride = functions;

  final Functions? _functionsOverride;

  Functions get _functions =>
      _functionsOverride ?? Functions(AppwriteService.client);

  /// Beantragt die Loeschung. Liefert den Zeitpunkt, ab dem sie endgueltig
  /// ist (14 Tage, E-50). Ein zweiter Antrag aendert die Frist nicht.
  Future<DateTime?> requestDeletion() async =>
      _termin(await _aufruf({'action': 'request_deletion'}));

  /// Nimmt eine beantragte Loeschung zurueck.
  Future<void> cancelDeletion() => _aufruf({'action': 'cancel_deletion'});

  /// Loescht eine eigene abgeschickte Bewertung vollstaendig, auch die
  /// oeffentliche Ansicht. Der Score des Betriebs wird neu berechnet.
  Future<void> deleteReview(String reviewId) =>
      _aufruf({'action': 'delete_review', 'review_id': reviewId});

  /// Alle selbst eingegebenen Daten als formatiertes JSON.
  Future<String> exportJson() async {
    final antwort = await _aufruf({'action': 'export'});
    return const JsonEncoder.withIndent('  ').convert(antwort['export']);
  }

  DateTime? _termin(Map<String, Object?> antwort) {
    final loeschung = antwort['deletion'];
    if (loeschung is! Map) return null;
    final wert = loeschung['delete_after'];
    return wert is String ? DateTime.tryParse(wert) : null;
  }

  Future<Map<String, Object?>> _aufruf(Map<String, Object?> body) async {
    final execution = await _functions.createExecution(
      functionId: QuestionnaireConstants.myAccountFunction,
      body: jsonEncode(body),
      xasync: false,
      method: aw.ExecutionMethod.pOST,
      path: '/',
    );
    Map<String, Object?> antwort = const {};
    try {
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is Map) antwort = decoded.cast<String, Object?>();
    } on FormatException {
      // bleibt leer, unten als Fehler behandelt
    }
    if (execution.responseStatusCode >= 400 || antwort['ok'] != true) {
      throw AccountException(
        antwort['message'] as String? ??
            'Das hat gerade nicht geklappt. Bitte versuch es später noch '
                'einmal.',
      );
    }
    return antwort;
  }
}

/// `my_account` hat abgelehnt oder ist nicht erreichbar. [message] richtet
/// sich an den Nutzer.
class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}
