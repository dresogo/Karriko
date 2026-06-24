import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/company_provider.dart';
import '../../data/models/company_model.dart';
import '../common/app_bar_widget.dart';
import '../common/search_bar_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';
  String _industry = 'Alle Branchen';
  double? _minRating;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
      if (q.isNotEmpty) {
        setState(() => _query = q);
        _search();
      }
    });
  }

  void _search() {
    ref.read(searchProvider.notifier).search(
      SearchFilters(
        query: _query.isEmpty ? null : _query,
        industry: _industry == 'Alle Branchen' ? null : _industry,
        minRating: _minRating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Suche'),
      drawer: const KarrikoDrawer(),
      body: Column(
        children: [
          SearchFilterBar(
            selectedIndustry: _industry,
            searchQuery: _query,
            onIndustryChanged: (v) { setState(() => _industry = v); _search(); },
            onQueryChanged: (v) => setState(() => _query = v),
            onSearch: _search,
          ),
          if (searchState.isLoading && searchState.results.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (searchState.error != null)
            Expanded(child: Center(child: Text(searchState.error!)))
          else if (searchState.results.isEmpty && searchState.filters.hasFilters)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('Keine Betriebe gefunden.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: searchState.results.length + (searchState.hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  if (i == searchState.results.length) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(searchProvider.notifier).loadMore();
                    });
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  return _CompanyListTile(company: searchState.results[i]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CompanyListTile extends StatelessWidget {
  final CompanyModel company;
  const _CompanyListTile({required this.company});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/company/${company.slug}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: const [AppColors.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name, style: Theme.of(context).textTheme.labelLarge),
                  if (company.location.isNotEmpty)
                    Text(company.location, style: Theme.of(context).textTheme.bodySmall),
                  if (company.industry != null)
                    Text(company.industry!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (company.averageRating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(company.averageRating!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                Text('${company.reviewCount} Bewertungen',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
