import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/blog_content.dart';
import '../../data/models/blog_entry_model.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/tap_target.dart';
import 'blog_cover.dart';
import '../common/fit_words_text.dart';

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

/// Breite, ab der das Raster dreispaltig steht (Factsheet §2.3: 1024).
const _wide = 1024.0;

/// Blog und Neuigkeiten nach Seiten-Tab „17 Blog“: Kopf mit Rubriken,
/// Aufmacher, Artikelraster und – sobald es welche gibt – die jüngsten
/// Produkt-Updates als Zeitleiste. Die Inhalte kommen aus [BlogContent].
///
/// Ein RSS-Feed (`/blog/feed.xml`) gehört zur serverseitigen Website (E-08)
/// und steht deshalb hier nicht.
class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  static List<BlogEntry> get _entries => BlogContent.entries;

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

    final showArticles = filter != _Filter.updates && articles.isNotEmpty;
    final showUpdates = filter != _Filter.artikel && updates.isNotEmpty;

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
            if (showArticles) _ArticlesBand(articles: articles),
            if (showUpdates)
              _UpdatesBand(
                // In der Gesamtansicht die fünf jüngsten, sonst alle.
                updates:
                    filter == _Filter.alle ? updates.take(5).toList() : updates,
                showAllLink: filter == _Filter.alle && updates.length > 5,
              ),
            if (!showArticles && !showUpdates) const _EmptyState(),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

// ─── Kopf mit Rubriken ───────────────────────────────────────────────────────

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
    final isWide = width >= _wide;

    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Kicker('BLOG & NEUIGKEITEN'),
        const SizedBox(height: AppLayout.s24),
        Text(
          'Was wir schreiben,\nwas wir bauen.',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: isWide
                ? (width * 0.045).clamp(48.0, 64.0)
                : (width * 0.085).clamp(30.0, 40.0),
            fontWeight: FontWeight.w800,
            height: 0.96,
            letterSpacing: isWide ? -1 : -0.5,
          ),
        ),
      ],
    );

    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Artikel rund um Ausbildung und Bewerbung und jede neue Funktion, '
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.only(
          top: isWide ? AppLayout.s64 + AppLayout.s32 : AppLayout.s48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 7, child: headline),
                  const SizedBox(width: AppLayout.s64),
                  Expanded(flex: 4, child: intro),
                ],
              )
            else ...[
              headline,
              const SizedBox(height: AppLayout.s24),
              intro,
            ],
            SizedBox(height: isWide ? AppLayout.s64 : AppLayout.s32),
            _FilterTabs(active: active, counts: counts),
          ],
        ),
      ),
    );
  }
}

/// Rubriken am unteren Rand des Kopfes; der aktive Reiter sitzt mit einer
/// Tintenkante auf der Haarlinie. Ein [Wrap], damit die Leiste bei schmalen
/// Viewports oder großer Systemschrift umbricht.
class _FilterTabs extends StatelessWidget {
  final _Filter active;
  final Map<_Filter, int> counts;

