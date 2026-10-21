import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/company_model.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/data/repositories/company_repository.dart';
import 'package:karriko_flutter/presentation/public/company_detail_screen.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';
import 'package:karriko_flutter/providers/company_provider.dart';

/// T-11.13: „Betrieb nicht gefunden“ nur, wenn es den Betrieb nicht gibt. Ein
/// Netzwerkfehler bekommt eine eigene Meldung mit neuem Versuch.
class _OhneKonto implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _oeffnen(WidgetTester tester, Object fehler) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/firma',
    routes: [
      GoRoute(
        path: '/firma',
        builder: (_, __) => const CompanyDetailScreen(slug: 'musterbau'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_OhneKonto()),
      companyBySlugProvider('musterbau')
          .overrideWith((_) => Future<CompanyModel>.error(fehler)),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('unbekannte Adresse: nicht gefunden', (tester) async {
    await _oeffnen(tester, const CompanyNotFound('musterbau'));

    expect(find.textContaining('nicht\ngefunden'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsNothing);
  });

  testWidgets('Netzwerkfehler: neuer Versuch statt „nicht gefunden“',
      (tester) async {
    await _oeffnen(tester, AppwriteException('Network request failed', 0, ''));

    expect(find.textContaining('nicht laden'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(find.textContaining('nicht\ngefunden'), findsNothing);
  });
}
