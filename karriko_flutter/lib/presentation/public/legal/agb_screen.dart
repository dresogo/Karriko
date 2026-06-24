import 'package:flutter/material.dart';
import '../../common/app_bar_widget.dart';

class AgbScreen extends StatelessWidget {
  const AgbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = [
      ('§ 1 Geltungsbereich', 'Diese Allgemeinen Geschäftsbedingungen gelten für die Nutzung der Plattform Karriko, erreichbar unter karriko.de sowie über die zugehörigen Apps.'),
      ('§ 2 Leistungen', 'Karriko stellt eine Plattform zur Verfügung, auf der Auszubildende Bewertungen über Ausbildungsbetriebe verfassen und lesen können sowie Betriebe ihre Profile verwalten können.'),
      ('§ 3 Registrierung', 'Die Nutzung bestimmter Funktionen erfordert eine Registrierung. Der Nutzer ist verpflichtet, wahrheitsgemäße Angaben zu machen und sein Passwort sicher aufzubewahren.'),
      ('§ 4 Nutzerpflichten', 'Nutzer sind verpflichtet, keine falschen, irreführenden oder beleidigenden Inhalte zu veröffentlichen. Bewertungen müssen auf eigenen, echten Erfahrungen basieren.'),
      ('§ 5 Haftungsbeschränkung', 'Karriko übernimmt keine Haftung für die Richtigkeit der von Nutzern verfassten Bewertungen und Inhalte. Karriko ist eine neutrale Plattform.'),
      ('§ 6 Datenschutz', 'Die Verarbeitung personenbezogener Daten erfolgt gemäß unserer Datenschutzerklärung und den Vorgaben der DSGVO.'),
      ('§ 7 Änderungen', 'Karriko behält sich das Recht vor, diese AGB jederzeit zu ändern. Nutzer werden über wesentliche Änderungen per E-Mail informiert.'),
    ];

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'AGB'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Allgemeine Geschäftsbedingungen', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text('Stand: Juni 2026', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 32),
              ...sections.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$1, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(s.$2, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
