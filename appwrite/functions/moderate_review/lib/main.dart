import 'dart:io';

import 'package:karriko_functions/karriko_functions.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

/// Gibt eine Bewertung frei oder lehnt sie ab.
///
/// Nur für das Team `moderators` (und `admins`, die alles dürfen, was
/// Moderatoren dürfen). Die Ausführungsrechte der Function schützen den Aufruf;
/// die Prüfung hier hält zusätzlich fest, **wer** entschieden hat, und dieser
/// Name landet im `moderation_log`. Eine Moderation ohne nachvollziehbaren
/// Urheber ist keine.
///
/// **Bei der Freigabe entsteht die öffentliche Zeile.** Erst hier, nicht beim
/// Einreichen: `public_reviews` ist die Tabelle, die jeder lesen darf, und was
/// dort steht, hat ein Mensch gesehen.
///
/// **Der Nachweis wird hier quittiert.** Ob ein Ausbildungsverhältnis belegt
/// ist, kann nur jemand entscheiden, der das Dokument gesehen hat — deshalb
/// `verified` im Aufruf und nirgends sonst. Ohne die Angabe bleibt es beim
/// bisherigen Stand.
///
/// **Ablehnen löscht nicht.** Die Bewertung bleibt in `reviews` mit Status
/// `rejected` stehen, mit Begründung im Log. Löschen träfe erfahrungsgemäß vor
/// allem die ausführlichen, ehrlichen Bewertungen — und wäre nicht umkehrbar.
Future<dynamic> main(final context) async {
  final RunContext ctx;
  try {
    ctx = RunContext.fromRuntime(context, environment: Platform.environment);
  } on MissingConfigException catch (e) {
    context.error(e.toString());
    return context.res.json(
      FunctionResponse.unavailable('Nicht eingerichtet.').payload,
      503,
    );
  }

  final userId = ctx.userId;
  if (userId == null) {
    return _antwort(
        context, FunctionResponse.unauthorized('Nicht angemeldet.'));
  }

  final client = ctx.adminClient();
  final wache = TeamGuard(adminClient: client, config: ctx.config);
  if (!await wache.mayModerate(userId)) {
    ctx.logError('$userId ist kein Moderator.');
    return _antwort(
      context,
      FunctionResponse.forbidden(
          'Diese Aktion ist der Moderation vorbehalten.'),
    );
  }

  final reviewId = ctx.body['review_id'];
  final aktion = ctx.body['action'];
  final begruendung = ctx.body['reason'] as String?;

  // Ob das Ausbildungsverhältnis nachgewiesen ist, entscheidet der Moderator —
  // er hat den Nachweis gesehen. Fehlt die Angabe, bleibt es beim bisherigen
  // Stand: Eine Freigabe ohne Aussage dazu setzt kein Kennzeichen.
  final nachgewiesen = ctx.body['verified'];

  if (reviewId is! String || reviewId.isEmpty) {
    return _antwort(context, FunctionResponse.invalid('review_id fehlt.'));
  }
  if (aktion != 'approve' && aktion != 'reject') {
    return _antwort(
      context,
      FunctionResponse.invalid('action muss "approve" oder "reject" sein.'),
    );
  }
  if (nachgewiesen != null && nachgewiesen is! bool) {
    return _antwort(
      context,
      FunctionResponse.invalid('verified muss wahr oder falsch sein.'),
    );
  }
  // Eine Ablehnung ohne Begründung ist für den Verfasser nicht nachvollziehbar
  // und für die Moderation nicht überprüfbar.
  if (aktion == 'reject' &&
      (begruendung == null || begruendung.trim().isEmpty)) {
    return _antwort(
      context,
      FunctionResponse.invalid('Eine Ablehnung braucht eine Begruendung.'),
    );
  }

  final tables = Tables(client: client, config: ctx.config);
  final loader = DefinitionLoader(client: client, config: ctx.config);

  final review = await tables.getReview(reviewId);
  final zeile = Map<String, Object?>.from(review.data);
  final flags = <String>[
    for (final flag in (zeile['quality_flags'] as List? ?? const []))
      flag.toString(),
  ];

  if (aktion == 'reject') {
    await tables.updateReview(reviewId, {'status': ReviewStatus.rejected});

    // Falls sie schon einmal freigegeben war: Die öffentliche Zeile muss weg.
    // Sonst bliebe eine abgelehnte Bewertung sichtbar.
    final oeffentlich = await tables.findPublicReview(reviewId);
    if (oeffentlich != null) {
      await tables.deletePublicReview(oeffentlich.$id);
      ctx.log('Oeffentliche Zeile ${oeffentlich.$id} entfernt.');
    }

    await tables.logModeration(
      reviewId: reviewId,
      moderatorId: userId,
      action: 'reject',
      reason: begruendung,
      flags: flags,
    );
    return _antwort(
        context, FunctionResponse.ok({'status': ReviewStatus.rejected}));
  }

  // ── Freigabe ──────────────────────────────────────────────────────────────

  final version = (zeile['schema_version'] as num?)?.round();
  if (version == null) {
    return _antwort(
      context,
      FunctionResponse.invalid('Der Bewertung fehlt die schema_version.'),
    );
  }

  final Questionnaire questionnaire;
  try {
    questionnaire = await loader.load(version);
  } on DefinitionNotFoundException catch (e) {
    ctx.logError(e.toString());
    return _antwort(
      context,
      FunctionResponse.unavailable(
        'Die Fassung des Fragebogens zu dieser Bewertung ist nicht abrufbar.',
      ),
    );
  }

  final jetzt = DateTime.now().toUtc();
  final eingereicht = DateTime.tryParse(review.$createdAt) ?? jetzt;

  // Die Alterung richtet sich nach dem Einreichen, nicht nach der Freigabe.
  // Eine Bewertung, die drei Jahre in der Moderation lag, ist alt — nicht neu,
  // weil sie gerade freigegeben wurde.
  final gealtert = CompanyAggregate.isAged(questionnaire, eingereicht, jetzt);

  if (nachgewiesen is bool) zeile['verified'] = nachgewiesen;

  // Name und Slug wandern in die öffentliche Zeile. `companies` ist für jeden
  // lesbar, die Betriebsseite also ohnehin offen — hier steht nichts, was nicht
  // schon öffentlich wäre.
  final betrieb = await tables.getCompany(zeile['company_id'] as String? ?? '');
  if (betrieb == null) {
    ctx.logError(
      'Betrieb ${zeile['company_id']} nicht gefunden — die oeffentliche Zeile '
      'entsteht ohne Name und Verweis.',
    );
  }

  final vorhanden = await tables.findPublicReview(reviewId);
  if (vorhanden == null) {
    final oeffentlich = await tables.createPublicReview(
      buildPublicReviewRow(
        reviewId: reviewId,
        reviewRow: zeile,
        isAged: gealtert,
        publishedAt: jetzt,
        companyName: betrieb?.data['name'] as String?,
        companySlug: betrieb?.data['slug'] as String?,
      ),
    );
    ctx.log('Oeffentliche Zeile ${oeffentlich.$id} angelegt.');
  } else {
    ctx.log('Oeffentliche Zeile besteht bereits — nichts angelegt.');
  }

  await tables.updateReview(reviewId, {
    'status': ReviewStatus.approved,
    if (nachgewiesen is bool) 'verified': nachgewiesen,
  });
  await tables.logModeration(
    reviewId: reviewId,
    moderatorId: userId,
    action: 'approve',
    reason: begruendung,
    flags: flags,
  );

  return _antwort(
    context,
    FunctionResponse.ok({
      'status': ReviewStatus.approved,
      'is_aged': gealtert,
      'verified': zeile['verified'] ?? false,
    }),
  );
}

dynamic _antwort(final context, FunctionResponse antwort) =>
    context.res.json(antwort.payload, antwort.status);
