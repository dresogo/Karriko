import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;
import '../../core/constants/appwrite_constants.dart';
import '../models/company_model.dart';
import '../services/appwrite_service.dart';

class CompanyRepository {
  TablesDB get _db => TablesDB(AppwriteService.client);

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
      tableId: AppwriteConstants.companiesCollection,
      queries: queries,
    );
    return result.rows.map((d) => CompanyModel.fromJson(_toMap(d))).toList();
  }

  Future<CompanyModel> getCompanyBySlug(String slug) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      queries: [Query.equal('slug', slug), Query.limit(1)],
    );
    if (result.rows.isEmpty) throw Exception('Unternehmen nicht gefunden');
    return CompanyModel.fromJson(_toMap(result.rows.first));
  }

  Future<CompanyModel> getCompanyById(String id) async {
    final doc = await _db.getRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      rowId: id,
    );
    return CompanyModel.fromJson(_toMap(doc));
  }

  Future<List<CompanyModel>> getFeaturedCompanies({int limit = 6}) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
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
      tableId: AppwriteConstants.companiesCollection,
      queries: [Query.search('name', query), Query.limit(5)],
    );
    return result.rows.map((d) => d.data['name'] as String).toList();
  }

  Future<CompanyModel> updateCompanyProfile({
    required String companyId,
    String? name,
    String? description,
    String? website,
    String? logoUrl,
    String? city,
    String? country,
    String? industry,
  }) async {
    await _db.updateRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      rowId: companyId,
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (website != null) 'website': website,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (industry != null) 'industry': industry,
      },
    );
    return getCompanyById(companyId);
  }

  Future<void> bookmarkCompany(String userId, String companyId) async {
    final existing = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    if (existing.rows.isNotEmpty) return;
    await _db.createRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
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
      tableId: AppwriteConstants.bookmarksCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    if (result.rows.isEmpty) return;
    await _db.deleteRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      rowId: result.rows.first.$id,
    );
  }

  Future<List<CompanyModel>> getBookmarkedCompanies(String userId) async {
    final bookmarks = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      queries: [Query.equal('user_id', userId), Query.limit(100)],
    );
    final companies = await Future.wait(
      bookmarks.rows.map((b) => getCompanyById(b.data['company_id'] as String)),
    );
    return companies;
  }

  Future<bool> isBookmarked(String userId, String companyId) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    return result.rows.isNotEmpty;
  }

  Map<String, dynamic> _toMap(aw.Row doc) => {
        'id': doc.$id,
        'created_at': doc.$createdAt,
        ...doc.data,
      };
}
