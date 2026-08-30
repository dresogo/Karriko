import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
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

/// Loest den Anmeldelink erfolgreich ein.
class _MagicOkRepository implements AuthRepository {
  int aufrufe = 0;
  String? gesehenerUserId;
  String? gesehenesSecret;

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> completeMagicLink({
    required String userId,
    required String secret,
  }) async {
    aufrufe++;
    gesehenerUserId = userId;
    gesehenesSecret = secret;
    return _azubi();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Der Link ist verbraucht oder abgelaufen.
class _MagicAbgelaufenRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> completeMagicLink({
    required String userId,
    required String secret,
  }) async =>
      throw const AuthFailure(
        'Dieser Link ist abgelaufen oder wurde bereits verwendet. '
        'Fordere bitte einen neuen an.',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Ein Betriebskonto versucht, sich per Link anzumelden.
class _MagicBetriebRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> completeMagicLink({
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
  testWidgets('Der Waechter laesst den Callback mit Geheimnis durch',
      (tester) async {
    // Kern der Route: Wuerde der Waechter hier umleiten, ginge das
    // Einmal-Geheimnis verloren, bevor es eingeloest ist.
    final repo = _MagicOkRepository();
    await _pump(tester, repo);

    await _goTo(tester, '/auth/magic?userId=u1&secret=geheim');

    expect(repo.aufrufe, 1);
    expect(repo.gesehenerUserId, 'u1');
    expect(repo.gesehenesSecret, 'geheim');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nach dem Einloesen bleibt das Geheimnis nicht in der Adresse',
      (tester) async {
    await _pump(tester, _MagicOkRepository());

    final location = await _goTo(tester, '/auth/magic?userId=u1&secret=geheim');

    expect(location, isNot(contains('secret')));
    expect(location, '/dashboard');
  });

  testWidgets('Abgelaufener Link bleibt stehen und schleift nicht',
      (tester) async {
    await _pump(tester, _MagicAbgelaufenRepository());

    final location = await _goTo(tester, '/auth/magic?userId=u1&secret=alt');

    expect(location, startsWith('/auth/magic'));
    expect(tester.takeException(), isNull);
    expect(find.byType(LoginErrorBanner), findsOneWidget);
    expect(find.text('Neuen Link anfordern'), findsOneWidget);
  });

  testWidgets('Unvollstaendiger Link meldet das, statt zu scheitern',
      (tester) async {
    await _pump(tester, _MagicOkRepository());

    final location = await _goTo(tester, '/auth/magic');

    expect(location, '/auth/magic');
    expect(find.byType(LoginErrorBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Betriebskonto wird abgewiesen und bleibt abgemeldet',
      (tester) async {
    await _pump(tester, _MagicBetriebRepository());

    final location = await _goTo(tester, '/auth/magic?userId=b1&secret=geheim');

    expect(location, startsWith('/auth/magic'));
    expect(_container.read(authProvider).isAuthenticated, isFalse);
    expect(find.byType(LoginErrorBanner), findsOneWidget);
  });

  testWidgets('Die Anforderungsseite ist ohne Anmeldung erreichbar',
      (tester) async {
    await _pump(tester, _MagicOkRepository());

    expect(await _goTo(tester, '/login/azubi/magic'), '/login/azubi/magic');
    expect(tester.takeException(), isNull);
  });
}
