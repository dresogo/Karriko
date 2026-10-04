import '../condition/condition.dart';
import '../model/module.dart';
import '../model/question.dart';
import '../model/questionnaire.dart';
import 'answers.dart';

/// Was im Teaser eines Moduls steht: wie viele Fragen, wie lange ungefähr.
class ModuleTeaser {
  final Module module;
  final int questionCount;
  final int estimatedSeconds;

  const ModuleTeaser({
    required this.module,
    required this.questionCount,
    required this.estimatedSeconds,
  });
}

/// Fortschritt innerhalb einer Phase.
///
/// Bewusst pro Phase und nicht als Gesamtwert: Die Länge des Bogens hängt an
/// den gewählten Modulen, ein Gesamtbalken würde bei jeder Modulentscheidung
/// springen.
class PhaseProgress {
  final String phaseId;
  final int answered;
  final int total;

  const PhaseProgress({
    required this.phaseId,
    required this.answered,
    required this.total,
  });

  double get fraction => total == 0 ? 0 : answered / total;
}

/// Die Ablaufsteuerung: aus Definition und bisherigen Antworten ergibt sich,
/// was als Nächstes kommt.
///
/// Alles hier ist eine reine Funktion der Eingaben. Derselbe Stand ergibt
/// immer denselben Ablauf — auf dem Client wie in der Function, die die
/// Einreichung später gegen genau dieselbe Logik prüft.
class QuestionnaireFlow {
  final Questionnaire questionnaire;

  /// Abgeleitete Werte für `{"computed": "…"}` in Bedingungen.
  final Map<String, Object?> computed;

  const QuestionnaireFlow(this.questionnaire, {this.computed = const {}});

  /// Die Zeitform, in der alle Texte erscheinen. Folgt allein aus S1.
  Tense tense(Answers answers) {
    final value = answers[questionnaire.flow.tenseQuestionId];
    if (value is String && questionnaire.flow.pastValues.contains(value)) {
      return Tense.past;
    }
    return Tense.current;
  }

  EvalContext context(Answers answers) => EvalContext(
        answers: answers.values,
        computed: {...computed, 'tense': tense(answers).name},
      );

  /// Die Module, die angeboten werden: die aus K12 gewählten plus alle
  /// automatisch ausgelösten.
  ///
  /// Reihenfolge ist die der Definition, nicht die der Prioritäten — sonst
  /// stünde bei jedem Azubi eine andere Strecke, und ein Vergleich der
  /// Bearbeitungszeiten wäre wertlos.
  List<Module> offeredModules(Answers answers) {
    final ctx = context(answers);
    final priorities = answers[questionnaire.flow.priorityQuestionId];
    final topN = <Object?>[];
    if (priorities is Iterable) {
      topN.addAll(priorities.take(questionnaire.flow.priorityTopN));
    }

    return [
      for (final module in questionnaire.modules)
        if (_moduleOffered(module, ctx, topN)) module,
    ];
  }

  bool _moduleOffered(Module module, EvalContext ctx, List<Object?> topN) {
    final flag = module.featureFlag;
    if (flag != null && !questionnaire.flagEnabled(flag)) return false;

    final key = module.priorityKey;
    if (key != null && topN.any((value) => deepEquals(value, key))) return true;

    final trigger = module.trigger;
    if (trigger != null && trigger.evaluate(ctx)) return true;

    // Kein Auslöser und kein Prioritätsschlüssel heißt: immer dabei. Das
    // Modul „Berufsschule und Betrieb" ist genau so gemeint.
    return key == null && trigger == null;
  }

  /// Alle Fragen, die bei diesem Antwortstand zu zeigen sind, in der
  /// Reihenfolge, in der sie kommen.
  List<Question> visibleQuestions(Answers answers) {
    final ctx = context(answers);
    final out = <Question>[];

    for (final phase in questionnaire.phases) {
      if (phase.holdsModules) {
        for (final module in offeredModules(answers)) {
          final teaser = module.teaserQuestion(phase.id);
          out.add(teaser);
          if (answers[teaser.id] != Module.acceptValue) continue;
          for (final questionId in module.questionIds) {
            final question = questionnaire.question(questionId)!;
            if (_passes(question, ctx)) out.add(question);
          }
        }
      } else {
        for (final question in questionnaire.questions) {
          if (question.phase != phase.id) continue;
          // Modulfragen kommen über ihr Modul, nie über ihre Phase.
          if (question.module != null) continue;
          if (_passes(question, ctx)) out.add(question);
        }
      }
    }
    return out;
  }

