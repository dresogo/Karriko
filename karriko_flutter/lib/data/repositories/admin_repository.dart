import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw;

import '../../core/constants/questionnaire_constants.dart';
import '../services/appwrite_service.dart';

/// Was das angemeldete Konto im Admin-Bereich darf.
class AdminRoles {
  final bool isAdmin;
  final bool isModerator;

  const AdminRoles({required this.isAdmin, required this.isModerator});

  /// Admins dürfen alles, was Moderatoren dürfen — wie `TeamGuard`.
  bool get mayModerate => isAdmin || isModerator;
}

/// Zugang zu `moderate_review` und `recompute_all`.
///
/// **Die Rollenprüfung hier ist nur Anzeige.** Sie entscheidet, welche Knöpfe
/// erscheinen. Geschützt sind die Aktionen durch die Ausführungsrechte der
/// Functions und durch `TeamGuard` darin; wer sich diesen Bildschirm
/// zurechtbiegt, bekommt von der Function trotzdem ein 403.
class AdminRepository {
  Functions get _functions => Functions(AppwriteService.client);

  /// Liest die Teams des angemeldeten Kontos. Ein Konto sieht nur Teams, in
  /// denen es selbst Mitglied ist — mehr braucht es hier nicht.
  Future<AdminRoles> loadRoles() async {
    final liste = await Teams(AppwriteService.client).list();
    final ids = {for (final team in liste.teams) team.$id};
    return AdminRoles(
      isAdmin: ids.contains(QuestionnaireConstants.adminsTeam),
      isModerator: ids.contains(QuestionnaireConstants.moderatorsTeam),
    );
  }

  Future<Map<String, Object?>> approve(String reviewId, {bool? verified}) =>
      _call(QuestionnaireConstants.moderateReviewFunction, {
        'review_id': reviewId,
        'action': 'approve',
        if (verified != null) 'verified': verified,
      });

  Future<Map<String, Object?>> reject(String reviewId, String reason) =>
      _call(QuestionnaireConstants.moderateReviewFunction, {
        'review_id': reviewId,
        'action': 'reject',
        'reason': reason,
      });

  Future<Map<String, Object?>> recompute({
    required int offset,
    required bool dryRun,
  }) =>
      _call(QuestionnaireConstants.recomputeAllFunction, {
        'offset': offset,
        'dry_run': dryRun,
      });

  Future<Map<String, Object?>> _call(
    String functionId,
    Map<String, Object?> body,
  ) async {
    final execution = await _functions.createExecution(
      functionId: functionId,
      body: jsonEncode(body),
      xasync: false,
      method: aw.ExecutionMethod.pOST,
      path: '/',
    );

    final antwort = _decode(execution.responseBody);
    if (execution.responseStatusCode >= 400 || antwort['ok'] != true) {
      throw AdminException(
        antwort['message'] as String? ??
            'Die Function hat mit ${execution.responseStatusCode} geantwortet.',
      );
    }
    return antwort;
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

class AdminException implements Exception {
  final String message;

  const AdminException(this.message);

  @override
  String toString() => message;
}
