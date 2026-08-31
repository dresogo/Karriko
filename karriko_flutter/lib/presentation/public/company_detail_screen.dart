import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/company_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/company_model.dart';
import '../../data/models/review_model.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/review_card.dart' show StarRating;

/// Profilseite eines Betriebs im Bandraster der Website: Vollbreite Bänder mit
/// Haarlinien, Inhalt auf lesbarem Mass ([ContentBand]), scharfe Kanten.
class CompanyDetailScreen extends ConsumerWidget {
  final String slug;
  const CompanyDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(companyBySlugProvider(slug));

    return Scaffold(
      appBar: const KarrikoAppBar(),
      drawer: const KarrikoDrawer(),
      body: company.when(
        data: (c) => _CompanyDetailBody(company: c),
        loading: () => const _LoadingState(),
        error: (_, __) => const _NotFoundState(),
      ),
    );
  }
}

class _CompanyDetailBody extends ConsumerWidget {
  final CompanyModel company;
  const _CompanyDetailBody({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(companyReviewsProvider(company.id));
    final auth = ref.watch(authProvider);

    // Verteilung und Kategoriemittel stammen aus den geladenen Bewertungen;
    // solange die noch laufen, bleiben die betroffenen Bänder leer statt zu
    // springen.
    final list = reviews.valueOrNull ?? const <ReviewModel>[];
    final stats = _ReviewStats.from(list);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileBand(company: company, stats: stats, isAzubi: auth.isAzubi),
          _MetricsBand(company: company),
          if (stats.categories.isNotEmpty) _CategoryBand(stats: stats),
          if (company.description != null &&
              company.description!.trim().isNotEmpty)
            _AboutBand(description: company.description!),
          _ReviewsBand(reviews: reviews, isAzubi: auth.isAzubi),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// ─── Profil ──────────────────────────────────────────────────────────────────

class _ProfileBand extends StatelessWidget {
  final CompanyModel company;
  final _ReviewStats stats;
  final bool isAzubi;

  const _ProfileBand({
    required this.company,
    required this.stats,
    required this.isAzubi,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 980;

    final identity = _CompanyIdentity(
      company: company,
      isAzubi: isAzubi,
      isWide: isWide,
    );
    final rating = _RatingPanel(company: company, stats: stats);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(
          vertical: isWide ? AppLayout.s64 : AppLayout.s48,
        ),
        child: isWide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 58, child: identity),
                    const SizedBox(width: AppLayout.s48),
                    const VerticalDivider(width: 1, color: AppColors.line),
                    const SizedBox(width: AppLayout.s48),
                    Expanded(flex: 42, child: rating),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  const SizedBox(height: AppLayout.s32),
                  const Divider(height: 1, color: AppColors.line),
                  const SizedBox(height: AppLayout.s32),
                  rating,
                ],
              ),
      ),
    );
  }
}

class _CompanyIdentity extends StatelessWidget {
  final CompanyModel company;
  final bool isAzubi;
  final bool isWide;

