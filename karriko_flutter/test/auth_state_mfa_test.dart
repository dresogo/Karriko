import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';

UserModel _user() => UserModel(
      id: 'u1',
      email: 'azubi@example.com',
      role: 'azubi',
      emailVerified: true,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('offene Bestaetigung gilt nicht als Anmeldung', () {
    const state = AuthState(mfaFactors: ['totp']);

    expect(state.mfaRequired, isTrue);
    // Alle Getter, an denen der Router haengt, muessen die halbe Sitzung als
    // "nicht angemeldet" sehen – sonst liesse sie geschuetzte Seiten passieren.
    expect(state.isAuthenticated, isFalse);
    expect(state.isAzubi, isFalse);
    expect(state.isBetrieb, isFalse);
    expect(state.emailVerified, isFalse);
  });

  test('clearMfa raeumt Faktoren und vorgemerkte Adresse', () {
    const offen = AuthState(mfaFactors: ['totp'], pendingEmail: 'a@b.de');

    final geraeumt = offen.copyWith(clearMfa: true);

    // Ohne das Flag liesse sich die Abfrage nie zuruecksetzen: copyWith
    // uebernimmt bei null immer den alten Wert, der Nutzer bliebe also
    // dauerhaft in mfaRequired haengen.
    expect(geraeumt.mfaRequired, isFalse);
    expect(geraeumt.mfaFactors, isEmpty);
    expect(geraeumt.pendingEmail, isNull);
  });

  test('bestandene Bestaetigung hinterlaesst keine offene Abfrage', () {
    final fertig = AuthState(user: _user());

    expect(fertig.mfaRequired, isFalse);
    expect(fertig.isAuthenticated, isTrue);
  });

  test('copyWith ohne clearMfa laesst die Abfrage stehen', () {
    const offen = AuthState(mfaFactors: ['totp']);

    final mitFehler = offen.copyWith(error: 'Der Code ist ungültig.');

    expect(mitFehler.mfaRequired, isTrue);
    expect(mitFehler.mfaFactors, ['totp']);
  });
}
