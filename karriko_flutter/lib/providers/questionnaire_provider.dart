import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/review_draft.dart';
import '../data/repositories/questionnaire_repository.dart';
import '../data/repositories/review_draft_repository.dart';
import '../data/repositories/review_submit_repository.dart';
import '../data/repositories/verification_repository.dart';

final questionnaireRepositoryProvider =
    Provider<QuestionnaireRepository>((ref) => QuestionnaireRepository());

final reviewDraftRepositoryProvider =
    Provider<ReviewDraftRepository>((ref) => ReviewDraftRepository());

final reviewSubmitRepositoryProvider =
    Provider<ReviewSubmitRepository>((ref) => ReviewSubmitRepository());

final verificationRepositoryProvider =
    Provider<VerificationRepository>((ref) => VerificationRepository());

/// Die aktive Fragendefinition.
///
/// Bewusst kein `autoDispose`: Die Definition aendert sich waehrend einer
/// Sitzung nicht, und sie erneut zu laden — inklusive Netzzugriff — waere
/// Verschwendung.
final activeQuestionnaireProvider =
    FutureProvider<LoadedQuestionnaire>((ref) async {
  return ref.watch(questionnaireRepositoryProvider).loadActive();
});

/// Die Entwuerfe des angemeldeten Nutzers: angefangen, nicht abgeschickt.
final myDraftsProvider = FutureProvider.family<List<ReviewDraft>, String>(
  (ref, userId) => ref.watch(reviewDraftRepositoryProvider).forUser(userId),
);
