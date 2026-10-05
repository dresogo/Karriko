import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:karriko_functions/karriko_functions.dart';

/// Der Arbeitstisch der Moderation: Übersicht, Warteschlange, Meldungen,
/// Protokoll und Betriebe.
///
/// **Warum es diese Function braucht.** Auf `reviews` hat kein Client Zugriff,
/// auch die Moderation nicht. Bis jetzt hieß das: Die offenen Bewertungen
/// suchte man in der Console heraus. Diese Function liefert sie dem
/// Admin-Bereich, mit genau den Spalten, die für eine Entscheidung nötig sind —
/// was draußen bleibt, steht in [withheldFromModeration].
///
/// **Entschieden wird woanders.** Freigeben und Ablehnen bleibt bei
/// `moderate_review`, damit es genau einen Weg gibt, auf dem eine Bewertung
/// öffentlich wird. Diese Function schreibt nur zwei Dinge: den Status einer
/// Meldung und das Verifizierungs-Kennzeichen eines Betriebs.
///
/// Aufruf mit `{"action": "…"}`:
///
/// | action           | wer         | weitere Felder                           |
/// |------------------|-------------|------------------------------------------|
/// | `overview`       | Moderation  | —                                        |
/// | `queue`          | Moderation  | `status` (Standard `pending_moderation`) |
/// | `reports`        | Moderation  | `filter`: `open` (Standard) oder `all`   |
/// | `resolve_report` | Moderation  | `report_id`, `resolution`, `note`        |
/// | `log`            | Moderation  | —                                        |
/// | `companies`      | Moderation  | `search`                                 |
/// | `verify_company` | nur Admins  | `company_id`, `verified`                 |
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
          'Dieser Bereich ist der Moderation vorbehalten.'),
    );
  }

  final tables = Tables(client: client, config: ctx.config);
  final aktion = ctx.body['action'];

  try {
    final antwort = switch (aktion) {
      'overview' => await _uebersicht(tables, client),
      'queue' => await _warteschlange(tables, ctx.body['status']),
      'reports' => await _meldungen(tables, ctx.body['filter']),
      'resolve_report' => await _meldungErledigen(tables, ctx.body, userId),
      'log' => await _protokoll(tables, client),
      'companies' => await _betriebe(tables, ctx.body['search']),
      'verify_company' => await wache.isAdmin(userId)
          ? await _betriebVerifizieren(tables, ctx.body)
          : FunctionResponse.forbidden(
              'Betriebe verifizieren dürfen nur Administratoren.'),
      _ => FunctionResponse.invalid('Unbekannte action: $aktion'),
    };
    return _antwort(context, antwort);
  } on AppwriteException catch (e) {
    ctx.logError('$aktion: ${e.code} ${e.message}');
    return _antwort(
      context,
      FunctionResponse.unavailable(
        'Die Daten ließen sich nicht laden. Ist das Schema eingespielt?',
      ),
    );
  }
}

// ── Übersicht ───────────────────────────────────────────────────────────────

Future<FunctionResponse> _uebersicht(Tables tables, Client client) async {
  final zahlen = await Future.wait([
    tables.countReviews(ReviewStatus.pendingModeration),
    tables.countReviews(ReviewStatus.scheduled),
    tables.countReviews(ReviewStatus.approved),
    tables.countReviews(ReviewStatus.rejected),
    tables.countOpenReports(),
    tables.countCompanies(),
    tables.countCompanies(verified: false),
  ]);

  final protokoll = await _protokollEintraege(tables, client, limit: 8);

  return FunctionResponse.ok({
    'counts': {
      'pending_moderation': zahlen[0],
      'scheduled': zahlen[1],
      'approved': zahlen[2],
      'rejected': zahlen[3],
      'open_reports': zahlen[4],
      'companies': zahlen[5],
      'companies_unverified': zahlen[6],
    },
    'recent_log': protokoll,
  });
}

// ── Warteschlange ───────────────────────────────────────────────────────────

/// Die Status, die sich in der Warteschlange ansehen lassen. Entwürfe gibt es
/// hier nicht — die liegen in `review_drafts` und gehören ihrem Verfasser.
const _sichtbareStatus = {
  ReviewStatus.pendingModeration,
  ReviewStatus.scheduled,
  ReviewStatus.approved,
  ReviewStatus.rejected,
};

