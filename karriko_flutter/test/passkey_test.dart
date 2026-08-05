import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/passkey_credential.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/auth/widgets/passkey_button.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

UserModel _user({String role = 'azubi'}) => UserModel(
      id: 'u1',
      email: 'azubi@example.com',
      role: role,
      emailVerified: true,
      createdAt: DateTime(2026, 1, 1),
    );

class _PasskeyRepository implements AuthRepository {
  _PasskeyRepository({
    this.user,
    this.fehler,
    this.passkeys = const [],
  });

  final UserModel? user;
  final Object? fehler;
  final List<PasskeyCredential> passkeys;

  int anmeldungen = 0;
  final List<String> geloescht = [];

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<UserModel> signInWithPasskey() async {
    anmeldungen++;
    if (fehler != null) throw fehler!;
    return _user();
  }

  @override
  Future<List<PasskeyCredential>> listPasskeys() async => passkeys;

  @override
  Future<void> deletePasskey(String id) async => geloescht.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late ProviderContainer _container;

Future<void> _pump(
  WidgetTester tester,
  AuthRepository repo, {
  bool passkeysMoeglich = true,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      passkeySupportProvider.overrideWithValue(passkeysMoeglich),
    ],
  );
  addTearDown(_container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _goTo(WidgetTester tester, String route) async {
  _container.read(routerProvider).go(route);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('Ohne Unterstuetzung erscheint die Schaltflaeche gar nicht',
      (tester) async {
    // Ein Knopf, der beim Druecken scheitert, ist schlechter als keiner.
    await _pump(tester, _PasskeyRepository(), passkeysMoeglich: false);

    await _goTo(tester, '/login/azubi');

    expect(find.byType(PasskeyButton), findsNothing);
  });

  // Passkeys sind phishingresistent und gerade fuer Betriebe wertvoll – anders
  // als Anmeldelink und Anbieter-Anmeldung stehen sie beiden Rollen offen.
  // Getrennte Testfaelle, weil beim Wechsel zwischen zwei Anmeldeseiten
  // kurzzeitig beide im Baum liegen.
  testWidgets('Azubis bekommen die Passkey-Schaltflaeche', (tester) async {
    await _pump(tester, _PasskeyRepository());

    await _goTo(tester, '/login/azubi');

    expect(find.byType(PasskeyButton), findsOneWidget);
  });

  testWidgets('Betriebe bekommen sie ebenfalls', (tester) async {
    await _pump(tester, _PasskeyRepository());

    await _goTo(tester, '/login/betrieb');

    expect(find.byType(PasskeyButton), findsOneWidget);
  });

  testWidgets('Anbieter-Anmeldung bleibt Azubis vorbehalten', (tester) async {
    await _pump(tester, _PasskeyRepository());

    await _goTo(tester, '/login/betrieb');

    expect(find.text('E-Mail-Link'), findsNothing);
    expect(find.text('Google'), findsNothing);
  });

  testWidgets('Nicht freigeschaltete Anbieter sagen das beim Druecken',
      (tester) async {
    // Solange keine Client-Zugangsdaten hinterlegt sind, sind die
    // Schaltflaechen Platzhalter. Sie duerfen die App nicht verlassen – ein
    // Weiterleiten endete auf einer Appwrite-Fehlerseite ohne Rueckweg.
    await _pump(tester, _PasskeyRepository());
    await _goTo(tester, '/login/azubi');

    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    // Vor dem Druecken kostet der Hinweis keine Hoehe.
    expect(find.textContaining('noch nicht freigeschaltet'), findsNothing);

    await tester.tap(find.text('Google'));
    await tester.pump();

    expect(find.textContaining('noch nicht freigeschaltet'), findsOneWidget);
    expect(
      _container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      '/login/azubi',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Erfolgreiche Anmeldung fuehrt aufs Dashboard', (tester) async {
    await _pump(tester, _PasskeyRepository());
    await _goTo(tester, '/login/azubi');

    await tester.tap(find.byType(PasskeyButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(_container.read(authProvider).isAuthenticated, isTrue);
  });

  testWidgets('Abbruch meldet den Grund und laesst die Seite stehen',
      (tester) async {
    final repo = _PasskeyRepository(
      fehler:
          const AuthFailure('Die Anmeldung mit dem Passkey wurde abgebrochen.'),
    );
    await _pump(tester, repo);
    await _goTo(tester, '/login/azubi');

    await tester.tap(find.byType(PasskeyButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.anmeldungen, 1);
    expect(_container.read(authProvider).isAuthenticated, isFalse);
    expect(find.textContaining('abgebrochen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Die Verwaltung ist ohne Anmeldung nicht erreichbar',
      (tester) async {
    await _pump(tester, _PasskeyRepository(user: null));

    await _goTo(tester, '/settings/passkeys');

    expect(
      _container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      startsWith('/login'),
    );
  });

  testWidgets('Angemeldet zeigt die Verwaltung die eingerichteten Passkeys',
      (tester) async {
    await _pump(
      tester,
      _PasskeyRepository(
        user: _user(),
        passkeys: [
          PasskeyCredential(
            id: 'p1',
            deviceName: 'Laptop',
            createdAt: DateTime(2026, 8, 1),
            backedUp: true,
          ),
        ],
      ),
    );

    await _goTo(tester, '/settings/passkeys');
    // Die Liste wird nach dem ersten Aufbau nachgeladen.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Laptop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
