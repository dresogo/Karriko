import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/tap_target.dart';

/// Über uns: wer hinter Karriko steht und woran sich die Plattform hält.
///
/// Aufbau nach dem Seiten-Tab „19 Über uns“: Kopf, Warum es Karriko gibt,
/// Grundsätze, Anbieter, Kontakt-Band. Ein Team-Abschnitt fehlt bewusst, bis
/// entschieden ist, wer mit Namen und Foto genannt wird; Rechtsform und Sitz
/// hängen an T-9.1 und stehen bis dahin nur im Impressum. Hier steht nur, was
/// stimmt (Factsheet §2.5).
class UeberUnsScreen extends StatelessWidget {
  const UeberUnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: KarrikoAppBar(title: 'Über uns'),
      drawer: KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(),
            _WhySection(),
            _PrinciplesSection(),
            _ProviderSection(),
            _ContactBand(),
            FooterWidget(),
          ],
        ),
      ),
    );
  }
}

/// Breite, ab der Abschnitte zweispaltig stehen (Factsheet §2.3: 1024).
const _wide = 1024.0;

/// Versal-Kicker über Titeln. Kleiner Text, deshalb `accentDark` (T-6.2).
class _Kicker extends StatelessWidget {
  final String text;

  const _Kicker(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.accentDark,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.32,
      ),
    );
  }
}

/// Abschnitt mit Haarlinie unten und dem Seitenmuster `section-grid`: links
/// die Überschrift (etwa ⅓), rechts der Inhalt (⅔), unter [_wide] einspaltig.
class _GridSection extends StatelessWidget {
  final String kicker;
  final String heading;
  final Widget child;
  final Color? background;

  const _GridSection({
    required this.kicker,
    required this.heading,
    required this.child,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _wide;
    final vPad = isWide ? AppLayout.s64 + AppLayout.s24 : AppLayout.s48;

    final headingBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Kicker(kicker),
        const SizedBox(height: AppLayout.s16),
        Text(
          heading,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: isWide ? 40 : 30,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(vertical: vPad),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: headingBlock),
                  const SizedBox(width: AppLayout.s64),
                  Expanded(flex: 2, child: child),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headingBlock,
                  const SizedBox(height: AppLayout.s32),
                  child,
                ],
              ),
      ),
    );
  }
}

// ─── Kopf ────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _wide;
    final titleSize = isWide ? (width * 0.06).clamp(56.0, 88.0) : 40.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(
          vertical: isWide ? AppLayout.s64 + AppLayout.s32 : AppLayout.s48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Kicker('ÜBER UNS'),
            const SizedBox(height: AppLayout.s24),
            Text(
              'Ausbildung\ntransparent machen.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                height: 0.94,
                letterSpacing: isWide ? -1 : -0.5,
              ),
            ),
            SizedBox(height: isWide ? AppLayout.s48 : AppLayout.s32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: const Text(
                'Karriko ist eine Bewertungsplattform für die duale Ausbildung '
                'im DACH-Raum. Azubis bewerten ihren Ausbildungsbetrieb, '
                'Betriebe sehen, was über sie gesagt wird. Damit beide Seiten '
                'vor der Entscheidung wissen, worauf sie sich einlassen.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 17,
                  height: 1.55,
                ),
              ),
            ),
            SizedBox(height: isWide ? AppLayout.s64 : AppLayout.s48),
            const _FactRow(),
          ],
        ),
      ),
    );
  }
}

/// Drei Kennzeichen der Plattform zwischen Haarlinien, dasselbe Muster wie auf
/// „Für Betriebe“. Nur Eigenschaften, keine Zahlen (T-11.5).
class _FactRow extends StatelessWidget {
  const _FactRow();

