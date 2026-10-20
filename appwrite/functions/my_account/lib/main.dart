import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:karriko_functions/karriko_functions.dart';

/// Die Rechte eines Kontos an seinen eigenen Daten: Löschen (T-2.8, Art. 17),
/// eine eigene Bewertung löschen (T-2.9) und Export (T-2.10, Art. 20).
///
/// **Wessen Daten, entscheidet der Server.** Wie bei `my_reviews` kommt die
/// Nutzerkennung aus dem geprüften JWT (`x-appwrite-user-id`), nie aus dem
/// Rumpf. Eine Kennung im Rumpf wäre eine Einladung, fremde Konten zu löschen
/// oder fremde Daten herunterzuladen.
///
/// **Keine bestätigte Adresse nötig.** Löschen und Auskunft stehen jedem
/// Konto zu, auch einem, das nie bestätigt wurde.
///
/// Rumpf `{"action": …}`:
/// * `status`: ob eine Löschung beantragt ist und wann sie greift
/// * `request_deletion`: Löschung beantragen; endgültig nach 14 Tagen
///   (E-50), ausgeführt von `cleanup`
/// * `cancel_deletion`: Antrag zurücknehmen
/// * `delete_review` mit `review_id`: eine eigene Bewertung vollständig löschen
/// * `export`: alle selbst eingegebenen Daten als JSON
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
        context, FunctionResponse.unauthorized('Bitte melde dich an.'));
  }

  final client = ctx.adminClient();
  final tables = Tables(client: client, config: ctx.config);
  final users = Users(client);

  try {
    switch (ctx.body['action']) {
      case 'status':
        return _antwort(context, await _status(tables, userId));

      case 'request_deletion':
        // Betriebskonten haben eigene Regeln (T-2.24) und gehen vorerst über
        // den Support. Entschieden mit dem Nutzer am 20.10.2026.
        if (await tables.companyByOwner(userId) != null) {
          return _antwort(
            context,
            FunctionResponse.forbidden(
              'Ein Betriebskonto lässt sich hier noch nicht löschen. Bitte '
              'wende dich an den Support.',
            ),
          );
        }
        if (await tables.getDeletionRequest(userId) == null) {
          final jetzt = DateTime.now().toUtc();
          final faellig =
              deletionDueAt(jetzt, graceDays: ctx.config.deletionGraceDays);
          await tables.createDeletionRequest(
            userId: userId,
            requestedAt: jetzt,
            deleteAfter: faellig,
          );
          await _prefSetzen(users, userId, faellig.toIso8601String());
          ctx.log('Löschung beantragt.');
        }
        return _antwort(context, await _status(tables, userId));

      case 'cancel_deletion':
        try {
          await tables.deleteRow(ctx.config.accountDeletionsTable, userId);
        } on AppwriteException catch (e) {
          if (e.code != 404) rethrow;
        }
        await _prefSetzen(users, userId, null);
        ctx.log('Löschung zurückgenommen.');
        return _antwort(context, await _status(tables, userId));

      case 'delete_review':
        final reviewId = ctx.body['review_id'];
        if (reviewId is! String || reviewId.isEmpty) {
          return _antwort(
              context, FunctionResponse.invalid('Unvollständige Anfrage.'));
        }
        final zeile = await _eigeneBewertung(tables, userId, reviewId);
        if (zeile == null) {
          // Fremd oder nicht vorhanden: dieselbe Antwort.
          return _antwort(context,
              FunctionResponse.notFound('Diese Bewertung gibt es nicht.'));
        }
        final datei = zeile.data['verification_file_id'];
        if (datei is String && datei.isNotEmpty) {
          try {
            await tables.deleteVerificationFile(datei);
          } on AppwriteException catch (e) {
            if (e.code != 404) rethrow;
          }
        }
        await deleteReviewCompletely(tables: tables, reviewRowId: zeile.$id);
        ctx.log('Bewertung ${zeile.$id} auf Wunsch gelöscht.');
        return _antwort(context, FunctionResponse.ok());

      case 'export':
        return _antwort(
          context,
          FunctionResponse.ok({'export': await _export(tables, users, userId)}),
        );

      default:
        return _antwort(
            context, FunctionResponse.invalid('Unvollständige Anfrage.'));
    }
  } on AppwriteException catch (e) {
    ctx.logError('${e.code} ${e.type} ${e.message}');
    return _antwort(
      context,
      FunctionResponse.unavailable(
          'Das hat gerade nicht geklappt. Bitte versuch es später noch einmal.'),
    );
  }
}

Future<FunctionResponse> _status(Tables tables, String userId) async {
  final antrag = await tables.getDeletionRequest(userId);
  return FunctionResponse.ok({
    'deletion': antrag == null
        ? null
        : {
            'requested_at': antrag.data['requested_at'],
            'delete_after': antrag.data['delete_after'],
          },
  });
}

/// Hält den Löschtermin zusätzlich in den Prefs, damit die App ihn ohne
/// zweiten Aufruf kennt und nur noch die Rücknahme-Seite zeigt. Maßgeblich
/// ist allein die Zeile in `account_deletions`; wer die Pref von Hand löscht,
/// nimmt damit nichts zurück.
Future<void> _prefSetzen(Users users, String userId, String? wert) async {
  final prefs =
      Map<String, Object?>.from((await users.getPrefs(userId: userId)).data);
  if (wert == null) {
    prefs.remove(accountDeletionPref);
  } else {
    prefs[accountDeletionPref] = wert;
  }
  await users.updatePrefs(userId: userId, prefs: prefs);
}

Future<dynamic> _eigeneBewertung(
    Tables tables, String userId, String reviewId) async {
  try {
    final zeile = await tables.getReview(reviewId);
    return zeile.data['user_id'] == userId ? zeile : null;
  } on AppwriteException catch (e) {
    if (e.code == 404) return null;
    rethrow;
  }
}

Future<Map<String, Object?>> _export(
    Tables tables, Users users, String userId) async {
  final konto = await users.get(userId: userId);
  final profil = await tables.getProfile(userId);
  final bewertungen = await tables.allReviewsByUser(userId);
  final entwuerfe = await tables.draftsByUser(userId);
  final merkliste = await tables.bookmarksByUser(userId);
  final meldungen = await tables.reportsByReporter(userId);

  final betriebe = await tables.companiesByIds({
    for (final z in [...bewertungen, ...entwuerfe, ...merkliste])
      if (z.data['company_id'] case final String id) id,
  }.toList());

  ExportRow zeile(dynamic z) => ExportRow(z.$id as String,
      z.$createdAt as String, Map<String, Object?>.from(z.data as Map));

  return buildAccountExport(
    exportedAt: DateTime.now(),
    account: {
      'name': konto.name,
      'email': konto.email,
      'email_verified': konto.emailVerification,
      'registered_at': konto.registration,
      'prefs': konto.prefs.data,
    },
    profile: profil == null ? null : Map<String, Object?>.from(profil.data),
    reviews: [for (final z in bewertungen) zeile(z)],
    drafts: [for (final z in entwuerfe) zeile(z)],
    bookmarks: [for (final z in merkliste) zeile(z)],
    reports: [for (final z in meldungen) zeile(z)],
    companyNames: {
      for (final e in betriebe.entries)
        if (e.value.data['name'] case final String name) e.key: name,
    },
  );
}

dynamic _antwort(final context, FunctionResponse antwort) =>
    context.res.json(antwort.payload, antwort.status);
