import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/passkey_client.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

/// Kann dieser Browser Passkeys?
///
/// Bewusst kein Teil des Repositories: Das ist eine Eigenschaft der Plattform,
/// keine Frage an die Datenschicht. Als eigener Provider laesst er sich in
/// Tests umschalten, ohne dass jedes Fake-Repository ihn kennen muss.
final passkeySupportProvider = Provider<bool>((ref) => passkeysVerfuegbar());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  /// Hinterlegte zweite Faktoren, solange die Abfrage offen ist.
  ///
  /// Leer, sobald die Anmeldung vollstaendig ist.
  ///
  /// Die laufende Challenge-ID und der Ladezustand der Eingabe liegen bewusst
  /// **nicht** hier, sondern im Bildschirm: an diesem Zustand haengt der
  /// `refreshListenable` des Routers. Eine Aenderung waehrend go_router eine
  /// Route installiert, verwirft die laufende Navigation – der Nutzer landete
  /// dann wieder auf der Startseite statt auf der Abfrage.
  final List<String> mfaFactors;

  /// Adresse aus dem angefangenen Anmeldeversuch, nur zur Anzeige.
  final String? pendingEmail;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.mfaFactors = const [],
    this.pendingEmail,
  });

  /// Die Anmeldung wartet auf den zweiten Faktor.
  ///
  /// [user] bleibt in diesem Zustand bewusst `null`: serverseitig besteht zwar
  /// eine Sitzung, aber sie traegt noch keine Berechtigungen. Damit bleiben
  /// [isAuthenticated] und die Rollen-Getter fuer alle bestehenden Aufrufer
  /// richtig – wer halb angemeldet ist, ist nicht angemeldet.
  bool get mfaRequired => mfaFactors.isNotEmpty;

  bool get isAuthenticated => user != null;
  bool get isAzubi => user?.isAzubi ?? false;
  bool get isBetrieb => user?.isBetrieb ?? false;
  bool get emailVerified => user?.emailVerified ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    List<String>? mfaFactors,
    String? pendingEmail,
    bool clearUser = false,
    bool clearError = false,
    bool clearMfa = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      // Ohne clearMfa liesse sich die offene Abfrage nie zuruecksetzen, und der
      // Nutzer bliebe nach bestandener Bestaetigung in mfaRequired haengen.
      mfaFactors: clearMfa ? const [] : (mfaFactors ?? this.mfaFactors),
      pendingEmail: clearMfa ? null : (pendingEmail ?? this.pendingEmail),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState(isLoading: true)) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final user = await _repo.getCurrentUser();
      state = AuthState(user: user);
    } on MfaRequired catch (e) {
      // Neu geladene Seite mit halbfertiger Sitzung. Ohne diesen Zweig saehe
      // die App den Nutzer als abgemeldet, waehrend die Sitzung serverseitig
      // weiterbesteht – der naechste Anmeldeversuch liefe dann ins Leere.
      state = AuthState(mfaFactors: e.factors);
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.signIn(email: email, password: password);
      state = AuthState(user: user);
    } on MfaRequired catch (e) {
      // Muss vor dem allgemeinen catch stehen: sonst landet ein planmaessiger
      // Zwischenschritt als rote Fehlermeldung auf der Anmeldeseite.
      state = AuthState(mfaFactors: e.factors, pendingEmail: email);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _message(e, 'Anmeldung fehlgeschlagen.'),
        clearUser: true,
      );
    }
  }

  /// Loest einen Anmeldelink ein.
  ///
  /// Setzt wie [submitMfaChallenge] weder `isLoading` noch `error`: Der
  /// Callback-Bildschirm laeuft, waehrend go_router seine Route gerade
  /// installiert. Jede Aenderung an diesem Zustand feuert den
  /// `refreshListenable` und verwirft die laufende Navigation.
  ///
  /// Fehler werden weitergereicht, nicht geschluckt.
  Future<void> completeMagicLink({
    required String userId,
    required String secret,
  }) async {
    final user = await _repo.completeMagicLink(userId: userId, secret: secret);
    state = AuthState(user: user);
  }

  /// Meldet mit einem Passkey an.
  ///
  /// Wie [completeMagicLink] ohne `isLoading` und `error`: Der Knopf zeigt
  /// beides selbst, damit der Router nicht bei jedem Tastendruck neu rechnet.
  /// Fehler werden weitergereicht.
  Future<void> signInWithPasskey() async {
    final user = await _repo.signInWithPasskey();
    state = AuthState(user: user);
  }

  /// Loest die Rueckleitung eines Anbieters ein.
  ///
  /// Gleiche Zurueckhaltung wie [completeMagicLink]: kein `isLoading`, kein
  /// `error`, damit der Callback-Bildschirm den Router nicht anstoesst.
  Future<void> completeOAuth({
    required String userId,
    required String secret,
  }) async {
    final user = await _repo.completeOAuth(userId: userId, secret: secret);
    state = AuthState(user: user);
  }

  /// Loest die Abfrage des zweiten Faktors ein.
  ///
  /// Setzt bewusst **weder** `isLoading` noch `error`: an diesem Zustand haengt
  /// der Router, und jede Aenderung stoesst eine Neuberechnung der Weiterleitung
  /// an. Der Bildschirm zeigt Ladebalken und Fehler daher selbst; hier aendert
  /// sich der Zustand nur, wenn die Anmeldung tatsaechlich durch ist.
  ///
  /// Fehler werden weitergereicht, nicht geschluckt.
  Future<void> submitMfaChallenge({
    required String challengeId,
    required String otp,
  }) async {
    final user = await _repo.completeMfaChallenge(
      challengeId: challengeId,
      otp: otp,
    );
    state = AuthState(user: user);
  }

  /// Bricht die offene Abfrage ab.
  ///
  /// Meldet zwingend auch serverseitig ab: die halbfertige Sitzung existiert
  /// bei Appwrite weiter und wuerde sonst den naechsten Anmeldeversuch stoeren.
  Future<void> cancelMfaChallenge() async {
    try {
      await _repo.signOut();
    } catch (_) {
      // Sitzung schon weg – nichts aufzuraeumen.
    }
    state = const AuthState();
  }

  /// Gibt die Meldung aus [AuthFailure] durch. Nur wenn keine vorliegt, greift
  /// der allgemeine Text – eine pauschale Meldung über falsche Zugangsdaten
  /// führt sonst in die Irre, wenn die eigentliche Ursache eine andere ist.
  String _message(Object error, String fallback) =>
      error is AuthFailure ? error.message : fallback;

  Future<void> registerAzubi({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? profession,
    String? city,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.registerAzubi(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        profession: profession,
        city: city,
      );
      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: _message(e, 'Registrierung fehlgeschlagen.'));
    }
  }

  Future<void> registerBetrieb({
    required String email,
    required String password,
    required String companyName,
    required String contactFirstName,
    required String contactLastName,
    String? industry,
    String? city,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.registerBetrieb(
        email: email,
        password: password,
        companyName: companyName,
        contactFirstName: contactFirstName,
        contactLastName: contactLastName,
        industry: industry,
        city: city,
      );
      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: _message(e, 'Registrierung fehlgeschlagen.'));
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Passwort-Reset fehlgeschlagen.');
    }
  }

  Future<void> updateProfile({String? firstName, String? lastName}) async {
    final userId = state.user?.id;
    if (userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _repo.updateProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
      );
      state = AuthState(user: updated);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Profil-Update fehlgeschlagen.');
    }
  }

  Future<void> refresh() => _initAuth();

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
