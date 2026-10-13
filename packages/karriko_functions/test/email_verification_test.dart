import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:karriko_functions/karriko_functions.dart';
import 'package:test/test.dart';

/// Nachweis für Referenz §3.2: Unbestätigte Konten können nicht bewerten.
///
/// `submit_review` fragt [hasVerifiedEmail], bevor es irgendetwas prüft oder
/// anlegt. Hier steht, wann die Antwort „ja“ lautet, und vor allem, dass jeder
/// Zweifelsfall „nein“ ergibt.
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

  test('bestätigte Adresse: ja', () async {
    expect(
      await hasVerifiedEmail(kontext(jwt: 'jwt'), loader: (_) async => true),
      isTrue,
    );
  });

  test('unbestätigte Adresse: nein', () async {
    expect(
      await hasVerifiedEmail(kontext(jwt: 'jwt'), loader: (_) async => false),
      isFalse,
    );
  });

  test('ohne JWT: nein, und Appwrite wird gar nicht erst gefragt', () async {
    var gefragt = false;
    Future<bool> loader(Client _) async {
      gefragt = true;
      return true;
    }

    expect(await hasVerifiedEmail(kontext(), loader: loader), isFalse);
    expect(await hasVerifiedEmail(kontext(jwt: ''), loader: loader), isFalse);
    expect(gefragt, isFalse);
  });

  test('Appwrite lehnt den Abruf ab: nein, mit Protokolleintrag', () async {
    final ergebnis = await hasVerifiedEmail(
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
