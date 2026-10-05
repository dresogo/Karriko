import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/blog_content.dart';
import '../../data/models/blog_entry_model.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import 'blog_cover.dart';

/// Detailseite eines Artikels: Kopf mit Rubrik und Einleitung, der Text in
/// lesbarer Spaltenbreite mit Inhaltsverzeichnis daneben, danach weitere
/// Artikel und ein passender nächster Schritt.
class BlogDetailScreen extends StatefulWidget {
  final String slug;
  const BlogDetailScreen({super.key, required this.slug});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final _scroll = ScrollController();

  /// Sprungziele für das Inhaltsverzeichnis, je Zwischenüberschrift.
  final _headingKeys = <int, GlobalKey>{};

  /// Index der Überschrift, in deren Abschnitt gerade gelesen wird.
  int? _activeHeading;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateActiveHeading);
  }

  @override
  void didUpdateWidget(BlogDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _headingKeys.clear();
      _activeHeading = null;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Aktiv ist die letzte Überschrift, die das obere Viertel des sichtbaren
  /// Bereichs erreicht hat.
  void _updateActiveHeading() {
    final viewport = context.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) return;
    final threshold =
        viewport.localToGlobal(Offset.zero).dy + viewport.size.height * 0.25;

    int? active;
    final indices = _headingKeys.keys.toList()..sort();
    for (final index in indices) {
      final box =
          _headingKeys[index]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= threshold) active = index;
    }
    if (active != _activeHeading) setState(() => _activeHeading = active);
  }

  GlobalKey _keyFor(int index) =>
      _headingKeys.putIfAbsent(index, GlobalKey.new);

  void _jumpTo(int index) {
    final target = _headingKeys[index]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.05,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = BlogContent.articleBySlug(widget.slug);

    return Scaffold(
      appBar: const KarrikoAppBar(),
      drawer: const KarrikoDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entry != null) _ReadingProgress(controller: _scroll),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (entry == null)
                    const _NotFound()
                  else ...[
                    _ArticleHeader(entry: entry),
                    _ArticleBody(
                      entry: entry,
                      keyFor: _keyFor,
                      onJump: _jumpTo,
                      activeHeading: _activeHeading,
                      scroll: _scroll,
                    ),
                    _RelatedArticles(current: entry),
                    _NextStep(category: entry.category!),
                  ],
                  const FooterWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lesefortschritt ─────────────────────────────────────────────────────────

/// Schmaler Balken unter der App-Leiste, der mit dem Scrollen wächst.
class _ReadingProgress extends StatelessWidget {
  final ScrollController controller;

  const _ReadingProgress({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          var progress = 0.0;
          if (controller.hasClients &&
              controller.position.hasContentDimensions &&
              controller.position.maxScrollExtent > 0) {
            progress = (controller.offset / controller.position.maxScrollExtent)
                .clamp(0.0, 1.0);
          }
          return LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            color: AppColors.accent,
            backgroundColor: AppColors.line,
          );
        },
      ),
    );
  }
}

// ─── Kopf ────────────────────────────────────────────────────────────────────

class _ArticleHeader extends StatelessWidget {
  final BlogEntry entry;

  const _ArticleHeader({required this.entry});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 720;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.only(top: isWide ? AppLayout.s32 : AppLayout.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Breadcrumb(category: entry.category!),
            SizedBox(height: isWide ? AppLayout.s32 : AppLayout.s24),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Text(
                          entry.title,
                          // Mit der Standardschrift zusammengeführt, damit die
                          // Messung dieselbe Schriftart nutzt wie die Anzeige.
                          style: _fitLongestWord(
                            entry.title,
                            DefaultTextStyle.of(context).style.merge(TextStyle(
                                  color: AppColors.ink,
                                  fontSize: (width * 0.04).clamp(32.0, 52.0),
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  letterSpacing: -0.5,
                                )),
                            constraints.maxWidth,
                            MediaQuery.textScalerOf(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppLayout.s24),
                    Text(
                      entry.teaser,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: isWide ? 20 : 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppLayout.s24),
                    _Byline(entry: entry),
                  ],
                ),
              ),
            ),
            SizedBox(height: isWide ? AppLayout.s48 : AppLayout.s32),
            BlogCover(
              category: entry.category!,
              height: isWide ? 220 : 140,
              iconSize: isWide ? 112 : 64,
            ),
          ],
        ),
      ),
    );
  }
}