Future<FunctionResponse> _warteschlange(Tables tables, Object? status) async {
  final gewuenscht = status is String && status.isNotEmpty
      ? status
      : ReviewStatus.pendingModeration;
  if (!_sichtbareStatus.contains(gewuenscht)) {
    return FunctionResponse.invalid('Unbekannter Status: $gewuenscht');
  }

  final zeilen = await tables.reviewsWithStatus(gewuenscht, limit: _hoechstens);
  final betriebe = await tables.companiesByIds([
    for (final zeile in zeilen)
      if (zeile.data['company_id'] case final String id) id,
  ].toSet().toList());
  final meldungen =
      await tables.openReportCounts([for (final z in zeilen) z.$id]);

  final eintraege = [
    for (final zeile in zeilen)
      buildQueueEntry(
        reviewId: zeile.$id,
        reviewRow: Map<String, Object?>.from(zeile.data),
        submittedAt: zeile.$createdAt,
        companyName:
            betriebe[zeile.data['company_id']]?.data['name'] as String?,
        companySlug:
            betriebe[zeile.data['company_id']]?.data['slug'] as String?,
        reportCount: meldungen[zeile.$id] ?? 0,
      ),
  ];

  // Die Warteschlange älteste zuerst: Wer am längsten wartet, kommt zuerst
  // dran. Die anderen Listen neueste zuerst.
  sortNewestFirst(eintraege, 'submitted_at');
  final sortiert = gewuenscht == ReviewStatus.pendingModeration
      ? eintraege.reversed.toList()
      : eintraege;

  return FunctionResponse.ok({
    'status': gewuenscht,
    'reviews': sortiert,
    if (zeilen.length >= _hoechstens) 'truncated': true,
  });
}

// ── Meldungen ───────────────────────────────────────────────────────────────

Future<FunctionResponse> _meldungen(Tables tables, Object? filter) async {
  final nurOffene = filter != 'all';
  final zeilen = await tables.reports(nurOffene: nurOffene, limit: _hoechstens);

  // Eine Meldung trägt entweder die interne oder die öffentliche Kennung. Erst
  // als interne versuchen, den Rest über die öffentliche Zeile auflösen.
  final gemeldet = {
    for (final zeile in zeilen)
      if (zeile.data['review_id'] case final String id) id,
  }.toList();

  final intern = await tables.reviewsByIds(gemeldet);
  final rest = [
    for (final id in gemeldet)
      if (!intern.containsKey(id)) id
  ];
  final oeffentlichNachZeile = await tables.publicReviewsByRowIds(rest);

  // Zuordnung gemeldete Kennung → interne Kennung.
  final aufgeloest = <String, String>{
    for (final id in intern.keys) id: id,
    for (final eintrag in oeffentlichNachZeile.entries)
      if (eintrag.value.data['review_id'] case final String internId)
        eintrag.key: internId,
  };
  final nachgeladen = await tables.reviewsByIds([
    for (final internId in aufgeloest.values)
      if (!intern.containsKey(internId)) internId,
  ]);
  final bewertungen = {...intern, ...nachgeladen};

  final oeffentlich =
      await tables.publicReviewsByIds(bewertungen.keys.toList());
  final betriebe = await tables.companiesByIds({
    for (final b in bewertungen.values)
      if (b.data['company_id'] case final String id) id,
  }.toList());

  final eintraege = <Map<String, Object?>>[];
  for (final zeile in zeilen) {
    final gemeldeteId = zeile.data['review_id'] as String?;
    final internId = aufgeloest[gemeldeteId];
    final bewertung = bewertungen[internId];
    final betrieb = betriebe[bewertung?.data['company_id']];
    eintraege.add(
      buildReportEntry(
        reportId: zeile.$id,
        reportRow: Map<String, Object?>.from(zeile.data),
        createdAt: zeile.$createdAt,
        reviewId: internId,
        review: bewertung == null
            ? null
            : Map<String, Object?>.from(bewertung.data),
        publicReviewId: oeffentlich[internId]?.$id,
        companyName: betrieb?.data['name'] as String?,
        companySlug: betrieb?.data['slug'] as String?,
      ),
    );
  }
  sortNewestFirst(eintraege, 'created_at');

  return FunctionResponse.ok({
    'filter': nurOffene ? 'open' : 'all',
    'reports': eintraege,
    if (zeilen.length >= _hoechstens) 'truncated': true,
  });
}

