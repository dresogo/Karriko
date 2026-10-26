import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/tap_target.dart';

/// Adresse für alle Anfragen über die Kontaktseite.
const kontaktEmail = 'demharter@dresogo.de';

/// Meldestelle für Sicherheitslücken, wie in `web/.well-known/security.txt`.
const sicherheitsMeldung =
    'https://github.com/dresogo/Karriko/security/advisories/new';

/// Kontakt per E-Mail (Seiten-Tab 21).
///
/// Hier stand ein Formular, das nichts verschickte und trotzdem „Nachricht
/// gesendet!“ meldete (T-2.11). Bis es einen Eingang dafür gibt (T-2.29),
/// öffnet die Seite das Mailprogramm. Die Anliegen gehen alle an dieselbe
/// Adresse, sortiert über den vorbelegten Betreff; weitere Adressen gibt es
/// noch nicht. Eine Antwortzeit steht bewusst nicht da (T-11).
class KontaktScreen extends StatelessWidget {
  const KontaktScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: KarrikoAppBar(title: 'Kontakt'),
      drawer: KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(),
            _AnliegenSection(),
            _BewertungSection(),
            _AnbieterSection(),
            FooterWidget(),
          ],
        ),
      ),
    );
  }
}

/// `mailto:` mit vorbelegtem Betreff. Leerzeichen als `%20`, nicht als `+`,
/// sonst zeigen manche Mailprogramme die Pluszeichen im Betreff.
Uri kontaktMailto(String betreff) =>
    Uri.parse('mailto:$kontaktEmail?subject=${Uri.encodeComponent(betreff)}');

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
    final isWide = MediaQuery.of(context).size.width >= _wide;
    final vPad = isWide ? AppLayout.s64 : AppLayout.s48;

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

const _lead = TextStyle(color: AppColors.muted, fontSize: 17, height: 1.55);

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
            const _Kicker('KONTAKT'),
            const SizedBox(height: AppLayout.s24),
            Text(
              'Schreib uns.',
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
                'Fragen, Hinweise oder Kritik: Wähl dein Anliegen, dann öffnet '
                'sich dein Mailprogramm mit dem passenden Betreff. So landet '
                'deine Nachricht gleich an der richtigen Stelle.',
                style: _lead,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Anliegen ────────────────────────────────────────────────────────────────

class _AnliegenSection extends StatelessWidget {
  const _AnliegenSection();

  static const _anliegen = [
    (
      'Allgemeine Frage',
      'Zur Plattform, zum Fragebogen oder zu deinem Konto.',
      'Allgemeine Frage',
    ),
    (
      'Betriebe und Premium',
      'Für Ausbildungsbetriebe: Profil, Prüfung, Stellen und Premium.',
      'Betriebe und Premium',
    ),
    (
      'Kammern und Schulen',
      'Für Kammern, Berufsschulen und Beratungsstellen.',
      'Kammern und Schulen',
    ),
    (
      'Presse',
      'Anfragen von Redaktionen.',
      'Presseanfrage',
    ),
    (
      'Datenschutz, Auskunft, Löschung',
      'Auskunft und Löschung nach Art. 15 und 17 DSGVO. Azubis können ihr '
          'Konto auch selbst in den Einstellungen löschen und ihre Daten '
          'exportieren.',
      'Datenschutz',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _GridSection(
      kicker: 'ANLIEGEN',
      heading: 'Worum\ngeht es?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (titel, text, betreff) in _anliegen)
            _AnliegenRow(
              titel: titel,
              text: text,
              ziel: kontaktEmail,
              uri: kontaktMailto(betreff),
            ),
          // Sicherheitslücken gehen vertraulich an die Meldestelle aus
          // security.txt, nicht ins Postfach.
          _AnliegenRow(
            titel: 'Sicherheitslücke',
            text: 'Bitte vertraulich melden, nicht als öffentliches Issue.',
            ziel: 'GitHub Security Advisory',
            uri: Uri.parse(sicherheitsMeldung),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

/// Ein Anliegen als Zeile zwischen Haarlinien: links Titel und Satz, rechts
/// das Ziel in Akzentfarbe. Die ganze Zeile ist der Link (im Web ein <a>).
class _AnliegenRow extends StatelessWidget {
  final String titel;
  final String text;
  final String ziel;
  final Uri uri;
  final bool isLast;

  const _AnliegenRow({
    required this.titel,
    required this.text,
    required this.ziel,
    required this.uri,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Link(
      uri: uri,
      // mailto im selben Tab, sonst bleibt ein leerer Tab zurück.
      target: uri.isScheme('mailto') ? LinkTarget.self : LinkTarget.blank,
      builder: (context, followLink) => TapTarget(
        onTap: followLink,
        isLink: true,
        builder: (context, active) {
          final body = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titel,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppLayout.s8),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
            ],
          );

          final zielText = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  ziel,
                  style: TextStyle(
                    color: AppColors.accentDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration:
                        active ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: AppColors.accentDark,
                  ),
                ),
              ),
              const SizedBox(width: AppLayout.s8),
              const Icon(Icons.arrow_forward,
                  size: 16, color: AppColors.accentDark),
            ],
          );

          return Container(
            padding: const EdgeInsets.symmetric(vertical: AppLayout.s24),
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
                      Expanded(flex: 3, child: body),
                      const SizedBox(width: AppLayout.s32),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: zielText,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      body,
                      const SizedBox(height: AppLayout.s16),
                      zielText,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ─── Bewertung melden ────────────────────────────────────────────────────────

/// Bewertungen gehören in den Meldeweg, nicht ins allgemeine Postfach. Einen
/// Melden-Knopf an jeder Bewertung gibt es noch nicht (T-6.18); bis dahin
/// steht hier ehrlich, welcher Weg heute geht.
class _BewertungSection extends StatelessWidget {
  const _BewertungSection();

  @override
  Widget build(BuildContext context) {
    return _GridSection(
      kicker: 'BEWERTUNGEN',
      heading: 'Falsch oder\nrechtswidrig?',
      background: AppColors.audienceBeige,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: const Text(
              'Betriebe melden eine Bewertung in ihrem Bereich unter '
              '„Meldungen“. Alle anderen schreiben uns mit dem Link zur '
              'Bewertung und dem Grund, warum sie nicht stehen bleiben sollte.',
              style: _lead,
            ),
          ),
          const SizedBox(height: AppLayout.s24),
          Link(
            uri: kontaktMailto('Bewertung melden'),
            builder: (context, followLink) => ElevatedButton(
              onPressed: followLink,
              child: const Text('Bewertung melden'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Anbieter ────────────────────────────────────────────────────────────────

class _AnbieterSection extends StatelessWidget {
  const _AnbieterSection();

  @override
  Widget build(BuildContext context) {
    return _GridSection(
      kicker: 'ANBIETER',
      heading: 'Direkt\nerreichbar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Die Adresse steht als Text da, für alle ohne eingerichtetes
          // Mailprogramm.
          const Text(
            kontaktEmail,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: const Text(
              'Wer für Karriko verantwortlich ist, steht im Impressum.',
              style: _lead,
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
