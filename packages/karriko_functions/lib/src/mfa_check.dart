import 'package:dart_appwrite/dart_appwrite.dart';

import 'context.dart';

/// Fragt Appwrite, ob für das Konto ein zweiter Faktor aktiv ist.
typedef MfaStatusLoader = Future<bool> Function(Client userClient);

/// Prüft, ob der Aufrufer einen zweiten Faktor eingerichtet hat (T-3.5).
///
/// Moderation und Administration sehen Rohdaten, Nachweise und entscheiden
/// über Veröffentlichungen. Ein Konto, das dafür nur ein Passwort braucht, ist
/// das lohnendste Ziel der ganzen Plattform. Deshalb verlangen
/// `moderate_review`, `moderation_desk` und `recompute_all` einen aktiven
/// zweiten Faktor. Ist er aktiv, verlangt Appwrite ihn bei jeder Anmeldung;
/// eine Sitzung ohne ihn kommt gar nicht erst zustande.
///
/// Gelesen wird mit dem JWT des Aufrufers, wie bei [hasVerifiedEmail]: kein
/// zusätzlicher Scope, und die Function sieht nur das eigene Konto.
///
/// Fällt im Zweifel auf „nein“: ohne JWT oder wenn Appwrite den Abruf
/// ablehnt.
Future<bool> hasMfaEnabled(
  RunContext ctx, {
  MfaStatusLoader loader = _ausAppwrite,
}) async {
  final jwt = ctx.userJwt;
  if (jwt == null || jwt.isEmpty) return false;
  try {
    return await loader(ctx.userClient());
  } on AppwriteException catch (e) {
    ctx.logError('MFA-Status nicht abrufbar: ${e.code} ${e.type}');
    return false;
  }
}

Future<bool> _ausAppwrite(Client userClient) async =>
    (await Account(userClient).get()).mfa;

/// Die Meldung an Moderatoren ohne zweiten Faktor.
const mfaRequiredMessage =
    'Für Moderation und Administration ist die Zwei-Faktor-Bestätigung '
    'Pflicht. Richte sie in deinen Einstellungen ein und melde dich neu an.';
