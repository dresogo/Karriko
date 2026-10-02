import 'package:flutter/widgets.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

/// Alles, was ein Fragen-Widget braucht.
///
/// Ein Widget kennt **eine** Typkennung und sonst nichts vom Fragebogen: nicht
/// den Ablauf, nicht die anderen Fragen, nicht das Absenden. Es bekommt eine
/// Frage, den bisherigen Wert und einen Rückkanal — mehr nicht. Damit lässt es
/// sich einzeln testen, und ein neuer Typ zieht keine Änderung am Ablauf nach
/// sich.
@immutable
class QuestionContext {
  final Question question;

  /// Die bisherige Antwort. `null` heißt unbeantwortet — und das ist bei
  /// [vas_unnumbered] ausdrücklich etwas anderes als 0.
  final Object? answer;

  final Tense tense;

  /// Für Widgets, die Texte aus `texts` nachschlagen — Anonymitätshinweis,
  /// Anlaufstellen, Rechtshinweis unter den Freitexten.
  final Questionnaire questionnaire;

  /// Eine neue Antwort. Darf beliebig oft kommen, auch bei jedem Tastendruck.
  final void Function(Object? value) onChanged;

  /// Weiterblättern. Kacheln und Wischkarten benutzen das, damit eine Antwort
  /// nicht noch einen Klick auf „Weiter" kostet.
  final VoidCallback onAdvance;

  const QuestionContext({
    required this.question,
    required this.answer,
    required this.tense,
    required this.questionnaire,
    required this.onChanged,
    required this.onAdvance,
  });

  /// Der Fragetext in der richtigen Zeitform.
  String get text => question.text.forTense(tense);

  String? get intro => question.intro?.forTense(tense);

  String? get placeholder => question.placeholder?.forTense(tense);

  /// Die Beschriftung einer Option in der richtigen Zeitform.
  String label(Option option) => option.label.forTense(tense);

  /// Ein Text aus `texts`, in der richtigen Zeitform.
  String? sharedText(String key) => questionnaire.text(key)?.forTense(tense);

  List<String> sharedTextList(String key) => [
        for (final text in questionnaire.textList(key)) text.forTense(tense),
      ];

  /// Ein Wert aus `config`, ohne Typgeraten an der Aufrufstelle.
  T? config<T>(String key) {
    final value = question.config[key];
    return value is T ? value : null;
  }

  num? configNum(String key) {
    final value = question.config[key];
    return value is num ? value : null;
  }
}
