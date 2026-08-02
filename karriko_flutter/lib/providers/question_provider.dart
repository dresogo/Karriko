import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/question_model.dart';
import '../data/repositories/question_repository.dart';

final questionRepositoryProvider =
    Provider<QuestionRepository>((ref) => QuestionRepository());

/// Fragenkatalog aus der Datenbank, gruppiert nach Kategorie in der Reihenfolge
/// des Feldes `sort_order`.
final questionsProvider = FutureProvider<List<QuestionModel>>((ref) {
  return ref.watch(questionRepositoryProvider).fetchQuestions();
});
