import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

class FuerBetriebeScreen extends StatelessWidget {
  const FuerBetriebeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(),
            _FeaturesSection(),
            _PricingSection(),
            _CtaSection(),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: AppColors.darkGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text('Für Ausbildungsbetriebe',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Text('Ausbildung als Qualitätsmerkmal.',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            'Verwalte dein Profil, verstehe Feedback und zeige Bewerbern, warum dein Betrieb die richtige Wahl ist.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.darkGreen),
            child: const Text('Jetzt registrieren'),
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.manage_accounts_outlined, 'Profil verwalten', 'Präsentiere deinen Betrieb mit Logo, Beschreibung und Ansprechpartnern.'),
      (Icons.star_outline, 'Bewertungen einsehen', 'Erhalte detailliertes Feedback von aktuellen und ehemaligen Azubis.'),
      (Icons.reply_outlined, 'Auf Bewertungen antworten', 'Reagiere professionell auf Kritik und zeige, dass du Feedback ernst nimmst.'),
      (Icons.analytics_outlined, 'Analytics nutzen', 'Verstehe Trends und vergleiche dich mit anderen Betrieben deiner Branche.'),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Was Karriko für Betriebe bietet', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: features.map((f) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(f.$1, size: 24, color: AppColors.primary),
                  const SizedBox(height: 10),
                  Text(f.$2, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(f.$3, style: Theme.of(context).textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pläne & Preise', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 20),
          _PricingCard(
            name: 'Basis',
            price: 'Kostenlos',
            features: const ['Öffentliches Profil', 'Bewertungen einsehen', 'Auf Bewertungen antworten'],
            isPrimary: false,
          ),
          const SizedBox(height: 12),
          _PricingCard(
            name: 'Premium',
            price: '49 €/Monat',
            features: const [
              'Alles aus Basis',
              'Detaillierte Analytics',
              'Team-Verwaltung',
              'Bewerbermanagement',
              'Prioritäts-Support',
            ],
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String name;
  final String price;
  final List<String> features;
  final bool isPrimary;

  const _PricingCard({
    required this.name,
    required this.price,
    required this.features,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPrimary ? AppColors.primary : AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text('Empfohlen',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          Text(name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : AppColors.textPrimary,
              )),
          const SizedBox(height: 4),
          Text(price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : AppColors.primary,
              )),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: isPrimary ? Colors.white : AppColors.success),
                  const SizedBox(width: 8),
                  Text(f, style: TextStyle(color: isPrimary ? Colors.white : AppColors.textPrimary, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? Colors.white : AppColors.primary,
                foregroundColor: isPrimary ? AppColors.primary : Colors.white,
              ),
              child: Text(isPrimary ? 'Premium starten' : 'Kostenlos starten'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('Bereit loszulegen?', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Erstelle jetzt dein kostenloses Betriebsprofil.',
              style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/register/betrieb'),
            child: const Text('Jetzt registrieren'),
          ),
        ],
      ),
    );
  }
}
