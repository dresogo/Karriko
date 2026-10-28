import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/company_provider.dart';
import '../../providers/job_provider.dart';
import '../../data/models/company_model.dart';
import '../../data/models/job_model.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/route_link.dart';
import '../common/tap_target.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _cityController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Suchbegriff und Filter stehen in der Adresse (T-11.17), damit sich
      // eine Suche teilen und nach dem Neuladen wiederherstellen lässt.
      final params = GoRouterState.of(context).uri.queryParameters;
      final q = params['q'] ?? '';
      if (q.isNotEmpty) {
        _query = q;
        _controller.text = q;
      }
      final branche = params['branche'];
      if (branche != null && _industries.contains(branche)) {
        _industry = branche;
      }
      final ort = params['ort']?.trim() ?? '';
      if (ort.isNotEmpty) {
        _city = ort;
        _cityController.text = ort;
      }
      // `sterne` ist der alte Name aus geteilten Links (T-11.17).
      final ab = double.tryParse(params['bewertung'] ?? params['sterne'] ?? '');
      if (_ratingSteps.contains(ab)) _minRating = ab;
      setState(() {});
      _search();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _search() {
    _adresseAktualisieren();
    ref.read(searchProvider.notifier).search(
          SearchFilters(
            query: _query.isEmpty ? null : _query,
            industry: _industry == 'Alle Branchen' ? null : _industry,
            city: _city,
            minRating: _minRating,
          ),
        );
  }

  /// Schreibt Suchbegriff und Filter in die Adresszeile, ohne neu zu
  /// navigieren: Der Bildschirm bleibt, wie er ist, nur die Adresse ändert
  /// sich (`replace`, damit „Zurück“ nicht durch jeden Filterwechsel läuft).
  void _adresseAktualisieren() {
    final params = <String, String>{
      if (_query.isNotEmpty) 'q': _query,
      if (_industry != 'Alle Branchen') 'branche': _industry,
      if (_city != null) 'ort': _city!,
      if (_minRating != null) 'bewertung': _ratingParam(_minRating!),
    };
    SystemNavigator.routeInformationUpdated(
      uri:
          Uri(path: '/search', queryParameters: params.isEmpty ? null : params),
      replace: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    final filters = _FiltersSidebar(
      industries: _industries,
      cityController: _cityController,
      selectedIndustry: _industry,
      minRating: _minRating,
      onIndustry: (v) {
        setState(() => _industry = v);
        _search();
      },
      onRating: (v) {
        setState(() => _minRating = v);
        _search();
      },
      onCity: (v) {
        final ort = v.trim().isEmpty ? null : v.trim();
        // Jeder Klick neben das Feld meldet sich; gesucht wird nur, wenn sich
        // der Ort geändert hat.
        if (ort == _city) return;
        setState(() => _city = ort);
        _search();
      },
    );

    final main = _MainColumn(
      controller: _controller,
      onQueryChanged: (v) => _query = v,
      onSearch: () {
        _query = _controller.text.trim();
        _search();
      },
    );

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Suche'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentBand(
              padding: const EdgeInsets.only(
                  top: AppLayout.s48, bottom: AppLayout.s64),
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
    final fontSize =
        (MediaQuery.of(context).size.width * 0.045).clamp(34.0, 56.0);
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

/// Stufen des Bewertungsfilters, als Zahl statt Sternen (Entscheidung vom
/// 22.10.2026, T-6.30). `null` heißt: alle.
const _ratingSteps = <double?>[null, 3, 3.5, 4];

/// „3“ oder „3,5“ für die Anzeige.
String _ratingLabel(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toString().replaceAll('.', ',');

/// „3“ oder „3.5“ für die Adresse.
String _ratingParam(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class _FiltersSidebar extends StatelessWidget {
  final List<String> industries;
  final TextEditingController cityController;
  final String selectedIndustry;
  final double? minRating;
  final ValueChanged<String> onIndustry;
  final ValueChanged<double?> onRating;
  final ValueChanged<String> onCity;

  const _FiltersSidebar({
    required this.industries,
    required this.cityController,
    required this.selectedIndustry,
    required this.minRating,
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
                _FilterLink(
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
          child: _RatingSlider(value: minRating, onChanged: onRating),
        ),
        const SizedBox(height: AppLayout.s32),
        _FilterSection(
          title: 'STANDORT',
          // Ein freies Feld statt einer festen Liste: Die Orte stehen in den
          // Betriebsdaten, und die Suche geht über den Volltext-Index auf
          // `city` (T-11.10). Gesucht wird mit Enter oder beim Verlassen.
          child: TextField(
            controller: cityController,
            onSubmitted: onCity,
            onTapOutside: (_) => onCity(cityController.text),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Ort, z. B. Dortmund',
              isDense: true,
            ),
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

/// Bewertungsfilter als Schieberegler mit Raster: vier Stufen aus
/// [_ratingSteps], Striche an jeder Stufe, Beschriftung darunter.
///
/// Swiss Design (Factsheet §2): Haarlinie in `line`, gewählter Bereich und
/// Griff in `ink`, eckiger Griff, keine Welle. Mit Fokus wird der Griff
/// `accent` mit Tintenrahmen, damit die Tastaturbedienung sichtbar bleibt.
/// Gesucht wird erst beim Loslassen, nicht bei jeder Stufe unterwegs; die
/// Beschriftungen sind zusätzlich Klickziele für ungenaue Finger.
class _RatingSlider extends StatefulWidget {
  final double? value;
  final ValueChanged<double?> onChanged;

  const _RatingSlider({required this.value, required this.onChanged});

  @override
  State<_RatingSlider> createState() => _RatingSliderState();
}

class _RatingSliderState extends State<_RatingSlider> {
  final _focus = FocusNode();
  late int _index = _indexOf(widget.value);

  static int _indexOf(double? v) {
    final i = _ratingSteps.indexOf(v);
    return i < 0 ? 0 : i;
  }

  /// „Alle Bewertungen“ oder „ab 3,5 von 5“: sichtbar und für Screenreader.
  static String _beschreibung(double? step) =>
      step == null ? 'Alle Bewertungen' : 'ab ${_ratingLabel(step)} von 5';

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(_RatingSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _index = _indexOf(widget.value);
  }

  @override
  void dispose() {
    // Steckt immer im eigenen Overlay (initialEntries); vor dispose
    // heraus, sonst schlägt die Prüfung in OverlayEntry.dispose an.
    _reglerEintrag.remove();
    _reglerEintrag.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _waehlen(int i) {
    setState(() => _index = i);
    widget.onChanged(_ratingSteps[i]);
  }

  /// Der Regler als Eintrag im eigenen Overlay (siehe [build]). Ein Eintrag
  /// baut sich nicht mit seinem Eltern-Widget neu, deshalb stößt [build] ihn
  /// jedes Mal an.
  late final OverlayEntry _reglerEintrag = OverlayEntry(
    builder: (context) {
      final last = _ratingSteps.length - 1;
      return Slider(
        focusNode: _focus,
        value: _index.toDouble(),
        min: 0,
        max: last.toDouble(),
        divisions: last,
        semanticFormatterCallback: (v) =>
            _beschreibung(_ratingSteps[v.round()]),
        onChanged: (v) => setState(() => _index = v.round()),
        onChangeEnd: (v) => widget.onChanged(_ratingSteps[v.round()]),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final last = _ratingSteps.length - 1;
    _reglerEintrag.markNeedsBuild();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Der gewählte Wert in Worten, damit er nicht nur an der Position
        // des Griffs abzulesen ist.
        ExcludeSemantics(
          child: Text(
            _beschreibung(_ratingSteps[_index]),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: AppLayout.s8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            trackShape: const RectangularSliderTrackShape(),
            activeTrackColor: AppColors.ink,
            inactiveTrackColor: AppColors.line,
            activeTickMarkColor: AppColors.ink,
            inactiveTickMarkColor: AppColors.muted,
            tickMarkShape: const _RasterTick(),
            thumbShape: _SquareThumb(focused: focused),
            overlayShape: SliderComponentShape.noOverlay,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: SizedBox(
            // Mindesthöhe des Klickziels (WCAG 2.5.8).
            height: 44,
            // Eigenes Overlay nur für den Regler (T-11.26). `Slider` legt
            // seinen Wert-Indikator immer per OverlayPortal ins nächste
            // Overlay, auch bei `ShowValueIndicator.never` – dann als leere
            // Fläche in Overlay-Größe. Im Navigator-Overlay war das die ganze
            // Seite, und ab Flutter 3.47 fängt ein solcher leerer
            // Semantik-Knoten im Web die Klicks ab: Kein Link der Suchseite
            // ließ sich mehr anklicken. Hier bleibt die Fläche so groß wie
            // der Regler, und darunter liegt kein Link.
            child: Overlay(initialEntries: [_reglerEintrag]),
          ),
        ),
        // Beschriftung unter den Rasterstrichen. Für Screenreader reicht der
        // Regler; die Beschriftungen sind nur zusätzliche Klickziele.
        ExcludeSemantics(
          child: SizedBox(
            height: 24,
            child: Stack(
              children: [
                for (var i = 0; i <= last; i++)
                  Align(
                    alignment: Alignment(-1 + 2 * i / last, 0),
                    child: TapTarget(
                      onTap: () => _waehlen(i),
                      builder: (context, active) => Text(
                        i == 0 ? 'Alle' : _ratingLabel(_ratingSteps[i]!),
                        style: TextStyle(
                          color: i == _index
                              ? AppColors.accentDark
                              : AppColors.muted,
                          fontSize: 12,
                          fontWeight:
                              i == _index ? FontWeight.w800 : FontWeight.w400,
                          decoration: active
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Rasterstrich: 1 px breit, 8 px hoch, mittig auf der Linie.
class _RasterTick extends SliderTickMarkShape {
  const _RasterTick();

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) =>
      const Size(1, 8);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    required bool isEnabled,
    required TextDirection textDirection,
  }) {
    final active = center.dx <= thumbCenter.dx;
    final color = active
        ? sliderTheme.activeTickMarkColor
        : sliderTheme.inactiveTickMarkColor;
    context.canvas.drawRect(
      Rect.fromCenter(center: center, width: 1, height: 8),
      Paint()..color = color ?? AppColors.muted,
    );
  }
}

/// Eckiger Griff (Factsheet §2.3: eckig außer Knöpfen). Mit Fokus `accent`
/// mit 2 px Rahmen in `ink`, wie die Fokus-Regel für Eingabefelder.
class _SquareThumb extends SliderComponentShape {
  final bool focused;

  const _SquareThumb({required this.focused});

  static const _size = 14.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(_size, _size);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final rect = Rect.fromCenter(center: center, width: _size, height: _size);
    final canvas = context.canvas;
    canvas.drawRect(
      rect,
      Paint()..color = focused ? AppColors.accent : AppColors.ink,
    );
    if (focused) {
      canvas.drawRect(
        rect.inflate(1),
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}

/// Eine Filteroption als Textzeile. [TapTarget] statt InkWell (E-10):
/// Hand-Cursor, Tastatur und Hover als Unterstreichung.
class _FilterLink extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterLink(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: TapTarget(
        onTap: onTap,
        builder: (context, active) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.accentDark : AppColors.ink,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
              decoration:
                  active ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
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
                    hintStyle:
                        TextStyle(color: Color(0xFF8C8E88), fontSize: 16),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18),
                    constraints: BoxConstraints(minHeight: 60),
                  ),
                ),
              ),
              TapTarget(
                semanticLabel: 'Suchen',
                onTap: onSearch,
                builder: (_, active) => Container(
                  width: 58,
                  height: 60,
                  decoration: BoxDecoration(
                    color: active ? AppColors.accentDark : AppColors.accent,
                    border: const Border(
                        left: BorderSide(color: AppColors.ink, width: 2)),
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
            itemBuilder: (context, i) =>
                _CompanyCard(company: searchState.results[i]),
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
      return _message(
          'Keine Betriebe gefunden. Passe Suchbegriff oder Filter an.');
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
    return TapTarget(
      onTap: loading ? null : onTap,
      builder: (_, active) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.audienceBeige : null,
          border: Border.all(color: AppColors.ink),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.ink),
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
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic);
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

  const _ArrowButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapTarget(
      onTap: enabled ? onTap : null,
      builder: (_, active) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent
              : (enabled ? AppColors.ink : AppColors.surface),
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
    return RouteLink(
      route: '/company/${company.slug}',
      behavior: HitTestBehavior.opaque,
      builder: (context, active) => Container(
        padding: const EdgeInsets.all(AppLayout.s24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: active ? AppColors.ink : AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.audienceBeige,
                border:
                    Border.fromBorderSide(BorderSide(color: AppColors.line)),
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
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            // Zahl mit flachem Balken statt Sternen (Entscheidung vom
            // 22.10.2026, T-6.30); Skala wie [ScoreBalken].
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    color: AppColors.line,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: rating == null
                          ? 0
                          : ((rating - 1) / 4).clamp(0.0, 1.0),
                      child: Container(color: AppColors.ink),
                    ),
                  ),
                ),
                const SizedBox(width: AppLayout.s16),
                Text(
                  rating != null
                      ? '${rating.toStringAsFixed(1).replaceAll('.', ',')} / 5'
                      : '–',
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
    return RouteLink(
      route: '/stellen/${job.id}',
      behavior: HitTestBehavior.opaque,
      builder: (context, active) => Container(
        padding: const EdgeInsets.all(AppLayout.s24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: active ? AppColors.ink : AppColors.line),
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
                    border: Border.fromBorderSide(
                        BorderSide(color: AppColors.line)),
                  ),
                  child: const Icon(Icons.work_outline,
                      color: AppColors.ink, size: 18),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: AppColors.accentDark,
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
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13),
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
