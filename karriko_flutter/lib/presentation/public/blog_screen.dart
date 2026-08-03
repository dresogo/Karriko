import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/blog_entry_model.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

/// Filter des gemeinsamen Streams. Der aktive Filter steht im Query-Parameter
/// `typ`, damit eine gefilterte Ansicht teilbar ist und der Zurück-Button wirkt.
enum _Filter {
  alle('alle', 'Alle'),
  artikel('artikel', 'Artikel'),
  updates('updates', 'Produkt-Updates');

  const _Filter(this.slug, this.label);

  final String slug;
  final String label;

  static _Filter fromSlug(String? slug) =>
      _Filter.values.firstWhere((f) => f.slug == slug, orElse: () => _Filter.alle);
}

/// Blog und Neuigkeiten in einem chronologischen Stream: redaktionelle Artikel
/// und Produkt-Updates. Die Inhalte sind vorerst statisch hinterlegt.
class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  static final _entries = <BlogEntry>[
    BlogEntry.update(
      title: 'Fragebogen für Betriebsbewertungen',
      teaser: 'Azubis beantworten jetzt strukturierte Fragen zu Ausbildungsqualität, '
          'Betreuung und Übernahmechancen statt nur Freitext zu schreiben.',
      date: DateTime(2026, 7, 24),
      version: 'v1.4',
      updateKind: UpdateKind.neu,
    ),
    BlogEntry.article(
      title: 'Wie finde ich den richtigen Ausbildungsbetrieb?',
      teaser: 'Worauf es bei der Wahl wirklich ankommt – von der Branche über das '
          'Betriebsklima bis zu den Übernahmechancen.',
      date: DateTime(2026, 6, 18),
      category: 'Tipps & Tricks',
      readingMinutes: 5,
      slug: 'tipps-ausbildungsbetrieb',
    ),
    BlogEntry.update(
      title: 'Schnellere Suche mit Branchenfiltern',
      teaser: 'Die Betriebssuche filtert jetzt nach Branche, Ort und Mindestbewertung '
          'und liefert Ergebnisse spürbar schneller.',
      date: DateTime(2026, 6, 2),
      version: 'v1.3',
      updateKind: UpdateKind.verbessert,
    ),
    BlogEntry.article(
      title: 'DSGVO und Ausbildungsbewertungen',
      teaser: 'Was Betriebe über anonyme Bewertungen wissen müssen und welche Rechte '
          'Azubis beim Veröffentlichen haben.',
      date: DateTime(2026, 5, 21),
      category: 'Datenschutz',
      readingMinutes: 3,
      slug: 'dsgvo-bewertungen',
    ),
    BlogEntry.update(
      title: 'Benachrichtigungen kamen doppelt an',
      teaser: 'Ein Fehler hat Betrieben dieselbe Bewertungsbenachrichtigung mehrfach '
          'zugestellt. Das ist behoben.',
      date: DateTime(2026, 5, 8),
      version: 'v1.2.1',
      updateKind: UpdateKind.behoben,
    ),
    BlogEntry.article(
      title: 'Warum Azubi-Feedback Betrieben hilft',
      teaser: 'Ehrliche Rückmeldungen decken auf, woran Ausbildung im Alltag scheitert '
          '– und was sich mit wenig Aufwand ändern lässt.',
      date: DateTime(2026, 4, 30),
      category: 'Für Betriebe',
      readingMinutes: 4,
      slug: 'azubi-feedback-betriebe',
    ),
    BlogEntry.article(
      title: 'Top 10 Ausbildungsberufe 2026',
      teaser: 'Welche Ausbildungen aktuell am stärksten nachgefragt werden und wo die '
          'Übernahmequoten am höchsten liegen.',
      date: DateTime(2026, 3, 12),
      category: 'Karriere',
      readingMinutes: 6,
      slug: 'top-ausbildungsberufe-2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filter = _Filter.fromSlug(GoRouterState.of(context).uri.queryParameters['typ']);

    final entries = switch (filter) {
      _Filter.alle => _entries,
      _Filter.artikel => _entries.where((e) => e.isArticle).toList(),
      _Filter.updates => _entries.where((e) => !e.isArticle).toList(),
    };

    // Der jüngste Artikel wird herausgestellt – bei der reinen Update-Ansicht
    // gibt es keinen Aufmacher.
    final featured = filter == _Filter.updates
        ? null
        : entries.where((e) => e.isArticle).firstOrNull;
    final rest = entries.where((e) => e != featured).toList();

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Blog & Neuigkeiten'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _HeroBand(),
            _FilterBand(active: filter, count: entries.length),
            ContentBand(
              padding: const EdgeInsets.only(
                top: AppLayout.s48,
                bottom: AppLayout.s64,
              ),
              child: entries.isEmpty
                  ? const _EmptyState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (featured != null) ...[
                          _FeaturedArticle(entry: featured),
                          const SizedBox(height: AppLayout.s48),
                        ],
                        if (rest.isNotEmpty)
                          _EntryList(entries: rest, showKindLabel: filter == _Filter.alle),
                      ],
                    ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroBand extends StatelessWidget {
  const _HeroBand();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(
          vertical: width > 720 ? AppLayout.s64 : AppLayout.s48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BLOG & NEUIGKEITEN',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.32,
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            Text(
              'Was wir schreiben,\nwas wir bauen.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: (width * 0.05).clamp(34.0, 60.0),
                fontWeight: FontWeight.w800,
                height: 0.98,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: const Text(
                'Artikel rund um Ausbildung und Karriere – und jede neue Funktion, '
                'die es auf Karriko schafft.',
                style: TextStyle(color: AppColors.muted, fontSize: 17, height: 1.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filterleiste ────────────────────────────────────────────────────────────

class _FilterBand extends StatelessWidget {
  final _Filter active;
  final int count;

  const _FilterBand({required this.active, required this.count});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 720;

    final segments = _FilterSegments(active: active);
    final label = Text(
      count == 1 ? '1 Beitrag' : '$count Beiträge',
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.96,
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.s24),
        child: isWide
            ? Row(
                children: [
                  Expanded(child: segments),
                  const SizedBox(width: AppLayout.s24),
                  label,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  segments,
                  const SizedBox(height: AppLayout.s16),
                  label,
                ],
              ),
      ),
    );
  }
}

/// Segmentierte Auswahl im Stil der Website: einzeln umrandete Flächen, das
/// aktive Segment als Tintenfläche.
///
/// Bewusst ein [Wrap] statt einer festen Zeile: Die Leiste bricht um, statt über
/// den Rand zu laufen – unabhängig von Viewportbreite, Labellänge und
/// vergrößerter Systemschrift.
class _FilterSegments extends StatelessWidget {
  final _Filter active;

  const _FilterSegments({required this.active});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppLayout.s8,
      runSpacing: AppLayout.s8,
      children: [
        for (final filter in _Filter.values)
          _Segment(filter: filter, selected: filter == active),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final _Filter filter;
  final bool selected;

  const _Segment({required this.filter, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.ink : AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.line),
          borderRadius: BorderRadius.zero,
        ),
        child: InkWell(
          // Der Filter landet in der URL: teilbar, und der Zurück-Button
          // führt zur vorherigen Auswahl zurück.
          onTap: () => context.go(
            filter == _Filter.alle ? '/blog' : '/blog?typ=${filter.slug}',
          ),
          hoverColor: selected ? AppColors.muted : AppColors.paper,
          focusColor: selected ? AppColors.muted : AppColors.audienceBeige,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: AppLayout.s24),
            alignment: Alignment.center,
            child: Text(
              filter.label,
              style: TextStyle(
                color: selected ? AppColors.paper : AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Aufmacher ───────────────────────────────────────────────────────────────

class _FeaturedArticle extends StatelessWidget {
  final BlogEntry entry;

  const _FeaturedArticle({required this.entry});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return _HoverRow(
      onTap: () => context.go('/blog/${entry.slug}'),
      semanticsLabel: 'Artikel: ${entry.title}. ${entry.teaser}',
      background: AppColors.surface,
      border: Border.all(color: AppColors.line),
      padding: EdgeInsets.all(width > 720 ? AppLayout.s48 : AppLayout.s24),
      builder: (context, arrow) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(text: 'AUFMACHER · ${entry.category!.toUpperCase()}'),
          const SizedBox(height: AppLayout.s16),
          Text(
            entry.title,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: width > 720 ? 36 : 27,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              entry.teaser,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: AppLayout.s24),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${entry.formattedDate} · ${entry.readingMinutes} Min Lesezeit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: AppLayout.s16),
              arrow,
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stream ──────────────────────────────────────────────────────────────────

class _EntryList extends StatelessWidget {
  final List<BlogEntry> entries;

  /// In der gemischten Ansicht kennzeichnet ein Label, ob ein Eintrag ein
  /// Artikel oder ein Produkt-Update ist.
  final bool showKindLabel;

  const _EntryList({required this.entries, required this.showKindLabel});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(color: AppColors.line, height: 1),
          for (final entry in entries) ...[
            if (entry.isArticle)
              _ArticleRow(entry: entry, showKindLabel: showKindLabel)
            else
              _UpdateRow(entry: entry, showKindLabel: showKindLabel),
            const Divider(color: AppColors.line, height: 1),
          ],
        ],
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final BlogEntry entry;
  final bool showKindLabel;

  const _ArticleRow({required this.entry, required this.showKindLabel});

  @override
  Widget build(BuildContext context) {
    return _HoverRow(
      onTap: () => context.go('/blog/${entry.slug}'),
      semanticsLabel: 'Artikel: ${entry.title}. ${entry.teaser}',
      padding: const EdgeInsets.symmetric(vertical: AppLayout.s32),
      builder: (context, arrow) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(
            text: [
              if (showKindLabel) 'ARTIKEL',
              entry.category!.toUpperCase(),
              entry.formattedDate.toUpperCase(),
            ].join(' · '),
          ),
          const SizedBox(height: AppLayout.s8),
          Text(entry.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppLayout.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              entry.teaser,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${entry.readingMinutes} Min Lesezeit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: AppLayout.s16),
              arrow,
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateRow extends StatelessWidget {
  final BlogEntry entry;
  final bool showKindLabel;

  const _UpdateRow({required this.entry, required this.showKindLabel});

  @override
  Widget build(BuildContext context) {
    // Updates verlinken nicht weiter – sie sind hier vollständig.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppLayout.s16,
            runSpacing: AppLayout.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _UpdateBadge(kind: entry.updateKind!),
              _Eyebrow(
                text: [
                  if (showKindLabel) 'PRODUKT-UPDATE',
                  entry.version!,
                  entry.formattedDate.toUpperCase(),
                ].join(' · '),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.s16),
          Text(entry.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppLayout.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(entry.teaser, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Kennzeichnung der Änderungsart. Icon und Text tragen die Bedeutung, die Farbe
/// unterstützt sie nur.
class _UpdateBadge extends StatelessWidget {
  final UpdateKind kind;

  const _UpdateBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kind) {
      UpdateKind.neu => (Icons.add, AppColors.accent),
      UpdateKind.verbessert => (Icons.trending_up, AppColors.ink),
      UpdateKind.behoben => (Icons.build_outlined, AppColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            kind.label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.88,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bausteine ───────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.96,
      ),
    );
  }
}

/// Anklickbare Zeile mit sichtbarem Hover-, Fokus- und Druckzustand. Der Fokus
/// wird als 2 px starke Tintenkante gezeichnet, der Pfeil wandert nach rechts.
class _HoverRow extends StatefulWidget {
  final VoidCallback onTap;
  final String semanticsLabel;
  final EdgeInsets padding;
  final Color? background;
  final BoxBorder? border;
  final Widget Function(BuildContext context, Widget arrow) builder;

  const _HoverRow({
    required this.onTap,
    required this.semanticsLabel,
    required this.padding,
    required this.builder,
    this.background,
    this.border,
  });

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final arrow = AnimatedSlide(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      offset: _hovered || _focused ? const Offset(0.25, 0) : Offset.zero,
      child: const Icon(Icons.arrow_forward, size: 20, color: AppColors.ink),
    );

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: widget.background ?? Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (v) => setState(() => _focused = v),
          onHover: (v) => setState(() => _hovered = v),
          hoverColor: AppColors.audienceBeige.withValues(alpha: 0.6),
          focusColor: AppColors.audienceBeige,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: widget.padding,
            foregroundDecoration: BoxDecoration(
              border: Border.all(
                color: _focused ? AppColors.ink : Colors.transparent,
                width: 2,
              ),
            ),
            decoration: BoxDecoration(border: widget.border),
            child: widget.builder(context, arrow),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nichts gefunden', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppLayout.s8),
          Text(
            'In dieser Rubrik gibt es aktuell keine Beiträge.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppLayout.s24),
          OutlinedButton(
            onPressed: () => context.go('/blog'),
            child: const Text('Alle Beiträge anzeigen'),
          ),
        ],
      ),
    );
  }
}
