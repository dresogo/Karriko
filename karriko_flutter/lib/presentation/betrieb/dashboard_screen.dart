import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../common/route_link.dart';
import '../common/app_page.dart';

class BetriebDashboardScreen extends ConsumerWidget {
  const BetriebDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final company = auth.user?.companyName;

    return AppPage(
      appBarTitle: 'Dashboard',
      eyebrow: 'BETRIEB',
      title: company?.isNotEmpty == true ? company! : 'Ihr Betrieb',
      lede: 'Bewertungen einsehen, Profil und Ausbildungsstellen pflegen.',
      headerAction: FilledButton.icon(
        onPressed: () => context.go('/betrieb-reviews'),
        icon: const Icon(Icons.rate_review_outlined, size: 18),
        label: const Text('Bewertungen ansehen'),
      ),
      children: const [
        _StatusBand(),
        SizedBox(height: AppLayout.s48),
        _MetricsNotice(),
        SizedBox(height: AppLayout.s48),
        SectionLabel('Verwaltung'),
        SizedBox(height: AppLayout.s16),
        _ManagementActions(),
        SizedBox(height: AppLayout.s48),
        _ProfileCompletion(),
      ],
    );
  }
}

// ─── Status ───────────────────────────────────────────────────────────────────

/// Prüfstatus des Betriebs und eine freiwillige Erinnerung an den zweiten
/// Faktor (T-6.38, Entscheidung vom 22.10.2026).
///
/// Der Prüfstatus steht hier, weil davon abhängt, ob Stellen veröffentlicht
/// werden können (`job_posting` verlangt das Abzeichen). Den zweiten Faktor
/// verlangt Karriko von Betrieben nicht (E-3.13 gilt nur für Moderation); die
/// Zeile verschwindet, sobald er aktiv ist.
class _StatusBand extends ConsumerWidget {
  const _StatusBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firma = ref.watch(myCompanyProvider).valueOrNull;
    final mfaAktiv = ref.watch(authProvider).user?.mfaEnabled ?? false;
    final text = Theme.of(context).textTheme;

    final zeilen = <Widget>[
      if (firma != null)
        _StatusZeile(
          icon: firma.isVerified
              ? Icons.verified_outlined
              : Icons.hourglass_empty,
          text: firma.isVerified
              ? 'Ihr Betrieb ist geprüft. Ausbildungsstellen können Sie '
                  'veröffentlichen.'
              : 'Ihr Betrieb wird noch geprüft. Stellen können Sie schon als '
                  'Entwurf anlegen, veröffentlicht werden sie nach der Prüfung.',
        ),
      if (!mfaAktiv)
        _StatusZeile(
          icon: Icons.shield_outlined,
          text: 'Empfehlung: Schützen Sie das Betriebskonto zusätzlich mit '
              'einem zweiten Faktor.',
          link: RouteLink(
            route: '/betrieb-settings/mfa',
            builder: (_, active) => Text(
              'Zwei-Faktor-Bestätigung einrichten',
              style: text.bodySmall?.copyWith(
                color: active ? AppColors.ink : AppColors.accentDark,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
    ];
    if (zeilen.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(left: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < zeilen.length; i++) ...[
            if (i > 0) const SizedBox(height: AppLayout.s16),
            zeilen[i],
          ],
        ],
      ),
    );
  }
}

class _StatusZeile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? link;

