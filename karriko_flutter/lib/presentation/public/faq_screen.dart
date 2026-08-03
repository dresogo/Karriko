import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

/// Häufig gestellte Fragen. Die Inhalte sind vorerst statisch hinterlegt und
/// können später aus der Datenbank geladen werden.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _groups = <(String, List<(String, String)>)>[
    (
      'Allgemein',
      [
        (
          'Was ist Karriko?',
          'Karriko ist eine Plattform, auf der Auszubildende ihren Ausbildungsbetrieb '
              'bewerten und angehende Azubis sich vor der Bewerbung ein ehrliches Bild '
              'machen können.',
        ),
        (
          'Ist die Nutzung kostenlos?',
          'Für Azubis ist Karriko vollständig kostenlos. Betriebe können ihr Profil '
              'kostenlos anlegen; erweiterte Funktionen sind Teil der kostenpflichtigen '
              'Pakete.',
        ),
      ],
    ),
    (
      'Für Azubis',
      [
        (
          'Wie schreibe ich eine Bewertung?',
          'Melde dich an, wähle deinen Betrieb aus und beantworte die Fragen zu '
              'Ausbildungsqualität, Betreuung, Work-Life-Balance und Übernahmechancen.',
        ),
        (
          'Ist meine Bewertung anonym?',
          'Ja. Du entscheidest bei jeder Bewertung selbst, ob dein Name angezeigt wird. '
              'Standardmäßig veröffentlichen wir Bewertungen anonym.',
        ),
        (
          'Kann mein Betrieb sehen, wer bewertet hat?',
          'Bei anonymen Bewertungen wird dem Betrieb weder Name noch E-Mail-Adresse '
              'angezeigt.',
        ),
        (
          'Kann ich eine Bewertung nachträglich ändern?',
          'Du kannst deine Bewertungen unter „Meine Bewertungen“ bearbeiten oder löschen.',
        ),
      ],
    ),
    (
      'Für Betriebe',
      [
        (
          'Wie beanspruche ich mein Unternehmensprofil?',
          'Registriere dich als Betrieb. Nach der Verifizierung kannst du dein Profil '
              'vervollständigen und auf Bewertungen antworten.',
        ),
        (
          'Können wir Bewertungen löschen lassen?',
          'Bewertungen werden nicht auf Wunsch entfernt. Verstößt ein Beitrag gegen '
              'unsere Richtlinien, kannst du ihn melden – wir prüfen jede Meldung.',
        ),
      ],
    ),
    (
      'Moderation & Datenschutz',
      [
        (
          'Wie werden Bewertungen geprüft?',
          'Jede Bewertung durchläuft vor der Veröffentlichung eine Moderation, in der '
              'Regel innerhalb von 24 Stunden.',
        ),
        (
          'Was passiert mit meinen Daten?',
          'Details zur Verarbeitung deiner Daten findest du in der Datenschutzerklärung.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Häufige Fragen'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentBand(
              padding: const EdgeInsets.only(
                top: AppLayout.s48,
                bottom: AppLayout.s64,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HILFE & SUPPORT',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.32,
                    ),
                  ),
                  const SizedBox(height: AppLayout.s16),
                  Text(
                    'Häufig gestellte Fragen',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppLayout.s16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: const Text(
                      'Die wichtigsten Antworten rund um Bewertungen, Konten und '
                      'Moderation – für Azubis und Betriebe.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 17,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppLayout.s48),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final group in _groups) ...[
                          Text(
                            group.$1.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.96,
                            ),
                          ),
                          const SizedBox(height: AppLayout.s16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < group.$2.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                        color: AppColors.line, height: 1),
                                  _FaqItem(
                                    question: group.$2[i].$1,
                                    answer: group.$2[i].$2,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppLayout.s32),
                        ],
                        const SizedBox(height: AppLayout.s16),
                        _ContactBox(),
                      ],
                    ),
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

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
            horizontal: AppLayout.s24, vertical: AppLayout.s8),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppLayout.s24,
          0,
          AppLayout.s24,
          AppLayout.s24,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.ink,
        collapsedIconColor: AppColors.muted,
        title: Text(question, style: Theme.of(context).textTheme.headlineSmall),
        children: [
          Text(answer,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}

class _ContactBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: const BoxDecoration(color: AppColors.audienceBeige),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Frage nicht dabei?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppLayout.s8),
          Text(
            'Schreib uns – wir melden uns in der Regel innerhalb von zwei Werktagen.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppLayout.s24),
          OutlinedButton(
            onPressed: () => context.go('/kontakt'),
            child: const Text('Zum Kontaktformular'),
          ),
        ],
      ),
    );
  }
}
