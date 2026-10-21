import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:karriko_functions/karriko_functions.dart';
import 'package:test/test.dart';

/// T-3.5: Moderation und Administration nur mit zweitem Faktor.
///
/// `moderate_review`, `moderation_desk` und `recompute_all` fragen
/// [hasMfaEnabled] nach der Team-Prüfung. Hier steht, wann die Antwort „ja“
/// lautet, und vor allem, dass jeder Zweifelsfall „nein“ ergibt.
void main() {
  final fehler = <String>[];

  RunContext kontext({String? jwt}) => RunContext(
        config: FunctionConfig.fromEnvironment({
          'APPWRITE_FUNCTION_PROJECT_ID': 'projekt',
          'KARRIKO_DATABASE_ID': 'datenbank',
        }),
        headers: {
          'x-appwrite-user-id': 'nutzer',
          if (jwt != null) 'x-appwrite-user-jwt': jwt,
        },
        body: const {},
        log: (_) {},
        logError: fehler.add,
      );

  setUp(fehler.clear);

  test('zweiter Faktor aktiv: ja', () async {
    expect(
      await hasMfaEnabled(kontext(jwt: 'jwt'), loader: (_) async => true),
      isTrue,
    );
  });

  test('kein zweiter Faktor: nein', () async {
    expect(
      await hasMfaEnabled(kontext(jwt: 'jwt'), loader: (_) async => false),
      isFalse,
    );
  });

  test('ohne JWT: nein, und Appwrite wird gar nicht erst gefragt', () async {
    var gefragt = false;
    Future<bool> loader(Client _) async {
      gefragt = true;
      return true;
    }

    expect(await hasMfaEnabled(kontext(), loader: loader), isFalse);
    expect(await hasMfaEnabled(kontext(jwt: ''), loader: loader), isFalse);
    expect(gefragt, isFalse);
  });

  test('Appwrite lehnt den Abruf ab: nein, mit Protokolleintrag', () async {
    final ergebnis = await hasMfaEnabled(
      kontext(jwt: 'abgelaufen'),
      loader: (_) async =>
          throw AppwriteException('JWT ungueltig', 401, 'user_jwt_invalid'),
    );

    expect(ergebnis, isFalse);
    expect(fehler.single, contains('401'));
    // Das JWT selbst gehört nicht ins Protokoll.
    expect(fehler.single, isNot(contains('abgelaufen')));
  });
}
