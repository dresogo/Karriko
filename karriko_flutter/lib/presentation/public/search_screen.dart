import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/company_provider.dart';
import '../../data/models/company_model.dart';
import '../../data/models/job_model.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String _industry = 'Alle Branchen';
  double? _minRating;
  String? _city;

  static const _industries = [
    'Alle Branchen',
    'Handwerk',
    'IT & Technik',
    'Kaufmännisch',
    'Gesundheit & Pflege',
    'Industrie',
  ];
  static const _cities = ['Zürich', 'Genf', 'Basel', 'Bern'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
      if (q.isNotEmpty) {
        _query = q;
        _controller.text = q;
      }
      _search();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(searchProvider.notifier).search(
      SearchFilters(
        query: _query.isEmpty ? null : _query,
        industry: _industry == 'Alle Branchen' ? null : _industry,
        city: _city,
        // "Ab 1 Stern" means no effective filter.
        minRating: (_minRating != null && _minRating! > 1) ? _minRating : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    final filters = _FiltersSidebar(
      industries: _industries,
      cities: _cities,
      selectedIndustry: _industry,
      minRating: _minRating ?? 1,
      selectedCity: _city,
      onIndustry: (v) { setState(() => _industry = v); _search(); },
      onRating: (v) { setState(() => _minRating = v); _search(); },
      onCity: (v) { setState(() => _city = _city == v ? null : v); _search(); },
    );

    final main = _MainColumn(
      controller: _controller,
      onQueryChanged: (v) => _query = v,
      onSearch: () { _query = _controller.text.trim(); _search(); },
    );

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Suche'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentBand(
              padding: const EdgeInsets.only(top: AppLayout.s48, bottom: AppLayout.s64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),
                  const SizedBox(height: AppLayout.s48),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 260, child: filters),
                        const SizedBox(width: AppLayout.s48),
                        Expanded(child: main),
                      ],
                    )
                  else ...[
                    filters,
                    const SizedBox(height: AppLayout.s48),
                    main,
                  ],
                ],
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fontSize = (MediaQuery.of(context).size.width * 0.045).clamp(34.0, 56.0);
    return Text(
      'UNTERNEHMEN DURCHSUCHEN',
      style: TextStyle(
        color: AppColors.ink,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.02,
        letterSpacing: -0.5,
      ),
    );
  }
}

// ─── Filter sidebar ──────────────────────────────────────────────────────────

class _FiltersSidebar extends StatelessWidget {
  final List<String> industries;
  final List<String> cities;
  final String selectedIndustry;
  final double minRating;
  final String? selectedCity;
  final ValueChanged<String> onIndustry;
  final ValueChanged<double> onRating;
  final ValueChanged<String> onCity;

  const _FiltersSidebar({
    required this.industries,
    required this.cities,
    required this.selectedIndustry,
    required this.minRating,
    required this.selectedCity,
    required this.onIndustry,
    required this.onRating,
    required this.onCity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterSection(
          title: 'BRANCHE',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final industry in industries)
                _IndustryLink(
                  label: industry,
                  selected: industry == selectedIndustry,
                  onTap: () => onIndustry(industry),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.s32),
        _FilterSection(
          title: 'BEWERTUNG',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: AppColors.line,
                  thumbColor: AppColors.ink,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: minRating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: onRating,
                ),
              ),
              const SizedBox(height: AppLayout.s8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    minRating <= 1 ? 'Alle' : 'Ab ${minRating.toInt()} Sternen',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const Text('5 Sterne',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.s32),
        _FilterSection(
          title: 'STANDORT',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final city in cities)
                _CityCheckbox(
                  label: city,
                  selected: selectedCity == city,
                  onTap: () => onCity(city),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: AppLayout.s8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.96,
            ),
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        child,
      ],
    );
  }
}

