import 'dart:io';

import 'package:karriko_functions/karriko_functions.dart';

/// Gibt zurückgestellte Bewertungen in die Moderation.
///
/// Läuft stündlich. Was hier passiert, ist nur ein Statuswechsel: Aus
/// `scheduled` wird `pending_moderation`. Veröffentlicht wird dadurch nichts —
/// dazwischen steht immer noch ein Mensch.
///
/// Zwei Wege führen hierher, und beide hat der Azubi selbst gewählt:
///
/// * **Tagesform.** Wer an einem schlechten Tag eine extreme Bewertung schreibt,
///   bekommt das Angebot, in drei Tagen nochmal draufzuschauen. Bis dahin bleibt
///   die Bewertung bearbeitbar.
/// * **Kleinbetrieb.** In einem Betrieb mit einem Azubi kann der Chef erkennen,
///   wer geschrieben hat. Wer deshalb bis nach dem Ausbildungsende warten will,
///   wartet bis dahin.
///
/// Das Datum wird **nicht** gelöscht. Es bleibt als Nachweis stehen, warum eine
/// Bewertung später erschien als sie entstand.
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

  var freigegeben = 0;
  var gescheitert = 0;

  await for (final row in tables.dueScheduledReviews(jetzt)) {
    try {
      await tables.updateReview(row.$id, {
        'status': ReviewStatus.pendingModeration,
      });
      freigegeben++;
    } catch (e) {
      // Eine einzelne Zeile, die nicht will, hält den Lauf nicht an: Beim
      // nächsten Durchgang in einer Stunde ist sie wieder dabei.
      ctx.logError('Bewertung ${row.$id} nicht umgestellt: $e');
      gescheitert++;
    }
  }

  ctx.log(
    freigegeben == 0 && gescheitert == 0
        ? 'Keine faellige Bewertung.'
        : '$freigegeben Bewertung(en) in die Moderation gegeben, '
            '$gescheitert gescheitert.',
  );

  return context.res.json(
    FunctionResponse.ok({
      'released': freigegeben,
      'failed': gescheitert,
      'checked_at': jetzt.toIso8601String(),
    }).payload,
  );
}
