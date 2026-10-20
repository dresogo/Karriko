import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw_enums;
import 'package:appwrite/models.dart' as aw;
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

  group('Schreiben über job_posting (T-4.31)', () {
    test('Anlegen schickt nur Formularfelder, keinen Betrieb', () async {
      final fn = _FakeFunctions(200, {'ok': true, 'job': _stelleJson});
      await JobRepository(functions: fn).createJob(
        title: 'Ausbildung',
        location: 'Dortmund',
        salary: '   ',
        isActive: false,
      );

      final body = jsonDecode(fn.aufrufe.single[#body] as String) as Map;
      expect(fn.aufrufe.single[#functionId], 'job_posting');
      expect(body['action'], 'create');
      final felder = body['fields'] as Map;
      expect(felder['title'], 'Ausbildung');
      expect(felder['is_active'], isFalse);
      for (final feld in [
        'company_id',
        'company',
        'company_slug',
        'company_logo_url',
        'industry',
      ]) {
        expect(felder.containsKey(feld), isFalse, reason: feld);
      }
    });

    test('Bearbeiten schickt alle Felder, auch geleerte', () {
      final felder = JobRepository.fieldsFor(
        title: 'Ausbildung',
        location: 'Dortmund',
        tasks: const [],
        requirements: const [],
        benefits: const [],
        isActive: true,
      );
      expect(felder['salary'], '');
      expect(felder.containsKey('start_date'), isTrue);
      expect(felder['start_date'], isNull);
    });

    test('Zurückziehen und Löschen nennen nur die Stelle', () async {
      final fn = _FakeFunctions(200, {'ok': true, 'job': _stelleJson});
      final repo = JobRepository(functions: fn);
      await repo.setActive(jobId: 'j1', isActive: false);
      await repo.deleteJob('j1');

      expect(
        [for (final a in fn.aufrufe) jsonDecode(a[#body] as String)],
        [
          {'action': 'set_active', 'job_id': 'j1', 'is_active': false},
          {'action': 'delete', 'job_id': 'j1'},
        ],
      );
    });

    test('reicht die Meldung der Function weiter', () {
      final fn = _FakeFunctions(403, {
        'ok': false,
        'code': 'forbidden',
        'message': 'Veröffentlichen geht erst, wenn euer Betrieb verifiziert '
            'ist.',
      });
      expect(
        JobRepository(functions: fn).setActive(jobId: 'j1', isActive: true),
        throwsA(isA<JobPostingException>()
            .having((e) => e.message, 'message', contains('verifiziert'))),
      );
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
              child: BetriebJobsSection(company: _company),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.text('Stelle bearbeiten'), findsOneWidget);
    // Der Schalter nennt seinen Zustand als Text, nicht nur über die Farbe.
    expect(find.textContaining('Wird als Entwurf gespeichert · Aus'),
        findsOneWidget);
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
              child: BetriebJobsSection(company: _company),
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

final _stelleJson = {
  'id': 'j1',
  'created_at': '2026-09-01T00:00:00.000Z',
  'company_id': 'c1',
  'company': 'Musterbau GmbH',
  'company_slug': 'musterbau-gmbh',
  'title': 'Ausbildung',
  'location': 'Dortmund',
  'is_active': false,
};

/// Antwortet auf `createExecution` mit [status] und [antwort] und merkt sich
/// die Argumente.
class _FakeFunctions implements Functions {
  _FakeFunctions(this.status, this.antwort);

  final int status;
  final Map<String, Object?> antwort;
  final aufrufe = <Map<Symbol, dynamic>>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createExecution) {
      aufrufe.add(invocation.namedArguments);
      return Future.value(aw.Execution(
        $id: 'e1',
        $createdAt: '',
        $updatedAt: '',
        $permissions: const [],
        functionId: 'job_posting',
        deploymentId: 'd1',
        trigger: aw_enums.ExecutionTrigger.http,
        status: aw_enums.ExecutionStatus.completed,
        requestMethod: 'POST',
        requestPath: '/',
        requestHeaders: const [],
        responseStatusCode: status,
        responseBody: jsonEncode(antwort),
        responseHeaders: const [],
        logs: '',
        errors: '',
        duration: 0.1,
      ));
    }
    return super.noSuchMethod(invocation);
  }
}
