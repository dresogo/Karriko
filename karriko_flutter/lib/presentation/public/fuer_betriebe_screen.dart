import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

/// Horizontale Randbreite der vollflächigen Bänder – identisch zur Startseite.
double _hPad(BuildContext context) =>
    MediaQuery.of(context).size.width > 720 ? 32.0 : 20.0;

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
    final isWide = width > 980;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      // Die Höhe folgt dem Inhalt: der Hero füllt bewusst nicht den ganzen
      // Bildschirm, damit die Merkmale schon ohne Scrollen anreißen.
      //
      // Fläche und Trennlinie liegen als eigene Ebene hinter dem Inhalt, statt
      // die Spalten per IntrinsicHeight auf gleiche Höhe zu zwingen: dessen
      // Höhenmessung ist über Expanded-Spalten mit umbrechendem Text ungenau
      // und lässt die Textspalte überlaufen.
      child: isWide
          ? Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      const Expanded(flex: 53, child: SizedBox.expand()),
                      Container(width: 1, color: AppColors.line),
                      const Expanded(
                        flex: 37,
                        child: ColoredBox(color: AppColors.surface),
                      ),
                    ],
                  ),
                ),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 53, child: _HeroCopy(isWide: true)),
                    SizedBox(width: 1),
                    Expanded(flex: 37, child: _RegisterPanel(isWide: true)),
                  ],
                ),
              ],
            )
          : const Column(
              children: [
                _HeroCopy(isWide: false),
                Divider(color: AppColors.line, height: 1),
                _RegisterPanel(isWide: false),
              ],
            ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final bool isWide;

  const _HeroCopy({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final hPad = isWide ? 32.0 : 20.0;
    final vPad = isWide ? 72.0 : 40.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
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
          const SizedBox(height: 22),
          Text(
            'Ausbildung als\nQualitätsmerkmal.',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: isWide
                  ? (MediaQuery.of(context).size.width * 0.05).clamp(42.0, 72.0)
                  : 34,
              fontWeight: FontWeight.w800,
              height: 0.94,
            ),
          ),
          SizedBox(height: isWide ? 40 : 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: const Text(
              'Verwalte dein Profil, verstehe Feedback und zeige Bewerbern, '
              'warum dein Betrieb die richtige Wahl ist.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 17,
                height: 1.55,
              ),
            ),
          ),
          SizedBox(height: isWide ? 56 : 36),
          const _TrustRow(),
        ],
      ),
    );
  }
}

