import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/review_model.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool showCompany;
  final VoidCallback? onTap;

  const ReviewCard({
    super.key,
    required this.review,
    this.showCompany = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.go('/reviews/${review.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: const [AppColors.cardShadow],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.lightGreen,
                  child:
                      Icon(Icons.person, color: AppColors.textMuted, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.displayAuthor,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      if (showCompany)
                        Text(
                          review.companyName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                        ),
                    ],
                  ),
                ),
                StarRating(rating: review.overallRating),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.title,
              style: Theme.of(context).textTheme.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              review.text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (review.profession != null) ...[
                  _Chip(review.profession!),
                  const SizedBox(width: 8),
                ],
                if (review.isVerified) ...[
                  const _VerifiedBadge(),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  DateFormat('dd.MM.yyyy').format(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (review.betriebReply != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antwort des Betriebs',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGreen,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.betriebReply!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.darkGreen,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  final int rating;
  final int max;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.max = 5,
    this.size = 14,
    this.interactive = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final filled = i < rating;
        return GestureDetector(
          onTap:
              interactive && onChanged != null ? () => onChanged!(i + 1) : null,
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            size: size,
            color: filled ? const Color(0xFFF59E0B) : AppColors.border,
          ),
        );
      }),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 10, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            'Verifiziert',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}
