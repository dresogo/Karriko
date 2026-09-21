import 'package:appwrite/appwrite.dart';

import '../../core/constants/appwrite_constants.dart';
import '../services/appwrite_service.dart';

/// Meldungen zu einer veröffentlichten Bewertung.
///
/// Das Einzige, was ein Client rund um eine fremde Bewertung schreiben darf.
/// Eine Meldung ist kein Urteil: Sie legt eine Zeile an, mehr passiert nicht.
/// Ob eine Bewertung verschwindet, entscheidet die Moderation — automatisches
/// Löschen trifft erfahrungsgemäß vor allem die ausführlichen, ehrlichen
/// Bewertungen.
class ReviewReportRepository {
  TablesDB get _db => TablesDB(AppwriteService.client);

  Future<void> report({
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
}
