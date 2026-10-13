import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Verhindert Netzwerkzugriffe beim Aufbau des Auth-Zustands im Test.
class _OfflineAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Die öffentlichen Seiten ohne eigenen Layout-Test, abgemeldet aufgerufen.
///
/// Statisch oder mit Formular, aber ohne Daten aus Appwrite: Was sie zeigen,
/// hängt nur von Breite und Schriftgröße ab.
Future<void> _open(
  WidgetTester tester,
  String route,
  Size size,
  double scale,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_OfflineAuthRepository()),
    ],
  );
  addTearDown(container.dispose);

  // Direkt auf der Zielseite starten: Ueber die Startseite zu gehen hiesse,
  // deren Ueberlaeufe hier mitzupruefen, und dafuer gibt es einen eigenen
  // Test.
  container.read(routerProvider).go(route);

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
}

void main() {
  const routes = <String, String>{
    'Über uns': '/ueber-uns',
    'Kontakt': '/kontakt',
    'FAQ': '/faq',
    'Impressum': '/impressum',
    'Datenschutz': '/datenschutz',
    'AGB': '/agb',
    'Registrierung Betrieb': '/register/betrieb',
    'Passwort vergessen': '/forgot-password',
    'Passwort zurücksetzen': '/reset-password',
  };

  const sizes = <String, Size>{
    'desktop 1440': Size(1440, 900),
    'laptop 1200': Size(1200, 800),
    'knapp über Umbruch': Size(1000, 700),
    'tablet 900': Size(900, 1000),
    'schmal 760': Size(760, 900),
    'phone 375': Size(375, 812),
    'phone klein 360': Size(360, 640),
  };

  routes.forEach((name, route) {
    sizes.forEach((sizeName, size) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets(
            '$name rendert fehlerfrei bei $sizeName'
            '${scale == 1.0 ? '' : ', Schrift $scale'}', (tester) async {
          await _open(tester, route, size, scale);
          expect(tester.takeException(), isNull);
        });
      }
    });
  });
}
