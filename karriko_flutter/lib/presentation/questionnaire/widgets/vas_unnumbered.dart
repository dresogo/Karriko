import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../question_context.dart';

/// Der Regler ohne Zahl — K6 und der Korrekturregler aus A2.
///
/// Es gibt genau zwei davon im ganzen Bogen, und beide sehen so aus:
///
/// * **Kein Griff, bis jemand ihn anfasst.** Ein vorgesetzter Griff ist ein
///   Vorschlag, und Vorschläge werden angenommen. Ohne Startposition gibt es
///   keinen, von dem aus man sich wegbewegt.
/// * **Keine Zahl.** Läuft eine Zahl mit, rastet die Antwort auf 50, 75 oder
///   100 ein. Ohne sie bleibt die Position, die jemand tatsächlich gemeint hat.
/// * **Beschriftung nur an den Enden**, und die steht in der Definition.
/// * „Nicht beantwortet" ist ein eigener Zustand und nicht 0. Wer den Regler
///   nie berührt, hat nichts gesagt — nicht „am schlechtesten".
class VasUnnumbered extends StatefulWidget {
  final QuestionContext context;

  const VasUnnumbered({super.key, required this.context});

  @override
  State<VasUnnumbered> createState() => _VasUnnumberedState();
}

class _VasUnnumberedState extends State<VasUnnumbered> {
  final _focus = FocusNode();

  int? get _wert {
    final antwort = widget.context.answer;
    return antwort is num ? antwort.round() : null;
  }

  int get _min => (widget.context.configNum('min') ?? 0).round();
  int get _max => (widget.context.configNum('max') ?? 100).round();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _setzen(int wert) {
    widget.context.onChanged(wert.clamp(_min, _max));
  }

  void _ausPosition(double anteil) {
    _setzen((_min + anteil.clamp(0, 1) * (_max - _min)).round());
  }

  /// Tastatur.
  ///
  /// Beim ersten Tastendruck muss der Griff irgendwo erscheinen, und das ist
  /// unvermeidlich eine Startposition — genau das, was der Zeiger-Weg
  /// vermeidet. Die Mitte ist dabei die ehrlichste Wahl: Sie bevorzugt weder
  /// die gute noch die schlechte Seite.
  KeyEventResult _taste(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final schritt = HardwareKeyboard.instance.isShiftPressed ? 10 : 1;
    final aktuell = _wert;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowDown:
        _setzen((aktuell ?? (_min + _max) ~/ 2) - (aktuell == null ? 0 : schritt));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowUp:
        _setzen((aktuell ?? (_min + _max) ~/ 2) + (aktuell == null ? 0 : schritt));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _setzen(_min);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _setzen(_max);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.context;
    final endLabels = ctx.config<Map<String, Object?>>('endLabels') ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          slider: true,
          label: ctx.text,
          // Für sehende Nutzer gibt es bewusst keine Zahl. Wer den Griff aber
          // nicht sehen kann, braucht die Position in Worten — sonst ist der
          // Regler unbedienbar. Der Ankereffekt, um den es oben geht, entsteht
          // an der mitlaufenden Anzeige, nicht an einer Vorlesung auf Abruf.
          value: _wert == null
              ? (ctx.sharedText('ui.not_answered') ?? '')
              : '${(((_wert! - _min) / (_max - _min)) * 100).round()} %',
          child: Focus(
            focusNode: _focus,
            onKeyEvent: _taste,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final breite = constraints.maxWidth;
                void ausLokal(Offset position) {
                  _focus.requestFocus();
                  _ausPosition(position.dx / breite);
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => ausLokal(d.localPosition),
                  onHorizontalDragStart: (d) => ausLokal(d.localPosition),
                  onHorizontalDragUpdate: (d) => ausLokal(d.localPosition),
                  child: _Bahn(
                    anteil: _wert == null
                        ? null
                        : (_wert! - _min) / (_max - _min),
                    fokussiert: _focus.hasFocus,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppLayout.s8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Ende(_labelVon(endLabels['min'])),
            _Ende(_labelVon(endLabels['max'])),
          ],
        ),
      ],
    );
  }

  String _labelVon(Object? roh) {
    if (roh is String) return roh;
    if (roh is Map && roh['current'] is String) return roh['current']! as String;
    return '';
  }
}

/// Der Griff des Reglers.
///
/// Trägt eine Kennung, weil „ist der Griff da?" die eigentliche Zusage dieses
/// Widgets ist und sich sonst nur über Farben und Größen prüfen ließe.
const griffKey = ValueKey<String>('vas-griff');

class _Bahn extends StatelessWidget {
  /// `null` heißt: noch kein Griff. Genau dafür ist der Typ hier nullable.
  final double? anteil;
  final bool fokussiert;

  const _Bahn({required this.anteil, required this.fokussiert});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.line,
              border: Border.all(
                color: fokussiert ? AppColors.accent : AppColors.line,
                width: fokussiert ? 2 : 0,
              ),
            ),
          ),
          if (anteil != null)
            LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: EdgeInsets.only(
                  left: (constraints.maxWidth - 28) * anteil!,
                ),
                child: Container(
                  key: griffKey,
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Ende extends StatelessWidget {
  final String text;

  const _Ende(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: AppColors.muted, fontSize: 14),
      );
}
