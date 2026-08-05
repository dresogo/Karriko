import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/constants/appwrite_constants.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/auth/login_shell.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

UserModel _azubi() => UserModel(
      id: 'u1',
      email: 'azubi@example.com',
      role: 'azubi',
      emailVerified: true,
      createdAt: DateTime(2026, 1, 1),
    );

class _OAuthOkRepository implements AuthRepository {
  String? gesehenerUserId;
  String? gesehenesSecret;

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> completeOAuth({
    required String userId,
    required String secret,
  }) async {
    gesehenerUserId = userId;
    gesehenesSecret = secret;
    return _azubi();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OAuthBetriebRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> completeOAuth({
    required String userId,
    required String secret,
  }) async =>
      throw const AuthFailure(
        'Betriebskonten melden sich mit E-Mail und Passwort an.',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late ProviderContainer _container;

Future<void> _pump(WidgetTester tester, AuthRepository repo) async {
  tester.view.physicalSize = const Size(1440, 900);
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

Future<String> _goTo(WidgetTester tester, String route) async {
  _container.read(routerProvider).go(route);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  return _container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();
}

void main() {
  group('Freischaltung', () {
    test('ist ohne hinterlegte Zugangsdaten aus', () {
      // Standard in der Aufbauphase. Ein Klick wuerde sonst die App verlassen
      // und auf einer Appwrite-Fehlerseite enden, von der niemand zurueckfindet.
      expect(AppwriteConstants.oauthEnabled, isFalse);
    });
  });

  group('Adresse der Anbieter-Anmeldung', () {
    test('enthält Projekt, Rückleitungen und den Anbieter', () {
      final url = oauth2TokenUrl('google');

      expect(url.path, endsWith('/account/tokens/oauth2/google'));
      expect(url.queryParameters['project'], AppwriteConstants.projectId);
      expect(url.queryParameters['success'], AppwriteConstants.oauthSuccessUrl);
      expect(url.queryParameters['failure'], AppwriteConstants.oauthFailureUrl);
      // Muss auf dem regionalen Endpunkt landen, nicht auf der App-Adresse.
      expect(url.host, Uri.parse(AppwriteConstants.endpoint).host);
    });

    test('trägt den Anbieter in den Pfad, nicht in die Query', () {
      // Ein Anbieter in der Query wuerde von Appwrite ignoriert – der Aufruf
      // liefe dann ins Leere, ohne dass es jemand merkt.
      expect(oauth2TokenUrl('apple').path, endsWith('/oauth2/apple'));
      expect(oauth2TokenUrl('apple').queryParameters, isNot(contains('apple')));
    });
  });

  testWidgets('Der Waechter laesst die Rueckleitung mit Geheimnis durch',
      (tester) async {
    final repo = _OAuthOkRepository();
    await _pump(tester, repo);

    await _goTo(tester, '/auth/oauth?userId=u1&secret=geheim');

    expect(repo.gesehenerUserId, 'u1');
    expect(repo.gesehenesSecret, 'geheim');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nach dem Einloesen bleibt das Geheimnis nicht in der Adresse',
      (tester) async {
    await _pump(tester, _OAuthOkRepository());

    final location = await _goTo(tester, '/auth/oauth?userId=u1&secret=geheim');

    expect(location, isNot(contains('secret')));
    expect(location, '/dashboard');
  });

  testWidgets('Abbruch beim Anbieter meldet das, ohne zu schleifen',
      (tester) async {
    await _pump(tester, _OAuthOkRepository());

    final location = await _goTo(tester, '/auth/oauth?error=1');

    expect(location, startsWith('/auth/oauth'));
    expect(find.byType(LoginErrorBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Betriebskonto wird abgewiesen und bleibt abgemeldet',
      (tester) async {
    // Appwrite verknuepft Identitaeten ueber die E-Mail. Ohne diese Sperre
    // kaeme ein Betrieb ohne Passwort und ohne Firmenpruefung hinein.
    await _pump(tester, _OAuthBetriebRepository());

    final location = await _goTo(tester, '/auth/oauth?userId=b1&secret=geheim');

    expect(location, startsWith('/auth/oauth'));
    expect(_container.read(authProvider).isAuthenticated, isFalse);
    expect(find.byType(LoginErrorBanner), findsOneWidget);
  });

  testWidgets('Unvollstaendige Rueckmeldung meldet das, statt zu scheitern',
      (tester) async {
    await _pump(tester, _OAuthOkRepository());

    final location = await _goTo(tester, '/auth/oauth');

    expect(location, '/auth/oauth');
    expect(find.byType(LoginErrorBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
