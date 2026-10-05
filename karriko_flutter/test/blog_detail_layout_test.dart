import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/blog_content.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/public/blog_detail_screen.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Verhindert Netzwerkzugriffe beim Aufbau des Auth-Zustands im Test.
class _OfflineAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late GoRouter _router;

Widget _app(String initialLocation) {
  _router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/blog',
        builder: (_, s) => Scaffold(body: Text('Übersicht ${s.uri}')),
      ),
      GoRoute(
        path: '/blog/:slug',
        builder: (_, s) => BlogDetailScreen(slug: s.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const Scaffold(body: Text('Suche')),
      ),
      GoRoute(
        path: '/fuer-betriebe',
        builder: (_, __) => const Scaffold(body: Text('Für Betriebe')),
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

void main() {
  const sizes = <String, Size>{
    'desktop': Size(1440, 900),
    'tablet': Size(900, 1000),
    'phone': Size(375, 812),
    'phone klein': Size(360, 640),
  };

  for (final article in BlogContent.articles) {
    sizes.forEach((sizeName, size) {
      testWidgets('„${article.slug}" rendert fehlerfrei bei $sizeName',
          (tester) async {
        await _pumpAt(tester, '/blog/${article.slug}', size);
        expect(tester.takeException(), isNull);
        expect(find.text(article.title), findsOneWidget);
      });
    });
  }

  testWidgets('Jeder Artikel zeigt seinen eigenen Text', (tester) async {
    await _pumpAt(tester, '/blog/dsgvo-bewertungen', const Size(1440, 900));

    // Überschriften stehen zusätzlich im Inhaltsverzeichnis.
    expect(find.text('Was Azubis wissen sollten'), findsWidgets);
    expect(find.text('Erst klären, was du willst'), findsNothing);
  });

  testWidgets('Unbekannter Slug zeigt einen Hinweis mit Rückweg',
      (tester) async {
    await _pumpAt(tester, '/blog/gibt-es-nicht', const Size(1440, 900));

    expect(find.text('Artikel nicht gefunden'), findsOneWidget);

    await tester.tap(find.text('Zur Übersicht'));
    await tester.pumpAndSettle();
    expect(find.text('Übersicht /blog'), findsOneWidget);
  });

  testWidgets('Inhaltsverzeichnis springt zur Zwischenüberschrift',
      (tester) async {
    await _pumpAt(
        tester, '/blog/tipps-ausbildungsbetrieb', const Size(1440, 900));

    // Der Text steht im Baum vor dem Inhaltsverzeichnis der Seitenspalte.
    final heading = find.text('Fazit').first;
    expect(tester.getTopLeft(heading).dy, greaterThan(900));

    final tocItem = find.bySemanticsLabel(RegExp('Zu Abschnitt 4 springen'));
    await tester.ensureVisible(tocItem);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(heading).dy, greaterThan(900));

    await tester.tap(tocItem);
    await tester.pumpAndSettle();

    final dy = tester.getTopLeft(heading).dy;
    expect(dy, inInclusiveRange(0, 900));
  });

  testWidgets('Inhaltsverzeichnis läuft beim Scrollen mit', (tester) async {
    await _pumpAt(
        tester, '/blog/tipps-ausbildungsbetrieb', const Size(1440, 900));

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();

    final toc = find.text('IN DIESEM ARTIKEL');
    expect(tester.getTopLeft(toc).dy, inInclusiveRange(0, 900));
  });

  testWidgets('Weiterlesen verlinkt andere Artikel', (tester) async {
    await _pumpAt(
        tester, '/blog/tipps-ausbildungsbetrieb', const Size(1440, 900));

    final related =
        find.bySemanticsLabel('Artikel: DSGVO und Ausbildungsbewertungen');
    await tester.scrollUntilVisible(related, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(related);
    await tester.pumpAndSettle();

    expect(find.text('Was Azubis wissen sollten'), findsWidgets);
  });

  testWidgets('Brotkrumen führen zur gefilterten Übersicht', (tester) async {
    await _pumpAt(tester, '/blog/dsgvo-bewertungen', const Size(1440, 900));

    await tester.tap(find.widgetWithText(TextButton, 'Artikel'));
    await tester.pumpAndSettle();

    expect(find.text('Übersicht /blog?typ=artikel'), findsOneWidget);
  });
}
