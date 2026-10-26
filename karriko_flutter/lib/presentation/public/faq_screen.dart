import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/fit_words_text.dart';

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
          'Melde dich an, bestätige deine E-Mail-Adresse, wähle deinen Betrieb aus '
              'und beantworte die Fragen zu fachlicher Ausbildung, Betreuung, '
              'Umgang, Belastung und Perspektive.',
        ),
        (
          'Ist meine Bewertung anonym?',
          'Ja. Bewertungen erscheinen immer ohne Namen, und die veröffentlichte '
              'Bewertung ist mit keinem Konto verknüpft.',
        ),
        (
          'Kann mein Betrieb sehen, wer bewertet hat?',
          'Nein. Der Betrieb sieht weder Namen noch E-Mail-Adresse. Einen Wert '
              'zeigen wir erst ab drei Bewertungen, damit sich eine einzelne nicht '
              'zuordnen lässt.',
        ),
        (
          'Kann ich eine Bewertung nachträglich ändern?',
          'Ändern lässt sich eine abgeschickte Bewertung noch nicht. Unter „Meine '
              'Bewertungen“ kannst du sie löschen und danach eine neue schreiben.',
        ),
      ],
    ),
    (
      'Für Betriebe',
      [
        (
          'Wie bekomme ich ein Unternehmensprofil?',
          'Registriere dich als Betrieb und bestätige deine E-Mail-Adresse; dabei '
              'entsteht dein Profil. Danach prüfen wir deinen Betrieb. '
              'Ausbildungsstellen veröffentlichen kannst du nach dieser Prüfung, '
              'als Entwurf vorbereiten schon vorher.',
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
          // Neutral formuliert, damit es heute (jede Bewertung sieht ein
          // Mensch) und nach der Vorsortierung (E-2.13) stimmt (T-6.26).
          'Jede Bewertung wird vor der Veröffentlichung geprüft. Auffällige '
              'Fälle und jede Meldung sieht sich ein Mensch an. Auf deinen '
              'Wunsch erscheint sie später, zum Beispiel erst nach deinem '
              'Ausbildungsende.',
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
                      color: AppColors.accentDark,
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
                            // Material liefert die Zeichenflaeche fuer den
                            // Ripple der ExpansionTile. Ohne sie hat der Ink
                            // keinen Untergrund und Flutter meldet das.
                            child: Material(
                              type: MaterialType.transparency,
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
        title: FitWordsText(question,
            style: Theme.of(context).textTheme.headlineSmall),
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
            'Schreib uns.',
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
