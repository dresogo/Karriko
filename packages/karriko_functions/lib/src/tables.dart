import 'dart:convert';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' as aw;

import 'config.dart';

/// Zugriff auf die Tabellen, mit den Rechten der Function.
///
/// Dünn gehalten: Was hier steht, ist Appwrite-Kleber. Die Logik liegt in
/// `questionnaire_core` und in [buildReviewRow] — und ist damit ohne Appwrite
/// prüfbar.
class Tables {
  final Client client;
  final FunctionConfig config;

  Tables({required this.client, required this.config});

  TablesDB get db => TablesDB(client);

  // ── reviews ───────────────────────────────────────────────────────────────

  Future<aw.Row> createReview(Map<String, Object?> data) => db.createRow(
        databaseId: config.databaseId,
        tableId: config.reviewsTable,
        rowId: ID.unique(),
        data: data,
        // Bewusst leer: Es gelten die Tabellenrechte, und die sind leer. Kein
        // Client liest oder schreibt hier — auch der Verfasser nicht.
        permissions: const [],
      );

  Future<aw.Row> getReview(String id) => db.getRow(
        databaseId: config.databaseId,
        tableId: config.reviewsTable,
        rowId: id,
      );

  Future<aw.Row> updateReview(String id, Map<String, Object?> data) =>
      db.updateRow(
        databaseId: config.databaseId,
        tableId: config.reviewsTable,
        rowId: id,
        data: data,
      );

  /// Gibt es schon eine Bewertung dieses Nutzers zu diesem Betrieb?
  ///
  /// Der eindeutige Index auf `user_id` + `company_id` setzt das in der
  /// Datenbank durch; diese Abfrage sorgt dafür, dass der Azubi eine
  /// verständliche Meldung bekommt statt eines Indexfehlers.
  Future<aw.Row?> findReviewByUserAndCompany({
    required String userId,
    required String companyId,
  }) async {
    final result = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.reviewsTable,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    return result.rows.isEmpty ? null : result.rows.first;
  }

  /// Alle Bewertungen mit diesem Status, seitenweise.
  Stream<aw.Row> reviewsByStatus(String status, {int pageSize = 100}) => _pages(
        tableId: config.reviewsTable,
        queries: [Query.equal('status', status)],
        pageSize: pageSize,
      );

  /// Zurückgestellte Bewertungen, deren Frist abgelaufen ist.
  Stream<aw.Row> dueScheduledReviews(DateTime now, {int pageSize = 100}) =>
      _pages(
        tableId: config.reviewsTable,
        queries: [
          Query.equal('status', 'scheduled'),
          Query.lessThanEqual(
              publishAfterColumn, now.toUtc().toIso8601String()),
        ],
        pageSize: pageSize,
      );

  static const publishAfterColumn = 'publish_after';

  // ── public_reviews ────────────────────────────────────────────────────────

  Future<aw.Row> createPublicReview(Map<String, Object?> data) => db.createRow(
        databaseId: config.databaseId,
        tableId: config.publicReviewsTable,
        rowId: ID.unique(),
        data: data,
        // Oeffentlich lesbar, und zwar nur lesbar. Schreiben duerfen nur
        // Functions — deshalb steht hier kein Recht fuer irgendeinen Nutzer.
        permissions: const [],
      );

