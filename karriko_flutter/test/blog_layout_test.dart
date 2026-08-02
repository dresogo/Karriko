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
const _updateTitle = 'Fragebogen für Betriebsbewertungen';

late GoRouter _router;

Widget _app(String initialLocation) {
  _router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/blog', builder: (_, __) => const BlogScreen()),
      GoRoute(
        path: '/blog/:slug',
        builder: (_, s) => Scaffold(body: Text('Detail: ${s.pathParameters['slug']}')),
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

String get _currentUri => _router.routerDelegate.currentConfiguration.uri.toString();

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
      testWidgets('Filter „$filterName" rendert fehlerfrei bei $sizeName',
          (tester) async {
        await _pumpAt(tester, location, size);
        expect(tester.takeException(), isNull);
      });
    });
  });

  testWidgets('Ungefiltert erscheinen Artikel und Produkt-Updates', (tester) async {
    await _pumpAt(tester, '/blog', const Size(1440, 900));

    expect(find.text(_featuredArticle), findsOneWidget);
    expect(find.text(_updateTitle), findsOneWidget);
  });

  testWidgets('Filter „Artikel" blendet Produkt-Updates aus', (tester) async {
    await _pumpAt(tester, '/blog?typ=artikel', const Size(1440, 900));

    expect(find.text(_featuredArticle), findsOneWidget);
    expect(find.text(_updateTitle), findsNothing);
  });

  testWidgets('Filter „Produkt-Updates" blendet Artikel und Aufmacher aus',
      (tester) async {
    await _pumpAt(tester, '/blog?typ=updates', const Size(1440, 900));

    expect(find.text(_updateTitle), findsOneWidget);
    expect(find.text(_featuredArticle), findsNothing);
    expect(find.textContaining('AUFMACHER'), findsNothing);
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

  testWidgets('Footer liegt unter dem Inhalt und die Seite scrollt', (tester) async {
    const size = Size(1440, 900);
    await _pumpAt(tester, '/blog', size);

    // Der Footer schließt die Seite ab und ist ohne Scrollen nicht sichtbar.
    expect(tester.getTopLeft(find.byType(FooterWidget)).dy, greaterThan(size.height));
  });
}