  bool _passes(Question question, EvalContext ctx) {
    final flag = question.featureFlag;
    if (flag != null && !questionnaire.flagEnabled(flag)) return false;
    final condition = question.condition;
    return condition == null || condition.evaluate(ctx);
  }

  /// Die nächste Frage, die noch keine Antwort hat.
  Question? nextUnanswered(Answers answers) {
    for (final question in visibleQuestions(answers)) {
      if (!answers.contains(question.id)) return question;
    }
    return null;
  }

  /// Die Frage nach [questionId]. `null` am Ende.
  ///
  /// Prüft `contains` statt `isAnswered`: Ein Bildschirm, den jemand bewusst
  /// ohne Antwort verlässt — ein Hinweis, ein übersprungenes Modul — ist
  /// erledigt, auch wenn dabei nichts Inhaltliches herauskommt.
  Question? after(Answers answers, String questionId) {
    final visible = visibleQuestions(answers);
    final index = visible.indexWhere((q) => q.id == questionId);
    if (index < 0 || index + 1 >= visible.length) return null;
    return visible[index + 1];
  }

  /// Die Frage vor [questionId]. `null` am Anfang.
  Question? before(Answers answers, String questionId) {
    final visible = visibleQuestions(answers);
    final index = visible.indexWhere((q) => q.id == questionId);
    if (index <= 0) return null;
    return visible[index - 1];
  }

  /// Antworten, die durch eine Änderung ungültig geworden sind.
  ///
  /// Wer bei S1 von „noch in der Ausbildung" auf „abgebrochen" wechselt, hat
  /// womöglich schon das Übernahmemodul beantwortet. Diese Antworten dürfen
  /// nicht mitgeschickt werden — die Validierung in der Function würde sie als
  /// „Antwort auf eine unsichtbare Frage" zurückweisen, und zu Recht.
  ///
  /// Wird so lange wiederholt, bis sich nichts mehr ändert: Das Entfernen einer
  /// Antwort kann die nächste unsichtbar machen.
  Set<String> staleAnswers(Answers answers) {
    final removed = <String>{};
    var current = answers;

    while (true) {
      final visible = {for (final q in visibleQuestions(current)) q.id};
      final stale = current.ids.where((id) => !visible.contains(id)).toSet();
      if (stale.isEmpty) return removed;
      removed.addAll(stale);
      current = current.remove(stale);
    }
  }

  /// Der Antwortstand ohne die ungültig gewordenen Antworten.
  Answers pruned(Answers answers) => answers.remove(staleAnswers(answers));

  /// Fragenzahl und geschätzte Dauer für den Teaser.
  ///
  /// Gezählt wird, was beim **jetzigen** Stand sichtbar wäre. Folgefragen
  /// innerhalb des Moduls, die an einer noch nicht gegebenen Antwort hängen,
  /// sind darin nicht enthalten — die Zahl im Teaser ist damit eine Untergrenze
  /// und verspricht nie zu wenig Aufwand.
  ModuleTeaser teaserFor(Module module, Answers answers) {
    final ctx = context(answers);
    var count = 0;
    for (final questionId in module.questionIds) {
      final question = questionnaire.question(questionId)!;
      if (_passes(question, ctx)) count++;
    }
    return ModuleTeaser(
      module: module,
      questionCount: count,
      estimatedSeconds: module.estimatedSeconds ??
          count * questionnaire.flow.secondsPerQuestion,
    );
  }

  List<ModuleTeaser> teasers(Answers answers) => [
        for (final module in offeredModules(answers))
          teaserFor(module, answers),
      ];

  PhaseProgress progress(Answers answers, String phaseId) {
    final visible =
        visibleQuestions(answers).where((q) => q.phase == phaseId).toList();
    return PhaseProgress(
      phaseId: phaseId,
      answered: visible.where((q) => answers.contains(q.id)).length,
      total: visible.length,
    );
  }

  List<PhaseProgress> allProgress(Answers answers) => [
        for (final phase in questionnaire.phases) progress(answers, phase.id),
      ];
}
