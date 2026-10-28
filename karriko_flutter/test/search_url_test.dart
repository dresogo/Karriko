import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/company_model.dart';
import 'package:karriko_flutter/data/models/job_model.dart';
import 'package:karriko_flutter/data/repositories/company_repository.dart';
import 'package:karriko_flutter/presentation/public/search_screen.dart';
import 'package:karriko_flutter/providers/company_provider.dart';
import 'package:karriko_flutter/providers/job_provider.dart';

/// T-11.17: Suchbegriff und Filter stehen in der Adresse, damit sich eine
/// Suche teilen und nach dem Neuladen wiederherstellen lässt.
class _FakeCompanyRepository implements CompanyRepository {
  final suchen = <Map<String, Object?>>[];

  @override
  Future<List<CompanyModel>> searchCompanies({
    String? query,
    String? industry,
    String? city,
    double? minRating,
    int limit = 20,
    int offset = 0,
  }) async {
    suchen.add({
      'query': query,
      'industry': industry,
      'city': city,
      'minRating': minRating,
    });
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final adressen = <String>[];

  setUp(() {
    adressen.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.navigation, (call) async {
      if (call.method == 'routeInformationUpdated') {
        final args = call.arguments as Map;
        adressen.add((args['uri'] ?? args['location']).toString());
      }
      return null;
    });
  });

  Future<_FakeCompanyRepository> oeffnen(
      WidgetTester tester, String adresse) async {
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _FakeCompanyRepository();
    final router = GoRouter(
      initialLocation: adresse,
      routes: [
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        companyRepositoryProvider.overrideWithValue(repo),
        jobSuggestionsProvider.overrideWith((_) async => const <JobModel>[]),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return repo;
  }

  testWidgets('Filter aus der Adresse kommen in der Suche an', (tester) async {
    final repo = await oeffnen(
        tester, '/search?q=Bau&branche=Handwerk&ort=Dortmund&sterne=3');

    expect(repo.suchen.last, {
      'query': 'Bau',
      'industry': 'Handwerk',
      'city': 'Dortmund',
      'minRating': 3.0,
    });
  });

  testWidgets('Bewertungsfilter mit Nachkommastelle (T-6.30)', (tester) async {
    final repo = await oeffnen(tester, '/search?bewertung=3.5');

    expect(repo.suchen.last['minRating'], 3.5);
    expect(adressen.last, contains('bewertung=3.5'));
  });

  testWidgets('Stufen außerhalb von 3, 3,5 und 4 werden ignoriert',
      (tester) async {
    final repo = await oeffnen(tester, '/search?sterne=2');

    expect(repo.suchen.last['minRating'], isNull);
  });

  testWidgets('Bewertungsregler: Stufe antippen sucht und schreibt die Adresse',
      (tester) async {
    final repo = await oeffnen(tester, '/search');

    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Alle Bewertungen'), findsOneWidget);

    await tester.tap(find.text('3,5'));
    await tester.pump();

    expect(repo.suchen.last['minRating'], 3.5);
    expect(adressen.last, contains('bewertung=3.5'));
    expect(find.text('ab 3,5 von 5'), findsOneWidget);
  });

  testWidgets('Bewertungsregler: per Tastatur eine Stufe weiter',
      (tester) async {
    final repo = await oeffnen(tester, '/search?bewertung=3');

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(repo.suchen.last['minRating'], 3.5);
  });

  testWidgets('Bewertungsregler legt keine Fläche über die Seite (T-11.26)',
      (tester) async {
    final semantik = tester.ensureSemantics();
    await oeffnen(tester, '/search');

    // Der Wert-Indikator des Sliders landet im nächsten Overlay. Ist das
    // das Overlay des Navigators, deckt ein leerer Semantik-Knoten die ganze
    // Seite ab, und im Web reagiert kein Link mehr auf Klicks.
    final overlay = find
        .ancestor(of: find.byType(Slider), matching: find.byType(Overlay))
        .first;
    expect(tester.getSize(overlay).height, lessThanOrEqualTo(44));

    // Kein leerer Knoten ohne Text und Aktion in Bildschirmgröße.
    final bildschirm = tester.view.physicalSize / tester.view.devicePixelRatio;
    final leer = <SemanticsNode>[];
    void pruefen(SemanticsNode knoten) {
      final daten = knoten.getSemanticsData();
      final rect = knoten.rect;
      if (knoten.childrenCount == 0 &&
          daten.label.isEmpty &&
          daten.actions == 0 &&
          rect.width >= bildschirm.width &&
          rect.height >= bildschirm.height) {
        leer.add(knoten);
      }
      knoten.visitChildren((kind) {
        pruefen(kind);
        return true;
      });
    }

    pruefen(tester
        .binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
    expect(leer, isEmpty);
    semantik.dispose();
  });

  testWidgets('Bewertungsregler: Wechsel der Seite räumt sauber auf',
      (tester) async {
    await oeffnen(tester, '/search?bewertung=3');
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(find.text('ab 4 von 5'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('unbekannte Branche wird ignoriert', (tester) async {
    final repo = await oeffnen(tester, '/search?branche=Erfunden');

    expect(repo.suchen.last['industry'], isNull);
  });

  testWidgets('die Suche schreibt sich in die Adresse', (tester) async {
    await oeffnen(tester, '/search?ort=Dortmund');

    expect(adressen.last, contains('ort=Dortmund'));
  });
}
