import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/tap_target.dart';

/// Für Betriebe: die Verkaufsseite für Ausbildungsbetriebe.
///
/// Aufbau nach dem Seiten-Tab „13 Für Betriebe“: Hero mit Profil-Check,
/// Leistungen, Ablauf, faire Regeln, Preise, Datenschutz, Fragen,
/// Schluss-Band. Anrede mit Sie (F-8). Hier steht nur, was es gibt (E-30,
/// T-11.7): keine Auswertung, keine Antworten auf Bewertungen (T-8.1), kein
/// Preis für Premium (T-8.4), kein AVV- oder TOM-Dokument (T-9.7).
class FuerBetriebeScreen extends StatelessWidget {
  const FuerBetriebeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: KarrikoAppBar(),
      drawer: KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(),
            _FeaturesSection(),
            _ProcessSection(),
            _RulesSection(),
            _PricingSection(),
            _SecuritySection(),
            _FaqSection(),
            _CtaSection(),
            FooterWidget(),
          ],
        ),
      ),
    );
  }
}

/// Breite, ab der Abschnitte zweispaltig stehen (Factsheet §2.3: 1024).
const _wide = 1024.0;

bool _isWide(BuildContext context) =>
    MediaQuery.of(context).size.width >= _wide;

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

/// Abschnittstitel im Display-Stil, auf schmalen Bildschirmen kleiner.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.ink,
        fontSize: _isWide(context) ? 40 : 30,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );
  }
}

/// Vollflächiges Band mit Haarlinie unten; der Inhalt steht im Satzspiegel.
class _Band extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Band({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final vPad =
        _isWide(context) ? AppLayout.s64 + AppLayout.s24 : AppLayout.s48;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(vertical: vPad),
        child: child,
      ),
    );
  }
}

/// Seitenmuster `section-grid`: links Kicker und Titel (⅓), rechts der
/// Inhalt (⅔); unter [_wide] untereinander.
class _Grid extends StatelessWidget {
  final String kicker;
  final String title;
  final Widget child;

  const _Grid({required this.kicker, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Kicker(kicker),
        const SizedBox(height: AppLayout.s16),
        _SectionTitle(title),
      ],
    );
    if (!_isWide(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [heading, const SizedBox(height: AppLayout.s32), child],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: heading),
        const SizedBox(width: AppLayout.s64),
        Expanded(flex: 2, child: child),
      ],
    );
  }
}

/// Primär- und Sekundäraktion der Seite, umbrechend bei wenig Platz.
class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppLayout.s16,
      runSpacing: AppLayout.s16,
      children: [
        ElevatedButton(
          onPressed: () => context.go('/register/betrieb'),
          // Flexible: bei großer Schrift auf dem Smartphone bricht die
          // Beschriftung um, statt über den Knopf hinauszulaufen.
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text('Betriebsprofil anlegen')),
              SizedBox(width: AppLayout.s8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () => context.go('/login/betrieb'),
          child: const Text('Anmelden'),
        ),
      ],
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _wide;
    // „Qualitätsmerkmal.“ ist ein langes Wort und muss in einer Zeile der
    // Textspalte bleiben; sonst bricht Flutter es mitten im Wort um.
    final titleSize = isWide
        ? (width * 0.042).clamp(44.0, 64.0)
        : (width * 0.085).clamp(28.0, 40.0);

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Kicker('FÜR AUSBILDUNGSBETRIEBE'),
        const SizedBox(height: AppLayout.s24),
        Text(
          'Ausbildung als\nQualitätsmerkmal.',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 0.94,
            letterSpacing: isWide ? -1 : -0.5,
          ),
        ),
        SizedBox(height: isWide ? AppLayout.s32 : AppLayout.s24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const Text(
            'Zeigen Sie Bewerberinnen und Bewerbern, wie bei Ihnen ausgebildet '
            'wird. Mit einem Profil, das Ihre Azubis mitschreiben, und Ihren '
            'Ausbildungsstellen direkt daneben.',
            style:
                TextStyle(color: AppColors.muted, fontSize: 17, height: 1.55),
          ),
        ),
        SizedBox(height: isWide ? AppLayout.s48 : AppLayout.s32),
        const _Actions(),
      ],
    );

    return _Band(
      color: AppColors.audienceBeige,
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: copy),
                const SizedBox(width: AppLayout.s64),
                const Expanded(flex: 2, child: _ProfileCheck()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: AppLayout.s48),
                const _ProfileCheck(),
              ],
            ),
    );
  }
}

/// Profil-Check: Viele Betriebe stehen schon auf Karriko, weil Azubis sie
/// bewertet haben. Die Suche führt auf die Betriebssuche mit dem Namen in der
/// Adresse (T-11.17); dort steht das Profil, falls es eins gibt.
class _ProfileCheck extends StatefulWidget {
  const _ProfileCheck();

