import 'dart:convert';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' as aw;

import 'config.dart';
import 'moderation_desk.dart';

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

  /// Wie viele Bewertungen der Nutzer seit [since] abgegeben hat.
  ///
  /// Liest eine Zeile und nimmt die Gesamtzahl aus der Antwort, wie
  /// [countReviews]. Der Index auf `user_id` + `company_id` bedient den Filter
  /// über seine erste Spalte; `$createdAt` grenzt danach eine kleine Menge ein.
  Future<int> countReviewsByUserSince(String userId, DateTime since) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.reviewsTable,
      queries: [
        Query.equal('user_id', userId),
        Query.greaterThanEqual(r'$createdAt', since.toUtc().toIso8601String()),
        Query.select([r'$id']),
        Query.limit(1),
      ],
      total: true,
    );
    return ergebnis.total;
  }

  /// Die Bewertungen eines Nutzers.
  ///
  /// Keine Sortierung in der Abfrage: Ein `orderDesc` auf `$createdAt` würde
  /// einen eigenen Index verlangen, und die Menge ist klein genug, um sie beim
  /// Aufrufer zu sortieren — je Nutzer und Betrieb gibt es höchstens eine
  /// Bewertung. Der eindeutige Index auf `user_id` + `company_id` bedient die
  /// Suche über seine erste Spalte.
  Future<List<aw.Row>> reviewsByUser(String userId, {int limit = 100}) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.reviewsTable,
      queries: [Query.equal('user_id', userId), Query.limit(limit)],
    );
    return ergebnis.rows;
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

  /// Die öffentlichen Zeilen zu mehreren Bewertungen, in **einer** Abfrage.
  ///
  /// `Query.equal` mit einer Liste heißt „einer davon". Ohne das wäre es eine
  /// Abfrage je Bewertung — bei einer Übersichtsseite also eine Abfrage je
  /// Zeile, und das summiert sich.
  Future<Map<String, aw.Row>> publicReviewsByIds(List<String> reviewIds) async {
    if (reviewIds.isEmpty) return const {};
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.publicReviewsTable,
      queries: [
        Query.equal('review_id', reviewIds),
        Query.limit(reviewIds.length),
      ],
    );
    return {
      for (final zeile in ergebnis.rows)
        if (zeile.data['review_id'] case final String id) id: zeile,
    };
  }

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

  /// Spiegelt den Gesamtscore nach `companies`.
  ///
  /// Doppelt gehalten, und das aus einem einzigen Grund: Die Suche sortiert und
  /// filtert nach der Bewertung, und Appwrite kann nicht über zwei Tabellen
  /// hinweg sortieren. Der **angezeigte** Score kommt immer aus
  /// `company_scores`; dies hier ist eine Kopie für die Abfrage.
  ///
  /// Scheitert sie, ist das kein Grund, die Aggregation abzubrechen: Der
  /// verbindliche Wert steht dann schon. Nur die Sortierung ist veraltet.
  Future<void> mirrorRatingToCompany(
    String companyId, {
    required double? averageRating,
    required int reviewCount,
  }) =>
      db.updateRow(
        databaseId: config.databaseId,
        tableId: config.companiesTable,
        rowId: companyId,
        data: {
          'average_rating': averageRating,
          'review_count': reviewCount,
        },
      );

  /// Name und Slug mehrerer Betriebe, in einer Abfrage.
  Future<Map<String, aw.Row>> companiesByIds(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.companiesTable,
      queries: [Query.equal(r'$id', ids), Query.limit(ids.length)],
    );
    return {for (final zeile in ergebnis.rows) zeile.$id: zeile};
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

  /// Die Begründung der jüngsten Ablehnung je Bewertung.
  ///
  /// Nur `reason`, und nur von Ablehnungen. **Nicht `moderator_id`**: Wer
  /// abgelehnt hat, bleibt dem Verfasser gegenüber ungenannt — die Begründung
  /// gehört ihm, der Name nicht. Auch nicht `flags`, aus demselben Grund, aus
  /// dem die Qualitätsmarkierungen nicht an den Verfasser gehen.
  Future<Map<String, String>> rejectionReasons(List<String> reviewIds) async {
    if (reviewIds.isEmpty) return const {};

    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.moderationLogTable,
      queries: [
        Query.equal('review_id', reviewIds),
        Query.equal('action', 'reject'),
        Query.limit(100),
      ],
    );

    // Die jüngste gewinnt: Eine Bewertung kann abgelehnt, überarbeitet und
    // wieder abgelehnt worden sein.
    final neueste = <String, String>{};
    final zeitpunkt = <String, String>{};
    for (final zeile in ergebnis.rows) {
      final id = zeile.data['review_id'];
      final grund = zeile.data['reason'];
      if (id is! String || grund is! String) continue;
      final wann = zeile.data['created_at'] as String? ?? zeile.$createdAt;
      final bisher = zeitpunkt[id];
      if (bisher == null || wann.compareTo(bisher) > 0) {
        neueste[id] = grund;
        zeitpunkt[id] = wann;
      }
    }
    return neueste;
  }

  /// Die jüngsten Einträge des Protokolls.
  Future<List<aw.Row>> recentModerationLog({int limit = 100}) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.moderationLogTable,
      queries: [Query.orderDesc(r'$createdAt'), Query.limit(limit)],
    );
    return ergebnis.rows;
  }

  // ── Moderationstisch ──────────────────────────────────────────────────────

  /// Wie viele Bewertungen diesen Status haben. Liest eine Zeile und nimmt
  /// die Gesamtzahl aus der Antwort.
  Future<int> countReviews(String status) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.reviewsTable,
      queries: [
        Query.equal('status', status),
        Query.select([r'$id']),
        Query.limit(1),
      ],
      total: true,
    );
    return ergebnis.total;
  }

  /// Die Bewertungen mit diesem Status, höchstens [limit].
  Future<List<aw.Row>> reviewsWithStatus(String status,
      {int limit = 100}) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.reviewsTable,
      queries: [Query.equal('status', status), Query.limit(limit)],
    );
    return ergebnis.rows;
  }

  /// Mehrere interne Bewertungen in einer Abfrage.
  Future<Map<String, aw.Row>> reviewsByIds(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.reviewsTable,
      queries: [Query.equal(r'$id', ids), Query.limit(ids.length)],
    );
    return {for (final zeile in ergebnis.rows) zeile.$id: zeile};
  }

  /// Öffentliche Zeilen über ihre **eigene** Kennung.
  ///
  /// Eine Meldung entsteht auf der öffentlichen Seite und kann deshalb deren
  /// Kennung tragen statt der internen. Beide Wege werden versucht.
  Future<Map<String, aw.Row>> publicReviewsByRowIds(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.publicReviewsTable,
      queries: [Query.equal(r'$id', ids), Query.limit(ids.length)],
    );
    return {for (final zeile in ergebnis.rows) zeile.$id: zeile};
  }

  /// Offene Meldungen: Status `open` oder — bei Zeilen von vor der Spalte —
  /// gar keiner.
  String get _nurOffene => Query.or([
        Query.isNull('status'),
        Query.equal('status', ReportStatus.open),
      ]);

  Future<int> countOpenReports() async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.reviewReportsTable,
      queries: [
        _nurOffene,
        Query.select([r'$id']),
        Query.limit(1)
      ],
      total: true,
    );
    return ergebnis.total;
  }

  /// Meldungen, neueste zuerst. [nurOffene] beschränkt auf unerledigte.
  Future<List<aw.Row>> reports(
      {required bool nurOffene, int limit = 100}) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.reviewReportsTable,
      queries: [
        if (nurOffene) _nurOffene,
        Query.orderDesc(r'$createdAt'),
        Query.limit(limit),
      ],
    );
    return ergebnis.rows;
  }

  /// Wie oft jede dieser Bewertungen gemeldet wurde (offene Meldungen).
  Future<Map<String, int>> openReportCounts(List<String> reviewIds) async {
    if (reviewIds.isEmpty) return const {};
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.reviewReportsTable,
      queries: [
        Query.equal('review_id', reviewIds),
        _nurOffene,
        Query.limit(500),
      ],
    );
    final zaehler = <String, int>{};
    for (final zeile in ergebnis.rows) {
      final id = zeile.data['review_id'];
      if (id is String) zaehler[id] = (zaehler[id] ?? 0) + 1;
    }
    return zaehler;
  }

  Future<aw.Row> getReport(String id) => db.getRow(
        databaseId: config.databaseId,
        tableId: config.reviewReportsTable,
        rowId: id,
      );

  Future<aw.Row> resolveReport(
    String id, {
    required String status,
    required String resolvedBy,
    String? note,
  }) =>
      db.updateRow(
        databaseId: config.databaseId,
        tableId: config.reviewReportsTable,
        rowId: id,
        data: {
          'status': status,
          'resolved_by': resolvedBy,
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
          if (note != null && note.trim().isNotEmpty)
            'resolution_note': note.trim(),
        },
      );

  /// Betriebe für die Verwaltungsliste, optional nach Name gefiltert.
  Future<List<aw.Row>> companies({String? suche, int limit = 100}) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.companiesTable,
      queries: [
        if (suche != null && suche.trim().isNotEmpty)
          Query.contains('name', [suche.trim()]),
        Query.orderAsc('name'),
        Query.limit(limit),
      ],
    );
    return ergebnis.rows;
  }

  Future<int> countCompanies({bool? verified}) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.companiesTable,
      queries: [
        if (verified != null) Query.equal('is_verified', verified),
        Query.select([r'$id']),
        Query.limit(1),
      ],
      total: true,
    );
    return ergebnis.total;
  }

  /// Die Firma, die einem Konto gehört, oder `null`.
  Future<aw.Row?> companyByOwner(String ownerId) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.companiesTable,
      queries: [Query.equal('owner_id', ownerId), Query.limit(1)],
    );
    return ergebnis.rows.isEmpty ? null : ergebnis.rows.first;
  }

  Future<bool> companySlugTaken(String slug) async {
    final ergebnis = await db.listRows(
      databaseId: config.databaseId,
      tableId: config.companiesTable,
      queries: [
        Query.equal('slug', slug),
        Query.select([r'$id']),
        Query.limit(1),
      ],
    );
    return ergebnis.rows.isNotEmpty;
  }

  /// Legt eine Firma an. Lesbar für alle, **kein** Änderungsrecht für den
  /// Eigentümer: Geändert wird nur über `company_profile` (T-4.2). Auch kein
  /// Löschrecht, ein Betriebsprofil wird beim Löschen des Kontos nur inaktiv
  /// (Referenz §3.4).
  Future<aw.Row> createCompany(Map<String, Object?> data) => db.createRow(
        databaseId: config.databaseId,
        tableId: config.companiesTable,
        rowId: ID.unique(),
        data: data,
        permissions: [Permission.read(Role.any())],
      );

  /// Ändert eine Firma und setzt dabei die Zeilenrechte neu. Ältere Zeilen
  /// tragen noch `update("user:…")` aus der Zeit, als der Client selbst
  /// schrieb; das fällt mit der ersten Änderung weg.
  Future<aw.Row> updateCompany(String companyId, Map<String, Object?> data) =>
      db.updateRow(
        databaseId: config.databaseId,
        tableId: config.companiesTable,
        rowId: companyId,
        data: data,
        permissions: [Permission.read(Role.any())],
      );

  // ── jobs ──────────────────────────────────────────────────────────────────

  /// Eine Stelle, oder `null`, wenn es sie nicht gibt.
  Future<aw.Row?> getJob(String id) async {
    try {
      return await db.getRow(
        databaseId: config.databaseId,
        tableId: config.jobsTable,
        rowId: id,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      rethrow;
    }
  }

  /// Zeilenrechte einer Stelle: Eine veröffentlichte lesen alle, einen
  /// Entwurf nur der Eigentümer. Kein Ändern- und Löschrecht, das geht nur
  /// über `job_posting` (T-4.31).
  List<String> _jobRechte({required bool isActive, required String ownerId}) =>
      [Permission.read(isActive ? Role.any() : Role.user(ownerId))];

  Future<aw.Row> createJob(
    Map<String, Object?> data, {
    required String ownerId,
  }) =>
      db.createRow(
        databaseId: config.databaseId,
        tableId: config.jobsTable,
        rowId: ID.unique(),
        data: data,
        permissions:
            _jobRechte(isActive: data['is_active'] == true, ownerId: ownerId),
      );

  Future<aw.Row> updateJob(
    String id,
    Map<String, Object?> data, {
    required bool isActive,
    required String ownerId,
  }) =>
      db.updateRow(
        databaseId: config.databaseId,
        tableId: config.jobsTable,
        rowId: id,
        data: data,
        permissions: _jobRechte(isActive: isActive, ownerId: ownerId),
      );

  Future<void> deleteJob(String id) => db.deleteRow(
        databaseId: config.databaseId,
        tableId: config.jobsTable,
        rowId: id,
      );

  Future<aw.Row> setCompanyVerified(String companyId, bool verified) =>
      db.updateRow(
        databaseId: config.databaseId,
        tableId: config.companiesTable,
        rowId: companyId,
        data: {'is_verified': verified},
      );

  // ── Daten eines Kontos (T-2.8, T-2.9, T-2.10) ──────────────────────────────

  /// Alle Zeilen einer Tabelle mit `spalte == wert`, seitenweise gelesen.
  Future<List<aw.Row>> _alleMit(String tableId, String spalte, String wert) =>
      _pages(tableId: tableId, queries: [Query.equal(spalte, wert)]).toList();

  Future<List<aw.Row>> allReviewsByUser(String userId) =>
      _alleMit(config.reviewsTable, 'user_id', userId);

  Future<List<aw.Row>> draftsByUser(String userId) =>
      _alleMit(config.draftsTable, 'user_id', userId);

  Future<List<aw.Row>> bookmarksByUser(String userId) =>
      _alleMit(config.bookmarksTable, 'user_id', userId);

  Future<List<aw.Row>> reportsByReporter(String userId) =>
      _alleMit(config.reviewReportsTable, 'reporter_id', userId);

  Future<List<aw.Row>> reportsForReview(String reviewId) =>
      _alleMit(config.reviewReportsTable, 'review_id', reviewId);

  Future<void> deleteRow(String tableId, String id) => db.deleteRow(
        databaseId: config.databaseId,
        tableId: tableId,
        rowId: id,
      );

  Future<aw.Row> updateRowData(
          String tableId, String id, Map<String, Object?> data) =>
      db.updateRow(
        databaseId: config.databaseId,
        tableId: tableId,
        rowId: id,
        data: data,
      );

  /// Die Profilzeile, oder `null`.
  Future<aw.Row?> getProfile(String userId) async {
    try {
      return await db.getRow(
        databaseId: config.databaseId,
        tableId: config.profilesTable,
        rowId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      rethrow;
    }
  }

  /// Der Löschantrag eines Kontos, oder `null`. Die Zeilenkennung ist die
  /// Nutzerkennung, damit es je Konto höchstens einen gibt.
  Future<aw.Row?> getDeletionRequest(String userId) async {
    try {
      return await db.getRow(
        databaseId: config.databaseId,
        tableId: config.accountDeletionsTable,
        rowId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      rethrow;
    }
  }

  Future<aw.Row> createDeletionRequest({
    required String userId,
    required DateTime requestedAt,
    required DateTime deleteAfter,
  }) =>
      db.createRow(
        databaseId: config.databaseId,
        tableId: config.accountDeletionsTable,
        rowId: userId,
        data: {
          'user_id': userId,
          'requested_at': requestedAt.toUtc().toIso8601String(),
          'delete_after': deleteAfter.toUtc().toIso8601String(),
        },
        permissions: const [],
      );

  /// Löschanträge, deren Frist abgelaufen ist.
  Future<List<aw.Row>> dueDeletionRequests(DateTime now) => _pages(
        tableId: config.accountDeletionsTable,
        queries: [
          Query.lessThanEqual('delete_after', now.toUtc().toIso8601String()),
        ],
      ).toList();

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
