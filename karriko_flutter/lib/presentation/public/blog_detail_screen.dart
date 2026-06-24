import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';

class BlogDetailScreen extends StatelessWidget {
  final String slug;
  const BlogDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text('Tipps & Tricks',
                  style: TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Text('Wie finde ich den richtigen Ausbildungsbetrieb?',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text('5 Min Lesezeit · 18. Juni 2026', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            Text(
              'Die Wahl des richtigen Ausbildungsbetriebs ist eine der wichtigsten Entscheidungen in deiner beruflichen Laufbahn. In diesem Artikel zeigen wir dir, worauf es wirklich ankommt und wie du Karriko nutzen kannst, um fundierte Entscheidungen zu treffen.\n\nErste Schritte bei der Suche\n\nBeginne mit einer klaren Vorstellung davon, was du dir von deiner Ausbildung erhoffst. Welche Branche interessiert dich? Bevorzugst du einen großen Konzern oder einen mittelständischen Betrieb? Liegt dir eine gute Work-Life-Balance am Herzen, oder stehen Karrierechancen für dich im Vordergrund?\n\nBewertungen lesen und vergleichen\n\nAuf Karriko findest du echte Erfahrungsberichte von Azubis, die bereits in den Betrieben arbeiten oder gearbeitet haben. Diese Bewertungen decken Aspekte wie Ausbildungsqualität, Betreuung, Betriebsklima und Übernahmechancen ab.\n\nFazit\n\nNutze alle verfügbaren Informationen – Karriko-Bewertungen, Praktika und Gespräche mit aktuellen Azubis – um eine fundierte Entscheidung zu treffen. Deine Ausbildung legt den Grundstein für deine berufliche Zukunft.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}
