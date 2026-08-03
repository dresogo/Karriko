import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/review_provider.dart';
import '../../data/models/review_model.dart';
import '../common/app_bar_widget.dart';
import '../common/review_card.dart';

class BetriebReviewsScreen extends ConsumerWidget {
  const BetriebReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(recentReviewsProvider);

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Bewertungen'),
      drawer: const KarrikoDrawer(),
      body: reviews.when(
        data: (list) => list.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textMuted),
                    SizedBox(height: 16),
                    Text('Keine Bewertungen vorhanden', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _BetriebReviewCard(review: list[i], ref: ref),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Fehler beim Laden.')),
      ),
    );
  }
}

class _BetriebReviewCard extends ConsumerStatefulWidget {
  final ReviewModel review;
  final WidgetRef ref;

  const _BetriebReviewCard({required this.review, required this.ref});

  @override
  ConsumerState<_BetriebReviewCard> createState() => _BetriebReviewCardState();
}

class _BetriebReviewCardState extends ConsumerState<_BetriebReviewCard> {
  bool _showReplyForm = false;
  final _replyCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(reviewRepositoryProvider).addBetriebReply(
        reviewId: widget.review.id,
        reply: _replyCtrl.text.trim(),
      );
      if (mounted) {
        setState(() { _isSaving = false; _showReplyForm = false; });
        ref.invalidate(recentReviewsProvider);
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReviewCard(review: widget.review),
        if (widget.review.betriebReply == null) ...[
          const SizedBox(height: 8),
          if (!_showReplyForm)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Antworten'),
                onPressed: () => setState(() => _showReplyForm = true),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _replyCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Deine Antwort auf diese Bewertung ...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showReplyForm = false),
                        child: const Text('Abbrechen'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveReply,
                        child: _isSaving
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Antwort senden'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