  const _CompanyIdentity({
    required this.company,
    required this.isAzubi,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(
          text: [
            'BETRIEBSPROFIL',
            if (company.industry != null && company.industry!.trim().isNotEmpty)
              company.industry!.toUpperCase(),
          ].join(' · '),
          color: AppColors.accent,
        ),
        const SizedBox(height: AppLayout.s24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompanyMark(company: company),
            const SizedBox(width: AppLayout.s24),
            Expanded(
              child: Text(
                company.name,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: (width * 0.042).clamp(30.0, 52.0),
                  fontWeight: FontWeight.w800,
                  height: 1.02,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s24),
        Wrap(
          spacing: AppLayout.s16,
          runSpacing: AppLayout.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (company.isVerified) const _VerifiedTag(),
            if (company.location.isNotEmpty)
              _MetaItem(icon: Icons.place_outlined, label: company.location),
            if (company.website != null && company.website!.trim().isNotEmpty)
              _MetaItem(icon: Icons.language, label: company.website!),
          ],
        ),
        const SizedBox(height: AppLayout.s32),
        Wrap(
          spacing: AppLayout.s16,
          runSpacing: AppLayout.s16,
          children: [
            if (isAzubi)
              ElevatedButton.icon(
                onPressed: () => context.go('/reviews/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Betrieb bewerten'),
              ),
            OutlinedButton.icon(
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Zur Suche'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Logo des Betriebs, ersatzweise ein Monogramm aus den Anfangsbuchstaben.
class _CompanyMark extends StatelessWidget {
  final CompanyModel company;

  const _CompanyMark({required this.company});

  String get _initials {
    final words = company.name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .toList();
    if (words.isEmpty) return '?';
    return words.map((w) => w.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = company.logoUrl != null && company.logoUrl!.isNotEmpty;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      child: hasLogo
          ? CachedNetworkImage(
              imageUrl: company.logoUrl!,
              fit: BoxFit.cover,
              width: 72,
              height: 72,
              errorWidget: (_, __, ___) => _monogram,
              placeholder: (_, __) => const SizedBox.shrink(),
            )
          : _monogram,
    );
  }

  Widget get _monogram => Text(
        _initials,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      );
}

/// Gesamtnote gross gesetzt, darunter die Verteilung der abgegebenen Sterne.
class _RatingPanel extends StatelessWidget {
  final CompanyModel company;
  final _ReviewStats stats;

  const _RatingPanel({required this.company, required this.stats});

  @override
  Widget build(BuildContext context) {
    final average = company.averageRating ?? stats.average;
    final total = company.reviewCount > 0 ? company.reviewCount : stats.total;

    if (average == null || total == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Eyebrow(text: 'GESAMTBEWERTUNG'),
          const SizedBox(height: AppLayout.s16),
          Text(
            'Noch keine\nBewertungen',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppLayout.s8),
          Text(
            'Dieser Betrieb wurde bisher nicht bewertet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Eyebrow(text: 'GESAMTBEWERTUNG'),
        const SizedBox(height: AppLayout.s16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatRating(average),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 72,
                fontWeight: FontWeight.w800,
                height: 0.86,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(width: AppLayout.s8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'von 5',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s16),
        Row(
          children: [
            StarRating(rating: average.round(), size: 18),
            const SizedBox(width: AppLayout.s8),
            Text(
              total == 1 ? '1 Bewertung' : '$total Bewertungen',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (stats.total > 0) ...[
          const SizedBox(height: AppLayout.s24),
          for (var star = 5; star >= 1; star--)
            _DistributionRow(
              star: star,
              count: stats.distribution[star] ?? 0,
              total: stats.total,
            ),
        ],
      ],
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final int star;
  final int count;
  final int total;

  const _DistributionRow({
    required this.star,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // Anteil an allen Bewertungen – nicht am größten Balken, sonst wirkt eine
    // einzelne Stimme wie ein Maximum.
    final fraction = total == 0 ? 0.0 : count / total;

    return Semantics(
      label: '$star Sterne: $count Bewertungen',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppLayout.s8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$star',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const Icon(Icons.star, size: 12, color: AppColors.muted),
            const SizedBox(width: AppLayout.s16),
            Expanded(child: _Meter(fraction: fraction)),
            const SizedBox(width: AppLayout.s16),
            SizedBox(
              width: 28,
              child: Text(
                '$count',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Balken auf beiger Spur. Der Wert steht immer auch als Zahl daneben – die
/// Länge des Balkens ist Zugabe, nicht die einzige Information.
class _Meter extends StatelessWidget {
  final double fraction;

  const _Meter({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: AppColors.audienceBeige,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(color: AppColors.ink),
      ),
    );
  }
}

// ─── Kennzahlen ──────────────────────────────────────────────────────────────

class _MetricsBand extends StatelessWidget {
  final CompanyModel company;

  const _MetricsBand({required this.company});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 720;

    final cells = <(String, String)>[
      (
        company.averageRating != null
            ? _formatRating(company.averageRating!)
            : '–',
        'Ø Bewertung',
      ),
      ('${company.reviewCount}', 'Bewertungen'),
      (company.industry ?? '–', 'Branche'),
      (DateFormat('yyyy').format(company.createdAt), 'Auf Karriko seit'),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        child: isWide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cells.length; i++)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: i == cells.length - 1
                                  ? BorderSide.none
                                  : const BorderSide(color: AppColors.line),
                            ),
                          ),
                          padding: EdgeInsets.only(
                            top: AppLayout.s32,
                            bottom: AppLayout.s32,
                            right: AppLayout.s24,
                            left: i == 0 ? 0 : AppLayout.s24,
                          ),
                          child: _MetricCell(
                              value: cells[i].$1, label: cells[i].$2),
                        ),
                      ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cells.length; i++)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: i == cells.length - 1
                              ? BorderSide.none
                              : const BorderSide(color: AppColors.line),
                        ),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppLayout.s24),
                      child:
                          _MetricCell(value: cells[i].$1, label: cells[i].$2),
                    ),
                ],
              ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String value;
  final String label;

  const _MetricCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Bewertung im Detail ─────────────────────────────────────────────────────

class _CategoryBand extends StatelessWidget {
  final _ReviewStats stats;

  const _CategoryBand({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 980;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(text: 'BEWERTUNG IM DETAIL'),
        const SizedBox(height: AppLayout.s16),
        Text(
          'Wie Azubis\ndie Ausbildung\neinordnen.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ],
    );

    final meters = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in stats.categories.entries)
          _CategoryRow(label: entry.key, value: entry.value),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 40, child: heading),
                  const SizedBox(width: AppLayout.s64),
                  Expanded(flex: 60, child: meters),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  const SizedBox(height: AppLayout.s32),
                  meters,
                ],
              ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final double value;

  const _CategoryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    // Auf schmalen Viewports steht das Label über dem Balken, sonst brechen
    // lange Begriffe wie „Ausbildungsqualität“ mitten im Wort um.
    final isWide = MediaQuery.sizeOf(context).width > 720;

    final labelText = Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
    final meterRow = Row(
      children: [
        Expanded(child: _Meter(fraction: value / 5)),
        const SizedBox(width: AppLayout.s16),
        SizedBox(
          width: 34,
          child: Text(
            _formatRating(value),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );

    return Semantics(
      label: '$label: ${_formatRating(value)} von 5',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.s16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: isWide
            ? Row(
                children: [
                  Expanded(flex: 40, child: labelText),
                  Expanded(flex: 60, child: meterRow),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  labelText,
                  const SizedBox(height: AppLayout.s8),
                  meterRow,
                ],
              ),
      ),
    );
  }
}

// ─── Über das Unternehmen ────────────────────────────────────────────────────

class _AboutBand extends StatelessWidget {
  final String description;

  const _AboutBand({required this.description});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 980;

    final heading = Text(
      'Über den\nBetrieb.',
      style: Theme.of(context).textTheme.displaySmall,
    );
    final body = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Text(
        description,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: AppColors.muted, height: 1.6),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 40, child: heading),
                  const SizedBox(width: AppLayout.s64),
                  Expanded(flex: 60, child: body),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  const SizedBox(height: AppLayout.s24),
                  body,
                ],
              ),
      ),
    );
  }
}

// ─── Bewertungen ─────────────────────────────────────────────────────────────

class _ReviewsBand extends StatelessWidget {
  final AsyncValue<List<ReviewModel>> reviews;
  final bool isAzubi;

  const _ReviewsBand({required this.reviews, required this.isAzubi});

  @override
  Widget build(BuildContext context) {
    return ContentBand(
      padding: const EdgeInsets.only(
        top: AppLayout.s48,
        bottom: AppLayout.s64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Bewertungen',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              if (reviews.valueOrNull != null &&
                  reviews.valueOrNull!.isNotEmpty)
                Text(
                  '${reviews.valueOrNull!.length} EINTRÄGE',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.96,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppLayout.s24),
          reviews.when(
            data: (list) => list.isEmpty
                ? _EmptyReviews(isAzubi: isAzubi)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1, color: AppColors.line),
                      for (final review in list) ...[
                        _ReviewRow(review: review),
                        const Divider(height: 1, color: AppColors.line),
                      ],
                    ],
                  ),
            loading: () => const _ReviewSkeleton(),
            error: (_, __) => const _ReviewError(),
          ),
        ],
      ),
    );
  }
}

