import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
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
      title: company?.isNotEmpty == true ? company! : 'Dein Betrieb',
      lede: 'Bewertungen einsehen, auf Feedback antworten und dein Profil pflegen.',
      headerAction: FilledButton.icon(
        onPressed: () => context.go('/betrieb-reviews'),
        icon: const Icon(Icons.rate_review_outlined, size: 18),
        label: const Text('Bewertungen ansehen'),
      ),
      children: const [
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

// ─── Kennzahlen ──────────────────────────────────────────────────────────────

/// An dieser Stelle standen bislang erfundene Kennzahlen (4,2 ⌀, 24 Bewertungen,
/// 1,2k Profilaufrufe) samt Score-Verlauf. Solange keine Auswertung angebunden
/// ist, benennt die Seite das offen, statt Zahlen zu zeigen, auf die ein Betrieb
/// Entscheidungen stützen würde.
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
            final cols = constraints.maxWidth >= 720 ? 3 : 1;
            final width = (constraints.maxWidth - (cols - 1) * gap) / cols;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: const [
                ('Ø Bewertung', 'Sobald Bewertungen vorliegen'),
                ('Bewertungen', 'Sobald Bewertungen vorliegen'),
                ('Profilaufrufe', 'Auswertung folgt'),
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
                  'Die Auswertung deiner Bewertungen ist noch nicht angebunden. '
                  'Deine eingegangenen Bewertungen findest du bereits unter '
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
      'Feedback lesen und beantworten',
      '/betrieb-reviews',
    ),
    (
      Icons.business_outlined,
      'Unternehmensprofil',
      'Angaben und Beschreibung pflegen',
      '/betrieb-profile',
    ),
    (
      Icons.insights_outlined,
      'Analytics',
      'Entwicklung im Zeitverlauf',
      '/analytics',
    ),
    (
      Icons.flag_outlined,
      'Bewertungen melden',
      'Regelverstösse prüfen lassen',
      '/reports',
    ),
    (
      Icons.group_outlined,
      'Team',
      'Zugriffe im Unternehmen verwalten',
      '/team',
    ),
    (
      Icons.card_membership_outlined,
      'Abonnement',
      'Tarif und Leistungen',
      '/subscription',
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
                      offset: _hovered || _focused ? const Offset(0.25, 0) : Offset.zero,
                      child: const Icon(Icons.arrow_forward, size: 18, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.s8),
                Text(widget.description, style: Theme.of(context).textTheme.bodySmall),
              ],
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
                'Vervollständige dein Profil',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppLayout.s8),
              Text(
                'Ein ausgefülltes Profil mit Beschreibung, Branche und Standort '
                'hilft Azubis bei der Einordnung deines Betriebs.',
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
