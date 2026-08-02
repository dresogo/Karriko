import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/review_provider.dart';
import '../../data/models/review_model.dart';
import '../common/app_bar_widget.dart';
import '../common/review_card.dart';

class ReviewDetailScreen extends ConsumerWidget {
  final String id;
  const ReviewDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(reviewByIdProvider(id));

    return Scaffold(
      appBar: const KarrikoAppBar(),
      drawer: const KarrikoDrawer(),
      body: review.when(
        data: (r) => _ReviewDetailBody(review: r),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Bewertung nicht gefunden.')),
      ),
    );
  }
}

class _ReviewDetailBody extends StatelessWidget {
  final ReviewModel review;
  const _ReviewDetailBody({required this.review});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.go('/company/${review.companySlug}'),
            child: Text(
              review.companyName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(review.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.lightGreen,
                child: const Icon(Icons.person, size: 18, color: AppColors.textMuted),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.displayAuthor, style: Theme.of(context).textTheme.labelLarge),
                  Text(DateFormat('dd. MMMM yyyy', 'de').format(review.createdAt),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const Spacer(),
              StarRating(rating: review.overallRating, size: 18),
            ],
          ),
          const SizedBox(height: 24),
          if (review.trainingQuality != null || review.mentoring != null ||
              review.workLifeBalance != null || review.careerOpportunities != null) ...[
            Text('Detailbewertungen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _RatingRow('Ausbildungsqualität', review.trainingQuality),
            _RatingRow('Betreuung', review.mentoring),
            _RatingRow('Work-Life-Balance', review.workLifeBalance),
            _RatingRow('Übernahmechancen', review.careerOpportunities),
            const SizedBox(height: 24),
          ],
          Text('Bewertung', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(review.text, style: Theme.of(context).textTheme.bodyLarge),
          if (review.pros != null) ...[
            const SizedBox(height: 16),
            _ProsConsSection(label: 'Vorteile', text: review.pros!, color: AppColors.success),
          ],
          if (review.cons != null) ...[
            const SizedBox(height: 12),
            _ProsConsSection(label: 'Nachteile', text: review.cons!, color: AppColors.error),
          ],
          if (review.betriebReply != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Antwort des Betriebs',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.darkGreen)),
                      const Spacer(),
                      if (review.betriebRepliedAt != null)
                        Text(
                          DateFormat('dd.MM.yyyy').format(review.betriebRepliedAt!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.betriebReply!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.darkGreen)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final int? rating;
  const _RatingRow(this.label, this.rating);

  @override
  Widget build(BuildContext context) {
    if (rating == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          StarRating(rating: rating!),
          const SizedBox(width: 8),
          Text('$rating/5', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ProsConsSection extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _ProsConsSection({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          const SizedBox(height: 4),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
