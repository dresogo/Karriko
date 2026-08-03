import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/review_provider.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/search_bar_widget.dart';
import '../common/review_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentReviews = ref.watch(recentReviewsProvider);

    return Scaffold(
      appBar: const KarrikoAppBar(showBack: false),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(),
            _MetricsSection(),
            _FeaturesSection(),
            _AudienceSection(),
            _RecentReviewsSection(recentReviews: recentReviews),
            _PrivacySection(),
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
      child: isWide
          ? SizedBox(
              height: MediaQuery.of(context).size.height - 76,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    flex: 53,
                    child: _HeroCopy(isWide: true),
                  ),
                  Container(width: 1, color: AppColors.line),
                  const Expanded(
                    flex: 37,
                    child: _SearchPanel(isWide: true),
                  ),
                ],
              ),
            )
          : const Column(
              children: [
                _HeroCopy(isWide: false),
                Divider(color: AppColors.line, height: 1),
                _SearchPanel(isWide: false),
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
    final vPad = isWide ? 96.0 : 40.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: eyebrow + headline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AUSBILDUNG TRANSPARENT MACHEN',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.32,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Bewertungen\nfür duale\nAusbildung.',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: isWide
                      ? (MediaQuery.of(context).size.width * 0.065)
                          .clamp(56.0, 120.0)
                      : 48,
                  fontWeight: FontWeight.w800,
                  height: 0.92,
                ),
              ),
            ],
          ),
          // Bottom: sub-text
          if (isWide)
            const Text(
              'Finde deinen Ausbildungsbetrieb, lies echte\nErfahrungsberichte und triff bessere Entscheidungen.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 17,
                height: 1.55,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final bool isWide;

  const _SearchPanel({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final hPad = isWide ? 64.0 : 20.0;
    final vPad = isWide ? 64.0 : 32.0;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Betrieb oder Beruf\nsuchen.',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          SizedBox(height: 18),
          HomeSearchBar(),
        ],
      ),
    );
  }
}

// ─── Metrics ─────────────────────────────────────────────────────────────────

class _MetricsSection extends StatelessWidget {
  static const _metrics = [
    ('2.400+', 'Bewertungen'),
    ('DACH', 'Fokusmarkt'),
    ('DSGVO', 'von Beginn an'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 720;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: isWide
          ? Row(
              children: _metrics.asMap().entries.map((e) {
                final isLast = e.key == _metrics.length - 1;
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: isLast
                            ? BorderSide.none
                            : const BorderSide(color: AppColors.line),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                    constraints: const BoxConstraints(minHeight: 170),
                    child: _MetricCell(value: e.value.$1, label: e.value.$2),
                  ),
                );
              }).toList(),
            )
          : Column(
              children: _metrics.asMap().entries.map((e) {
                final isLast = e.key == _metrics.length - 1;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: isLast
                          ? BorderSide.none
                          : const BorderSide(color: AppColors.line),
                    ),
                  ),
                  child: _MetricCell(value: e.value.$1, label: e.value.$2),
                );
              }).toList(),
            ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String value;
  final String label;

  const _MetricCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final fontSize =
        (MediaQuery.of(context).size.width * 0.05).clamp(38.0, 72.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 0.92,
          ),
        ),
        const SizedBox(height: 44),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Features ────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  static const _features = [
    (
      '01',
      'Bewerten',
      'Ausbildungsqualität, Betreuung, Lernkultur und Übernahmechancen strukturiert einordnen.'
    ),
    (
      '02',
      'Vergleichen',
      'Betriebe nach Beruf, Standort und Erfahrungswerten anderer Auszubildender entdecken.'
    ),
    (
      '03',
      'Vertrauen',
      'Moderierte Rezensionen schaffen hilfreiche Orientierung ohne unnötige Komplexität.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 980;
    final hPad = width > 720 ? 32.0 : 20.0;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section heading
                Container(
                  width: (width * 0.28).clamp(260.0, 400.0),
                  padding: EdgeInsets.fromLTRB(hPad, 86, hPad, 86),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.line)),
                  ),
                  child: _SectionHeading(),
                ),
                // Feature list
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
      'Klare Einblicke,\nbevor die\nBewerbung\nrausgeht.',
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

// ─── Audience band ───────────────────────────────────────────────────────────