  @override
  State<_ProfileCheck> createState() => _ProfileCheckState();
}

class _ProfileCheckState extends State<_ProfileCheck> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final q = _controller.text.trim();
    context.go(Uri(
      path: '/search',
      queryParameters: q.isEmpty ? null : {'q': q},
    ).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Kicker('PROFIL-CHECK'),
          const SizedBox(height: AppLayout.s16),
          const Text(
            'Ist Ihr Betrieb schon auf Karriko?',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          const Text(
            'Azubis können Betriebe bewerten, bevor diese selbst registriert '
            'sind. Suchen Sie nach Ihrem Namen.',
            style:
                TextStyle(color: AppColors.muted, fontSize: 15, height: 1.55),
          ),
          const SizedBox(height: AppLayout.s24),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: const InputDecoration(
              labelText: 'Name des Betriebs',
              prefixIcon: Icon(Icons.search, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          OutlinedButton(
            onPressed: _search,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Betrieb suchen'),
          ),
        ],
      ),
    );
  }
}

// ─── Leistungen ──────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  static const _features = [
    (
      '01',
      'Öffentliches Profil',
      'Stellen Sie Ihren Betrieb mit Beschreibung, Website und Standort vor.',
    ),
    (
      '02',
      'Bewertungen einsehen',
      'Lesen Sie, was aktuelle und ehemalige Azubis über die Ausbildung bei '
          'Ihnen sagen. Einen Gesamtwert zeigen wir ab drei Bewertungen.',
    ),
    (
      '03',
      'Ausbildungsstellen ausschreiben',
      'Ihre Stellen stehen auf Ihrem Profil und in der Suche, direkt neben '
          'den Bewertungen.',
    ),
    (
      '04',
      'Bewertungen melden',
      'Verstößt eine Bewertung gegen unsere Regeln, melden Sie sie. Jede '
          'Meldung prüft ein Mensch.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Band(
      child: _Grid(
        kicker: 'LEISTUNGEN',
        title: 'Was Karriko\nfür Betriebe\nbietet.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, f) in _features.indexed)
              _NumberedRow(
                number: f.$1,
                title: f.$2,
                text: f.$3,
                isLast: i == _features.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

/// Zeile mit Nummer, Titel und Text zwischen Haarlinien.
class _NumberedRow extends StatelessWidget {
  final String number;
  final String title;
  final String text;
  final bool isLast;

  const _NumberedRow({
    required this.number,
    required this.title,
    required this.text,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    final numberText = Text(
      number,
      style: const TextStyle(
        color: AppColors.accentDark,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
              color: AppColors.muted, fontSize: 17, height: 1.55),
        ),
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
                SizedBox(
                  width: 64,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: numberText,
                  ),
                ),
                Expanded(child: body),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                numberText,
                const SizedBox(height: AppLayout.s8),
                body,
              ],
            ),
    );
  }
}

// ─── Ablauf ──────────────────────────────────────────────────────────────────

class _ProcessSection extends StatelessWidget {
  const _ProcessSection();

  // Menschliche Prüfung nach E-40; Stellen erst danach öffentlich
  // (job_posting, FAQ „Für Betriebe“).
  static const _steps = [
    (
      '1',
      'Registrieren',
      'Konto anlegen und E-Mail-Adresse bestätigen. Dabei entsteht Ihr Profil.',
    ),
    (
      '2',
      'Wir prüfen Ihren Betrieb',
      'Ein Mensch prüft Ihre Angaben, bevor Ihr Betrieb als geprüft gilt.',
    ),
    (
      '3',
      'Profil pflegen, Stellen ausschreiben',
      'Ihr Profil pflegen Sie sofort. Stellen bereiten Sie als Entwurf vor und '
          'veröffentlichen sie nach der Prüfung.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 768;

    final steps = [
      for (final s in _steps)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                s.$1,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            Container(height: 2, width: 32, color: AppColors.ink),
            const SizedBox(height: AppLayout.s24),
            Text(
              s.$2,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppLayout.s8),
            Text(
              s.$3,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 17, height: 1.55),
            ),
          ],
        ),
    ];

    return _Band(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Kicker('SO LÄUFT ES AB'),
          const SizedBox(height: AppLayout.s16),
          const _SectionTitle('In drei Schritten zum Profil.'),
          SizedBox(height: isWide ? AppLayout.s64 : AppLayout.s48),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, step) in steps.indexed) ...[
                  if (i > 0) const SizedBox(width: AppLayout.s48),
                  Expanded(child: step),
                ],
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, step) in steps.indexed) ...[
                  if (i > 0) const SizedBox(height: AppLayout.s48),
                  step,
                ],
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Faire Regeln ────────────────────────────────────────────────────────────

class _RulesSection extends StatelessWidget {
  const _RulesSection();

