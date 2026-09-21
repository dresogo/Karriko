import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

import '../core/constants/questionnaire_constants.dart';
import '../data/models/review_draft.dart';
import '../data/repositories/review_submit_repository.dart';
import '../data/services/device_key.dart';
import 'auth_provider.dart';
import 'questionnaire_provider.dart';

/// Woran ein Durchlauf hängt. Als Record, damit Riverpod die Familie über
/// Gleichheit statt über Identität unterscheidet.
typedef QuestionnaireRunKey = ({
  String companyId,
  String companyName,
  String? inviteSource,
});

/// Der Stand eines laufenden Fragebogens.
@immutable
class QuestionnaireRunState {
  final bool loading;
  final String? loadError;

  /// Die Version, mit der dieser Durchlauf begonnen wurde. Sie wechselt nicht,
  /// auch wenn inzwischen eine neue aktiv ist.
  final Questionnaire? questionnaire;

  final Answers answers;

  /// Bearbeitungszeit je Bildschirm in Millisekunden, über Rücksprünge hinweg
  /// aufsummiert.
  final Map<String, int> timings;

  final String? currentQuestionId;
  final String? draftId;
  final String? verificationFileId;

  final bool submitting;
  final String? submitError;
  final SubmitResult? result;

  const QuestionnaireRunState({
    this.loading = true,
    this.loadError,
    this.questionnaire,
    this.answers = const Answers.empty(),
    this.timings = const {},
    this.currentQuestionId,
    this.draftId,
    this.verificationFileId,
    this.submitting = false,
    this.submitError,
    this.result,
  });

  bool get ready => questionnaire != null && !loading;

  bool get submitted => result != null;

  QuestionnaireRunState copyWith({
    bool? loading,
    String? loadError,
    Questionnaire? questionnaire,
    Answers? answers,
    Map<String, int>? timings,
    String? currentQuestionId,
    String? draftId,
    String? verificationFileId,
    bool? submitting,
    String? submitError,
    SubmitResult? result,
    bool clearLoadError = false,
    bool clearSubmitError = false,
  }) {
    return QuestionnaireRunState(
      loading: loading ?? this.loading,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      questionnaire: questionnaire ?? this.questionnaire,
      answers: answers ?? this.answers,
      timings: timings ?? this.timings,
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      draftId: draftId ?? this.draftId,
      verificationFileId: verificationFileId ?? this.verificationFileId,
      submitting: submitting ?? this.submitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      result: result ?? this.result,
    );
  }
}

/// Führt einen Fragebogen von der ersten bis zur letzten Frage.
///
/// Der Zustand ist unveränderlich und die Ablaufsteuerung eine reine Funktion
/// davon: Welche Frage als Nächstes kommt, welche Module angeboten werden und
/// welche Antworten durch eine Änderung ungültig geworden sind, rechnet
/// [QuestionnaireFlow] jedes Mal neu aus. Es gibt hier keinen zweiten,
/// mitgeführten Ablauf, der davon abweichen könnte.
class QuestionnaireRunNotifier extends StateNotifier<QuestionnaireRunState> {
  final Ref _ref;
  final QuestionnaireRunKey key;

  Timer? _draftTimer;

  /// Wann der aktuelle Bildschirm aufgebaut wurde.
  DateTime? _betreten;

  QuestionnaireRunNotifier(this._ref, this.key)
      : super(const QuestionnaireRunState());

  // ── Start ─────────────────────────────────────────────────────────────────

  Future<void> start() async {
    final userId = _ref.read(authProvider).user?.id;

    try {
      final entwurf = userId == null
          ? null
          : await _ref
              .read(reviewDraftRepositoryProvider)
              .find(userId: userId, companyId: key.companyId);

      // Ein vorhandener Entwurf bestimmt die Version, nicht die aktive: Wer
      // unter v1 angefangen hat, füllt v1 zu Ende. Sonst verschwänden mitten
      // im Ausfüllen Fragen, während andere auftauchten.
      final geladen = entwurf == null
          ? await _ref.read(questionnaireRepositoryProvider).loadActive()
          : await _ref
              .read(questionnaireRepositoryProvider)
              .loadVersion(entwurf.schemaVersion);

      final antworten = Answers.from(entwurf?.answers ?? const {});
      final flow = QuestionnaireFlow(
        geladen.questionnaire,
        computed: computedValues(geladen.questionnaire, antworten),
      );

      // Auch ein geladener Entwurf wird aufgeräumt. Er kann unter einer
      // anderen Fassung entstanden sein, und dann hängen Antworten daran, die
      // es nicht mehr gibt — die Function würde die Einreichung zu Recht
      // zurückweisen.
      final bereinigt = flow.pruned(antworten);

      state = state.copyWith(
        loading: false,
        clearLoadError: true,
        questionnaire: geladen.questionnaire,
        answers: bereinigt,
        timings: entwurf?.timings ?? const {},
        draftId: entwurf?.id,
        currentQuestionId: _naechste(geladen.questionnaire, bereinigt,
            bevorzugt: entwurf?.currentQuestionId),
      );
      _betreten = DateTime.now();
    } on StateError catch (e) {
      state = state.copyWith(loading: false, loadError: e.message);
    } catch (e) {
      debugPrint('Fragebogen: Start fehlgeschlagen — $e');
      state = state.copyWith(
        loading: false,
        loadError: 'Der Fragebogen konnte nicht geladen werden. '
            'Bitte versuch es gleich noch einmal.',
      );
    }
  }

