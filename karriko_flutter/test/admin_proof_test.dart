import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/admin_models.dart';
import 'package:karriko_flutter/data/repositories/admin_repository.dart';
import 'package:karriko_flutter/presentation/admin/admin_providers.dart';
import 'package:karriko_flutter/presentation/admin/sections/log_section.dart';
import 'package:karriko_flutter/presentation/admin/sections/moderation_section.dart';

/// T-2.20: Die Moderation öffnet einen Nachweis über `moderation_desk`, nicht
/// mehr über die Console, und das Öffnen steht im Protokoll.
class _FakeAdminRepository implements AdminRepository {
  final geoeffnet = <String>[];

  @override
  Future<ProofFile> openProof(String reviewId) async {
    geoeffnet.add(reviewId);
    return const ProofFile(bytes: [1, 2, 3], mimeType: 'application/pdf');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _zeigen(WidgetTester tester, Widget kind,
    {AdminRepository? repo}) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      if (repo != null) adminRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: kind)),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('mit Nachweis: „Nachweis ansehen“ lädt ihn über die Function',
      (tester) async {
    final repo = _FakeAdminRepository();
    await _zeigen(
      tester,
      const ReviewCard(
        item: QueueItem(
          reviewId: 'r1',
          status: 'pending_moderation',
          hasVerification: true,
        ),
      ),
      repo: repo,
    );

    await tester.tap(find.text('Nachweis ansehen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repo.geoeffnet, ['r1']);
    expect(find.text('Nachweis geladen.'), findsOneWidget);
    expect(find.text('Öffnen'), findsOneWidget);
  });

  testWidgets('ohne Nachweis kein Knopf', (tester) async {
    await _zeigen(
      tester,
      const ReviewCard(
        item: QueueItem(reviewId: 'r1', status: 'pending_moderation'),
      ),
      repo: _FakeAdminRepository(),
    );
    expect(find.text('Nachweis ansehen'), findsNothing);
  });

  testWidgets('das Protokoll zeigt das Öffnen nicht als Ablehnung',
      (tester) async {
    await _zeigen(
      tester,
      const LogRow(
        entry: ModerationLogItem(logId: 'l1', action: 'proof_viewed'),
      ),
    );
    expect(find.text('Nachweis geöffnet'), findsOneWidget);
    expect(find.text('Abgelehnt'), findsNothing);
  });
}
