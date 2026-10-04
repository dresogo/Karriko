import 'package:flutter/material.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

import '../../../core/theme/app_theme.dart';
import '../question_context.dart';

/// Eine senkrechte Liste ausformulierter Antworten.
///
/// Die Reihenfolge ist die der Definition und wird **nie** gemischt: Die
/// Optionen sind ordinal, sie laufen von der besten zur schlechtesten Antwort.
/// Eine zufällige Reihenfolge machte aus einer Skala eine Ratesituation.
///
/// Verbale Anker statt Zahlen, weil „meistens" für alle dasselbe heißt und
/// eine 4 auf einer Fünferskala nicht.
class VerbalChoice extends StatelessWidget {
  final QuestionContext context;

  /// Bei Kacheln steht der Text in einem größeren Kasten. Sonst identisch.
  final bool alsKacheln;

  const VerbalChoice({
    super.key,
    required this.context,
    this.alsKacheln = false,
  });

  @override
  Widget build(BuildContext buildContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in context.question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: AppLayout.s8),
            child: OptionTile(
              label: context.label(option),
              selected: deepEquals(context.answer, option.storedValue),
              gross: alsKacheln,
              onTap: () {
                context.onChanged(option.storedValue);
                context.onAdvance();
              },
            ),
          ),
      ],
    );
  }
}

/// Segmentierte Auswahl für kurze, gleich lange Optionen — S4.
class SegmentedChoice extends StatelessWidget {
  final QuestionContext context;

  const SegmentedChoice({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    return Wrap(
      spacing: AppLayout.s8,
      runSpacing: AppLayout.s8,
      children: [
        for (final option in context.question.options)
          OptionChip(
            label: context.label(option),
            selected: deepEquals(context.answer, option.storedValue),
            onTap: () {
              context.onChanged(option.storedValue);
              context.onAdvance();
            },
          ),
      ],
    );
  }
}

/// Mehrfachauswahl.
///
/// Kein automatisches Weiterblättern: Wer mehrere Haken setzen darf, ist nach
/// dem ersten nicht fertig.
class MultiSelect extends StatelessWidget {
  final QuestionContext context;

  const MultiSelect({super.key, required this.context});

  List<Object?> get _gewaehlt {
    final antwort = context.answer;
    return antwort is List ? antwort : const [];
  }

  void _umschalten(Option option) {
    final wert = option.storedValue;
    final gewaehlt = [..._gewaehlt];
    final index = gewaehlt.indexWhere((e) => deepEquals(e, wert));
    if (index >= 0) {
      gewaehlt.removeAt(index);
    } else {
      gewaehlt.add(wert);
    }
    context.onChanged(gewaehlt.isEmpty ? null : gewaehlt);
  }

  @override
  Widget build(BuildContext buildContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in context.question.options)
          CheckboxListTile(
            value: _gewaehlt.any((e) => deepEquals(e, option.storedValue)),
            onChanged: (_) => _umschalten(option),
            title: Text(context.label(option)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

/// Die Tagesform aus A3. Fünf Stufen, sonst wie eine gewöhnliche Auswahl.
///
/// Der Wert wird nie veröffentlicht: Er ist eine Kovariate in der Auswertung
/// und der Auslöser für das Angebot, in drei Tagen noch einmal draufzuschauen.
class MoodChoice extends StatelessWidget {
  final QuestionContext context;

  const MoodChoice({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    return Wrap(
      spacing: AppLayout.s8,
      runSpacing: AppLayout.s8,
      children: [
        for (final option in context.question.options)
          OptionChip(
            label: context.label(option),
            selected: deepEquals(context.answer, option.storedValue),
            onTap: () {
              context.onChanged(option.storedValue);
              context.onAdvance();
            },
          ),
      ],
    );
  }
}

/// Die ruhige Rückfrage aus A2.
///
/// Sie ersetzt den Aufmerksamkeitstest, den erwachsene Nutzer zu Recht als
/// Gängelung empfinden. Hier wird nicht geprüft, ob jemand aufgepasst hat,
/// sondern gefragt, was er meint — und die Antwort zählt.
class ConsistencyCheck extends StatelessWidget {
  final QuestionContext context;

  const ConsistencyCheck({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) =>
      VerbalChoice(context: context, alsKacheln: true);
}

/// Die Wahl, wann veröffentlicht wird — Kleinbetrieb und Tagesform.
///
/// Beide Wege bleiben offen. Niemand wird gesperrt, niemand wird bevormundet;
/// der Hinweis steht da, und die Entscheidung liegt beim Azubi.
class PublishOptions extends StatelessWidget {
  final QuestionContext context;

  const PublishOptions({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) =>
      VerbalChoice(context: context, alsKacheln: true);
}

/// Ein Tor: zwei Wege, keiner davon vorbelegt.
///
/// Wird gebraucht, wo eine Strecke nicht unangekündigt beginnen darf.
class GateChoice extends StatelessWidget {
  final QuestionContext context;

  const GateChoice({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    return Wrap(
      spacing: AppLayout.s16,
      runSpacing: AppLayout.s8,
      children: [
        for (final option in context.question.options)
          ElevatedButton(
            onPressed: () {
              context.onChanged(option.storedValue);
              context.onAdvance();
            },
            child: Text(context.label(option)),
          ),
      ],
    );
  }
}

// ── Bausteine ────────────────────────────────────────────────────────────────

/// Eine Antwortzeile.
///
/// [InkWell] statt [GestureDetector]: Das bringt Fokusrahmen, Tastaturbedienung
/// über Leertaste und Eingabetaste und die Ankündigung als Schaltfläche
/// mit — alles, was ein reiner Gestenerkenner verschluckt.
class OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool gross;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.gross = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.s16,
            vertical: gross ? 20 : 14,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.paper : AppColors.ink,
                    fontSize: gross ? 17 : 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: AppColors.paper, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const OptionChip({
    super.key,
    required this.label,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.surface,
            border:
                Border.all(color: selected ? AppColors.ink : AppColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.paper : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
