import '../model/json_reader.dart';

/// Was eine Bedingung zum Auswerten braucht.
///
/// Absichtlich nur Daten, keine Dienste: Die Auswertung ist eine reine
/// Funktion. Zweimal dieselbe Eingabe, zweimal dasselbe Ergebnis — sonst wäre
/// nicht zu erklären, warum Client und Server unterschiedliche Fragen zeigen.
class EvalContext {
  /// Antworten je Frage-ID.
  final Map<String, Object?> answers;

  /// Abgeleitete Werte, die keiner Frage entsprechen: `detail_overall`,
  /// `tense` und was sonst noch über `{"computed": "…"}` erreichbar sein soll.
  final Map<String, Object?> computed;

  const EvalContext({
    required this.answers,
    this.computed = const {},
  });
}

/// Ein Operand einer Bedingung: ein Antwortverweis, ein abgeleiteter Wert oder
/// ein Literal.
sealed class Operand {
  const Operand();

  Object? resolve(EvalContext context);

  /// Trägt die referenzierten Frage-IDs ein. Dient der Prüfung beim Laden.
  void collectAnswerIds(Set<String> out) {}

  static Operand parse(JsonNode node) {
    final value = node.value;
    if (value is Map) {
      final map = node.asMap;
      if (map.containsKey('answer')) {
        final extra =
            map.keys.where((key) => key != 'answer' && key != 'field');
        if (extra.isNotEmpty) {
          node.fail(
              'Ein Antwortverweis kennt nur "answer" und "field", gefunden '
              'zusätzlich: ${extra.join(', ')}.');
        }
        return AnswerOperand(
          node.require('answer').asString,
          field:
              node.child('field').exists ? node.child('field').asString : null,
        );
      }
      if (map.containsKey('computed')) {
        if (map.length != 1) {
          node.fail('Ein Verweis auf einen abgeleiteten Wert hat genau einen '
              'Schlüssel: "computed".');
        }
        return ComputedOperand(node.require('computed').asString);
      }
      node.fail(
          'Objekt als Operand erlaubt nur "answer" oder "computed", gefunden: '
          '${map.keys.join(', ')}.');
    }
    return LiteralOperand(value);
  }
}

class AnswerOperand extends Operand {
  final String questionId;

  /// Ein einzelnes Feld innerhalb der Antwort.
  ///
  /// Nötig für die Wischkarten: S8 und K1 liefern eine Zuordnung von Karte auf
  /// Ja/Nein/Weiß-ich-nicht, und das Arbeitszeitmodul hängt an genau einer
  /// davon („Schichtarbeit"). Ohne das hier müsste jede Karte eine eigene Frage
  /// sein — und aus einem Bildschirm würden sieben.
  final String? field;

  const AnswerOperand(this.questionId, {this.field});

  @override
  Object? resolve(EvalContext context) {
    final value = context.answers[questionId];
    if (field == null) return value;
    if (value is Map) return value[field];
    // Kein Objekt, also gibt es das Feld auch nicht. Kein Fehler: Die Frage
    // kann schlicht noch unbeantwortet sein.
    return null;
  }

  @override
  void collectAnswerIds(Set<String> out) => out.add(questionId);
}

class ComputedOperand extends Operand {
  final String key;

  const ComputedOperand(this.key);

  @override
  Object? resolve(EvalContext context) => context.computed[key];
}

class LiteralOperand extends Operand {
  final Object? literal;

  const LiteralOperand(this.literal);

  @override
  Object? resolve(EvalContext context) => literal;
}

/// Eine Bedingung aus der Definition.
///
/// Deklarativ und ohne Seiteneffekte. Was hier nicht ausdrückbar ist, gehört
/// nicht in die Definition, sondern in ein abgeleitetes `computed`.
sealed class Condition {
  const Condition();

  bool evaluate(EvalContext context);

  void collectAnswerIds(Set<String> out);

  /// Alle bekannten Operatoren. Steht hier, damit die Fehlermeldung beim
  /// Laden aufzählen kann, was es stattdessen gibt.
  static const operators = <String>{
    'all',
    'any',
    'not',
    'eq',
    'neq',
    'in',
    'gt',
    'gte',
    'lt',
    'lte',
    'answered',
    'selected',
    'ranked_top',
  };

  /// Liest eine Bedingung. `null` und ein leeres Objekt bedeuten „immer wahr".
  static Condition? parseOrNull(JsonNode node) {
    if (!node.exists) return null;
    final map = node.asMap;
    if (map.isEmpty) return null;
    return parse(node);
  }

  static Condition parse(JsonNode node) {
    final map = node.asMap;
    if (map.length != 1) {
      node.fail('Eine Bedingung hat genau einen Operator, gefunden: '
          '${map.isEmpty ? 'keinen' : map.keys.join(', ')}.');
    }
    final op = map.keys.first;
    final arg = node.require(op);

    if (!operators.contains(op)) {
      node.fail('Unbekannter Operator "$op". Bekannt sind: '
          '${(operators.toList()..sort()).join(', ')}.');
    }

    switch (op) {
      case 'all':
      case 'any':
        final parts = [for (final item in arg.items) parse(item)];
        if (parts.isEmpty) {
          arg.fail('"$op" braucht mindestens eine Bedingung.');
        }
        return op == 'all' ? AllCondition(parts) : AnyCondition(parts);

      case 'not':
        return NotCondition(parse(arg));

      case 'answered':
        return AnsweredCondition(Operand.parse(_single(arg)));

      case 'ranked_top':
        final parts = arg.asList;
        if (parts.length != 3) {
          arg.fail('"ranked_top" erwartet [Rangliste, Wert, Anzahl], gefunden '
              '${parts.length} Operanden.');
        }
        return RankedTopCondition(
          Operand.parse(arg.at(0)),
          Operand.parse(arg.at(1)),
          arg.at(2).asInt,
        );

      default:
        final parts = arg.asList;
        if (parts.length != 2) {
          arg.fail(
              '"$op" erwartet genau zwei Operanden, gefunden ${parts.length}.');
        }
        final left = Operand.parse(arg.at(0));
        final right = Operand.parse(arg.at(1));
        return BinaryCondition(op, left, right);
    }
  }

