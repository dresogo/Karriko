import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/auth/login_shell.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// T-6.5: Passwort vergessen, Passwort setzen und E-Mail bestätigen.
///
/// Vorher lösten weder der Reset-Link noch der Bestätigungslink ihr Geheimnis
/// ein: Die Reset-Seite rief `updatePassword` (braucht eine Sitzung, die es
/// nach „Passwort vergessen“ nicht gibt), und die Bestätigungsseite las die
/// Query gar nicht.

UserModel _azubi({bool verified = false}) => UserModel(
      id: 'u1',
      email: 'azubi@example.com',
      role: 'azubi',
      emailVerified: verified,
      createdAt: DateTime(2026, 1, 1),
    );

class _Repo implements AuthRepository {
  UserModel? user;

  /// Was der nächste Einlöseversuch wirft; `null` heißt Erfolg.
  Object? fehler;

  final aufrufe = <String>[];

  _Repo({this.user, this.fehler});

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<void> resetPassword(String email, {bool betrieb = false}) async {
    aufrufe.add('reset:$email:$betrieb');
  }

  @override
  Future<void> completeRecovery({
    required String userId,
    required String secret,
    required String password,
  }) async {
    aufrufe.add('recovery:$userId:$secret');
    if (fehler != null) throw fehler!;
  }

