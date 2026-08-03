import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/company_model.dart';
import '../data/models/job_model.dart';
import '../data/repositories/company_repository.dart';

final companyRepositoryProvider =
    Provider<CompanyRepository>((ref) => CompanyRepository());

class SearchFilters {
  final String? query;
  final String? industry;
  final String? city;
  final double? minRating;

  const SearchFilters({this.query, this.industry, this.city, this.minRating});

  SearchFilters copyWith({
    String? query,
    String? industry,
    String? city,
    double? minRating,
    bool clearQuery = false,
    bool clearIndustry = false,
    bool clearCity = false,
    bool clearMinRating = false,
  }) {
    return SearchFilters(
      query: clearQuery ? null : (query ?? this.query),
      industry: clearIndustry ? null : (industry ?? this.industry),
      city: clearCity ? null : (city ?? this.city),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }

  bool get hasFilters =>
      (query?.isNotEmpty ?? false) ||
      (industry != null && industry != 'Alle Branchen') ||
      (city?.isNotEmpty ?? false) ||
      minRating != null;
}

class SearchState {
  final List<CompanyModel> results;
  final bool isLoading;
  final String? error;
  final SearchFilters filters;
  final bool hasMore;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.filters = const SearchFilters(),
    this.hasMore = true,
  });

  SearchState copyWith({
    List<CompanyModel>? results,
    bool? isLoading,
    String? error,
    SearchFilters? filters,
    bool? hasMore,
    bool clearError = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final CompanyRepository _repo;

  SearchNotifier(this._repo) : super(const SearchState());

  Future<void> search(SearchFilters filters) async {
    state = state.copyWith(
        isLoading: true, filters: filters, results: [], clearError: true);
    try {
      final results = await _repo.searchCompanies(
        query: filters.query,
        industry: filters.industry,
        city: filters.city,
        minRating: filters.minRating,
      );
      state = state.copyWith(
        results: results,
        isLoading: false,
        hasMore: results.length == 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Suche fehlgeschlagen.');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final more = await _repo.searchCompanies(
        query: state.filters.query,
        industry: state.filters.industry,
        city: state.filters.city,
        minRating: state.filters.minRating,
        offset: state.results.length,
      );
      state = state.copyWith(
        results: [...state.results, ...more],
        isLoading: false,
        hasMore: more.length == 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void clear() => state = const SearchState();
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(companyRepositoryProvider));
});

final featuredCompaniesProvider = FutureProvider<List<CompanyModel>>((ref) {
  return ref.watch(companyRepositoryProvider).getFeaturedCompanies();
});

final companyBySlugProvider =
    FutureProvider.family<CompanyModel, String>((ref, slug) {
  return ref.watch(companyRepositoryProvider).getCompanyBySlug(slug);
});

final searchSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) {
  if (query.length < 2) return Future.value([]);
  return ref.watch(companyRepositoryProvider).getSearchSuggestions(query);
});

final bookmarkedCompaniesProvider =
    FutureProvider.family<List<CompanyModel>, String>((ref, userId) {
  return ref.watch(companyRepositoryProvider).getBookmarkedCompanies(userId);
});

/// Suggested Ausbildungsstellen for the search page carousel.
///
/// NOTE: There is no jobs backend yet (no jobs collection / repository), so
/// these entries are derived from real companies as a placeholder. Replace this
/// with a proper jobs source once one exists.
final jobSuggestionsProvider = FutureProvider<List<JobModel>>((ref) async {
  final companies =
      await ref.watch(companyRepositoryProvider).searchCompanies(limit: 12);
  return [
    for (final c in companies)
      JobModel(
        id: 'job-${c.id}',
        title: c.industry != null
            ? 'Ausbildung · ${c.industry}'
            : 'Ausbildungsplatz',
        company: c.name,
        companySlug: c.slug,
        companyLogoUrl: c.logoUrl,
        location: c.location,
        profession: c.industry,
        industry: c.industry,
        badge: 'Neu',
        badgeVariant: JobBadgeVariant.isNew,
        isActive: true,
        createdAt: c.createdAt,
      ),
  ];
});
