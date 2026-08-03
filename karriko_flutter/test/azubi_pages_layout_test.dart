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

final _azubi = UserModel(
  id: 'u1',
  email: 'azubi@karriko.de',
  role: 'azubi',
  firstName: 'Lena',
  lastName: 'Berger',
  emailVerified: true,
  createdAt: DateTime(2026, 3, 14),
);

late ProviderContainer _container;

Future<void> _open(WidgetTester tester, String route, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_azubi))
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
  await tester.pump();
  _container.read(routerProvider).go(route);
  // Seitenwechsel vollstaendig durchlaufen lassen. pumpAndSettle scheidet aus:
  // Die Ladeanzeige der Abschnitte dreht sich endlos und liefe in den Timeout.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  const sizes = <String, Size>{
    'desktop 1440': Size(1440, 900),
    'laptop 1200': Size(1200, 800),
    'tablet 900': Size(900, 1000),
    'schmal 760': Size(760, 900),
    'phone 375': Size(375, 812),
    'phone klein 360': Size(360, 640),
  };

  const routes = <String, String>{
    'Dashboard': '/dashboard',
    'Profil': '/profile',
    'Einstellungen': '/settings',
  };

  routes.forEach((name, route) {
    sizes.forEach((sizeName, size) {
      testWidgets('$name rendert fehlerfrei bei $sizeName', (tester) async {
        await _open(tester, route, size);
        expect(tester.takeException(), isNull);
      });
    });
  });

  testWidgets('Dashboard begruesst mit dem Namen und zeigt Schnellzugriff',
      (tester) async {
    await _open(tester, '/dashboard', const Size(1440, 900));

    expect(find.text('Hallo, Lena Berger.'), findsOneWidget);
    expect(find.text('Fragen bewerten'), findsOneWidget);
    expect(find.text('Mein Profil'), findsOneWidget);
  });

  testWidgets('Profil zeigt Konto-Angaben aus dem Nutzer', (tester) async {
    await _open(tester, '/profile', const Size(1440, 900));

    expect(find.text('Lena Berger'), findsWidgets);
    expect(find.text('14. März 2026'), findsOneWidget);
    expect(find.text('Azubi'), findsOneWidget);
  });

  testWidgets('Einstellungen benennen den Schalterzustand als Text',
      (tester) async {
    await _open(tester, '/settings', const Size(1440, 900));

    // Zustand darf nicht allein an Farbe und Position haengen.
    expect(find.textContaining('Andere Nutzer sehen deinen Namen · Aus'),
        findsOneWidget);
    expect(find.textContaining('Antworten und Statusänderungen · An'),
        findsOneWidget);
  });

  testWidgets('Profilmenue zeigt Kopfbereich und alle Ziele', (tester) async {
    await _open(tester, '/dashboard', const Size(1440, 900));

    await tester.tap(find.byTooltip('Profilmenü öffnen'));
    await tester.pumpAndSettle();

    expect(find.text('AZUBI'), findsOneWidget);
    expect(find.text('azubi@karriko.de'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
    expect(find.text('Einstellungen'), findsWidgets);
    expect(find.text('Abmelden'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profilmenue fuehrt auf die Einstellungen', (tester) async {
    await _open(tester, '/dashboard', const Size(1440, 900));

    await tester.tap(find.byTooltip('Profilmenü öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einstellungen').last);
    await tester.pumpAndSettle();

    expect(
      _container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      '/settings',
    );
  });
}