  // E-29; Löschen auf Wunsch gibt es nicht (FAQ „Für Betriebe“), jede
  // Meldung prüft ein Mensch (E-2.13).
  static const _rules = [
    'Bewertungen und ihre Reihenfolge sind nicht käuflich, auch nicht mit '
        'Premium.',
    'Bewertungen werden nicht auf Wunsch entfernt. Verstöße melden Sie, wir '
        'prüfen jede Meldung.',
    'Ihr Profil bleibt frei von Werbung für Mitbewerber, auch im kostenlosen '
        'Tarif.',
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = _isWide(context);
    // Auf der dunklen Fläche: Papier statt Tinte, gedämpft für Nebentext und
    // Linien. Keine neuen Farbwerte, nur Deckkraft (Factsheet §2.1).
    final paperMuted = AppColors.paper.withValues(alpha: 0.8);
    final paperLine = AppColors.paper.withValues(alpha: 0.2);

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in _rules)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppLayout.s24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: paperLine)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.check, size: 20, color: AppColors.accent),
                ),
                const SizedBox(width: AppLayout.s16),
                Expanded(
                  child: Text(
                    rule,
                    style: const TextStyle(
                      color: AppColors.paper,
                      fontSize: 19,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppLayout.s16),
        TapTarget(
          onTap: () => context.go('/transparenz'),
          builder: (context, active) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppLayout.s8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'So funktioniert Karriko',
                    style: TextStyle(
                      color: AppColors.paper,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: active
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: AppColors.paper,
                    ),
                  ),
                ),
                const SizedBox(width: AppLayout.s8),
                const Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.paper),
              ],
            ),
          ),
        ),
      ],
    );

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAIRE REGELN',
          style: TextStyle(
            color: paperMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.32,
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        Text(
          'Was Geld\nnicht kauft.',
          style: TextStyle(
            color: AppColors.paper,
            fontSize: isWide ? 56 : 36,
            fontWeight: FontWeight.w800,
            height: 0.96,
          ),
        ),
      ],
    );

    return _Band(
      color: AppColors.ink,
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: heading),
                const SizedBox(width: AppLayout.s64),
                Expanded(flex: 2, child: list),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: AppLayout.s32), list],
            ),
    );
  }
}

// ─── Preise ──────────────────────────────────────────────────────────────────

class _PricingSection extends StatelessWidget {
  const _PricingSection();

  static const _basis = _PricingCard(
    name: 'BASIS',
    price: 'Kostenlos',
    features: [
      'Öffentliches Profil',
      'Bewertungen einsehen',
      'Ausbildungsstellen ausschreiben',
      'Bewertungen melden',
    ],
    isPremium: false,
  );

  // Umfang und Preis sind offen (T-8.4); fest steht nur, was Premium nie
  // sein darf (E-29). Kein „Empfohlen“, solange es nichts zu kaufen gibt.
  static const _premium = _PricingCard(
    name: 'PREMIUM',
    price: 'In Planung',
    features: [
      'Mehr Möglichkeiten, den Betrieb darzustellen',
      'Kein Einfluss auf Bewertungen oder ihre Reihenfolge',
      'Umfang und Preis stehen noch nicht fest',
    ],
    isPremium: true,
  );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return _Band(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Kicker('PLÄNE & PREISE'),
          const SizedBox(height: AppLayout.s16),
          const _SectionTitle('Kostenlos starten.'),
          const SizedBox(height: AppLayout.s48),
          if (isWide)
            const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _basis),
                  SizedBox(width: AppLayout.s24),
                  Expanded(child: _premium),
                ],
              ),
            )
          else
            const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_basis, SizedBox(height: AppLayout.s24), _premium],
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
  final bool isPremium;

  const _PricingCard({
    required this.name,
    required this.price,
    required this.features,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 768;

    return Container(
      padding: EdgeInsets.all(isWide ? AppLayout.s32 : AppLayout.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: isPremium ? AppColors.ink : AppColors.line,
          width: isPremium ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.32,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          Text(
            price,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: (width * 0.035).clamp(32.0, 48.0),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: AppLayout.s32),
          for (final f in features)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      isPremium ? Icons.remove : Icons.check,
                      size: 16,
                      color: isPremium ? AppColors.muted : AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                          color: AppColors.ink, fontSize: 15, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          // Breit sind die Kacheln gleich hoch und die Knöpfe sitzen bündig
          // unten; schmal läuft die Höhe frei.
          if (isWide) const Spacer() else const SizedBox(height: AppLayout.s24),
          const SizedBox(height: AppLayout.s24),
          SizedBox(
            width: double.infinity,
            child: isPremium
                ? OutlinedButton(
                    onPressed: () => context.go('/kontakt'),
                    child: const Text('Interesse melden'),
                  )
                : ElevatedButton(
                    onPressed: () => context.go('/register/betrieb'),
                    child: const Text('Kostenlos starten'),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Datenschutz und Sicherheit ──────────────────────────────────────────────

class _SecuritySection extends StatelessWidget {
  const _SecuritySection();

  // E-02, E-3.12, E-3.13 (TOTP für Betriebskonten über die Einstellungen).
  static const _facts = [
    (
      'Frankfurt am Main',
      'Konten, Profile und Bewertungen liegen auf Servern in Frankfurt.',
    ),
    (
      'Zwei-Faktor',
      'Sichern Sie Ihr Betriebskonto zusätzlich mit einer Authenticator-App.',
    ),
    (
      'Leckprüfung',
      'Passwörter, die aus bekannten Datenlecks stammen, lehnen wir ab.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    final cells = [
      for (final f in _facts)
        Container(
          padding: const EdgeInsets.only(top: AppLayout.s24),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.$1,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppLayout.s8),
              Text(
                f.$2,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 15, height: 1.55),
              ),
            ],
          ),
        ),
    ];

    return _Band(
      child: _Grid(
        kicker: 'DATENSCHUTZ & SICHERHEIT',
        title: 'Gespeichert in Frankfurt.',
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, c) in cells.indexed) ...[
                    if (i > 0) const SizedBox(width: AppLayout.s32),
                    Expanded(child: c),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, c) in cells.indexed) ...[
                    if (i > 0) const SizedBox(height: AppLayout.s32),
                    c,
                  ],
                ],
              ),
      ),
    );
  }
}

