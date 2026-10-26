import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Findet Zeilen, die mitten in einem Wort umbrechen (T-11.14).
///
/// Flutter trennt nicht nach Silben. Passt ein einzelnes Wort nicht in die
/// Zeile, bricht es an beliebiger Stelle um („Bewertunge / n“). Geprüft wird
/// jede sichtbare Textzeile: Steht vor ihrem ersten Zeichen ein Buchstabe
/// und ist das erste Zeichen selbst einer, ist das Wort geteilt.
List<String> midWordBreaks(WidgetTester tester) {
  final funde = <String>[];
  final letter = RegExp(r'[\p{L}\p{N}]', unicode: true);

  for (final element in find.byType(RichText).evaluate()) {
    final render = element.renderObject;
    if (render is! RenderParagraph || !render.hasSize) continue;
    final text = render.text.toPlainText(includeSemanticsLabels: false);
    if (text.length < 2) continue;

    final boxes = render.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    final zeilenAnfaenge = <double>{};
    for (final box in boxes) {
      if (!zeilenAnfaenge.add(box.top.roundToDouble())) continue;
      final pos = render
          .getPositionForOffset(Offset(box.left + 0.5, box.top + 1))
          .offset;
      if (pos <= 0 || pos >= text.length) continue;
      final davor = text[pos - 1];
      final danach = text[pos];
      if (letter.hasMatch(davor) && letter.hasMatch(danach)) {
        final start = text.lastIndexOf(RegExp(r'\s'), pos - 1) + 1;
        final endeRoh = text.indexOf(RegExp(r'\s'), pos);
        final ende = endeRoh < 0 ? text.length : endeRoh;
        final groesse = _schriftgroesse(render.text);
        funde.add('${text.substring(start, pos)} / ${text.substring(pos, ende)}'
            '${groesse == null ? '' : ' (${groesse.round()} px)'}');
      }
    }
  }
  return funde;
}

double? _schriftgroesse(InlineSpan span) {
  double? groesse = span.style?.fontSize;
  span.visitChildren((kind) {
    groesse ??= kind.style?.fontSize;
    return groesse == null;
  });
  return groesse;
}
