import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/presentation/common/route_link.dart';
import 'package:url_launcher/link.dart';

/// T-11.22: Verweise auf App-Seiten sind echte Links, keine Knöpfe.
void main() {
  late GoRouter router;

  Future<void> pump(WidgetTester tester) async {
    router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: RouteLink(
            route: '/blog',
            builder: (_, active) => const Text('Blog'),
          ),
        ),
      ),
      GoRoute(
          path: '/blog', builder: (_, __) => const Scaffold(body: Text('B'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    await tester.pump();
  }

  testWidgets('trägt die Zieladresse als Link', (tester) async {
    await pump(tester);

    final link = tester.widget<Link>(find.byType(Link));
    expect(link.uri.toString(), '/blog');
  });

  testWidgets('Screenreader hören „Link“, nicht „Schaltfläche“',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    final node = tester.getSemantics(find.text('Blog'));
    expect(node.flagsCollection.isLink, isTrue);
    expect(node.flagsCollection.isButton, isFalse);
    handle.dispose();
  });

  // Das Navigieren selbst übernimmt url_launcher über den Navigationskanal
  // der Plattform; das läuft im Testlauf nicht, geprüft im Browser.
}
