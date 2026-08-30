import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Konto mit hinterlegtem zweitem Faktor.
///
/// [getCurrentUser] wirft [MfaRequired] – genau das tut das echte Repository,
/// wenn eine angefangene Sitzung im Browser liegt und die Seite neu geladen
/// wird.
class _MfaPendingRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async =>
      throw const MfaRequired(['totp', 'recoverycode']);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Konto ohne offene Bestaetigung.
class _VerifiedRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => UserModel(
        id: 'u1',
        email: 'azubi@example.com',
        role: 'azubi',
        emailVerified: true,
        mfaEnabled: true,
        createdAt: DateTime(2026, 1, 1),
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
  return _container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();
}

void main() {
  testWidgets('Offene Bestaetigung zieht geschuetzte Seiten auf /mfa-challenge',
      (tester) async {
    await _pump(tester, _MfaPendingRepository());

    for (final route in [
      '/dashboard',
      '/settings',
      '/betrieb-dashboard',
      '/login/azubi',
      '/verify-email',
    ]) {
      final location = await _goTo(tester, route);

      expect(
        tester.takeException(),
        isNull,
        reason: '$route darf keine Weiterleitungsschleife ausloesen',
      );
      expect(location, '/mfa-challenge', reason: 'von $route');
    }
  });

  testWidgets('/mfa-challenge bleibt stehen und schleift nicht',
      (tester) async {
    await _pump(tester, _MfaPendingRepository());

    expect(await _goTo(tester, '/mfa-challenge'), '/mfa-challenge');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Oeffentliche Seiten bleiben waehrend der Bestaetigung offen',
      (tester) async {
    // Wer mitten in der Anmeldung steckt, muss trotzdem das Impressum lesen
    // koennen. Ein pauschaler Redirect waere hier zu grob.
    await _pump(tester, _MfaPendingRepository());

    expect(await _goTo(tester, '/faq'), '/faq');
    expect(await _goTo(tester, '/impressum'), '/impressum');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Halbe Sitzung gilt nicht als angemeldet', (tester) async {
    await _pump(tester, _MfaPendingRepository());

    final auth = _container.read(authProvider);
    expect(auth.mfaRequired, isTrue);
    expect(auth.isAuthenticated, isFalse);
    expect(auth.isAzubi, isFalse);
    expect(auth.emailVerified, isFalse);
  });

  testWidgets('Ohne offene Bestaetigung leitet /mfa-challenge weiter',
      (tester) async {
    await _pump(tester, _VerifiedRepository());

    expect(await _goTo(tester, '/mfa-challenge'), '/dashboard');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Abgemeldet fuehrt /mfa-challenge auf den Login', (tester) async {
    await _pump(tester, _MfaPendingRepository());
    // Abbruch meldet ab und raeumt den Zustand.
    _container.read(authProvider.notifier).state = const AuthState();
    await tester.pump();

    expect(await _goTo(tester, '/mfa-challenge'), '/login');
  });
}