  String? _naechste(
    Questionnaire questionnaire,
    Answers answers, {
    String? bevorzugt,
  }) {
    final flow = QuestionnaireFlow(
      questionnaire,
      computed: computedValues(questionnaire, answers),
    );
    final sichtbar = flow.visibleQuestions(answers);
    if (sichtbar.isEmpty) return null;

    // Der gemerkte Bildschirm nur, wenn er noch sichtbar ist.
    if (bevorzugt != null && sichtbar.any((q) => q.id == bevorzugt)) {
      return bevorzugt;
    }
    return (flow.nextUnanswered(answers) ?? sichtbar.last).id;
  }

  // ── Ablauf ────────────────────────────────────────────────────────────────

  Questionnaire get _q => state.questionnaire!;

  /// Die Ablaufsteuerung zum jetzigen Stand.
  QuestionnaireFlow get flow => QuestionnaireFlow(
        _q,
        computed: computedValues(_q, state.answers),
      );

  Question? get currentQuestion {
    final id = state.currentQuestionId;
    if (id == null || state.questionnaire == null) return null;
    for (final question in flow.visibleQuestions(state.answers)) {
      if (question.id == id) return question;
    }
    return null;
  }

  Tense get tense => flow.tense(state.answers);

  /// Nimmt eine Antwort entgegen und räumt auf, was dadurch ungültig wird.
  void answer(String questionId, Object? value) {
    if (!state.ready) return;
    final erweitert = state.answers.set(questionId, value);
    final bereinigt = QuestionnaireFlow(
      _q,
      computed: computedValues(_q, erweitert),
    ).pruned(erweitert);

    state = state.copyWith(answers: bereinigt);
    _entwurfPlanen();
  }

  /// Weiter zum nächsten sichtbaren Bildschirm.
  ///
  /// Gibt `false` zurück, wenn es keinen mehr gibt — dann ist der Bogen am
  /// Ende und es geht ans Absenden.
  bool next() {
    final id = state.currentQuestionId;
    if (id == null) return false;
    _zeitBuchen();

    final danach = flow.after(state.answers, id);
    if (danach == null) return false;

    state = state.copyWith(currentQuestionId: danach.id);
    _betreten = DateTime.now();
    _entwurfPlanen();
    return true;
  }

  /// Zurück. Gibt `false` zurück, wenn wir schon am Anfang stehen.
  bool back() {
    final id = state.currentQuestionId;
    if (id == null) return false;
    _zeitBuchen();

    final davor = flow.before(state.answers, id);
    if (davor == null) return false;

    state = state.copyWith(currentQuestionId: davor.id);
    _betreten = DateTime.now();
    return true;
  }

  void goTo(String questionId) {
    _zeitBuchen();
    state = state.copyWith(currentQuestionId: questionId);
    _betreten = DateTime.now();
  }

  /// Zeit auf dem verlassenen Bildschirm dazuzählen.
  ///
  /// Aufsummiert statt überschrieben: Wer zurückgeht und eine Antwort ändert,
  /// hat sich mit dem Bildschirm zweimal befasst. Die zweite Zeit zu verwerfen
  /// hieße, genau die sorgfältigen Bewerter als zu schnell zu markieren.
  void _zeitBuchen() {
    final id = state.currentQuestionId;
    final seit = _betreten;
    if (id == null || seit == null) return;

    final dauer = DateTime.now().difference(seit).inMilliseconds;
    if (dauer <= 0) return;

    state = state.copyWith(
      timings: {...state.timings, id: (state.timings[id] ?? 0) + dauer},
    );
  }

