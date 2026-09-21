import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

import '../../core/constants/questionnaire_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/company_provider.dart';
import '../../providers/questionnaire_provider.dart';
import '../../providers/questionnaire_run_provider.dart';
import '../common/app_bar_widget.dart';
import 'phase_progress.dart';
import 'preview_projection.dart';
import 'question_context.dart';
import 'widget_registry.dart';
import 'widgets/info_widgets.dart';
import 'widgets/preview_widget.dart';
import 'widgets/verification_widget.dart';

/// Der Fragebogen: eine Frage pro Bildschirm.
///
/// Ohne Betrieb in der Adresse steht zuerst die Auswahl. Mit Betrieb läuft der
/// Bogen — und zwar genau so, wie [QuestionnaireFlow] ihn aus Definition und
/// Antworten errechnet. Dieser Bildschirm entscheidet nichts über die Strecke;
/// er zeigt sie an.
class QuestionnaireScreen extends ConsumerWidget {
  final String? companyId;

  /// Einladungsquelle aus dem Query-Parameter `src`.
  final String? inviteSource;

  const QuestionnaireScreen({super.key, this.companyId, this.inviteSource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (companyId == null) {
      return const _BetriebWaehlen();
    }

    final betrieb = ref.watch(companyByIdProvider(companyId!));

    return betrieb.when(
      data: (firma) => _Durchlauf(
        schluessel: (
          companyId: firma.id,
          companyName: firma.name,
          inviteSource: _gueltigeQuelle(inviteSource),
        ),
      ),
      loading: () => const _Geruest(child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const _Geruest(
        child: _Meldung(
          text: 'Dieser Betrieb wurde nicht gefunden. Such ihn noch einmal '
              'über die Betriebsauswahl.',
        ),
      ),
    );
  }

  /// Eine Einladungsquelle zählt nur, wenn sie in der Liste steht.
  ///
  /// Wer über eine Einladung kommt, wird intern markiert, weil diese Stichprobe
  /// repräsentativer ist. Ohne diese Prüfung ließe sich die Markierung über
  /// eine selbstgebaute Adresse erschleichen — und dann wäre sie wertlos.
  static String? _gueltigeQuelle(String? roh) {
    if (roh == null) return null;
    return QuestionnaireConstants.inviteSources.contains(roh) ? roh : null;
  }
}

// ── Betriebsauswahl ──────────────────────────────────────────────────────────

class _BetriebWaehlen extends ConsumerStatefulWidget {
  const _BetriebWaehlen();

  @override
  ConsumerState<_BetriebWaehlen> createState() => _BetriebWaehlenState();
}

class _BetriebWaehlenState extends ConsumerState<_BetriebWaehlen> {
  final _suche = TextEditingController();

  @override
  void dispose() {
    _suche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final treffer = ref.watch(searchProvider);

    return _Geruest(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welchen Betrieb möchtest du bewerten?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppLayout.s24),
          TextField(
            controller: _suche,
            autofocus: true,
            onSubmitted: (wert) => ref
                .read(searchProvider.notifier)
                .search(SearchFilters(query: wert)),
            decoration: InputDecoration(
              hintText: 'Betrieb suchen',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => ref
                    .read(searchProvider.notifier)
                    .search(SearchFilters(query: _suche.text)),
              ),
            ),
          ),
          const SizedBox(height: AppLayout.s24),
          if (treffer.isLoading) const LinearProgressIndicator(),
          for (final firma in treffer.results)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(firma.name),
              subtitle: Text(firma.location),
              trailing: const Icon(Icons.arrow_forward),
              // Die Kennung geht in die Adresse, der Name nicht: Eine URL
              // bleibt im Verlauf des Browsers stehen.
              onTap: () => context.go('/reviews/new?company=${firma.id}'),
            ),
          if (!treffer.isLoading &&
              treffer.filters.hasFilters &&
              treffer.results.isEmpty)
            const _Meldung(
              text: 'Kein Treffer. Vielleicht ist der Betrieb noch nicht auf '
                  'Karriko — dann lässt er sich hier noch nicht bewerten.',
            ),
        ],
      ),
    );
  }
}

// ── Der Durchlauf ────────────────────────────────────────────────────────────

class _Durchlauf extends ConsumerWidget {
  final QuestionnaireRunKey schluessel;

