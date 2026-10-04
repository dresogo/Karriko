import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_models.dart';
import '../../common/app_page.dart';
import '../admin_providers.dart';
import '../admin_sections.dart';
import '../widgets/admin_widgets.dart';
import 'log_section.dart';

class OverviewSection extends ConsumerWidget {
  final String? name;
  final ValueChanged<AdminSection> onNavigate;

  const OverviewSection({super.key, this.name, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminOverviewProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          eyebrow: 'ÜBERSICHT',
          title: name == null ? 'Guten Tag.' : 'Hallo, $name.',
          lede: 'Was gerade auf eine Entscheidung wartet und was zuletzt '
              'entschieden wurde.',
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(adminOverviewProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Aktualisieren'),
          ),
        ),
        const SizedBox(height: AppLayout.s48),
        overview.when(
          loading: () => const AdminLoadingList(count: 2, height: 120),
          error: (e, _) => AdminErrorBox(
            error: e,
            onRetry: () => ref.invalidate(adminOverviewProvider),
          ),
          data: (o) => _Inhalt(o: o, onNavigate: onNavigate),
        ),
      ],
    );
  }
}

class _Inhalt extends StatelessWidget {
  final AdminOverview o;
  final ValueChanged<AdminSection> onNavigate;

  const _Inhalt({required this.o, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final kacheln = [
      _Kachel(
        wert: o.pending,
        label: 'Wartet auf Moderation',
        icon: Icons.inbox_outlined,
        dringend: o.pending > 0,
        onTap: () => onNavigate(AdminSection.moderation),
      ),
      _Kachel(
        wert: o.openReports,
        label: 'Offene Meldungen',
        icon: Icons.outlined_flag_rounded,
        dringend: o.openReports > 0,
        onTap: () => onNavigate(AdminSection.reports),
      ),
      _Kachel(
        wert: o.scheduled,
        label: 'Zurückgestellt',
        icon: Icons.schedule_rounded,
        onTap: () => onNavigate(AdminSection.moderation),
      ),
      _Kachel(
        wert: o.approved,
        label: 'Freigegeben',
        icon: Icons.check_circle_outline_rounded,
      ),
      _Kachel(
        wert: o.rejected,
        label: 'Abgelehnt',
        icon: Icons.block_rounded,
      ),
      _Kachel(
        wert: o.companiesUnverified,
        label: 'Betriebe unverifiziert',
        hinweis: 'von ${o.companies}',
        icon: Icons.domain_verification_outlined,
        onTap: () => onNavigate(AdminSection.companies),
      ),
    ];

    final allesErledigt = o.pending == 0 && o.openReports == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!allesErledigt) ...[
          _Aufgabe(o: o, onNavigate: onNavigate),
          const SizedBox(height: AppLayout.s32),
        ],
        const SectionLabel('Kennzahlen'),
        const SizedBox(height: AppLayout.s16),
        LayoutBuilder(builder: (context, c) {
          final spalten = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 520 ? 2 : 1);
          const abstand = AppLayout.s16;
          final breite = (c.maxWidth - (spalten - 1) * abstand) / spalten;
          return Wrap(
            spacing: abstand,
            runSpacing: abstand,
            children: [
              for (final k in kacheln) SizedBox(width: breite, child: k),
            ],
          );
        }),
        const SizedBox(height: AppLayout.s48),
        Row(
          children: [
            const Expanded(child: SectionLabel('Zuletzt entschieden')),
            TextButton(
              onPressed: () => onNavigate(AdminSection.log),
              child: const Text('Ganzes Protokoll'),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s8),
        if (o.recentLog.isEmpty)
          const AdminEmpty(
            icon: Icons.history_rounded,
            title: 'Noch keine Entscheidungen',
            text: 'Sobald eine Bewertung freigegeben oder abgelehnt wird, '
                'steht sie hier.',
          )
        else
          AppRowGroup(
            children: [for (final e in o.recentLog) LogRow(entry: e)],
          ),
      ],
    );
  }
}

/// Der nächste Schritt, prominent — eine Seite, eine Hauptaktion.
class _Aufgabe extends StatelessWidget {
  final AdminOverview o;
  final ValueChanged<AdminSection> onNavigate;

  const _Aufgabe({required this.o, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final warteschlange = o.pending > 0;
    final text = warteschlange
        ? '${o.pending} ${o.pending == 1 ? 'Bewertung wartet' : 'Bewertungen warten'} '
            'auf eine Entscheidung.'
        : '${o.openReports} ${o.openReports == 1 ? 'Meldung ist' : 'Meldungen sind'} '
            'noch offen.';

    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      color: AppColors.ink,
      child: Wrap(
        spacing: AppLayout.s24,
        runSpacing: AppLayout.s16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ALS NÄCHSTES',
                  style: TextStyle(
                    color: Color(0xFFFF8A86),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.32,
                  ),
                ),
                const SizedBox(height: AppLayout.s8),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => onNavigate(
                warteschlange ? AdminSection.moderation : AdminSection.reports),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
                warteschlange ? 'Warteschlange öffnen' : 'Meldungen prüfen'),
          ),
        ],
      ),
    );
  }
}

class _Kachel extends StatelessWidget {
  final int wert;
  final String label;
  final String? hinweis;
  final IconData icon;
  final bool dringend;
  final VoidCallback? onTap;

  const _Kachel({
    required this.wert,
    required this.label,
    required this.icon,
    this.hinweis,
    this.dringend = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inhalt = Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      // Keine Füllfarbe: Die Fläche kommt vom Material darunter, sonst
      // verdeckte sie den Hover-Zustand.
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: dringend ? AppColors.accent : AppColors.ink, width: 3),
          left: const BorderSide(color: AppColors.line),
          right: const BorderSide(color: AppColors.line),
          bottom: const BorderSide(color: AppColors.line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: dringend ? AppColors.accentDark : AppColors.muted),
              const Spacer(),
              if (onTap != null)
                const Icon(Icons.arrow_outward_rounded,
                    size: 18, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: AppLayout.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$wert',
                style: TextStyle(
                  color: dringend ? AppColors.accentDark : AppColors.ink,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (hinweis != null) ...[
                const SizedBox(width: AppLayout.s8),
                Text(hinweis!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: AppLayout.s8),
          SectionLabel(label),
        ],
      ),
    );

    if (onTap == null) {
      return Material(color: AppColors.surface, child: inhalt);
    }
    return Semantics(
      button: true,
      label: '$label: $wert',
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.paper,
          child: inhalt,
        ),
      ),
    );
  }
}
