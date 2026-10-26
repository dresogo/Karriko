import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/common/fit_words_text.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

import 'support/word_breaks.dart';

/// T-11.14: Bei 320 px bricht kein Wort mitten im Wort um.
///
/// Mit der echten Inter-Schrift: Die Testschrift von Flutter hat viel
/// breitere Zeichen und meldete Brüche, die es im Browser nicht gibt.

class _OfflineAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _ladeInter() async {
  final loader = FontLoader(AppFonts.family)
    ..addFont(rootBundle.load('assets/fonts/inter/Inter-Regular.ttf'));
  await loader.load();
}

void main() {
  setUpAll(_ladeInter);

  const routes = [
    '/',
    '/fuer-betriebe',
    '/blog',
    '/ueber-uns',
    '/kontakt',
    '/faq',
    '/impressum',
    '/datenschutz',
    '/agb',
    '/login',
    '/login/azubi',
    '/login/betrieb',
    '/login/azubi/magic',
    '/register/azubi',
    '/register/betrieb',
    '/forgot-password',
    '/reset-password',
  ];

  for (final route in routes) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('$route bei 320 px${scale == 1.0 ? '' : ', Schrift $scale'}',
          (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final container = ProviderContainer(overrides: [
          authRepositoryProvider.overrideWithValue(_OfflineAuthRepository()),
        ]);
        addTearDown(container.dispose);
        container.read(routerProvider).go(route);

        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: ref.watch(routerProvider),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(midWordBreaks(tester), isEmpty);
      });
    }
  }

  group('FitWordsText', () {
    Future<double> schrift(
        WidgetTester tester, String text, double breite) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: breite,
            child: FitWordsText(text, style: const TextStyle(fontSize: 48)),
          ),
        ),
      ));
      // Das einzige Absatz-Objekt unter FitWordsText.
      final absatz = tester.allRenderObjects
          .whereType<RenderParagraph>()
          .firstWhere((r) => r.text.toPlainText() == text);
      return absatz.textScaler.scale(48);
    }

    testWidgets('bleibt bei genug Platz in der Grundgröße', (tester) async {
      expect(await schrift(tester, 'Bewertungen', 1000), 48);
    });

    testWidgets('verkleinert, bis das längste Wort passt', (tester) async {
      expect(
          await schrift(tester, 'Bewertungen\nfür duale', 200), lessThan(48));
      expect(midWordBreaks(tester), isEmpty);
    });
  });
}
