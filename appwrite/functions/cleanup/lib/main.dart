import 'dart:io';

import 'package:karriko_functions/karriko_functions.dart';

/// Räumt weg, was seine Aufgabe erfüllt hat.
///
/// Läuft täglich. Zwei Dinge, und beide aus demselben Grund: Daten, die
/// niemand mehr braucht, sind kein Bestand, sondern ein Risiko.
///
/// * **Verwaiste Entwürfe.** Ein Entwurf, den seit Monaten niemand angefasst
///   hat, wird nicht mehr fortgesetzt. Er enthält Antworten zu einem Betrieb,
///   die nie abgeschickt wurden — und die niemand jemals sehen sollte.
/// * **Geprüfte Verifikationsnachweise.** Der Nachweis wird gebraucht, um zu
///   belegen, dass ein Ausbildungsverhältnis bestand. Sobald ein Moderator ihn
///   gesehen und die Bewertung entschieden hat, ist er erfüllt. Was bleibt, ist
///   die Kennzeichnung „nachgewiesen" an der Bewertung — nicht das Dokument.
///
/// Die Fristen stehen in der Umgebung, nicht hier. Beide sind in
/// notes/APPWRITE_SETUP.md als **juristisch zu prüfen** gekennzeichnet: Wie
/// lange man einen Nachweis aufbewahren darf und aufbewahren muss, ist keine
/// Entwicklungsfrage.
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

  final client = ctx.adminClient();
  final tables = Tables(client: client, config: ctx.config);
  final jetzt = DateTime.now().toUtc();
  final probelauf = ctx.body['dry_run'] == true;

  // ── Entwürfe ──────────────────────────────────────────────────────────────

  final entwurfsGrenze =
      jetzt.subtract(Duration(days: ctx.config.draftRetentionDays));
  var entwuerfe = 0;

  await for (final row in tables.staleDrafts(entwurfsGrenze)) {
    if (probelauf) {
      entwuerfe++;
      continue;
    }
    try {
      await tables.deleteDraft(row.$id);
      entwuerfe++;
    } catch (e) {
      ctx.logError('Entwurf ${row.$id} nicht geloescht: $e');
    }
  }

  // ── Verifikationsnachweise ────────────────────────────────────────────────

  final nachweisGrenze =
      jetzt.subtract(Duration(days: ctx.config.verificationRetentionDays));
  var nachweise = 0;

  // Nur entschiedene Bewertungen. Ein Nachweis zu einer Bewertung, die noch in
  // der Moderation liegt, wird noch gebraucht — egal wie alt er ist.
  for (final status in [ReviewStatus.approved, ReviewStatus.rejected]) {
    await for (final row in tables.reviewsByStatus(status)) {
      final fileId = row.data['verification_file_id'];
      if (fileId is! String || fileId.isEmpty) continue;

      final entschieden = DateTime.tryParse(row.$updatedAt);
      if (entschieden == null || entschieden.isAfter(nachweisGrenze)) continue;

      if (probelauf) {
        nachweise++;
        continue;
      }

      try {
        await tables.deleteVerificationFile(fileId);
      } catch (e) {
        // Eine Datei, die es nicht mehr gibt, ist kein Fehler — das Feld muss
        // trotzdem weg, sonst versucht der nächste Lauf es wieder.
        ctx.logError('Nachweis $fileId nicht geloescht: $e');
      }

      try {
        await tables.updateReview(row.$id, {
          'verification_file_id': null,
          // Die Kennzeichnung bleibt. Dass ein Nachweis vorlag, ist der Punkt;
          // das Dokument selbst war nur der Weg dorthin.
          'verification_cleared_at': jetzt.toIso8601String(),
        });
        nachweise++;
      } catch (e) {
        ctx.logError('Bewertung ${row.$id} nicht aktualisiert: $e');
      }
    }
  }

  ctx.log(
    '${probelauf ? 'Probelauf: ' : ''}$entwuerfe Entwurf/Entwuerfe aelter als '
    '${ctx.config.draftRetentionDays} Tage, $nachweise Nachweis(e) aelter als '
    '${ctx.config.verificationRetentionDays} Tage nach der Entscheidung.',
  );

  return context.res.json(
    FunctionResponse.ok({
      'drafts_deleted': entwuerfe,
      'verifications_deleted': nachweise,
      'dry_run': probelauf,
      'ran_at': jetzt.toIso8601String(),
    }).payload,
  );
}
