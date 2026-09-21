import 'package:flutter/material.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

import '../../../core/theme/app_theme.dart';
import '../question_context.dart';

/// Die Prioritätenfrage K12: acht Karten, die drei wichtigsten nach oben.
///
/// Zwei Bedienwege, und der zweite ist keine Krücke:
///
/// * **Ziehen** mit Maus und Finger, über [ReorderableListView].
/// * **Antippen** in der gewünschten Reihenfolge. Drag and Drop ist mit
///   Tastatur und Screenreader nicht zu bedienen, und K12 steuert nicht nur
///   die Anzeige, sondern die Gewichte des Gesamtscores — wer hier aussteigt,
///   fällt nicht aus einer Spielerei, sondern aus der Bewertung.
class RankTopN extends StatelessWidget {
  final QuestionContext context;

  const RankTopN({super.key, required this.context});

  int get _topN => (context.configNum('topN') ?? 3).round();

  List<String> get _rang {
    final antwort = context.answer;
    if (antwort is List) {
      return [
        for (final eintrag in antwort)
          if (eintrag is String) eintrag,
      ];
    }
    return const [];
  }

  List<Option> get _uebrig => [
        for (final option in context.question.options)
          if (!_rang.contains(option.id)) option,
      ];

  void _antippen(String id) {
    final rang = [..._rang];
    if (rang.contains(id)) {
      rang.remove(id);
    } else if (rang.length < _topN) {
      rang.add(id);
    } else {
      // Voll: Die letzte weicht. Sonst müsste man erst abwählen, und das ist
      // ein Schritt, den niemand erwartet.
      rang
        ..removeLast()
        ..add(id);
    }
    context.onChanged(rang.isEmpty ? null : rang);
  }

  /// [ReorderableListView.onReorderItem] liefert den Zielindex bereits um den
  /// entnommenen Eintrag bereinigt — anders als das abgeloeste `onReorder`.
  void _umsortieren(int von, int nach) {
    final rang = [..._rang];
    rang.insert(nach, rang.removeAt(von));
    context.onChanged(rang);
  }

  Option? _optionFuer(String id) {
    for (final option in context.question.options) {
      if (option.id == id) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext buildContext) {
    final rang = _rang;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.sharedText('ui.rank_hint') ?? '',
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: AppLayout.s24),
        if (rang.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rang.length,
            onReorderItem: _umsortieren,
            itemBuilder: (context, index) {
              final option = _optionFuer(rang[index]);
              return _Gewaehlt(
                key: ValueKey(rang[index]),
                platz: index + 1,
                index: index,
                label: option == null ? rang[index] : this.context.label(option),
                onEntfernen: () => _antippen(rang[index]),
              );
            },
          ),
        if (rang.length < _topN) ...[
          const SizedBox(height: AppLayout.s16),
          for (final option in _uebrig)
            _Offen(
              label: context.label(option),
              onTap: () => _antippen(option.id),
            ),
        ],
        if (rang.isNotEmpty) ...[
          const SizedBox(height: AppLayout.s16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.onChanged(null),
              child: Text(context.sharedText('ui.rank_reset') ?? ''),
            ),
          ),
        ],
      ],
    );
  }
}

class _Gewaehlt extends StatelessWidget {
  final int platz;
  final int index;
  final String label;
  final VoidCallback onEntfernen;

  const _Gewaehlt({
    super.key,
    required this.platz,
    required this.index,
    required this.label,
    required this.onEntfernen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.s8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.s16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink,
        border: Border.all(color: AppColors.ink),
      ),
      child: Row(
        children: [
          Text(
            '$platz',
            style: const TextStyle(
              color: AppColors.paper,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: AppLayout.s16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.paper,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Der Griff ist zusätzlich, nicht stattdessen: Entfernen geht über
          // die Schaltfläche daneben, und die ist fokussierbar.
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.s8),
              child: Icon(Icons.drag_handle, color: AppColors.paper, size: 20),
            ),
          ),
          IconButton(
            onPressed: onEntfernen,
            icon: const Icon(Icons.close, color: AppColors.paper, size: 18),
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          ),
        ],
      ),
    );
  }
}

class _Offen extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Offen({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.s8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.s16,
            vertical: 14,
          ),
        ),
        child: SizedBox(width: double.infinity, child: Text(label)),
      ),
    );
  }
}
