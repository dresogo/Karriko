import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/public/blog_screen.dart';
import 'package:karriko_flutter/presentation/common/footer_widget.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Verhindert Netzwerkzugriffe beim Aufbau des Auth-Zustands im Test.
class _OfflineAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _featuredArticle = 'Wie finde ich den richtigen Ausbildungsbetrieb?';

late GoRouter _router;

Widget _app(String initialLocation) {
  _router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/blog', builder: (_, __) => const BlogScreen()),
      GoRoute(
        path: '/blog/:slug',
        builder: (_, s) =>
            Scaffold(body: Text('Detail: ${s.pathParameters['slug']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_OfflineAuthRepository()),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: _router),
  );
}

Future<void> _pumpAt(WidgetTester tester, String location, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(location));
  await tester.pump();
}

String get _currentUri =>
    _router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  const sizes = <String, Size>{
    'desktop': Size(1440, 900),
    'laptop': Size(1200, 800),
    'tablet': Size(900, 1000),
    'schmal knapp über Umbruch': Size(760, 900),
    'phone': Size(375, 812),
    'phone klein': Size(360, 640),
  };

  const locations = <String, String>{
    'Alle': '/blog',
    'Artikel': '/blog?typ=artikel',
    'Produkt-Updates': '/blog?typ=updates',
  };

  locations.forEach((filterName, location) {
    sizes.forEach((sizeName, size) {
      // Normale und vergrößerte Systemschrift: deckt auf, wo eine Höhe
      // oder Breite stillschweigend als konstant angenommen wird.
      for (final scale in const [1.0, 1.3]) {
        testWidgets(
            'Filter „$filterName" rendert fehlerfrei bei $sizeName${scale == 1.0 ? '' : ', Schrift $scale'}',
            (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await _pumpAt(tester, location, size);
          expect(tester.takeException(), isNull);
        });
      }
    });
  });

  testWidgets('Ungefiltert erscheinen die Artikel', (tester) async {
    await _pumpAt(tester, '/blog', const Size(1440, 900));

    expect(find.text(_featuredArticle), findsOneWidget);
  });

  testWidgets('Filter „Artikel" zeigt den Aufmacher', (tester) async {
    await _pumpAt(tester, '/blog?typ=artikel', const Size(1440, 900));

    expect(find.text(_featuredArticle), findsOneWidget);
  });

  // Bis zum Launch gibt es keine Produkt-Updates (T-11.8). Die Rubrik sagt das,
  // statt Versionen zu erfinden.
  testWidgets('Filter „Produkt-Updates" ist ehrlich leer', (tester) async {
    await _pumpAt(tester, '/blog?typ=updates', const Size(1440, 900));

    expect(find.text('Nichts gefunden'), findsOneWidget);
    expect(find.text(_featuredArticle), findsNothing);
    expect(find.textContaining('AUFMACHER'), findsNothing);
    expect(find.textContaining('v1.'), findsNothing);
  });

  testWidgets('Filterwechsel schreibt sich in die URL', (tester) async {
    await _pumpAt(tester, '/blog', const Size(1440, 900));
    expect(_currentUri, '/blog');

    await tester.tap(find.text('Produkt-Updates'));
    await tester.pumpAndSettle();

    expect(_currentUri, '/blog?typ=updates');
    expect(find.text(_featuredArticle), findsNothing);
  });

  testWidgets('Artikel führt auf seine Detailseite', (tester) async {
    await _pumpAt(tester, '/blog', const Size(1440, 900));

    await tester.tap(find.text(_featuredArticle));
    await tester.pumpAndSettle();

    expect(find.text('Detail: tipps-ausbildungsbetrieb'), findsOneWidget);
  });

  testWidgets('Footer liegt unter dem Inhalt und die Seite scrollt',
      (tester) async {
    const size = Size(1440, 900);
    await _pumpAt(tester, '/blog', size);

    // Der Footer schließt die Seite ab und ist ohne Scrollen nicht sichtbar.
    expect(tester.getTopLeft(find.byType(FooterWidget)).dy,
        greaterThan(size.height));
  });
}
