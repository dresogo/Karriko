import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/company_scores.dart';
import '../data/models/public_review.dart';
import '../data/models/review_draft.dart';
import '../data/models/own_review.dart';
import '../data/repositories/my_reviews_repository.dart';
import '../data/repositories/public_review_repository.dart';
import '../data/repositories/review_report_repository.dart';
import '../data/services/submitted_reviews_log.dart';
import 'questionnaire_provider.dart';

final publicReviewRepositoryProvider =
    Provider<PublicReviewRepository>((ref) => PublicReviewRepository());

final reviewReportRepositoryProvider =
    Provider<ReviewReportRepository>((ref) => ReviewReportRepository());

/// Die freigegebenen Bewertungen eines Betriebs.
final companyReviewsProvider =
    FutureProvider.family<List<PublicReview>, String>((ref, companyId) {
  return ref.watch(publicReviewRepositoryProvider).forCompany(companyId);
});

/// Die Aggregate eines Betriebs. `null`, solange es noch keine gibt.
final companyScoresProvider =
    FutureProvider.family<CompanyScores?, String>((ref, companyId) {
  return ref.watch(publicReviewRepositoryProvider).scoresFor(companyId);
});

final reviewByIdProvider =
    FutureProvider.family<PublicReview, String>((ref, id) {
  return ref.watch(publicReviewRepositoryProvider).byId(id);
});

final recentReviewsProvider = FutureProvider<List<PublicReview>>((ref) {
  return ref.watch(publicReviewRepositoryProvider).recent();
});

/// Was ein Azubi von seinen eigenen Bewertungen sieht.
///
/// Nur die Entwürfe. Die abgeschickten holt [ownReviewsProvider] über die
/// Function `my_reviews` — direkt abrufbar sind sie nicht, weil
/// `public_reviews` keine `user_id` trägt und kein Client auf `reviews`
/// zugreift.
final myDraftsAndReviewsProvider =
    FutureProvider.family<List<ReviewDraft>, String>((ref, userId) {
  return ref.watch(reviewDraftRepositoryProvider).forUser(userId);
});

/// Die auf diesem Geraet abgeschickten Bewertungen.
///
/// Rein lokal. Seit es `my_reviews` gibt, ist das nur noch der Rueckfall —
/// siehe [ownReviewsProvider].
final submittedReviewsProvider = FutureProvider<List<SubmittedReview>>((ref) {
  return SubmittedReviewsLog().read();
});

final myReviewsRepositoryProvider =
    Provider<MyReviewsRepository>((ref) => MyReviewsRepository());

/// Woher die Liste der eigenen Bewertungen kam.
///
/// Der Unterschied gehoert auf den Bildschirm: Die Liste vom Server ist
/// vollstaendig, die lokale kennt nur, was von diesem Geraet abgeschickt wurde.
/// Beides als dasselbe darzustellen waere eine Behauptung, die nicht stimmt.
class OwnReviewsResult {
  final List<OwnReview> reviews;

  /// `true` heisst: Der Server war nicht erreichbar, das hier kommt aus dem
  /// Browser und ist moeglicherweise unvollstaendig.
  final bool vomGeraet;

  const OwnReviewsResult({required this.reviews, this.vomGeraet = false});
}

/// Die eigenen abgeschickten Bewertungen.
///
/// Erst der Server ueber `my_reviews`, und nur wenn der nicht antwortet die
/// lokale Liste. Der Rueckfall ist nicht gleichwertig und wird auch nicht so
/// dargestellt — er kennt nur dieses Geraet und weiss nichts ueber den Stand
/// der Moderation.
final ownReviewsProvider = FutureProvider<OwnReviewsResult>((ref) async {
  try {
    final liste = await ref.watch(myReviewsRepositoryProvider).load();
    return OwnReviewsResult(reviews: liste);
  } on MyReviewsException {
    return OwnReviewsResult(reviews: await _vomGeraet(), vomGeraet: true);
  } catch (_) {
    return OwnReviewsResult(reviews: await _vomGeraet(), vomGeraet: true);
  }
});

/// Die lokale Liste in derselben Form, damit der Bildschirm nur einen Fall
/// kennen muss.
///
/// Was das Geraet nicht weiss, bleibt leer: Es kennt den Stand der Moderation
/// nicht, keine Freitexte und keinen Verweis auf die oeffentliche Zeile.
Future<List<OwnReview>> _vomGeraet() async {
  final lokal = await SubmittedReviewsLog().read();
  return [
    for (final eintrag in lokal)
      OwnReview(
        reviewId: eintrag.reviewId,
        companyId: eintrag.companyId,
        companyName: eintrag.companyName.isEmpty ? null : eintrag.companyName,
        status: eintrag.status,
        submittedAt: eintrag.submittedAt,
      ),
  ];
}
