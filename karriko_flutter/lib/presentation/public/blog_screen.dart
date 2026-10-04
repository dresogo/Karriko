import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/blog_entry_model.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

/// Filter der Blogseite. Der aktive Filter steht im Query-Parameter `typ`,
/// damit eine gefilterte Ansicht teilbar ist und der Zurück-Button wirkt.
enum _Filter {
  alle('alle', 'Alle'),
  artikel('artikel', 'Artikel'),
  updates('updates', 'Produkt-Updates');

  const _Filter(this.slug, this.label);

  final String slug;
  final String label;

  String get location => this == _Filter.alle ? '/blog' : '/blog?typ=$slug';

  static _Filter fromSlug(String? slug) => _Filter.values
      .firstWhere((f) => f.slug == slug, orElse: () => _Filter.alle);
}

/// Blog und Neuigkeiten: redaktionelle Artikel als Karten, Produkt-Updates als
/// Zeitleiste. In der Gesamtansicht stehen beide nebeneinander, damit sich die
/// zwei Inhaltsarten nicht gegenseitig verdrängen. Die Inhalte sind vorerst
/// statisch hinterlegt und absteigend nach Datum sortiert.
class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  static final _entries = <BlogEntry>[
    BlogEntry.update(
      title: 'Fragebogen für Betriebsbewertungen',
      teaser:
          'Azubis beantworten jetzt strukturierte Fragen zu Ausbildungsqualität, '
          'Betreuung und Übernahmechancen statt nur Freitext zu schreiben.',
      date: DateTime(2026, 7, 24),
      version: 'v1.4',
      updateKind: UpdateKind.neu,
    ),
    BlogEntry.article(
      title: 'Wie finde ich den richtigen Ausbildungsbetrieb?',
      teaser:
          'Worauf es bei der Wahl wirklich ankommt – von der Branche über das '
          'Betriebsklima bis zu den Übernahmechancen.',
      date: DateTime(2026, 6, 18),
      category: 'Tipps & Tricks',
      readingMinutes: 5,
      slug: 'tipps-ausbildungsbetrieb',
    ),
    BlogEntry.update(
      title: 'Schnellere Suche mit Branchenfiltern',
      teaser:
          'Die Betriebssuche filtert jetzt nach Branche, Ort und Mindestbewertung '
          'und liefert Ergebnisse spürbar schneller.',
      date: DateTime(2026, 6, 2),
      version: 'v1.3',
      updateKind: UpdateKind.verbessert,
    ),
    BlogEntry.article(
      title: 'DSGVO und Ausbildungsbewertungen',
      teaser:
          'Was Betriebe über anonyme Bewertungen wissen müssen und welche Rechte '
          'Azubis beim Veröffentlichen haben.',
      date: DateTime(2026, 5, 21),
      category: 'Datenschutz',
      readingMinutes: 3,
      slug: 'dsgvo-bewertungen',
    ),
    BlogEntry.update(
      title: 'Benachrichtigungen kamen doppelt an',
      teaser:
          'Ein Fehler hat Betrieben dieselbe Bewertungsbenachrichtigung mehrfach '
          'zugestellt. Das ist behoben.',
      date: DateTime(2026, 5, 8),
      version: 'v1.2.1',
      updateKind: UpdateKind.behoben,
    ),
    BlogEntry.article(
      title: 'Warum Azubi-Feedback Betrieben hilft',
      teaser:
          'Ehrliche Rückmeldungen decken auf, woran Ausbildung im Alltag scheitert '
          '– und was sich mit wenig Aufwand ändern lässt.',
      date: DateTime(2026, 4, 30),
      category: 'Für Betriebe',
      readingMinutes: 4,
      slug: 'azubi-feedback-betriebe',
    ),
    BlogEntry.article(
      title: 'Top 10 Ausbildungsberufe 2026',
      teaser:
          'Welche Ausbildungen aktuell am stärksten nachgefragt werden und wo die '
          'Übernahmequoten am höchsten liegen.',
      date: DateTime(2026, 3, 12),
      category: 'Karriere',
      readingMinutes: 6,
      slug: 'top-ausbildungsberufe-2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filter =
        _Filter.fromSlug(GoRouterState.of(context).uri.queryParameters['typ']);

    final articles = _entries.where((e) => e.isArticle).toList();
    final updates = _entries.where((e) => !e.isArticle).toList();
    final counts = {
      _Filter.alle: _entries.length,
      _Filter.artikel: articles.length,
      _Filter.updates: updates.length,
    };

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Blog & Neuigkeiten'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              active: filter,
              counts: counts,
              lastUpdate: _entries.isEmpty ? null : _entries.first,
            ),
            ContentBand(
              padding: const EdgeInsets.only(
                top: AppLayout.s48,
                bottom: AppLayout.s64,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => switch (filter) {
                  _Filter.alle => _OverviewView(
                      articles: articles,
                      updates: updates,
                      width: constraints.maxWidth,
                    ),
                  _Filter.artikel => _ArticlesView(
                      articles: articles,
                      width: constraints.maxWidth,
                    ),
                  _Filter.updates => _UpdatesView(updates: updates),
                },
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

// ─── Kopf mit Filter-Tabs ────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final _Filter active;
  final Map<_Filter, int> counts;
  final BlogEntry? lastUpdate;

  const _Header({
    required this.active,
    required this.counts,
    required this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 900;

    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(text: 'BLOG & NEUIGKEITEN', color: AppColors.accent),
        const SizedBox(height: AppLayout.s16),
        Text(
          'Was wir schreiben,\nwas wir bauen.',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: (width * 0.045).clamp(34.0, 56.0),
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );

    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Artikel rund um Ausbildung und Karriere – und jede neue Funktion, '
          'die es auf Karriko schafft.',
          style: TextStyle(color: AppColors.muted, fontSize: 17, height: 1.55),
        ),
        if (lastUpdate != null) ...[
          const SizedBox(height: AppLayout.s16),
          Text(
            'Zuletzt aktualisiert am ${lastUpdate!.formattedDate}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.only(top: isWide ? AppLayout.s64 : AppLayout.s48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 7, child: headline),
                  const SizedBox(width: AppLayout.s48),
                  Expanded(flex: 5, child: intro),
                ],
              )
            else ...[
              headline,
              const SizedBox(height: AppLayout.s24),
              intro,
            ],
            SizedBox(height: isWide ? AppLayout.s48 : AppLayout.s32),
            _FilterTabs(active: active, counts: counts),
          ],
        ),
      ),
    );
  }
}

