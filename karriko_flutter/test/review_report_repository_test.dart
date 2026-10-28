import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw_enums;
import 'package:appwrite/models.dart' as aw;
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/data/repositories/review_report_repository.dart';

/// T-4.41 aus Sicht der App: Meldungen gehen über `report_review`, und die
/// Melderkennung wird nie mitgeschickt.
void main() {
  test('schickt Bewertung und Grund, keine Melderkennung', () async {
    final fn = _FakeFunctions(200, {'ok': true, 'report_id': 'm1'});
    await ReviewReportRepository(functions: fn)
        .report(reviewId: 'r1', reason: 'Beleidigung');

    expect(fn.koerper.single, {'review_id': 'r1', 'reason': 'Beleidigung'});
    expect(fn.aufrufe.single[#functionId], 'report_review');
  });

  test('reicht die Meldung der Function weiter', () {
    final fn = _FakeFunctions(429, {
      'ok': false,
      'message': 'Du hast heute schon 5 Meldungen abgegeben.',
    });
    expect(
      ReviewReportRepository(functions: fn)
          .report(reviewId: 'r1', reason: 'Spam'),
      throwsA(isA<ReportException>()
          .having((e) => e.message, 'message', contains('5 Meldungen'))),
    );
  });

  test('ohne lesbare Antwort: allgemeine Meldung', () {
    final fn = _FakeFunctions(500, const {});
    expect(
      ReviewReportRepository(functions: fn)
          .report(reviewId: 'r1', reason: 'Spam'),
      throwsA(isA<ReportException>()),
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
        functionId: 'report_review',
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
