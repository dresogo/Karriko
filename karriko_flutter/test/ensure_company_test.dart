import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/data/models/company_model.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/data/repositories/company_repository.dart';

/// `company_profile` nimmt seit T-4.25 nur Konten mit bestaetigter Adresse an. Die
/// Firma entsteht deshalb nicht mehr bei der Registrierung, sondern in
/// [AuthRepository.ensureCompany]. Was bei der Registrierung eingegeben
/// wurde, darf dabei nicht verloren gehen: Branche und Ort liegen in den
/// Account-Prefs.

class _FakeAccount implements Account {
  _FakeAccount(this.prefs);

  final Map<String, dynamic> prefs;

  @override
  Future<aw.Preferences> getPrefs() async => aw.Preferences(data: prefs);

  // `_linkCompany` schreibt die Verknuepfung zurueck; ein Fehler dort wird
  // geschluckt und ist fuer diese Tests ohne Belang.
  @override
  Future<aw.User> updatePrefs({required Map prefs}) =>
      Future.error(AppwriteException('nicht im Test', 500, 'test'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTablesDB implements TablesDB {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #updateRow) {
      return Future<aw.Row>.error(
          AppwriteException('Row not found', 404, 'row_not_found'));
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeCompanyRepository implements CompanyRepository {
  _FakeCompanyRepository({this.vorhanden});

  final CompanyModel? vorhanden;
  final angelegt = <Map<String, String?>>[];

  @override
  Future<CompanyModel?> findCompanyByOwner(String ownerId) async => vorhanden;

  @override
  Future<CompanyModel> createCompany({
    required String name,
    String? industry,
    String? city,
  }) async {
    angelegt.add({'name': name, 'industry': industry, 'city': city});
    return _firma(name: name, industry: industry, city: city);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CompanyModel _firma({
  String id = 'c1',
  String name = 'Musterbau GmbH',
  String? industry,
  String? city,
}) =>
    CompanyModel(
      id: id,
      slug: 'musterbau-gmbh',
      name: name,
      industry: industry,
      city: city,
      reviewCount: 0,
      isPremium: false,
      isVerified: false,
      ownerId: 'b1',
      createdAt: DateTime(2026, 10, 20),
    );

final _betrieb = UserModel(
  id: 'b1',
  email: 'kontakt@musterbau.de',
  role: 'betrieb',
  companyName: 'Musterbau GmbH',
  emailVerified: true,
  createdAt: DateTime(2026, 10, 20),
);

AuthRepository _repo(
        _FakeCompanyRepository firmen, Map<String, dynamic> prefs) =>
    AuthRepository(
      companyRepository: firmen,
      account: _FakeAccount(prefs),
      db: _FakeTablesDB(),
    );

void main() {
  test('legt die Firma mit Branche und Ort aus den Prefs an', () async {
    final firmen = _FakeCompanyRepository();
    final firma = await _repo(firmen, {
      'role': 'betrieb',
      'company_name': 'Musterbau GmbH',
      'industry': 'Handwerk',
      'city': 'Dortmund',
    }).ensureCompany(_betrieb);

    expect(firmen.angelegt, [
      {'name': 'Musterbau GmbH', 'industry': 'Handwerk', 'city': 'Dortmund'},
    ]);
    expect(firma?.city, 'Dortmund');
  });

  test('leere oder fehlende Angaben werden zu null', () async {
    final firmen = _FakeCompanyRepository();
    await _repo(firmen, {'industry': '  '}).ensureCompany(_betrieb);

    expect(firmen.angelegt.single['industry'], isNull);
    expect(firmen.angelegt.single['city'], isNull);
  });

  test('legt keine zweite Firma an, wenn es schon eine gibt', () async {
    final firmen = _FakeCompanyRepository(vorhanden: _firma(id: 'alt'));
    final firma =
        await _repo(firmen, {'industry': 'Handwerk'}).ensureCompany(_betrieb);

    expect(firmen.angelegt, isEmpty);
    expect(firma?.id, 'alt');
  });
}
