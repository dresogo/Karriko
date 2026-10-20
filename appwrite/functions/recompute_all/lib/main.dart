import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart' show ExecutionMethod;
import 'package:karriko_functions/karriko_functions.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

/// Rechnet alle Werte mit den aktuellen Parametern neu.
///
/// Nur für das Team `admins`, und nur von Hand. Wird gebraucht, wenn sich an der
/// Definition etwas geändert hat, was die Auswertung betrifft: ein Punktwert,
/// ein Gewicht, die Schrumpfungsstärke, die Alterungsgrenze. Ohne diesen Lauf
/// stünden alte und neue Bewertungen auf verschiedenen Maßstäben.
///
/// **Idempotent.** Zweimal laufen lassen ändert nichts am Ergebnis: Die
/// Berechnung geht immer von den Rohantworten aus, nie von einem vorherigen
/// Ergebnis.
///
/// **In Etappen.** Der Lauf verarbeitet höchstens [_stapelGroesse] Bewertungen
/// und gibt den nächsten Versatz zurück. Läuft die Function in ein Timeout, ruft
/// man sie mit diesem Versatz wieder auf, statt von vorn anzufangen.
///
/// **Danach die Betriebe (T-2.21).** Am Ende jedes Stapels wird
/// `aggregate_company` für jeden darin betroffenen Betrieb einmal angestoßen,
/// asynchron, damit dieser Lauf nicht auf die Aggregation wartet. Über die
/// Ereignisse an `public_reviews` liefe sie zwar oft ohnehin, aber nicht
/// verlässlich: Ändert sich nur ein Parameter der Aggregation (etwa die
/// Alterungsgrenze), ändern sich die Zeilen womöglich gar nicht. Ein Betrieb,
/// dessen Bewertungen über zwei Stapel verteilt sind, wird zweimal angestoßen;
/// die Aggregation ist idempotent, der zweite Lauf sieht den fertigen Stand.
///
/// Abweichung vom Plan: Dort war vorgesehen, den Fortschritt in einer Zeile in
/// `company_scores` zu merken. Der Versatz im Aufruf ist einfacher und hat
/// keinen Zustand, der zwischen zwei Läufen veralten kann.
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
  if (!await wache.isAdmin(userId)) {
    ctx.logError('$userId ist kein Admin.');
    return _antwort(
      context,
      FunctionResponse.forbidden(
          'Diese Aktion ist Administratoren vorbehalten.'),
    );
  }

  final versatz = (ctx.body['offset'] as num?)?.round() ?? 0;
  final probelauf = ctx.body['dry_run'] == true;

  final tables = Tables(client: client, config: ctx.config);
  final loader = DefinitionLoader(client: client, config: ctx.config);

  var gesehen = 0;
  var neuGerechnet = 0;
  var uebersprungen = 0;
  final betriebe = <String>{};

  // Welche Versionen sich nicht laden liessen. Ohne das Gedaechtnis wuerde eine
  // kaputte Version fuer jede einzelne Bewertung erneut heruntergeladen — der
  // Zwischenspeicher im Loader merkt sich nur Erfolge.
  final unbrauchbar = <int, String>{};

  await for (final row in tables.reviewsByStatus(ReviewStatus.approved)) {
    gesehen++;
    if (gesehen <= versatz) continue;
    if (neuGerechnet + uebersprungen >= _stapelGroesse) break;

    final version = (row.data['schema_version'] as num?)?.round();
    if (version == null) {
      uebersprungen++;
      continue;
    }

    if (unbrauchbar.containsKey(version)) {
      uebersprungen++;
      continue;
    }

    final Questionnaire fassung;
    try {
      fassung = await loader.load(version);
    } on DefinitionException catch (e) {
      // Einmal melden, nicht je Bewertung. Bei tausend Zeilen derselben Version
      // waeren das tausend gleichlautende Zeilen im Protokoll.
      unbrauchbar[version] = e.toString();
      ctx.logError('Version $version nicht verwendbar: $e');
      uebersprungen++;
      continue;
    }

    final answers = Answers.from(decodeJsonColumn(row.data['answers_json']));
    final timings = <String, int>{
      for (final eintrag in decodeJsonColumn(row.data['timings_json']).entries)
        if (eintrag.value is num) eintrag.key: (eintrag.value! as num).round(),
    };

    final scores = ReviewScores.compute(fassung, answers);
    final flags = evaluateQuality(
      questionnaire: fassung,
      answers: answers,
      timings: timings,
      scores: scores,
    );

    final companyId = row.data['company_id'];
    if (companyId is String) betriebe.add(companyId);

    if (probelauf) {
      neuGerechnet++;
      continue;
    }

    // Nur die gerechneten Spalten. Status, Rohantworten und alles, was ein
    // Mensch entschieden hat, bleibt unangetastet — ein Neuberechnen ist keine
    // erneute Moderation.
    await tables.updateReview(row.$id, {
      'detail_overall': scores.detailOverall,
      for (final eintrag in subscoreColumns.entries)
        eintrag.value: scores.subscores[eintrag.key],
      for (final eintrag in separateColumns.entries)
        eintrag.value: scores.separate[eintrag.key],
      'quality_flags': [for (final flag in flags) flag.code],
      'quality_notes': [
        for (final flag in flags) '${flag.code}: ${flag.reason}',
      ],
    });

    // Die öffentliche Zeile trägt dieselben Werte und muss mitziehen, sonst
    // zeigte das Profil die alten.
    final oeffentlich = await tables.findPublicReview(row.$id);
    if (oeffentlich != null) {
      await tables.db.updateRow(
        databaseId: ctx.config.databaseId,
        tableId: ctx.config.publicReviewsTable,
        rowId: oeffentlich.$id,
        data: {
          for (final eintrag in subscoreColumns.entries)
            eintrag.value: scores.subscores[eintrag.key],
          for (final eintrag in separateColumns.entries)
            eintrag.value: scores.separate[eintrag.key],
        },
      );
    }

    neuGerechnet++;
  }

  final fertig = neuGerechnet + uebersprungen < _stapelGroesse;

  // Im Probelauf wird nichts angestoßen: Er soll nur zählen.
  final angestossen = <String>[];
  if (!probelauf) {
    final functions = Functions(client);
    for (final betrieb in betriebe) {
      try {
        await functions.createExecution(
          functionId: ctx.config.aggregateFunction,
          body: jsonEncode({'company_id': betrieb}),
          xasync: true,
          method: ExecutionMethod.pOST,
          path: '/',
        );
        angestossen.add(betrieb);
      } catch (e) {
        // Kein Abbruch: Die Bewertungen sind neu gerechnet. Der Betrieb steht
        // in `companies` und lässt sich von Hand nachholen.
        ctx.logError('aggregate_company für $betrieb nicht angestoßen: $e');
      }
    }
  }

  ctx.log(
    '${probelauf ? 'Probelauf: ' : ''}$neuGerechnet neu gerechnet, '
    '$uebersprungen uebersprungen, ${betriebe.length} Betrieb(e) betroffen. '
    '${fertig ? 'Fertig.' : 'Weiter ab Versatz ${versatz + neuGerechnet + uebersprungen}.'}',
  );

  return _antwort(
    context,
    FunctionResponse.ok({
      'recomputed': neuGerechnet,
      'skipped': uebersprungen,
      // Ohne diese Liste sähe ein Lauf, in dem jede Bewertung übersprungen
      // wurde, wie ein erfolgreicher mit nichts zu tun aus.
      if (unbrauchbar.isNotEmpty)
        'unusable_versions': {
          for (final eintrag in unbrauchbar.entries)
            eintrag.key.toString(): eintrag.value,
        },
      'companies': betriebe.toList(),
      'done': fertig,
      if (!fertig) 'next_offset': versatz + neuGerechnet + uebersprungen,
      'dry_run': probelauf,
      // Für diese Betriebe läuft `aggregate_company` jetzt im Hintergrund.
      // Fehlt einer aus `companies`, ließ er sich nicht anstoßen (siehe Log).
      'aggregation_started': angestossen,
    }),
  );
}

/// Wie viele Bewertungen ein Aufruf verarbeitet.
///
/// Klein gehalten, damit ein Lauf verlässlich innerhalb des Timeouts bleibt.
/// Jede Bewertung kostet einen Schreibvorgang, oft zwei.
const _stapelGroesse = 100;

dynamic _antwort(final context, FunctionResponse antwort) =>
    context.res.json(antwort.payload, antwort.status);
