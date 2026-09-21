/// Alles, was der Fragebogen an Appwrite-Kennungen und Fristen braucht.
///
/// Die Kennungen sind ueber `--dart-define` austauschbar, damit sich eine
/// zweite Umgebung (Test, Abnahme) aufsetzen laesst, ohne den Code zu aendern.
/// Die Standardwerte sind sprechende Namen, keine echten Kennungen — die
/// Datenbank- und Projekt-ID des Bestands stehen im Klartext im Repository,
/// das soll sich hier nicht fortsetzen.
class QuestionnaireConstants {
  QuestionnaireConstants._();

  // ── Tabellen ──────────────────────────────────────────────────────────────

  static const releasesCollection = String.fromEnvironment(
    'TBL_QUESTIONNAIRE_RELEASES',
    defaultValue: 'questionnaire_releases',
  );

  static const draftsCollection = String.fromEnvironment(
    'TBL_REVIEW_DRAFTS',
    defaultValue: 'review_drafts',
  );

  static const publicReviewsCollection = String.fromEnvironment(
    'TBL_PUBLIC_REVIEWS',
    defaultValue: 'public_reviews',
  );

  static const companyScoresCollection = String.fromEnvironment(
    'TBL_COMPANY_SCORES',
    defaultValue: 'company_scores',
  );

  // ── Ablagen ───────────────────────────────────────────────────────────────

  static const questionnairesBucket = String.fromEnvironment(
    'BUCKET_QUESTIONNAIRES',
    defaultValue: 'questionnaires',
  );

  static const verificationBucket = String.fromEnvironment(
    'BUCKET_VERIFICATION',
    defaultValue: 'verification_documents',
  );

  // ── Functions ─────────────────────────────────────────────────────────────

  /// Die einzige Stelle, an der eine Bewertung entsteht. Der Client hat auf
  /// `reviews` kein Schreibrecht.
  static const submitReviewFunction = String.fromEnvironment(
    'FN_SUBMIT_REVIEW',
    defaultValue: 'submit_review',
  );

  // ── Mitgelieferter Rueckfall ──────────────────────────────────────────────

  /// Wird benutzt, wenn der Storage nicht erreichbar ist. Muss Zeichen fuer
  /// Zeichen mit `appwrite/questionnaires/questionnaire_v1.json`
  /// uebereinstimmen; dafuer gibt es `tools/sync_questionnaire.dart`.
  static const bundledAsset = 'assets/questionnaire/questionnaire_v1.json';

  /// Die Version, die als Asset mitgeliefert wird. Wird beim Laden gegen die
  /// Datei geprueft.
  static const bundledVersion = 1;

  static const locale = 'de-DE';

  // ── Fristen ───────────────────────────────────────────────────────────────

  /// Wie lange nach der letzten Antwort gewartet wird, bevor der Entwurf nach
  /// Appwrite geht. Lokal wird sofort gespeichert.
  ///
  /// Ohne die Verzoegerung schriebe jeder Tastendruck im Freitext ein Dokument.
  static const draftSyncDelay = Duration(seconds: 3);

  /// Query-Parameter, ueber den eine Einladung ihre Quelle mitgibt.
  ///
  /// Spontane Bewertungen fallen systematisch extremer aus als angeforderte.
  /// Wer ueber eine Einladung kommt, wird deshalb markiert — diese Stichprobe
  /// ist repraesentativer.
  static const inviteSourceParam = 'src';

  /// Erlaubte Werte fuer [inviteSourceParam]. Alles andere wird verworfen,
  /// damit sich die Markierung nicht ueber eine selbstgebaute URL erschleichen
  /// laesst.
  static const inviteSources = {
    'probezeit',
    'jahresbeginn',
    'nach_ende',
    'kammer',
    'schule',
  };
}
