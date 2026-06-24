import '../models/company_model.dart';
import '../services/supabase_service.dart';

class CompanyRepository {
  final _client = SupabaseService.client;

  Future<List<CompanyModel>> searchCompanies({
    String? query,
    String? industry,
    String? city,
    double? minRating,
    int limit = 20,
    int offset = 0,
  }) async {
    var q = _client.from('companies').select();

    if (query != null && query.isNotEmpty) {
      q = q.ilike('name', '%$query%');
    }
    if (industry != null && industry != 'Alle Branchen') {
      q = q.eq('industry', industry);
    }
    if (city != null && city.isNotEmpty) {
      q = q.ilike('city', '%$city%');
    }
    if (minRating != null) {
      q = q.gte('average_rating', minRating);
    }

    final data = await q
        .order('average_rating', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).map((e) => CompanyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CompanyModel> getCompanyBySlug(String slug) async {
    final data = await _client
        .from('companies')
        .select()
        .eq('slug', slug)
        .single();
    return CompanyModel.fromJson(data);
  }

  Future<CompanyModel> getCompanyById(String id) async {
    final data = await _client
        .from('companies')
        .select()
        .eq('id', id)
        .single();
    return CompanyModel.fromJson(data);
  }

  Future<List<CompanyModel>> getFeaturedCompanies({int limit = 6}) async {
    final data = await _client
        .from('companies')
        .select()
        .eq('is_premium', true)
        .order('average_rating', ascending: false)
        .limit(limit);
    return (data as List).map((e) => CompanyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];
    final data = await _client
        .from('companies')
        .select('name')
        .ilike('name', '%$query%')
        .limit(5);
    return (data as List).map((e) => e['name'] as String).toList();
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
    await _client.from('companies').update({
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (website != null) 'website': website,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (industry != null) 'industry': industry,
    }).eq('id', companyId);
    return getCompanyById(companyId);
  }

  Future<void> bookmarkCompany(String userId, String companyId) async {
    await _client.from('bookmarks').upsert({
      'user_id': userId,
      'company_id': companyId,
    });
  }

  Future<void> removeBookmark(String userId, String companyId) async {
    await _client
        .from('bookmarks')
        .delete()
        .eq('user_id', userId)
        .eq('company_id', companyId);
  }

  Future<List<CompanyModel>> getBookmarkedCompanies(String userId) async {
    final data = await _client
        .from('bookmarks')
        .select('companies(*)')
        .eq('user_id', userId);
    return (data as List)
        .map((e) => CompanyModel.fromJson(e['companies'] as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isBookmarked(String userId, String companyId) async {
    final data = await _client
        .from('bookmarks')
        .select('id')
        .eq('user_id', userId)
        .eq('company_id', companyId)
        .maybeSingle();
    return data != null;
  }
}