/// Verkleinert die Schrift, bis das längste Wort in eine Zeile passt. Flutter
/// trennt keine Silben, lange Komposita wie „Ausbildungsbewertungen“ würden
/// auf schmalen Viewports sonst mitten im Wort umbrechen.
TextStyle _fitLongestWord(
  String text,
  TextStyle style,
  double maxWidth,
  TextScaler scaler,
) {
  const minSize = 22.0;
  final longest = text
      .split(RegExp(r'\s+'))
      .fold('', (a, b) => b.length > a.length ? b : a);

  var fitted = style;
  while ((fitted.fontSize ?? 14) > minSize) {
    final painter = TextPainter(
      text: TextSpan(text: longest, style: fitted),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final fits = painter.width <= maxWidth;
    painter.dispose();
    if (fits) break;
    fitted = fitted.copyWith(fontSize: fitted.fontSize! - 1);
  }
  return fitted;
}

class _Breadcrumb extends StatelessWidget {
  final String category;

  const _Breadcrumb({required this.category});

  @override
  Widget build(BuildContext context) {
    const separator = Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
    );

    return Semantics(
      container: true,
      label: 'Brotkrumen-Navigation',
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _CrumbLink(label: 'Blog', location: '/blog'),
          separator,
          const _CrumbLink(label: 'Artikel', location: '/blog?typ=artikel'),
          separator,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              category,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrumbLink extends StatelessWidget {
  final String label;
  final String location;

  const _CrumbLink({required this.label, required this.location});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(location),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.muted,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// Autor, Datum und Lesezeit unter der Einleitung.
class _Byline extends StatelessWidget {
  final BlogEntry entry;

  const _Byline({required this.entry});

  @override
  Widget build(BuildContext context) {
    final meta = Theme.of(context).textTheme.bodySmall;

    return Wrap(
      spacing: AppLayout.s24,
      runSpacing: AppLayout.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              color: AppColors.ink,
              alignment: Alignment.center,
              child: const Text(
                'K',
                style: TextStyle(
                  color: AppColors.paper,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppLayout.s8),
            const Text(
              'Karriko-Redaktion',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        _IconMeta(
          icon: Icons.calendar_today_outlined,
          text: entry.formattedDate,
          style: meta,
        ),
        _IconMeta(
          icon: Icons.schedule,
          text: '${entry.readingMinutes} Min. Lesezeit',
          style: meta,
        ),
      ],
    );
  }
}

class _IconMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle? style;

  const _IconMeta({required this.icon, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}

// ─── Text ────────────────────────────────────────────────────────────────────

class _ArticleBody extends StatelessWidget {
  final BlogEntry entry;
  final GlobalKey Function(int index) keyFor;
  final void Function(int index) onJump;

  final int? activeHeading;
  final ScrollController scroll;

  const _ArticleBody({
    required this.entry,
    required this.keyFor,
    required this.onJump,
    required this.activeHeading,
    required this.scroll,
  });

  /// Lesbare Zeilenlänge: rund 70 Zeichen bei 18 px.
  static const _measure = 680.0;
  static const _sidebarWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    final headings = [
      for (final (i, block) in entry.body.indexed)
        if (block is ArticleHeading) (index: i, text: block.text),
    ];

    return ContentBand(
      padding: const EdgeInsets.only(top: AppLayout.s48, bottom: AppLayout.s64),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasSidebar = constraints.maxWidth >= 960;

          final article = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _measure),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasSidebar && headings.length > 1) ...[
                  _TableOfContents(
                    headings: headings,
                    onJump: onJump,
                    activeHeading: null,
                  ),
                  const SizedBox(height: AppLayout.s48),
                ],
                ..._buildBlocks(context),
                const SizedBox(height: AppLayout.s48),
                const Divider(height: 1),
                const SizedBox(height: AppLayout.s24),
                const _ArticleActions(),
              ],
            ),
          );

          if (!hasSidebar) {
            return Align(alignment: Alignment.centerLeft, child: article);
          }

          final main = Padding(
            padding:
                const EdgeInsets.only(right: _sidebarWidth + AppLayout.s64),
            child: Align(alignment: Alignment.topLeft, child: article),
          );
          if (headings.isEmpty) return main;

          return _StickySidebar(
            scroll: scroll,
            width: _sidebarWidth,
            sidebar: _TableOfContents(
              headings: headings,
              onJump: onJump,
              activeHeading: activeHeading,
            ),
            child: main,
          );
        },
      ),
    );
  }

  List<Widget> _buildBlocks(BuildContext context) {
    final widgets = <Widget>[];
    var headingNumber = 0;

    for (final (i, block) in entry.body.indexed) {
      final isFirst = widgets.isEmpty;
      switch (block) {
        case ArticleParagraph(:final text):
          widgets.add(Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : AppLayout.s16),
            child: Text(text, style: _bodyStyle),
          ));
        case ArticleHeading(:final text):
          headingNumber++;
          widgets.add(Padding(
            key: keyFor(i),
            padding: EdgeInsets.only(
              top: isFirst ? 0 : AppLayout.s48,
              bottom: AppLayout.s8,
            ),
            child: _BodyHeading(number: headingNumber, text: text),
          ));
        case ArticleList(:final items, :final ordered):
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: AppLayout.s16),
            child: _BodyList(items: items, ordered: ordered),
          ));
        case ArticleCallout(:final title, :final text):
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: AppLayout.s24),
            child: _Callout(title: title, text: text),
          ));
      }
    }
    return widgets;
  }
}

