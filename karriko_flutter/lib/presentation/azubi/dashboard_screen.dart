import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/company_model.dart';
import '../../data/models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/review_provider.dart';
import '../common/app_page.dart';

class AzubiDashboardScreen extends ConsumerWidget {
  const AzubiDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final userId = auth.user?.id ?? '';
    final myReviews = ref.watch(myReviewsProvider(userId));
    final bookmarks = ref.watch(bookmarkedCompaniesProvider(userId));

    return AppPage(
      appBarTitle: 'Dashboard',
      eyebrow: 'DASHBOARD',
      title: 'Hallo, ${auth.user?.displayName ?? 'Azubi'}.',
      lede: 'Deine Bewertungen, deine gemerkten Betriebe und der schnelle Weg '
          'zu allem Weiteren.',
      headerAction: FilledButton.icon(
        onPressed: () => context.go('/reviews/new'),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Bewertung schreiben'),
      ),
      children: [
        _Stats(reviews: myReviews, bookmarks: bookmarks),
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Schnellzugriff'),
        const SizedBox(height: AppLayout.s16),
        const _QuickActions(),
        const SizedBox(height: AppLayout.s48),
        _ReviewsSection(reviews: myReviews),
        const SizedBox(height: AppLayout.s48),
        _BookmarksSection(bookmarks: bookmarks),
      ],
    );
  }
}

// ─── Kennzahlen ──────────────────────────────────────────────────────────────

class _Stats extends StatelessWidget {
  final AsyncValue<List<ReviewModel>> reviews;
  final AsyncValue<List<CompanyModel>> bookmarks;

  const _Stats({required this.reviews, required this.bookmarks});

  /// Zeigt Werte erst, wenn sie geladen sind – ein Strich ist ehrlicher als
  /// eine Null, die nach dem Laden auf etwas anderes springt.
  String _count(AsyncValue<List<Object>> value) =>
      value.maybeWhen(data: (list) => '${list.length}', orElse: () => '–');

  String get _average => reviews.maybeWhen(
        data: (list) {
          if (list.isEmpty) return '–';
          final sum = list.fold<int>(0, (acc, r) => acc + r.overallRating);
          return (sum / list.length).toStringAsFixed(1);
        },
        orElse: () => '–',
      );

  @override
  Widget build(BuildContext context) {
    const gap = AppLayout.s24;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 720 ? 3 : 1;
        final width = (constraints.maxWidth - (cols - 1) * gap) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: StatTile(value: _count(reviews), label: 'Bewertungen'),
            ),
            SizedBox(
              width: width,
              child: StatTile(value: _average, label: 'Ø deiner Bewertungen'),
            ),
            SizedBox(
              width: width,
              child: StatTile(
                  value: _count(bookmarks), label: 'Gemerkte Betriebe'),
            ),
          ],
        );
      },
    );
  }
}

