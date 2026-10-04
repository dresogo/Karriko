import 'package:dart_appwrite/dart_appwrite.dart';

import 'config.dart';

/// Prüft die Team-Zugehörigkeit des aufrufenden Nutzers.
///
/// Warum nicht über die Ausführungsrechte der Function allein: Appwrite schützt
/// damit schon den Aufruf, und das ist die erste Schranke. Diese Prüfung ist die
/// zweite — sie hält fest, **wer** moderiert hat, und dieser Name landet im
/// `moderation_log`. Eine Moderation ohne nachvollziehbaren Urheber ist keine.
class TeamGuard {
  final Client adminClient;
  final FunctionConfig config;

  TeamGuard({required this.adminClient, required this.config});

  Future<bool> isModerator(String userId) =>
      _istMitglied(config.moderatorsTeam, userId);

  Future<bool> isAdmin(String userId) =>
      _istMitglied(config.adminsTeam, userId);

  /// Admins dürfen alles, was Moderatoren dürfen.
  Future<bool> mayModerate(String userId) async =>
      await isModerator(userId) || await isAdmin(userId);

  Future<bool> _istMitglied(String teamId, String userId) async {
    try {
      final mitgliedschaften = await Teams(adminClient).listMemberships(
        teamId: teamId,
        queries: [Query.equal('userId', userId), Query.limit(1)],
      );
      return mitgliedschaften.memberships.isNotEmpty &&
          mitgliedschaften.memberships.first.confirm;
    } on AppwriteException {
      // Ein fehlendes Team ist kein „ja". Wer die Teams nicht angelegt hat,
      // hat niemanden berechtigt — und nicht alle.
      return false;
    }
  }
}