const _bodyStyle = TextStyle(
  color: AppColors.ink,
  fontSize: 18,
  height: 1.75,
);

class _BodyHeading extends StatelessWidget {
  final int number;
  final String text;

  const _BodyHeading({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(
              number.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyList extends StatelessWidget {
  final List<String> items;
  final bool ordered;

  const _BodyList({required this.items, required this.ordered});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, item) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppLayout.s8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: ordered
                      ? Text(
                          '${i + 1}.',
                          style: _bodyStyle.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        )
                      : Padding(
                          // Mittig zur ersten Textzeile (18 px × 1,75).
                          padding: const EdgeInsets.only(top: 12, left: 4),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              width: 7,
                              height: 7,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                ),
                Expanded(child: Text(item, style: _bodyStyle)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Hervorgehobener Hinweis mit Tintenkante links.
class _Callout extends StatelessWidget {
  final String title;
  final String text;

  const _Callout({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: const BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border(left: BorderSide(color: AppColors.ink, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child:
                Icon(Icons.lightbulb_outline, size: 22, color: AppColors.ink),
          ),
          const SizedBox(width: AppLayout.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seitenspalte, die beim Scrollen am oberen Rand mitläuft, bis der Text
/// endet. Die Spalte liegt positioniert über dem Text; ihre Höhe bestimmt
/// allein der Text, damit nichts davon abhängt, wie hoch die Spalte ist.
class _StickySidebar extends StatefulWidget {
  final ScrollController scroll;
  final double width;
  final Widget sidebar;
  final Widget child;

  const _StickySidebar({
    required this.scroll,
    required this.width,
    required this.sidebar,
    required this.child,
  });

  @override
  State<_StickySidebar> createState() => _StickySidebarState();
}

class _StickySidebarState extends State<_StickySidebar> {
  final _stackKey = GlobalKey();
  final _sidebarKey = GlobalKey();

  /// Abstand zum oberen Rand des sichtbaren Bereichs.
  static const _gap = AppLayout.s24;

  double _offset() {
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final sidebar =
        _sidebarKey.currentContext?.findRenderObject() as RenderBox?;
    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (stack == null ||
        sidebar == null ||
        viewport == null ||
        !stack.hasSize ||
        !sidebar.hasSize ||
        !stack.attached) {
      return 0;
    }

    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    // Position ohne den aktuellen Versatz der Spalte.
    final stackTop = stack.localToGlobal(Offset.zero).dy;
    final maxOffset = stack.size.height - sidebar.size.height;
    if (maxOffset <= 0) return 0;
    return (viewportTop + _gap - stackTop).clamp(0.0, maxOffset);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.scroll,
      builder: (context, child) => Stack(
        key: _stackKey,
        children: [
          child!,
          Positioned(
            top: _offset(),
            right: 0,
            width: widget.width,
            child: KeyedSubtree(key: _sidebarKey, child: widget.sidebar),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

/// Inhaltsverzeichnis; ein Tipp springt zur jeweiligen Zwischenüberschrift.
/// Der Abschnitt, in dem gerade gelesen wird, ist hervorgehoben.
class _TableOfContents extends StatelessWidget {
  final List<({int index, String text})> headings;
  final void Function(int index) onJump;
  final int? activeHeading;

  const _TableOfContents({
    required this.headings,
    required this.onJump,
    required this.activeHeading,
  });

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
          const Text(
            'IN DIESEM ARTIKEL',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.32,
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          for (final (n, heading) in headings.indexed)
            _TocItem(
              number: n + 1,
              text: heading.text,
              active: heading.index == activeHeading,
              onTap: () => onJump(heading.index),
            ),
        ],
      ),
    );
  }
}

class _TocItem extends StatelessWidget {
  final int number;
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _TocItem({
    required this.number,
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Zu Abschnitt $number springen: $text',
      selected: active,
      excludeSemantics: true,
      child: Material(
        color: active ? AppColors.audienceBeige : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.audienceBeige,
          focusColor: AppColors.audienceBeige,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: active ? AppColors.ink : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.s8,
                vertical: 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      number.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Teilen und Rückweg am Ende des Textes.
class _ArticleActions extends StatelessWidget {
  const _ArticleActions();

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: Uri.base.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Link in die Zwischenablage kopiert'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppLayout.s16,
      runSpacing: AppLayout.s16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.go('/blog'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Alle Beiträge'),
        ),
        TextButton.icon(
          onPressed: () => _copyLink(context),
          icon: const Icon(Icons.link, size: 18),
          label: const Text('Link kopieren'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size(44, 48),
          ),
        ),
      ],
    );
  }
}

// ─── Weiterlesen ─────────────────────────────────────────────────────────────

class _RelatedArticles extends StatelessWidget {
  final BlogEntry current;

  const _RelatedArticles({required this.current});

  @override
  Widget build(BuildContext context) {
    // Erst dieselbe Rubrik, dann die jüngsten übrigen Artikel.
    final others =
        BlogContent.articles.where((e) => e.slug != current.slug).toList()
          ..sort((a, b) {
            final sameA = a.category == current.category ? 0 : 1;
            final sameB = b.category == current.category ? 0 : 1;
            if (sameA != sameB) return sameA - sameB;
            return b.date.compareTo(a.date);
          });
    final related = others.take(3).toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : (constraints.maxWidth >= 560 ? 2 : 1);

            final rows = <Widget>[];
            for (var i = 0; i < related.length; i += columns) {
              if (rows.isNotEmpty) {
                rows.add(const SizedBox(height: AppLayout.s24));
              }
              rows.add(IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: AppLayout.s24),
                      Expanded(
                        child: i + c < related.length
                            ? _RelatedCard(entry: related[i + c])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Weiterlesen',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppLayout.s24),
                ...rows,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RelatedCard extends StatefulWidget {
  final BlogEntry entry;

  const _RelatedCard({required this.entry});

  @override
  State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final active = _hovered || _focused;

    return Semantics(
      button: true,
      label: 'Artikel: ${entry.title}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: () => context.go('/blog/${entry.slug}'),
          onHover: (v) => setState(() => _hovered = v),
          onFocusChange: (v) => setState(() => _focused = v),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: AppColors.audienceBeige.withValues(alpha: 0.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            foregroundDecoration: BoxDecoration(
              border: Border.all(
                color: active ? AppColors.ink : AppColors.line,
                width: _focused ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlogCover(category: entry.category!, height: 96, iconSize: 36),
                Padding(
                  padding: const EdgeInsets.all(AppLayout.s24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppLayout.s16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${entry.formattedDate} · '
                              '${entry.readingMinutes} Min.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            offset: active ? const Offset(0.3, 0) : Offset.zero,
                            child: Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: active ? AppColors.accent : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ─── Nächster Schritt ────────────────────────────────────────────────────────

/// Abschlussband mit einem zur Rubrik passenden nächsten Schritt.
class _NextStep extends StatelessWidget {
  final String category;

  const _NextStep({required this.category});

  @override
  Widget build(BuildContext context) {
    final forCompanies = category == 'Für Betriebe';
    final (title, text, label, location) = forCompanies
        ? (
            'Zeig, wie gut deine Ausbildung ist.',
            'Lege ein Betriebsprofil an, antworte auf Bewertungen und werde '
                'von passenden Azubis gefunden.',
            'Mehr für Betriebe',
            '/fuer-betriebe',
          )
        : (
            'Finde deinen Ausbildungsbetrieb.',
            'Lies echte Erfahrungsberichte von Azubis und vergleiche Betriebe '
                'nach Branche, Ort und Bewertung.',
            'Betriebe entdecken',
            '/search',
          );

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 820;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.paper,
            fontSize: isWide ? 36 : 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.line,
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ],
    );

    final button = FilledButton.icon(
      onPressed: () => context.go(location),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.arrow_forward, size: 18),
      label: Text(label),
    );

    return Container(
      color: AppColors.ink,
      child: ContentBand(
        padding: EdgeInsets.symmetric(
          vertical: isWide ? AppLayout.s64 : AppLayout.s48,
        ),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: copy,
                    ),
                  ),
                  const SizedBox(width: AppLayout.s48),
                  button,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: AppLayout.s24),
                  button,
                ],
              ),
      ),
    );
  }
}

// ─── Nicht gefunden ──────────────────────────────────────────────────────────

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return ContentBand(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
      child: Container(
        padding: const EdgeInsets.all(AppLayout.s48),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artikel nicht gefunden',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppLayout.s8),
            Text(
              'Diesen Artikel gibt es nicht oder nicht mehr. Vielleicht hilft '
              'ein Blick in die Übersicht.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppLayout.s24),
            OutlinedButton.icon(
              onPressed: () => context.go('/blog'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Zur Übersicht'),
            ),
          ],
        ),
      ),
    );
  }
}
