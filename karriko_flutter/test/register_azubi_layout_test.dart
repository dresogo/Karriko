import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

class _AbgemeldetesRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late ProviderContainer _container;

Future<void> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_AbgemeldetesRepository()),
      passkeySupportProvider.overrideWithValue(true),
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
  await tester.pump(const Duration(milliseconds: 50));

  _container.read(routerProvider).go('/register/azubi');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Alle Breiten, die auch die uebrigen Layout-Tests abdecken.
const _breiten = [360.0, 375.0, 414.0, 768.0, 1024.0, 1440.0];

void main() {
  group('Kein Ueberlauf', () {
    for (final breite in _breiten) {
      testWidgets('bei ${breite.toInt()} px', (tester) async {
        await _open(tester, Size(breite, 900));

        // Der Schrittinhalt scrollt jetzt innerhalb des Rahmens. Vorher stand
        // dort eine Column mit Spacer, die auf schmalen Fenstern ueberlief.
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('bei 1,3-facher Systemschrift', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _open(tester, const Size(375, 900));

      expect(tester.takeException(), isNull);
    });
  });

  group('Reihenfolge der Schritte', () {
    // Die PageView baut nur die sichtbare Seite. Was zu finden ist, steht
    // also auf dem gerade angezeigten Schritt.
    testWidgets('Zugangsdaten stehen an erster Stelle', (tester) async {
      await _open(tester, const Size(1440, 900));

      expect(
          find.widgetWithText(TextFormField, 'E-Mail-Adresse'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Passwort'), findsOneWidget);
      // Die persoenlichen Daten kommen erst danach.
      expect(find.widgetWithText(TextFormField, 'Vorname'), findsNothing);
    });

    testWidgets('Die Wege ohne Passwort stehen beim ersten Schritt',
        (tester) async {
      await _open(tester, const Size(1440, 900));

      expect(find.text('E-Mail-Link'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('Passkeys werden hier nicht angeboten, sondern erklaert',
        (tester) async {
      // Ein Passkey haengt an einem bestehenden Konto – der Dienst verlangt
      // eine Sitzung. „Mit Passkey registrieren" gibt es deshalb nicht.
      await _open(tester, const Size(1440, 900));

      expect(find.text('Passkey'), findsNothing);
      expect(
        find.textContaining('nach der Registrierung in den Einstellungen'),
        findsOneWidget,
      );
    });

    testWidgets('AGB-Zustimmung und Registrieren stehen erst am Ende',
        (tester) async {
      // Zustimmung gehoert zu der Handlung, die sie erlaubt – nicht an den
      // Anfang, wo sie zwei Schritte vor dem Absenden abgehakt wuerde.
      await _open(tester, const Size(1440, 900));

      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('Registrieren'), findsNothing);
    });
  });
}
