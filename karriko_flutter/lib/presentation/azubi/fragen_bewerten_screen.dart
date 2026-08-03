import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/question_model.dart';
import '../../providers/question_provider.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/review_card.dart';

/// Vorlage für den Fragebogen, den Azubis zu ihrem Betrieb beantworten.
///
/// Die Fragen kommen aus der Datenbank ([questionsProvider]). Das Absenden der
/// Antworten ist noch nicht angebunden – der Aufbau steht, die Persistenz folgt.
class FragenBewertenScreen extends ConsumerStatefulWidget {
  const FragenBewertenScreen({super.key});

  @override
  ConsumerState<FragenBewertenScreen> createState() =>
      _FragenBewertenScreenState();
}

class _FragenBewertenScreenState extends ConsumerState<FragenBewertenScreen> {
  /// Antworten je Frage-ID: int für Sterne, bool für Ja/Nein, String für Freitext.
  final Map<String, Object> _answers = {};

  void _setAnswer(String questionId, Object value) {
    setState(() => _answers[questionId] = value);
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(questionsProvider);

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Fragen bewerten'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentBand(
              padding: const EdgeInsets.only(
                top: AppLayout.s48,
                bottom: AppLayout.s64,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FRAGEBOGEN',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.32,
                      ),
                    ),
                    const SizedBox(height: AppLayout.s16),
                    Text(
                      'Deinen Betrieb bewerten',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppLayout.s16),
                    const Text(
                      'Beantworte die Fragen zu deinem Ausbildungsbetrieb. Deine '
                      'Antworten werden anonym ausgewertet.',
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 17, height: 1.55),
                    ),
                    const SizedBox(height: AppLayout.s48),
                    questions.when(
                      data: (list) => _QuestionList(
                        questions: list,
                        answers: _answers,
                        onAnswer: _setAnswer,
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppLayout.s48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const _ErrorBox(),
                    ),
                    const SizedBox(height: AppLayout.s32),
                    questions.maybeWhen(
                      data: (list) => Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/dashboard'),
                            child: const Text('Abbrechen'),
                          ),
                          const SizedBox(width: AppLayout.s16),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${_answers.length} von ${list.length} Fragen beantwortet. '
                                    'Das Speichern wird noch angebunden.',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Antworten absenden'),
                          ),
                        ],
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

class _QuestionList extends StatelessWidget {
  final List<QuestionModel> questions;
  final Map<String, Object> answers;
  final void Function(String questionId, Object value) onAnswer;

  const _QuestionList({
    required this.questions,
    required this.answers,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppLayout.s24),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
        child: Text(
          'Aktuell sind keine Fragen hinterlegt.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Nach Kategorie gruppieren, Reihenfolge der Liste bleibt erhalten.
    final grouped = <String, List<QuestionModel>>{};
    for (final q in questions) {
      grouped.putIfAbsent(q.category, () => []).add(q);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Text(
            entry.key.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.96,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < entry.value.length; i++) ...[
                  if (i > 0) const Divider(color: AppColors.line, height: 1),
                  _QuestionTile(
                    question: entry.value[i],
                    answer: answers[entry.value[i].id],
                    onAnswer: (v) => onAnswer(entry.value[i].id, v),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppLayout.s32),
        ],
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final QuestionModel question;
  final Object? answer;
  final ValueChanged<Object> onAnswer;

  const _QuestionTile({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppLayout.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.isRequired ? '${question.text} *' : question.text,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (question.hint != null) ...[
            const SizedBox(height: AppLayout.s8),
            Text(question.hint!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: AppLayout.s16),
          switch (question.type) {
            QuestionType.rating => StarRating(
                rating: answer is int ? answer as int : 0,
                size: 30,
                interactive: true,
                onChanged: onAnswer,
              ),
            QuestionType.yesNo => Row(
                children: [
                  _ChoiceChip(
                    label: 'Ja',
                    selected: answer == true,
                    onTap: () => onAnswer(true),
                  ),
                  const SizedBox(width: AppLayout.s8),
                  _ChoiceChip(
                    label: 'Nein',
                    selected: answer == false,
                    onTap: () => onAnswer(false),
                  ),
                ],
              ),
            QuestionType.text => TextFormField(
                initialValue: answer is String ? answer as String : null,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Deine Antwort ...',
                  alignLabelWithHint: true,
                ),
                onChanged: onAnswer,
              ),
          },
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.paper,
          border: Border.all(color: selected ? AppColors.ink : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.paper : AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Text(
        'Die Fragen konnten nicht geladen werden. Bitte versuche es später erneut.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
