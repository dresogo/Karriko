import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  bool get isAzubi => user?.isAzubi ?? false;
  bool get isBetrieb => user?.isBetrieb ?? false;
  bool get emailVerified => user?.emailVerified ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
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
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.signIn(email: email, password: password);
      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _message(e, 'Anmeldung fehlgeschlagen.'),
        clearUser: true,
      );
    }
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