  const _Durchlauf({required this.schluessel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(questionnaireRunProvider(schluessel));
    final steuerung = ref.read(questionnaireRunProvider(schluessel).notifier);

    if (stand.loading) {
      return const _Geruest(child: Center(child: CircularProgressIndicator()));
    }
    if (stand.loadError != null) {
      return _Geruest(child: _Meldung(text: stand.loadError!));
    }
    if (stand.submitted) {
      return _Fertig(stand: stand);
    }

    final frage = steuerung.currentQuestion;
    if (frage == null) {
      return _Absenden(schluessel: schluessel);
    }

    return _Frage(schluessel: schluessel, frage: frage);
  }
}

class _Frage extends ConsumerWidget {
  final QuestionnaireRunKey schluessel;
  final Question frage;

  const _Frage({required this.schluessel, required this.frage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(questionnaireRunProvider(schluessel));
    final steuerung = ref.read(questionnaireRunProvider(schluessel).notifier);
    final questionnaire = stand.questionnaire!;
    final tense = steuerung.tense;

    final ctx = QuestionContext(
      question: frage,
      answer: stand.answers[frage.id],
      tense: tense,
      questionnaire: questionnaire,
      onChanged: (wert) => steuerung.answer(frage.id, wert),
      onAdvance: () {
        if (!steuerung.next()) {
          // Am Ende angekommen: Der Bildschirm wechselt von selbst auf das
          // Absenden, weil currentQuestion dann null ist.
          steuerung.saveDraft();
        }
      },
    );

    final eingabe = _eingabeFuer(context, ref, ctx, stand, steuerung);

    // Ein unbekannter Typ wird im Release übersprungen. Das passiert hier und
    // nicht in der Registry, weil nur der Bildschirm weiterblättern kann.
    if (eingabe == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => steuerung.next());
      return const _Geruest(child: Center(child: CircularProgressIndicator()));
    }

    final anonymitaet = frage.sensitive
        ? ctx.sharedText('anonymity.sensitive')
        : null;

    return _Geruest(
      fortschritt: PhaseProgressBar(
        questionnaire: questionnaire,
        fortschritt: steuerung.flow.allProgress(stand.answers),
        aktuellePhase: frage.phase,
        tense: tense,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (anonymitaet != null) ...[
            _AnonymitaetsBand(text: anonymitaet),
            const SizedBox(height: AppLayout.s24),
          ],
          if (ctx.intro != null) ...[
            // Die normalisierende Einleitung steht über der Frage, nicht auf
            // einem eigenen Bildschirm: Sie wirkt nur, wenn sie beim Antworten
            // noch zu sehen ist.
            Container(
              padding: const EdgeInsets.all(AppLayout.s16),
              decoration: const BoxDecoration(color: AppColors.audienceBeige),
              child: Text(
                ctx.intro!,
                style: const TextStyle(height: 1.55),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
          ],
          Text(ctx.text, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppLayout.s32),
          eingabe,
          const SizedBox(height: AppLayout.s48),
          _Navigation(schluessel: schluessel, frage: frage, ctx: ctx),
        ],
      ),
    );
  }

  /// Die vier Typen, die mehr brauchen als die Frage selbst.
  Widget? _eingabeFuer(
    BuildContext context,
    WidgetRef ref,
    QuestionContext ctx,
    QuestionnaireRunState stand,
    QuestionnaireRunNotifier steuerung,
  ) {
    switch (frage.type) {
      case 'intro':
        return IntroScreen(context: ctx);

      case 'anonymity_notice':
        return AnonymityNotice(context: ctx);

      case 'module_teaser':
        final modulId = frage.config['moduleId'];
        final modul = modulId is String
            ? stand.questionnaire!.module(modulId)
            : null;
        if (modul == null) return null;
        return ModuleTeaserScreen(
          context: ctx,
          teaser: steuerung.flow.teaserFor(modul, stand.answers),
        );

      case 'preview':
        final zurueckgenommen = <String>{
          for (final eintrag in (stand.answers[frage.id] as List? ?? const []))
            if (eintrag is String) eintrag,
        };
        return PreviewScreen(
          context: ctx,
          zurueckgenommen: zurueckgenommen,
          projektion: PreviewProjection(
            questionnaire: stand.questionnaire!,
            answers: stand.answers,
            companyId: schluessel.companyId,
            companyName: schluessel.companyName,
            zurueckgenommen: zurueckgenommen,
          ),
          onZurueckgenommen: (bloecke) =>
              steuerung.answer(frage.id, bloecke.toList()),
        );

      case 'verification':
        return VerificationUpload(
          context: ctx,
          fileId: stand.verificationFileId,
          onUpload: (datei) async {
            final id = await ref.read(verificationRepositoryProvider).upload(
                  bytes: datei.bytes,
                  filename: datei.name,
                  contentType: datei.contentType,
                );
            steuerung.setVerificationFile(id);
            return id;
          },
        );
    }

    return QuestionWidgetRegistry.buildOrNull(ctx);
  }
}

class _Navigation extends ConsumerWidget {
  final QuestionnaireRunKey schluessel;
  final Question frage;
  final QuestionContext ctx;