  /// `answered` darf einen nackten Operanden oder eine einelementige Liste
  /// bekommen — beides liest sich in JSON natürlich.
  static JsonNode _single(JsonNode node) {
    if (node.value is List) {
      final list = node.asList;
      if (list.length != 1) {
        node.fail('"answered" erwartet genau einen Operanden.');
      }
      return node.at(0);
    }
    return node;
  }
}

class AllCondition extends Condition {
  final List<Condition> parts;

  const AllCondition(this.parts);

  @override
  bool evaluate(EvalContext context) =>
      parts.every((part) => part.evaluate(context));

  @override
  void collectAnswerIds(Set<String> out) {
    for (final part in parts) {
      part.collectAnswerIds(out);
    }
  }
}

class AnyCondition extends Condition {
  final List<Condition> parts;

  const AnyCondition(this.parts);

  @override
  bool evaluate(EvalContext context) =>
      parts.any((part) => part.evaluate(context));

  @override
  void collectAnswerIds(Set<String> out) {
    for (final part in parts) {
      part.collectAnswerIds(out);
    }
  }
}

class NotCondition extends Condition {
  final Condition part;

  const NotCondition(this.part);

  @override
  bool evaluate(EvalContext context) => !part.evaluate(context);

  @override
  void collectAnswerIds(Set<String> out) => part.collectAnswerIds(out);
}

class AnsweredCondition extends Condition {
  final Operand operand;

  const AnsweredCondition(this.operand);

  @override
  bool evaluate(EvalContext context) => isAnswered(operand.resolve(context));

  @override
  void collectAnswerIds(Set<String> out) => operand.collectAnswerIds(out);

  /// Was als „beantwortet" zählt.
  ///
  /// `null` nicht, die leere Zeichenkette nicht, die leere Liste nicht. `0`
  /// dagegen schon — bei K3 ist „null Überstunden" eine Antwort und keine
  /// Lücke, und genau daran hängt die Folgefrage K3.1.
  static bool isAnswered(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}

class RankedTopCondition extends Condition {
  final Operand ranking;
  final Operand value;
  final int topN;

  const RankedTopCondition(this.ranking, this.value, this.topN);

  @override
  bool evaluate(EvalContext context) {
    final list = ranking.resolve(context);
    if (list is! Iterable) return false;
    final needle = value.resolve(context);
    final index = list.toList().indexOf(needle);
    return index >= 0 && index < topN;
  }

  @override
  void collectAnswerIds(Set<String> out) {
    ranking.collectAnswerIds(out);
    value.collectAnswerIds(out);
  }
}

class BinaryCondition extends Condition {
  final String op;
  final Operand left;
  final Operand right;

  const BinaryCondition(this.op, this.left, this.right);

  @override
  bool evaluate(EvalContext context) {
    final a = left.resolve(context);
    final b = right.resolve(context);

    switch (op) {
      case 'eq':
        return deepEquals(a, b);
      case 'neq':
        return !deepEquals(a, b);
      case 'in':
        if (b is Iterable) return b.any((item) => deepEquals(a, item));
        return false;
      case 'selected':
        if (a is Iterable) return a.any((item) => deepEquals(item, b));
        return false;
      default:
        return _compare(a, b);
    }
  }

  /// Zahlenvergleich.
  ///
  /// Ist eine Seite keine Zahl, ist das Ergebnis `false` — nicht etwa ein
  /// Fehler. Das ist gewollt: K3 kann „weiß ich nicht genau" sein, und
  /// `{"gt": [{"answer":"k3_ueberstunden"}, 0]}` soll dann schlicht nicht
  /// greifen, statt den Fragebogen anzuhalten.
  bool _compare(Object? a, Object? b) {
    final x = _asNum(a);
    final y = _asNum(b);
    if (x == null || y == null) return false;
    switch (op) {
      case 'gt':
        return x > y;
      case 'gte':
        return x >= y;
      case 'lt':
        return x < y;
      case 'lte':
        return x <= y;
    }
    return false;
  }

  static num? _asNum(Object? value) => value is num ? value : null;

  @override
  void collectAnswerIds(Set<String> out) {
    left.collectAnswerIds(out);
    right.collectAnswerIds(out);
  }
}

/// Gleichheit über die Werte hinweg, die in Antworten vorkommen können.
///
/// Dart vergleicht Listen und Maps mit `==` über die Identität. Eine Antwort
/// auf eine Mehrfachauswahl ist aber eine frisch gebaute Liste; ohne
/// Elementvergleich wäre `eq` dort immer falsch.
bool deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is num && b is num) return a == b;
  if (a is Iterable && b is Iterable) {
    final x = a.toList();
    final y = b.toList();
    if (x.length != y.length) return false;
    for (var i = 0; i < x.length; i++) {
      if (!deepEquals(x[i], y[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}
