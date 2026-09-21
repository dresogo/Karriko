import 'dart:convert';

import '../condition/condition.dart';
import 'config.dart';
import 'json_reader.dart';
import 'module.dart';
import 'question.dart';

/// Eine geladene, geprüfte Fragebogendefinition.
///
/// „Geprüft" heißt: Jede Bedingung kennt nur bekannte Operatoren, jeder
/// Antwortverweis zeigt auf eine Frage, die es gibt, jede Modulfrage existiert,
/// jeder Scoring-Beitrag auch. Was [parse] durchlässt, kann im Formular nicht
/// mehr an einem Tippfehler scheitern.
class Questionnaire {
  final String id;
  final int version;
  final String locale;

  final List<Phase> phases;
  final List<Question> questions;
  final List<Module> modules;

  final FlowConfig flow;
  final ScoringConfig scoring;
  final VisibilityConfig visibility;
  final QualityConfig quality;

  final Map<String, bool> featureFlags;

  /// Anonymitätshinweise, Rechtshinweise, Anlaufstellen. Rohes JSON, weil die
  /// Form je Schlüssel verschieden ist; der Zugriff läuft über [text] und
  /// [textList].
  final Map<String, Object?> texts;

  final Map<String, Question> _byId;
  final Map<String, Module> _modulesById;

  Questionnaire._({
    required this.id,
    required this.version,
    required this.locale,
    required this.phases,
    required this.questions,
    required this.modules,
    required this.flow,
    required this.scoring,
    required this.visibility,
    required this.quality,
    required this.featureFlags,
    required this.texts,
  })  : _byId = {for (final q in questions) q.id: q},
        _modulesById = {for (final m in modules) m.id: m};

  Question? question(String id) => _byId[id];

  Module? module(String id) => _modulesById[id];

  bool flagEnabled(String flag) => featureFlags[flag] ?? false;

  /// Die Phase, in der die Module laufen.
  Phase get modulePhase => phases.firstWhere(
        (phase) => phase.holdsModules,
        orElse: () => throw StateError(
            'Keine Phase ist als Modulphase markiert (holdsModules).'),
      );

  /// Ein Text aus [texts]. `null`, wenn es ihn nicht gibt — der Aufrufer
  /// entscheidet, ob das ein Fehler ist.
  TextVariants? text(String key) {
    final value = texts[key];
    if (value == null) return null;
    return TextVariants.parse(JsonNode(value, 'texts.$key'));
  }

  /// Eine Liste von Texten, etwa die Anlaufstellen am Ende des Konfliktmoduls.
  List<TextVariants> textList(String key) {
    final value = texts[key];
    if (value is! List) return const [];
    return [
      for (var i = 0; i < value.length; i++)
        TextVariants.parse(JsonNode(value[i], 'texts.$key[$i]')),
    ];
  }

  /// Alle Einträge, die ich ergänzt habe und die durchgesehen werden müssen.
  List<String> get reviewFlagged {
    final out = <String>[];
    for (final module in modules) {
      if (module.review) out.add('module:${module.id}');
    }
    for (final question in questions) {
      if (question.review) out.add(question.id);
      for (final option in question.options) {
        if (option.review) out.add('${question.id}.${option.id}');
      }
    }
    return out;
  }

  static Questionnaire parseJsonString(String source) =>
      parse(jsonDecode(source) as Object?);

  static Questionnaire parse(Object? json) {
    final root = JsonNode.root(json);

    final questions = [
      for (final item in root.require('questions').items) Question.parse(item),
    ];
    final modules = [
      for (final item in root.child('modules').items) Module.parse(item),
    ];
    final phases = [
      for (final item in root.require('phases').items) Phase.parse(item),
    ];

    final flags = <String, bool>{};
    if (root.child('featureFlags').exists) {
      for (final entry in root.child('featureFlags').entries) {
        flags[entry.key] = entry.value.asBool;
      }
    }

    final questionnaire = Questionnaire._(
      id: root.require('id').asString,
      version: root.require('version').asInt,
      locale: root.require('locale').asString,
      phases: phases,
      questions: questions,
      modules: modules,
      flow: FlowConfig.parse(root.require('flow')),
      scoring: ScoringConfig.parse(root.require('scoring')),
      visibility: VisibilityConfig.parse(root.child('visibility')),
      quality: QualityConfig.parse(root.child('quality')),
      featureFlags: flags,
      texts: root.child('texts').asRawMap,
    );

    _check(questionnaire, root);
    return questionnaire;
  }

