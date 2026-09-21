import 'package:flutter/material.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

import '../../../core/theme/app_theme.dart';
import '../question_context.dart';
import 'choice_widgets.dart';

/// Elf Kacheln von 0 bis 10 — die Weiterempfehlung K5.
///
/// Kacheln statt Regler: Der Standard für Weiterempfehlungsfragen, über
/// Plattformen hinweg vergleichbar, und ohne Wischen zu bedienen. Auf schmalen
/// Bildschirmen wird umgebrochen statt waagerecht gescrollt — eine Skala, von
/// der man nur die Hälfte sieht, ist keine Skala.
class Scale0To10 extends StatelessWidget {
  final QuestionContext context;

  const Scale0To10({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    final min = (context.configNum('min') ?? 0).round();
    final max = (context.configNum('max') ?? 10).round();
    final endLabels = context.config<Map<String, Object?>>('endLabels') ?? const {};
    final gewaehlt = context.answer is num ? (context.answer! as num).round() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppLayout.s8,
          runSpacing: AppLayout.s8,
          children: [
            for (var wert = min; wert <= max; wert++)
              _Kachel(
                wert: wert,
                selected: gewaehlt == wert,
                onTap: () {
                  context.onChanged(wert);
                  context.onAdvance();
                },
              ),
          ],
        ),
        const SizedBox(height: AppLayout.s8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Ende(_text(endLabels['min'])),
            _Ende(_text(endLabels['max'])),
          ],
        ),
      ],
    );
  }

  String _text(Object? roh) {
    if (roh is String) return roh;
    if (roh is Map && roh['current'] is String) return roh['current']! as String;
    return '';
  }
}

class _Kachel extends StatelessWidget {
  final int wert;
  final bool selected;
  final VoidCallback onTap;

  const _Kachel({
    required this.wert,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.surface,
            border:
                Border.all(color: selected ? AppColors.ink : AppColors.line),
          ),
          child: Text(
            '$wert',
            style: TextStyle(
              color: selected ? AppColors.paper : AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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

/// Ein Zähler für Zahlen, die der Azubi wirklich weiß — Überstunden,
/// Gesprächshäufigkeit, Vergütung.
///
/// Schrittweite, Grenzen und die Sonderschaltflächen stehen in `config`. Die
/// Beschriftung der Sonderfelder kommt aus der Definition; „ich mache keine
/// Überstunden" trägt dort den Wert 0 und ist damit dieselbe Aussage wie eine
/// Null im Zähler — die Folgefrage K3.1 bleibt in beiden Fällen gleich aus.
class StepperInput extends StatelessWidget {
  final QuestionContext context;

  const StepperInput({super.key, required this.context});

  num get _min => context.configNum('min') ?? 0;
  num get _max => context.configNum('max') ?? 100;
  num get _step => context.configNum('step') ?? 1;

  num? get _zahl => context.answer is num ? context.answer! as num : null;

  List<({Object? wert, String label})> get _sonder {
    final roh = context.config<List<Object?>>('special') ?? const [];
    return [
      for (final eintrag in roh)
        if (eintrag is Map)
          (
            wert: eintrag.containsKey('value') ? eintrag['value'] : eintrag['id'],
            label: _label(eintrag['label']),
          ),
    ];
  }

  String _label(Object? roh) {
    if (roh is String) return roh;
    if (roh is Map) {
      final past = context.tense == Tense.past ? roh['past'] : null;
      final text = past ?? roh['current'];
      if (text is String) return text;
    }
    return '';
  }

  void _aendern(num delta) {
    final basis = _zahl ?? _min;
    context.onChanged((basis + delta).clamp(_min, _max));
  }

  @override
  Widget build(BuildContext buildContext) {
    final zahl = _zahl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.outlined(
              onPressed: zahl == null || zahl <= _min ? null : () => _aendern(-_step),
              icon: const Icon(Icons.remove),
              tooltip: '−$_step',
            ),
            const SizedBox(width: AppLayout.s16),
            Container(
              constraints: const BoxConstraints(minWidth: 96),
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.s16,
                vertical: 12,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
              child: Text(
                zahl == null
                    ? '–'
                    : (zahl is int ? '$zahl' : zahl.toStringAsFixed(0)),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppLayout.s16),
            IconButton.outlined(
              onPressed: zahl != null && zahl >= _max ? null : () => _aendern(_step),
              icon: const Icon(Icons.add),
              tooltip: '+$_step',
            ),
          ],
        ),
        if (_sonder.isNotEmpty) ...[
          const SizedBox(height: AppLayout.s24),
          Wrap(
            spacing: AppLayout.s8,
            runSpacing: AppLayout.s8,
            children: [
              for (final eintrag in _sonder)
                OptionChip(
                  label: eintrag.label,
                  selected: deepEquals(context.answer, eintrag.wert),
                  onTap: () => context.onChanged(eintrag.wert),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