  static const _facts = [
    ('Kostenlos', 'für Azubis'),
    ('Frankfurt', 'Datenhaltung'),
    ('DACH', 'Deutschland, Österreich, Schweiz'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;

    final cells = [
      for (final fact in _facts)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fact.$1,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fact.$2,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
    ];

    // Schmal stehen die Angaben untereinander, jede mit eigener Haarlinie;
    // so bricht nichts um und nichts wird abgeschnitten.
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final cell in cells)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppLayout.s16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: cell,
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: AppLayout.s24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, cell) in cells.indexed) ...[
              if (index > 0)
                Container(
                  width: 1,
                  color: AppColors.line,
                  margin: const EdgeInsets.symmetric(horizontal: AppLayout.s24),
                ),
              Expanded(child: cell),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Warum es Karriko gibt ───────────────────────────────────────────────────

class _WhySection extends StatelessWidget {
  const _WhySection();

  static const _paragraphs = [
    'Wer eine Ausbildung sucht, entscheidet sich für Jahre in einem '
        'Betrieb, den er meist nur aus der Stellenanzeige und einem '
        'Vorstellungs\u00ADgespräch kennt. Wie Betreuung, Umgang und Belastung '
        'wirklich sind, erfährt man erst, wenn man schon unterschrieben hat.',
    'Karriko sammelt diese Erfahrungen. Azubis beantworten einen '
        'strukturierten Fragebogen zu ihrem Betrieb, statt nur Sterne zu '
        'vergeben. Daraus entsteht ein Bild in mehreren Bereichen, von der '
        'fachlichen Ausbildung bis zum Umgang, das sich zwischen Betrieben '
        'vergleichen lässt.',
    'Betriebe bekommen ein Profil, sehen ihre Bewertungen und schreiben ihre '
        'Ausbildungsstellen direkt daneben aus. Wer gut ausbildet, kann es '
        'damit zeigen.',
  ];

  @override
  Widget build(BuildContext context) {
    return _GridSection(
      kicker: 'WARUM ES KARRIKO GIBT',
      heading: 'Transparenz vor der Entscheidung.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, text) in _paragraphs.indexed) ...[
              if (index > 0) const SizedBox(height: AppLayout.s24),
              Text(
                text,
                style: TextStyle(
                  color: index == 0 ? AppColors.ink : AppColors.muted,
                  fontSize: index == 0 ? 20 : 17,
                  height: index == 0 ? 1.45 : 1.55,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Grundsätze ──────────────────────────────────────────────────────────────

class _PrinciplesSection extends StatelessWidget {
  const _PrinciplesSection();

  // Belegt durch E-29, E-02/E-53 und den geplanten Hilfe-Tab (16). Nicht
  // „keine Drittdienste“: Der Noto-Fallback lädt noch von Google (W-2.1).
  static const _principles = [
    (
      '01',
      'Bewertungen sind nicht käuflich.',
      'Weder Bewertungen noch ihre Reihenfolge lassen sich kaufen, auch nicht '
          'mit Premium. Betriebe können sich besser darstellen, aber nicht '
          'besser platzieren.',
      'So funktioniert Karriko',
      '/transparenz',
    ),
    (
      '02',
      'Daten bleiben in Frankfurt.',
      'Konten, Bewertungen und Profile liegen auf Servern in Frankfurt am '
          'Main. Getrackt wird nur mit deiner Einwilligung.',
      'Zur Datenschutzerklärung',
      '/datenschutz',
    ),
    (
      '03',
      'Hilfe gibt es ohne Anmeldung.',
      'Wer in der Ausbildung Probleme hat, findet die passenden '
          'Anlaufstellen, ohne ein Konto anzulegen.',
      'Zu Hilfe und Anlaufstellen',
      '/hilfe',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _GridSection(
      kicker: 'GRUNDSÄTZE',
      heading: 'Woran wir uns halten.',
      background: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, p) in _principles.indexed)
            _PrincipleRow(
              number: p.$1,
              title: p.$2,
              text: p.$3,
              linkLabel: p.$4,
              route: p.$5,
              isLast: index == _principles.length - 1,
            ),
        ],
      ),
    );
  }
}

/// Ein Grundsatz: große Nummer, Titel, Text, Verweis. Die ganze Zeile ist das
/// Klickziel; bei Hover oder Fokus färbt sich der Verweis und die Nummer.
class _PrincipleRow extends StatelessWidget {
  final String number;
  final String title;
  final String text;
  final String linkLabel;
  final String route;
  final bool isLast;

  const _PrincipleRow({
    required this.number,
    required this.title,
    required this.text,
    required this.linkLabel,
    required this.route,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;

    return TapTarget(
      onTap: () => context.go(route),
      builder: (context, active) {
        // Die Nummer ist Gliederung, kein Inhalt: Screenreader lesen den
        // Titel, nicht „null eins“.
        final numberText = ExcludeSemantics(
          child: Text(
            number,
            style: TextStyle(
              color: active ? AppColors.accent : AppColors.line,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        );

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppLayout.s8),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 17,
                height: 1.55,
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    linkLabel,
                    style: TextStyle(
                      color: AppColors.accentDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: active
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: AppColors.accentDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppLayout.s8),
                const Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.accentDark),
              ],
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppLayout.s32),
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: AppColors.line),
              bottom: isLast
                  ? const BorderSide(color: AppColors.line)
                  : BorderSide.none,
            ),
          ),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 96, child: numberText),
                    Expanded(child: body),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    numberText,
                    const SizedBox(height: AppLayout.s16),
                    body,
                  ],
                ),
        );
      },
    );
  }
}

