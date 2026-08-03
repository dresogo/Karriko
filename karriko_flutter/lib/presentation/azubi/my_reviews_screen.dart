import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/review_model.dart';
import '../../providers/review_provider.dart';
import '../common/app_bar_widget.dart';
import '../common/review_card.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id ?? '';
    final reviews = ref.watch(myReviewsProvider(userId));

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Meine Bewertungen'),
      drawer: const KarrikoDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/reviews/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Neue Bewertung', style: TextStyle(color: Colors.white)),
      ),
      body: reviews.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rate_review_outlined,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('Noch keine Bewertungen',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Teile deine Erfahrungen mit anderen Azubis.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/reviews/new'),
                      child: const Text('Erste Bewertung schreiben'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ReviewManageCard(
                    review: list[i], ref: ref, userId: userId),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Fehler beim Laden.')),
      ),
    );
  }
}

class _ReviewManageCard extends ConsumerWidget {
  final ReviewModel review;
  final WidgetRef ref;
  final String userId;

  const _ReviewManageCard(
      {required this.review, required this.ref, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        ReviewCard(review: review, showCompany: true),
        Positioned(
          top: 8,
          right: 8,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: AppColors.textMuted, size: 18),
            onSelected: (v) async {
              if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Bewertung löschen?'),
                    content: const Text(
                        'Diese Aktion kann nicht rückgängig gemacht werden.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Abbrechen')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        child: const Text('Löschen'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(reviewRepositoryProvider)
                      .deleteReview(review.id);
                  ref.invalidate(myReviewsProvider(userId));
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Löschen',
                      style: TextStyle(color: AppColors.error))),
            ],
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: review.status == 'published'
                  ? AppColors.lightGreen
                  : AppColors.background,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              review.status == 'published' ? 'Veröffentlicht' : 'In Prüfung',
              style: TextStyle(
                fontSize: 10,
                color: review.status == 'published'
                    ? AppColors.success
                    : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
