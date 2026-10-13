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

late ProviderContainer _container;

Future<void> _open(WidgetTester tester, String route, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_OfflineAuthRepository()),
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
}

String get _location => _container
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

void main() {
  const sizes = <String, Size>{
    'desktop 1440': Size(1440, 900),
    'phone 375': Size(375, 812),
    'phone klein 360': Size(360, 640),
  };

  sizes.forEach((name, size) {
    testWidgets('Fehlerseite rendert fehlerfrei bei $name', (tester) async {
      await _open(tester, '/gibt-es-nicht', size);

      expect(find.text('Diese Seite gibt es nicht.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Fehlerseite zeigt den Pfad, aber nicht die Query',
      (tester) async {
    await _open(tester, '/gibt-es-nicht?secret=geheim', const Size(1440, 900));

    expect(find.textContaining('/gibt-es-nicht'), findsOneWidget);
    expect(find.textContaining('geheim'), findsNothing);
  });

  testWidgets('Fehlerseite fuehrt zur Startseite', (tester) async {
    await _open(tester, '/gibt-es-nicht', const Size(1440, 900));

    await tester.tap(find.text('Zur Startseite'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(_location, '/');
  });

  testWidgets('Fehlerseite fuehrt zur Suche', (tester) async {
    await _open(tester, '/gibt-es-nicht', const Size(1440, 900));

    await tester.tap(find.text('Betrieb suchen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(_location, '/search');
  });
}