/// Bewertung als redaktionelle Zeile statt als Karte: Haarlinien trennen, der
/// Hover- und Fokuszustand liegt auf der ganzen Zeile.
class _ReviewRow extends StatefulWidget {
  final ReviewModel review;

  const _ReviewRow({required this.review});

  @override
  State<_ReviewRow> createState() => _ReviewRowState();
}

class _ReviewRowState extends State<_ReviewRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final isWide = MediaQuery.sizeOf(context).width > 720;

    final meta = [
      if (review.profession != null && review.profession!.isNotEmpty)
        review.profession!.toUpperCase(),
      if (review.apprenticeshipYear != null &&
          review.apprenticeshipYear!.isNotEmpty)
        review.apprenticeshipYear!.toUpperCase(),
      DateFormat('dd.MM.yyyy').format(review.createdAt),
    ].join(' · ');

    return Semantics(
      button: true,
      label: 'Bewertung: ${review.title}, '
          '${review.overallRating} von 5 Sternen. ${review.displayAuthor}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/reviews/${review.id}'),
          onHover: (v) => setState(() => _hovered = v),
          onFocusChange: (v) => setState(() => _focused = v),
          hoverColor: AppColors.audienceBeige.withValues(alpha: 0.6),
          focusColor: AppColors.audienceBeige,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: AppLayout.s32),
            foregroundDecoration: BoxDecoration(
              border: Border.all(
                color: _focused ? AppColors.ink : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Eyebrow(text: meta),
                          const SizedBox(height: AppLayout.s8),
                          Text(
                            review.title,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: isWide ? 24 : 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppLayout.s24),
                    _ScoreTag(rating: review.overallRating),
                  ],
                ),
                const SizedBox(height: AppLayout.s16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(
                    review.text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (review.pros != null || review.cons != null) ...[
                  const SizedBox(height: AppLayout.s24),
                  _ProsCons(
                    pros: review.pros,
                    cons: review.cons,
                    isWide: isWide,
                  ),
                ],
                if (review.betriebReply != null) ...[
                  const SizedBox(height: AppLayout.s24),
                  _BetriebReply(text: review.betriebReply!),
                ],
                const SizedBox(height: AppLayout.s24),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            review.displayAuthor,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (review.isVerified) ...[
                            const SizedBox(width: AppLayout.s8),
                            const _VerifiedTag(compact: true),
                          ],
                        ],
                      ),
                    ),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      offset: _hovered || _focused
                          ? const Offset(0.25, 0)
                          : Offset.zero,
                      child: const Icon(Icons.arrow_forward,
                          size: 20, color: AppColors.ink),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Note der Bewertung als Tintenfläche – gut lesbar und ohne Farbcodierung.
