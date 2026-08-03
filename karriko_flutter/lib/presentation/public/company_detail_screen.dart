import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/company_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/company_model.dart';
import '../common/app_bar_widget.dart';
import '../common/review_card.dart';

class CompanyDetailScreen extends ConsumerWidget {
  final String slug;
  const CompanyDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(companyBySlugProvider(slug));

    return Scaffold(
      appBar: const KarrikoAppBar(),
      drawer: const KarrikoDrawer(),
      body: company.when(
        data: (c) => _CompanyDetailBody(company: c),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Betrieb nicht gefunden.')),
      ),
    );
  }
}

class _CompanyDetailBody extends ConsumerWidget {
  final CompanyModel company;
  const _CompanyDetailBody({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(companyReviewsProvider(company.id));
    final auth = ref.watch(authProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.business,
                          size: 32, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(company.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                              ),
                              if (company.isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGreen,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified,
                                          size: 12, color: AppColors.primary),
                                      SizedBox(width: 3),
                                      Text('Verifiziert',
                                          style: TextStyle(
                                              color: AppColors.primaryDark,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (company.location.isNotEmpty)
                            Text(company.location,
                                style: Theme.of(context).textTheme.bodyMedium),
                          if (company.industry != null)
                            Text(company.industry!,
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatCard(
                      label: 'Bewertung',
                      value: company.averageRating != null
                          ? company.averageRating!.toStringAsFixed(1)
                          : '–',
                      icon: Icons.star,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Bewertungen',
                      value: company.reviewCount.toString(),
                      icon: Icons.rate_review_outlined,
                    ),
                    if (auth.isAzubi) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/reviews/new'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Bewerten'),
                        ),
                      ),
                    ],
                  ],
                ),
                if (company.description != null) ...[
                  const SizedBox(height: 20),
                  Text('Über das Unternehmen',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(company.description!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bewertungen',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                reviews.when(
                  data: (list) => list.isEmpty
                      ? const _EmptyReviews()
                      : Column(
                          children: list
                              .map((r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ReviewCard(review: r),
                                  ))
                              .toList(),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Text('Fehler beim Laden der Bewertungen.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.rate_review_outlined,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Noch keine Bewertungen',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Sei der Erste und teile deine Erfahrungen!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/reviews/new'),
            child: const Text('Jetzt bewerten'),
          ),
        ],
      ),
    );
  }
}
