import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw;

import '../../core/constants/questionnaire_constants.dart';
import '../services/appwrite_service.dart';

/// Meldungen zu einer veröffentlichten Bewertung.
///
/// Das Einzige, was ein Client rund um eine fremde Bewertung anstoßen darf.
/// Eine Meldung ist kein Urteil: Sie legt eine Zeile an, mehr passiert nicht.
/// Ob eine Bewertung verschwindet, entscheidet die Moderation — automatisches
/// Löschen trifft erfahrungsgemäß vor allem die ausführlichen, ehrlichen
/// Bewertungen.
///
/// Angelegt wird über die Function `report_review` (T-4.41). **Keine
/// Melderkennung im Aufruf:** Die Function nimmt sie aus dem geprüften JWT;
/// vorher setzte der Client `reporter_id` selbst und konnte so im Namen
/// anderer melden.
class ReviewReportRepository {
  /// [functions] ersetzt in Tests den Zugriff auf Appwrite.
  ReviewReportRepository({Functions? functions})
      : _functionsOverride = functions;

  final Functions? _functionsOverride;

  Functions get _functions =>
      _functionsOverride ?? Functions(AppwriteService.client);

  Future<void> report({
    required String reviewId,
    required String reason,
  }) async {
    final execution = await _functions.createExecution(
      functionId: QuestionnaireConstants.reportReviewFunction,
      body: jsonEncode({'review_id': reviewId, 'reason': reason}),
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
      throw ReportException(
        antwort['message'] as String? ??
            'Die Meldung hat gerade nicht geklappt. Bitte versuch es später '
                'noch einmal.',
      );
    }
  }
}

/// `report_review` hat abgelehnt oder ist nicht erreichbar. [message] richtet
/// sich an den Nutzer.
class ReportException implements Exception {
  const ReportException(this.message);

  final String message;

  @override
  String toString() => message;
}