class _AudienceSection extends StatelessWidget {
  static const _cards = [
    (
      'Azubi',
      'Erfahrungen teilen, Betriebe finden, Ausbildung realistischer einschätzen.',
      AppColors.surface,
      false
    ),
    (
      'Betrieb',
      'Profil pflegen, Feedback verstehen, Ausbildung als Qualitätsmerkmal zeigen.',
      AppColors.audienceBeige,
      false
    ),
    (
      'Stellen',
      'Moderation, Datenschutzprozesse und Plattformqualität zentral steuern.',
      AppColors.green,
      true
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 720;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: isWide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _cards.asMap().entries.map((e) {
                  final isLast = e.key == _cards.length - 1;
                  return Expanded(
                    child: _AudienceCard(
                      title: e.value.$1,
                      description: e.value.$2,
                      bgColor: e.value.$3,
                      inverted: e.value.$4,
                      borderRight: !isLast,
                    ),
                  );
                }).toList(),
              ),
            )
          : Column(
              children: _cards.asMap().entries.map((e) {
                final isLast = e.key == _cards.length - 1;
                return _AudienceCard(
                  title: e.value.$1,
                  description: e.value.$2,
                  bgColor: e.value.$3,
                  inverted: e.value.$4,
                  borderRight: false,
                  borderBottom: !isLast,
                );
              }).toList(),
            ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  final String title;
  final String description;
  final Color bgColor;
  final bool inverted;
  final bool borderRight;
  final bool borderBottom;

  const _AudienceCard({
    required this.title,
    required this.description,
    required this.bgColor,
    required this.inverted,
    this.borderRight = false,
    this.borderBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = inverted ? Colors.white : AppColors.ink;
    final descColor =
        inverted ? Colors.white.withValues(alpha: 0.78) : AppColors.muted;
    final fontSize =
        (MediaQuery.of(context).size.width * 0.04).clamp(32.0, 58.0);

    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: borderRight
              ? const BorderSide(color: AppColors.line)
              : BorderSide.none,
          bottom: borderBottom
              ? const BorderSide(color: AppColors.line)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              height: 0.96,
            ),
          ),
          const SizedBox(height: 96),
          Text(description,
              style: TextStyle(color: descColor, fontSize: 17, height: 1.55)),
        ],
      ),
    );
  }
}

// ─── Recent reviews ──────────────────────────────────────────────────────────

class _RecentReviewsSection extends StatelessWidget {
  final AsyncValue recentReviews;

  const _RecentReviewsSection({required this.recentReviews});

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width > 720 ? 32.0 : 20.0;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKTUELLE BEWERTUNGEN',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.96,
            ),
          ),
          const SizedBox(height: 24),
          recentReviews.when(
            data: (reviews) => Column(
              children: (reviews as List)
                  .map<Widget>((r) => Container(
                        decoration: const BoxDecoration(
                          border:
                              Border(bottom: BorderSide(color: AppColors.line)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ReviewCard(review: r, showCompany: true),
                      ))
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Fehler beim Laden der Bewertungen.'),
          ),
        ],
      ),
    );
  }
}

// ─── Privacy ─────────────────────────────────────────────────────────────────

class _PrivacySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 980;
    final hPad = width > 720 ? 32.0 : 20.0;
    final vPad = (width * 0.08).clamp(48.0, 96.0);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 40,
                  child: _PrivacyHeading(),
                ),
                SizedBox(width: (width * 0.08).clamp(32.0, 120.0)),
                Expanded(
                  flex: 60,
                  child: _PrivacyBody(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrivacyHeading(),
                const SizedBox(height: 24),
                _PrivacyBody(),
              ],
            ),
    );
  }
}

class _PrivacyHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fontSize =
        (MediaQuery.of(context).size.width * 0.045).clamp(36.0, 72.0);
    return Text(
      'Datenschutz\nist kein\nZusatzmodul.',
      style: TextStyle(
        color: AppColors.ink,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 0.96,
      ),
    );
  }
}

class _PrivacyBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fontSize =
        (MediaQuery.of(context).size.width * 0.018).clamp(17.0, 26.0);
    return Text(
      'RLS-Policies, AVV-Anforderungen und eine DSGVO-konforme Architektur sind als Produktprinzipien angelegt. Die Gestaltung bleibt bewusst ruhig, damit Vertrauen, Nachvollziehbarkeit und Bewertungsqualität im Vordergrund stehen.',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: fontSize,
        height: 1.35,
      ),
    );
  }
}