/// Reiter am unteren Rand des Kopfes. Der aktive Reiter trägt eine Tintenkante,
/// jeder zeigt die Zahl seiner Beiträge. Ein [Wrap] statt einer festen Zeile,
/// damit die Leiste bei schmalen Viewports oder großer Systemschrift umbricht,
/// statt über den Rand zu laufen.
class _FilterTabs extends StatelessWidget {
  final _Filter active;
  final Map<_Filter, int> counts;

  const _FilterTabs({required this.active, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppLayout.s8,
      children: [
        for (final filter in _Filter.values)
          _Tab(
            filter: filter,
            count: counts[filter] ?? 0,
            selected: filter == active,
          ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final _Filter filter;
  final int count;
  final bool selected;

  const _Tab({
    required this.filter,
    required this.count,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: '${filter.label}, $count Beiträge',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Der Filter landet in der URL: teilbar, und der Zurück-Button
          // führt zur vorherigen Auswahl zurück.
          onTap: () => context.go(filter.location),
          hoverColor: AppColors.audienceBeige,
          focusColor: AppColors.audienceBeige,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppLayout.s16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.ink : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppLayout.s8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  color: selected ? AppColors.ink : AppColors.audienceBeige,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? AppColors.paper : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ansichten ───────────────────────────────────────────────────────────────

/// Gesamtansicht: Artikel im Hauptbereich, Updates als Zeitleiste daneben. Auf
/// schmalen Viewports rutscht die Zeitleiste unter die Artikel.
class _OverviewView extends StatelessWidget {
  final List<BlogEntry> articles;
  final List<BlogEntry> updates;
  final double width;

  const _OverviewView({
    required this.articles,
    required this.updates,
    required this.width,
  });

  static const _sidebarWidth = 340.0;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty && updates.isEmpty) return const _EmptyState();

    final hasSidebar = width >= 960;
    final mainWidth =
        hasSidebar ? width - _sidebarWidth - AppLayout.s48 : width;

    final main = articles.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                title: 'Artikel',
                actionLabel: 'Alle Artikel',
                actionLocation: _Filter.artikel.location,
              ),
              const SizedBox(height: AppLayout.s24),
              _ArticleSection(
                articles: articles,
                width: mainWidth,
                compact: true,
              ),
            ],
          );

    final sidebar = updates.isEmpty
        ? const SizedBox.shrink()
        : _UpdatesPanel(updates: updates.take(4).toList());

    if (hasSidebar) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: main),
          const SizedBox(width: AppLayout.s48),
          SizedBox(width: _sidebarWidth, child: sidebar),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        main,
        if (articles.isNotEmpty && updates.isNotEmpty)
          const SizedBox(height: AppLayout.s48),
        sidebar,
      ],
    );
  }
}

