/// Was der Verfasser über seine **eigene** Bewertung erfahren darf.
///
/// Das ist nicht dasselbe wie „alles, was in der Zeile steht". Eine Bewertung
/// trägt Angaben, die für die Moderation gedacht sind, und ein paar davon
/// würden ihren Zweck verlieren, sobald der Verfasser sie sieht.
///
/// Was zurückgeht, steht in [buildOwnReviewEntry]. Was absichtlich fehlt, steht
/// in [withheldFromAuthor] — mit dem Grund, damit es niemand später „der
/// Vollständigkeit halber" ergänzt.
library;

/// Die Spalten, die der Verfasser **nicht** zu sehen bekommt, und warum.
///
/// Diese Zuordnung ist nicht Dokumentation, sondern Prüfgegenstand: Ein Test
/// geht sie durch und stellt sicher, dass keine davon in der Antwort landet.
const withheldFromAuthor = <String, String>{
  'quality_flags':
      'Wer erfährt, dass er als Durchklicker markiert wurde, weiss beim '
          'naechsten Mal, wie er es vermeidet. Flags leiten in die Moderation; '
          'sie sind keine Rueckmeldung an den Verfasser.',
  'quality_notes': 'Wie quality_flags, nur ausformuliert.',
  'timings_json':
      'Aus den Zeiten entsteht das Flag too_fast. Sie zurueckzugeben hiesse, '
          'die Schwelle verhandelbar zu machen.',
  'answers_json':
      'Der Verfasser kennt seine Antworten. Sie noch einmal auszuliefern '
          'bringt ihm nichts und macht die Antwort gross.',
  'detail_overall':
      'Die gerechneten Werte sind vor der Freigabe nicht endgueltig — '
          'recompute_all kann sie aendern, die Moderation kann ablehnen. Nach '
          'der Freigabe stehen sie in der oeffentlichen Ansicht, die der '
          'Verfasser wie jeder andere sieht. Zwei Darstellungen desselben Werts '
          'waeren eine zu viel.',
  'sub_fachlich': 'Wie detail_overall.',
  'sub_betreuung': 'Wie detail_overall.',
  'sub_umgang': 'Wie detail_overall.',
  'sub_belastung': 'Wie detail_overall.',
  'sub_verguetung': 'Wie detail_overall.',
  'sub_perspektive': 'Wie detail_overall.',
  'sub_berufsschule': 'Wie detail_overall.',
  'k5_recommend': 'Wie detail_overall.',
  'k6_overall': 'Wie detail_overall.',
  'device_hash':
      'Ein gesalzener Hash der Geraetekennung. Er dient dem Erkennen von '
          'Mehrfachabgaben und hat im Client nichts zu suchen.',
  'user_id': 'Die Zuordnung, um die es hier geht, ist der Aufrufer selbst. Sie '
      'zurueckzuspiegeln bringt nichts.',
  'verification_file_id':
      'Dass ein Nachweis vorlag, sagt `verified`. Die Dateikennung sagt nichts '
          'darueber hinaus.',
  'invited': 'Interne Kennzeichnung fuer die Auswertung der Stichprobe.',
  'invite_source': 'Wie invited.',
  'beruf_code': 'Interner Schluessel. Angezeigt wird beruf_name.',
  'respondent_status': 'Interne Kennzeichnung fuer die Auswertung.',
  'moderator_id':
      'Wer eine Bewertung abgelehnt hat, bleibt dem Verfasser gegenueber '
          'ungenannt. Die Begruendung gehoert ihm, der Name nicht.',
};

/// Baut einen Eintrag der Liste „meine abgeschickten Bewertungen".
///
/// Reine Funktion über die Zeile und ein paar nachgeladene Angaben — kein
/// Appwrite, kein Netz. Damit lässt sich prüfen, was ausgeliefert würde, ohne
/// es auszuliefern.
///
/// [rejectionReason] steht nur bei einer Ablehnung. `moderate_review` weist
/// eine Ablehnung ohne Begründung zurück, und zwar genau deshalb: Sie wäre für
/// den Verfasser nicht nachvollziehbar. Hier kommt sie bei ihm an.
Map<String, Object?> buildOwnReviewEntry({
  required String reviewId,
  required Map<String, Object?> reviewRow,
  required String submittedAt,
  String? companyName,
  String? companySlug,
  String? publicReviewId,
  String? publishedAt,
  String? rejectionReason,
}) {
  final status = reviewRow['status'];

  return {
    'review_id': reviewId,
    'company_id': reviewRow['company_id'],
    'company_name': companyName,
    'company_slug': companySlug,
    'status': status,
    'submitted_at': submittedAt,

    // Die eigenen Angaben. Der Verfasser hat sie geschrieben; sie wiederzusehen
    // ist der Sinn der Liste.
    'beruf_name': reviewRow['beruf_name'],
    'start_year': reviewRow['start_year'],
    'end_year': reviewRow['end_year'],
    'freitext_gut': reviewRow['freitext_gut'],
    'freitext_schlecht': reviewRow['freitext_schlecht'],
    'verified': reviewRow['verified'] ?? false,

    // Zurückgestellt: Wann es weitergeht. Ohne diese Angabe sähe eine
    // zurückgestellte Bewertung wie eine verschollene aus.
    if (reviewRow['publish_after'] != null)
      'publish_after': reviewRow['publish_after'],
    if (reviewRow['publish_after_training_end'] == true)
      'publish_after_training_end': true,

    // Freigegeben: der Verweis auf die öffentliche Zeile, damit der Client
    // dorthin verlinken kann.
    if (publicReviewId != null) 'public_review_id': publicReviewId,
    if (publishedAt != null) 'published_at': publishedAt,

    // Abgelehnt: die Begründung, ohne den Namen des Moderators.
    if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
      'rejection_reason': rejectionReason.trim(),
  };
}