class _IndustryLink extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IndustryLink({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.ink,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CityCheckbox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CityCheckbox({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? AppColors.ink : AppColors.surface,
                border: Border.all(color: selected ? AppColors.ink : AppColors.line),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ─── Main column: search + carousels ─────────────────────────────────────────

class _MainColumn extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearch;

  const _MainColumn({
    required this.controller,
    required this.onQueryChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final jobs = ref.watch(jobSuggestionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search row (ink border + red accent button). Kept square by design.
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onQueryChanged,
                  onSubmitted: (_) => onSearch(),
                  decoration: const InputDecoration(
                    hintText: 'Betrieb oder Beruf suchen ...',
                    hintStyle: TextStyle(color: Color(0xFF8C8E88), fontSize: 16),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18),
                    constraints: BoxConstraints(minHeight: 60),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onSearch,
                child: Container(
                  width: 58,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    border: Border(left: BorderSide(color: AppColors.ink, width: 2)),
                  ),
                  child: const Center(
                    child: Icon(Icons.search, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.s48),

        // With an active search or filter, show the actual results grid.
        // Otherwise show the two suggestion carousels (Betriebe + Stellen).
        if (searchState.filters.hasFilters)
          _ResultsGrid(
            state: searchState,
            onLoadMore: () => ref.read(searchProvider.notifier).loadMore(),
          )
        else ...[
          // Row 1: suggested companies.
          _Carousel(
            label: 'BETRIEBE',
            cardHeight: 214,
            isLoading: searchState.isLoading && searchState.results.isEmpty,
            isEmpty: searchState.results.isEmpty,
            emptyMessage: searchState.error ?? 'Keine Betriebe gefunden.',
            itemCount: searchState.results.length,
            onNearEnd: () => ref.read(searchProvider.notifier).loadMore(),
            itemBuilder: (context, i) => _CompanyCard(company: searchState.results[i]),
          ),
          const SizedBox(height: AppLayout.s48),

          // Row 2: suggested Ausbildungsstellen.
          jobs.when(
            data: (list) => _Carousel(
              label: 'STELLEN',
              cardHeight: 204,
              isLoading: false,
              isEmpty: list.isEmpty,
              emptyMessage: 'Keine Stellen gefunden.',
              itemCount: list.length,
              itemBuilder: (context, i) => _JobCard(job: list[i]),
            ),
            loading: () => const _Carousel(
              label: 'STELLEN',
              cardHeight: 204,
              isLoading: true,
              isEmpty: true,
              emptyMessage: '',
              itemCount: 0,
              itemBuilder: _noBuilder,
            ),
            error: (_, __) => const _Carousel(
              label: 'STELLEN',
              cardHeight: 204,
              isLoading: false,
              isEmpty: true,
              emptyMessage: 'Stellen konnten nicht geladen werden.',
              itemCount: 0,
              itemBuilder: _noBuilder,
            ),
          ),
        ],
      ],
    );
  }
}

Widget _noBuilder(BuildContext context, int index) => const SizedBox.shrink();

// ─── Results grid (shown while a search / filter is active) ───────────────────

class _ResultsGrid extends StatelessWidget {
  final SearchState state;
  final VoidCallback onLoadMore;

  const _ResultsGrid({required this.state, required this.onLoadMore});

  static const _gap = AppLayout.s24;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppLayout.s48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return _message(state.error!);
    }
    if (state.results.isEmpty) {
      return _message('Keine Betriebe gefunden. Passe Suchbegriff oder Filter an.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final avail = constraints.maxWidth;
        final cols = avail >= 640 ? 3 : (avail >= 380 ? 2 : 1);
        final cardWidth = (avail - (cols - 1) * _gap) / cols;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${state.results.length} ${state.results.length == 1 ? 'ERGEBNIS' : 'ERGEBNISSE'}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.96,
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final company in state.results)
                  SizedBox(
                    width: cardWidth,
                    height: 214,
                    child: _CompanyCard(company: company),
                  ),
              ],
            ),
            if (state.hasMore) ...[
              const SizedBox(height: AppLayout.s32),
              Center(
                child: _LoadMoreButton(
                  loading: state.isLoading,
                  onTap: onLoadMore,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _message(String text) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.all(AppLayout.s32),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.muted, fontSize: 15),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LoadMoreButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
              )
            : const Text(
                'Mehr anzeigen',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

// ─── Horizontal carousel with paging arrows ──────────────────────────────────

class _Carousel extends StatefulWidget {
  final String label;
  final double cardHeight;
  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final VoidCallback? onNearEnd;

  const _Carousel({
    required this.label,
    required this.cardHeight,
    required this.isLoading,
    required this.isEmpty,
    required this.emptyMessage,
    required this.itemCount,
    required this.itemBuilder,
    this.onNearEnd,
  });

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _scroll = ScrollController();
  bool _canLeft = false;
  bool _canRight = false;

  static const _gap = AppLayout.s24;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final canLeft = _scroll.offset > 1;
    final canRight = _scroll.offset < max - 1;
    if (canLeft != _canLeft || canRight != _canRight) {
      setState(() {
        _canLeft = canLeft;
        _canRight = canRight;
      });
    }
    if (widget.onNearEnd != null && _scroll.offset > max - 200) {
      widget.onNearEnd!();
    }
  }

  void _page(int direction, double viewport) {
    final target = (_scroll.offset + direction * viewport)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final avail = constraints.maxWidth;
        // Show three cards on wide viewports; a fixed measure on narrow ones so
        // the row scrolls horizontally.
        final wide = avail >= 640;
        final cardWidth = wide ? (avail - 2 * _gap) / 3 : 230.0;
        final viewport = (cardWidth + _gap) * (wide ? 3 : 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.96,
                  ),
                ),
                const Spacer(),
                _ArrowButton(
                  icon: Icons.arrow_back,
                  enabled: _canLeft,
                  onTap: () => _page(-1, viewport),
                ),
                const SizedBox(width: AppLayout.s8),
                _ArrowButton(
                  icon: Icons.arrow_forward,
                  enabled: _canRight,
                  onTap: () => _page(1, viewport),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.s16),
            SizedBox(
              height: widget.cardHeight,
              child: _body(cardWidth),
            ),
          ],
        );
      },
    );
  }

  Widget _body(double cardWidth) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.isEmpty) {
      return Container(
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
          border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.all(AppLayout.s24),
        child: Text(
          widget.emptyMessage,
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
      );
    }
    return ListView.separated(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      itemCount: widget.itemCount,
      separatorBuilder: (_, __) => const SizedBox(width: _gap),
      itemBuilder: (context, i) => SizedBox(
        width: cardWidth,
        child: widget.itemBuilder(context, i),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.ink : AppColors.surface,
          border: Border.all(color: enabled ? AppColors.ink : AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : AppColors.line,
        ),
      ),
    );
  }
}

// ─── Cards ───────────────────────────────────────────────────────────────────

class _CompanyCard extends StatelessWidget {
  final CompanyModel company;

  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final rating = company.averageRating;
    return GestureDetector(
      onTap: () => context.go('/company/${company.slug}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppLayout.s24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.audienceBeige,
                border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
              ),
              child: const Icon(Icons.business, color: AppColors.ink, size: 20),
            ),
            const SizedBox(height: AppLayout.s16),
            Text(
              company.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                company.description ?? company.industry ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Icon(
                        Icons.star,
                        size: 16,
                        color: (rating != null && rating.round() > i)
                            ? AppColors.ink
                            : AppColors.line,
                      ),
                  ],
                ),
                Text(
                  rating != null ? '${rating.toStringAsFixed(1)} / 5' : '–',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/company/${job.companySlug}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppLayout.s24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.audienceBeige,
                    border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
                  ),
                  child: const Icon(Icons.work_outline, color: AppColors.ink, size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: AppColors.accent,
                  child: Text(
                    job.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.s16),
            Text(
              job.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const Spacer(),
            Text(
              job.company,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
