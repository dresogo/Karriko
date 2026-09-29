import 'dart:io';

import 'package:karriko_functions/karriko_functions.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

/// Nimmt eine fertige Bewertung an.
///
/// **Die einzige Stelle, an der eine Bewertung entsteht.** Clients haben auf
/// `reviews` kein Schreibrecht — nicht weil man ihnen nicht traut, sondern weil
/// Werte, die der Client berechnet, keine Werte sind: Sie wären beliebig
/// setzbar, und ein Score, den man sich selbst geben kann, sagt nichts.
///
/// Was hier passiert, in dieser Reihenfolge:
///
/// 1. Anmeldung prüfen. Ohne Nutzer keine Bewertung.
/// 2. **Genau die Version laden**, mit der die Einreichung erstellt wurde.
/// 3. Gegen diese Version prüfen: nur sichtbare Fragen beantwortet, Typen und
///    Wertebereiche korrekt, Pflichtfragen vorhanden.
/// 4. Dublette prüfen.
/// 5. Werte und Qualitäts-Flags **neu** berechnen. Was der Client gerechnet
///    hat, war für die Anzeige.
/// 6. Zeile anlegen, Entwurf löschen.
Future<dynamic> main(final context) async {
  final RunContext ctx;
  try {
    ctx = RunContext.fromRuntime(context, environment: Platform.environment);
  } on MissingConfigException catch (e) {
    context.error(e.toString());
    return context.res.json(
      FunctionResponse.unavailable(
        'Der Dienst ist nicht vollstaendig eingerichtet.',
      ).payload,
      503,
    );
  }

  final userId = ctx.userId;
  if (userId == null) {
    return _antwort(
      context,
      FunctionResponse.unauthorized(
        'Bitte melde dich an, um deine Bewertung abzuschicken.',
      ),
    );
  }

  final companyId = ctx.body['company_id'];
  final schemaVersion = ctx.body['schema_version'];
  final rohAntworten = ctx.body['answers'];

  if (companyId is! String ||
      companyId.isEmpty ||
      schemaVersion is! num ||
      rohAntworten is! Map) {
    return _antwort(
      context,
      FunctionResponse.invalid('Die Einreichung ist unvollstaendig.'),
    );
  }

  final client = ctx.adminClient();
  final tables = Tables(client: client, config: ctx.config);
  final loader = DefinitionLoader(client: client, config: ctx.config);

  final Questionnaire questionnaire;
  try {
    questionnaire = await loader.load(schemaVersion.round());
  } on DefinitionException catch (e) {
    ctx.logError(e.toString());
    return _antwort(
      context,
      FunctionResponse.unavailable(
        'Die Fassung des Fragebogens, mit der du angefangen hast, ist gerade '
        'nicht abrufbar. Dein Entwurf ist gespeichert.',
      ),
    );
  }

  final answers = Answers.from(
    rohAntworten.map((key, value) => MapEntry(key.toString(), value)),
  );

  // Streng und nicht nachsichtig: Der Client räumt ungültig gewordene
  // Antworten selbst auf, und er benutzt dafür dieselbe Funktion wie diese
  // Prüfung. Kommt hier trotzdem eine Antwort auf eine unsichtbare Frage an,
  // stimmt etwas nicht — und dann ist Stillschweigen die schlechtere Antwort.
  final pruefung = validateSubmission(
    questionnaire: questionnaire,
    answers: answers,
  );
  if (!pruefung.isValid) {
    for (final befund in pruefung.issues) {
      ctx.logError('Ungueltig: $befund');
    }
    return _antwort(
      context,
      FunctionResponse.invalid(
        'Die Bewertung ist noch nicht vollstaendig.',
        [
          for (final befund in pruefung.issues)
            '${befund.code}:${befund.questionId}'
        ],
      ),
    );
  }

  final vorhanden = await tables.findReviewByUserAndCompany(
    userId: userId,
    companyId: companyId,
  );
  if (vorhanden != null) {
    return _antwort(
      context,
      FunctionResponse.duplicate(
        'Du hast diesen Betrieb schon bewertet.',
      ),
    );
  }

  final scores = ReviewScores.compute(questionnaire, answers);
  final timings = <String, int>{
    for (final eintrag in (ctx.body['timings'] as Map? ?? const {}).entries)
      if (eintrag.value is num)
        eintrag.key.toString(): (eintrag.value as num).round(),
  };

  final flags = evaluateQuality(
    questionnaire: questionnaire,
    answers: answers,
    timings: timings,
    scores: scores,
  );

  final entscheidung = decidePublishing(
    questionnaire: questionnaire,
    answers: answers,
    config: ctx.config,
    now: DateTime.now().toUtc(),
  );

  final zeile = buildReviewRow(
    questionnaire: questionnaire,
    answers: answers,
    scores: scores,
    flags: flags,
    companyId: companyId,
    userId: userId,
    status: entscheidung.status,
    timings: timings,
    inviteSource: _quelle(questionnaire, ctx.body['invite_source']),
    verificationFileId: ctx.body['verification_file_id'] as String?,
    // Der Rohwert wird gehasht und fällt danach weg. Ohne Salz in der Umgebung
    // wird gar nicht gehasht — ein bekanntes Salz ist kein Salz.
    deviceHash: hashDeviceKey(
      ctx.body['device_key'] as String?,
      ctx.config.deviceHashSalt,
    ),
    publishAfter: entscheidung.publishAfter,
    publishAfterTrainingEnd: entscheidung.untilTrainingEnd,
  );

  final angelegt = await tables.createReview(zeile);
  ctx.log(
    'Bewertung ${angelegt.$id} angelegt, Status ${entscheidung.status}, '
    '${flags.length} Flag(s).',
  );

  // Erst nach dem Anlegen. Scheitert das Löschen, ist der Entwurf verwaist —
  // `cleanup` räumt ihn später weg. Umgekehrt wäre die Bewertung verloren.
  final draftId = ctx.body['draft_id'];
  if (draftId is String && draftId.isNotEmpty) {
    try {
      await tables.deleteDraft(draftId);
    } catch (e) {
      ctx.logError('Entwurf $draftId nicht geloescht: $e');
    }
  }

  return _antwort(
    context,
    FunctionResponse.ok({
      'review_id': angelegt.$id,
      'status': entscheidung.status,
      if (entscheidung.publishAfter != null)
        'publish_after': entscheidung.publishAfter!.toIso8601String(),
      'quality_flags': [for (final flag in flags) flag.code],
    }),
  );
}

/// Eine Einladungsquelle zählt nur, wenn die Definition sie kennt.
///
/// Der Client prüft das schon, aber ein Client ist kein Argument: Wer über eine
/// Einladung kommt, wird intern markiert, und diese Markierung ließe sich sonst
/// über eine selbstgebaute Adresse erschleichen.
String? _quelle(Questionnaire questionnaire, Object? roh) {
  if (roh is! String || roh.isEmpty) return null;
  final erlaubt = questionnaire.flow.inviteSources;
  if (erlaubt.isEmpty) return roh;
  return erlaubt.contains(roh) ? roh : null;
}

dynamic _antwort(final context, FunctionResponse antwort) =>
    context.res.json(antwort.payload, antwort.status);
