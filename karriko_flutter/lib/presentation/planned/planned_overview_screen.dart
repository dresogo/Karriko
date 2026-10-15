import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/tap_target.dart';
import 'planned_catalog.dart';
import 'planned_page.dart';

/// Arbeitsübersicht aller geplanten Seiten, nur über die Adresse erreichbar.
/// Dient dazu, die Grobgerüste durchzuklicken, solange sie nirgends verlinkt
/// sind.
class PlannedOverviewScreen extends StatelessWidget {
  const PlannedOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final public =
        plannedPages.where((p) => p.area == PlannedArea.public).toList();
    final app = plannedPages.where((p) => p.area == PlannedArea.app).toList();

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Seitenübersicht'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlannedHeader(
              eyebrow: 'Arbeitsstand',
              title: 'Geplante Seiten',
              lede: '${plannedPages.length} Seiten aus der Sitemap als '
                  'Grobgerüst. Die Bereiche Nutzer und Anfragen liegen im '
                  'Admin-Bereich, Wartungs- und Vorschaltseite als statisches '
                  'HTML unter /wartung.html und /bald.html.',
              status: PlannedStatus.needed,
              refs: const ['E-30'],
            ),
            ContentBand(
              padding: const EdgeInsets.only(
                top: AppLayout.s48,
                bottom: AppLayout.s64,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Group(title: 'Öffentlich und Anmeldung', pages: public),
                  const SizedBox(height: AppLayout.s48),
                  _Group(title: 'Nach der Anmeldung', pages: app),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<PlannedPageSpec> pages;

  const _Group({required this.title, required this.pages});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.32,
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        for (final p in pages) _Row(spec: p),
        Container(height: 1, color: AppColors.line),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final PlannedPageSpec spec;

  const _Row({required this.spec});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final title = spec.title.replaceAll('{}', '…');

    return TapTarget(
      onTap: () => context.go(spec.href),
      builder: (context, active) {
        final name = Text(
          title,
          style: TextStyle(
            color: active ? AppColors.accentDark : AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        );
        final path = Text(
          spec.href,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
        final status = Text(
          spec.status.label,
          style: TextStyle(
            color: spec.status == PlannedStatus.open
                ? AppColors.muted
                : AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        );

        return Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: AppLayout.s16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 3, child: name),
                    const SizedBox(width: AppLayout.s16),
                    Expanded(flex: 3, child: path),
                    const SizedBox(width: AppLayout.s16),
                    Expanded(flex: 2, child: status),
                    Icon(Icons.arrow_forward,
                        size: 18,
                        color: active ? AppColors.accentDark : AppColors.muted),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          name,
                          const SizedBox(height: 4),
                          path,
                          const SizedBox(height: 4),
                          status,
                        ],
                      ),
                    ),
                    const SizedBox(width: AppLayout.s16),
                    Icon(Icons.arrow_forward,
                        size: 18,
                        color: active ? AppColors.accentDark : AppColors.muted),
                  ],
                ),
        );
      },
    );
  }
}
