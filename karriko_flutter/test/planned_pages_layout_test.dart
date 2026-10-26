import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/planned/planned_catalog.dart';
import 'package:karriko_flutter/presentation/planned/planned_page.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Verhindert Netzwerkzugriffe beim Aufbau des Auth-Zustands im Test.
class _OfflineAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_OfflineAuthRepository()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void _setView(WidgetTester tester, Size size, double scale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Die Grobgerüste aus der Sitemap. Direkt gerendert statt über den Router:
/// Die Seiten hinter der Anmeldung würden sonst abgemeldet aufs Login
/// umgeleitet, und geprüft werden soll das Gerüst selbst.
void main() {
  const sizes = <String, Size>{
    'desktop 1440': Size(1440, 900),
    'tablet 900': Size(900, 1000),
    'phone klein 360': Size(360, 800),
    // Schmalste gängige Breite (iPhone SE 1. Generation); dort fielen die
    // Fehler aus T-11.14 auf (T-7.10).
    'phone schmal 320': Size(320, 568),
  };

  for (final spec in plannedPages) {
    for (final size in sizes.entries) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets(
            '${spec.path} rendert fehlerfrei bei ${size.key}'
            '${scale == 1.0 ? '' : ', Schrift $scale'}', (tester) async {
          _setView(tester, size.value, scale);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: _container(),
              // Eigener kleiner Router: Die Kopfzeile fragt GoRouter nach dem
              // Zurueck-Weg und braucht ihn deshalb im Kontext.
              child: MaterialApp.router(
                theme: AppTheme.light,
                routerConfig: GoRouter(routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, __) =>
                        PlannedPage(spec: spec, subject: 'Beispiel'),
                  ),
                ]),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.text('Inhalt folgt'), findsWidgets);
        });
      }
    }
  }

  testWidgets('Seitenübersicht listet alle Seiten und ist erreichbar',
      (tester) async {
    _setView(tester, const Size(1440, 2400), 1.0);
    final container = _container();
    container.read(routerProvider).go('/seitenuebersicht');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Geplante Seiten'), findsOneWidget);
    expect(find.text('/hilfe'), findsOneWidget);
  });

  test('Jeder Pfad kommt im Katalog nur einmal vor', () {
    final paths = plannedPages.map((p) => p.path).toList();
    expect(paths.toSet().length, paths.length);
  });
}
