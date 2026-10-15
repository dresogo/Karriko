import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/company_model.dart';
import 'package:karriko_flutter/data/models/public_review.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/public/company_detail_screen.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';
import 'package:karriko_flutter/providers/company_provider.dart';
import 'package:karriko_flutter/providers/job_provider.dart';
import 'package:karriko_flutter/providers/review_provider.dart';

/// T-6.16: „Bewerten" auf dem Unternehmensprofil muss den Betrieb mitgeben.
///
/// Ohne `?company=` beginnt der Fragebogen bei der Betriebsauswahl, und der
/// Azubi sucht den Betrieb, von dessen Profil er gerade kommt, noch einmal.

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

final _azubi = UserModel(
  id: 'a1',
  email: 'lea@example.com',
  role: 'azubi',
  firstName: 'Lea',
  lastName: 'Brandt',
  emailVerified: true,
  createdAt: DateTime(2026, 2, 9),
);

class _AzubiAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => _azubi;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/firma',
    routes: [
      GoRoute(
        path: '/firma',
        builder: (_, __) => CompanyDetailScreen(slug: _company.slug),
      ),
      GoRoute(
        path: '/reviews/new',
        builder: (_, s) =>
            Text('Fragebogen für ${s.uri.queryParameters['company']}'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AzubiAuthRepository()),
        companyBySlugProvider(_company.slug).overrideWith((_) => _company),
        companyJobsProvider(_company.slug).overrideWith((_) => const []),
        companyReviewsProvider(_company.id)
            .overrideWith((_) => const <PublicReview>[]),
        companyScoresProvider(_company.id).overrideWith((_) => null),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  test('bewertenRoute haengt die Betriebskennung als Query an', () {
    expect(bewertenRoute('c1'), '/reviews/new?company=c1');
  });

  for (final knopf in ['Betrieb bewerten', 'Jetzt bewerten']) {
    testWidgets('„$knopf" öffnet den Fragebogen mit dem Betrieb',
        (tester) async {
      final router = await _open(tester);

      final ziel = find.text(knopf);
      await tester.ensureVisible(ziel);
      await tester.tap(ziel);
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/reviews/new?company=c1',
      );
      expect(find.text('Fragebogen für c1'), findsOneWidget);
    });
  }
}
