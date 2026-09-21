import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/company_scores.dart';
import '../data/models/public_review.dart';
import '../data/models/review_draft.dart';
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
/// Zwei Quellen, weil es zwei Zustände gibt: ein Entwurf, an dem er noch
/// arbeitet, und eine abgeschickte Bewertung. Die abgeschickte ist ihm nicht
/// zugeordnet abrufbar — `public_reviews` trägt keine `user_id`, und genau das
/// ist der Sinn der Trennung. Was er wiederfindet, sind seine Entwürfe.
final myDraftsAndReviewsProvider =
    FutureProvider.family<List<ReviewDraft>, String>((ref, userId) {
  return ref.watch(reviewDraftRepositoryProvider).forUser(userId);
});

/// Die auf diesem Geraet abgeschickten Bewertungen.
///
/// Rein lokal — siehe [SubmittedReviewsLog] fuer den Grund und den Preis.
final submittedReviewsProvider = FutureProvider<List<SubmittedReview>>((ref) {
  return SubmittedReviewsLog().read();
});
