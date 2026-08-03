import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

/// Wirft bei der Anmeldung einen vorgegebenen Fehler.
class _FailingAuthRepository implements AuthRepository {
  _FailingAuthRepository(this.error);

  final Object error;

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<String?> _errorAfterSignIn(Object thrown) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FailingAuthRepository(thrown)),
    ],
  );
  addTearDown(container.dispose);

  await container
      .read(authProvider.notifier)
      .signIn(email: 'test@example.com', password: 'Geheim123');

  return container.read(authProvider).error;
}

void main() {
  test('AuthFailure-Meldung erreicht die Oberflaeche unveraendert', () async {
    const meldung = 'E-Mail-Adresse oder Passwort ist falsch.';

    expect(await _errorAfterSignIn(const AuthFailure(meldung)), meldung);
  });

  test('Sitzungskonflikt wird nicht als falsches Passwort gemeldet', () async {
    const meldung = 'Es besteht bereits eine aktive Sitzung. Bitte lade die Seite neu.';

    final error = await _errorAfterSignIn(const AuthFailure(meldung));

    expect(error, meldung);
    expect(error, isNot(contains('Zugangsdaten')));
  });

  test('Unbekannter Fehler faellt auf den allgemeinen Text zurueck', () async {
    expect(
      await _errorAfterSignIn(Exception('irgendetwas')),
      'Anmeldung fehlgeschlagen.',
    );
  });

  test('Fehlgeschlagene Anmeldung setzt den Nutzer zurueck', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(_FailingAuthRepository(const AuthFailure('nope'))),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authProvider.notifier)
        .signIn(email: 'test@example.com', password: 'Geheim123');

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isFalse);
    expect(state.isLoading, isFalse);
  });
}
