import 'package:dart_appwrite/dart_appwrite.dart';

import 'account_data.dart';
import 'tables.dart';

/// Löscht ein Konto endgültig, nachdem die Frist aus E-50 abgelaufen ist.
///
/// Aufgerufen von `cleanup` für jeden fälligen Antrag in `account_deletions`.
/// Die Reihenfolge ist so gewählt, dass ein Abbruch in der Mitte nichts
/// Halbes hinterlässt, das sich nicht nachholen ließe: Der Antrag wird erst
/// ganz am Ende entfernt, der nächste Lauf fängt also von vorn an, und jeder
/// Schritt verträgt es, schon erledigt zu sein.
///
/// 1. Bewertungen: veröffentlichte bleiben ohne Nutzerbezug und ohne
///    Gerätehash stehen ([detachReviewFromUser]), alle anderen werden samt
///    Nachweis und Meldungen gelöscht ([keepReviewOnAccountDeletion]).
/// 2. Entwürfe und Merkliste werden gelöscht.
/// 3. Eigene Meldungen bleiben für die Moderation stehen, tragen aber statt
///    der Nutzerkennung einen Platzhalter.
/// 4. Die Profilzeile wird gelöscht.
/// 5. Das Appwrite-Konto wird gelöscht; damit enden alle Sitzungen und die
///    Prefs.
/// 6. Der Antrag selbst wird gelöscht. Es bleibt keine Zeile, die das Konto
///    nennt.
///
/// Konten, denen inzwischen eine Firma gehört, werden übersprungen: Für
/// Betriebskonten gilt T-2.24, nicht dieser Weg.
Future<PurgeResult> purgeAccount({
  required Tables tables,
  required Users users,
  required String userId,
  required void Function(String) log,
}) async {
  if (await tables.companyByOwner(userId) != null) {
    log('Konto mit Firma übersprungen (T-2.24).');
    return PurgeResult.skipped;
  }

  var behalten = 0;
  var geloescht = 0;
  for (final zeile in await tables.allReviewsByUser(userId)) {
    final datei = zeile.data['verification_file_id'];
    if (datei is String && datei.isNotEmpty) {
      await _ohne404(() => tables.deleteVerificationFile(datei));
    }
    if (keepReviewOnAccountDeletion(zeile.data['status'] as String?)) {
      await tables.updateRowData(tables.config.reviewsTable, zeile.$id,
          detachReviewFromUser(zeile.$id));
      behalten++;
    } else {
      await deleteReviewCompletely(tables: tables, reviewRowId: zeile.$id);
      geloescht++;
    }
  }

  for (final zeile in await tables.draftsByUser(userId)) {
    await _ohne404(() => tables.deleteDraft(zeile.$id));
  }
  for (final zeile in await tables.bookmarksByUser(userId)) {
    await _ohne404(
        () => tables.deleteRow(tables.config.bookmarksTable, zeile.$id));
  }
  for (final zeile in await tables.reportsByReporter(userId)) {
    await tables.updateRowData(tables.config.reviewReportsTable, zeile.$id,
        {'reporter_id': deletedUserMarker(zeile.$id)});
  }
  if (await tables.getProfile(userId) != null) {
    await _ohne404(() => tables.deleteRow(tables.config.profilesTable, userId));
  }

  await _ohne404(() => users.delete(userId: userId));
  await _ohne404(
      () => tables.deleteRow(tables.config.accountDeletionsTable, userId));

  // Keine Nutzerkennung im Log (E-53): nur Zahlen.
  log('Konto gelöscht: $behalten Bewertung(en) ohne Bezug behalten, '
      '$geloescht gelöscht.');
  return PurgeResult.deleted;
}

enum PurgeResult { deleted, skipped }

/// Löscht eine Bewertung vollständig: öffentliche Zeile (die Aggregation
/// rechnet über ihr Löschereignis neu), Meldungen dazu und die Zeile in
/// `reviews`. Der Nachweis wird vom Aufrufer gelöscht, weil er seine Kennung
/// schon kennt.
///
/// Der Eintrag im `moderation_log` bleibt: Er nennt nur Bewertungskennung,
/// Moderator und Entscheidung, nicht die Person, und hält fest, wer was
/// entschieden hat.
Future<void> deleteReviewCompletely({
  required Tables tables,
  required String reviewRowId,
}) async {
  final oeffentlich = await tables.findPublicReview(reviewRowId);
  if (oeffentlich != null) {
    await _ohne404(() => tables.deletePublicReview(oeffentlich.$id));
  }
  for (final meldung in await tables.reportsForReview(reviewRowId)) {
    await _ohne404(
        () => tables.deleteRow(tables.config.reviewReportsTable, meldung.$id));
  }
  await _ohne404(
      () => tables.deleteRow(tables.config.reviewsTable, reviewRowId));
}

/// Ein Schritt, der schon erledigt sein darf: 404 heißt „gibt es nicht mehr".
Future<void> _ohne404(Future<Object?> Function() schritt) async {
  try {
    await schritt();
  } on AppwriteException catch (e) {
    if (e.code != 404) rethrow;
  }
}