class _ScoreTag extends StatelessWidget {
  final int rating;

  const _ScoreTag({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 52,
          height: 52,
          color: AppColors.ink,
          alignment: Alignment.center,
          child: Text(
            '$rating',
            style: const TextStyle(
              color: AppColors.paper,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppLayout.s8),
        StarRating(rating: rating, size: 12),
      ],
    );
  }
}

class _ProsCons extends StatelessWidget {
  final String? pros;
  final String? cons;
  final bool isWide;

  const _ProsCons(
      {required this.pros, required this.cons, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (pros != null && pros!.trim().isNotEmpty)
        _ProsConsBlock(
          icon: Icons.add,
          label: 'Positiv',
          text: pros!,
          accent: AppColors.green,
        ),
      if (cons != null && cons!.trim().isNotEmpty)
        _ProsConsBlock(
          icon: Icons.remove,
          label: 'Kritisch',
          text: cons!,
          accent: AppColors.accent,
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return isWide && items.length == 2
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: AppLayout.s16),
                Expanded(child: items[1]),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppLayout.s16),
                items[i],
              ],
            ],
          );
  }
}

class _ProsConsBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color accent;

  const _ProsConsBlock({
    required this.icon,
    required this.label,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: const BorderSide(color: AppColors.line),
          right: const BorderSide(color: AppColors.line),
          bottom: const BorderSide(color: AppColors.line),
          left: BorderSide(color: accent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.88,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.s8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BetriebReply extends StatelessWidget {
  final String text;

  const _BetriebReply({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: const BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border(left: BorderSide(color: AppColors.green, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.reply, size: 14, color: AppColors.green),
              SizedBox(width: 6),
              Text(
                'ANTWORT DES BETRIEBS',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.88,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.s8),
          Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── Zustände ────────────────────────────────────────────────────────────────

class _EmptyReviews extends StatelessWidget {
  final bool isAzubi;

  const _EmptyReviews({required this.isAzubi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Noch keine Bewertungen',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppLayout.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Für diesen Betrieb liegt bisher keine Erfahrung vor. '
              'Die erste Bewertung hilft allen, die sich hier bewerben wollen.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (isAzubi) ...[
            const SizedBox(height: AppLayout.s24),
            ElevatedButton(
              onPressed: () => context.go('/reviews/new'),
              child: const Text('Jetzt bewerten'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Platzhalter in der Höhe echter Zeilen, damit beim Nachladen nichts springt.
class _ReviewSkeleton extends StatelessWidget {
  const _ReviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppLayout.s32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 180, color: AppColors.line),
                const SizedBox(height: AppLayout.s16),
                Container(height: 24, width: 320, color: AppColors.line),
                const SizedBox(height: AppLayout.s16),
                Container(height: 12, color: AppColors.audienceBeige),
                const SizedBox(height: AppLayout.s8),
                Container(height: 12, color: AppColors.audienceBeige),
              ],
            ),
          ),
        ],
        const Divider(height: 1, color: AppColors.line),
      ],
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.line),
          right: BorderSide(color: AppColors.line),
          bottom: BorderSide(color: AppColors.line),
          left: BorderSide(color: AppColors.accent, width: 3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.accent),
          const SizedBox(width: AppLayout.s16),
          Expanded(
            child: Text(
              'Die Bewertungen konnten nicht geladen werden.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ContentBand(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 12, width: 160, color: AppColors.line),
          const SizedBox(height: AppLayout.s24),
          Container(height: 48, width: 420, color: AppColors.line),
          const SizedBox(height: AppLayout.s16),
          Container(height: 16, width: 240, color: AppColors.audienceBeige),
        ],
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    return ContentBand(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow(text: 'BETRIEBSPROFIL', color: AppColors.accent),
          const SizedBox(height: AppLayout.s16),
          Text(
            'Betrieb nicht\ngefunden.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppLayout.s16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Dieses Profil gibt es nicht (mehr). Über die Suche findest du '
              'alle Betriebe, die auf Karriko bewertet wurden.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppLayout.s24),
          OutlinedButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Zur Suche'),
          ),
        ],
      ),
    );
  }
}

// ─── Bausteine ───────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  final String text;
  final Color color;

  const _Eyebrow({required this.text, this.color = AppColors.muted});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.96,
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VerifiedTag extends StatelessWidget {
  final bool compact;

  const _VerifiedTag({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border.all(color: AppColors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: compact ? 11 : 14, color: AppColors.green),
          const SizedBox(width: 5),
          Text(
            'VERIFIZIERT',
            style: TextStyle(
              color: AppColors.green,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.88,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Auswertung ──────────────────────────────────────────────────────────────

/// Verteilung und Kategoriemittel aus den geladenen Bewertungen. Beides wird
/// hier gerechnet, weil das Unternehmensdokument nur Schnitt und Anzahl kennt.
class _ReviewStats {
  final Map<int, int> distribution;
  final int total;
  final double? average;
  final Map<String, double> categories;

  const _ReviewStats({
    required this.distribution,
    required this.total,
    required this.average,
    required this.categories,
  });

  factory _ReviewStats.from(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const _ReviewStats(
        distribution: {},
        total: 0,
        average: null,
        categories: {},
      );
    }

    final distribution = <int, int>{};
    var sum = 0;
    for (final review in reviews) {
      final star = review.overallRating.clamp(1, 5);
      distribution[star] = (distribution[star] ?? 0) + 1;
      sum += review.overallRating;
    }

    double? mean(int? Function(ReviewModel) pick) {
      final values = reviews.map(pick).whereType<int>().toList();
      if (values.isEmpty) return null;
      return values.reduce((a, b) => a + b) / values.length;
    }

    final categories = <String, double>{};
    void add(String label, double? value) {
      if (value != null) categories[label] = value;
    }

    add('Ausbildungsqualität', mean((r) => r.trainingQuality));
    add('Betreuung', mean((r) => r.mentoring));
    add('Work-Life-Balance', mean((r) => r.workLifeBalance));
    add('Übernahmechancen', mean((r) => r.careerOpportunities));

    return _ReviewStats(
      distribution: distribution,
      total: reviews.length,
      average: sum / reviews.length,
      categories: categories,
    );
  }
}

/// Note im deutschen Format: ein Nachkommastellen-Wert mit Komma.
String _formatRating(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');
