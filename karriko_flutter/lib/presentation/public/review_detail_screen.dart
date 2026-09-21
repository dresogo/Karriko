import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/public_review.dart';
import '../../providers/review_provider.dart';
import '../common/app_bar_widget.dart';
import '../common/public_review_card.dart';

/// Eine einzelne Bewertung in voller Länge.
///
/// Zeigt dasselbe Widget wie die Vorschau vor dem Absenden — was der Azubi
/// dort gesehen hat, steht hier. Das ist der ganze Punkt: Auf Karriko sind
/// Einzelbewertungen anklickbar, und wenn sich Vorschau und Veröffentlichung
/// unterscheiden, hat die Vorschau gelogen.
class ReviewDetailScreen extends ConsumerWidget {
  final String id;

  const ReviewDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(reviewByIdProvider(id));

    return Scaffold(
      appBar: const KarrikoAppBar(),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: ContentBand(
          padding: const EdgeInsets.only(
            top: AppLayout.s32,
            bottom: AppLayout.s64,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: review.when(
              data: (eintrag) => _Inhalt(review: eintrag),
              loading: () => const Center(child: CircularProgressIndicator()),
              // Nicht gefunden heißt hier nicht unbedingt „gibt es nicht":
              // Eine frisch abgeschickte Bewertung liegt noch in der
              // Moderation und ist deshalb nicht öffentlich.
              error: (_, __) => const _NichtSichtbar(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Inhalt extends StatelessWidget {
  final PublicReview review;

  const _Inhalt({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (review.companySlug != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.go('/company/${review.companySlug}'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(review.companyName ?? 'Zum Betrieb'),
            ),
          ),
        const SizedBox(height: AppLayout.s16),
        PublicReviewCard(review: review, zeigeBetrieb: true),
        if (review.isAged) ...[
          const SizedBox(height: AppLayout.s24),
          const _Hinweis(
            text: 'Diese Bewertung ist älter als drei Jahre. '
                'Ausbildungsqualität hängt oft an einzelnen Personen und '
                'ändert sich mit deren Wechsel — sie beschreibt womöglich '
                'einen anderen Betrieb als den heutigen.',
          ),
        ],
      ],
    );
  }
}

class _NichtSichtbar extends StatelessWidget {
  const _NichtSichtbar();

  @override
  Widget build(BuildContext context) {
    return const _Hinweis(
      text: 'Diese Bewertung ist gerade nicht öffentlich. Entweder liegt sie '
          'noch in der Prüfung, oder es gibt sie nicht.',
    );
  }
}

class _Hinweis extends StatelessWidget {
  final String text;

  const _Hinweis({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border.all(color: AppColors.line),
      ),
      child: Text(text, style: const TextStyle(height: 1.55)),
    );
  }
}
