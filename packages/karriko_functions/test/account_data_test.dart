import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' as aw;
import 'package:karriko_functions/karriko_functions.dart';
import 'package:test/test.dart';

/// T-2.8 bis T-2.10: Was bei einer Kontolöschung bleibt und was geht, was eine
/// gelöschte Bewertung mitnimmt und was der Export enthält.
void main() {
  group('Kontolöschung, reine Regeln', () {
    test('nur veröffentlichte Bewertungen bleiben', () {
      expect(keepReviewOnAccountDeletion('approved'), isTrue);
      for (final s in ['pending_moderation', 'scheduled', 'rejected', null]) {
        expect(keepReviewOnAccountDeletion(s), isFalse, reason: '$s');
      }
    });

    test('eine erhaltene Bewertung verliert Konto, Gerätehash und Nachweis',
        () {
      expect(detachReviewFromUser('r1'), {
        'user_id': 'geloescht-r1',
        'device_hash': null,
        'verification_file_id': null,
      });
    });

    test('Frist 14 Tage (E-50)', () {
      final antrag = DateTime.utc(2026, 10, 20, 12);
      expect(deletionDueAt(antrag), DateTime.utc(2026, 11, 3, 12));
    });
  });

  group('Export (Art. 20)', () {
    final export = buildAccountExport(
      exportedAt: DateTime.utc(2026, 10, 20),
      account: {'name': 'Mia', 'email': 'mia@example.org'},
      profile: {r'$id': 'u1', 'first_name': 'Mia', 'role': 'azubi'},
      reviews: [
        ExportRow('r1', '2026-10-01T00:00:00Z', {
          'company_id': 'c1',
          'status': 'approved',
          'freitext_gut': 'Gute Betreuung',
          'answers_json': '{"k1": 4}',
          'user_id': 'u1',
          'device_hash': 'abc',
          'quality_flags': 'too_fast',
          'quality_notes': 'x',
          'timings_json': '{}',
          'verification_file_id': 'f1',
          'sub_fachlich': 4.2,
        }),
      ],
      drafts: [
        ExportRow('d1', '2026-10-02T00:00:00Z',
            {'company_id': 'c2', 'answers_json': '{"k1": 2}'}),
      ],
      bookmarks: [
        ExportRow('b1', '2026-10-03T00:00:00Z',
            {'user_id': 'u1', 'company_id': 'c1'}),
      ],
      reports: [
        ExportRow('m1', '2026-10-04T00:00:00Z',
            {'review_id': 'r9', 'reporter_id': 'u1', 'reason': 'Beleidigung'}),
      ],
      passkeys: [
        ExportRow('p1', '2026-10-05T00:00:00Z', {
          'userId': 'u1',
          'deviceName': 'Laptop',
          'createdAt': '2026-10-05T00:00:00Z',
          'lastUsedAt': null,
          'backedUp': true,
          'credentialId': 'cred',
          'publicKey': 'key',
          'signCount': 3,
        }),
      ],
      companyNames: {'c1': 'Musterbau GmbH', 'c2': 'Beispiel AG'},
    );

    test('enthält die selbst eingegebenen Daten, lesbar', () {
      final r = (export['reviews'] as List).single as Map;
      expect(r['freitext_gut'], 'Gute Betreuung');
      expect(r['answers_json'], {'k1': 4}, reason: 'JSON entpackt');
      expect(r['company_name'], 'Musterbau GmbH');
      expect((export['drafts'] as List).single,
          containsPair('company_name', 'Beispiel AG'));
      expect((export['bookmarks'] as List).single,
          containsPair('company_name', 'Musterbau GmbH'));
      expect((export['reports'] as List).single,
          containsPair('reason', 'Beleidigung'));
    });

    test('ohne interne Prüfmerkmale und Rechenwerte', () {
      final r = (export['reviews'] as List).single as Map;
      for (final feld in [
        'user_id',
        'device_hash',
        'quality_flags',
        'quality_notes',
        'timings_json',
        'verification_file_id',
        'sub_fachlich',
      ]) {
        expect(r.containsKey(feld), isFalse, reason: feld);
      }
      expect(
          ((export['reports'] as List).single as Map)['reporter_id'], isNull);
    });

    test('Passkeys mit Gerätename und Zeiten, ohne Prüfdaten (T-2.43)', () {
      final p = (export['passkeys'] as List).single as Map;
      expect(p['deviceName'], 'Laptop');
      expect(p['backedUp'], isTrue);
      for (final feld in ['userId', 'credentialId', 'publicKey', 'signCount']) {
        expect(p.containsKey(feld), isFalse, reason: feld);
      }
    });

    test('ohne Appwrite-Metadaten im Profil', () {
      expect((export['profile'] as Map).containsKey(r'$id'), isFalse);
    });
  });

  group('purgeAccount', () {
    test('behält Veröffentlichtes ohne Bezug, löscht den Rest und das Konto',
        () async {
      final t = _FakeTables(
        reviews: [
          _row('r1', {'status': 'approved', 'verification_file_id': 'f1'}),
          _row('r2', {'status': 'pending_moderation'}),
        ],
        drafts: [_row('d1', {})],
        bookmarks: [_row('b1', {})],
        meldungen: [_row('m1', {})],
        passkeys: [_row('p1', {})],
        hatProfil: true,
      );
      final u = _FakeUsers();
      final log = <String>[];

      final ergebnis =
          await purgeAccount(tables: t, users: u, userId: 'u1', log: log.add);

      expect(ergebnis, PurgeResult.deleted);
      expect(
          t.aktualisiert,
          containsPair('reviews/r1', {
            'user_id': 'geloescht-r1',
            'device_hash': null,
            'verification_file_id': null,
          }));
      expect(t.dateienGeloescht, ['f1']);
      expect(
          t.geloescht,
          containsAll([
            'reviews/r2',
            'review_drafts/d1',
            'bookmarks/b1',
            'passkeys/p1',
            'profiles/u1',
            'account_deletions/u1',
          ]));
      expect(t.geloescht, isNot(contains('reviews/r1')));
      expect(
          t.aktualisiert['review_reports/m1'], {'reporter_id': 'geloescht-m1'});
      expect(u.geloescht, ['u1']);
      expect(t.geloescht.last, 'account_deletions/u1',
          reason: 'Der Antrag geht zuletzt, damit ein Abbruch nachholbar ist.');
      expect(log.join(), isNot(contains('u1')), reason: 'E-53');
    });

    test('überspringt Konten mit Firma (T-2.24)', () async {
      final t = _FakeTables(hatFirma: true);
      final u = _FakeUsers();
      expect(
        await purgeAccount(tables: t, users: u, userId: 'u1', log: (_) {}),
        PurgeResult.skipped,
      );
      expect(u.geloescht, isEmpty);
      expect(t.geloescht, isEmpty);
    });

    test('ein schon gelöschtes Konto hält den Lauf nicht an', () async {
      final t = _FakeTables();
      final u = _FakeUsers(fehlt: true);
      expect(
        await purgeAccount(tables: t, users: u, userId: 'u1', log: (_) {}),
        PurgeResult.deleted,
      );
      expect(t.geloescht, contains('account_deletions/u1'));
    });
  });
}

