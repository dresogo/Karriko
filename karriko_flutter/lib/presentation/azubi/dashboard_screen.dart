import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/company_provider.dart';
import '../common/app_bar_widget.dart';
import '../common/review_card.dart';

class AzubiDashboardScreen extends ConsumerWidget {
  const AzubiDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final myReviews = ref.watch(myReviewsProvider(auth.user?.id ?? ''));
    final bookmarks = ref.watch(bookmarkedCompaniesProvider(auth.user?.id ?? ''));

    return Scaffold(
      appBar: const KarrikoAppBar(showBack: false),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeBanner(name: auth.user?.displayName ?? 'Azubi'),
            const SizedBox(height: 20),
            _QuickActions(),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Meine Bewertungen', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/my-reviews'),
                  child: const Text('Alle anzeigen', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            myReviews.when(
              data: (reviews) => reviews.isEmpty
                  ? _EmptyState(
                      icon: Icons.rate_review_outlined,
                      text: 'Noch keine Bewertungen',
                      action: 'Jetzt bewerten',
                      onAction: () => context.go('/reviews/new'),
                    )
                  : Column(
                      children: reviews.take(3).map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ReviewCard(review: r),
                      )).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Fehler beim Laden.'),
            ),
            const SizedBox(height: 24),
            Text('Merkliste', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            bookmarks.when(
              data: (companies) => companies.isEmpty
                  ? _EmptyState(
                      icon: Icons.bookmark_border,
                      text: 'Keine Betriebe gespeichert',
                      action: 'Betriebe entdecken',
                      onAction: () => context.go('/search'),
                    )
                  : Column(
                      children: companies.take(3).map((c) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business, color: AppColors.primary, size: 20),
                        ),
                        title: Text(c.name, style: Theme.of(context).textTheme.labelLarge),
                        subtitle: Text(c.location.isNotEmpty ? c.location : (c.industry ?? '')),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        onTap: () => context.go('/company/${c.slug}'),
                      )).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;
  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hallo $name! 👋',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Hier sind deine wichtigsten Updates.',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.rate_review_outlined, 'Bewertung schreiben', '/reviews/new'),
      (Icons.quiz_outlined, 'Fragen bewerten', '/fragen-bewerten'),
      (Icons.search, 'Betrieb suchen', '/search'),
      (Icons.bookmark_border, 'Merkliste', '/bookmarks'),
      (Icons.person_outline, 'Mein Profil', '/profile'),
      (Icons.notifications_outlined, 'Mitteilungen', '/notifications'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: actions.map((a) => GestureDetector(
        onTap: () => context.go(a.$3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(a.$1, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(a.$2,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}
