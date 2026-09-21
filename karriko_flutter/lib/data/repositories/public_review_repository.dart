import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;

import '../../core/constants/appwrite_constants.dart';
import '../../core/constants/questionnaire_constants.dart';
import '../models/company_scores.dart';
import '../models/public_review.dart';
import '../services/appwrite_service.dart';

/// Liest, was öffentlich ist: freigegebene Einzelbewertungen und die
/// Aggregate je Betrieb.
///
/// Beides kommt aus eigenen Tabellen, die nur Functions beschreiben. Der
/// Client liest hier und rechnet nichts nach — er käme an die Grundlage gar
/// nicht heran, und ein zweiter Rechenweg wäre ein zweites Ergebnis.
class PublicReviewRepository {
  TablesDB get _db => TablesDB(AppwriteService.client);

  Future<List<PublicReview>> forCompany(
    String companyId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.publicReviewsCollection,
      queries: [
        Query.equal('company_id', companyId),
        Query.orderDesc('published_at'),
        Query.limit(limit),
        Query.offset(offset),
      ],
    );
    return result.rows.map((row) => PublicReview.fromJson(_toMap(row))).toList();
  }

  Future<PublicReview> byId(String id) async {
    final row = await _db.getRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.publicReviewsCollection,
      rowId: id,
    );
    return PublicReview.fromJson(_toMap(row));
  }

  Future<List<PublicReview>> recent({int limit = 6}) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.publicReviewsCollection,
      queries: [
        Query.orderDesc('published_at'),
        Query.limit(limit),
      ],
    );
    return result.rows.map((row) => PublicReview.fromJson(_toMap(row))).toList();
  }

  /// Die Aggregate eines Betriebs. `null`, solange es noch keine gibt.
  ///
  /// Kein Fehlerfall: Ein Betrieb ohne Bewertung hat keine Aggregate, und das
  /// ist der Normalzustand für jeden neuen Eintrag.
  Future<CompanyScores?> scoresFor(String companyId) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.companyScoresCollection,
      queries: [
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    if (result.rows.isEmpty) return null;
    return CompanyScores.fromJson(_toMap(result.rows.first));
  }

  Map<String, dynamic> _toMap(aw.Row row) => {
        'id': row.$id,
        'published_at': row.$createdAt,
        'updated_at': row.$updatedAt,
        ...row.data,
      };
}
