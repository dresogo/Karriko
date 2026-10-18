import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/core/constants/appwrite_constants.dart';
import 'package:karriko_flutter/data/repositories/company_repository.dart';

aw.Row _row(String id, Map<String, dynamic> data) => aw.Row(
      $id: id,
      $sequence: '1',
      $tableId: 't',
      $databaseId: 'd',
      $createdAt: '2026-09-01T10:00:00.000Z',
      $updatedAt: '2026-09-01T10:00:00.000Z',
      $permissions: const [],
      data: data,
    );

Map<String, dynamic> _firma(String id) => {
      'slug': 'firma-$id',
      'name': 'Firma $id',
      'review_count': 0,
    };

/// Spielt die Tabellen nach, statt Appwrite zu fragen, und merkt sich jeden
/// Aufruf. `listRows` liefert je Tabelle die hinterlegten Zeilen.
class _FakeTablesDB implements TablesDB {
  _FakeTablesDB({this.listen = const {}, this.firmen = const {}});

  final Map<String, List<aw.Row>> listen;
  final Map<String, Map<String, dynamic>> firmen;
  final aufrufe = <Invocation>[];

  Iterable<Invocation> von(Symbol name) =>
      aufrufe.where((a) => a.memberName == name);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    aufrufe.add(invocation);
    final args = invocation.namedArguments;
    switch (invocation.memberName) {
      case #listRows:
        final rows = listen[args[#tableId]] ?? const <aw.Row>[];
        return Future.value(aw.RowList(total: rows.length, rows: rows));
      case #getRow:
        final id = args[#rowId] as String;
        final daten = firmen[id];
        if (daten == null) {
          return Future<aw.Row>.error(
              AppwriteException('Row not found', 404, 'row_not_found'));
        }
        return Future.value(_row(id, daten));
      case #createRow:
        return Future.value(
            _row('neu', Map<String, dynamic>.from(args[#data] as Map)));
      case #updateRow:
        return Future.value(_row(args[#rowId] as String, const {}));
      case #deleteRow:
        return Future<dynamic>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('Merkliste', () {
    test('ein Betrieb wird nur einmal gemerkt', () async {
      final db = _FakeTablesDB(listen: {
        AppwriteConstants.bookmarksTable: [
          _row('b1', {'user_id': 'u1', 'company_id': 'c1'}),
        ],
      });
      await CompanyRepository(db: db).bookmarkCompany('u1', 'c1');

      expect(db.von(#createRow), isEmpty);
    });

    test('neuer Eintrag ist nur für das eigene Konto lesbar und löschbar',
        () async {
      final db = _FakeTablesDB();
      await CompanyRepository(db: db).bookmarkCompany('u1', 'c1');

      final aufruf = db.von(#createRow).single.namedArguments;
      expect(aufruf[#data], {'user_id': 'u1', 'company_id': 'c1'});
      expect(aufruf[#permissions], [
        Permission.read(Role.user('u1')),
        Permission.delete(Role.user('u1')),
      ]);
    });

    test('Entfernen löscht den gefundenen Eintrag', () async {
      final db = _FakeTablesDB(listen: {
        AppwriteConstants.bookmarksTable: [
          _row('b7', {'user_id': 'u1', 'company_id': 'c1'}),
        ],
      });
      await CompanyRepository(db: db).removeBookmark('u1', 'c1');

      expect(db.von(#deleteRow).single.namedArguments[#rowId], 'b7');
    });

    test('Entfernen ohne Eintrag löscht nichts', () async {
      final db = _FakeTablesDB();
      await CompanyRepository(db: db).removeBookmark('u1', 'c1');

      expect(db.von(#deleteRow), isEmpty);
    });

    test('fragt nur die Einträge des eigenen Kontos ab', () async {
      final db = _FakeTablesDB();
      await CompanyRepository(db: db).getBookmarkedCompanies('u1');

      final queries =
          db.von(#listRows).single.namedArguments[#queries] as List<String>;
      expect(queries, contains(Query.equal('user_id', 'u1')));
    });

    test('ein gelöschter Betrieb fällt weg, statt die Liste zu sprengen',
        () async {
      final db = _FakeTablesDB(
        listen: {
          AppwriteConstants.bookmarksTable: [
            _row('b1', {'user_id': 'u1', 'company_id': 'c1'}),
            _row('b2', {'user_id': 'u1', 'company_id': 'weg'}),
          ],
        },
        firmen: {'c1': _firma('c1')},
      );
      final liste =
          await CompanyRepository(db: db).getBookmarkedCompanies('u1');

      expect(liste.map((c) => c.id), ['c1']);
    });

    test('andere Fehler gehen weiter nach oben', () async {
      final db = _FailingTablesDB();
      expect(
        CompanyRepository(db: db).getBookmarkedCompanies('u1'),
        throwsA(isA<AppwriteException>()),
      );
    });
  });

  group('Suche', () {
    Future<List<String>> queriesFuer({
      String? query,
      String? industry,
      String? city,
      double? minRating,
    }) async {
      final db = _FakeTablesDB();
      await CompanyRepository(db: db).searchCompanies(
        query: query,
        industry: industry,
        city: city,
        minRating: minRating,
      );
      return db.von(#listRows).single.namedArguments[#queries] as List<String>;
    }

    test('ohne Filter nur Sortierung und Seite', () async {
      final queries = await queriesFuer();
      expect(queries, [
        Query.orderDesc('average_rating'),
        Query.limit(20),
        Query.offset(0),
      ]);
    });

    test('„Alle Branchen“ filtert nicht', () async {
      final queries = await queriesFuer(industry: 'Alle Branchen', query: '');
      expect(queries, hasLength(3));
    });

    test('Filter werden zu Abfragen', () async {
      final queries = await queriesFuer(
        query: 'Bäckerei',
        industry: 'Handwerk',
        city: 'Dortmund',
        minRating: 3.5,
      );
      expect(
        queries,
        containsAll([
          Query.search('name', 'Bäckerei'),
          Query.equal('industry', 'Handwerk'),
          Query.search('city', 'Dortmund'),
          Query.greaterThanEqual('average_rating', 3.5),
        ]),
      );
    });

    test('Vorschläge erst ab zwei Zeichen', () async {
      final db = _FakeTablesDB();
      final vorschlaege =
          await CompanyRepository(db: db).getSearchSuggestions('B');

      expect(vorschlaege, isEmpty);
      expect(db.aufrufe, isEmpty);
    });
  });

  group('Profil bearbeiten', () {
    test('ändert nur übergebene Felder und nie den Slug', () async {
      final db = _FakeTablesDB(firmen: {'c1': _firma('c1')});
      await CompanyRepository(db: db)
          .updateCompanyProfile(companyId: 'c1', name: 'Neu GmbH');

      final daten = db.von(#updateRow).single.namedArguments[#data];
      expect(daten, {'name': 'Neu GmbH'});
    });
  });
}

/// Jeder Lesezugriff scheitert wie bei fehlender Verbindung.
class _FailingTablesDB extends _FakeTablesDB {
  _FailingTablesDB()
      : super(listen: {
          AppwriteConstants.bookmarksTable: [
            _row('b1', {'user_id': 'u1', 'company_id': 'c1'}),
          ],
        });

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getRow) {
      return Future<aw.Row>.error(
          AppwriteException('Network request failed', 0, ''));
    }
    return super.noSuchMethod(invocation);
  }
}