aw.Row _row(String id, Map<String, Object?> data) => aw.Row(
      $id: id,
      $sequence: '1',
      $tableId: 't',
      $databaseId: 'd',
      $createdAt: '2026-10-01T00:00:00Z',
      $updatedAt: '2026-10-01T00:00:00Z',
      $permissions: const [],
      data: data,
    );

class _FakeTables implements Tables {
  _FakeTables({
    this.reviews = const [],
    this.drafts = const [],
    this.bookmarks = const [],
    this.meldungen = const [],
    this.passkeys = const [],
    this.hatProfil = false,
    this.hatFirma = false,
  });

  final List<aw.Row> reviews, drafts, bookmarks, meldungen, passkeys;
  final bool hatProfil, hatFirma;

  final geloescht = <String>[];
  final aktualisiert = <String, Map<String, Object?>>{};
  final dateienGeloescht = <String>[];

  @override
  final config = FunctionConfig.fromEnvironment({
    'APPWRITE_FUNCTION_PROJECT_ID': 'p',
    'KARRIKO_DATABASE_ID': 'd',
  });

  @override
  Future<aw.Row?> companyByOwner(String ownerId) async =>
      hatFirma ? _row('c1', {}) : null;
  @override
  Future<List<aw.Row>> allReviewsByUser(String userId) async => reviews;
  @override
  Future<List<aw.Row>> draftsByUser(String userId) async => drafts;
  @override
  Future<List<aw.Row>> bookmarksByUser(String userId) async => bookmarks;
  @override
  Future<List<aw.Row>> reportsByReporter(String userId) async => meldungen;
  @override
  Future<List<aw.Row>> passkeysByUser(String userId) async => passkeys;
  @override
  Future<List<aw.Row>> reportsForReview(String reviewId) async => const [];
  @override
  Future<aw.Row?> findPublicReview(String reviewId) async => null;
  @override
  Future<aw.Row?> getProfile(String userId) async =>
      hatProfil ? _row(userId, {}) : null;

  @override
  Future<void> deleteRow(String tableId, String id) async =>
      geloescht.add('$tableId/$id');
  @override
  Future<void> deleteDraft(String id) async =>
      geloescht.add('${config.draftsTable}/$id');
  @override
  Future<aw.Row> updateRowData(
      String tableId, String id, Map<String, Object?> data) async {
    aktualisiert['$tableId/$id'] = data;
    return _row(id, data);
  }

  @override
  Future<void> deleteVerificationFile(String fileId) async =>
      dateienGeloescht.add(fileId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUsers implements Users {
  _FakeUsers({this.fehlt = false});

  final bool fehlt;
  final geloescht = <String>[];

  @override
  Future<dynamic> delete({required String userId}) async {
    if (fehlt) throw AppwriteException('User not found', 404, 'user_not_found');
    geloescht.add(userId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
