import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:questionnaire_core/questionnaire_core.dart';

import '../../../core/theme/app_theme.dart';
import '../question_context.dart';

/// Mehrere Textfelder unter einer Frage — die beiden Freitexte aus A1 und die
/// eine Frage am Ende des Abbruchmoduls.
///
/// Zwei Felder statt eines sind bei A1 Absicht: Sie erzwingen den Blick auf
/// beide Seiten. Wer nur ein Feld hat, füllt es mit dem, was gerade obenauf
/// liegt — und das ist nach einer schlechten Erfahrung selten das Gute.
///
/// Der Hinweis unter den Feldern ist die rechtlich entscheidende Stelle:
/// Werturteile sind von der Meinungsfreiheit gedeckt, unwahre
/// Tatsachenbehauptungen nicht. Der Unterschied liegt in der Formulierung, und
/// genau dort setzt der Platzhalter im Feld an.
class TextPair extends StatefulWidget {
  final QuestionContext context;

  const TextPair({super.key, required this.context});

  @override
  State<TextPair> createState() => _TextPairState();
}

class _TextPairState extends State<TextPair> {
  final _controller = <String, TextEditingController>{};

  List<({String id, String label})> get _felder {
    final roh = widget.context.config<List<Object?>>('fields') ?? const [];
    return [
      for (final eintrag in roh)
        if (eintrag is Map && eintrag['id'] is String)
          (id: eintrag['id']! as String, label: _label(eintrag['label'])),
    ];
  }

  String _label(Object? roh) {
    if (roh is String) return roh;
    if (roh is Map) {
      final past = widget.context.tense == Tense.past ? roh['past'] : null;
      final text = past ?? roh['current'];
      if (text is String) return text;
    }
    return '';
  }

