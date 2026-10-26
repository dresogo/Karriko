import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/common/footer_widget.dart';
import 'package:karriko_flutter/presentation/public/fuer_betriebe_screen.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Verhindert Netzwerkzugriffe beim Aufbau des Auth-Zustands im Test.
class _OfflineAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late GoRouter _router;

Widget _app() {
  _router = GoRouter(
    initialLocation: '/fuer-betriebe',
    routes: [
      GoRoute(
          path: '/fuer-betriebe',
          builder: (_, __) => const FuerBetriebeScreen()),
      GoRoute(
        path: '/register/betrieb',
        builder: (_, __) => const Scaffold(body: Text('Registrierung')),
      ),
      GoRoute(
        path: '/login/betrieb',
        builder: (_, __) => const Scaffold(body: Text('Anmeldung')),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const Scaffold(body: Text('Suche')),
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

String get _currentUri =>
    _router.routerDelegate.currentConfiguration.uri.toString();

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app());
  await tester.pump();
}

void main() {
  const sizes = <String, Size>{
    'breiter Desktop': Size(1920, 1080),
    'desktop': Size(1440, 900),
    'laptop': Size(1200, 800),
    'knapp über dem Split-Umbruch': Size(1000, 900),
    'tablet': Size(900, 1000),
    'schmal knapp über Umbruch': Size(760, 900),
    'phone': Size(375, 812),
    'phone klein': Size(360, 640),
    // Schmalste gängige Breite (iPhone SE 1. Generation); dort fielen die
    // Fehler aus T-11.14 auf (T-7.10).
    'phone schmal 320': Size(320, 568),
  };

  sizes.forEach((sizeName, size) {
    testWidgets('Seite rendert fehlerfrei bei $sizeName', (tester) async {
      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);
    });
  });

  // Vergrößerte Systemschrift verschiebt alle Textmaße und deckt auf, wenn eine
  // Höhe oder Breite im Layout stillschweigend als konstant angenommen wird.
  // Die Kopfzeile selbst prüft app_bar_layout_test.dart.
  sizes.forEach((sizeName, size) {
    testWidgets('Vergrößerte Systemschrift bricht $sizeName nicht',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Inhalte nach Seiten-Tab 13 sind da', (tester) async {
    await _pumpAt(tester, const Size(1440, 4000));

    expect(find.text('FÜR AUSBILDUNGSBETRIEBE'), findsOneWidget);
    expect(find.text('Ist Ihr Betrieb schon auf Karriko?'), findsOneWidget);
    expect(find.text('Was Karriko\nfür Betriebe\nbietet.'), findsOneWidget);
    expect(find.text('In drei Schritten zum Profil.'), findsOneWidget);
    expect(find.text('Was Geld\nnicht kauft.'), findsOneWidget);
    expect(find.text('PLÄNE & PREISE'), findsOneWidget);
    expect(find.text('Kostenlos'), findsOneWidget);
    expect(find.text('In Planung'), findsOneWidget);
    expect(find.text('Gespeichert in Frankfurt.'), findsOneWidget);
    expect(find.text('Was Betriebe uns fragen.'), findsOneWidget);
    expect(find.text('Bereit\nloszulegen?'), findsOneWidget);
  });

  testWidgets('Leistungen sind wie auf der Startseite nummeriert',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 4000));

    for (final number in ['01', '02', '03', '04']) {
      expect(find.text(number), findsOneWidget);
    }
  });

  testWidgets('Hero ist zweispaltig', (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    final kicker = tester.getRect(find.text('FÜR AUSBILDUNGSBETRIEBE'));
    final check =
        tester.getRect(find.text('Ist Ihr Betrieb schon auf Karriko?'));

    // Der Profil-Check liegt rechts neben der Textspalte, nicht darunter.
    expect(check.left, greaterThan(kicker.right));
  });

  testWidgets('Hero-Höhe folgt dem Inhalt, nicht der Bildschirmhöhe',
      (tester) async {
    // Der Startpunkt der Folgesektion markiert das Ende des Heros.
    Future<double> heroEnd(Size size) async {
      await _pumpAt(tester, size);
      return tester
          .getRect(find.text('Was Karriko\nfür Betriebe\nbietet.'))
          .top;
    }

    final kurz = await heroEnd(const Size(1440, 900));
    final lang = await heroEnd(const Size(1440, 1400));

    // Gleiche Breite, deutlich höheres Fenster: der Hero wächst nicht mit.
    expect(kurz, lang);
  });

  testWidgets('Tarifkacheln halten Abstand zu den Rändern und zueinander',
      (tester) async {
    const size = Size(1440, 4000);
    await _pumpAt(tester, size);

    final basis = tester
        .getRect(find.widgetWithText(ElevatedButton, 'Kostenlos starten'));
    final premium =
        tester.getRect(find.widgetWithText(OutlinedButton, 'Interesse melden'));

    expect(basis.left, greaterThan(0));
    expect(premium.right, lessThan(size.width));
    // Gasse zwischen den Kacheln.
    expect(premium.left, greaterThan(basis.right + 16));
  });

  testWidgets('Registrierung ist aus dem Hero erreichbar', (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    await tester.tap(
        find.widgetWithText(ElevatedButton, 'Betriebsprofil anlegen').first);
    await tester.pumpAndSettle();

    expect(find.text('Registrierung'), findsOneWidget);
  });

  testWidgets('Anmelden führt zum Betriebszugang', (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    // Der Filter auf OutlinedButton grenzt gegen die gleichnamige
    // Schaltfläche der Kopfzeile ab.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Anmelden').first);
    await tester.pumpAndSettle();
    expect(_currentUri, '/login/betrieb');
  });

  testWidgets('Profil-Check sucht den Betrieb über die Suche', (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    await tester.enterText(find.byType(TextField), 'Müller GmbH');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Betrieb suchen'));
    await tester.pumpAndSettle();

    expect(Uri.parse(_currentUri).path, '/search');
    expect(Uri.parse(_currentUri).queryParameters['q'], 'Müller GmbH');
  });

  testWidgets('Fragen klappen auf', (tester) async {
    await _pumpAt(tester, const Size(1440, 4000));

    const answerStart = 'Bewertungen werden nicht auf Wunsch entfernt. '
        'Verstößt ein Beitrag';
    expect(find.textContaining(answerStart), findsNothing);

    final question = find.text('Können wir Bewertungen löschen lassen?');
    await tester.ensureVisible(question);
    await tester.tap(question);
    await tester.pump();
    expect(find.textContaining(answerStart), findsOneWidget);
  });

  testWidgets('Footer schließt die Seite ab', (tester) async {
    const size = Size(1440, 900);
    await _pumpAt(tester, size);

    expect(tester.getTopLeft(find.byType(FooterWidget)).dy,
        greaterThan(size.height));
  });

  // T-11.7: Die Seite verspricht nichts, was nicht entschieden ist.
  testWidgets('Keine unentschiedenen Versprechen', (tester) async {
    await _pumpAt(tester, const Size(1440, 4000));

    for (final text in [
      'Auf Bewertungen antworten',
      'Analytics nutzen',
      'Bewerbermanagement',
      'Team-Verwaltung',
      '49 €/Monat',
      'EMPFOHLEN',
      'Premium starten',
      'Auswertung',
    ]) {
      expect(find.text(text), findsNothing, reason: text);
    }
  });
}
