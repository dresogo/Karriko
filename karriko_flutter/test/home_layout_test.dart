import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/common/app_bar_widget.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Verhindert Netzwerkzugriffe beim Aufbau des Auth-Zustands im Test.
class _OfflineAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _unterzeile =
    'Finde deinen Ausbildungsbetrieb, lies echte\nErfahrungsberichte und triff bessere Entscheidungen.';

Future<void> _open(WidgetTester tester, Size size, double scale) async {
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
  const sizes = <String, Size>{
    'breiter Desktop': Size(1920, 1080),
    'desktop 1440': Size(1440, 900),
    'laptop 1200': Size(1200, 800),
    'knapp über Umbruch': Size(1000, 700),
    'tablet 900': Size(900, 1000),
    'phone 375': Size(375, 812),
    'phone klein 360': Size(360, 640),
    // Schmalste gängige Breite (iPhone SE 1. Generation); dort fielen die
    // Fehler aus T-11.14 auf (T-7.10).
    'phone schmal 320': Size(320, 568),
  };

  sizes.forEach((name, size) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets(
          'Startseite rendert fehlerfrei bei $name'
          '${scale == 1.0 ? '' : ', Schrift $scale'}', (tester) async {
        await _open(tester, size, scale);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // Die Unterzeile sitzt am unteren Rand der Textspalte, 40 px Innenabstand.
  // Daran laesst sich die Hoehe des Hero ablesen, ohne private Klassen.
  const breite = Size(1440, 900);
  const heroUnterkante = 900 - KarrikoAppBar.height;

  testWidgets('Hero fuellt bei normaler Schrift genau den Bildschirm',
      (tester) async {
    await _open(tester, breite, 1.0);

    expect(
      tester.getBottomLeft(find.text(_unterzeile)).dy,
      moreOrLessEquals(KarrikoAppBar.height + heroUnterkante - 40),
    );
  });

  testWidgets('Hero waechst mit grosser Schrift, statt ueberzulaufen',
      (tester) async {
    await _open(tester, breite, 1.3);

    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.text(_unterzeile)).dy,
      greaterThan(KarrikoAppBar.height + heroUnterkante - 40),
    );
    // Die Suche rutscht mit und bleibt an der Unterkante.
    expect(
      tester.getBottomLeft(find.byType(TextField)).dy,
      greaterThan(KarrikoAppBar.height + heroUnterkante - 64),
    );
  });
}