  const _Navigation({
    required this.schluessel,
    required this.frage,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(questionnaireRunProvider(schluessel));
    final steuerung = ref.read(questionnaireRunProvider(schluessel).notifier);
    final beantwortet = stand.answers.isAnswered(frage.id);

    return Row(
      children: [
        if (steuerung.flow.before(stand.answers, frage.id) != null)
          OutlinedButton.icon(
            onPressed: steuerung.back,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text(ctx.sharedText('ui.back') ?? ''),
          ),
        const Spacer(),
        // Eine Pflichtfrage lässt sich nicht überspringen; alles andere schon.
        // Wer nichts sagen will, soll nicht hängenbleiben — eine erzwungene
        // Antwort ist keine Antwort.
        if (!frage.required && !beantwortet)
          TextButton(
            onPressed: () {
              steuerung.answer(frage.id, null);
              steuerung.next();
            },
            child: Text(ctx.sharedText('ui.skip_question') ?? ''),
          ),
        if (beantwortet || frage.type == 'intro' || frage.type == 'anonymity_notice')
          Padding(
            padding: const EdgeInsets.only(left: AppLayout.s16),
            child: ElevatedButton.icon(
              onPressed: () {
                if (frage.type == 'intro' || frage.type == 'anonymity_notice') {
                  steuerung.answer(frage.id, true);
                }
                steuerung.next();
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(ctx.sharedText('ui.next') ?? ''),
            ),
          ),
      ],
    );
  }
}

// ── Absenden und Ergebnis ────────────────────────────────────────────────────

class _Absenden extends ConsumerWidget {
  final QuestionnaireRunKey schluessel;

  const _Absenden({required this.schluessel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(questionnaireRunProvider(schluessel));
    final steuerung = ref.read(questionnaireRunProvider(schluessel).notifier);
    final questionnaire = stand.questionnaire!;
    final tense = steuerung.tense;

    return _Geruest(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            schluessel.companyName,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppLayout.s24),
          if (stand.submitError != null) ...[
            _Meldung(text: stand.submitError!, fehler: true),
            const SizedBox(height: AppLayout.s24),
          ],
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: steuerung.back,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(
                  questionnaire.text('ui.back')?.forTense(tense) ?? '',
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: stand.submitting ? null : steuerung.submit,
                child: stand.submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        questionnaire.text('ui.submit')?.forTense(tense) ?? '',
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fertig extends StatelessWidget {
  final QuestionnaireRunState stand;

  const _Fertig({required this.stand});

  @override
  Widget build(BuildContext context) {
    final ergebnis = stand.result!;
    final verschoben = ergebnis.status == 'scheduled';

    return _Geruest(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: AppColors.green),
          const SizedBox(height: AppLayout.s24),
          Text(
            verschoben ? 'Gespeichert' : 'Danke',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppLayout.s16),
          Text(
            verschoben
                ? 'Deine Bewertung ist gespeichert und geht später in die '
                    'Prüfung. Bis dahin kannst du sie noch ändern.'
                : 'Deine Bewertung geht jetzt in die Prüfung. Sobald sie '
                    'freigegeben ist, erscheint sie im Profil des Betriebs.',
            style: const TextStyle(fontSize: 17, height: 1.55),
          ),
          const SizedBox(height: AppLayout.s32),
          ElevatedButton(
            onPressed: () => context.go('/my-reviews'),
            child: const Text('Zu meinen Bewertungen'),
          ),
        ],
      ),
    );
  }
}

// ── Gerüst ───────────────────────────────────────────────────────────────────

class _Geruest extends StatelessWidget {
  final Widget child;
  final Widget? fortschritt;

  const _Geruest({required this.child, this.fortschritt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Betrieb bewerten'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: ContentBand(
          padding: const EdgeInsets.only(
            top: AppLayout.s32,
            bottom: AppLayout.s64,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fortschritt != null) ...[
                  fortschritt!,
                  const SizedBox(height: AppLayout.s32),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnonymitaetsBand extends StatelessWidget {
  final String text;

  const _AnonymitaetsBand({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 18),
          const SizedBox(width: AppLayout.s8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.55))),
        ],
      ),
    );
  }
}

class _Meldung extends StatelessWidget {
  final String text;
  final bool fehler;

  const _Meldung({required this.text, this.fehler = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(
        color: fehler ? AppColors.primaryLight : AppColors.surface,
        border: Border.all(color: fehler ? AppColors.accent : AppColors.line),
      ),
      child: Text(text, style: const TextStyle(height: 1.55)),
    );
  }
}
