import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw_enums;
import 'package:appwrite/models.dart' as aw;
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/data/repositories/account_repository.dart';

/// T-2.8 bis T-2.10 aus Sicht der App: Alles geht über `my_account`, und es
/// wird nie eine Nutzerkennung mitgeschickt.
void main() {
  test('Löschung beantragen liefert den Termin', () async {
    final fn = _FakeFunctions(200, {
      'ok': true,
      'deletion': {
        'requested_at': '2026-10-20T12:00:00.000Z',
        'delete_after': '2026-11-03T12:00:00.000Z',
      },
    });
    final termin = await AccountRepository(functions: fn).requestDeletion();

    expect(termin, DateTime.utc(2026, 11, 3, 12));
    expect(fn.koerper.single, {'action': 'request_deletion'});
  });

  test('keine Aktion schickt eine Nutzerkennung mit', () async {
    final fn = _FakeFunctions(200, {'ok': true, 'export': {}});
    final repo = AccountRepository(functions: fn);
    await repo.requestDeletion();
    await repo.cancelDeletion();
    await repo.deleteReview('r1');
    await repo.exportJson();

    expect(fn.koerper, [
      {'action': 'request_deletion'},
      {'action': 'cancel_deletion'},
      {'action': 'delete_review', 'review_id': 'r1'},
      {'action': 'export'},
    ]);
    expect(fn.aufrufe.map((a) => a[#functionId]).toSet(), {'my_account'});
  });

  test('der Export ist lesbar formatiertes JSON', () async {
    final fn = _FakeFunctions(200, {
      'ok': true,
      'export': {
        'format': 'karriko-export-1',
        'reviews': [],
      },
    });
    final json = await AccountRepository(functions: fn).exportJson();

    expect(jsonDecode(json), {'format': 'karriko-export-1', 'reviews': []});
    expect(json, contains('\n  '));
  });

  test('reicht die Meldung der Function weiter', () {
    final fn = _FakeFunctions(403, {
      'ok': false,
      'message': 'Ein Betriebskonto lässt sich hier noch nicht löschen.',
    });
    expect(
      AccountRepository(functions: fn).requestDeletion(),
      throwsA(isA<AccountException>()
          .having((e) => e.message, 'message', contains('Betriebskonto'))),
    );
  });
}

class _FakeFunctions implements Functions {
  _FakeFunctions(this.status, this.antwort);

  final int status;
  final Map<String, Object?> antwort;
  final aufrufe = <Map<Symbol, dynamic>>[];

  List<Object?> get koerper =>
      [for (final a in aufrufe) jsonDecode(a[#body] as String)];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createExecution) {
      aufrufe.add(invocation.namedArguments);
      return Future.value(aw.Execution(
        $id: 'e1',
        $createdAt: '',
        $updatedAt: '',
        $permissions: const [],
        functionId: 'my_account',
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
