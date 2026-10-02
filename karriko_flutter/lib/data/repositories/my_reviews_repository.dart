import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw;

import '../../core/constants/questionnaire_constants.dart';
import '../models/own_review.dart';
import '../services/appwrite_service.dart';

/// Holt die eigenen abgeschickten Bewertungen über `my_reviews`.
///
/// **Es gibt keinen direkten Weg dorthin, und das ist Absicht.** Auf `reviews`
/// hat kein Client Zugriff, und `public_reviews` trägt keine `user_id` — eine
/// öffentlich lesbare Zeile, die auf ein Konto zeigt, wäre keine anonyme
/// Bewertung. Die Zuordnung entsteht nur in der Function, nur lesend und nur
/// für die Dauer eines Aufrufs.
///
/// **Es wird keine Nutzerkennung mitgeschickt.** Die Function nimmt sie aus dem
/// geprüften JWT. Ein Parameter dafür wäre eine Einladung, die Bewertungen
/// anderer zu lesen, und deshalb gibt es hier keinen.
class MyReviewsRepository {
  Functions get _functions => Functions(AppwriteService.client);

  Future<List<OwnReview>> load() async {
    final execution = await _functions.createExecution(
      functionId: QuestionnaireConstants.myReviewsFunction,
      body: '{}',
      xasync: false,
      method: aw.ExecutionMethod.pOST,
      path: '/',
    );

    final antwort = _decode(execution.responseBody);

    if (execution.responseStatusCode >= 400 || antwort['ok'] != true) {
      throw MyReviewsException(
        antwort['code'] as String? ?? 'unavailable',
        antwort['message'] as String? ??
            'Deine Bewertungen konnten nicht geladen werden.',
      );
    }

    final liste = antwort['reviews'];
    if (liste is! List) return const [];

    return [
      for (final eintrag in liste)
        if (OwnReview.fromJson(eintrag) case final OwnReview e) e,
    ];
  }

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

class MyReviewsException implements Exception {
  /// `unauthorized` oder `unavailable`.
  final String code;
  final String message;

  const MyReviewsException(this.code, this.message);

  @override
  String toString() => message;
}
