// Erzeugt notes/REVIEW_TEXTE.md aus questionnaire_v1.json.
//
// Warum erzeugt statt von Hand gepflegt: Die Liste soll vollstaendig sein und
// vollstaendig bleiben. Eine handgeschriebene Liste ist ab der ersten Aenderung
// an der Definition unvollstaendig, ohne dass es jemandem auffaellt — und
// gerade bei den rechtlichen Platzhaltern ist „faellt niemandem auf" der
// Schaden, um den es geht.
//
// Aufruf:
//
//   dart run tools/review_texte.dart
//   dart run tools/review_texte.dart --pruefen   meldet Abweichungen, aendert nichts
//
// Der Probelauf ist fuer die CI: Er endet mit Code 1, wenn jemand die
// Definition geaendert und die Liste nicht neu erzeugt hat.

import 'dart:convert';
import 'dart:io';

const _quelle = 'karriko_flutter/assets/questionnaire/questionnaire_v1.json';
const _ziel = 'notes/REVIEW_TEXTE.md';

const _vorwort = r'''
# Texte zur Durchsicht

**Erzeugt aus [`questionnaire_v1.json`](../karriko_flutter/assets/questionnaire/questionnaire_v1.json) mit `dart run tools/review_texte.dart`. Nicht von Hand ändern.**

Hier steht alles, was ich in der Fragendefinition geschrieben habe, ohne dass
es wörtlich in [`karriko-fragebogen.md`](karriko-fragebogen.md) stand. Drei
Sorten, und sie brauchen unterschiedliche Aufmerksamkeit:

| Sorte | Was zu tun ist |
|---|---|
| **Rechtliche Platzhalter** | Müssen vor dem ersten Echtbetrieb durch geprüften Text ersetzt werden. Ich habe hier nichts erfunden — es steht wörtlich `PLATZHALTER` da, damit niemand sie versehentlich für fertig hält. |
| **Ergänzte Inhalte** | Die Spezifikation nennt an diesen Stellen nur Beispiele oder gar nichts: Modulfragen, Antwortstufen, Schwellenwerte, Anlaufstellen, Berufsliste. Ich habe sinnvoll ergänzt. Alles davon ist eine Behauptung, die du prüfen solltest. |
| **Vergangenheitsformen** | Die Spezifikation formuliert überwiegend im Präsens für aktuelle Azubis. Jede `past`-Variante ist von mir. Die meisten sind mechanisch, ein paar nicht. |

Was **nicht** hier steht, ist wörtlich aus der Spezifikation übernommen und
wurde nicht angefasst.
''';

void main(List<String> args) {
  final nurPruefen = args.contains('--pruefen');

  final quelle = File(_quelle);
  if (!quelle.existsSync()) {
    stderr.writeln(
      'Nicht gefunden: $_quelle\n'
      'Das Skript laeuft im Wurzelverzeichnis des Repositories.',
    );
    exit(1);
  }

  final json = jsonDecode(quelle.readAsStringSync()) as Map<String, Object?>;
  final markdown = _erzeugen(json);

  final ziel = File(_ziel);
  final gleich = ziel.existsSync() && ziel.readAsStringSync() == markdown;

  if (gleich) {
    print('· $_ziel unveraendert');
    return;
  }

  if (nurPruefen) {
    stderr.writeln(
      '✗ $_ziel ist nicht auf dem Stand der Definition.\n'
      'Mit `dart run tools/review_texte.dart` neu erzeugen.',
    );
    exit(1);
  }

  ziel.parent.createSync(recursive: true);
  ziel.writeAsStringSync(markdown);
  print('+ $_ziel geschrieben');
}