// ─── Anbieter ────────────────────────────────────────────────────────────────

class _ProviderSection extends StatelessWidget {
  const _ProviderSection();

  @override
  Widget build(BuildContext context) {
    return _GridSection(
      kicker: 'WER DAHINTERSTEHT',
      heading: 'Klar benannt.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: const Text(
              'Ein Bewertungsportal lebt davon, dass man weiß, wer dahinter '
              'steht. Wer für Karriko verantwortlich ist und wie du uns '
              'erreichst, steht im Impressum.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 17,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: AppLayout.s24),
          OutlinedButton(
            onPressed: () => context.go('/impressum'),
            child: const Text('Zum Impressum'),
          ),
        ],
      ),
    );
  }
}

// ─── Kontakt-Band ────────────────────────────────────────────────────────────

class _ContactBand extends StatelessWidget {
  const _ContactBand();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _wide;
    final headingSize = isWide ? (width * 0.045).clamp(48.0, 72.0) : 36.0;

    final heading = Text(
      'Fragen, Kritik,\nIdeen?',
      style: TextStyle(
        color: AppColors.ink,
        fontSize: headingSize,
        fontWeight: FontWeight.w800,
        height: 0.96,
      ),
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schreib uns eine E-Mail. Hinweise auf Fehler helfen uns besonders.',
          style: TextStyle(color: AppColors.muted, fontSize: 17, height: 1.55),
        ),
        const SizedBox(height: AppLayout.s32),
        // Wrap: bei schmaler Breite oder großer Schrift rutscht der zweite
        // Knopf in die nächste Zeile.
        Wrap(
          spacing: AppLayout.s16,
          runSpacing: AppLayout.s16,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/kontakt'),
              // Flexible: Bei 320 px und großer Schrift lief die Zeile sonst
              // um 2 px über (T-7.10).
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text('Schreib uns')),
                  SizedBox(width: AppLayout.s8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => context.go('/presse'),
              child: const Text('Presse'),
            ),
          ],
        ),
      ],
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(
          vertical: isWide ? AppLayout.s64 + AppLayout.s32 : AppLayout.s64,
        ),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 1, child: heading),
                  const SizedBox(width: AppLayout.s64),
                  Expanded(flex: 2, child: actions),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  const SizedBox(height: AppLayout.s32),
                  actions,
                ],
              ),
      ),
    );
  }
}
