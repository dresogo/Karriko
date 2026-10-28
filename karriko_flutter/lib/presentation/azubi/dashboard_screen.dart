import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/review_draft.dart';
import '../../providers/auth_provider.dart';
import '../../providers/questionnaire_provider.dart';
import '../../providers/review_provider.dart';
import '../common/app_page.dart';
import 'own_review_status.dart';

class AzubiDashboardScreen extends ConsumerWidget {
  const AzubiDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final userId = auth.user?.id ?? '';
    final myReviews = ref.watch(myDraftsProvider(userId));

    return AppPage(
      appBarTitle: 'Dashboard',
      eyebrow: 'DASHBOARD',
      title: 'Hallo, ${auth.user?.displayName ?? 'Azubi'}.',
      lede: 'Deine Bewertungen und Entwürfe auf einen Blick.',
      headerAction: FilledButton.icon(
        onPressed: () => context.go('/reviews/new'),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Bewertung schreiben'),
      ),
      children: [
        _Stats(reviews: myReviews),
        const SizedBox(height: AppLayout.s48),
        const _SubmittedSection(),
        const SizedBox(height: AppLayout.s48),
        _ReviewsSection(reviews: myReviews),
      ],
    );
  }
}

// ─── Kennzahlen ──────────────────────────────────────────────────────────────

class _Stats extends StatelessWidget {
  final AsyncValue<List<ReviewDraft>> reviews;

  const _Stats({required this.reviews});

  /// Zeigt Werte erst, wenn sie geladen sind – ein Strich ist ehrlicher als
  /// eine Null, die nach dem Laden auf etwas anderes springt.
  String _count(AsyncValue<List<Object>> value) =>
      value.maybeWhen(data: (list) => '${list.length}', orElse: () => '–');

  /// Kein Durchschnitt mehr.
  ///
  /// Abgeschickte Bewertungen sind keinem Konto zugeordnet — `public_reviews`
  /// traegt keine `user_id`, und `reviews` ist fuer Clients gesperrt. Ein
  /// Mittelwert ueber die eigenen Bewertungen laesst sich damit nicht bilden,
  /// und einen ueber die Entwuerfe zu zeigen waere eine erfundene Zahl.
  String get _offeneEntwuerfe => _count(reviews);

  @override
  Widget build(BuildContext context) {
    const gap = AppLayout.s24;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 720 ? 2 : 1;
        final width = (constraints.maxWidth - (cols - 1) * gap) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: StatTile(
                  value: _offeneEntwuerfe, label: 'Angefangene Bewertungen'),
            ),
          ],
        );
      },
    );
  }
}

// ─── Bewertungen ─────────────────────────────────────────────────────────────

/// Die abgeschickten Bewertungen mit ihrem Stand (T-6.34). Dieselben Texte
/// wie unter „Meine Bewertungen“, damit ein Zustand nicht zwei Namen hat.
class _SubmittedSection extends ConsumerWidget {
  const _SubmittedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eigene = ref.watch(ownReviewsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHead(
          label: 'Abgeschickte Bewertungen',
          actionLabel: 'Alle anzeigen',
          onAction: () => context.go('/my-reviews'),
        ),
        const SizedBox(height: AppLayout.s16),
        eigene.when(
          data: (ergebnis) => ergebnis.reviews.isEmpty
              ? Text(
                  'Noch keine Bewertung abgeschickt.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : AppRowGroup(
                  children: [
                    for (final eintrag in ergebnis.reviews.take(3))
                      AppRow(
                        icon: Icons.rate_review_outlined,
                        title: eintrag.companyName ?? 'Betrieb',
                        subtitle: ownReviewStatusText(eintrag),
                        onTap: () => context.go('/my-reviews'),
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

class _ReviewsSection extends StatelessWidget {
  final AsyncValue<List<ReviewDraft>> reviews;

  const _ReviewsSection({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHead(
          label: 'Angefangene Bewertungen',
          actionLabel: 'Alle anzeigen',
          onAction: () => context.go('/my-reviews'),
        ),
        const SizedBox(height: AppLayout.s16),
        reviews.when(
          data: (list) => list.isEmpty
              ? AppEmptyState(
                  title: 'Kein offener Entwurf',
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
                        icon: Icons.edit_outlined,
                        title: '${review.answers.length} Antworten',
                        subtitle: draftDeletionText(review),
                        onTap: () => context
                            .go('/reviews/new?company=${review.companyId}'),
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
