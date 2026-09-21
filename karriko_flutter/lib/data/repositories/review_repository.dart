import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;
import '../../core/constants/appwrite_constants.dart';
import '../models/review_model.dart';
import '../services/appwrite_service.dart';

class ReviewRepository {
  TablesDB get _db => TablesDB(AppwriteService.client);

  Future<List<ReviewModel>> getReviewsForCompany(
    String companyId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.reviewsCollection,
      queries: [
        Query.equal('company_id', companyId),
        Query.equal('status', 'published'),
        Query.orderDesc('created_at'),
        Query.limit(limit),
        Query.offset(offset),
      ],
    );
    return result.rows.map((d) => ReviewModel.fromJson(_toMap(d))).toList();
  }

  Future<ReviewModel> getReviewById(String id) async {
    final doc = await _db.getRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.reviewsCollection,
      rowId: id,
    );
    return ReviewModel.fromJson(_toMap(doc));
  }

  Future<List<ReviewModel>> getMyReviews(String userId) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.reviewsCollection,
      queries: [
        Query.equal('author_id', userId),
        Query.orderDesc('created_at'),
        Query.limit(100),
      ],
    );
    return result.rows.map((d) => ReviewModel.fromJson(_toMap(d))).toList();
  }

  Future<void> deleteReview(String reviewId) async {
    await _db.deleteRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.reviewsCollection,
      rowId: reviewId,
    );
  }

  Future<ReviewModel> addBetriebReply({
    required String reviewId,
    required String reply,
  }) async {
    final doc = await _db.updateRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.reviewsCollection,
      rowId: reviewId,
      data: {
        'betrieb_reply': reply,
        'betrieb_replied_at': DateTime.now().toIso8601String(),
      },
    );
    return ReviewModel.fromJson(_toMap(doc));
  }

  Future<void> reportReview({
    required String reviewId,
    required String reporterId,
    required String reason,
  }) async {
    await _db.createRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.reviewReportsCollection,
      rowId: ID.unique(),
      data: {
        'review_id': reviewId,
        'reporter_id': reporterId,
        'reason': reason,
      },
      permissions: [
        Permission.read(Role.user(reporterId)),
      ],
    );
  }

  Future<List<ReviewModel>> getRecentReviews({int limit = 6}) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.reviewsCollection,
      queries: [
        Query.equal('status', 'published'),
        Query.orderDesc('created_at'),
        Query.limit(limit),
      ],
    );
    return result.rows.map((d) => ReviewModel.fromJson(_toMap(d))).toList();
  }

  Map<String, dynamic> _toMap(aw.Row doc) => {
        'id': doc.$id,
        'created_at': doc.$createdAt,
        ...doc.data,
      };
}