String _erzeugen(Map<String, Object?> json) {
  final fragen = (json['questions']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final module = ((json['modules'] ?? <Object?>[]) as List<Object?>)
      .cast<Map<String, Object?>>();
  final texte = (json['texts'] ?? <String, Object?>{}) as Map<String, Object?>;

  final b = StringBuffer()
    ..writeln(_vorwort.trim())
    ..writeln()
    ..writeln('---')
    ..writeln();

  _platzhalter(b, texte);
  _moduleMitReview(b, module);
  _fragenMitReview(b, fragen);
  _optionenMitReview(b, fragen);
  _vergangenheitsformen(b, fragen, module);

  b
    ..writeln('---')
    ..writeln()
    ..writeln(
      '*Erzeugt am '
      '${DateTime.now().toUtc().toIso8601String().substring(0, 10)} aus '
      'Version ${json['version']} der Definition.*',
    );

  return b.toString();
}

// ── Abschnitte ───────────────────────────────────────────────────────────────

void _platzhalter(StringBuffer b, Map<String, Object?> texte) {
  final treffer = <String, String>{};

  texte.forEach((key, wert) {
    for (final text in _texteSammeln(wert)) {
      if (text.startsWith('PLATZHALTER')) {
        treffer['$key${treffer.containsKey(key) ? ' (weitere)' : ''}'] = text;
      }
    }
  });

  b
    ..writeln('## 1. Rechtliche Platzhalter')
    ..writeln()
    ..writeln(
      '**${treffer.length} Stück.** Diese Texte muss jemand schreiben, '
      'der dafür einstehen kann. Bis dahin erscheinen sie so, wie sie hier '
      'stehen — sichtbar unfertig ist besser als unsichtbar falsch.',
    )
    ..writeln();

  if (treffer.isEmpty) {
    b
      ..writeln('Keine. (Das wäre überraschend — prüf nach.)')
      ..writeln();
    return;
  }

  treffer.forEach((key, text) {
    b
      ..writeln('### `$key`')
      ..writeln()
      ..writeln('> $text')
      ..writeln();
  });
}

void _moduleMitReview(StringBuffer b, List<Map<String, Object?>> module) {
  final treffer = module.where((m) => m['review'] == true).toList();

  b
    ..writeln('## 2. Module, deren Zuschnitt ich ergänzt habe')
    ..writeln()
    ..writeln(
      '**${treffer.length} von ${module.length} Modulen.** Abschnitt 5 '
      'der Spezifikation nennt je Modul ein bis drei Beispielfragen. Welche '
      'Fragen ein Modul tatsächlich stellt, wie lange es dauert und wann es '
      'ausgelöst wird, steht dort nicht durchgehend.',
    )
    ..writeln();

  if (treffer.isEmpty) {
    b.writeln('Keine.\n');
    return;
  }

  b
    ..writeln('| Modul | Fragen | Teaser |')
    ..writeln('|---|---|---|');
  for (final m in treffer) {
    final fragen = (m['questions']! as List<Object?>).length;
    b.writeln(
      '| `${m['id']}` — ${_text(m['label'])} | $fragen | '
      '${_zelle(_text(m['teaser']))} |',
    );
  }
  b.writeln();
}

void _fragenMitReview(StringBuffer b, List<Map<String, Object?>> fragen) {
  final treffer = fragen.where((q) => q['review'] == true).toList();

  b
    ..writeln('## 3. Fragen, die ich ergänzt oder zugeschnitten habe')
    ..writeln()
    ..writeln(
      '**${treffer.length} von ${fragen.length} Fragen.** Entweder '
      'steht die Frage so nicht in der Spezifikation, oder ihr Format, ihre '
      'Bedingung oder ihre Grenzwerte sind von mir.',
    )
    ..writeln();

  if (treffer.isEmpty) {
    b.writeln('Keine.\n');
    return;
  }

  b
    ..writeln('| Kennung | Spec | Text |')
    ..writeln('|---|---|---|');
  for (final q in treffer) {
    b.writeln(
      '| `${q['id']}` | ${q['specRef'] ?? '—'} | '
      '${_zelle(_text(q['text']))} |',
    );
  }
  b.writeln();
}

void _optionenMitReview(StringBuffer b, List<Map<String, Object?>> fragen) {
  final zeilen = <String>[];
  var gesamt = 0;

  for (final q in fragen) {
    final optionen = ((q['options'] ?? <Object?>[]) as List<Object?>)
        .cast<Map<String, Object?>>();
    gesamt += optionen.length;
    for (final o in optionen) {
      if (o['review'] != true) continue;
      final score = o['score'];
      zeilen.add(
        '| `${q['id']}` | `${o['id']}` | ${_zelle(_text(o['label']))} '
        '| ${score == null ? '—' : score.toString().replaceAll('.', ',')} |',
      );
    }
    // Karten einer Wischfrage sind Optionen in allem ausser dem Namen.
    final config = (q['config'] ?? <String, Object?>{}) as Map<String, Object?>;
    final karten = ((config['cards'] ?? <Object?>[]) as List<Object?>)
        .cast<Map<String, Object?>>();
    gesamt += karten.length;
    for (final k in karten) {
      if (k['review'] != true) continue;
      zeilen.add(
        '| `${q['id']}` | `${k['id']}` (Karte) | '
        '${_zelle(_text(k['label']))} | — |',
      );
    }
  }

  b
    ..writeln('## 4. Antwortoptionen, die ich ergänzt habe')
    ..writeln()
    ..writeln(
      '**${zeilen.length} von $gesamt Optionen.** Die Spezifikation '
      'gibt bei den Kernfragen alle fünf Stufen wörtlich vor; bei den '
      'Modulfragen nennt sie meist nur die beiden Enden oder gar nichts. '
      'Die Punktwerte in der letzten Spalte bestimmen, wie stark eine '
      'Antwort den zugehörigen Subscore bewegt.',
    )
    ..writeln();

  if (zeilen.isEmpty) {
    b.writeln('Keine.\n');
    return;
  }

  b
    ..writeln('| Frage | Option | Beschriftung | Punkte |')
    ..writeln('|---|---|---|---|');
  for (final zeile in zeilen) {
    b.writeln(zeile);
  }
  b.writeln();
}

void _vergangenheitsformen(
  StringBuffer b,
  List<Map<String, Object?>> fragen,
  List<Map<String, Object?>> module,
) {
  final zeilen = <String>[];
  final identisch = <String>[];

  void pruefen(String wo, Object? text) {
    if (text is! Map) return;
    final current = text['current'];
    final past = text['past'];
    if (current is! String || past is! String) return;
    if (current == past) {
      identisch.add(wo);
      return;
    }
    zeilen.add('| `$wo` | ${_zelle(current)} | ${_zelle(past)} |');
  }

  for (final m in module) {
    pruefen('modul:${m['id']}.label', m['label']);
    pruefen('modul:${m['id']}.teaser', m['teaser']);
  }

  for (final q in fragen) {
    final id = q['id'];
    pruefen('$id.text', q['text']);
    pruefen('$id.intro', q['intro']);
    pruefen('$id.placeholder', q['placeholder']);

    for (final o
        in ((q['options'] ?? <Object?>[]) as List<Object?>)
            .cast<Map<String, Object?>>()) {
      pruefen('$id.${o['id']}', o['label']);
    }
    final config = (q['config'] ?? <String, Object?>{}) as Map<String, Object?>;
    for (final k
        in ((config['cards'] ?? <Object?>[]) as List<Object?>)
            .cast<Map<String, Object?>>()) {
      pruefen('$id.${k['id']}', k['label']);
    }
    for (final f
        in ((config['fields'] ?? <Object?>[]) as List<Object?>)
            .cast<Map<String, Object?>>()) {
      pruefen('$id.${f['id']}', f['label']);
    }
    for (final s
        in ((config['special'] ?? <Object?>[]) as List<Object?>)
            .whereType<Map<String, Object?>>()) {
      pruefen('$id.${s['id']}', s['label']);
    }
  }

  b
    ..writeln('## 5. Vergangenheitsformen')
    ..writeln()
    ..writeln(
      '**${zeilen.length} Texte, bei denen sich die Zeitform '
      'unterscheidet.** Weitere ${identisch.length} Texte tragen in beiden '
      'Zeitformen denselben Wortlaut — dort gibt es nichts umzuformen, etwa '
      'bei „Probezeit" oder „weiß ich nicht".',
    )
    ..writeln()
    ..writeln(
      'Die Zeitform folgt allein aus S1: Wer noch in der Ausbildung '
      'ist, liest die linke Spalte, alle anderen die rechte.',
    )
    ..writeln()
    ..writeln(
      '| Stelle | Präsens (wörtlich aus der Spezifikation) | Vergangenheit (von mir) |',
    )
    ..writeln('|---|---|---|');
  for (final zeile in zeilen) {
    b.writeln(zeile);
  }
  b.writeln();
}

// ── Hilfen ───────────────────────────────────────────────────────────────────

String _text(Object? wert) {
  if (wert is String) return wert;
  if (wert is Map && wert['current'] is String)
    return wert['current']! as String;
  return '—';
}

List<String> _texteSammeln(Object? wert) {
  if (wert is String) return [wert];
  if (wert is Map && wert['current'] is String) {
    return [wert['current']! as String];
  }
  if (wert is List) {
    return [for (final eintrag in wert) ..._texteSammeln(eintrag)];
  }
  return const [];
}

/// Macht einen Text tabellentauglich: Ein senkrechter Strich im Text wuerde
/// sonst die Spalte sprengen.
String _zelle(String text) => text.replaceAll('|', r'\|').replaceAll('\n', ' ');
