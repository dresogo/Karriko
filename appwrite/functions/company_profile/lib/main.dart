import 'dart:io';
import 'dart:math';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:karriko_functions/karriko_functions.dart';

/// Legt das Firmenprofil des Aufrufers an oder ändert es.
///
/// **Warum es diese Function braucht (T-4.2).** Appwrite kennt keine Rechte je
/// Spalte. Solange der Client direkt in `companies` schrieb, konnte jedes
/// bestätigte Konto beim Anlegen und der Eigentümer beim Ändern auch
/// `is_verified`, `is_premium`, `average_rating`, `review_count` und
/// `owner_id` setzen. Die Tabelle hat deshalb kein Anlege- und die Zeilen
/// kein Änderungsrecht mehr; der einzige Schreibweg ist hier, und er nimmt
/// nur die Felder aus [companyEditableFields].
///
/// **Welche Firma, entscheidet der Server.** Der Rumpf trägt keine Firmen- und
/// keine Nutzerkennung. Die Firma ist die, deren `owner_id` der Aufrufer aus
/// dem geprüften JWT ist (`x-appwrite-user-id`). Wer eine fremde Kennung
/// mitschicken könnte, könnte fremde Profile ändern.
///
/// **Die Rolle spielt keine Rolle (E-3.10).** Ob ein Konto in der App als
/// Betrieb auftritt, steht in Prefs und Profil und ist vom Konto selbst
/// änderbar. Hier zählt nur: bestätigte Adresse, höchstens eine Firma je
/// Konto, und die eigene Firma.
///
/// Rumpf: `{"action": "create" | "update", "fields": {…}}`.
/// Antwort: `{"ok": true, "company": {…}}` wie eine Zeile aus `companies`.
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
      FunctionResponse.unauthorized(
        'Bitte melde dich an, um dein Unternehmensprofil zu bearbeiten.',
      ),
    );
  }

  // Wie `create("users/verified")` auf einer Tabelle, nur hier geprüft, weil
  // die Tabelle selbst kein Anlegerecht mehr hat (T-4.25).
  if (!await hasVerifiedEmail(ctx)) {
    return _antwort(
      context,
      FunctionResponse.forbidden(
        'Bitte bestätige zuerst deine E-Mail-Adresse.',
      ),
    );
  }

  final action = ctx.body['action'];
  final rohFelder = ctx.body['fields'];
  if ((action != 'create' && action != 'update') || rohFelder is! Map) {
    return _antwort(
      context,
      FunctionResponse.invalid('Unvollständige Anfrage.'),
    );
  }

  final eingabe = parseCompanyProfile(
    rohFelder.map((k, v) => MapEntry(k.toString(), v)),
    creating: action == 'create',
  );
  if (!eingabe.isValid) {
    ctx.log('$userId: abgewiesen – ${eingabe.errors.join('; ')}');
    return _antwort(
      context,
      FunctionResponse.invalid(eingabe.errors.first, eingabe.errors),
    );
  }

  final tables = Tables(client: ctx.adminClient(), config: ctx.config);

  try {
    final vorhanden = await tables.companyByOwner(userId);

    if (action == 'create') {
      // Höchstens eine Firma je Konto. Ein zweiter Aufruf, etwa nach einem
      // abgebrochenen ersten, liefert die bestehende statt einer zweiten.
      if (vorhanden != null) {
        return _firma(context, vorhanden);
      }
      final zeile = await _anlegen(tables, userId, eingabe.data);
      ctx.log('$userId: Firma ${zeile.$id} angelegt.');
      return _firma(context, zeile);
    }

    if (vorhanden == null) {
      return _antwort(
        context,
        FunctionResponse.forbidden('Zu diesem Konto gibt es kein Unternehmen.'),
      );
    }
    if (eingabe.data.isEmpty) return _firma(context, vorhanden);

    // Der Slug bleibt bei einer Umbenennung, wie bisher in der App: Er steht in
    // der öffentlichen Adresse, und geteilte Links sollen nicht brechen.
    final zeile = await tables.updateCompany(vorhanden.$id, eingabe.data);
    ctx.log('$userId: Firma ${zeile.$id} geändert '
        '(${eingabe.data.keys.join(', ')}).');
    return _firma(context, zeile);
  } on AppwriteException catch (e) {
    ctx.logError('$userId: ${e.code} ${e.type} ${e.message}');
    return _antwort(
      context,
      FunctionResponse.unavailable(
        'Das Unternehmensprofil konnte nicht gespeichert werden.',
      ),
    );
  }
}

/// Legt die Firma mit einem freien Slug an.
///
/// Verbindlich ist der eindeutige Index `slug_unique`. Die Prüfung vorher
/// erspart nur den häufigen Fall; kommt trotzdem ein zweiter Aufruf
/// dazwischen, scheitert das Anlegen mit 409 und der zweite Versuch nimmt
/// einen Zusatz.
Future<dynamic> _anlegen(
  Tables tables,
  String userId,
  Map<String, Object?> felder,
) async {
  final basis = companySlug(felder['name']! as String);
  var slug = await tables.companySlugTaken(basis) ? _mitZusatz(basis) : basis;
  try {
    return await tables.createCompany(
      buildNewCompanyRow(ownerId: userId, slug: slug, fields: felder),
    );
  } on AppwriteException catch (e) {
    if (e.code != 409) rethrow;
    slug = _mitZusatz(basis);
    return tables.createCompany(
      buildNewCompanyRow(ownerId: userId, slug: slug, fields: felder),
    );
  }
}

/// Sechs zufällige Hexziffern. Nicht `ID.unique()`: Dessen Anfang ist ein
/// Zeitstempel und unterscheidet zwei gleichzeitige Aufrufe kaum.
String _mitZusatz(String basis) {
  final zufall = Random.secure();
  final zusatz = List.generate(6, (_) => zufall.nextInt(16).toRadixString(16));
  return '$basis-${zusatz.join()}';
}

dynamic _firma(final context, dynamic zeile) => _antwort(
      context,
      FunctionResponse.ok({
        'company': companyResponse(
          id: zeile.$id as String,
          createdAt: zeile.$createdAt as String,
          data: Map<String, Object?>.from(zeile.data as Map),
        ),
      }),
    );

dynamic _antwort(final context, FunctionResponse antwort) =>
    context.res.json(antwort.payload, antwort.status);
