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

class NewReviewState {
  final int step;
  final String? companyId;
  final String? companyName;
  final bool isAnonymous;
  final int overallRating;
  final int? trainingQuality;
  final int? mentoring;
  final int? workLifeBalance;
  final int? careerOpportunities;
  final String title;
  final String text;
  final String? pros;
  final String? cons;
  final String? profession;
  final bool isSubmitting;
  final String? error;
  final bool submitted;

  const NewReviewState({
    this.step = 0,
    this.companyId,
    this.companyName,
    this.isAnonymous = true,
    this.overallRating = 0,
    this.trainingQuality,
    this.mentoring,
    this.workLifeBalance,
    this.careerOpportunities,
    this.title = '',
    this.text = '',
    this.pros,
    this.cons,
    this.profession,
    this.isSubmitting = false,
    this.error,
    this.submitted = false,
  });

  NewReviewState copyWith({
    int? step,
    String? companyId,
    String? companyName,
    bool? isAnonymous,
    int? overallRating,
    int? trainingQuality,
    int? mentoring,
    int? workLifeBalance,
    int? careerOpportunities,
    String? title,
    String? text,
    String? pros,
    String? cons,
    String? profession,
    bool? isSubmitting,
    String? error,
    bool? submitted,
    bool clearError = false,
  }) {
    return NewReviewState(
      step: step ?? this.step,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      overallRating: overallRating ?? this.overallRating,
      trainingQuality: trainingQuality ?? this.trainingQuality,
      mentoring: mentoring ?? this.mentoring,
      workLifeBalance: workLifeBalance ?? this.workLifeBalance,
      careerOpportunities: careerOpportunities ?? this.careerOpportunities,
      title: title ?? this.title,
      text: text ?? this.text,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      profession: profession ?? this.profession,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      submitted: submitted ?? this.submitted,
    );
  }
}

class NewReviewNotifier extends StateNotifier<NewReviewState> {
  final ReviewRepository _repo;

  NewReviewNotifier(this._repo) : super(const NewReviewState());

  void goToStep(int step) => state = state.copyWith(step: step);
  void nextStep() => state = state.copyWith(step: state.step + 1);
  void prevStep() => state = state.copyWith(step: state.step - 1);

  void setCompany(String id, String name) =>
      state = state.copyWith(companyId: id, companyName: name);

  void setRatings({
    required int overall,
    int? training,
    int? mentoring,
    int? workLife,
    int? career,
  }) {
    state = state.copyWith(
      overallRating: overall,
      trainingQuality: training,
      mentoring: mentoring,
      workLifeBalance: workLife,
      careerOpportunities: career,
    );
  }

  void setDetails({
    required String title,
    required String text,
    String? pros,
    String? cons,
    String? profession,
    bool? isAnonymous,
  }) {
    state = state.copyWith(
      title: title,
      text: text,
      pros: pros,
      cons: cons,
      profession: profession,
      isAnonymous: isAnonymous,
    );
  }

  Future<void> submit(String authorId) async {
    if (state.companyId == null) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.createReview(
        companyId: state.companyId!,
        authorId: authorId,
        isAnonymous: state.isAnonymous,
        overallRating: state.overallRating,
        trainingQuality: state.trainingQuality,
        mentoring: state.mentoring,
        workLifeBalance: state.workLifeBalance,
        careerOpportunities: state.careerOpportunities,
        title: state.title,
        text: state.text,
        pros: state.pros,
        cons: state.cons,
        profession: state.profession,
      );
      state = state.copyWith(isSubmitting: false, submitted: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Bewertung konnte nicht gespeichert werden.',
      );
    }
  }

  void reset() => state = const NewReviewState();
}

final newReviewProvider =
    StateNotifierProvider<NewReviewNotifier, NewReviewState>((ref) {
  return NewReviewNotifier(ref.watch(reviewRepositoryProvider));
});
