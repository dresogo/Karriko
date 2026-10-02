import 'package:flutter/material.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

import '../../../core/theme/app_theme.dart';
import '../question_context.dart';

/// Ein Bildschirm, der nur etwas mitteilt — die Anlaufstellen am Ende des
/// Konfliktmoduls etwa.
///
/// Der Text steht unter einem Schlüssel in `texts`, nicht an der Frage: Er
/// erscheint an mehreren Stellen und darf nicht auseinanderlaufen.
class IntroScreen extends StatelessWidget {
  final QuestionContext context;

  const IntroScreen({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    final key = context.config<String>('textKey');
    final einzeln = key == null ? null : context.sharedText(key);
    final liste = key == null ? const <String>[] : context.sharedTextList(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (einzeln != null)
          Text(einzeln, style: const TextStyle(fontSize: 17, height: 1.55)),
        for (final eintrag in liste)
          Padding(
            padding: const EdgeInsets.only(bottom: AppLayout.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: AppLayout.s8),
                  child: Icon(Icons.arrow_right, size: 18),
                ),
                Expanded(
                  child: Text(
                    eintrag,
                    style: const TextStyle(fontSize: 17, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Die Anonymitätszusage.
///
/// Sie steht nicht nur einmal im Intro, sondern erneut direkt vor jedem
/// sensiblen Block — und zwar mit der genauen Aussage, was der Betrieb sieht
/// und was nicht. Eine allgemeine Beteuerung am Anfang hat niemand mehr im
/// Kopf, wenn die unangenehme Frage kommt.
class AnonymityNotice extends StatelessWidget {
  final QuestionContext context;

  const AnonymityNotice({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 20),
          const SizedBox(width: AppLayout.s16),
          Expanded(child: IntroScreen(context: context)),
        ],
      ),
    );
  }
}

/// Der Teaser vor einem Modul: wie viele Fragen, wie lange ungefähr.
///
/// Phase 2 wird nicht als Pflichtstrecke angekündigt, sondern modulweise
/// angeboten. Wer vorher weiß, worauf er sich einlässt, bricht seltener
/// mittendrin ab — und wer ablehnt, hat trotzdem eine vollständige Bewertung
/// abgegeben.
class ModuleTeaserScreen extends StatelessWidget {
  final QuestionContext context;

  /// Aus der Ablaufsteuerung, nicht geschätzt.
  final ModuleTeaser teaser;

  const ModuleTeaserScreen({
    super.key,
    required this.context,
    required this.teaser,
  });

  @override
  Widget build(BuildContext buildContext) {
    final modul = teaser.module;
    final minuten = (teaser.estimatedSeconds / 60).ceil();
    final dauer = teaser.estimatedSeconds < 60
        ? '${teaser.estimatedSeconds} Sek.'
        : '$minuten Min.';

    final annehmen = modul.acceptLabel?.forTense(context.tense) ??
        context.sharedText('module.accept') ??
        '';
    final ueberspringen = modul.skipLabel?.forTense(context.tense) ??
        context.sharedText('module.skip') ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Zahl(text: '${teaser.questionCount}', label: 'Fragen'),
            const SizedBox(width: AppLayout.s24),
            _Zahl(text: dauer, label: 'ungefähr'),
          ],
        ),
        const SizedBox(height: AppLayout.s32),
        Wrap(
          spacing: AppLayout.s16,
          runSpacing: AppLayout.s8,
          children: [
            ElevatedButton(
              onPressed: () {
                context.onChanged(Module.acceptValue);
                context.onAdvance();
              },
              child: Text(annehmen),
            ),
            OutlinedButton(
              onPressed: () {
                context.onChanged(Module.skipValue);
                context.onAdvance();
              },
              child: Text(ueberspringen),
            ),
          ],
        ),
      ],
    );
  }
}

class _Zahl extends StatelessWidget {
  final String text;
  final String label;

  const _Zahl({required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}
