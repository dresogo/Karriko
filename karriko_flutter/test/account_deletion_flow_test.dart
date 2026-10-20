import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/account_repository.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/providers/account_provider.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// T-2.8 von Anfang bis Ende in der App: beantragen in den Einstellungen,
/// danach nur noch die Rücknahme-Seite, zurücknehmen führt zurück.
///
/// Der Termin steht wie im echten Ablauf erst nach dem Neuladen des Kontos
/// fest: Die Fakes teilen sich [_Konto], so wie `my_account` die Prefs setzt,
/// aus denen `getCurrentUser` liest.
class _Konto {
  DateTime? loeschung;
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.konto);

  final _Konto konto;

  @override
  Future<UserModel?> getCurrentUser() async => UserModel(
        id: 'u1',
        email: 'azubi@karriko.de',
        role: 'azubi',
        firstName: 'Lena',
        lastName: 'Berger',
        emailVerified: true,
        createdAt: DateTime(2026, 3, 14),
        deletionPendingUntil: konto.loeschung,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountRepository implements AccountRepository {
  _FakeAccountRepository(this.konto);

  final _Konto konto;
  final aufrufe = <String>[];

  @override
  Future<DateTime?> requestDeletion() async {
    aufrufe.add('request');
    return konto.loeschung = DateTime.utc(2026, 11, 3, 12);
  }

  @override
  Future<void> cancelDeletion() async {
    aufrufe.add('cancel');
    konto.loeschung = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;

  Future<void> oeffnen(WidgetTester tester, _Konto konto,
      _FakeAccountRepository konten, String route) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(konto)),
      accountRepositoryProvider.overrideWithValue(konten),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ));
    await tester.pump();
    container.read(routerProvider).go(route);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  String ort() => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  testWidgets('beantragen führt auf die Rücknahme-Seite', (tester) async {
    final konto = _Konto();
    final konten = _FakeAccountRepository(konto);
    await oeffnen(tester, konto, konten, '/settings');

    await tester.ensureVisible(find.text('Konto löschen'));
    await tester.pump();
    await tester.tap(find.text('Konto löschen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('in 14 Tagen'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Konto löschen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(konten.aufrufe, ['request']);
    expect(ort(), '/konto-loeschung');
    expect(find.textContaining('03.11.2026'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'kein Überlauf bei 375 px');
  });

  testWidgets('zurücknehmen führt zurück ins Konto', (tester) async {
    final konto = _Konto()..loeschung = DateTime.utc(2026, 11, 3, 12);
    final konten = _FakeAccountRepository(konto);
    await oeffnen(tester, konto, konten, '/dashboard');
    expect(ort(), '/konto-loeschung');

    await tester.ensureVisible(find.text('Löschung zurücknehmen'));
    await tester.pump();
    await tester.tap(find.text('Löschung zurücknehmen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(konten.aufrufe, ['cancel']);
    expect(ort(), '/dashboard');
  });
}
