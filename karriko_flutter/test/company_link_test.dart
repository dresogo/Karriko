import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/company_model.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/data/repositories/company_repository.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';
import 'package:karriko_flutter/providers/company_provider.dart';

/// Prueft die Verknuepfung zwischen Betriebskonto und `companies`-Dokument.
///
/// Vor dieser Verknuepfung schrieb das Unternehmensprofil nirgendwohin: Dem
/// Konto fehlte jede Firma, gegen die es haette speichern koennen. Die Tests
/// hier halten fest, dass die Verknuepfung besteht und benutzt wird.

CompanyModel _company({
  String id = 'c1',
  String name = 'Musterbau GmbH',
  String? city = 'Dortmund',
}) =>
    CompanyModel(
      id: id,
      slug: 'musterbau-gmbh',
      name: name,
      city: city,
      industry: 'Handwerk',
      reviewCount: 0,
      isPremium: false,
      isVerified: false,
      ownerId: 'b1',
      createdAt: DateTime(2026, 2, 9),
    );

final _betrieb = UserModel(
  id: 'b1',
  email: 'kontakt@musterbau.de',
  role: 'betrieb',
  firstName: 'Jonas',
  lastName: 'Keller',
  companyName: 'Musterbau GmbH',
  companyId: 'c1',
  emailVerified: true,
  createdAt: DateTime(2026, 2, 9),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.company});

  final CompanyModel? company;
  int ensureAufrufe = 0;

  @override
  Future<UserModel?> getCurrentUser() async => _betrieb;

  @override
  Future<CompanyModel?> ensureCompany(UserModel user) async {
    ensureAufrufe++;
    return company;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCompanyRepository implements CompanyRepository {
  /// Mitgeschriebene Aufrufe von [updateCompanyProfile].
  final gespeichert = <Map<String, String?>>[];

  @override
  Future<CompanyModel> updateCompanyProfile({
    required String companyId,
    String? name,
    String? description,
    String? website,
    String? logoUrl,
    String? city,
    String? country,
    String? industry,
  }) async {
    gespeichert.add({
      'companyId': companyId,
      'name': name,
      'city': city,
      'industry': industry,
    });
    return _company(name: name ?? 'Musterbau GmbH', city: city);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _oeffneProfil(
  WidgetTester tester, {
  required _FakeAuthRepository auth,
  required _FakeCompanyRepository companies,
}) async {
  tester.view.physicalSize = const Size(1440, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      companyRepositoryProvider.overrideWithValue(companies),
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
  container.read(routerProvider).go('/betrieb-profile');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('companySlug', () {
    test('schreibt Umlaute aus, statt sie zu verschlucken', () {
      // "mller-gmbh" waere das Ergebnis eines reinen Filters - fuer den
      // DACH-Markt ist das kein Randfall, sondern der Normalfall.
      expect(companySlug('Müller GmbH'), 'mueller-gmbh');
      expect(companySlug('Schrödinger & Söhne'), 'schroedinger-soehne');
      expect(companySlug('Weißbier AG'), 'weissbier-ag');
    });

    test('faellt auf Kleinbuchstaben, Ziffern und Bindestriche zurueck', () {
      expect(companySlug('Meyer & Co. KG'), 'meyer-co-kg');
      expect(companySlug('3M Deutschland'), '3m-deutschland');
    });

    test('laesst keine Bindestriche am Rand stehen', () {
      expect(companySlug('  Bosch  '), 'bosch');
      expect(companySlug('- Siemens -'), 'siemens');
    });

    test('liefert nie eine leere Adresse', () {
      // Ein Name ganz ohne lateinische Buchstaben ergaebe sonst einen Slug,
      // der auf die Sammelseite statt auf ein Unternehmen zeigt.
      expect(companySlug('***'), 'unternehmen');
      expect(companySlug(''), 'unternehmen');
    });
  });

  group('Unternehmensprofil', () {
    testWidgets('speichert gegen die verknuepfte Firmen-ID', (tester) async {
      final auth = _FakeAuthRepository(company: _company());
      final companies = _FakeCompanyRepository();
      await _oeffneProfil(tester, auth: auth, companies: companies);

      await tester.tap(find.text('Bearbeiten'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Musterbau GmbH'),
        'Musterbau Holding GmbH',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(companies.gespeichert, hasLength(1),
          reason: 'updateCompanyProfile hatte vorher null Aufrufer');
      expect(companies.gespeichert.single['companyId'], 'c1');
      expect(companies.gespeichert.single['name'], 'Musterbau Holding GmbH');
    });

    testWidgets('meldet den Erfolg, statt eine Einschraenkung zu behaupten',
        (tester) async {
      final auth = _FakeAuthRepository(company: _company());
      final companies = _FakeCompanyRepository();
      await _oeffneProfil(tester, auth: auth, companies: companies);

      await tester.tap(find.text('Bearbeiten'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('gespeichert'), findsWidgets);
      expect(find.textContaining('nur für diese Sitzung'), findsNothing);
    });

    testWidgets('ohne Firma bleibt Bearbeiten verschlossen', (tester) async {
      // Laesst sich die Firma nicht beschaffen, waere ein Formular ohne
      // Speicherziel schlimmer als gar keines: Es verspraeche wieder etwas,
      // das nicht passiert.
      final auth = _FakeAuthRepository(company: null);
      final companies = _FakeCompanyRepository();
      await _oeffneProfil(tester, auth: auth, companies: companies);

      expect(find.text('Bearbeiten'), findsNothing);
      expect(companies.gespeichert, isEmpty);
    });

    testWidgets('holt die Firma ueber ensureCompany, nicht ueber die rohe ID',
        (tester) async {
      // Konten aus der Zeit vor der Verknuepfung haben keine company_id. Ginge
      // die Seite direkt an user.companyId, blieben sie dauerhaft ohne Firma.
      final auth = _FakeAuthRepository(company: _company());
      await _oeffneProfil(
        tester,
        auth: auth,
        companies: _FakeCompanyRepository(),
      );

      expect(auth.ensureAufrufe, greaterThan(0));
    });
  });
}