// ─── Fragen von Betrieben ────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  // Aus der FAQ-Rubrik „Für Betriebe“ (faq_screen.dart), in der Sie-Form;
  // die dritte Frage stammt aus „Für Azubis“ und betrifft Betriebe ebenso.
  static const _items = [
    (
      'Wie bekomme ich ein Unternehmensprofil?',
      'Registrieren Sie sich als Betrieb und bestätigen Sie Ihre '
          'E-Mail-Adresse; dabei entsteht Ihr Profil. Danach prüfen wir Ihren '
          'Betrieb. Ausbildungsstellen veröffentlichen können Sie nach dieser '
          'Prüfung, als Entwurf vorbereiten schon vorher.',
    ),
    (
      'Können wir Bewertungen löschen lassen?',
      'Bewertungen werden nicht auf Wunsch entfernt. Verstößt ein Beitrag '
          'gegen unsere Richtlinien, können Sie ihn melden. Wir prüfen jede '
          'Meldung.',
    ),
    (
      'Können wir sehen, wer uns bewertet hat?',
      'Nein. Sie sehen weder Namen noch E-Mail-Adresse. Einen Gesamtwert '
          'zeigen wir erst ab drei Bewertungen, damit sich eine einzelne nicht '
          'zuordnen lässt.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Band(
      child: _Grid(
        kicker: 'FRAGEN',
        title: 'Was Betriebe uns fragen.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in _items.indexed)
              _FaqItem(
                question: item.$1,
                answer: item.$2,
                isLast: i == _items.length - 1,
              ),
            const SizedBox(height: AppLayout.s24),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.go('/faq'),
                child: const Text('Alle häufigen Fragen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aufklappbare Frage. Die Frage ist das Klickziel ([TapTarget]); offen steht
/// ein Minus, zu ein Plus.
class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool isLast;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isLast,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: AppColors.line),
          bottom: widget.isLast
              ? const BorderSide(color: AppColors.line)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: _open,
            child: TapTarget(
              onTap: () => setState(() => _open = !_open),
              builder: (context, active) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppLayout.s24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: TextStyle(
                          color: active ? AppColors.accentDark : AppColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppLayout.s16),
                    Icon(
                      _open ? Icons.remove : Icons.add,
                      size: 22,
                      color: active ? AppColors.accentDark : AppColors.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppLayout.s24,
                right: AppLayout.s48,
              ),
              child: Text(
                widget.answer,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 17, height: 1.55),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Abschluss ───────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _wide;

    final heading = Text(
      'Bereit\nloszulegen?',
      style: TextStyle(
        color: AppColors.ink,
        // Schmal genug, dass „loszulegen?“ in der Drittelspalte bleibt.
        fontSize: isWide ? (width * 0.035).clamp(40.0, 56.0) : 36,
        fontWeight: FontWeight.w800,
        height: 0.96,
      ),
    );

    const body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legen Sie Ihr Betriebsprofil kostenlos an.',
          style: TextStyle(color: AppColors.muted, fontSize: 19, height: 1.45),
        ),
        SizedBox(height: AppLayout.s32),
        _Actions(),
      ],
    );

    return _Band(
      color: AppColors.audienceBeige,
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: heading),
                const SizedBox(width: AppLayout.s64),
                const Expanded(flex: 2, child: body),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: AppLayout.s32), body],
            ),
    );
  }
}