  @override
  Future<void> confirmEmail({
    required String userId,
    required String secret,
  }) async {
    aufrufe.add('confirm:$userId:$secret');
    if (fehler != null) throw fehler!;
    if (user != null) user = _azubi(verified: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late ProviderContainer _container;

Future<void> _pump(WidgetTester tester, _Repo repo,
    {Size size = const Size(1440, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(_container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<String> _goTo(WidgetTester tester, String route) async {
  _container.read(routerProvider).go(route);
  await _settle(tester);
  return _location();
}

String _location() => _container
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

void main() {
  group('Passwort vergessen', () {
    testWidgets('antwortet im Konjunktiv und nennt die Adresse',
        (tester) async {
      final repo = _Repo();
      await _pump(tester, repo);
      await _goTo(tester, '/forgot-password');

      await tester.enterText(find.byType(TextFormField), 'a@example.com');
      await tester.tap(find.text('Link schicken'));
      await _settle(tester);

      expect(repo.aufrufe, ['reset:a@example.com:false']);
      expect(find.text('Schau in dein Postfach.'), findsOneWidget);
      expect(find.textContaining('ein Konto existiert', findRichText: true),
          findsOneWidget);
      expect(find.text('Erneut senden (in 60 s)'), findsOneWidget);
    });

    testWidgets('Betriebe: Sie-Ansprache, Link führt zum Betriebs-Login',
        (tester) async {
      final repo = _Repo();
      await _pump(tester, repo);
      await _goTo(tester, '/forgot-password?zugang=betrieb');

      expect(find.textContaining('Wir schicken Ihnen'), findsOneWidget);
      // Ohne Passwort anmelden gibt es nur für Azubis (E-40).
      expect(find.text('Ohne Passwort anmelden'), findsNothing);

      await tester.enterText(find.byType(TextFormField), 'b@example.com');
      await tester.tap(find.text('Link schicken'));
      await _settle(tester);
      expect(repo.aufrufe, ['reset:b@example.com:true']);
      expect(find.text('Schauen Sie in Ihr Postfach.'), findsOneWidget);
    });
  });

  group('Passwort setzen', () {
    testWidgets('löst das Geheimnis aus dem Link ein, ohne Sitzung',
        (tester) async {
      final repo = _Repo();
      await _pump(tester, repo);
      await _goTo(tester, '/reset-password?userId=u1&secret=geheim');

      await tester.enterText(
          find.byType(TextFormField), 'ein langer satz als passwort');
      await tester.tap(find.text('Passwort speichern'));
      await _settle(tester);

      expect(repo.aufrufe, ['recovery:u1:geheim']);
      expect(find.text('Dein Passwort\nist geändert.'), findsOneWidget);
      expect(find.text('Jetzt anmelden'), findsOneWidget);
    });

    testWidgets('unvollständiger Link zeigt den Weg zu einem neuen',
        (tester) async {
      await _pump(tester, _Repo());
      await _goTo(tester, '/reset-password');

      expect(find.text('Dieser Link\ngilt nicht mehr.'), findsOneWidget);
      expect(find.text('Neuen Link anfordern'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('abgelaufener Link wechselt in denselben Zustand',
        (tester) async {
      await _pump(tester, _Repo(fehler: const AuthLinkInvalid()));
      await _goTo(tester, '/reset-password?userId=u1&secret=alt');

      await tester.enterText(
          find.byType(TextFormField), 'ein langer satz als passwort');
      await tester.tap(find.text('Passwort speichern'));
      await _settle(tester);

      expect(find.text('Dieser Link\ngilt nicht mehr.'), findsOneWidget);
    });

    testWidgets('abgelehntes Passwort steht am Feld, Eingabe bleibt',
        (tester) async {
      await _pump(
          tester, _Repo(fehler: const AuthFailure('Aus einem Datenleck.')));
      await _goTo(tester, '/reset-password?userId=u1&secret=geheim');

      await tester.enterText(
          find.byType(TextFormField), 'ein langer satz als passwort');
      await tester.tap(find.text('Passwort speichern'));
      await _settle(tester);

      expect(find.text('Aus einem Datenleck.'), findsOneWidget);
      expect(find.text('Passwort speichern'), findsOneWidget);
      expect(find.text('ein langer satz als passwort'), findsOneWidget);
    });

    testWidgets('Geheimnis erscheint nie auf der Seite (E-47)', (tester) async {
      await _pump(tester, _Repo(fehler: const AuthLinkInvalid()));
      await _goTo(tester, '/reset-password?userId=u1&secret=sehrgeheim');

      expect(find.textContaining('sehrgeheim'), findsNothing);
    });
  });

  group('E-Mail bestätigen', () {
    testWidgets('Link ohne Sitzung wird eingelöst statt zur Anmeldung',
        (tester) async {
      final repo = _Repo();
      await _pump(tester, repo);

      final location =
          await _goTo(tester, '/verify-email?userId=u1&secret=geheim');

      expect(location, startsWith('/verify-email'));
      expect(repo.aufrufe, ['confirm:u1:geheim']);
      expect(find.text('Adresse\nbestätigt.'), findsOneWidget);

      // Nach zwei Sekunden weiter; ohne Sitzung führt der Wächter zur
      // Anmeldung, das Geheimnis bleibt nicht in der Adresse.
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester);
      expect(_location(), isNot(contains('secret')));
      expect(_location(), startsWith('/login'));
    });

    testWidgets('angemeldet: nach der Bestätigung aufs Dashboard',
        (tester) async {
      final repo = _Repo(user: _azubi());
      await _pump(tester, repo);

      await _goTo(tester, '/verify-email?userId=u1&secret=geheim');
      expect(_container.read(authProvider).emailVerified, isTrue);

      await tester.tap(find.text('Weiter'));
      await _settle(tester);
      expect(_location(), '/dashboard');
    });

    testWidgets('abgelaufener Link meldet das', (tester) async {
      await _pump(tester, _Repo(fehler: const AuthLinkInvalid()));

      await _goTo(tester, '/verify-email?userId=u1&secret=alt');

      expect(find.text('Dieser Link\ngilt nicht mehr.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Zwischenstopp nennt die Adresse und bietet Abmelden',
        (tester) async {
      await _pump(tester, _Repo(user: _azubi()));

      expect(await _goTo(tester, '/verify-email'), '/verify-email');
      expect(find.text('azubi@example.com'), findsOneWidget);
      expect(find.text('Ich habe bestätigt'), findsOneWidget);
      expect(find.text('E-Mail erneut senden'), findsOneWidget);
      expect(find.text('Falsche Adresse? Abmelden und neu registrieren'),
          findsOneWidget);
    });
  });

  group('Layout', () {
    const sizes = <String, Size>{
      'desktop': Size(1440, 900),
      'phone': Size(375, 812),
      'phone schmal': Size(320, 640),
    };
    const routes = <String, String>{
      'Passwort vergessen': '/forgot-password',
      'Passwort setzen': '/reset-password?userId=u1&secret=s',
      'Link ungültig': '/reset-password',
      'E-Mail bestätigen': '/verify-email',
    };

    routes.forEach((name, route) {
      sizes.forEach((sizeName, size) {
        for (final scale in const [1.0, 1.3]) {
          testWidgets(
              '$name rendert bei $sizeName${scale == 1.0 ? '' : ', Schrift $scale'}',
              (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue);

            final user = route == '/verify-email' ? _azubi() : null;
            await _pump(tester, _Repo(user: user), size: size);
            await _goTo(tester, route);

            expect(tester.takeException(), isNull);
            expect(find.byType(LoginShell), findsOneWidget);
          });
        }
      });
    });
  });
}
