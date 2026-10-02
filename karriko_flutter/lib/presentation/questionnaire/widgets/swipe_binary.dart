import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../question_context.dart';

/// Wischkarten — S8, K1 und der Jugendarbeitsschutz.
///
/// Nur für Fakten mit Ja/Nein, nie für Bewertungen: Die Wischgeste verführt
/// zum schnellen Durchziehen, und was man durchzieht, hat man nicht abgewogen.
///
/// Gewischt wird nach links und rechts — **und** es gibt drei jederzeit
/// sichtbare Schaltflächen. Nicht als Notlösung: Ohne sie ist die Frage mit
/// Maus, Tastatur oder Screenreader nicht zu beantworten, und das wäre keine
/// Geste weniger, sondern eine Gruppe von Nutzern weniger.
class SwipeBinary extends StatefulWidget {
  final QuestionContext context;

  const SwipeBinary({super.key, required this.context});

  @override
  State<SwipeBinary> createState() => _SwipeBinaryState();
}

class _SwipeBinaryState extends State<SwipeBinary> {
  /// Reihenfolge der beantworteten Karten, damit „Zurücknehmen" weiß, welche
  /// die letzte war.
  final _reihenfolge = <String>[];

  List<({String id, String label})> get _karten {
    final roh = widget.context.config<List<Object?>>('cards') ?? const [];
    return [
      for (final eintrag in roh)
        if (eintrag is Map && eintrag['id'] is String)
          (
            id: eintrag['id']! as String,
            label: _label(eintrag['label']),
          ),
    ];
  }

  String _label(Object? roh) {
    if (roh is String) return roh;
    if (roh is Map) {
      final variante = widget.context.tense.name == 'past' ? roh['past'] : null;
      final text = variante ?? roh['current'];
      if (text is String) return text;
    }
    return '';
  }

  Map<String, Object?> get _antworten {
    final antwort = widget.context.answer;
    if (antwort is Map) {
      return antwort.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  Object get _ja => widget.context.question.config['yesValue'] ?? 'ja';
  Object get _nein => widget.context.question.config['noValue'] ?? 'nein';

  Object? get _weissNicht {
    final andere = widget.context.config<List<Object?>>('otherValues');
    return andere == null || andere.isEmpty ? null : andere.first;
  }

  ({String id, String label})? get _aktuelle {
    for (final karte in _karten) {
      if (!_antworten.containsKey(karte.id)) return karte;
    }
    return null;
  }

  void _beantworten(String kartenId, Object? wert) {
    setState(() {
      _reihenfolge
        ..remove(kartenId)
        ..add(kartenId);
    });
    widget.context.onChanged({..._antworten, kartenId: wert});
  }

  void _zuruecknehmen() {
    if (_reihenfolge.isEmpty) return;
    final letzte = _reihenfolge.removeLast();
    final neu = {..._antworten}..remove(letzte);
    setState(() {});
    widget.context.onChanged(neu.isEmpty ? null : neu);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.context;
    final karten = _karten;
    final aktuell = _aktuelle;
    final beantwortet = _antworten.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$beantwortet / ${karten.length}',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.96,
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        if (aktuell == null)
          _Fertig(text: ctx.sharedText('ui.draft_saved') ?? '')
        else
          Dismissible(
            key: ValueKey(aktuell.id),
            // Links weg, rechts trifft zu — so steht es in der Spezifikation.
            onDismissed: (richtung) => _beantworten(
              aktuell.id,
              richtung == DismissDirection.startToEnd ? _ja : _nein,
            ),
            background: _Wischgrund(
              ausrichtung: Alignment.centerLeft,
              text: ctx.sharedText('ui.yes') ?? '',
              farbe: AppColors.green,
            ),
            secondaryBackground: _Wischgrund(
              ausrichtung: Alignment.centerRight,
              text: ctx.sharedText('ui.no') ?? '',
              farbe: AppColors.accent,
            ),
            child: _Karte(text: aktuell.label),
          ),
        const SizedBox(height: AppLayout.s24),
        if (aktuell != null)
          Wrap(
            spacing: AppLayout.s8,
            runSpacing: AppLayout.s8,
            children: [
              _Knopf(
                label: ctx.sharedText('ui.yes') ?? '',
                onPressed: () => _beantworten(aktuell.id, _ja),
              ),
              _Knopf(
                label: ctx.sharedText('ui.no') ?? '',
                onPressed: () => _beantworten(aktuell.id, _nein),
              ),
              if (_weissNicht != null)
                _Knopf(
                  label: ctx.sharedText('ui.unknown') ?? '',
                  onPressed: () => _beantworten(aktuell.id, _weissNicht),
                ),
            ],
          ),
        if (_reihenfolge.isNotEmpty) ...[
          const SizedBox(height: AppLayout.s16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _zuruecknehmen,
              icon: const Icon(Icons.undo, size: 16),
              label: Text(ctx.sharedText('ui.undo') ?? ''),
            ),
          ),
        ],
      ],
    );
  }
}

class _Karte extends StatelessWidget {
  final String text;

  const _Karte({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      alignment: Alignment.centerLeft,
      child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _Wischgrund extends StatelessWidget {
  final Alignment ausrichtung;
  final String text;
  final Color farbe;

  const _Wischgrund({
    required this.ausrichtung,
    required this.text,
    required this.farbe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: farbe,
      alignment: ausrichtung,
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.s24),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.paper,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Fertig extends StatelessWidget {
  final String text;

  const _Fertig({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppColors.green),
          const SizedBox(width: AppLayout.s8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Knopf extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _Knopf({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) =>
      OutlinedButton(onPressed: onPressed, child: Text(label));
}
