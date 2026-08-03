import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  final UserModel? user;

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserModel _user({required String role, required bool verified}) => UserModel(
      id: 'u1',
      email: 'azubi@example.com',
      role: role,
      firstName: 'Test',
      lastName: 'Nutzer',
      emailVerified: verified,
      createdAt: DateTime(2026, 1, 1),
    );

late ProviderContainer _container;

Future<void> _pump(WidgetTester tester, UserModel? user) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user))
    ],
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
  // Auth-Initialisierung abwarten, damit der Guard den echten Zustand sieht.
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
  testWidgets(
      'Unbestaetigte Adresse fuehrt auf /verify-email, nicht in eine Schleife',
      (tester) async {
    await _pump(tester, _user(role: 'azubi', verified: false));

    for (final route in ['/dashboard', '/profile', '/settings']) {
      final location = await _goTo(tester, route);

      expect(
        tester.takeException(),
        isNull,
        reason: '$route darf keine Weiterleitungsschleife ausloesen',
      );
      expect(location, '/verify-email', reason: 'von $route');
    }
  });

  testWidgets('/verify-email bleibt stehen, solange die Adresse offen ist',
      (tester) async {
    await _pump(tester, _user(role: 'azubi', verified: false));

    expect(await _goTo(tester, '/verify-email'), '/verify-email');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bestaetigter Azubi erreicht seine Seiten', (tester) async {
    await _pump(tester, _user(role: 'azubi', verified: true));

    expect(await _goTo(tester, '/dashboard'), '/dashboard');
    expect(await _goTo(tester, '/profile'), '/profile');
    expect(await _goTo(tester, '/settings'), '/settings');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bestaetigter Azubi wird von /verify-email weggeleitet',
      (tester) async {
    await _pump(tester, _user(role: 'azubi', verified: true));

    expect(await _goTo(tester, '/verify-email'), '/dashboard');
  });

  testWidgets('Betrieb landet nicht in den Azubi-Bereichen', (tester) async {
    await _pump(tester, _user(role: 'betrieb', verified: true));

    expect(await _goTo(tester, '/dashboard'), '/betrieb-dashboard');
    expect(await _goTo(tester, '/betrieb-profile'), '/betrieb-profile');
  });

  testWidgets('Abgemeldet fuehrt auf den Login mit Rueckziel', (tester) async {
    await _pump(tester, null);

    expect(await _goTo(tester, '/dashboard'), '/login?next=%2Fdashboard');
  });
}