  Future<aw.Row?> findPublicReview(String reviewId) async {
    final result = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.publicReviewsTable,
      queries: [Query.equal('review_id', reviewId), Query.limit(1)],
    );
    return result.rows.isEmpty ? null : result.rows.first;
  }

  Future<void> deletePublicReview(String id) => db.deleteRow(
        databaseId: config.databaseId,
        tableId: config.publicReviewsTable,
        rowId: id,
      );

  Stream<aw.Row> publicReviewsForCompany(String companyId,
          {int pageSize = 100}) =>
      _pages(
        tableId: config.publicReviewsTable,
        queries: [Query.equal('company_id', companyId)],
        pageSize: pageSize,
      );

  Stream<aw.Row> allPublicReviews({int pageSize = 100}) =>
      _pages(tableId: config.publicReviewsTable, pageSize: pageSize);

  // ── companies ─────────────────────────────────────────────────────────────

  /// Name und Slug des Betriebs, für die öffentliche Zeile.
  ///
  /// `null`, wenn es den Betrieb nicht mehr gibt. Das ist kein Grund, eine
  /// Freigabe abzubrechen: Die Bewertung gilt weiter, nur die Verlinkung fehlt.
  Future<aw.Row?> getCompany(String id) async {
    try {
      return await db.getRow(
        databaseId: config.databaseId,
        tableId: config.companiesTable,
        rowId: id,
      );
    } catch (_) {
      return null;
    }
  }

  // ── company_scores ────────────────────────────────────────────────────────

  Future<aw.Row?> findCompanyScores(String companyId) async {
    final result = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.companyScoresTable,
      queries: [Query.equal('company_id', companyId), Query.limit(1)],
    );
    return result.rows.isEmpty ? null : result.rows.first;
  }

  /// Legt an oder aktualisiert.
  ///
  /// Idempotent, weil `aggregate_company` bei jeder Änderung an
  /// `public_reviews` läuft — auch zweimal für dieselbe Änderung, wenn Appwrite
  /// ein Ereignis wiederholt.
  Future<aw.Row> upsertCompanyScores(
    String companyId,
    Map<String, Object?> data,
  ) async {
    final vorhanden = await findCompanyScores(companyId);
    if (vorhanden != null) {
      return db.updateRow(
        databaseId: config.databaseId,
        tableId: config.companyScoresTable,
        rowId: vorhanden.$id,
        data: data,
      );
    }
    return db.createRow(
      databaseId: config.databaseId,
      tableId: config.companyScoresTable,
      rowId: ID.unique(),
      data: {'company_id': companyId, ...data},
      permissions: const [],
    );
  }

  // ── review_drafts ─────────────────────────────────────────────────────────

  Future<void> deleteDraft(String id) => db.deleteRow(
        databaseId: config.databaseId,
        tableId: config.draftsTable,
        rowId: id,
      );

  /// Entwürfe, die seit [grenze] nicht angefasst wurden.
  Stream<aw.Row> staleDrafts(DateTime grenze, {int pageSize = 100}) => _pages(
        tableId: config.draftsTable,
        queries: [
          Query.lessThan('updated_at', grenze.toUtc().toIso8601String()),
        ],
        pageSize: pageSize,
      );

  // ── moderation_log ────────────────────────────────────────────────────────

  Future<aw.Row> logModeration({
    required String reviewId,
    required String moderatorId,
    required String action,
    String? reason,
    List<String> flags = const [],
  }) =>
      db.createRow(
        databaseId: config.databaseId,
        tableId: config.moderationLogTable,
        rowId: ID.unique(),
        data: {
          'review_id': reviewId,
          'moderator_id': moderatorId,
          'action': action,
          if (reason != null) 'reason': reason,
          'flags': flags,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
        permissions: const [],
      );

  // ── Seitenweise lesen ─────────────────────────────────────────────────────

  /// Blättert über eine Tabelle, ohne alles in den Speicher zu holen.
  ///
  /// Über `offset` und nicht über einen Cursor: Die hier durchlaufenen Tabellen
  /// ändern sich während eines Laufs nicht — `recompute_all` und `cleanup`
  /// arbeiten auf einem Stand, den niemand gleichzeitig umschreibt. Ein Cursor
  /// wäre bei laufenden Änderungen richtiger und hier nur Aufwand.
  Stream<aw.Row> _pages({
    required String tableId,
    List<String> queries = const [],
    int pageSize = 100,
  }) async* {
    var offset = 0;
    while (true) {
      final seite = await db.listRows(
        databaseId: config.databaseId,
        tableId: tableId,
        queries: [
          ...queries,
          Query.limit(pageSize),
          Query.offset(offset),
        ],
      );
      if (seite.rows.isEmpty) return;
      for (final row in seite.rows) {
        yield row;
      }
      if (seite.rows.length < pageSize) return;
      offset += pageSize;
    }
  }

  // ── Storage ───────────────────────────────────────────────────────────────

  Future<void> deleteVerificationFile(String fileId) =>
      Storage(client).deleteFile(
        bucketId: config.verificationBucket,
        fileId: fileId,
      );
}

/// Liest eine JSON-Spalte. Ein kaputter Wert ergibt eine leere Zuordnung —
/// eine einzelne unlesbare Zeile soll einen Stapellauf nicht anhalten.
Map<String, Object?> decodeJsonColumn(Object? roh) {
  if (roh is! String || roh.isEmpty) return const {};
  try {
    final decoded = jsonDecode(roh);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } on FormatException {
    return const {};
  }
  return const {};
}