  const _FilterTabs({required this.active, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppLayout.s32,
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
    return Semantics(
      selected: selected,
      label: '${filter.label}, $count Beiträge',
      excludeSemantics: true,
      child: TapTarget(
        // Der Filter landet in der URL: teilbar, und der Zurück-Button
        // führt zur vorherigen Auswahl zurück.
        onTap: () => context.go(filter.location),
        builder: (context, active) {
          final color = selected || active ? AppColors.ink : AppColors.muted;
          return Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? AppColors.ink
                      : (active ? AppColors.line : Colors.transparent),
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flexible: ein einzelner Reiter kann bei großer Schrift
                // breiter sein als die ganze Zeile. Dann bricht sein Text um.
                Flexible(
                  child: Text(
                    filter.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppLayout.s8),
                Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? AppColors.accentDark : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Artikel ─────────────────────────────────────────────────────────────────

/// Jüngster Artikel als Aufmacher, darunter die übrigen als Raster.
class _ArticlesBand extends StatelessWidget {
  final List<BlogEntry> articles;

  const _ArticlesBand({required this.articles});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _wide;
    final rest = articles.skip(1).toList();

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(
          vertical: isWide ? AppLayout.s64 : AppLayout.s48,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            // Drei Spalten ab 1024 px; bei wenigen Artikeln so viele, wie es
            // gibt, damit keine leere Spalte stehen bleibt.
            final maxColumns = isWide ? 3 : (w >= 560 ? 2 : 1);
            final columns = rest.isEmpty ? 1 : rest.length.clamp(1, maxColumns);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FeaturedArticle(entry: articles.first, wide: w >= 760),
                if (rest.isNotEmpty) ...[
                  SizedBox(height: isWide ? AppLayout.s64 : AppLayout.s48),
                  const _SectionLabel('WEITERE ARTIKEL'),
                  const SizedBox(height: AppLayout.s32),
                  _CardGrid(
                    columns: columns,
                    children: [for (final e in rest) _ArticleCard(entry: e)],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Aufmacher: Titelbild 3:2 links, Text rechts; schmal untereinander. Die
/// ganze Fläche ist das Klickziel.
class _FeaturedArticle extends StatelessWidget {
  final BlogEntry entry;
  final bool wide;

  const _FeaturedArticle({required this.entry, required this.wide});

  @override
  Widget build(BuildContext context) {
    return TapTarget(
      onTap: () => context.go('/blog/${entry.slug}'),
      builder: (context, active) {
        final cover = AspectRatio(
          aspectRatio: 3 / 2,
          child: BlogCover(category: entry.category!, iconSize: 96),
        );

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Kicker('NEUESTER ARTIKEL'),
            const SizedBox(height: AppLayout.s16),
            Text(
              entry.title,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: wide ? 36 : 26,
                fontWeight: FontWeight.w800,
                height: 1.08,
                letterSpacing: -0.5,
                decoration:
                    active ? TextDecoration.underline : TextDecoration.none,
                decorationThickness: 2,
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            Text(
              entry.teaser,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 17, height: 1.55),
            ),
            const SizedBox(height: AppLayout.s24),
            _ArticleMeta(entry: entry),
            const SizedBox(height: AppLayout.s24),
            _ReadMore(active: active),
          ],
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cover, const SizedBox(height: AppLayout.s24), body],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 7, child: cover),
            const SizedBox(width: AppLayout.s48),
            Expanded(flex: 5, child: body),
          ],
        );
      },
    );
  }
}

/// Artikelkarte ohne Rahmen: Titelbild 3:2, Rubrik, Titel, Teaser, Angaben.
class _ArticleCard extends StatelessWidget {
  final BlogEntry entry;

  const _ArticleCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return TapTarget(
      onTap: () => context.go('/blog/${entry.slug}'),
      builder: (context, active) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 3 / 2,
            child: BlogCover(category: entry.category!, iconSize: 56),
          ),
          const SizedBox(height: AppLayout.s24),
          FitWordsText(
            entry.title,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              decoration:
                  active ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          Text(
            entry.teaser,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.muted, fontSize: 15, height: 1.55),
          ),
          const Spacer(),
          const SizedBox(height: AppLayout.s16),
          _ArticleMeta(entry: entry),
        ],
      ),
    );
  }
}

/// Raster mit gleich hohen Karten pro Zeile, damit die Angaben unten auf
/// einer Linie stehen.
class _CardGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const _CardGrid({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppLayout.s48));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: AppLayout.s32),
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

/// Datum und Lesezeit, durch einen Mittelpunkt getrennt.
class _ArticleMeta extends StatelessWidget {
  final BlogEntry entry;

  const _ArticleMeta({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${entry.formattedDate}  ·  ${entry.readingMinutes} Min. Lesezeit',
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 13,
        height: 1.35,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _ReadMore extends StatelessWidget {
  final bool active;

  const _ReadMore({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accentDark : AppColors.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Weiterlesen',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppLayout.s8),
        Icon(Icons.arrow_forward, size: 18, color: color),
      ],
    );
  }
}

// ─── Produkt-Updates ─────────────────────────────────────────────────────────

/// Zeitleiste der Updates: Datum links, Satz rechts. Bis zum Start gibt es
/// keine Updates (T-11.8); dann steht dieses Band nicht da.
class _UpdatesBand extends StatelessWidget {
  final List<BlogEntry> updates;
  final bool showAllLink;

  const _UpdatesBand({required this.updates, required this.showAllLink});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wide;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Kicker('PRODUKT-UPDATES'),
        const SizedBox(height: AppLayout.s16),
        Text(
          'Neu auf Karriko.',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: isWide ? 40 : 30,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < updates.length; i++)
          _TimelineRow(entry: updates[i], isLast: i == updates.length - 1),
        if (showAllLink) ...[
          const SizedBox(height: AppLayout.s24),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go(_Filter.updates.location),
              child: const Text('Alle Updates'),
            ),
          ),
        ],
      ],
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.symmetric(
          vertical: isWide ? AppLayout.s64 : AppLayout.s48,
        ),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  const SizedBox(height: AppLayout.s32),
                  list
                ],
              ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final BlogEntry entry;
  final bool isLast;

  const _TimelineRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    final date = Text(
      entry.formattedDate,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppLayout.s8,
          runSpacing: AppLayout.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _UpdateBadge(kind: entry.updateKind!),
            if (entry.version != null)
              Text(entry.version!,
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppLayout.s8),
        Text(
          entry.title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.teaser,
          style: const TextStyle(
              color: AppColors.muted, fontSize: 15, height: 1.55),
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
                SizedBox(width: 136, child: date),
                Expanded(child: body),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [date, const SizedBox(height: AppLayout.s8), body],
            ),
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

/// Abschnittsbezeichnung in Versalien mit Tintenkante darüber.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: AppLayout.s16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.32,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nichts gefunden',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppLayout.s8),
            const Text(
              'In dieser Rubrik gibt es aktuell keine Beiträge.',
              style:
                  TextStyle(color: AppColors.muted, fontSize: 17, height: 1.55),
            ),
            const SizedBox(height: AppLayout.s24),
            OutlinedButton(
              onPressed: () => context.go('/blog'),
              child: const Text('Alle Beiträge anzeigen'),
            ),
          ],
        ),
      ),
    );
  }
}
