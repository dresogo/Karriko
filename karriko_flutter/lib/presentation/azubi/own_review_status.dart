import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/own_review.dart';
import '../../data/models/review_draft.dart';

/// Ab wann `cleanup` diesen Entwurf löscht (E-51), als Text für die Liste.
String draftDeletionText(ReviewDraft draft) {
  final am = draft.updatedAt
      .add(const Duration(days: AppConstants.draftRetentionDays))
      .toLocal();
  return 'Wird am ${DateFormat('dd.MM.yyyy').format(am)} gelöscht, '
      'wenn du ihn bis dahin nicht weiterbearbeitest';
}

/// Was unter dem Betriebsnamen steht.
///
/// Die vier Zustände bekommen vier Texte. Eine zurückgestellte Bewertung sähe
/// sonst wie eine verschollene aus, und eine abgelehnte wie eine, die noch
/// geprüft wird.
String ownReviewStatusText(OwnReview eintrag) {
  final datum = DateFormat('dd.MM.yyyy').format(eintrag.submittedAt);

  if (eintrag.istZurueckgestellt) {
    if (eintrag.publishAfterTrainingEnd) {
      return 'Gespeichert · geht nach deinem Ausbildungsende in die Prüfung';
    }
    final ab = eintrag.publishAfter;
    return ab == null
        ? 'Gespeichert · geht später in die Prüfung'
        : 'Gespeichert · geht am ${DateFormat('dd.MM.yyyy').format(ab)} '
            'in die Prüfung';
  }

  if (eintrag.istFreigegeben) {
    final seit = eintrag.publishedAt;
    return seit == null
        ? 'Veröffentlicht'
        : 'Veröffentlicht am ${DateFormat('dd.MM.yyyy').format(seit)}';
  }

  if (eintrag.istAbgelehnt) return 'Nicht veröffentlicht';

  return 'Abgeschickt am $datum · in Prüfung';
}
