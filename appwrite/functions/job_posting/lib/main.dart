import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' as aw;
import 'package:karriko_functions/karriko_functions.dart';

/// Legt Stellenanzeigen des Aufrufers an, ändert, veröffentlicht, zieht
/// zurück und löscht sie.
///
/// **Warum es diese Function braucht (T-4.31).** Solange der Client direkt in
/// `jobs` schrieb, setzte er `company_id` und die Angaben zum Betrieb selbst.
/// Ein bestätigtes Konto konnte so eine Stelle im Namen eines fremden Betriebs
/// anlegen. Die Tabelle hat deshalb kein Schreibrecht mehr, die Zeilen nur
/// ein Leserecht; geschrieben wird nur hier.
///
/// **Welcher Betrieb, entscheidet der Server:** der, dessen `owner_id` der
/// Aufrufer aus dem geprüften JWT ist, wie bei `company_profile`. Eine Stelle
/// lässt sich nur ändern oder löschen, wenn sie zu diesem Betrieb gehört.
///
/// **Veröffentlichen erst mit Abzeichen.** Entwürfe darf jeder Betrieb
/// anlegen; öffentlich wird eine Stelle erst, wenn die Moderation den Betrieb
/// verifiziert hat (siehe [jobPublishBlocked]).
///
/// Rumpf:
/// * `{"action": "create", "fields": {…}}`
/// * `{"action": "update", "job_id": "…", "fields": {…}}`
/// * `{"action": "set_active", "job_id": "…", "is_active": true}`
/// * `{"action": "delete", "job_id": "…"}`
///
/// Antwort: `{"ok": true, "job": {…}}` wie eine Zeile aus `jobs`, beim
/// Löschen nur `{"ok": true}`.
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
      FunctionResponse.unauthorized('Bitte melde dich an.'),
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

  final action = ctx.body['action'];
  final jobId = ctx.body['job_id'];
  if (action is! String ||
      !const {'create', 'update', 'set_active', 'delete'}.contains(action) ||
      (action != 'create' && (jobId is! String || jobId.isEmpty))) {
    return _antwort(
        context, FunctionResponse.invalid('Unvollständige Anfrage.'));
  }

  final tables = Tables(client: ctx.adminClient(), config: ctx.config);

  try {
    final firma = await tables.companyByOwner(userId);
    if (firma == null) {
      return _antwort(
        context,
        FunctionResponse.forbidden('Zu diesem Konto gibt es kein Unternehmen.'),
      );
    }
    final verifiziert = firma.data['is_verified'] == true;

    // Die bestehende Stelle, und nur wenn sie zu diesem Betrieb gehört. Eine
    // fremde Stelle wird behandelt wie eine, die es nicht gibt: Die Antwort
    // verrät nicht, ob die Kennung existiert.
    aw.Row? stelle;
    if (action != 'create') {
      stelle = await tables.getJob(jobId as String);
      if (stelle == null || stelle.data['company_id'] != firma.$id) {
        ctx.log('$userId: Stelle $jobId nicht gefunden oder fremd.');
        return _antwort(
          context,
          FunctionResponse.notFound('Diese Stelle gibt es nicht.'),
        );
      }
    }

    switch (action) {
      case 'delete':
        await tables.deleteJob(stelle!.$id);
        ctx.log('$userId: Stelle ${stelle.$id} gelöscht.');
        return _antwort(context, FunctionResponse.ok());

      case 'set_active':
        final aktiv = ctx.body['is_active'];
        if (aktiv is! bool) {
          return _antwort(
              context, FunctionResponse.invalid('Unvollständige Anfrage.'));
        }
        final gesperrt =
            jobPublishBlocked(isActive: aktiv, companyVerified: verifiziert);
        if (gesperrt != null) {
          return _antwort(context, FunctionResponse.forbidden(gesperrt));
        }
        final zeile = await tables.updateJob(
          stelle!.$id,
          {'is_active': aktiv},
          isActive: aktiv,
          ownerId: userId,
        );
        ctx.log('$userId: Stelle ${zeile.$id} '
            '${aktiv ? 'veröffentlicht' : 'zurückgezogen'}.');
        return _stelle(context, zeile);

      default: // create, update
        final roh = ctx.body['fields'];
        if (roh is! Map) {
          return _antwort(
              context, FunctionResponse.invalid('Unvollständige Anfrage.'));
        }
        final eingabe =
            parseJobPosting(roh.map((k, v) => MapEntry(k.toString(), v)));
        if (!eingabe.isValid) {
          ctx.log('$userId: abgewiesen – ${eingabe.errors.join('; ')}');
          return _antwort(
            context,
            FunctionResponse.invalid(eingabe.errors.first, eingabe.errors),
          );
        }
        final gesperrt = jobPublishBlocked(
            isActive: eingabe.isActive, companyVerified: verifiziert);
        if (gesperrt != null) {
          return _antwort(context, FunctionResponse.forbidden(gesperrt));
        }

        final daten = {
          ...eingabe.data,
          ...jobCompanyFields(
            companyId: firma.$id,
            company: Map<String, Object?>.from(firma.data),
          ),
        };
        final zeile = action == 'create'
            ? await tables.createJob(daten, ownerId: userId)
            : await tables.updateJob(
                stelle!.$id,
                daten,
                isActive: eingabe.isActive,
                ownerId: userId,
              );
        ctx.log('$userId: Stelle ${zeile.$id} '
            '${action == 'create' ? 'angelegt' : 'geändert'}.');
        return _stelle(context, zeile);
    }
  } on AppwriteException catch (e) {
    ctx.logError('$userId: ${e.code} ${e.type} ${e.message}');
    return _antwort(
      context,
      FunctionResponse.unavailable(
          'Die Stelle konnte nicht gespeichert werden.'),
    );
  }
}

dynamic _stelle(final context, aw.Row zeile) => _antwort(
      context,
      FunctionResponse.ok({
        'job': {
          'id': zeile.$id,
          'created_at': zeile.$createdAt,
          ...zeile.data,
        },
      }),
    );

dynamic _antwort(final context, FunctionResponse antwort) =>
    context.res.json(antwort.payload, antwort.status);
