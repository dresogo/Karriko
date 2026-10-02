import '../condition/condition.dart';
import 'json_reader.dart';

/// Zeitform, in der ein Text erscheint.
///
/// Hängt ausschließlich an der Steuerfrage S1: Wer noch in der Ausbildung ist,
/// liest Präsens, alle anderen Vergangenheit.
enum Tense { current, past }

/// Ein Text in beiden Zeitformen.
///
/// Fehlt `past`, greift `current`. Dass eine Variante fehlt, ist trotzdem ein
/// Befund und kein Zustand, in dem man v1 ausliefert — der Schema-Test in
/// Etappe B besteht auf beiden.
class TextVariants {
  final String current;
  final String? past;

  const TextVariants({required this.current, this.past});

  String forTense(Tense tense) =>
      tense == Tense.past ? (past ?? current) : current;

  bool get hasPast => past != null;

  /// Erlaubt beides: eine nackte Zeichenkette (dann nur Präsens) oder ein
  /// Objekt `{"current": …, "past": …}`.
  static TextVariants parse(JsonNode node) {
    final value = node.value;
    if (value is String) return TextVariants(current: value);
    final map = node.asMap;
    if (!map.containsKey('current')) {
      node.fail('Text braucht mindestens "current".');
    }
    return TextVariants(
      current: node.require('current').asString,
      past: node.child('past').exists ? node.child('past').asString : null,
    );
  }

  static TextVariants? parseOrNull(JsonNode node) =>
      node.exists ? parse(node) : null;
}

/// Eine Antwortoption.
class Option {
  final String id;
  final TextVariants label;

  /// Der gespeicherte Wert. Fehlt er in der Definition, ist es [id].
  final Object? value;

  /// Normalisierter Beitrag zur Auswertung, 0,0 bis 1,0.
  ///
  /// **Immer „höher ist besser".** Die umgekehrte Polung von K10 steckt in den
  /// Werten der Optionen, nicht in einem Vorzeichen anderswo. Die Polung selbst
  /// steht getrennt an der Frage ([Question.reversePolarity]), weil sie nur für
  /// den Straightlining-Index gebraucht wird.
  final double? score;

  final bool review;

  const Option({
    required this.id,
    required this.label,
    this.value,
    this.score,
    this.review = false,
  });

  /// Was in den Antworten landet.
  Object? get storedValue => value ?? id;

  static Option parse(JsonNode node) {
    final score = node.child('score');
    if (score.exists) {
      final v = score.asDouble;
      if (v < 0 || v > 1) {
        score.fail('score liegt zwischen 0,0 und 1,0, gefunden: $v.');
      }
    }
    return Option(
      id: node.require('id').asString,
      label: TextVariants.parse(node.require('label')),
      value: node.child('value').value,
      score: score.exists ? score.asDouble : null,
      review: node.child('review').boolOr(false),
    );
  }
}

/// Eine Frage der Definition.
///
/// [type] ist eine Typkennung, kein Enum. Der Dart-Code kennt die Liste der
/// Kennungen nicht; die Zuordnung zu einem Widget passiert in der Registry der
/// Flutter-Seite, und ein unbekannter Typ ist dort ein sichtbarer Fehler.
class Question {
  final String id;

  /// Kennung aus der Spezifikation, etwa `K3.1`. Steht zusätzlich zur [id] da,
  /// damit sich eine Frage im Fachdokument wiederfinden lässt.
  final String specRef;

  final String type;
  final String phase;
  final String? module;

  final TextVariants text;
  final TextVariants? intro;
  final TextVariants? placeholder;

  final List<Option> options;

  /// Typabhängige Einstellungen. Wird nicht geprüft, weil der Inhalt je
  /// Typkennung anders aussieht; zuständig ist das Widget.
  final Map<String, Object?> config;

  final Condition? condition;

  /// Vor dieser Frage erscheint die Anonymitätszusage erneut.
  final bool sensitive;

  /// Die Antwort wird veröffentlicht.
  final bool public;

  /// Muss beantwortet werden, solange sie sichtbar ist.
  final bool required;

  /// Schlüssel, unter dem die Antwort ins Scoring eingeht. Fehlt er, trägt die
  /// Frage zu keinem Subscore bei.
  final String? scoringRef;

  /// Umgekehrt gepolt (K10). Nur für den Straightlining-Index von Belang.
  final bool reversePolarity;

  /// Merkmalsschalter, an dem diese Frage hängt.
  ///
  /// Steht er aus, erscheint die Frage nie — unabhängig von [condition]. Ein
  /// ganzes Modul hängt über `Module.featureFlag` an einem Schalter; das hier
  /// ist der Fall für einzelne Fragen, etwa den Kleinbetriebshinweis in Phase 3.
  final String? featureFlag;

  /// Von mir ergänzt, nicht aus der Spezifikation. Landet in REVIEW_TEXTE.md.
  final bool review;

  const Question({
    required this.id,
    required this.specRef,
    required this.type,
    required this.phase,
    required this.text,
    this.module,
    this.intro,
    this.placeholder,
    this.options = const [],
    this.config = const {},
    this.condition,
    this.sensitive = false,
    this.public = false,
    this.required = false,
    this.scoringRef,
    this.reversePolarity = false,
    this.featureFlag,
    this.review = false,
  });

  Option? optionForValue(Object? value) {
    for (final option in options) {
      if (deepEquals(option.storedValue, value)) return option;
    }
    return null;
  }

  Option? optionById(String id) {
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  static Question parse(JsonNode node) {
    final id = node.require('id').asString;
    final options = [
      for (final item in node.child('options').items) Option.parse(item)
    ];

    final seen = <String>{};
    for (final option in options) {
      if (!seen.add(option.id)) {
        node
            .child('options')
            .fail('Die Option "${option.id}" kommt in "$id" mehrfach vor.');
      }
    }

    return Question(
      id: id,
      specRef: node.child('specRef').stringOr(''),
      type: node.require('type').asString,
      phase: node.require('phase').asString,
      module:
          node.child('module').exists ? node.child('module').asString : null,
      text: TextVariants.parse(node.require('text')),
      intro: TextVariants.parseOrNull(node.child('intro')),
      placeholder: TextVariants.parseOrNull(node.child('placeholder')),
      options: options,
      config: node.child('config').asRawMap,
      condition: Condition.parseOrNull(node.child('condition')),
      sensitive: node.child('sensitive').boolOr(false),
      public: node.child('public').boolOr(false),
      required: node.child('required').boolOr(false),
      scoringRef: node.child('scoringRef').exists
          ? node.child('scoringRef').asString
          : null,
      reversePolarity: node.child('reversePolarity').boolOr(false),
      featureFlag: node.child('featureFlag').exists
          ? node.child('featureFlag').asString
          : null,
      review: node.child('review').boolOr(false),
    );
  }
}
