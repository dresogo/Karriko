import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/own_review.dart';
import '../../data/models/review_draft.dart';
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
///   Bewertung wäre. Den Weg dorthin öffnet allein die Function `my_reviews`:
///   Sie stellt die Zuordnung her, aber nur lesend und nur für die Dauer eines
///   Aufrufs. Antwortet sie nicht, bleibt die lokale Liste als Rückfall — und
///   dann steht auch dort, dass sie nur dieses Gerät kennt.
class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id ?? '';
    final entwuerfe = ref.watch(myDraftsProvider(userId));
    final abgeschickt = ref.watch(ownReviewsProvider);

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
                  beschreibung: 'Deine Bewertungen sind öffentlich mit keinem '
                      'Konto verknüpft — genau deshalb bleiben sie anonym. '
                      'Diese Liste siehst nur du.',
                  inhalt: abgeschickt.when(
                    data: (ergebnis) => ergebnis.reviews.isEmpty
                        ? _Leer(
                            text: ergebnis.vomGeraet
                                ? 'Von diesem Gerät wurde noch nichts '
                                    'abgeschickt.'
                                : 'Du hast noch keine Bewertung abgeschickt.',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (ergebnis.vomGeraet) const _NurDiesesGeraet(),
                              for (final eintrag in ergebnis.reviews)
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

/// Der Hinweis, wenn die Liste aus dem Browser kommt statt vom Server.
///
/// Er steht da, weil die beiden nicht gleichwertig sind: Die lokale Liste kennt
/// nur dieses Gerät und weiß nichts über den Stand der Moderation. Sie als
/// vollständig darzustellen wäre eine Behauptung, die nicht stimmt.
class _NurDiesesGeraet extends StatelessWidget {
  const _NurDiesesGeraet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.s16),
      padding: const EdgeInsets.all(AppLayout.s16),
      color: AppColors.audienceBeige,
      child: const Text(
        'Der Server war gerade nicht erreichbar. Diese Liste kommt aus diesem '
        'Browser — sie kann unvollständig sein und zeigt nicht, wie weit die '
        'Prüfung ist.',
        style: TextStyle(color: AppColors.ink, fontSize: 14),
      ),
    );
  }
}

class _AbgeschicktZeile extends StatelessWidget {
  final OwnReview eintrag;

  const _AbgeschicktZeile({required this.eintrag});

  /// Was unter dem Betriebsnamen steht.
  ///
  /// Die vier Zustände bekommen vier Texte. Eine zurückgestellte Bewertung sähe
  /// sonst wie eine verschollene aus, und eine abgelehnte wie eine, die noch
  /// geprüft wird.
  String _lage() {
    final datum = DateFormat('dd.MM.yyyy').format(eintrag.submittedAt);

    if (eintrag.istZurueckgestellt) {
      if (eintrag.publishAfterTrainingEnd) {
        return 'Gespeichert · geht nach deinem Ausbildungsende in die Prüfung';
      }
      final ab = eintrag.publishAfter;
      return ab == null
          ? 'Gespeichert · geht später in die Prüfung'
          : 'Gespeichert · geht am ${DateFormat('dd.MM.yyyy').format(ab)} '
              'in die Prüfung';
    }

    if (eintrag.istFreigegeben) {
      final seit = eintrag.publishedAt;
      return seit == null
          ? 'Veröffentlicht'
          : 'Veröffentlicht am ${DateFormat('dd.MM.yyyy').format(seit)}';
    }

    if (eintrag.istAbgelehnt) return 'Nicht veröffentlicht';

    return 'Abgeschickt am $datum · in Prüfung';
  }

  @override
  Widget build(BuildContext context) {
    // Verlinkt wird nur, was es öffentlich gibt. Ein Verweis auf eine Seite,
    // die noch nichts zeigt, ist kein Verweis.
    final ziel = eintrag.publicReviewId;

    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.s8),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(eintrag.companyName ?? 'Betrieb'),
            subtitle: Text(_lage()),
            trailing: ziel == null
                ? null
                : const Icon(Icons.arrow_forward, semanticLabel: 'Ansehen'),
            onTap: ziel == null ? null : () => context.go('/reviews/$ziel'),
          ),
          // Die Begründung einer Ablehnung gehört dem Verfasser. `moderate_review`
          // verlangt sie genau deshalb — hier kommt sie bei ihm an. Wer
          // entschieden hat, steht nicht dabei.
          if (eintrag.istAbgelehnt && eintrag.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.s16,
                0,
                AppLayout.s16,
                AppLayout.s16,
              ),
              child: Text(
                'Begründung: ${eintrag.rejectionReason}',
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ),
        ],
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