class _ArticlesView extends StatelessWidget {
  final List<BlogEntry> articles;
  final double width;

  const _ArticlesView({required this.articles, required this.width});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const _EmptyState();
    return _ArticleSection(articles: articles, width: width);
  }
}

class _UpdatesView extends StatelessWidget {
  final List<BlogEntry> updates;

  const _UpdatesView({required this.updates});

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) return const _EmptyState();

    // Lesbare Zeilenlänge statt Text über die volle Breite.
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Was sich auf Karriko geändert hat',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppLayout.s8),
            Text(
              'Neue Funktionen, Verbesserungen und behobene Fehler – die '
              'neuesten zuerst.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppLayout.s32),
            for (var i = 0; i < updates.length; i++)
              _TimelineEntry(
                entry: updates[i],
                isLast: i == updates.length - 1,
                dense: false,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Artikel ─────────────────────────────────────────────────────────────────

/// Jüngster Artikel als Aufmacher, die übrigen darunter: in der Übersicht als
/// kompakte Liste, in der Artikelansicht als Kartenraster.
class _ArticleSection extends StatelessWidget {
  final List<BlogEntry> articles;
  final double width;
  final bool compact;

  const _ArticleSection({
    required this.articles,
    required this.width,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final featured = articles.first;
    final rest = articles.skip(1).toList();
    final columns = width >= 960 ? 3 : (width >= 560 ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeaturedArticle(entry: featured, wide: width >= 640),
        if (rest.isNotEmpty && compact)
          for (final e in rest) ...[
            const SizedBox(height: AppLayout.s16),
            _ArticleListItem(entry: e, wide: width >= 560),
          ]
        else if (rest.isNotEmpty) ...[
          const SizedBox(height: AppLayout.s24),
          _CardGrid(
            columns: columns,
            children: [for (final e in rest) _ArticleCard(entry: e)],
          ),
        ],
      ],
    );
  }
}

/// Kompakte Artikelzeile: kleine Rubrikkachel links, Text rechts.
class _ArticleListItem extends StatelessWidget {
  final BlogEntry entry;
  final bool wide;

  const _ArticleListItem({required this.entry, required this.wide});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () => context.go('/blog/${entry.slug}'),
      semanticsLabel: 'Artikel: ${entry.title}. ${entry.teaser}',
      builder: (context, active) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: wide ? 128 : 56,
              child: _Cover(
                category: entry.category!,
                iconSize: wide ? 40 : 24,
                showLabel: false,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(wide ? AppLayout.s24 : AppLayout.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Eyebrow(text: entry.category!.toUpperCase()),
                    const SizedBox(height: AppLayout.s8),
                    Text(
                      entry.title,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: wide ? 18 : 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (wide) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.teaser,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: AppLayout.s8),
                    _ArticleMeta(entry: entry),
                  ],
                ),
              ),
            ),
            // Auf schmalen Viewports braucht der Titel die Breite; die ganze
            // Zeile ist ohnehin die Trefferfläche.
            if (wide)
              Padding(
                padding: const EdgeInsets.only(right: AppLayout.s24),
                child: Center(child: _Arrow(active: active)),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedArticle extends StatelessWidget {
  final BlogEntry entry;
  final bool wide;

  const _FeaturedArticle({required this.entry, required this.wide});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () => context.go('/blog/${entry.slug}'),
      semanticsLabel: 'Aufmacher, Artikel: ${entry.title}. ${entry.teaser}',
      builder: (context, active) {
        final body = Padding(
          padding: EdgeInsets.all(wide ? AppLayout.s32 : AppLayout.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Eyebrow(text: 'AUFMACHER', color: AppColors.accent),
              const SizedBox(height: AppLayout.s16),
              Text(
                entry.title,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: wide ? 28 : 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppLayout.s16),
              Text(
                entry.teaser,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: AppLayout.s24),
              _ArticleMeta(entry: entry),
              const SizedBox(height: AppLayout.s24),
              _ReadMore(active: active),
            ],
          ),
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cover(category: entry.category!, height: 136, iconSize: 56),
              body,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 260),
                  child: _Cover(category: entry.category!, iconSize: 80),
                ),
              ),
              Expanded(flex: 8, child: body),
            ],
          ),
        );
      },
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final BlogEntry entry;

  const _ArticleCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () => context.go('/blog/${entry.slug}'),
      semanticsLabel: 'Artikel: ${entry.title}. ${entry.teaser}',
      builder: (context, active) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Cover(category: entry.category!, height: 120, iconSize: 44),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppLayout.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ArticleMeta(entry: entry),
                  const SizedBox(height: AppLayout.s16),
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppLayout.s8),
                  Text(
                    entry.teaser,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  const SizedBox(height: AppLayout.s24),
                  _ReadMore(active: active),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Raster mit gleich hohen Karten pro Zeile. Jede Zeile misst ihre höchste
/// Karte, damit der „Weiterlesen“-Link überall auf derselben Linie sitzt.
class _CardGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const _CardGrid({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppLayout.s24));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: AppLayout.s24),
                Expanded(
                  child: i + c < children.length
                      ? children[i + c]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// Farbfläche je Rubrik – dieselbe Sprache wie die Zielgruppen-Kacheln auf der
/// Startseite. Die Rubrik steht immer als Text darauf, Farbe und Icon sind nur
/// zusätzliche Orientierung.
class _Cover extends StatelessWidget {
  final String category;
  final double? height;
  final double iconSize;

  /// Bei schmalen Kacheln steht die Rubrik im Text daneben statt darauf.
  final bool showLabel;

  const _Cover({
    required this.category,
    required this.iconSize,
    this.height,
    this.showLabel = true,
  });

  static (Color, Color, IconData) _styleFor(String category) =>
      switch (category) {
        'Tipps & Tricks' => (
            AppColors.green,
            AppColors.paper,
            Icons.lightbulb_outline
          ),
        'Datenschutz' => (
            AppColors.ink,
            AppColors.paper,
            Icons.shield_outlined
          ),
        'Für Betriebe' => (
            AppColors.audienceBeige,
            AppColors.ink,
            Icons.storefront_outlined
          ),
        'Karriere' => (AppColors.accentDark, Colors.white, Icons.trending_up),
        _ => (AppColors.audienceBeige, AppColors.ink, Icons.article_outlined),
      };

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = _styleFor(category);

    if (!showLabel) {
      return ExcludeSemantics(
        child: Container(
          height: height,
          color: background,
          alignment: Alignment.center,
          child: Icon(icon, size: iconSize, color: foreground),
        ),
      );
    }

    return ExcludeSemantics(
      child: Container(
        height: height,
        color: background,
        padding: const EdgeInsets.all(AppLayout.s24),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(icon, size: iconSize, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleMeta extends StatelessWidget {
  final BlogEntry entry;

  const _ArticleMeta({required this.entry});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: AppLayout.s16,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(entry.formattedDate, style: style),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 14, color: AppColors.muted),
            const SizedBox(width: 4),
            Flexible(
              child:
                  Text('${entry.readingMinutes} Min. Lesezeit', style: style),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadMore extends StatelessWidget {
  final bool active;

  const _ReadMore({required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Weiterlesen',
          style: TextStyle(
            color: active ? AppColors.accent : AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppLayout.s8),
        _Arrow(active: active, size: 18),
      ],
    );
  }
}

/// Pfeil, der bei Hover und Fokus nach rechts wandert und die Akzentfarbe
/// annimmt.
class _Arrow extends StatelessWidget {
  final bool active;
  final double size;

  const _Arrow({required this.active, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      offset: active ? const Offset(0.3, 0) : Offset.zero,
      child: Icon(
        Icons.arrow_forward,
        size: size,
        color: active ? AppColors.accent : AppColors.ink,
      ),
    );
  }
}

// ─── Produkt-Updates ─────────────────────────────────────────────────────────

/// Kompakte Zeitleiste der jüngsten Updates neben den Artikeln.
class _UpdatesPanel extends StatelessWidget {
  final List<BlogEntry> updates;

  const _UpdatesPanel({required this.updates});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Neu auf Karriko',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Die jüngsten Änderungen an der Plattform.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppLayout.s24),
          for (var i = 0; i < updates.length; i++)
            _TimelineEntry(
              entry: updates[i],
              isLast: i == updates.length - 1,
              dense: true,
            ),
          const SizedBox(height: AppLayout.s24),
          const Divider(height: 1),
          const SizedBox(height: AppLayout.s16),
          Align(
            alignment: Alignment.centerLeft,
            child: _TextLink(
              label: 'Alle Updates ansehen',
              location: _Filter.updates.location,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final BlogEntry entry;
  final bool isLast;

  /// Kompakte Variante für die Seitenspalte.
  final bool dense;

  const _TimelineEntry({
    required this.entry,
    required this.isLast,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final kindColor = _UpdateBadge.colorFor(entry.updateKind!);

    // Die Höhe bestimmt allein der Inhalt; Markierung und Verbindungslinie
    // liegen positioniert dahinter.
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 5.5,
            top: 17,
            bottom: 0,
            child: Container(width: 1, color: AppColors.line),
          ),
        Positioned(
          left: 0,
          top: 5,
          child: Container(width: 12, height: 12, color: kindColor),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 12 + (dense ? AppLayout.s16 : AppLayout.s24),
            bottom: isLast ? 0 : (dense ? AppLayout.s24 : AppLayout.s32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppLayout.s8,
                runSpacing: AppLayout.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _UpdateBadge(kind: entry.updateKind!),
                  Text(
                    '${entry.version} · ${entry.formattedDate}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.s8),
              Text(
                entry.title,
                style: dense
                    ? const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      )
                    : Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                entry.teaser,
                style: dense
                    ? Theme.of(context).textTheme.bodySmall
                    : Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kennzeichnung der Änderungsart. Icon und Text tragen die Bedeutung, die Farbe
/// unterstützt sie nur.
class _UpdateBadge extends StatelessWidget {
  final UpdateKind kind;

  const _UpdateBadge({required this.kind});

  static Color colorFor(UpdateKind kind) => switch (kind) {
        UpdateKind.neu => AppColors.accent,
        UpdateKind.verbessert => AppColors.green,
        UpdateKind.behoben => AppColors.muted,
      };

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      UpdateKind.neu => Icons.add,
      UpdateKind.verbessert => Icons.trending_up,
      UpdateKind.behoben => Icons.build_outlined,
    };
    final color = colorFor(kind);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(border: Border.all(color: color)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
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
  final Color color;

  const _Eyebrow({required this.text, this.color = AppColors.muted});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.32,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final String actionLocation;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.actionLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(width: AppLayout.s16),
        _TextLink(label: actionLabel, location: actionLocation),
      ],
    );
  }
}

/// Textlink mit Pfeil und ausreichend großer Trefferfläche.
class _TextLink extends StatelessWidget {
  final String label;
  final String location;

  const _TextLink({required this.label, required this.location});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.go(location),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.arrow_forward, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.s8),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}

/// Anklickbare Fläche mit sichtbarem Hover-, Fokus- und Druckzustand. Bei
/// Hover und Fokus wird die Haarlinie zur Tintenkante; der Builder erfährt
/// über `active`, ob er Pfeil und Link hervorheben soll.
class _Pressable extends StatefulWidget {
  final VoidCallback onTap;
  final String semanticsLabel;
  final Widget Function(BuildContext context, bool active) builder;

  const _Pressable({
    required this.onTap,
    required this.semanticsLabel,
    required this.builder,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused;

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (v) => setState(() => _focused = v),
          onHover: (v) => setState(() => _hovered = v),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: AppColors.audienceBeige.withValues(alpha: 0.5),
          highlightColor: AppColors.audienceBeige.withValues(alpha: 0.3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            foregroundDecoration: BoxDecoration(
              border: Border.all(
                color: active ? AppColors.ink : AppColors.line,
                width: _focused ? 2 : 1,
              ),
            ),
            child: widget.builder(context, active),
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
          Text('Nichts gefunden',
              style: Theme.of(context).textTheme.headlineMedium),
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
