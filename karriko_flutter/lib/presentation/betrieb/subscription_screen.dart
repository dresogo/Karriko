import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Abonnement'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CurrentPlan(),
            const SizedBox(height: 24),
            Text('Verfügbare Pläne', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            _PlanCard(
              name: 'Basis',
              price: 'Kostenlos',
              features: const ['Öffentliches Profil', 'Bewertungen einsehen', 'Auf Bewertungen antworten'],
              isCurrent: true,
            ),
            const SizedBox(height: 12),
            _PlanCard(
              name: 'Premium',
              price: '49 €/Monat',
              features: const [
                'Alles aus Basis',
                'Detaillierte Analytics',
                'Team-Verwaltung (bis zu 5 Nutzer)',
                'Bewerbermanagement',
                'Prioritäts-Support',
              ],
              isCurrent: false,
            ),
            const SizedBox(height: 24),
            Text('Rechnungen', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('Keine Rechnungen vorhanden.', style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPlan extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, Color(0xFF1E5A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aktueller Plan',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          const Text('Basis', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Kostenlos', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.darkGreen),
            child: const Text('Auf Premium upgraden'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final List<String> features;
  final bool isCurrent;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.features,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.lightGreen : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isCurrent ? AppColors.primary : AppColors.border, width: isCurrent ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text('Aktuell', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          Text(price,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 14, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(f, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          if (!isCurrent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {}, child: Text('Zu $name wechseln')),
            ),
          ],
        ],
      ),
    );
  }
}