  const _StatusZeile({required this.icon, required this.text, this.link});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.ink),
        const SizedBox(width: AppLayout.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: Theme.of(context).textTheme.bodySmall),
              if (link != null) ...[
                const SizedBox(height: AppLayout.s8),
                link!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Kennzahlen ──────────────────────────────────────────────────────────────

/// An dieser Stelle standen bislang erfundene Kennzahlen (4,2 ⌀, 24 Bewertungen,
/// 1,2k Profilaufrufe) samt Score-Verlauf. Solange keine Auswertung angebunden
/// ist, benennt die Seite das offen, statt Zahlen zu zeigen, auf die ein Betrieb
/// Entscheidungen stützen würde. Profilaufrufe zählt Karriko noch nicht
/// (T-2.25), deshalb steht dafür auch kein Platzhalter (E-30, T-6.38).
class _MetricsNotice extends StatelessWidget {
  const _MetricsNotice();

  @override
  Widget build(BuildContext context) {
    const gap = AppLayout.s24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Kennzahlen'),
        const SizedBox(height: AppLayout.s16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 720 ? 2 : 1;
            final width = (constraints.maxWidth - (cols - 1) * gap) / cols;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: const [
                ('Ø Bewertung', 'Sobald Bewertungen vorliegen'),
                ('Bewertungen', 'Sobald Bewertungen vorliegen'),
              ]
                  .map((m) => (m.$1, m.$2))
                  .map(
                    (m) => SizedBox(
                      width: width,
                      child: _PendingStat(label: m.$1, hint: m.$2),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: AppLayout.s16),
        Container(
          padding: const EdgeInsets.all(AppLayout.s16),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(left: BorderSide(color: AppColors.line, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
              const SizedBox(width: AppLayout.s8),
              Expanded(
                child: Text(
                  'Die Auswertung Ihrer Bewertungen ist noch nicht angebunden. '
                  'Ihre eingegangenen Bewertungen finden Sie bereits unter '
                  '„Bewertungen".',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingStat extends StatelessWidget {
  final String label;
  final String hint;

  const _PendingStat({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '–',
            style: TextStyle(
              color: AppColors.line,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          SectionLabel(label),
          const SizedBox(height: 4),
          Text(hint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─── Verwaltung ──────────────────────────────────────────────────────────────

class _ManagementActions extends StatelessWidget {
  const _ManagementActions();

  static const _actions = <(IconData, String, String, String)>[
    (
      Icons.rate_review_outlined,
      'Bewertungen',
      'Feedback lesen',
      '/betrieb-reviews',
    ),
    (
      Icons.business_outlined,
      'Unternehmensprofil',
      'Angaben und Beschreibung pflegen',
      '/betrieb-profile',
    ),
    (
      Icons.work_outline,
      'Ausbildungsstellen',
      'Stellen ausschreiben und verwalten',
      '/betrieb-stellen',
    ),
    // Analytics, Team und Abonnement gibt es noch nicht (T-6.39); die
    // Routen leiten hierher zurueck.
    (
      Icons.flag_outlined,
      'Bewertungen melden',
      'Regelverstösse prüfen lassen',
      '/reports',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const gap = AppLayout.s16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = switch (constraints.maxWidth) {
          >= 900 => 3,
          >= 560 => 2,
          _ => 1,
        };
        final width = (constraints.maxWidth - (cols - 1) * gap) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in _actions)
              SizedBox(
                width: width,
                child: _ManagementCard(
                  icon: action.$1,
                  title: action.$2,
                  description: action.$3,
                  route: action.$4,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ManagementCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String route;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });

  @override
  State<_ManagementCard> createState() => _ManagementCardState();
}

class _ManagementCardState extends State<_ManagementCard> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.description}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        child: SelectionContainer.disabled(
          child: InkWell(
            onTap: () => context.go(widget.route),
            onFocusChange: (v) => setState(() => _focused = v),
            onHover: (v) => setState(() => _hovered = v),
            hoverColor: AppColors.paper,
            focusColor: AppColors.audienceBeige,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 108),
              padding: const EdgeInsets.all(AppLayout.s24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _focused ? AppColors.ink : AppColors.line,
                  width: _focused ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon, size: 20, color: AppColors.ink),
                      const SizedBox(width: AppLayout.s16),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        offset: _hovered || _focused
                            ? const Offset(0.25, 0)
                            : Offset.zero,
                        child: const Icon(Icons.arrow_forward,
                            size: 18, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.s8),
                  Text(widget.description,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profil-Vollständigkeit ──────────────────────────────────────────────────

class _ProfileCompletion extends StatelessWidget {
  const _ProfileCompletion();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Nächster Schritt'),
        const SizedBox(height: AppLayout.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vervollständigen Sie Ihr Profil',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppLayout.s8),
              Text(
                'Ein ausgefülltes Profil mit Beschreibung, Branche und Standort '
                'hilft Azubis bei der Einordnung Ihres Betriebs.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppLayout.s24),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => context.go('/betrieb-profile'),
                  child: const Text('Profil bearbeiten'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
