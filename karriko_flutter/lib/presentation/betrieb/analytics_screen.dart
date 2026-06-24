import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Analytics'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PremiumBanner(),
            const SizedBox(height: 20),
            Text('Übersicht', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            _AnalyticsGrid(),
            const SizedBox(height: 24),
            Text('Bewertungsverteilung', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            _RatingDistribution(),
            const SizedBox(height: 24),
            Text('Top-Kategorien', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            _CategoryScores(),
          ],
        ),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Premium Analytics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Detaillierte Einblicke in deine Bewertungen.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.darkGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Upgraden', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const stats = [
      ('4.2', 'Ø Gesamtbewertung', Icons.star, AppColors.warning),
      ('24', 'Gesamt-Bewertungen', Icons.rate_review_outlined, AppColors.primary),
      ('1.2k', 'Profilaufrufe', Icons.visibility_outlined, AppColors.success),
      ('87%', 'Weiterleitungsrate', Icons.trending_up, AppColors.primary),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: stats.map((s) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(s.$3, color: s.$4, size: 18),
            const Spacer(),
            Text(s.$1, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: s.$4)),
            Text(s.$2, style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
          ],
        ),
      )).toList(),
    );
  }
}

class _RatingDistribution extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const dist = [(5, 0.45), (4, 0.30), (3, 0.15), (2, 0.07), (1, 0.03)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: dist.map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(width: 16, child: Text('${d.$1}', style: Theme.of(context).textTheme.bodySmall)),
              const Icon(Icons.star, size: 12, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: d.$2,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text('${(d.$2 * 100).round()}%', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.end),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _CategoryScores extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const scores = [
      ('Ausbildungsqualität', 4.3),
      ('Betreuung', 4.0),
      ('Work-Life-Balance', 3.8),
      ('Übernahmechancen', 4.1),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: scores.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: Text(s.$1, style: Theme.of(context).textTheme.bodyMedium)),
              Text(s.$2.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(width: 8),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < s.$2.round() ? Icons.star : Icons.star_border,
                  size: 12,
                  color: i < s.$2.round() ? AppColors.warning : AppColors.border,
                )),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
