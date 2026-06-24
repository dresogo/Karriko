import '../models/review_model.dart';
import '../services/supabase_service.dart';

class ReviewRepository {
  final _client = SupabaseService.client;

  Future<List<ReviewModel>> getReviewsForCompany(
    String companyId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('company_id', companyId)
        .eq('status', 'published')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ReviewModel> getReviewById(String id) async {
    final data = await _client.from('reviews').select().eq('id', id).single();
    return ReviewModel.fromJson(data);
  }

  Future<List<ReviewModel>> getMyReviews(String userId) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('author_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ReviewModel> createReview({
    required String companyId,
    required String authorId,
    required bool isAnonymous,
    required int overallRating,
    int? trainingQuality,
    int? mentoring,
    int? workLifeBalance,
    int? careerOpportunities,
    required String title,
    required String text,
    String? pros,
    String? cons,
    String? apprenticeshipYear,
    String? profession,
  }) async {
    final data = await _client
        .from('reviews')
        .insert({
          'company_id': companyId,
          'author_id': authorId,
          'is_anonymous': isAnonymous,
          'overall_rating': overallRating,
          if (trainingQuality != null) 'training_quality': trainingQuality,
          if (mentoring != null) 'mentoring': mentoring,
          if (workLifeBalance != null) 'work_life_balance': workLifeBalance,
          if (careerOpportunities != null) 'career_opportunities': careerOpportunities,
          'title': title,
          'text': text,
          if (pros != null) 'pros': pros,
          if (cons != null) 'cons': cons,
          if (apprenticeshipYear != null) 'apprenticeship_year': apprenticeshipYear,
          if (profession != null) 'profession': profession,
          'status': 'pending',
        })
        .select()
        .single();
    return ReviewModel.fromJson(data);
  }

  Future<void> deleteReview(String reviewId) async {
    await _client.from('reviews').delete().eq('id', reviewId);
  }

  Future<ReviewModel> addBetriebReply({
    required String reviewId,
    required String reply,
  }) async {
    final data = await _client
        .from('reviews')
        .update({
          'betrieb_reply': reply,
          'betrieb_replied_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reviewId)
        .select()
        .single();
    return ReviewModel.fromJson(data);
  }

  Future<void> reportReview({
    required String reviewId,
    required String reporterId,
    required String reason,
  }) async {
    await _client.from('review_reports').insert({
      'review_id': reviewId,
      'reporter_id': reporterId,
      'reason': reason,
    });
  }

  Future<List<ReviewModel>> getRecentReviews({int limit = 6}) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('status', 'published')
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
