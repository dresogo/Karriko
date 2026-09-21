import '../condition/condition.dart';
import '../flow/answers.dart';
import '../flow/flow.dart';
import '../model/question.dart';
import '../model/questionnaire.dart';

/// Ein Befund der Prüfung.
class ValidationIssue {
  /// Die betroffene Frage. Leer, wenn der Befund die Einreichung als Ganzes
  /// betrifft.
  final String questionId;

  /// Maschinenlesbar, für die Function: `not_visible`, `missing_required`,
  /// `unknown_question`, `invalid_value`.
  final String code;

  /// Für den Entwickler, nicht für den Azubi. Landet im Log der Function,
  /// nicht im Formular.
  final String message;

  const ValidationIssue({
    required this.questionId,
    required this.code,
    required this.message,
  });

  @override
  String toString() => '[$code] $questionId: $message';
}

class ValidationResult {
  final List<ValidationIssue> issues;

  const ValidationResult(this.issues);

  bool get isValid => issues.isEmpty;

  List<ValidationIssue> withCode(String code) => [
        for (final issue in issues)
          if (issue.code == code) issue
      ];
}

/// Prüft eine Einreichung gegen **genau die Version**, mit der sie erstellt
/// wurde.
///
/// Darauf kommt es an: Eine Bewertung, die unter v1 begonnen wurde, wird unter
/// v1 geprüft, auch wenn inzwischen v2 aktiv ist. Sonst wäre jede
/// Fragebogenänderung rückwirkend ein Grund, fremde Einreichungen abzulehnen.
///
/// Die Prüfung ist **datengetrieben, nicht typgetrieben**. Sie liest `options`
/// und `config` und kennt keine einzige Typkennung. Ein neuer Widget-Typ in der
/// Flutter-Schicht erzwingt damit keine Änderung hier.
ValidationResult validateSubmission({
  required Questionnaire questionnaire,
  required Answers answers,
}) {
  final issues = <ValidationIssue>[];
  final flow = QuestionnaireFlow(questionnaire);
  final visible = flow.visibleQuestions(answers);
  final visibleById = {for (final question in visible) question.id: question};

  for (final id in answers.ids) {
    if (visibleById.containsKey(id)) continue;
    final known =
        questionnaire.question(id) != null || _isTeaserId(questionnaire, id);
    issues.add(ValidationIssue(
      questionId: id,
      code: known ? 'not_visible' : 'unknown_question',
      message: known
          ? 'Beantwortet, obwohl bei diesem Antwortstand nicht sichtbar.'
          : 'Es gibt keine Frage mit dieser Kennung in Version '
              '${questionnaire.version}.',
    ));
  }

  for (final question in visible) {
    final answered = answers.isAnswered(question.id);
    if (question.required && !answered) {
      issues.add(ValidationIssue(
        questionId: question.id,
        code: 'missing_required',
        message: 'Pflichtfrage ohne Antwort.',
      ));
      continue;
    }
    if (!answers.contains(question.id)) continue;
    final problem = _checkValue(question, answers[question.id]);
    if (problem != null) {
      issues.add(ValidationIssue(
        questionId: question.id,
        code: 'invalid_value',
        message: problem,
      ));
    }
  }

  return ValidationResult(issues);
}

bool _isTeaserId(Questionnaire questionnaire, String id) {
  for (final module in questionnaire.modules) {
    if (module.teaserQuestionId == id) return true;
  }
  return false;
}

/// `null`, wenn der Wert in Ordnung ist, sonst die Begründung.
String? _checkValue(Question question, Object? value) {
  if (value == null) return null;

  if (value is Map) {
    if (question.config['cards'] is List) return _checkCards(question, value);
    if (question.config['fields'] is List) return _checkFields(question, value);
    return 'Eine Zuordnung ist als Antwort auf diese Frage nicht vorgesehen: '
        'weder "cards" noch "fields" sind in config hinterlegt.';
  }
  if (value is Iterable) return _checkList(question, value.toList());
  if (value is num) return _checkNumber(question, value);
  if (value is String) return _checkScalar(question, value);
  if (value is bool) return _checkScalar(question, value);

  return 'Wert vom Typ ${value.runtimeType} ist als Antwort nicht vorgesehen.';
}

/// Mehrere Textfelder unter einer Frage — die beiden Freitexte aus A1.
///
/// Zwei Felder statt eines sind dort Absicht: Sie erzwingen den Blick auf beide
/// Seiten. Für die Prüfung heißt das nur, dass eine Antwort hier aus mehreren
/// benannten Texten besteht.
String? _checkFields(Question question, Map<Object?, Object?> value) {
  final fields = question.config['fields'];
  final known = <String>{
    for (final field in fields as List<Object?>)
      if (field is Map && field['id'] is String)
        field['id'] as String
      else if (field is String)
        field,
  };
  final maxLength = question.config['maxLength'];

  for (final entry in value.entries) {
    if (!known.contains(entry.key)) {
      return 'Unbekanntes Feld "${entry.key}".';
    }
    final text = entry.value;
    if (text == null) continue;
    if (text is! String) {
      return 'Feld "${entry.key}" enthält ${text.runtimeType} statt Text.';
    }
    if (maxLength is int && text.length > maxLength) {
      return 'Feld "${entry.key}" ist ${text.length} Zeichen lang, erlaubt '
          'sind $maxLength.';
    }
  }
  return null;
}

