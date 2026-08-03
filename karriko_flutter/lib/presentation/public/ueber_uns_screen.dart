import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

class UeberUnsScreen extends StatelessWidget {
  const UeberUnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Über uns'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              color: AppColors.darkGreen,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Über Karriko',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(
                    'Wir machen Ausbildung transparent – für Azubis und Betriebe gleichermaßen.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unsere Mission',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Karriko wurde mit dem Ziel gegründet, den Ausbildungsmarkt im DACH-Raum transparenter zu machen. Wir glauben, dass ehrliches Feedback sowohl Azubis bei ihrer Berufswahl hilft als auch Betriebe dabei unterstützt, ihre Ausbildungsqualität kontinuierlich zu verbessern.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  Text('Unsere Werte',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 16),
                  const _ValueCard(
                    icon: Icons.shield_outlined,
                    title: 'Vertrauen & Transparenz',
                    description:
                        'Alle Bewertungen werden moderiert und auf Authentizität geprüft.',
                  ),
                  const SizedBox(height: 12),
                  const _ValueCard(
                    icon: Icons.lock_outline,
                    title: 'Datenschutz first',
                    description:
                        'DSGVO-konform von Beginn an – nicht als Nachgedanke.',
                  ),
                  const SizedBox(height: 12),
                  const _ValueCard(
                    icon: Icons.people_outline,
                    title: 'Für alle Beteiligten',
                    description:
                        'Karriko schafft Mehrwert für Azubis, Betriebe und den Ausbildungsmarkt.',
                  ),
                ],
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ValueCard(
      {required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(description,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