  // ── Verifikation ──────────────────────────────────────────────────────────

  void setVerificationFile(String fileId) {
    state = state.copyWith(verificationFileId: fileId);
    _entwurfPlanen();
  }

  // ── Entwurf ───────────────────────────────────────────────────────────────

  /// Nach jeder Änderung, aber mit Verzögerung.
  ///
  /// Ohne sie schriebe jeder Tastendruck im Freitext ein Dokument nach
  /// Appwrite. Der lokale Stand steht ohnehin im Speicher der Seite; was hier
  /// verzögert wird, ist allein die Sicherung über das Gerät hinaus.
  void _entwurfPlanen() {
    _draftTimer?.cancel();
    _draftTimer = Timer(QuestionnaireConstants.draftSyncDelay, saveDraft);
  }

  Future<void> saveDraft() async {
    final userId = _ref.read(authProvider).user?.id;
    if (userId == null || !state.ready) return;
    _zeitBuchen();

    try {
      final gespeichert =
          await _ref.read(reviewDraftRepositoryProvider).save(ReviewDraft(
                id: state.draftId,
                userId: userId,
                companyId: key.companyId,
                schemaVersion: _q.version,
                answers: state.answers.toJson(),
                timings: state.timings,
                currentQuestionId: state.currentQuestionId,
                inviteSource: key.inviteSource,
                updatedAt: DateTime.now().toUtc(),
              ));
      if (!mounted) return;
      state = state.copyWith(draftId: gespeichert.id);
    } catch (e) {
      // Ein misslungener Zwischenstand ist kein Grund, den Bogen anzuhalten.
      // Die Antworten stehen im Speicher der Seite und gehen beim nächsten
      // Versuch mit.
      debugPrint('Fragebogen: Entwurf nicht gespeichert — $e');
    }
  }

  // ── Absenden ──────────────────────────────────────────────────────────────

  /// Die Prüfung, die auch die Function macht — nur früher.
  ///
  /// Serverseitig läuft sie ohnehin und ist dort verbindlich. Hier vorweg,
  /// damit ein Fehler nicht erst nach dem Absenden auffällt.
  ValidationResult validate() => validateSubmission(
        questionnaire: _q,
        answers: flow.pruned(state.answers),
      );

  Future<void> submit() async {
    if (!state.ready || state.submitting) return;
    _zeitBuchen();

    final bereinigt = flow.pruned(state.answers);
    final pruefung =
        validateSubmission(questionnaire: _q, answers: bereinigt);

    if (!pruefung.isValid) {
      final fehlend = pruefung.withCode('missing_required');
      state = state.copyWith(
        submitError: fehlend.isNotEmpty
            ? 'Es fehlt noch eine Pflichtantwort. Geh einen Schritt zurück, '
                'dann siehst du, welche.'
            : 'Die Bewertung ist noch nicht vollständig.',
      );
      return;
    }

    state = state.copyWith(submitting: true, clearSubmitError: true);

    try {
      final ergebnis =
          await _ref.read(reviewSubmitRepositoryProvider).submit(
                companyId: key.companyId,
                schemaVersion: _q.version,
                answers: bereinigt.toJson(),
                timings: state.timings,
                inviteSource: key.inviteSource,
                verificationFileId: state.verificationFileId,
                draftId: state.draftId,
                deviceKey: await DeviceKey().readOrCreate(),
              );
      if (!mounted) return;

      _draftTimer?.cancel();
      state = state.copyWith(
        submitting: false,
        answers: bereinigt,
        result: ergebnis,
      );
    } on SubmitException catch (e) {
      if (!mounted) return;
      state = state.copyWith(submitting: false, submitError: e.message);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    super.dispose();
  }
}

/// Ein Durchlauf je Betrieb.
///
/// `autoDispose`, damit ein abgeschlossener oder verlassener Bogen nicht im
/// Speicher liegenbleibt — und damit ein erneutes Öffnen den Entwurf frisch
/// lädt, statt einen alten Stand im Arbeitsspeicher weiterzuführen.
final questionnaireRunProvider = StateNotifierProvider.autoDispose
    .family<QuestionnaireRunNotifier, QuestionnaireRunState, QuestionnaireRunKey>(
  (ref, key) {
    // Am Leben halten, solange der Bildschirm offen ist: Ein Wegräumen
    // mitten im Ausfüllen verlöre den nicht gesicherten Stand.
    ref.keepAlive();
    return QuestionnaireRunNotifier(ref, key)..start();
  },
);
