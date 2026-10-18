import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/core/utils/list_field.dart';
import 'package:karriko_flutter/data/models/company_model.dart';
import 'package:karriko_flutter/data/models/job_model.dart';
import 'package:karriko_flutter/data/repositories/job_repository.dart';
import 'package:karriko_flutter/presentation/betrieb/widgets/jobs_section.dart';
import 'package:karriko_flutter/providers/company_provider.dart';
import 'package:karriko_flutter/providers/job_provider.dart';

/// Merkt sich jeden Aufruf, statt Appwrite zu fragen.
class _FakeJobRepository implements JobRepository {
  final List<JobModel> stellen;
  final aufrufe = <Invocation>[];

  _FakeJobRepository([this.stellen = const []]);

  Iterable<Invocation> aufrufeVon(Symbol name) =>
      aufrufe.where((a) => a.memberName == name);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    aufrufe.add(invocation);
    if (invocation.memberName == #jobsForCompany) {
      return Future.value(stellen);
    }
    if (invocation.memberName == #updateJob) {
      return Future<JobModel>.value(stellen.first);
    }
    return super.noSuchMethod(invocation);
  }
}

final _stelle = JobModel(
  id: 'j1',
  companyId: 'c1',
  company: 'Musterbau GmbH',
  companySlug: 'musterbau-gmbh',
  title: 'Ausbildung Maurer (m/w/d)',
  location: 'Dortmund',
  profession: 'Maurer',
  employmentType: 'Ausbildung',
  salary: '1. Jahr 1.050 €',
  tasks: const ['Mauern', 'Putzen'],
  isActive: false,
  createdAt: DateTime(2026, 9, 1),
);

final _company = CompanyModel(
  id: 'c1',
  slug: 'musterbau-gmbh',
  name: 'Musterbau GmbH',
  city: 'Dortmund',
  industry: 'Handwerk',
  reviewCount: 0,
  isPremium: false,
  isVerified: false,
  ownerId: 'b1',
  createdAt: DateTime(2026, 2, 9),
);

