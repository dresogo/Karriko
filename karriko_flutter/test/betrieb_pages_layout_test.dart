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

final _betrieb = UserModel(
  id: 'b1',
  email: 'kontakt@musterbau.de',
  role: 'betrieb',
  firstName: 'Jonas',
  lastName: 'Keller',
  companyName: 'Musterbau GmbH',
  emailVerified: true,
  createdAt: DateTime(2026, 2, 9),
);

late ProviderContainer _container;

Future<void> _open(WidgetTester tester, String route, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_betrieb))
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
    'Betrieb-Dashboard': '/betrieb-dashboard',
    'Unternehmensprofil': '/betrieb-profile',
    'Betrieb-Einstellungen': '/betrieb-settings',
  };

  routes.forEach((name, route) {
    sizes.forEach((sizeName, size) {
      testWidgets('$name rendert fehlerfrei bei $sizeName', (tester) async {
        await _open(tester, route, size);
        expect(tester.takeException(), isNull);
      });
    });
  });

  testWidgets('Dashboard zeigt den echten Unternehmensnamen', (tester) async {
    await _open(tester, '/betrieb-dashboard', const Size(1440, 900));

    expect(find.text('Musterbau GmbH'), findsOneWidget);
    // Die erfundenen Kennzahlen von frueher duerfen nicht zurueckkehren.
    expect(find.text('4.2'), findsNothing);
    expect(find.text('1.2k'), findsNothing);
    expect(find.textContaining('noch nicht angebunden'), findsOneWidget);
  });

  testWidgets('Dashboard verlinkt alle Betriebsbereiche', (tester) async {
    await _open(tester, '/betrieb-dashboard', const Size(1440, 900));

    for (final title in [
      'Bewertungen',
      'Unternehmensprofil',
      'Analytics',
      'Team'
    ]) {
      expect(find.text(title), findsWidgets, reason: 'Kachel „$title" fehlt');
    }
    // Team und Berichte waren zuvor nur ueber die URL erreichbar.
    expect(find.text('Bewertungen melden'), findsOneWidget);
  });

  testWidgets('Unternehmensprofil nutzt keinen erfundenen Namen',
      (tester) async {
    await _open(tester, '/betrieb-profile', const Size(1440, 900));

    expect(find.text('Musterbetrieb GmbH'), findsNothing);
    expect(find.text('Musterbau GmbH'), findsWidgets);
    expect(find.textContaining('noch nicht dauerhaft gespeichert'),
        findsOneWidget);
  });

  testWidgets('Betriebs-Einstellungen benennen den Schalterzustand',
      (tester) async {
    await _open(tester, '/betrieb-settings', const Size(1440, 900));

    expect(find.textContaining('E-Mail bei jeder neuen Bewertung · An'),
        findsOneWidget);
    expect(
        find.textContaining('Neue Funktionen und Tipps · Aus'), findsOneWidget);
  });

  testWidgets('Einstellungen fuehren auf das Team', (tester) async {
    await _open(tester, '/betrieb-settings', const Size(1440, 900));

    // Die Konto-Sektion ist um Passkeys und Zwei-Faktor-Bestaetigung
    // gewachsen; 'Team' liegt dadurch unterhalb der Sichtkante.
    await tester.ensureVisible(find.text('Team'));
    await tester.pump();
    await tester.tap(find.text('Team'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      _container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      '/team',
    );
  });

  testWidgets('Profilmenue zeigt die Betriebsrolle', (tester) async {
    // Von den Einstellungen aus, weil das Dashboard „BETRIEB" schon als
    // Eyebrow traegt und der Treffer sonst nicht eindeutig waere.
    await _open(tester, '/betrieb-settings', const Size(1440, 900));

    await tester.tap(find.byTooltip('Profilmenü öffnen'));
    await tester.pumpAndSettle();

    expect(find.text('BETRIEB'), findsOneWidget);
    expect(find.text('kontakt@musterbau.de'), findsWidgets);
  });
}