Future<FunctionResponse> _meldungErledigen(
  Tables tables,
  Map<String, Object?> body,
  String userId,
) async {
  final id = body['report_id'];
  final ergebnis = body['resolution'];
  final notiz = body['note'];

  if (id is! String || id.isEmpty) {
    return FunctionResponse.invalid('report_id fehlt.');
  }
  if (!ReportStatus.resolved.contains(ergebnis)) {
    return FunctionResponse.invalid(
        'resolution muss "dismissed" oder "actioned" sein.');
  }

  await tables.resolveReport(
    id,
    status: ergebnis as String,
    resolvedBy: userId,
    note: notiz is String ? notiz : null,
  );
  return FunctionResponse.ok({'status': ergebnis});
}

// ── Protokoll ───────────────────────────────────────────────────────────────

Future<FunctionResponse> _protokoll(Tables tables, Client client) async =>
    FunctionResponse.ok({
      'entries': await _protokollEintraege(tables, client, limit: _hoechstens),
    });

Future<List<Map<String, Object?>>> _protokollEintraege(
  Tables tables,
  Client client, {
  required int limit,
}) async {
  final zeilen = await tables.recentModerationLog(limit: limit);
  if (zeilen.isEmpty) return const [];

  final bewertungen = await tables.reviewsByIds({
    for (final z in zeilen)
      if (z.data['review_id'] case final String id) id,
  }.toList());
  final betriebe = await tables.companiesByIds({
    for (final b in bewertungen.values)
      if (b.data['company_id'] case final String id) id,
  }.toList());
  final namen = await _namen(
      client,
      {
        for (final z in zeilen)
          if (z.data['moderator_id'] case final String id) id,
      }.toList());

  final eintraege = [
    for (final zeile in zeilen)
      buildLogEntry(
        logId: zeile.$id,
        logRow: Map<String, Object?>.from(zeile.data),
        fallbackCreatedAt: zeile.$createdAt,
        companyName:
            betriebe[bewertungen[zeile.data['review_id']]?.data['company_id']]
                ?.data['name'] as String?,
        moderatorName: namen[zeile.data['moderator_id']],
      ),
  ];
  sortNewestFirst(eintraege, 'created_at');
  return eintraege;
}

/// Anzeigenamen der Moderatoren. Schlägt das fehl, bleibt es bei der Kennung —
/// ein fehlender Name ist kein Grund, das Protokoll nicht zu zeigen.
Future<Map<String, String>> _namen(Client client, List<String> ids) async {
  if (ids.isEmpty) return const {};
  try {
    final liste = await Users(client).list(
      queries: [Query.equal(r'$id', ids), Query.limit(ids.length)],
    );
    return {
      for (final nutzer in liste.users)
        nutzer.$id: nutzer.name.isNotEmpty ? nutzer.name : nutzer.email,
    };
  } catch (_) {
    return const {};
  }
}

// ── Betriebe ────────────────────────────────────────────────────────────────

Future<FunctionResponse> _betriebe(Tables tables, Object? suche) async {
  final zeilen = await tables.companies(
    suche: suche is String ? suche : null,
    limit: _hoechstens,
  );
  return FunctionResponse.ok({
    'companies': [
      for (final zeile in zeilen)
        buildCompanyEntry(
          companyId: zeile.$id,
          companyRow: Map<String, Object?>.from(zeile.data),
          createdAt: zeile.$createdAt,
        ),
    ],
    if (zeilen.length >= _hoechstens) 'truncated': true,
  });
}

Future<FunctionResponse> _betriebVerifizieren(
  Tables tables,
  Map<String, Object?> body,
) async {
  final id = body['company_id'];
  final verifiziert = body['verified'];
  if (id is! String || id.isEmpty) {
    return FunctionResponse.invalid('company_id fehlt.');
  }
  if (verifiziert is! bool) {
    return FunctionResponse.invalid('verified muss wahr oder falsch sein.');
  }
  await tables.setCompanyVerified(id, verifiziert);
  return FunctionResponse.ok({'is_verified': verifiziert});
}

/// Wie viele Zeilen eine Liste höchstens zurückgibt.
const _hoechstens = 100;

dynamic _antwort(final context, FunctionResponse antwort) =>
    context.res.json(antwort.payload, antwort.status);
