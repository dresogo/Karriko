import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw_enums;
import 'package:appwrite/models.dart' as aw;
import '../../core/constants/appwrite_constants.dart';
import '../../core/constants/questionnaire_constants.dart';
import '../models/company_model.dart';
import '../services/appwrite_service.dart';

class CompanyRepository {
  /// [db] ersetzt in Tests den Zugriff auf Appwrite. Ohne ihn entsteht er
  /// erst beim Aufruf, weil der Client beim Bau des Providers noch nicht
  /// initialisiert sein muss.
  CompanyRepository({TablesDB? db, Functions? functions})
      : _dbOverride = db,
        _functionsOverride = functions;

  final TablesDB? _dbOverride;
  final Functions? _functionsOverride;

  TablesDB get _db => _dbOverride ?? TablesDB(AppwriteService.client);
  Functions get _functions =>
      _functionsOverride ?? Functions(AppwriteService.client);

  Future<List<CompanyModel>> searchCompanies({
    String? query,
    String? industry,
    String? city,
    double? minRating,
    int limit = 20,
    int offset = 0,
  }) async {
    final queries = <String>[
      Query.orderDesc('average_rating'),
      Query.limit(limit),
      Query.offset(offset),
    ];
    if (query != null && query.isNotEmpty) {
      queries.add(Query.search('name', query));
    }
    if (industry != null && industry != 'Alle Branchen') {
      queries.add(Query.equal('industry', industry));
    }
    if (city != null && city.isNotEmpty) {
      queries.add(Query.search('city', city));
    }
    if (minRating != null) {
      queries.add(Query.greaterThanEqual('average_rating', minRating));
    }

    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesTable,
      queries: queries,
    );
    return result.rows.map((d) => CompanyModel.fromJson(_toMap(d))).toList();
  }

  Future<CompanyModel> getCompanyBySlug(String slug) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesTable,
      queries: [Query.equal('slug', slug), Query.limit(1)],
    );
    if (result.rows.isEmpty) throw Exception('Unternehmen nicht gefunden');
    return CompanyModel.fromJson(_toMap(result.rows.first));
  }

  Future<CompanyModel> getCompanyById(String id) async {
    final doc = await _db.getRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesTable,
      rowId: id,
    );
    return CompanyModel.fromJson(_toMap(doc));
  }

  Future<List<CompanyModel>> getFeaturedCompanies({int limit = 6}) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesTable,
      queries: [
        Query.equal('is_premium', true),
        Query.orderDesc('average_rating'),
        Query.limit(limit),
      ],
    );
    return result.rows.map((d) => CompanyModel.fromJson(_toMap(d))).toList();
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesTable,
      queries: [Query.search('name', query), Query.limit(5)],
    );
    return result.rows.map((d) => d.data['name'] as String).toList();
  }

  /// Sucht das Unternehmen, das einem Konto gehoert.
  ///
  /// Gegenstueck zur Verknuepfung im Profil: Faellt die dort aus – etwa weil
  /// das Konto vor deren Einfuehrung entstand –, laesst sich das Unternehmen
  /// hierueber wiederfinden, statt ein zweites anzulegen.
  Future<CompanyModel?> findCompanyByOwner(String ownerId) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesTable,
      queries: [Query.equal('owner_id', ownerId), Query.limit(1)],
    );
    if (result.rows.isEmpty) return null;
    return CompanyModel.fromJson(_toMap(result.rows.first));
  }

  /// Legt das Unternehmen des angemeldeten Betriebskontos an.
  ///
  /// Ueber die Function `company_profile`, nicht direkt in die Tabelle
  /// (T-4.2): Appwrite kennt keine Rechte je Spalte, und wer direkt anlegt,
  /// koennte `is_verified`, `is_premium`, `average_rating` oder `owner_id`
  /// gleich mitsetzen. Eigentuemer ist immer der Aufrufer, die Function nimmt
  /// ihn aus dem JWT. Gibt es schon eine Firma zu diesem Konto, kommt diese
  /// zurueck statt einer zweiten. Slug, Rechte an der Zeile und die gesperrten
  /// Felder setzt der Server; die Zeile ist fuer alle lesbar, aenderbar nur
  /// ueber die Function und nicht loeschbar (Referenz §3.4).
  Future<CompanyModel> createCompany({
    required String name,
    String? industry,
    String? city,
  }) =>
      _companyProfile('create', {
        'name': name,
        if (industry != null) 'industry': industry,
        if (city != null) 'city': city,
      });

  /// Aendert die Stammdaten des eigenen Unternehmens, ueber `company_profile`.
  ///
  /// Welche Firma, entscheidet der Server: die des angemeldeten Kontos. Nur
  /// uebergebene Felder werden geaendert, ein leerer Text leert das Feld. Der
  /// Slug bleibt **unberuehrt**, auch wenn sich der Name aendert: Er steht in
  /// der oeffentlichen Adresse, und geteilte Links sollen nicht brechen.
  ///
  /// Wirft [CompanyProfileException] mit einer Meldung fuer den Nutzer, etwa
  /// wenn die Website nicht mit http:// oder https:// beginnt.
  Future<CompanyModel> updateCompanyProfile({
    String? name,
    String? description,
    String? website,
    String? logoUrl,
    String? city,
    String? country,
    String? industry,
  }) =>
      _companyProfile('update', {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (website != null) 'website': website,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (industry != null) 'industry': industry,
      });

  Future<CompanyModel> _companyProfile(
    String action,
    Map<String, String> fields,
  ) async {
    final execution = await _functions.createExecution(
      functionId: QuestionnaireConstants.companyProfileFunction,
      body: jsonEncode({'action': action, 'fields': fields}),
      xasync: false,
      method: aw_enums.ExecutionMethod.pOST,
      path: '/',
    );

    Map<String, Object?> antwort = const {};
    try {
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is Map) antwort = decoded.cast<String, Object?>();
    } on FormatException {
      // bleibt leer, unten als Fehler behandelt
    }

    final firma = antwort['company'];
    if (execution.responseStatusCode >= 400 ||
        antwort['ok'] != true ||
        firma is! Map) {
      throw CompanyProfileException(
        antwort['message'] as String? ??
            'Das Unternehmensprofil konnte nicht gespeichert werden.',
      );
    }
    return CompanyModel.fromJson(firma.cast<String, dynamic>());
  }

  Future<void> bookmarkCompany(String userId, String companyId) async {
    final existing = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksTable,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    if (existing.rows.isNotEmpty) return;
    await _db.createRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksTable,
      rowId: ID.unique(),
      data: {'user_id': userId, 'company_id': companyId},
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<void> removeBookmark(String userId, String companyId) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksTable,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    if (result.rows.isEmpty) return;
    await _db.deleteRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksTable,
      rowId: result.rows.first.$id,
    );
  }

  /// Gemerkte Unternehmen eines Kontos.
  ///
  /// Ein Eintrag, dessen Unternehmen es nicht mehr gibt, fällt weg, statt die
  /// ganze Merkliste mit einem Fehler zu belegen. Andere Fehler (etwa keine
  /// Verbindung) gehen weiter nach oben.
  Future<List<CompanyModel>> getBookmarkedCompanies(String userId) async {
    final bookmarks = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksTable,
      queries: [Query.equal('user_id', userId), Query.limit(100)],
    );
    final companies = await Future.wait(
      bookmarks.rows.map((b) async {
        try {
          return await getCompanyById(b.data['company_id'] as String);
        } on AppwriteException catch (e) {
          if (e.code == 404) return null;
          rethrow;
        }
      }),
    );
    return companies.whereType<CompanyModel>().toList();
  }

  Map<String, dynamic> _toMap(aw.Row doc) => {
        'id': doc.$id,
        'created_at': doc.$createdAt,
        ...doc.data,
      };
}

/// Die Function `company_profile` hat abgelehnt oder ist nicht erreichbar.
/// [message] richtet sich an den Nutzer.
class CompanyProfileException implements Exception {
  const CompanyProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
