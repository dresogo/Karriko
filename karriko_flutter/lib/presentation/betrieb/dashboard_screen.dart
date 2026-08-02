import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';

class BetriebDashboardScreen extends ConsumerWidget {
  const BetriebDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const KarrikoAppBar(showBack: false),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text('Übersicht deines Betriebsprofils', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            _KpiCards(),
            const SizedBox(height: 24),
            _ScoreTrend(),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Aktuelle Bewertungen', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/betrieb-reviews'),
                  child: const Text('Alle anzeigen', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _RecentReviewsPlaceholder(),
            const SizedBox(height: 24),
            _ProfileCompletion(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _KpiCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const kpis = [
      (Icons.star, '4.2', 'Ø Bewertung', AppColors.primary),
      (Icons.rate_review_outlined, '24', 'Bewertungen', AppColors.warning),
      (Icons.visibility_outlined, '1.2k', 'Profilaufrufe', AppColors.success),
      (Icons.trending_up, '+3', 'Neu (30 Tage)', AppColors.primary),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: kpis.map((k) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: const [AppColors.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(k.$1, color: k.$4, size: 20),
            const Spacer(),
            Text(k.$2, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: k.$4)),
            Text(k.$3, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      )).toList(),
    );
  }
}

class _ScoreTrend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score-Verlauf (30 Tage)', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [3.8, 4.0, 3.9, 4.1, 4.0, 4.2, 4.2].map((v) {
                final height = ((v - 3.5) / 1.5 * 60).clamp(10.0, 60.0);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReviewsPlaceholder extends StatelessWidget {
  const _RecentReviewsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.rate_review_outlined, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text('Noch keine Bewertungen', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ProfileCompletion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const completion = 0.65;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Profil-Vollständigkeit', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              Text('${(completion * 100).round()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completion,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Füge ein Logo und eine Beschreibung hinzu, um dein Profil zu vervollständigen.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () => context.go('/betrieb-profile'),
              child: const Text('Unternehmensprofil bearbeiten'),
            ),
          ),
        ],
      ),
    );
  }
}
