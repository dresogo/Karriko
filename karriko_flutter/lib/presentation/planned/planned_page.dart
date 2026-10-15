import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

/// Stand einer geplanten Seite, wie ihn die Sitemap führt.
enum PlannedStatus {
  /// Die Seite wird gebraucht, Umfang und Inhalt sind klar.
  needed('Benötigt'),

  /// Ob und wie es die Seite gibt, ist eine offene Produktentscheidung.
  open('Entscheidung offen');

  final String label;
  const PlannedStatus(this.label);
}

/// Wo die Seite lebt. Öffentliche Seiten tragen die Fußzeile der Website,
/// die angemeldeten Bereiche nicht.
enum PlannedArea { public, app }

/// Ein Abschnitt, der später mit Inhalt gefüllt wird.
class PlannedSection {
  final String title;
  final String description;

  const PlannedSection(this.title, this.description);
}

/// Beschreibung einer Seite, die es laut Sitemap geben soll, aber noch nicht
/// gibt. Sobald eine Seite echten Inhalt bekommt, erhält sie einen eigenen
/// Bildschirm und fällt aus dem Katalog.
class PlannedPageSpec {
  /// Pfad in der Schreibweise von GoRouter, etwa `/berufe/:beruf`.
  final String path;

  /// Beispiel-Adresse für die Seitenübersicht, wenn [path] Parameter hat.
  final String? example;

  final String eyebrow;

  /// Titel; `{}` wird bei Parameter-Seiten durch den Wert aus der Adresse
  /// ersetzt.
  final String title;
  final String lede;
  final PlannedStatus status;
  final PlannedArea area;
  final List<PlannedSection> sections;

  /// Verweise auf Entscheidungen (E-…) und Aufgaben (T-…).
  final List<String> refs;

  const PlannedPageSpec({
    required this.path,
    this.example,
    required this.eyebrow,
    required this.title,
    required this.lede,
    this.status = PlannedStatus.needed,
    required this.area,
    required this.sections,
    this.refs = const [],
  });

  String get href => example ?? path;
}

/// Grobgerüst einer geplanten Seite: Kopfband, Stand, nummerierte Abschnitte
/// mit Platzhalterflächen. Bewusst ohne erfundene Inhalte.
class PlannedPage extends StatelessWidget {
  final PlannedPageSpec spec;

  /// Wert des Pfadparameters, lesbar aufbereitet.
  final String? subject;

  const PlannedPage({super.key, required this.spec, this.subject});

  @override
  Widget build(BuildContext context) {
    final title = subject == null
        ? spec.title.replaceAll('{}', '…')
        : spec.title.replaceAll('{}', subject!);

    return Scaffold(
      appBar: KarrikoAppBar(title: title),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlannedHeader(
              eyebrow: spec.eyebrow,
              title: title,
              lede: spec.lede,
              status: spec.status,
              refs: spec.refs,
            ),
            ContentBand(
              padding: const EdgeInsets.only(
                top: AppLayout.s48,
                bottom: AppLayout.s64,
              ),
              child: PlannedSectionList(sections: spec.sections),
            ),
            if (spec.area == PlannedArea.public) const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

/// Kopfband auf weißer Fläche: Kicker, Titel, Einleitung und Stand.
class PlannedHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String lede;
  final PlannedStatus status;
  final List<String> refs;

  const PlannedHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.lede,
    required this.status,
    required this.refs,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 720;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(
          vertical: isWide ? AppLayout.s64 : AppLayout.s48,
        ),
        // Volle Breite, sonst zentriert ContentBand die schmale Spalte und
        // der Kopf steht nicht bündig mit dem Inhalt darunter.
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accentDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.32,
                ),
              ),
              const SizedBox(height: AppLayout.s16),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: isWide ? 56 : 34,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.s24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(
                  lede,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.muted, height: 1.55),
                ),
              ),
              const SizedBox(height: AppLayout.s32),
              Wrap(
                spacing: AppLayout.s8,
                runSpacing: AppLayout.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusMark(status: status),
                  for (final r in refs) _RefTag(r),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  final PlannedStatus status;

  const _StatusMark({required this.status});

  @override
  Widget build(BuildContext context) {
    final needed = status == PlannedStatus.needed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: needed ? AppColors.ink : AppColors.surface,
        border: Border.all(color: AppColors.ink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            needed ? Icons.construction_outlined : Icons.help_outline,
            size: 14,
            color: needed ? AppColors.surface : AppColors.ink,
          ),
          const SizedBox(width: AppLayout.s8),
          Flexible(
            child: Text(
              needed ? 'Im Aufbau · ${status.label}' : status.label,
              style: TextStyle(
                color: needed ? AppColors.surface : AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefTag extends StatelessWidget {
  final String text;

  const _RefTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Nummerierte Abschnitte mit Haarlinien, wie die Merkmalszeilen der Website.
/// Breit stehen Nummer und Titel links, Beschreibung und Platzhalter rechts.
class PlannedSectionList extends StatelessWidget {
  final List<PlannedSection> sections;

  const PlannedSectionList({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++)
          _SectionRow(number: i + 1, section: sections[i]),
        const SizedBox(height: AppLayout.s32),
        const _DraftNotice(),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  final int number;
  final PlannedSection section;

  const _SectionRow({required this.number, required this.section});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final textTheme = Theme.of(context).textTheme;

    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: AppColors.accentDark,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: AppLayout.s8),
        Semantics(
          header: true,
          child: Text(section.title, style: textTheme.headlineSmall),
        ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          section.description,
          style: textTheme.bodyLarge?.copyWith(height: 1.55),
        ),
        const SizedBox(height: AppLayout.s16),
        const _Placeholder(),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.s32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: head),
                const SizedBox(width: AppLayout.s32),
                Expanded(child: body),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                head,
                const SizedBox(height: AppLayout.s16),
                body,
              ],
            ),
    );
  }
}

/// Fläche, auf der später der Inhalt steht. Feste Mindesthöhe, damit sich das
/// Seitenraster schon jetzt beurteilen lässt.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppLayout.s16),
        decoration: BoxDecoration(
          color: AppColors.audienceBeige,
          border: Border.all(color: AppColors.line),
        ),
        child: const Text(
          'Inhalt folgt',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _DraftNotice extends StatelessWidget {
  const _DraftNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.accentDark, width: 3)),
      ),
      child: Text(
        'Diese Seite ist ein Grobgerüst. Inhalt und Gestaltung folgen; bis '
        'dahin ist sie nirgends verlinkt.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
