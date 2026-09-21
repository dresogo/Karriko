import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../common/public_review_card.dart';
import '../preview_projection.dart';
import '../question_context.dart';

/// Die Vorschau aus A4.
///
/// Nicht optional, und zwar aus einem Grund: Auf Karriko sind Einzelbewertungen
/// anklickbar. Wer nicht vorher sieht, was davon öffentlich wird, entdeckt es
/// hinterher — und dann entsteht genau das Vertrauensproblem, das die Plattform
/// lösen will.
///
/// Darunter steht, was **nicht** sichtbar wird. Jeder öffentliche Block lässt
/// sich einzeln zurücknehmen; es ist nicht alles oder nichts.
class PreviewScreen extends StatelessWidget {
  final QuestionContext context;
  final PreviewProjection projektion;

  /// Welche Blöcke zurückgenommen sind. Steckt in der Antwort auf diese Frage,
  /// damit die Entscheidung im Entwurf mitläuft und beim Absenden mitgeht.
  final Set<String> zurueckgenommen;

  final void Function(Set<String> bloecke) onZurueckgenommen;

  const PreviewScreen({
    super.key,
    required this.context,
    required this.projektion,
    required this.zurueckgenommen,
    required this.onZurueckgenommen,
  });

  @override
  Widget build(BuildContext buildContext) {
    final bloecke = projektion.bloecke;
    final nichtSichtbar = projektion.nichtSichtbar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PublicReviewCard(review: projektion.build(), vorschau: true),
        if (bloecke.isNotEmpty) ...[
          const SizedBox(height: AppLayout.s32),
          for (final block in bloecke)
            _Block(
              label: block.label,
              zurueckgenommen: zurueckgenommen.contains(block.id),
              zuruecknehmenLabel:
                  context.sharedText('ui.preview_withdraw') ?? '',
              wiederLabel: context.sharedText('ui.preview_restore') ?? '',
              onUmschalten: () {
                final neu = {...zurueckgenommen};
                if (!neu.remove(block.id)) neu.add(block.id);
                onZurueckgenommen(neu);
              },
            ),
        ],
        if (nichtSichtbar.isNotEmpty) ...[
          const SizedBox(height: AppLayout.s32),
          Container(
            padding: const EdgeInsets.all(AppLayout.s24),
            decoration: BoxDecoration(
              color: AppColors.audienceBeige,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (context.sharedText('ui.preview_hidden') ?? '').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.96,
                  ),
                ),
                const SizedBox(height: AppLayout.s16),
                for (final eintrag in nichtSichtbar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3, right: AppLayout.s8),
                          child: Icon(Icons.visibility_off_outlined, size: 15),
                        ),
                        Expanded(child: Text(eintrag)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Block extends StatelessWidget {
  final String label;
  final bool zurueckgenommen;
  final String zuruecknehmenLabel;
  final String wiederLabel;
  final VoidCallback onUmschalten;

  const _Block({
    required this.label,
    required this.zurueckgenommen,
    required this.zuruecknehmenLabel,
    required this.wiederLabel,
    required this.onUmschalten,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: zurueckgenommen ? AppColors.muted : AppColors.ink,
                decoration:
                    zurueckgenommen ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          TextButton(
            onPressed: onUmschalten,
            child: Text(zurueckgenommen ? wiederLabel : zuruecknehmenLabel),
          ),
        ],
      ),
    );
  }
}