void main() {
  group('Zeilenaufteilung bei Aufgaben und Anforderungen', () {
    test('eine Zeile ist ein Punkt', () {
      expect(splitListField('Kunden beraten\nLager pflegen'),
          ['Kunden beraten', 'Lager pflegen']);
    });

    test('Leerzeilen und Leerraum fallen weg', () {
      expect(splitListField('\n  Kunden beraten  \n\n\n   \nLager pflegen\n'),
          ['Kunden beraten', 'Lager pflegen']);
    });

    test('führende Aufzählungszeichen fallen weg', () {
      expect(
        splitListField('- Bindestrich\n• Punkt\n* Stern\n  -   eingerückt'),
        ['Bindestrich', 'Punkt', 'Stern', 'eingerückt'],
      );
    });

    test('Zeichen mitten im Text bleiben stehen', () {
      expect(splitListField('Vor- und Nachbereitung\nA * B'),
          ['Vor- und Nachbereitung', 'A * B']);
    });

    test('Windows-Zeilenenden aus Word', () {
      expect(splitListField('Eins\r\nZwei\r\n'), ['Eins', 'Zwei']);
    });

    test('leeres Feld ergibt keine Punkte', () {
      expect(splitListField(''), isEmpty);
      expect(splitListField('\n \n- \n'), isEmpty);
    });
  });

  group('Entwurf ist nicht öffentlich', () {
    test('ein Entwurf ist nur für den Eigentümer lesbar', () {
      final rechte =
          JobRepository.permissionsFor(ownerId: 'b1', isActive: false);
      expect(rechte, contains(Permission.read(Role.user('b1'))));
      expect(rechte, isNot(contains(Permission.read(Role.any()))));
    });

    test('eine veröffentlichte Stelle ist für alle lesbar', () {
      final rechte =
          JobRepository.permissionsFor(ownerId: 'b1', isActive: true);
      expect(rechte, contains(Permission.read(Role.any())));
    });

    test('ändern und löschen darf in beiden Fällen nur der Eigentümer', () {
      for (final aktiv in [true, false]) {
        final rechte =
            JobRepository.permissionsFor(ownerId: 'b1', isActive: aktiv);
        expect(rechte, contains(Permission.update(Role.user('b1'))));
        expect(rechte, contains(Permission.delete(Role.user('b1'))));
        expect(
            rechte
                .where((r) => r.startsWith('update') || r.startsWith('delete')),
            everyElement(contains('user:b1')));
      }
    });

    test('das öffentliche Profil fragt nur veröffentlichte Stellen an',
        () async {
      final repo = _FakeJobRepository();
      final container = ProviderContainer(overrides: [
        jobRepositoryProvider.overrideWithValue(repo),
        companyBySlugProvider('musterbau-gmbh')
            .overrideWith((ref) async => _company),
      ]);
      addTearDown(container.dispose);

      await container.read(companyJobsProvider('musterbau-gmbh').future);

      final aufruf = repo.aufrufeVon(#jobsForCompany).single;
      expect(aufruf.positionalArguments.single, 'c1');
      expect(aufruf.namedArguments[#onlyActive] ?? true, isTrue);
    });

    test('die eigene Verwaltung sieht auch Entwürfe', () async {
      final repo = _FakeJobRepository();
      final container = ProviderContainer(overrides: [
        jobRepositoryProvider.overrideWithValue(repo),
        myCompanyProvider.overrideWith((ref) async => _company),
      ]);
      addTearDown(container.dispose);

      await container.read(myJobsProvider.future);

      expect(
        repo.aufrufeVon(#jobsForCompany).single.namedArguments[#onlyActive],
        isFalse,
      );
    });
  });

  group('Daten einer Stelle', () {
    Map<String, dynamic> payload({required bool leeren}) =>
        JobRepository.payloadFor(
          companyId: 'c1',
          companyName: 'Musterbau GmbH',
          companySlug: 'musterbau-gmbh',
          title: '  Ausbildung  ',
          location: 'Dortmund',
          salary: '   ',
          tasks: const [],
          requirements: const [],
          benefits: const [],
          isActive: true,
          leereFelderLeeren: leeren,
        );

    test('beim Anlegen fallen leere Felder weg', () {
      final daten = payload(leeren: false);
      expect(daten['title'], 'Ausbildung');
      expect(daten.containsKey('salary'), isFalse);
      expect(daten.containsKey('start_date'), isFalse);
    });

    test('beim Bearbeiten werden geleerte Felder auf null gesetzt', () {
      final daten = payload(leeren: true);
      expect(daten.containsKey('salary'), isTrue);
      expect(daten['salary'], isNull);
      expect(daten.containsKey('start_date'), isTrue);
      expect(daten['start_date'], isNull);
    });
  });

  testWidgets('Bearbeiten füllt das Formular und speichert die Stelle',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _FakeJobRepository([_stelle]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jobRepositoryProvider.overrideWithValue(repo),
          myCompanyProvider.overrideWith((ref) async => _company),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BetriebJobsSection(company: _company, ownerId: 'b1'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.text('Stelle bearbeiten'), findsOneWidget);
    expect(find.text('Ausbildung Maurer (m/w/d)'), findsOneWidget);
    expect(find.text('Mauern\nPutzen'), findsOneWidget);
    // Weitere Stelle anlegen geht erst, wenn das Formular zu ist.
    expect(find.text('Weitere Stelle erstellen'), findsNothing);

    await tester.enterText(find.text('1. Jahr 1.050 €'), '');
    await tester.ensureVisible(find.text('Änderungen speichern'));
    await tester.tap(find.text('Änderungen speichern'));
    await tester.pumpAndSettle();

    final aufruf = repo.aufrufeVon(#updateJob).single;
    expect(aufruf.namedArguments[#jobId], 'j1');
    expect(aufruf.namedArguments[#ownerId], 'b1');
    expect(aufruf.namedArguments[#salary], '');
    // Ein Entwurf bleibt beim Speichern ein Entwurf.
    expect(aufruf.namedArguments[#isActive], isFalse);
    expect(repo.aufrufeVon(#createJob), isEmpty);
    expect(find.text('Änderungen am Entwurf gespeichert.'), findsOneWidget);
  });

  testWidgets('Formular ohne Titel speichert nicht', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _FakeJobRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jobRepositoryProvider.overrideWithValue(repo),
          myCompanyProvider.overrideWith((ref) async => _company),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BetriebJobsSection(company: _company, ownerId: 'b1'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stelle erstellen'));
    await tester.pumpAndSettle();

    // Der Standort kommt aus dem Profil; nur der Titel fehlt.
    await tester.ensureVisible(find.text('Veröffentlichen'));
    await tester.tap(find.text('Veröffentlichen'));
    await tester.pumpAndSettle();

    expect(find.text('Titel ist erforderlich'), findsOneWidget);
    expect(repo.aufrufeVon(#createJob), isEmpty);
  });
}
