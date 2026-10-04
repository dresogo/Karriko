import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;

import '../../core/constants/appwrite_constants.dart';
import '../../core/constants/questionnaire_constants.dart';
import '../models/review_draft.dart';
import '../services/appwrite_service.dart';

/// Speichert und laedt begonnene Bewertungen.
///
/// Der Entwurf gehoert dem Nutzer: Die Rechte werden pro Zeile gesetzt, und
/// zwar nur fuer ihn. Ein Moderator sieht keinen Entwurf, ein Betrieb erst
/// recht nicht — sichtbar wird eine Bewertung erst nach dem Absenden.
class ReviewDraftRepository {
  TablesDB get _db => TablesDB(AppwriteService.client);

  /// Der Entwurf dieses Nutzers zu diesem Betrieb, falls es einen gibt.
  Future<ReviewDraft?> find({
    required String userId,
    required String companyId,
  }) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.draftsCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    if (result.rows.isEmpty) return null;
    return ReviewDraft.fromJson(_toMap(result.rows.first));
  }

  /// Alle Entwuerfe eines Nutzers, fuer die Uebersicht „angefangen, nicht
  /// abgeschickt".
  Future<List<ReviewDraft>> forUser(String userId) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.draftsCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.orderDesc('updated_at'),
        Query.limit(50),
      ],
    );
    return result.rows.map((row) => ReviewDraft.fromJson(_toMap(row))).toList();
  }

  /// Legt an oder aktualisiert.
  ///
  /// Der eindeutige Index auf `user_id` + `company_id` setzt durch, dass es je
  /// Nutzer und Betrieb nur einen Entwurf gibt. Waeren es mehrere, wuerde beim
  /// Fortsetzen geraten, welcher gemeint ist.
  Future<ReviewDraft> save(ReviewDraft draft) async {
    final data = draft.toAppwrite();

    if (draft.id != null) {
      final row = await _db.updateRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: QuestionnaireConstants.draftsCollection,
        rowId: draft.id!,
        data: data,
      );
      return ReviewDraft.fromJson(_toMap(row));
    }

    final row = await _db.createRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.draftsCollection,
      rowId: ID.unique(),
      data: data,
      permissions: [
        Permission.read(Role.user(draft.userId)),
        Permission.update(Role.user(draft.userId)),
        Permission.delete(Role.user(draft.userId)),
      ],
    );
    return ReviewDraft.fromJson(_toMap(row));
  }

  /// Nach dem Absenden. Die Function loescht den Entwurf ebenfalls; hier ist es
  /// der schnellere Weg, damit die Liste der Entwuerfe sofort stimmt.
  Future<void> delete(String draftId) async {
    await _db.deleteRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.draftsCollection,
      rowId: draftId,
    );
  }

  Map<String, dynamic> _toMap(aw.Row row) => {
        'id': row.$id,
        'updated_at': row.$updatedAt,
        ...row.data,
      };
}