  Map<String, Object?> get _werte {
    final antwort = widget.context.answer;
    if (antwort is Map) {
      return antwort.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  TextEditingController _ctrl(String id) => _controller.putIfAbsent(
        id,
        () => TextEditingController(text: _werte[id] as String? ?? ''),
      );

  void _aendern(String id, String text) {
    final werte = {..._werte, id: text};
    // Leere Felder fliegen raus, damit eine Frage, die nur aus Leerzeichen
    // besteht, nicht als beantwortet gilt.
    werte.removeWhere((_, wert) => wert is String && wert.trim().isEmpty);
    widget.context.onChanged(werte.isEmpty ? null : werte);
  }

  @override
  void dispose() {
    for (final controller in _controller.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.context;
    final felder = _felder;
    final hinweisKey = ctx.config<String>('noticeKey');
    final hinweis = hinweisKey == null ? null : ctx.sharedText(hinweisKey);
    final maxLength = ctx.configNum('maxLength')?.round();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Auf Mobil untereinander, sonst nebeneinander — beide Felder sollen
        // gleichzeitig sichtbar sein, sonst ist der Zweck dahin.
        final nebeneinander = constraints.maxWidth >= 720 && felder.length > 1;

        final eingaben = [
          for (final feld in felder)
            Expanded(
              flex: nebeneinander ? 1 : 0,
              child: Padding(
                padding: EdgeInsets.only(
                  right:
                      nebeneinander && feld != felder.last ? AppLayout.s16 : 0,
                  bottom: nebeneinander ? 0 : AppLayout.s16,
                ),
                child: TextField(
                  controller: _ctrl(feld.id),
                  onChanged: (text) => _aendern(feld.id, text),
                  maxLines: 6,
                  minLines: 4,
                  maxLength: maxLength,
                  decoration: InputDecoration(
                    labelText: feld.label,
                    hintText: ctx.placeholder,
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (nebeneinander)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: eingaben,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final eingabe in eingaben) eingabe.child,
                ],
              ),
            if (hinweis != null) ...[
              const SizedBox(height: AppLayout.s8),
              Text(
                hinweis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Auswahl aus einem Zahlenbereich — die Jahresangaben aus S2.
class YearDropdown extends StatelessWidget {
  final QuestionContext context;

  const YearDropdown({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    // Mit Optionen verhält sich der Typ wie eine gewöhnliche Auswahl; ohne
    // spannt er den Bereich aus `config` auf.
    if (context.question.options.isNotEmpty) {
      return DropdownButtonFormField<Object?>(
        initialValue: context.answer,
        items: [
          for (final option in context.question.options)
            DropdownMenuItem(
              value: option.storedValue,
              child: Text(context.label(option)),
            ),
        ],
        onChanged: context.onChanged,
      );
    }

    final min = (context.configNum('min') ?? 2000).round();
    final max = (context.configNum('max') ?? DateTime.now().year).round();

    return DropdownButtonFormField<int>(
      initialValue:
          context.answer is num ? (context.answer! as num).round() : null,
      items: [
        // Absteigend: Das jüngste Jahr steht oben, und das ist in fast allen
        // Fällen das gesuchte.
        for (var jahr = max; jahr >= min; jahr--)
          DropdownMenuItem(value: jahr, child: Text('$jahr')),
      ],
      onChanged: (wert) {
        context.onChanged(wert);
        context.onAdvance();
      },
    );
  }
}

/// Suchfeld mit Vorschlägen — die Berufswahl aus S3.
///
/// Die Liste kommt aus einem Asset, dessen Pfad in der Definition steht. Der
/// letzte Eintrag der Liste ist ein Auffangeintrag für Berufe, die nicht
/// darin vorkommen; ohne ihn bliebe jemand an S3 hängen, dessen Beruf die
/// Liste nicht kennt.
class SearchSelect extends StatefulWidget {
  final QuestionContext context;

  const SearchSelect({super.key, required this.context});

  @override
  State<SearchSelect> createState() => _SearchSelectState();
}

class _SearchSelectState extends State<SearchSelect> {
  final _suche = TextEditingController();
  List<({String code, String name})> _eintraege = const [];
  bool _laedt = true;

  @override
  void initState() {
    super.initState();
    _suche.text = widget.context.answer as String? ?? '';
    _laden();
  }

  Future<void> _laden() async {
    final pfad = widget.context.config<String>('asset');
    if (pfad == null) {
      setState(() => _laedt = false);
      return;
    }
    try {
      final roh = jsonDecode(await rootBundle.loadString(pfad));
      final liste = roh is Map ? roh['berufe'] : roh;
      setState(() {
        _eintraege = [
          for (final eintrag in liste is List ? liste : const [])
            if (eintrag is Map && eintrag['name'] is String)
              (
                code: eintrag['code'] as String? ?? '',
                name: eintrag['name']! as String,
              ),
        ];
        _laedt = false;
      });
    } catch (_) {
      // Ohne Liste bleibt das freie Textfeld. Das ist schlechter als eine
      // Auswahl, aber besser als eine Frage, die sich nicht beantworten lässt.
      setState(() => _laedt = false);
    }
  }

  @override
  void dispose() {
    _suche.dispose();
    super.dispose();
  }

  List<({String code, String name})> get _treffer {
    final suche = _suche.text.trim().toLowerCase();
    if (suche.length < 2) return const [];
    return [
      for (final eintrag in _eintraege)
        if (eintrag.name.toLowerCase().contains(suche)) eintrag,
    ].take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.context;
    final gewaehlt = ctx.answer as String?;
    final treffer = _treffer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _suche,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: ctx.sharedText('ui.search_hint'),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        if (_laedt)
          const Padding(
            padding: EdgeInsets.only(top: AppLayout.s16),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: AppLayout.s8),
        for (final eintrag in treffer)
          ListTile(
            title: Text(eintrag.name),
            selected: gewaehlt == eintrag.name,
            contentPadding: EdgeInsets.zero,
            onTap: () {
              _suche.text = eintrag.name;
              ctx.onChanged(eintrag.name);
              setState(() {});
            },
          ),
        if (!_laedt && _suche.text.trim().length >= 2 && treffer.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppLayout.s8),
            child: Text(
              ctx.sharedText('ui.search_empty') ?? '',
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ),
      ],
    );
  }
}
