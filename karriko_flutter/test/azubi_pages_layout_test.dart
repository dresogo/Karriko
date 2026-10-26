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
    // Schmalste gängige Breite (iPhone SE 1. Generation); dort fielen die
    // Fehler aus T-11.14 auf (T-7.10).
    'phone schmal 320': Size(320, 568),
  };

  const routes = <String, String>{
    'Dashboard': '/dashboard',
    'Profil': '/profile',
    'Einstellungen': '/settings',
  };

  routes.forEach((name, route) {
    sizes.forEach((sizeName, size) {
      // Normale und vergrößerte Systemschrift: deckt auf, wo eine Höhe
      // oder Breite stillschweigend als konstant angenommen wird.
      for (final scale in const [1.0, 1.3]) {
        testWidgets(
            '$name rendert fehlerfrei bei $sizeName${scale == 1.0 ? '' : ', Schrift $scale'}',
            (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await _open(tester, route, size);
          expect(tester.takeException(), isNull);
        });
      }
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

  testWidgets('Einstellungen zeigen keine Schalter ohne Wirkung',
      (tester) async {
    await _open(tester, '/settings', const Size(1440, 900));

    // E-30: Profil und Benachrichtigungen gibt es noch nicht, also auch
    // keine Schalter dafuer (T-2.14).
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Öffentliches Profil'), findsNothing);
    expect(find.text('Benachrichtigungen'), findsNothing);
  });

  testWidgets('Benachrichtigungen führen aufs Dashboard', (tester) async {
    // E-30: Es gibt weder Tabelle noch Auslöser (T-2.13). Alte Lesezeichen
    // auf /notifications sollen nicht auf eine immer leere Seite führen.
    await _open(tester, '/notifications', const Size(1440, 900));

    expect(
      _container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      '/dashboard',
    );
  });

  testWidgets('Merkliste führt aufs Dashboard und steht dort nicht',
      (tester) async {
    // E-30: Ohne Merken-Knopf bliebe die Liste immer leer (T-6.23).
    await _open(tester, '/bookmarks', const Size(1440, 900));

    expect(
      _container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      '/dashboard',
    );
    expect(find.text('Merkliste'), findsNothing);
    expect(find.text('Gemerkte Betriebe'), findsNothing);
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
