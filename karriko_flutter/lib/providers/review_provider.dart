import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/review_model.dart';
import '../data/repositories/review_repository.dart';

final reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) => ReviewRepository());

final companyReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, companyId) {
  return ref.watch(reviewRepositoryProvider).getReviewsForCompany(companyId);
});

final reviewByIdProvider =
    FutureProvider.family<ReviewModel, String>((ref, id) {
  return ref.watch(reviewRepositoryProvider).getReviewById(id);
});

final myReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, userId) {
  return ref.watch(reviewRepositoryProvider).getMyReviews(userId);
});

final recentReviewsProvider = FutureProvider<List<ReviewModel>>((ref) {
  return ref.watch(reviewRepositoryProvider).getRecentReviews();
});
