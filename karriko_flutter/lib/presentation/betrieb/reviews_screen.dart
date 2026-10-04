import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/company_provider.dart';
import '../../providers/review_provider.dart';
import '../common/app_bar_widget.dart';
import '../common/public_review_card.dart';

/// Was ein Betrieb über sich liest.
///
/// Genau das, was jeder Besucher auch sieht — nicht mehr. Es gibt hier keine
/// Angabe, die der Öffentlichkeit verborgen bleibt, und keine, die auf einen
/// Bewerter zeigt.
///
/// **Ohne Antwortfunktion.** Ob Betriebe auf Bewertungen antworten dürfen, ist
/// in Abschnitt 11 der Spezifikation ausdrücklich offen: Die Möglichkeit
/// verändert das Antwortverhalten der Azubis spürbar, weil sie mit einer
/// Reaktion rechnen. Solange die Frage offen ist, wird sie nicht durch eine
/// gebaute Funktion entschieden.
class BetriebReviewsScreen extends ConsumerWidget {
  const BetriebReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firma = ref.watch(myCompanyProvider);

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Bewertungen'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: ContentBand(
          padding: const EdgeInsets.only(
            top: AppLayout.s32,
            bottom: AppLayout.s64,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: firma.when(
              data: (betrieb) => betrieb == null
                  ? const _Hinweis(
                      text: 'Zu diesem Konto gehört noch kein Betrieb.',
                    )
                  : _Liste(companyId: betrieb.id),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _Hinweis(
                text: 'Die Unternehmensdaten konnten nicht geladen werden.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Liste extends ConsumerWidget {
  final String companyId;

  const _Liste({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(companyReviewsProvider(companyId));
    final scores = ref.watch(companyScoresProvider(companyId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        scores.when(
          data: (werte) => werte == null || !werte.scoreVisible
              ? const _Hinweis(
                  text: 'Ein Gesamtscore erscheint ab drei Bewertungen. '
                      'Bis dahin stünde er auf zu wenig Grundlage.',
                )
              : _Ueberblick(
                  overall: werte.overall,
                  anzahl: werte.reviewCount,
                  alt: werte.agedCount,
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppLayout.s32),
        reviews.when(
          data: (liste) => liste.isEmpty
              ? const _Hinweis(text: 'Noch keine freigegebene Bewertung.')
              : Column(
                  children: [
                    for (final review in liste)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppLayout.s16),
                        child: PublicReviewCard(review: review),
                      ),
                  ],
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _Hinweis(
            text: 'Die Bewertungen konnten nicht geladen werden.',
          ),
        ),
      ],
    );
  }
}

class _Ueberblick extends StatelessWidget {
  final double? overall;
  final int anzahl;
  final int alt;

  const _Ueberblick({
    required this.overall,
    required this.anzahl,
    required this.alt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overall != null)
            ScoreBalken(label: 'Gesamt', wert: overall!, betont: true),
          const SizedBox(height: AppLayout.s8),
          Text(
            alt == 0
                ? '$anzahl Bewertungen'
                : '$anzahl Bewertungen, davon $alt älter als drei Jahre',
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
        ],
      ),
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
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Text(text, style: const TextStyle(height: 1.55)),
    );
  }
}
