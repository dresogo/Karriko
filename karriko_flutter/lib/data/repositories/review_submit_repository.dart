import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw;

import '../../core/constants/questionnaire_constants.dart';
import '../services/appwrite_service.dart';

/// Was beim Absenden herauskommt.
class SubmitResult {
  /// Die Kennung der angelegten Bewertung.
  final String reviewId;

  /// `pending_moderation` oder `scheduled`.
  final String status;

  /// Bei `scheduled`: ab wann sie in die Moderation geht.
  final DateTime? publishAfter;

  const SubmitResult({
    required this.reviewId,
    required this.status,
    this.publishAfter,
  });
}

/// Wird geworfen, wenn die Function die Einreichung ablehnt.
///
/// Die Meldungen richten sich an den Azubi und nicht an den Entwickler: Was
/// genau serverseitig nicht stimmte, steht im Log der Function, nicht auf dem
/// Bildschirm.
class SubmitException implements Exception {
  final String message;

  /// Maschinenlesbar, falls die Oberflaeche unterscheiden will:
  /// `validation`, `duplicate`, `unauthorized`, `unavailable`.
  final String code;

  const SubmitException(this.code, this.message);

  @override
  String toString() => message;
}

/// Schickt eine fertige Bewertung ab.
///
/// **Der Client schreibt nicht in `reviews`.** Er ruft `submit_review` auf und
/// schickt Rohantworten, Zeiten und die `schema_version` mit. Die Function
/// laedt genau diese Version, prueft die Einreichung dagegen, rechnet die
/// Werte neu und legt die Zeile an. Was der Client vorher gerechnet hat, war
/// fuer die Anzeige — verbindlich ist nur das Ergebnis der Function.
class ReviewSubmitRepository {
  Functions get _functions => Functions(AppwriteService.client);

  Future<SubmitResult> submit({
    required String companyId,
    required int schemaVersion,
    required Map<String, Object?> answers,
    required Map<String, int> timings,
    String? inviteSource,
    String? verificationFileId,
    String? draftId,

    /// Eine stabile Kennung des Geraets. Wird **serverseitig** gesalzen und
    /// gehasht; hier geht der Rohwert hin, gespeichert wird er nie.
    String? deviceKey,
  }) async {
    final body = jsonEncode({
      'company_id': companyId,
      'schema_version': schemaVersion,
      'answers': answers,
      'timings': timings,
      if (inviteSource != null) 'invite_source': inviteSource,
      if (verificationFileId != null) 'verification_file_id': verificationFileId,
      if (draftId != null) 'draft_id': draftId,
      if (deviceKey != null) 'device_key': deviceKey,
    });

    try {
      final execution = await _functions.createExecution(
        functionId: QuestionnaireConstants.submitReviewFunction,
        body: body,
        // Nicht asynchron: Der Azubi soll erfahren, ob es geklappt hat,
        // bevor er die Seite verlaesst.
        xasync: false,
        method: aw.ExecutionMethod.pOST,
        path: '/',
      );

      final antwort = _decode(execution.responseBody);

      if (execution.responseStatusCode >= 400 || antwort['ok'] != true) {
        throw SubmitException(
          antwort['code'] as String? ?? 'validation',
          antwort['message'] as String? ??
              'Die Bewertung konnte nicht gespeichert werden.',
        );
      }

      final publishAfter = antwort['publish_after'];
      return SubmitResult(
        reviewId: antwort['review_id'] as String,
        status: antwort['status'] as String? ?? 'pending_moderation',
        publishAfter:
            publishAfter is String ? DateTime.tryParse(publishAfter) : null,
      );
    } on AppwriteException catch (e) {
      throw SubmitException(
        e.code == 401 ? 'unauthorized' : 'unavailable',
        e.code == 401
            ? 'Bitte melde dich an, um deine Bewertung abzuschicken.'
            : 'Die Bewertung konnte gerade nicht abgeschickt werden. '
                'Dein Entwurf ist gespeichert.',
      );
    }
  }

  /// Eine Antwort, die kein JSON ist, ist ein Fehler der Function — aber kein
  /// Grund, den Nutzer mit einem Stacktrace zu behelligen.
  Map<String, Object?> _decode(String body) {
    if (body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      return const {};
    }
    return const {};
  }
}
