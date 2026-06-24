import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/company_provider.dart';
import '../common/app_bar_widget.dart';
import '../common/review_card.dart';

class NewReviewScreen extends ConsumerStatefulWidget {
  const NewReviewScreen({super.key});

  @override
  ConsumerState<NewReviewScreen> createState() => _NewReviewScreenState();
}

class _NewReviewScreenState extends ConsumerState<NewReviewScreen> {
  final _pageCtrl = PageController();

  final _searchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _prosCtrl = TextEditingController();
  final _consCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  int _overallRating = 0;
  int _trainingQuality = 0;
  int _mentoring = 0;
  int _workLife = 0;
  int _career = 0;
  bool _isAnonymous = true;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _prosCtrl.dispose();
    _consCtrl.dispose();
    _professionCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    ref.read(newReviewProvider.notifier).goToStep(step);
    _pageCtrl.animateToPage(step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    ref.read(newReviewProvider.notifier).setDetails(
      title: _titleCtrl.text.trim(),
      text: _textCtrl.text.trim(),
      pros: _prosCtrl.text.trim().isEmpty ? null : _prosCtrl.text.trim(),
      cons: _consCtrl.text.trim().isEmpty ? null : _consCtrl.text.trim(),
      profession: _professionCtrl.text.trim().isEmpty ? null : _professionCtrl.text.trim(),
      isAnonymous: _isAnonymous,
    );
    await ref.read(newReviewProvider.notifier).submit(userId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newReviewProvider);

    ref.listen(newReviewProvider, (_, next) {
      if (next.submitted) {
        ref.read(newReviewProvider.notifier).reset();
        context.go('/my-reviews');
      }
    });

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Bewertung schreiben'),
      body: Column(
        children: [
          _StepIndicator(current: state.step, total: 4),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step0SelectCompany(
                  searchCtrl: _searchCtrl,
                  selectedCompany: state.companyName,
                  onSelect: (id, name) {
                    ref.read(newReviewProvider.notifier).setCompany(id, name);
                    _goToStep(1);
                  },
                ),
                _Step1Ratings(
                  formKey: _step1Key,
                  overallRating: _overallRating,
                  trainingQuality: _trainingQuality,
                  mentoring: _mentoring,
                  workLife: _workLife,
                  career: _career,
                  onOverallChanged: (v) => setState(() => _overallRating = v),
                  onTrainingChanged: (v) => setState(() => _trainingQuality = v),
                  onMentoringChanged: (v) => setState(() => _mentoring = v),
                  onWorkLifeChanged: (v) => setState(() => _workLife = v),
                  onCareerChanged: (v) => setState(() => _career = v),
                  onNext: () {
                    if (_overallRating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bitte gib eine Gesamtbewertung ab.')));
                      return;
                    }
                    ref.read(newReviewProvider.notifier).setRatings(
                      overall: _overallRating,
                      training: _trainingQuality > 0 ? _trainingQuality : null,
                      mentoring: _mentoring > 0 ? _mentoring : null,
                      workLife: _workLife > 0 ? _workLife : null,
                      career: _career > 0 ? _career : null,
                    );
                    _goToStep(2);
                  },
                  onBack: () => _goToStep(0),
                ),
                _Step2Details(
                  formKey: _step2Key,
                  titleCtrl: _titleCtrl,
                  textCtrl: _textCtrl,
                  prosCtrl: _prosCtrl,
                  consCtrl: _consCtrl,
                  professionCtrl: _professionCtrl,
                  isAnonymous: _isAnonymous,
                  onAnonymousChanged: (v) => setState(() => _isAnonymous = v ?? true),
                  onNext: () {
                    if (!_step2Key.currentState!.validate()) return;
                    _goToStep(3);
                  },
                  onBack: () => _goToStep(1),
                ),
                _Step3Confirm(
                  state: state,
                  onSubmit: _submit,
                  onBack: () => _goToStep(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final labels = ['Betrieb', 'Bewertung', 'Details', 'Bestätigung'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: List.generate(total, (i) {
          final active = i == current;
          final done = i < current;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: done || active ? AppColors.primary : AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: done || active ? AppColors.primary : AppColors.border),
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : Text('${i + 1}', style: TextStyle(fontSize: 11, color: active ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Text(labels[i], style: TextStyle(fontSize: 9, color: active ? AppColors.primary : AppColors.textMuted)),
                  ],
                ),
                if (i < total - 1)
                  Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 14), color: done ? AppColors.primary : AppColors.border)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Step0SelectCompany extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final String? selectedCompany;
  final void Function(String id, String name) onSelect;

  const _Step0SelectCompany({required this.searchCtrl, this.selectedCompany, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = searchCtrl.text;
    final suggestions = query.length >= 2 ? ref.watch(searchSuggestionsProvider(query)) : const AsyncValue.data(<String>[]);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welchen Betrieb möchtest du bewerten?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: searchCtrl,
            onChanged: (_) => (context as Element).markNeedsBuild(),
            decoration: const InputDecoration(
              hintText: 'Betrieb suchen ...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          if (query.length >= 2)
            suggestions.when(
              data: (list) => Column(
                children: list.map((s) => ListTile(
                  title: Text(s),
                  leading: const Icon(Icons.business, color: AppColors.primary),
                  onTap: () => onSelect('placeholder-id', s),
                )).toList(),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          if (selectedCompany != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(selectedCompany!, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkGreen)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step1Ratings extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final int overallRating;
  final int trainingQuality;
  final int mentoring;
  final int workLife;
  final int career;
  final ValueChanged<int> onOverallChanged;
  final ValueChanged<int> onTrainingChanged;
  final ValueChanged<int> onMentoringChanged;
  final ValueChanged<int> onWorkLifeChanged;
  final ValueChanged<int> onCareerChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step1Ratings({
    required this.formKey,
    required this.overallRating,
    required this.trainingQuality,
    required this.mentoring,
    required this.workLife,
    required this.career,
    required this.onOverallChanged,
    required this.onTrainingChanged,
    required this.onMentoringChanged,
    required this.onWorkLifeChanged,
    required this.onCareerChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Deine Bewertung', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          _RatingItem('Gesamtbewertung *', overallRating, onOverallChanged),
          _RatingItem('Ausbildungsqualität', trainingQuality, onTrainingChanged),
          _RatingItem('Betreuung', mentoring, onMentoringChanged),
          _RatingItem('Work-Life-Balance', workLife, onWorkLifeChanged),
          _RatingItem('Übernahmechancen', career, onCareerChanged),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Zurück'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: onNext, child: const Text('Weiter'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingItem extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingItem(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          StarRating(rating: value, size: 32, interactive: true, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Step2Details extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController textCtrl;
  final TextEditingController prosCtrl;
  final TextEditingController consCtrl;
  final TextEditingController professionCtrl;
  final bool isAnonymous;
  final ValueChanged<bool?> onAnonymousChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step2Details({
    required this.formKey,
    required this.titleCtrl,
    required this.textCtrl,
    required this.prosCtrl,
    required this.consCtrl,
    required this.professionCtrl,
    required this.isAnonymous,
    required this.onAnonymousChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Details zur Bewertung', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titel der Bewertung *'),
              validator: (v) => Validators.required(v, label: 'Titel'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: textCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Deine Bewertung * (min. 100 Zeichen)',
                alignLabelWithHint: true,
              ),
              validator: Validators.reviewText,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: prosCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Vorteile (optional)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: consCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Nachteile (optional)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: professionCtrl,
              decoration: const InputDecoration(labelText: 'Ausbildungsberuf (optional)'),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: isAnonymous,
              onChanged: onAnonymousChanged,
              contentPadding: EdgeInsets.zero,
              title: const Text('Anonym bewerten', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Dein Name wird nicht angezeigt.', style: TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Zurück'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: onNext, child: const Text('Weiter'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3Confirm extends StatelessWidget {
  final NewReviewState state;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _Step3Confirm({required this.state, required this.onSubmit, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bewertung bestätigen', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Überprüfe deine Angaben vor dem Absenden.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          if (state.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
            const SizedBox(height: 12),
          ],
          _SummaryRow('Betrieb', state.companyName ?? '–'),
          _SummaryRow('Gesamtbewertung', '${state.overallRating}/5'),
          _SummaryRow('Titel', state.title),
          _SummaryRow('Anonym', state.isAnonymous ? 'Ja' : 'Nein'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(state.text.isNotEmpty ? state.text : '–',
                style: Theme.of(context).textTheme.bodyMedium, maxLines: 5, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Deine Bewertung wird nach Einreichung moderiert und in der Regel innerhalb von 24 Stunden veröffentlicht.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Zurück'))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isSubmitting ? null : onSubmit,
                  child: state.isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Bewertung absenden'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
