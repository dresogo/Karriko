import 'dart:io';

import 'package:karriko_functions/karriko_functions.dart';

/// Nimmt eine Meldung zu einer veröffentlichten Bewertung an (T-4.41).
///
/// **Die einzige Stelle, an der eine Meldung entsteht.** Vorher schrieb der
/// Client direkt in `review_reports` und setzte `reporter_id` und `status`
/// selbst; eine Meldung ließ sich so einem fremden Konto zuschreiben. Jetzt
/// kommt der Melder aus dem geprüften Aufruf, der Status ist immer „offen“,
/// und die Tabelle hat kein Anlegerecht mehr für Clients.
///
/// Was hier passiert, in dieser Reihenfolge:
///
/// 1. Anmeldung und bestätigte Adresse prüfen, wie vorher die Tabellenregel
///    `create("users/verified")`.
/// 2. Begründung prüfen: nicht leer, höchstens 1000 Zeichen.
/// 3. Die Bewertung muss öffentlich sein. Gemeldet wird, was man sieht.
/// 4. Dieselbe Bewertung zählt je Konto einmal (T-2.17), danach höchstens
///    fünf Meldungen je 24 h (T-3.10).
/// 5. Zeile anlegen; lesen darf sie der Melder und die Moderation.
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
      context,
      FunctionResponse.unauthorized('Bitte melde dich an, um zu melden.'),
    );
  }
  if (!await hasVerifiedEmail(ctx)) {
    return _antwort(
      context,
      FunctionResponse.forbidden(
        'Bitte bestätige zuerst deine E-Mail-Adresse.',
      ),
    );
  }

  final reviewId = ctx.body['review_id'];
  final grund = normalizeReportReason(ctx.body['reason']);
  if (reviewId is! String || reviewId.isEmpty || grund == null) {
    return _antwort(
      context,
      FunctionResponse.invalid(
        'Bitte gib einen Grund an, höchstens $maxReportReasonLength Zeichen.',
      ),
    );
  }

  final tables = Tables(client: ctx.adminClient(), config: ctx.config);

  if (await tables.findPublicReview(reviewId) == null) {
    return _antwort(
      context,
      FunctionResponse.notFound('Diese Bewertung gibt es nicht.'),
    );
  }

  if (await tables.reportExists(reviewId, userId)) {
    return _antwort(
      context,
      FunctionResponse.duplicate('Du hast diese Bewertung schon gemeldet.'),
    );
  }

  final juengst = await tables.countReportsByReporterSince(
    userId,
    reportWindowStart(DateTime.now()),
  );
  if (reportLimitReached(juengst)) {
    ctx.log('Meldelimit erreicht: $juengst in 24 h.');
    return _antwort(
      context,
      FunctionResponse.rateLimited(
        'Du hast heute schon $maxReportsPerWindow Meldungen abgegeben. '
        'Bitte versuch es morgen wieder.',
      ),
    );
  }

  final zeile = await tables.createReport(
    buildReportRow(reviewId: reviewId, reporterId: userId, reason: grund),
    userId,
  );
  ctx.log('Meldung ${zeile.$id} zu Bewertung $reviewId angelegt.');

  return _antwort(context, FunctionResponse.ok({'report_id': zeile.$id}));
}

dynamic _antwort(final context, FunctionResponse antwort) =>
    context.res.json(antwort.payload, antwort.status);
