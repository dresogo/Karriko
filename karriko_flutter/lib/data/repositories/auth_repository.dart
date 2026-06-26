import 'package:appwrite/appwrite.dart';
import '../../core/constants/appwrite_constants.dart';
import '../models/user_model.dart';
import '../services/appwrite_service.dart';

class AuthRepository {
  Account get _account => AppwriteService.account;
  Databases get _db => Databases(AppwriteService.client);

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _account.createEmailPasswordSession(email: email, password: password);
    return _fetchCurrentUser();
  }

  Future<UserModel> registerAzubi({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? profession,
    String? city,
  }) async {
    final created = await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: '$firstName $lastName',
    );
    await _account.createEmailPasswordSession(email: email, password: password);
    await _account.updatePrefs(prefs: {
      'role': 'azubi',
      'first_name': firstName,
      'last_name': lastName,
      if (profession != null) 'profession': profession,
      if (city != null) 'city': city,
    });
    await _db.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.profilesCollection,
      documentId: created.$id,
      data: {
        'email': email,
        'role': 'azubi',
        'first_name': firstName,
        'last_name': lastName,
        if (profession != null) 'profession': profession,
        if (city != null) 'city': city,
      },
      permissions: [
        Permission.read(Role.user(created.$id)),
        Permission.update(Role.user(created.$id)),
        Permission.delete(Role.user(created.$id)),
      ],
    );
    await _account.createVerification(
      url: AppwriteConstants.verificationUrl,
    );
    return UserModel(
      id: created.$id,
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
    final created = await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: '$contactFirstName $contactLastName',
    );
    await _account.createEmailPasswordSession(email: email, password: password);
    await _account.updatePrefs(prefs: {
      'role': 'betrieb',
      'first_name': contactFirstName,
      'last_name': contactLastName,
      'company_name': companyName,
      if (industry != null) 'industry': industry,
      if (city != null) 'city': city,
    });
    await _db.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.profilesCollection,
      documentId: created.$id,
      data: {
        'email': email,
        'role': 'betrieb',
        'first_name': contactFirstName,
        'last_name': contactLastName,
        'company_name': companyName,
        if (industry != null) 'industry': industry,
        if (city != null) 'city': city,
      },
      permissions: [
        Permission.read(Role.user(created.$id)),
        Permission.update(Role.user(created.$id)),
        Permission.delete(Role.user(created.$id)),
      ],
    );
    await _account.createVerification(
      url: AppwriteConstants.verificationUrl,
    );
    return UserModel(
      id: created.$id,
      email: email,
      role: 'betrieb',
      firstName: contactFirstName,
      lastName: contactLastName,
      emailVerified: false,
      createdAt: DateTime.now(),
    );
  }

  Future<void> signOut() => _account.deleteSession(sessionId: 'current');

  Future<void> resetPassword(String email) async {
    await _account.createRecovery(
      email: email,
      url: AppwriteConstants.verificationUrl,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _account.updatePassword(password: newPassword);
  }

  Future<void> resendVerificationEmail() async {
    await _account.createVerification(url: AppwriteConstants.verificationUrl);
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      return await _fetchCurrentUser();
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    try {
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.profilesCollection,
        documentId: userId,
        data: updates,
      );
    } catch (_) {
      await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.profilesCollection,
        documentId: userId,
        data: updates,
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
    }
    final prefs = await _account.getPrefs();
    if (firstName != null || lastName != null) {
      await _account.updatePrefs(prefs: {
        ...prefs.data,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      });
    }
    return _fetchCurrentUser();
  }

  Future<void> deleteAccount(String userId) async {
    // Requires server-side function with API key in Appwrite.
    throw UnimplementedError('Account deletion requires a server-side Appwrite Function.');
  }

  Future<UserModel> _fetchCurrentUser() async {
    final user = await _account.get();
    try {
      final doc = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.profilesCollection,
        documentId: user.$id,
      );
      return UserModel(
        id: user.$id,
        email: user.email,
        role: doc.data['role'] as String? ?? 'azubi',
        firstName: doc.data['first_name'] as String?,
        lastName: doc.data['last_name'] as String?,
        avatarUrl: doc.data['avatar_url'] as String?,
        emailVerified: user.emailVerification,
        createdAt: DateTime.parse(user.$createdAt),
      );
    } catch (_) {
      final prefs = await _account.getPrefs();
      return UserModel(
        id: user.$id,
        email: user.email,
        role: prefs.data['role'] as String? ?? 'azubi',
        firstName: prefs.data['first_name'] as String?,
        lastName: prefs.data['last_name'] as String?,
        emailVerified: user.emailVerification,
        createdAt: DateTime.parse(user.$createdAt),
      );
    }
  }
}
