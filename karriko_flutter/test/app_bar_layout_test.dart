import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/common/app_bar_widget.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Liefert den Nutzer fuer den Auth-Zustand, ohne Netzwerk.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  final UserModel? user;

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Ein langer Name, damit das Profilmenue in der breiten Kopfzeile so viel
// Platz braucht wie im echten Leben.
final _azubi = UserModel(
  id: 'a1',
  email: 'maximiliane@example.de',
  role: 'azubi',
  firstName: 'Maximiliane',
  lastName: 'Mustermann-Schulze',
  emailVerified: true,
  createdAt: DateTime(2026, 2, 9),
);

Future<void> _pumpHeader(
  WidgetTester tester, {
  required double width,
  required double textScale,
  UserModel? user,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          appBar: KarrikoAppBar(),
          drawer: KarrikoDrawer(),
          body: SizedBox.shrink(),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  // Rund um den Umbruchpunkt besonders dicht, denn dort lief die Zeile frueher
  // ueber: bei 1,3-facher Schrift zwischen 981 und rund 1150 px.
  const widths = <double>[
    360,
    375,
    760,
    979,
    981,
    1000,
    1050,
    1100,
    1150,
    1200,
    1274,
    1300,
    1440,
    1920,
  ];
  const scales = <double>[1.0, 1.3, 1.5, 2.0];

  for (final user in <UserModel?>[null, _azubi]) {
    final who = user == null ? 'abgemeldet' : 'angemeldet';
    for (final scale in scales) {
      testWidgets('Kopfzeile ohne Ueberlauf, $who, Schrift $scale',
          (tester) async {
        for (final width in widths) {
          await _pumpHeader(tester, width: width, textScale: scale, user: user);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Ueberlauf bei $width px und Schrift $scale ($who)',
          );
        }
      });
    }
  }

  testWidgets('Normale Schrift: breite Navigation ab 981 px', (tester) async {
    await _pumpHeader(tester, width: 981, textScale: 1.0);
    expect(find.text('Für Betriebe'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);

    await _pumpHeader(tester, width: 979, textScale: 1.0);
    expect(find.text('Für Betriebe'), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets('Grosse Schrift: Menue statt Navigation, bis sie Platz hat',
      (tester) async {
    // 1,3 x 980 = 1274: darunter das Menue, darueber die Navigation.
    await _pumpHeader(tester, width: 1100, textScale: 1.3);
    expect(find.text('Für Betriebe'), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);

    await _pumpHeader(tester, width: 1300, textScale: 1.3);
    expect(find.text('Für Betriebe'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });
}
