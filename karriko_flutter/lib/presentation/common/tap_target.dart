import 'package:flutter/material.dart';

/// Klickziel für Stellen, an denen ein [InkWell] nicht passt – etwa weil die
/// Fläche selbst eine Farbe trägt, die die Tinte verdecken würde, oder weil
/// der Hover-Zustand die Schrift statt den Hintergrund verändern soll.
///
/// Bringt mit, was ein blosser GestureDetector nicht hat: Hand-Cursor im
/// Browser, Hover- und Fokuszustand für [builder], Bedienung per Tab und
/// Enter/Leertaste sowie die Rolle „Button“ für Screenreader. Ohne [onTap]
/// ist das Ziel deaktiviert: kein Hand-Cursor, kein Fokus.
///
/// Der Inhalt ist von der globalen Textauswahl ausgenommen, damit ein Klick
/// mit leichter Mausbewegung navigiert, statt Text zu markieren.
class TapTarget extends StatefulWidget {
  final VoidCallback? onTap;

  /// Baut den Inhalt; `active` ist wahr bei Hover oder Tastaturfokus.
  final Widget Function(BuildContext context, bool active) builder;

  final HitTestBehavior? behavior;

  const TapTarget({
    super.key,
    required this.onTap,
    required this.builder,
    this.behavior,
  });

  @override
  State<TapTarget> createState() => _TapTargetState();
}

class _TapTargetState extends State<TapTarget> {
  bool _hovered = false;
  bool _focused = false;

  void _activate() => widget.onTap?.call();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    // Hover ueber einen eigenen MouseRegion wie bei InkWell: Das Hover-Signal
    // des FocusableActionDetector haengt am Fokus-Hervorhebungsmodus und
    // bleibt aus, solange dieser auf Touch steht.
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        // Im Web löst Enter ein ButtonActivateIntent aus, die Leertaste ein
        // ActivateIntent – wie bei InkWell werden beide bedient.
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: Semantics(
          button: true,
          enabled: enabled,
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: widget.behavior,
            child: SelectionContainer.disabled(
              child: widget.builder(context, enabled && (_hovered || _focused)),
            ),
          ),
        ),
      ),
    );
  }
}
