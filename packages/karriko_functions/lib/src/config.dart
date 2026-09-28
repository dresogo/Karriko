/// Alles, was eine Function aus ihrer Umgebung liest.
///
/// **Keine Voreinstellungen für Kennungen, die es nur einmal gibt.** Die
/// Datenbank-ID hat keinen sinnvollen Standardwert: Ein Tippfehler in der
/// Variablen würde sonst gegen eine erfundene Datenbank laufen und eine
/// Fehlermeldung erzeugen, die auf alles andere hindeutet. Fehlt sie, bricht
/// die Function beim Start ab und sagt, welche Variable fehlt.
///
/// **Keine Secrets im Code.** Das Salz für die Gerätekennung kommt aus der
/// Umgebung; ohne es wird gar nicht gehasht, statt mit einem eingebauten
/// Ersatzwert weiterzumachen — ein bekanntes Salz ist kein Salz.
class FunctionConfig {
  final String endpoint;
  final String projectId;
  final String databaseId;

  final String reviewsTable;
  final String publicReviewsTable;
  final String draftsTable;
  final String companyScoresTable;
  final String moderationLogTable;
  final String releasesTable;

  final String questionnairesBucket;
  final String verificationBucket;

  final String moderatorsTeam;
  final String adminsTeam;

  /// Salz für den Hash der Gerätekennung. `null` heißt: nicht hashen.
  final String? deviceHashSalt;

  /// Nach wie vielen Tagen ohne Änderung ein Entwurf verfällt.
  final int draftRetentionDays;

  /// Nach wie vielen Tagen ein geprüfter Verifikationsnachweis gelöscht wird.
  final int verificationRetentionDays;

  /// Um wie viele Tage die Veröffentlichung verschoben wird, wenn jemand in
  /// A3 darum bittet.
  final int delayDays;

  /// Um wie viele Monate bei einem Kleinbetrieb verschoben wird, wenn der
  /// Azubi „erst nach Ausbildungsende" wählt und kein Enddatum bekannt ist.
  final int smallBusinessDelayMonths;

  const FunctionConfig({
    required this.endpoint,
    required this.projectId,
    required this.databaseId,
    required this.reviewsTable,
    required this.publicReviewsTable,
    required this.draftsTable,
    required this.companyScoresTable,
    required this.moderationLogTable,
    required this.releasesTable,
    required this.questionnairesBucket,
    required this.verificationBucket,
    required this.moderatorsTeam,
    required this.adminsTeam,
    required this.deviceHashSalt,
    required this.draftRetentionDays,
    required this.verificationRetentionDays,
    required this.delayDays,
    required this.smallBusinessDelayMonths,
  });

  /// Liest die Konfiguration aus [env], üblicherweise `Platform.environment`.
  ///
  /// Wird als Funktion statt als Zugriff auf `Platform` gebaut, damit sich das
  /// im Test durchspielen lässt — eine Konfiguration, die nur unter Appwrite
  /// prüfbar ist, wird nicht geprüft.
  static FunctionConfig fromEnvironment(Map<String, String> env) {
    String pflicht(String name) {
      final wert = env[name];
      if (wert == null || wert.trim().isEmpty) {
        throw MissingConfigException(name);
      }
      return wert.trim();
    }

    String mit(String name, String standard) {
      final wert = env[name];
      return wert == null || wert.trim().isEmpty ? standard : wert.trim();
    }

    int zahl(String name, int standard) {
      final wert = env[name];
      if (wert == null) return standard;
      return int.tryParse(wert.trim()) ?? standard;
    }

    return FunctionConfig(
      // APPWRITE_FUNCTION_API_ENDPOINT und _PROJECT_ID setzt Appwrite selbst.
      endpoint: mit('APPWRITE_FUNCTION_API_ENDPOINT',
          mit('APPWRITE_ENDPOINT', 'https://fra.cloud.appwrite.io/v1')),
      projectId: pflicht('APPWRITE_FUNCTION_PROJECT_ID'),
      databaseId: pflicht('KARRIKO_DATABASE_ID'),
      reviewsTable: mit('KARRIKO_TBL_REVIEWS', 'reviews'),
      publicReviewsTable: mit('KARRIKO_TBL_PUBLIC_REVIEWS', 'public_reviews'),
      draftsTable: mit('KARRIKO_TBL_DRAFTS', 'review_drafts'),
      companyScoresTable: mit('KARRIKO_TBL_COMPANY_SCORES', 'company_scores'),
      moderationLogTable: mit('KARRIKO_TBL_MODERATION_LOG', 'moderation_log'),
      releasesTable: mit('KARRIKO_TBL_RELEASES', 'questionnaire_releases'),
      questionnairesBucket:
          mit('KARRIKO_BUCKET_QUESTIONNAIRES', 'questionnaires'),
      verificationBucket:
          mit('KARRIKO_BUCKET_VERIFICATION', 'verification_documents'),
      moderatorsTeam: mit('KARRIKO_TEAM_MODERATORS', 'moderators'),
      adminsTeam: mit('KARRIKO_TEAM_ADMINS', 'admins'),
      deviceHashSalt: env['KARRIKO_DEVICE_HASH_SALT']?.trim().isEmpty ?? true
          ? null
          : env['KARRIKO_DEVICE_HASH_SALT']!.trim(),
      draftRetentionDays: zahl('KARRIKO_DRAFT_RETENTION_DAYS', 90),
      verificationRetentionDays:
          zahl('KARRIKO_VERIFICATION_RETENTION_DAYS', 30),
      delayDays: zahl('KARRIKO_DELAY_DAYS', 3),
      smallBusinessDelayMonths: zahl('KARRIKO_SMALL_BUSINESS_DELAY_MONTHS', 6),
    );
  }
}

/// Eine Pflichtvariable fehlt.
class MissingConfigException implements Exception {
  final String name;

  const MissingConfigException(this.name);

  @override
  String toString() =>
      'Die Umgebungsvariable "$name" fehlt. Siehe notes/APPWRITE_SETUP.md.';
}