/// Belegzeile unter dem Fließtext: drei Kennzahlen der Plattform, durch
/// Haarlinien getrennt – dasselbe Muster wie das Kennzahlenband der Startseite,
/// nur auf Hero-Maßstab verkleinert.
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _facts = [
    ('2.400+', 'Bewertungen'),
    ('DACH', 'Fokusmarkt'),
    ('DSGVO', 'von Beginn an'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.only(top: 20),
      // Einzeilige Texte mit Ellipse: die Zeilenhöhe bleibt damit unabhängig
      // von der zugeteilten Breite, auch bei vergrößerter Systemschrift.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, fact) in _facts.indexed) ...[
            if (index > 0)
              Container(
                width: 1,
                height: 38,
                color: AppColors.line,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fact.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fact.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aktionsfläche des Heros. Aufgebaut wie eine Karteikarte: Kicker, Titel, die
/// im Basis-Tarif enthaltenen Leistungen als Haarlinien-Liste und darunter die
/// einzige primäre Aktion der Seite.
class _RegisterPanel extends StatelessWidget {
  final bool isWide;

  const _RegisterPanel({required this.isWide});

  static const _included = [
    'Öffentliches Profil',
    'Bewertungen einsehen',
    'Auf Bewertungen antworten',
  ];

  @override
  Widget build(BuildContext context) {
    final hPad = isWide ? 40.0 : 20.0;
    final vPad = isWide ? 56.0 : 36.0;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'KOSTENLOS STARTEN',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.32,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Betriebsprofil\nanlegen.',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 28),
          for (final (index, item) in _included.indexed)
            _IncludedRow(label: item, isLast: index == _included.length - 1),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/register/betrieb'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Row(
                children: [
                  Expanded(child: Text('Jetzt registrieren')),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Wrap statt Row: bei vergrößerter Systemschrift rutscht der Link
          // unter den Text, statt die Zeile zu sprengen.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Schon dabei?',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Anmelden'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Eine Leistungszeile im Aktionspanel: Haarlinie oben, Häkchen im Akzent.
class _IncludedRow extends StatelessWidget {
  final String label;
  final bool isLast;

  const _IncludedRow({required this.label, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: AppColors.line),
          bottom: isLast
              ? const BorderSide(color: AppColors.line)
              : BorderSide.none,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Features ────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  static const _features = [
    (
      '01',
      'Profil verwalten',
      'Präsentiere deinen Betrieb mit Logo, Beschreibung und Ansprechpartnern.'
    ),
    (
      '02',
      'Bewertungen einsehen',
      'Erhalte detailliertes Feedback von aktuellen und ehemaligen Azubis.'
    ),
    (
      '03',
      'Auf Bewertungen antworten',
      'Reagiere professionell auf Kritik und zeige, dass du Feedback ernst nimmst.'
    ),
    (
      '04',
      'Analytics nutzen',
      'Verstehe Trends und vergleiche dich mit anderen Betrieben deiner Branche.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 980;
    final hPad = _hPad(context);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sektionsüberschrift
                Container(
                  width: (width * 0.28).clamp(260.0, 400.0),
                  padding: EdgeInsets.fromLTRB(hPad, 86, hPad, 86),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.line)),
                  ),
                  child: _SectionHeading(),
                ),
                // Merkmalsliste
                Expanded(
                  child: Column(
                    children: _features.asMap().entries.map((e) {
                      final isLast = e.key == _features.length - 1;
                      return _FeatureRow(
                        number: e.value.$1,
                        title: e.value.$2,
                        description: e.value.$3,
                        isLast: isLast,
                        isWide: true,
                      );
                    }).toList(),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(hPad, 44, hPad, 44),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: _SectionHeading(),
                ),
                ..._features.asMap().entries.map((e) => _FeatureRow(
                      number: e.value.$1,
                      title: e.value.$2,
                      description: e.value.$3,
                      isLast: e.key == _features.length - 1,
                      isWide: false,
                    )),
              ],
            ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fontSize =
        (MediaQuery.of(context).size.width * 0.045).clamp(36.0, 72.0);
    return Text(
      'Was Karriko\nfür Betriebe\nbietet.',
      style: TextStyle(
        color: AppColors.ink,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 0.96,
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final bool isLast;
  final bool isWide;

  const _FeatureRow({
    required this.number,
    required this.title,
    required this.description,
    required this.isLast,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 162),
      padding: EdgeInsets.all(isWide ? 32 : 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.line),
        ),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: Text(number,
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  flex: 45,
                  child: Text(title,
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 26),
                Expanded(
                  flex: 100,
                  child: Text(description,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 17, height: 1.55)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(title,
                    style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(description,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 17, height: 1.55)),
              ],
            ),
    );
  }
}

// ─── Preise ──────────────────────────────────────────────────────────────────

class _PricingSection extends StatelessWidget {
  /// Gasse zwischen den beiden Tarifkarten.
  static const _gap = AppLayout.s24;

  static const _basis = _PricingCard(
    name: 'BASIS',
    price: 'Kostenlos',
    features: [
      'Öffentliches Profil',
      'Bewertungen einsehen',
      'Auf Bewertungen antworten',
    ],
    isPrimary: false,
  );

  static const _premium = _PricingCard(
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;
    final hPad = _hPad(context);

    // Die Tarife stehen als eigenständige Karten im Satzspiegel: Abstand zu
    // beiden Seitenrändern und eine Gasse dazwischen, statt bündig durchlaufend.
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 48),
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
          const SizedBox(height: 24),
          if (isWide)
            const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _basis),
                  SizedBox(width: _gap),
                  Expanded(child: _premium),
                ],
              ),
            )
          else
            const Column(
              children: [_basis, SizedBox(height: _gap), _premium],
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
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 720;
    final bg = isPrimary ? AppColors.ink : AppColors.surface;
    final titleColor = isPrimary ? Colors.white : AppColors.ink;
    final mutedColor =
        isPrimary ? Colors.white.withValues(alpha: 0.78) : AppColors.muted;
    final priceSize = (width * 0.04).clamp(32.0, 58.0);

    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: EdgeInsets.all(isWide ? 32 : 20),
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
            const SizedBox(height: 8),
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
          const SizedBox(height: 22),
          Text(
            price,
            style: TextStyle(
              color: titleColor,
              fontSize: priceSize,
              fontWeight: FontWeight.w800,
              height: 0.96,
            ),
          ),
          const SizedBox(height: 44),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                          color: mutedColor, fontSize: 17, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Breit: Karten sind gleich hoch, die Schaltflächen sitzen bündig
          // am unteren Rand. Schmal: fester Abstand, da die Höhe frei läuft.
          if (isWide) const Spacer() else const SizedBox(height: 32),
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

// ─── Abschluss ───────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 980;
    final hPad = _hPad(context);
    final vPad = (width * 0.08).clamp(48.0, 96.0);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 40, child: _CtaHeading()),
                SizedBox(width: (width * 0.08).clamp(32.0, 120.0)),
                Expanded(flex: 60, child: _CtaBody()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CtaHeading(),
                const SizedBox(height: 24),
                _CtaBody(),
              ],
            ),
    );
  }
}

class _CtaHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fontSize =
        (MediaQuery.of(context).size.width * 0.045).clamp(36.0, 72.0);
    return Text(
      'Bereit\nloszulegen?',
      style: TextStyle(
        color: AppColors.ink,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 0.96,
      ),
    );
  }
}

class _CtaBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fontSize =
        (MediaQuery.of(context).size.width * 0.018).clamp(17.0, 26.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Erstelle jetzt dein kostenloses Betriebsprofil.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: fontSize,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.go('/register/betrieb'),
          child: const Text('Jetzt registrieren'),
        ),
      ],
    );
  }
}
