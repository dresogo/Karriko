import 'dart:io';

import 'package:karriko_functions/karriko_functions.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

/// Rechnet die Aggregate eines Betriebs neu.
///
/// Ausgelöst durch Änderungen an `public_reviews` — also genau dann, wenn eine
/// Bewertung freigegeben oder zurückgezogen wurde.
///
/// **Die Quelle ist trotzdem `reviews`, nicht `public_reviews`.** Das sieht nach
/// einem Widerspruch aus und ist keiner: Die Gewichte des Gesamtscores entstehen
/// aus den aggregierten K12-Prioritäten aller Bewerter dieses Betriebs, und die
/// stehen in den Rohantworten. Sie nach `public_reviews` zu kopieren, nur damit
/// diese Function sie lesen kann, hieße drei von acht Prioritätskarten je Azubi
/// zu veröffentlichen — eine Angabe mehr, die niemand gebraucht hätte.
///
/// Idempotent: Wiederholt Appwrite ein Ereignis, kommt dasselbe Ergebnis heraus.
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

  final companyId = _betrieb(ctx);
  if (companyId == null) {
    ctx.logError('Kein company_id im Ereignis und keines im Rumpf.');
    return context.res.json(
      FunctionResponse.invalid('company_id fehlt.').payload,
      400,
    );
  }

  final client = ctx.adminClient();
  final tables = Tables(client: client, config: ctx.config);
  final loader = DefinitionLoader(client: client, config: ctx.config);

  // Die Parameter der Berechnung — Schwellen, Untergrenzen, Schrumpfungsstärke,
  // Alterungsgrenze — kommen aus der aktiven Definition. Sie gelten für die
  // Anzeige und nicht für die einzelne Einreichung; deshalb hier die aktive und
  // nicht die Version der jeweiligen Bewertung.
  final Questionnaire aktiv;
  try {
    aktiv = await loader.loadActive();
  } on DefinitionException catch (e) {
    ctx.logError(e.toString());
    return context.res.json(
      FunctionResponse.unavailable('Keine aktive Fragebogenversion.').payload,
      503,
    );
  }

  final eingaben = <AggregateInput>[];
  final zahlen = <String, List<num>>{};

  await for (final row in tables.reviewsByStatus(ReviewStatus.approved)) {
    if (row.data['company_id'] != companyId) continue;

    final version = (row.data['schema_version'] as num?)?.round();
    if (version == null) continue;

    final Questionnaire fassung;
    try {
      fassung = await loader.load(version);
    } on DefinitionException catch (e) {
      // Eine einzelne unlesbare Fassung darf den Betriebsscore nicht kippen.
      ctx.logError('Bewertung ${row.$id} uebersprungen: $e');
      continue;
    }

    final answers = Answers.from(decodeJsonColumn(row.data['answers_json']));
    final prioritaeten = _prioritaeten(fassung, answers);

    final eingabe = aggregateInputFromRow(
      {
        ...row.data,
        // Für die Alterung zählt das Einreichen, nicht die Freigabe.
        'published_at': row.$createdAt,
      },
      priorities: prioritaeten,
    );
    if (eingabe != null) eingaben.add(eingabe);

    _zahlenSammeln(aktiv, fassung, answers, zahlen);
  }

  final aggregat = CompanyAggregate.compute(
    questionnaire: aktiv,
    reviews: eingaben,
    now: DateTime.now().toUtc(),
  );

  final mittel = <String, num>{
    for (final eintrag in zahlen.entries)
      if (eintrag.value.isNotEmpty)
        eintrag.key:
            eintrag.value.reduce((a, b) => a + b) / eintrag.value.length,
  };

  await tables.upsertCompanyScores(
    companyId,
    buildCompanyScoresRow(
      aggregat,
      questionnaire: aktiv,
      zahlenangaben: mittel,
    ),
  );

  ctx.log(
    'Betrieb $companyId: ${aggregat.reviewCount} Bewertungen, '
    '${aggregat.agedCount} davon alt, Score '
    '${aggregat.scoreVisible ? aggregat.overall?.toStringAsFixed(2) : 'noch nicht sichtbar'}.',
  );

  return context.res.json(
    FunctionResponse.ok({
      'company_id': companyId,
      'review_count': aggregat.reviewCount,
      'score_visible': aggregat.scoreVisible,
    }).payload,
  );
}

/// Der Betrieb, um den es geht.
///
/// Beim Ereignis-Auslöser steckt er in der geänderten Zeile, beim Aufruf von
/// Hand im Rumpf. Beide Wege müssen funktionieren: Ohne den zweiten ließe sich
/// ein Betrieb nach einer Parameteränderung nicht einzeln nachrechnen.
String? _betrieb(RunContext ctx) {
  final ausRumpf = ctx.body['company_id'];
  if (ausRumpf is String && ausRumpf.isNotEmpty) return ausRumpf;

  final daten = ctx.eventData;
  final ausEreignis = daten?['company_id'];
  return ausEreignis is String && ausEreignis.isNotEmpty ? ausEreignis : null;
}

/// Die ersten N Prioritäten aus K12.
List<String> _prioritaeten(Questionnaire questionnaire, Answers answers) {
  final wert = answers[questionnaire.flow.priorityQuestionId];
  if (wert is! List) return const [];
  return [
    for (final eintrag in wert.take(questionnaire.flow.priorityTopN))
      if (eintrag is String) eintrag,
  ];
}

/// Sammelt die Zahlenangaben, aus denen später Spannen werden.
///
/// Welche Frage welche Angabe liefert, steht in `visibility.numberSources` der
/// Definition — diese Function weiß nicht, dass die Vergütung in
/// `mod_geld_verguetung` steht.
void _zahlenSammeln(
  Questionnaire aktiv,
  Questionnaire fassung,
  Answers answers,
  Map<String, List<num>> ziel,
) {
  aktiv.visibility.numberSources.forEach((schluessel, frageId) {
    if (fassung.question(frageId) == null) return;
    final wert = answers[frageId];
    if (wert is num) {
      ziel.putIfAbsent(schluessel, () => []).add(wert);
    }
  });
}
