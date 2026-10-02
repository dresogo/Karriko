import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/review_draft.dart';
import '../../data/services/submitted_reviews_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/questionnaire_provider.dart';
import '../../providers/review_provider.dart';
import '../common/app_bar_widget.dart';

/// Was ein Azubi von seinen eigenen Bewertungen sieht.
///
/// Zwei Listen, weil es zwei Zustände gibt:
///
/// * **Angefangen.** Entwürfe stehen in `review_drafts` und gehören ihm; sie
///   lassen sich fortsetzen, wo er aufgehört hat.
/// * **Abgeschickt.** Die stehen in `reviews`, und dorthin hat kein Client
///   Zugriff — auch er selbst nicht. `public_reviews` trägt keine `user_id`,
///   weil eine öffentlich lesbare Zeile, die auf ein Konto zeigt, keine anonyme
///   Bewertung wäre. Was hier steht, merkt sich deshalb dieses Gerät.
class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id ?? '';
    final entwuerfe = ref.watch(myDraftsProvider(userId));
    final abgeschickt = ref.watch(submittedReviewsProvider);

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Meine Bewertungen'),
      drawer: const KarrikoDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/reviews/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Neue Bewertung',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: ContentBand(
          padding: const EdgeInsets.only(
            top: AppLayout.s32,
            bottom: AppLayout.s64,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Abschnitt(
                  titel: 'Angefangen',
                  beschreibung: 'Hier kannst du weitermachen, wo du aufgehört '
                      'hast. Nur du siehst diese Entwürfe.',
                  inhalt: entwuerfe.when(
                    data: (liste) => liste.isEmpty
                        ? const _Leer(text: 'Kein offener Entwurf.')
                        : Column(
                            children: [
                              for (final entwurf in liste)
                                _EntwurfsZeile(entwurf: entwurf),
                            ],
                          ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const _Leer(
                      text: 'Deine Entwürfe konnten nicht geladen werden.',
                    ),
                  ),
                ),
                const SizedBox(height: AppLayout.s48),
                _Abschnitt(
                  titel: 'Abgeschickt',
                  beschreibung: 'Diese Liste steht nur auf diesem Gerät. Deine '
                      'Bewertungen sind mit keinem Konto verknüpft — genau '
                      'deshalb bleiben sie anonym.',
                  inhalt: abgeschickt.when(
                    data: (liste) => liste.isEmpty
                        ? const _Leer(
                            text: 'Von diesem Gerät wurde noch nichts '
                                'abgeschickt.',
                          )
                        : Column(
                            children: [
                              for (final eintrag in liste)
                                _AbgeschicktZeile(eintrag: eintrag),
                            ],
                          ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const _Leer(text: 'Nicht lesbar.'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Abschnitt extends StatelessWidget {
  final String titel;
  final String beschreibung;
  final Widget inhalt;

  const _Abschnitt({
    required this.titel,
    required this.beschreibung,
    required this.inhalt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titel.toUpperCase(),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.32,
          ),
        ),
        const SizedBox(height: AppLayout.s8),
        Text(
          beschreibung,
          style: const TextStyle(color: AppColors.muted, height: 1.55),
        ),
        const SizedBox(height: AppLayout.s24),
        inhalt,
      ],
    );
  }
}

class _EntwurfsZeile extends ConsumerWidget {
  final ReviewDraft entwurf;

  const _EntwurfsZeile({required this.entwurf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.s8),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: ListTile(
        title: Text('${entwurf.answers.length} Antworten'),
        subtitle: Text(
          'Zuletzt bearbeitet am '
          '${DateFormat('dd.MM.yyyy').format(entwurf.updatedAt)}',
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => context.go('/reviews/new?company=${entwurf.companyId}'),
      ),
    );
  }
}

class _AbgeschicktZeile extends StatelessWidget {
  final SubmittedReview eintrag;

  const _AbgeschicktZeile({required this.eintrag});

  @override
  Widget build(BuildContext context) {
    final wartet = eintrag.status == 'scheduled';

    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.s8),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: ListTile(
        title: Text(eintrag.companyName),
        subtitle: Text(
          wartet
              ? 'Gespeichert, geht später in die Prüfung'
              : 'Abgeschickt am '
                  '${DateFormat('dd.MM.yyyy').format(eintrag.submittedAt)} · '
                  'in Prüfung',
        ),
        trailing: const Icon(Icons.arrow_forward),
        // Der Verweis geht auf die öffentliche Ansicht. Solange die Bewertung
        // in der Moderation liegt, gibt es dort noch nichts zu sehen — das ist
        // ehrlicher als eine eigene Vorschau, die etwas anderes zeigt.
        onTap: () => context.go('/reviews/${eintrag.reviewId}'),
      ),
    );
  }
}

class _Leer extends StatelessWidget {
  final String text;

  const _Leer({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Text(text, style: const TextStyle(color: AppColors.muted)),
    );
  }
}