// ─── Schnellzugriff ──────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = <(IconData, String, String)>[
    (Icons.quiz_outlined, 'Fragen bewerten', '/fragen-bewerten'),
    (Icons.search, 'Betrieb suchen', '/search'),
    (Icons.rate_review_outlined, 'Meine Bewertungen', '/my-reviews'),
    (Icons.bookmark_border, 'Merkliste', '/bookmarks'),
    (Icons.person_outline, 'Mein Profil', '/profile'),
    (Icons.tune, 'Einstellungen', '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    const gap = AppLayout.s16;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Feste Spaltenzahl statt Seitenverhältnis: So bestimmt der Inhalt die
        // Höhe und lange Beschriftungen brechen um, statt überzulaufen.
        final cols = switch (constraints.maxWidth) {
          >= 900 => 3,
          >= 560 => 2,
          _ => 1,
        };
        final width = (constraints.maxWidth - (cols - 1) * gap) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in _actions)
              SizedBox(
                width: width,
                child: _QuickAction(
                  icon: action.$1,
                  label: action.$2,
                  route: action.$3,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;

  const _QuickAction(
      {required this.icon, required this.label, required this.route});

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: () => context.go(widget.route),
          onFocusChange: (v) => setState(() => _focused = v),
          onHover: (v) => setState(() => _hovered = v),
          hoverColor: AppColors.paper,
          focusColor: AppColors.audienceBeige,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.s16,
              vertical: AppLayout.s16,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _focused ? AppColors.ink : AppColors.line,
                  width: _focused ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 20, color: AppColors.ink),
                const SizedBox(width: AppLayout.s16),
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  offset: _hovered || _focused
                      ? const Offset(0.25, 0)
                      : Offset.zero,
                  child: const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bewertungen ─────────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final AsyncValue<List<ReviewModel>> reviews;

  const _ReviewsSection({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHead(
          label: 'Meine Bewertungen',
          actionLabel: 'Alle anzeigen',
          onAction: () => context.go('/my-reviews'),
        ),
        const SizedBox(height: AppLayout.s16),
        reviews.when(
          data: (list) => list.isEmpty
              ? AppEmptyState(
                  title: 'Noch keine Bewertung',
                  description:
                      'Teile deine Erfahrung und hilf anderen bei der Wahl '
                      'ihres Ausbildungsbetriebs.',
                  actionLabel: 'Erste Bewertung schreiben',
                  onAction: () => context.go('/reviews/new'),
                )
              : AppRowGroup(
                  children: [
                    for (final review in list.take(3))
                      AppRow(
                        icon: Icons.rate_review_outlined,
                        title: review.title,
                        subtitle:
                            '${review.companyName} · ${review.overallRating}/5',
                        onTap: () => context.go('/reviews/${review.id}'),
                      ),
                  ],
                ),
          loading: () => const _SectionLoading(),
          error: (_, __) => const _SectionError(
            text: 'Deine Bewertungen konnten nicht geladen werden.',
          ),
        ),
      ],
    );
  }
}

// ─── Merkliste ───────────────────────────────────────────────────────────────

class _BookmarksSection extends StatelessWidget {
  final AsyncValue<List<CompanyModel>> bookmarks;

  const _BookmarksSection({required this.bookmarks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHead(
          label: 'Merkliste',
          actionLabel: 'Alle anzeigen',
          onAction: () => context.go('/bookmarks'),
        ),
        const SizedBox(height: AppLayout.s16),
        bookmarks.when(
          data: (list) => list.isEmpty
              ? AppEmptyState(
                  title: 'Keine Betriebe gemerkt',
                  description:
                      'Speichere Betriebe, die dich interessieren, um sie '
                      'später wiederzufinden.',
                  actionLabel: 'Betriebe entdecken',
                  onAction: () => context.go('/search'),
                )
              : AppRowGroup(
                  children: [
                    for (final company in list.take(3))
                      AppRow(
                        icon: Icons.business_outlined,
                        title: company.name,
                        subtitle: company.location.isNotEmpty
                            ? company.location
                            : (company.industry ?? 'Ohne Angabe'),
                        onTap: () => context.go('/company/${company.slug}'),
                      ),
                  ],
                ),
          loading: () => const _SectionLoading(),
          error: (_, __) => const _SectionError(
            text: 'Deine Merkliste konnte nicht geladen werden.',
          ),
        ),
      ],
    );
  }
}

// ─── Bausteine ───────────────────────────────────────────────────────────────

class _SectionHead extends StatelessWidget {
  final String label;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHead({
    required this.label,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SectionLabel(label)),
        const SizedBox(width: AppLayout.s16),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

/// Platzhalter in der Höhe des späteren Inhalts, damit die Seite beim Laden
/// nicht springt.
class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child:
            CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  final String text;

  const _SectionError({required this.text});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: AppColors.accentDark),
          const SizedBox(width: AppLayout.s8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
