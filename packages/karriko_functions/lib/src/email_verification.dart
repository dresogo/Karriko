import 'package:dart_appwrite/dart_appwrite.dart';

import 'context.dart';

/// Fragt Appwrite, ob die Adresse des Kontos bestätigt ist.
typedef EmailStatusLoader = Future<bool> Function(Client userClient);

/// Prüft, ob der Aufrufer eine bestätigte E-Mail-Adresse hat.
///
/// Warum hier und nicht nur in der App: Die App schickt unbestätigte Konten
/// auf `/verify-email`, aber eine Function lässt sich auch ohne App aufrufen.
/// Eine Schranke, die nur im Client steht, ist keine (Referenz §3.2).
///
/// Gelesen wird **mit dem JWT des Aufrufers**, nicht mit dem Admin-Schlüssel.
/// So sieht die Function nur das eigene Konto und braucht keinen zusätzlichen
/// Scope wie `users.read`.
///
/// Fällt im Zweifel auf „nein“: Ohne JWT oder wenn Appwrite den Abruf
/// ablehnt, gilt die Adresse als unbestätigt. Ein Fehler soll keine Bewertung
/// durchlassen, die sonst abgewiesen würde.
Future<bool> hasVerifiedEmail(
  RunContext ctx, {
  EmailStatusLoader loader = _ausAppwrite,
}) async {
  final jwt = ctx.userJwt;
  if (jwt == null || jwt.isEmpty) return false;
  try {
    return await loader(ctx.userClient());
  } on AppwriteException catch (e) {
    ctx.logError('Kontostatus nicht abrufbar: ${e.code} ${e.type}');
    return false;
  }
}

Future<bool> _ausAppwrite(Client userClient) async =>
    (await Account(userClient).get()).emailVerification;
