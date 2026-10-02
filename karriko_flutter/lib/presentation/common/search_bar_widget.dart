import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/company_provider.dart';

/// Höhe der Eingabezeile inkl. 2px-Rahmen oben und unten.
const double _kBarHeight = 66.0;
const double _kFieldHeight = 62.0;

class HomeSearchBar extends ConsumerStatefulWidget {
  const HomeSearchBar({super.key});

  @override
  ConsumerState<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends ConsumerState<HomeSearchBar> {
  final _controller = TextEditingController();
  final _barKey = GlobalKey();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  /// Öffnet die Such-Ebene: die Leiste fährt aus ihrer Position gerade nach
  /// oben in die Mitte der Bildschirmhöhe, darunter ist Platz für Vorschläge.
  void _open() {
    if (_entry != null) return;

    final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero) & box.size;

    _entry = OverlayEntry(
      builder: (_) => _SearchOverlay(
        controller: _controller,
        originRect: origin,
        onDismissed: () {
          _removeOverlay();
          if (mounted) setState(() {});
        },
        onSubmit: _search,
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  void _search(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    context.go('/search?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    // Während die Overlay-Leiste sichtbar ist, bleibt hier nur der Platzhalter
    // stehen, damit das Layout der Seite unverändert bleibt.
    return SizedBox(
      key: _barKey,
      height: _kBarHeight,
      child: Opacity(
        opacity: _entry != null ? 0 : 1,
        child: _SearchField(
          controller: _controller,
          readOnly: true,
          onTap: _open,
          onSubmit: _search,
        ),
      ),
    );
  }
}

// ─── Overlay: Leiste fährt in die Bildschirmmitte ────────────────────────────

class _SearchOverlay extends StatefulWidget {
  final TextEditingController controller;
  final Rect originRect;
  final VoidCallback onDismissed;
  final ValueChanged<String> onSubmit;

  const _SearchOverlay({
    required this.controller,
    required this.originRect,
    required this.onDismissed,
    required this.onSubmit,
  });

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    reverseDuration: const Duration(milliseconds: 240),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);

  final _focusNode = FocusNode();
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    // Stellt sicher, dass die Endposition auch dann gezeichnet wird, wenn der
    // letzte Animationsframe ausbleibt.
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() {});
    });
    _anim.forward();
    widget.controller.addListener(_onText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focusNode.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onText() => setState(() {});

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _focusNode.unfocus();
    await _anim.reverse();
    if (mounted) widget.onDismissed();
  }

  void _submit(String value) {
    if (value.trim().isEmpty) return;
    // Beim Absenden ohne Rueckwaerts-Animation schliessen, damit die
    // Navigation nicht auf das Ende der Animation warten muss.
    _closing = true;
    _focusNode.unfocus();
    widget.onDismissed();
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final origin = widget.originRect;
    // Zielposition: Leiste steht mittig in der Bildschirmhöhe.
    final targetTop =
        ((screen.height - _kBarHeight) / 2).clamp(24.0, screen.height);
    final query = widget.controller.text;

    return Material(
      type: MaterialType.transparency,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                _close();
                return null;
              },
            ),
          },
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) {
              final t = _t.value;
              final top = lerpDouble(origin.top, targetTop, t)!;
              return Stack(
                children: [
                  // Abdunkelnder Hintergrund, schließt die Suche beim Klick.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _close,
                      child: ColoredBox(
                        color: AppColors.ink.withValues(alpha: 0.28 * t),
                      ),
                    ),
                  ),
                  Positioned(
                    left: origin.left,
                    width: origin.width,
                    top: top,
                    bottom: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SearchField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          onSubmit: _submit,
                        ),
                        if (query.trim().length >= 2)
                          Flexible(
                            child: Opacity(
                              opacity: t,
                              child: _SuggestionsPanel(
                                query: query.trim(),
                                onSelected: (s) {
                                  widget.controller.text = s;
                                  _submit(s);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Eingabezeile ────────────────────────────────────────────────────────────

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String> onSubmit;

  const _SearchField({
    required this.controller,
    required this.onSubmit,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: _kBarHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              readOnly: widget.readOnly,
              canRequestFocus: !widget.readOnly,
              onTap: widget.onTap,
              onSubmitted: widget.onSubmit,
              // Text sitzt linksbündig, aber vertikal mittig in der Zeile.
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Betrieb oder Beruf suchen ...',
                hintStyle:
                    const TextStyle(color: Color(0xFF8C8E88), fontSize: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                suffixIcon: hasText
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.muted, size: 18),
                        onPressed: () => widget.controller.clear(),
                      )
                    : null,
              ),
            ),
          ),
          // Roter Such-Button
          GestureDetector(
            onTap: () => widget.onSubmit(widget.controller.text),
            child: Container(
              width: 58,
              height: _kFieldHeight,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                border:
                    Border(left: BorderSide(color: AppColors.ink, width: 2)),
              ),
              child: const Center(
                child: Icon(Icons.search, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vorschläge ──────────────────────────────────────────────────────────────

class _SuggestionsPanel extends ConsumerWidget {
  final String query;
  final ValueChanged<String> onSelected;

  const _SuggestionsPanel({required this.query, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(searchSuggestionsProvider(query));

    return suggestions.when(
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : _SuggestionList(suggestions: list, onTap: onSelected),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionList({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions
              .map(
                (s) => _SuggestionTile(label: s, onTap: () => onTap(s)),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionTile({required this.label, required this.onTap});

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // onPointerDown statt onTap: der Klick greift auch dann, wenn das
      // Textfeld durch den Klick gerade den Fokus verliert.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => widget.onTap(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surface : AppColors.paper,
            border: Border.all(
              color: _hovered ? AppColors.ink : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 14, color: AppColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
