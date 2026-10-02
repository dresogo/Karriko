import 'dart:io';

import 'package:karriko_functions/karriko_functions.dart';

/// Listet die Bewertungen auf, die der Aufrufer selbst abgeschickt hat.
///
/// **Warum es diese Function braucht.** `public_reviews` trägt keine `user_id`,
/// und auf `reviews` hat kein Client Zugriff — auch der Verfasser nicht. Das ist
/// der Kern der Trennung: Eine öffentlich lesbare Zeile, die auf ein Konto
/// zeigt, wäre keine anonyme Bewertung. Der Preis war bisher, dass ein Azubi
/// seine abgeschickten Bewertungen nur in dem Browser wiederfand, aus dem er sie
/// abgeschickt hatte.
///
/// Diese Function löst das, ohne die Trennung aufzugeben: Die Zuordnung
/// entsteht **nur hier, nur für die Dauer des Aufrufs**, und sie entsteht aus
/// dem angemeldeten Nutzer.
///
/// **Die Nutzerkennung kommt aus dem Aufruf, nicht aus dem Rumpf.** Appwrite
/// setzt `x-appwrite-user-id` aus dem geprüften JWT; das ist der Punkt, an dem
/// alles hängt. Eine `user_id` im Rumpf wäre eine Einladung, die Bewertungen
/// anderer zu lesen. Es gibt deshalb keinen Parameter dafür, und es darf auch
/// keinen geben.
///
/// **Sie schreibt nichts.** Ihr Schlüssel hat nur `rows.read`. Eine Function,
/// die nur liest, kann keine Bewertung verändern — und das ist hier keine
/// Sparsamkeit, sondern die Eigenschaft, die sie harmlos macht.
///
/// Was zurückgeht und was absichtlich fehlt, entscheidet
/// [buildOwnReviewEntry]; die Begründung je Feld steht in
/// [withheldFromAuthor].
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
      FunctionResponse.unauthorized(
        'Bitte melde dich an, um deine Bewertungen zu sehen.',
      ),
    );
  }

  final client = ctx.adminClient();
  final tables = Tables(client: client, config: ctx.config);

  final zeilen = await tables.reviewsByUser(userId, limit: _hoechstens);

  if (zeilen.isEmpty) {
    return _antwort(context, FunctionResponse.ok({'reviews': const []}));
  }

  final ids = [for (final zeile in zeilen) zeile.$id];
  final betriebsIds = <String>{
    for (final zeile in zeilen)
      if (zeile.data['company_id'] case final String id) id,
  }.toList();

  // Drei Abfragen für alle Zeilen zusammen, nicht drei je Zeile.
  final oeffentlich = await tables.publicReviewsByIds(ids);
  final betriebe = await tables.companiesByIds(betriebsIds);

  // Begründungen nur für die abgelehnten. Für die anderen gibt es keine, und
  // das Protokoll der Moderation wird nicht ohne Grund gelesen.
  final abgelehnt = [
    for (final zeile in zeilen)
      if (zeile.data['status'] == ReviewStatus.rejected) zeile.$id,
  ];
  final gruende = await tables.rejectionReasons(abgelehnt);

  final eintraege = <Map<String, Object?>>[];
  for (final zeile in zeilen) {
    final betrieb = betriebe[zeile.data['company_id']];
    final oeff = oeffentlich[zeile.$id];

    eintraege.add(
      buildOwnReviewEntry(
        reviewId: zeile.$id,
        reviewRow: Map<String, Object?>.from(zeile.data),
        submittedAt: zeile.$createdAt,
        companyName: betrieb?.data['name'] as String?,
        companySlug: betrieb?.data['slug'] as String?,
        publicReviewId: oeff?.$id,
        publishedAt: oeff?.data['published_at'] as String?,
        rejectionReason: gruende[zeile.$id],
      ),
    );
  }

  // Sortiert wird hier und nicht in der Abfrage: Ein `orderDesc` auf
  // `$createdAt` verlangte einen eigenen Index, und bei höchstens einer
  // Bewertung je Betrieb ist die Liste kurz.
  eintraege.sort((a, b) {
    final x = a['submitted_at'] as String? ?? '';
    final y = b['submitted_at'] as String? ?? '';
    return y.compareTo(x);
  });

  ctx.log('$userId: ${eintraege.length} eigene Bewertung(en).');

  return _antwort(
    context,
    FunctionResponse.ok({
      'reviews': eintraege,
      // Ehrlich statt stillschweigend abgeschnitten. Wer mehr Betriebe bewertet
      // hat als die Obergrenze, soll es erfahren.
      if (zeilen.length >= _hoechstens) 'truncated': true,
    }),
  );
}

/// Wie viele Bewertungen ein Aufruf zurückgibt.
///
/// Je Nutzer und Betrieb gibt es höchstens eine — wer hundert Betriebe bewertet
/// hat, ist ein Fall für die Moderation und nicht für eine längere Liste.
const _hoechstens = 100;

dynamic _antwort(final context, FunctionResponse antwort) =>
    context.res.json(antwort.payload, antwort.status);
