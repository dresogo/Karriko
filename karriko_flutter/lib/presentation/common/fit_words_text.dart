import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Text, der nie mitten im Wort umbricht (T-11.14).
///
/// Flutter trennt nicht nach Silben. Ist das längste Wort breiter als die
/// Zeile, etwa „Bewertungen“ in 48 px bei 320 px Breite, wird es irgendwo
/// geteilt („Bewertunge / n“). Dieses Widget misst beim Layout das längste
/// Wort und verkleinert die Schrift genau so weit, dass es passt. Ist genug
/// Platz, bleibt alles wie bei [Text].
///
/// Für Überschriften gedacht. Fließtext bekommt stattdessen weiche
/// Trennstriche (`­`) an den Wortfugen, damit die Lesegröße bleibt.
///
/// Als eigenes Render-Objekt statt mit `LayoutBuilder`, weil Überschriften
/// oft in Rastern gleich hoher Karten unter `IntrinsicHeight` stehen.
class FitWordsText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const FitWordsText(this.text, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    final standard = DefaultTextStyle.of(context);
    final basis = standard.style.merge(style);
    // Registrar und Auswahlfarbe wie bei [Text]: Die Überschrift bleibt in
    // der globalen Textauswahl markierbar (E-10).
    return _FitWordsParagraph(
      text: TextSpan(text: text, style: basis),
      textAlign: textAlign ?? standard.textAlign ?? TextAlign.start,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      registrar: SelectionContainer.maybeOf(context),
      selectionColor: DefaultSelectionStyle.of(context).selectionColor,
    );
  }
}

class _FitWordsParagraph extends LeafRenderObjectWidget {
  final TextSpan text;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final SelectionRegistrar? registrar;
  final Color? selectionColor;

  const _FitWordsParagraph({
    required this.text,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    required this.registrar,
    required this.selectionColor,
  });

  @override
  _RenderFitWords createRenderObject(BuildContext context) => _RenderFitWords(
        text,
        textAlign: textAlign,
        textDirection: textDirection,
        baseScaler: textScaler,
        registrar: registrar,
        selectionColor: selectionColor,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderFitWords renderObject) {
    renderObject
      ..text = text
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..baseScaler = textScaler
      ..registrar = registrar
      ..selectionColor = selectionColor;
  }
}

class _RenderFitWords extends RenderParagraph {
  _RenderFitWords(
    TextSpan super.text, {
    required super.textAlign,
    required super.textDirection,
    required TextScaler baseScaler,
    super.registrar,
    super.selectionColor,
  })  : _baseScaler = baseScaler,
        super(textScaler: baseScaler);

  TextScaler _baseScaler;
  double? _breitestes;

  set baseScaler(TextScaler value) {
    if (value == _baseScaler) return;
    _baseScaler = value;
    _breitestes = null;
    markNeedsLayout();
  }

  @override
  set text(InlineSpan value) {
    if (value != text) _breitestes = null;
    super.text = value;
  }

  /// Breite des längsten Worts in der Grundgröße.
  double _breitestesWort() {
    final cached = _breitestes;
    if (cached != null) return cached;
    final span = text as TextSpan;
    var breitestes = 0.0;
    for (final wort in (span.text ?? '').split(RegExp(r'\s+'))) {
      if (wort.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: wort, style: span.style),
        textDirection: textDirection,
        textScaler: _baseScaler,
        maxLines: 1,
      )..layout();
      breitestes = math.max(breitestes, painter.width);
      painter.dispose();
    }
    return _breitestes = breitestes;
  }

  @override
  void performLayout() {
    final breite = constraints.maxWidth;
    // Etwas Luft gegen Rundung der Glyphenbreiten beim Zeichnen.
    final platz = breite * 0.98;
    final breitestes = _breitestesWort();
    final passend = breite.isFinite && breitestes > platz
        ? _FitScaler(_baseScaler, platz / breitestes)
        : _baseScaler;
    // Die eigene Schriftgröße ändert sich erst hier, wenn die Breite bekannt
    // ist. Das Setzen markiert das Objekt als neu zu layouten; der Rückruf
    // erlaubt das während des laufenden Layouts.
    if (passend != textScaler) {
      invokeLayoutCallback<BoxConstraints>((_) => textScaler = passend);
    }
    super.performLayout();
  }
}

/// Verkleinert die Schrift über den System-Faktor hinaus um [faktor].
class _FitScaler extends TextScaler {
  final TextScaler basis;
  final double faktor;

  const _FitScaler(this.basis, this.faktor);

  @override
  double scale(double fontSize) => basis.scale(fontSize) * faktor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => basis.textScaleFactor * faktor;

  @override
  bool operator ==(Object other) =>
      other is _FitScaler && other.basis == basis && other.faktor == faktor;

  @override
  int get hashCode => Object.hash(basis, faktor);
}