  /// Alles, was erst auffällt, wenn die Einzelteile beisammen sind.
  static void _check(Questionnaire q, JsonNode root) {
    final ids = <String>{};
    for (final question in q.questions) {
      if (!ids.add(question.id)) {
        root.fail('Die Frage-ID "${question.id}" kommt mehrfach vor.');
      }
    }

    for (final module in q.modules) {
      if (ids.contains(module.teaserQuestionId)) {
        root.fail(
            'Die Frage-ID "${module.teaserQuestionId}" ist reserviert für den '
            'Teaser des Moduls "${module.id}".');
      }
    }

    final phaseIds = {for (final phase in q.phases) phase.id};
    final modulePhases = q.phases.where((phase) => phase.holdsModules).length;
    if (modulePhases != 1) {
      root.fail('Genau eine Phase muss "holdsModules": true tragen, gefunden: '
          '$modulePhases.');
    }

    for (final question in q.questions) {
      if (!phaseIds.contains(question.phase)) {
        root.fail(
            'Die Frage "${question.id}" verweist auf die unbekannte Phase '
            '"${question.phase}".');
      }
      if (question.module != null && q.module(question.module!) == null) {
        root.fail(
            'Die Frage "${question.id}" verweist auf das unbekannte Modul '
            '"${question.module}".');
      }
    }

    final moduleIds = <String>{};
    for (final module in q.modules) {
      if (!moduleIds.add(module.id)) {
        root.fail('Die Modul-ID "${module.id}" kommt mehrfach vor.');
      }
      for (final questionId in module.questionIds) {
        final question = q.question(questionId);
        if (question == null) {
          root.fail(
              'Das Modul "${module.id}" verweist auf die unbekannte Frage '
              '"$questionId".');
        }
        if (question.module != module.id) {
          root.fail(
              'Die Frage "$questionId" steht im Modul "${module.id}", trägt '
              'aber module="${question.module}".');
        }
      }
    }

    _checkAnswerRefs(q, root);

    // Die Zeitform- und die Prioritätenfrage müssen existieren, sonst steht
    // der Ablauf.
    if (q.question(q.flow.tenseQuestionId) == null) {
      root.fail('flow.tenseQuestion verweist auf die unbekannte Frage '
          '"${q.flow.tenseQuestionId}".');
    }
    if (q.question(q.flow.priorityQuestionId) == null) {
      root.fail('flow.priorityQuestion verweist auf die unbekannte Frage '
          '"${q.flow.priorityQuestionId}".');
    }

    for (final entry in q.scoring.items.entries) {
      for (final item in entry.value) {
        if (q.question(item.questionId) == null) {
          root.fail(
              'Der Subscore "${entry.key}" verweist auf die unbekannte Frage '
              '"${item.questionId}".');
        }
      }
    }
    for (final dimension in q.scoring.dimensions) {
      if (!q.scoring.items.containsKey(dimension)) {
        root.fail('Für die Dimension "$dimension" fehlen die Beiträge.');
      }
      if (!q.scoring.defaultWeights.containsKey(dimension)) {
        root.fail('Für die Dimension "$dimension" fehlt das Standardgewicht.');
      }
    }

    for (final questionId in q.quality.straightliningQuestions) {
      if (q.question(questionId) == null) {
        root.fail('Der Straightlining-Index verweist auf die unbekannte Frage '
            '"$questionId".');
      }
    }
    for (final pair in q.quality.pairs) {
      for (final questionId in [pair.questionA, pair.questionB]) {
        if (q.question(questionId) == null) {
          root.fail(
              'Das Konsistenzpaar "${pair.id}" verweist auf die unbekannte '
              'Frage "$questionId".');
        }
      }
    }
    for (final questionId in q.quality.freeTextQuestions) {
      if (q.question(questionId) == null) {
        root.fail('quality.freeTextQuestions verweist auf die unbekannte Frage '
            '"$questionId".');
      }
    }
  }

  /// Jeder `{"answer": "…"}`-Verweis muss auf eine Frage zeigen, die es gibt.
  ///
  /// Das ist der eigentliche Grund für diese ganze Prüfung: Ein verschriebener
  /// Verweis liefert sonst still `null`, die Bedingung ist dann einfach falsch,
  /// und die Folgefrage erscheint nie — ohne dass irgendwo ein Fehler auftaucht.
  static void _checkAnswerRefs(Questionnaire q, JsonNode root) {
    void check(Condition? condition, String where) {
      if (condition == null) return;
      final referenced = <String>{};
      condition.collectAnswerIds(referenced);
      for (final id in referenced) {
        if (q.question(id) == null) {
          root.fail('$where verweist auf die unbekannte Frage "$id".');
        }
      }
    }

    for (final question in q.questions) {
      check(question.condition, 'Die Bedingung von "${question.id}"');
    }
    for (final module in q.modules) {
      check(module.trigger, 'Der Auslöser des Moduls "${module.id}"');
    }
    for (final combination in q.quality.impossible) {
      check(combination.condition,
          'Die unmögliche Kombination "${combination.id}"');
    }
  }
}
