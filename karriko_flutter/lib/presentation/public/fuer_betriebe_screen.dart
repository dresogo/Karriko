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

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(vertical: width > 720 ? AppLayout.s64 : AppLayout.s48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FÜR AUSBILDUNGSBETRIEBE',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.32,
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            Text(
              'Ausbildung als\nQualitätsmerkmal.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: (width * 0.05).clamp(34.0, 60.0),
                fontWeight: FontWeight.w800,
                height: 0.98,
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: const Text(
                'Verwalte dein Profil, verstehe Feedback und zeige Bewerbern, '
                'warum dein Betrieb die richtige Wahl ist.',
                style: TextStyle(color: AppColors.muted, fontSize: 17, height: 1.55),
              ),
            ),
            const SizedBox(height: AppLayout.s32),
            ElevatedButton(
              onPressed: () => context.go('/register/betrieb'),
              child: const Text('Jetzt registrieren'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Features ────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  static const _features = [
    (Icons.manage_accounts_outlined, 'Profil verwalten',
        'Präsentiere deinen Betrieb mit Logo, Beschreibung und Ansprechpartnern.'),
    (Icons.star_outline, 'Bewertungen einsehen',
        'Erhalte detailliertes Feedback von aktuellen und ehemaligen Azubis.'),
    (Icons.reply_outlined, 'Auf Bewertungen antworten',
        'Reagiere professionell auf Kritik und zeige, dass du Feedback ernst nimmst.'),
    (Icons.analytics_outlined, 'Analytics nutzen',
        'Verstehe Trends und vergleiche dich mit anderen Betrieben deiner Branche.'),
  ];

  static const _gap = AppLayout.s24;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.s48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WAS KARRIKO FÜR BETRIEBE BIETET',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.96,
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            LayoutBuilder(
              builder: (context, constraints) {
                final avail = constraints.maxWidth;
                final cols = avail >= 640 ? 2 : 1;
                final cardWidth = (avail - (cols - 1) * _gap) / cols;
                return Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  children: [
                    for (final f in _features)
                      SizedBox(
                        width: cardWidth,
                        child: _FeatureCard(icon: f.$1, title: f.$2, description: f.$3),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.audienceBeige,
              border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
            ),
            child: Icon(icon, size: 22, color: AppColors.ink),
          ),
          const SizedBox(height: AppLayout.s16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          Text(
            description,
            style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Pricing ─────────────────────────────────────────────────────────────────

class _PricingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    const basis = _PricingCard(
      name: 'BASIS',
      price: 'Kostenlos',
      features: ['Öffentliches Profil', 'Bewertungen einsehen', 'Auf Bewertungen antworten'],
      isPrimary: false,
    );
    const premium = _PricingCard(
      name: 'PREMIUM',
      price: '49 €/Monat',
      features: [
        'Alles aus Basis',
        'Detaillierte Analytics',
        'Team-Verwaltung',
        'Bewerbermanagement',
        'Prioritäts-Support',
      ],
      isPrimary: true,
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.s48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PLÄNE & PREISE',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.96,
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            if (isWide)
              const IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: basis),
                    SizedBox(width: AppLayout.s24),
                    Expanded(child: premium),
                  ],
                ),
              )
            else ...[
              basis,
              const SizedBox(height: AppLayout.s24),
              premium,
            ],
          ],
        ),
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
    final bg = isPrimary ? AppColors.ink : AppColors.surface;
    final titleColor = isPrimary ? Colors.white : AppColors.ink;
    final mutedColor = isPrimary ? Colors.white70 : AppColors.muted;

    return Container(
      padding: const EdgeInsets.all(AppLayout.s32),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: isPrimary ? AppColors.ink : AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPrimary ? 'EMPFOHLEN' : name,
            style: TextStyle(
              color: isPrimary ? AppColors.accent : mutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.96,
            ),
          ),
          if (isPrimary) ...[
            const SizedBox(height: AppLayout.s8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.96,
              ),
            ),
          ],
          const SizedBox(height: AppLayout.s16),
          Text(
            price,
            style: TextStyle(
              color: titleColor,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: AppLayout.s24),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(color: titleColor, fontSize: 15, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppLayout.s24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/register/betrieb'),
              child: Text(isPrimary ? 'Premium starten' : 'Kostenlos starten'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTA ─────────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(vertical: width > 720 ? AppLayout.s64 : AppLayout.s48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bereit loszulegen?',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: (width * 0.045).clamp(30.0, 48.0),
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            const Text(
              'Erstelle jetzt dein kostenloses Betriebsprofil.',
              style: TextStyle(color: AppColors.muted, fontSize: 17, height: 1.55),
            ),
            const SizedBox(height: AppLayout.s32),
            ElevatedButton(
              onPressed: () => context.go('/register/betrieb'),
              child: const Text('Jetzt registrieren'),
            ),
          ],
        ),
      ),
    );
  }
}
