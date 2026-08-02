import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/auth/login_choice_screen.dart';
import 'package:karriko_flutter/presentation/auth/login_screen.dart';
import 'package:karriko_flutter/presentation/common/app_bar_widget.dart';
import 'package:karriko_flutter/presentation/common/footer_widget.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Verhindert Netzwerkzugriffe beim Aufbau des Auth-Zustands im Test.
class _OfflineAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(String initialLocation) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginChoiceScreen()),
      GoRoute(
        path: '/login/azubi',
        builder: (_, __) => const LoginScreen(role: LoginRole.azubi),
      ),
      GoRoute(
        path: '/login/betrieb',
        builder: (_, __) => const LoginScreen(role: LoginRole.betrieb),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_OfflineAuthRepository()),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

Future<void> _pumpAt(WidgetTester tester, String location, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(location));
  await tester.pump();
}

void main() {
  // Breite Viewports nutzen das geteilte Raster, schmale stapeln. Kurze und
  // hohe Fenster prüfen, dass die Sektion mitwächst statt abzuschneiden.
  const sizes = <String, Size>{
    'desktop': Size(1440, 900),
    'desktop hoch': Size(1440, 1400),
    'desktop kurz': Size(1200, 560),
    'laptop knapp über Umbruch': Size(1000, 700),
    'tablet': Size(900, 1000),
    'phone': Size(375, 812),
    'phone kurz': Size(360, 640),
  };

  const routes = <String, String>{
    'Auswahl': '/login',
    'Azubi-Login': '/login/azubi',
    'Betrieb-Login': '/login/betrieb',
  };

  routes.forEach((routeName, location) {
    sizes.forEach((sizeName, size) {
      testWidgets('$routeName rendert fehlerfrei bei $sizeName', (tester) async {
        await _pumpAt(tester, location, size);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('$routeName: Footer liegt unterhalb des sichtbaren Bereichs',
        (tester) async {
      const size = Size(1440, 900);
      await _pumpAt(tester, location, size);

      // Der Login-Bereich füllt den Viewport unter der Kopfzeile vollständig,
      // der Footer ist erst nach dem Scrollen sichtbar.
      final footerTop = tester.getTopLeft(find.byType(FooterWidget)).dy;
      expect(footerTop, greaterThanOrEqualTo(size.height));
    });

    testWidgets('$routeName: Kopfzeile bleibt sichtbar', (tester) async {
      await _pumpAt(tester, location, const Size(1440, 900));

      expect(find.byType(KarrikoAppBar), findsOneWidget);
      expect(tester.getTopLeft(find.byType(KarrikoAppBar)).dy, 0);
    });
  });

  testWidgets('Auswahlseite: Panelinhalt sitzt vertikal mittig', (tester) async {
    const size = Size(1440, 900);
    await _pumpAt(tester, '/login', size);

    // Ober- und Unterkante des Panelinhalts gegen die Sektionsgrenzen messen:
    // Bei mittiger Ausrichtung sind beide Abstände gleich groß.
    // Erstes und letztes Kind des Panelinhalts. Beim letzten die Schaltfläche
    // messen, nicht den Textknoten – die Tap-Fläche ist größer als der Text.
    final contentTop = tester.getTopLeft(find.text('ZUGANG WÄHLEN')).dy;
    final contentBottom = tester
        .getBottomLeft(find.widgetWithText(TextButton, 'Als Betrieb registrieren'))
        .dy;

    final topGap = contentTop - KarrikoAppBar.height;
    final bottomGap = size.height - contentBottom;

    expect(topGap, greaterThan(0));
    expect((topGap - bottomGap).abs(), lessThan(4));
  });

  testWidgets('Login-Formular sitzt vertikal mittig', (tester) async {
    const size = Size(1440, 900);
    await _pumpAt(tester, '/login/azubi', size);

    // Die AutofillGroup umschließt exakt den Panelinhalt.
    final content = find.byType(AutofillGroup);
    final contentTop = tester.getTopLeft(content).dy;
    final contentBottom = tester.getBottomLeft(content).dy;

    final topGap = contentTop - KarrikoAppBar.height;
    final bottomGap = size.height - contentBottom;

    expect(topGap, greaterThan(0));
    expect((topGap - bottomGap).abs(), lessThan(4));
  });

  testWidgets('Auswahlseite reicht den next-Parameter weiter', (tester) async {
    await _pumpAt(tester, '/login?next=%2Fbookmarks', const Size(1440, 900));

    await tester.tap(find.text('Ich bin Azubi'));
    await tester.pumpAndSettle();

    expect(find.text('Azubi\nanmelden.'), findsOneWidget);
  });
}