String? _checkCards(Question question, Map<Object?, Object?> value) {
  final cards = question.config['cards'] as List<Object?>;
  final known = <String>{
    for (final card in cards)
      if (card is Map && card['id'] is String) card['id'] as String,
  };
  final allowed = <Object?>{
    question.config['yesValue'] ?? 'ja',
    question.config['noValue'] ?? 'nein',
    ...?_list(question.config['otherValues']),
  };

  for (final entry in value.entries) {
    if (!known.contains(entry.key)) {
      return 'Unbekannte Karte "${entry.key}".';
    }
    if (!allowed.any((option) => deepEquals(option, entry.value))) {
      return 'Unzulässiger Wert "${entry.value}" für die Karte "${entry.key}".';
    }
  }
  return null;
}

String? _checkList(Question question, List<Object?> value) {
  if (question.options.isEmpty) {
    return 'Für diese Frage sind keine Optionen hinterlegt, eine Liste ist '
        'hier also kein gültiger Wert.';
  }

  for (final item in value) {
    if (question.optionForValue(item) == null) {
      return 'Unbekannte Option "$item".';
    }
  }

  final seen = <Object?>[];
  for (final item in value) {
    if (seen.any((other) => deepEquals(other, item))) {
      return 'Die Option "$item" kommt mehrfach vor.';
    }
    seen.add(item);
  }

  // Eine Rangfolge hat eine feste Länge — bei K12 genau drei. Weniger heißt,
  // dass die Gewichte auf zu wenig Grundlage stehen; mehr, dass das Widget
  // etwas anderes geschickt hat als vereinbart.
  final topN = question.config['topN'];
  if (topN is int && value.length != topN) {
    return 'Erwartet sind genau $topN Ränge, geliefert wurden ${value.length}.';
  }

  final min = question.config['minSelect'];
  if (min is int && value.length < min) {
    return 'Mindestens $min Auswahlen erwartet, geliefert wurden '
        '${value.length}.';
  }
  final max = question.config['maxSelect'];
  if (max is int && value.length > max) {
    return 'Höchstens $max Auswahlen erlaubt, geliefert wurden ${value.length}.';
  }
  return null;
}

String? _checkNumber(Question question, num value) {
  final min = question.config['min'];
  final max = question.config['max'];
  if (min is num && value < min) {
    return 'Wert $value liegt unter dem Minimum $min.';
  }
  if (max is num && value > max) {
    return 'Wert $value liegt über dem Maximum $max.';
  }

  final step = question.config['step'];
  if (step is num && step > 0 && min is num) {
    final offset = value - min;
    if ((offset / step - (offset / step).round()).abs() > 1e-9) {
      return 'Wert $value liegt nicht auf der Schrittweite $step ab $min.';
    }
  }

  // Bei einer Frage mit Optionen ist eine nackte Zahl nur zulässig, wenn eine
  // Option genau diesen Wert trägt.
  if (question.options.isNotEmpty && question.optionForValue(value) == null) {
    return 'Unbekannte Option "$value".';
  }
  return null;
}

String? _checkScalar(Question question, Object value) {
  final special = _list(question.config['special']);
  if (special != null && special.any((item) => deepEquals(item, value))) {
    return null;
  }

  if (question.options.isNotEmpty) {
    if (question.optionForValue(value) == null) {
      return 'Unbekannte Option "$value".';
    }
    return null;
  }

  // Eine Frage mit Zahlengrenzen erwartet eine Zahl. Alles andere ist nur
  // zulässig, wenn es in `config.special` steht — und das ist oben schon
  // abgehandelt. Ohne diese Prüfung ginge jede Zeichenkette als „weiß ich
  // nicht" durch, und der Stepper hätte still einen zweiten, undeklarierten
  // Sonderwert.
  if (_hasNumericBounds(question)) {
    return 'Erwartet wird eine Zahl oder einer der hinterlegten Sonderwerte, '
        'geliefert wurde "$value".';
  }

  if (value is String) {
    final maxLength = question.config['maxLength'];
    if (maxLength is int && value.length > maxLength) {
      return 'Text ist ${value.length} Zeichen lang, erlaubt sind $maxLength.';
    }
  }
  return null;
}

bool _hasNumericBounds(Question question) =>
    question.config['min'] is num ||
    question.config['max'] is num ||
    question.config['step'] is num;

List<Object?>? _list(Object? value) => value is List ? value : null;
