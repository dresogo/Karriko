import '../models/user_model.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final _client = SupabaseService.client;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await SupabaseService.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Anmeldung fehlgeschlagen');
    return _fetchUserProfile(response.user!.id);
  }

  Future<UserModel> registerAzubi({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? profession,
    String? city,
  }) async {
    final response = await SupabaseService.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'role': 'azubi',
        'profession': profession,
        'city': city,
      },
    );
    if (response.user == null) throw Exception('Registrierung fehlgeschlagen');
    return UserModel(
      id: response.user!.id,
      email: email,
      role: 'azubi',
      firstName: firstName,
      lastName: lastName,
      emailVerified: false,
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel> registerBetrieb({
    required String email,
    required String password,
    required String companyName,
    required String contactFirstName,
    required String contactLastName,
    String? industry,
    String? city,
  }) async {
    final response = await SupabaseService.signUp(
      email: email,
      password: password,
      data: {
        'first_name': contactFirstName,
        'last_name': contactLastName,
        'role': 'betrieb',
        'company_name': companyName,
        'industry': industry,
        'city': city,
      },
    );
    if (response.user == null) throw Exception('Registrierung fehlgeschlagen');
    return UserModel(
      id: response.user!.id,
      email: email,
      role: 'betrieb',
      firstName: contactFirstName,
      lastName: contactLastName,
      emailVerified: false,
      createdAt: DateTime.now(),
    );
  }

  Future<void> signOut() => SupabaseService.signOut();

  Future<void> resetPassword(String email) => SupabaseService.resetPassword(email);

  Future<void> updatePassword(String newPassword) => SupabaseService.updatePassword(newPassword);

  Future<void> resendVerificationEmail(String email) =>
      SupabaseService.resendVerificationEmail(email);

  Future<UserModel?> getCurrentUser() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    try {
      return await _fetchUserProfile(user.id);
    } catch (_) {
      final meta = user.userMetadata ?? {};
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        role: meta['role'] as String? ?? 'azubi',
        firstName: meta['first_name'] as String?,
        lastName: meta['last_name'] as String?,
        emailVerified: user.emailConfirmedAt != null,
        createdAt: DateTime.parse(user.createdAt),
      );
    }
  }

  Future<UserModel> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    return _fetchUserProfile(userId);
  }

  Future<void> deleteAccount(String userId) async {
    await _client.rpc('delete_user_account', params: {'user_id': userId});
  }

  Future<UserModel> _fetchUserProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromJson(data);
  }
}
