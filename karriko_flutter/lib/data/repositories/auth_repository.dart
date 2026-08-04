import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import '../../core/constants/appwrite_constants.dart';
import '../models/user_model.dart';
import '../services/appwrite_service.dart';

/// Fehler der Anmeldung oder Registrierung mit einer Meldung, die direkt
/// angezeigt werden kann.
class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  Account get _account => AppwriteService.account;
  Databases get _db => Databases(AppwriteService.client);

  /// Beendet eine noch offene Sitzung.
  ///
  /// Appwrite lehnt das Anlegen einer Sitzung ab, solange bereits eine aktive
  /// besteht (`user_session_already_exists`). Bleibt nach einer abgebrochenen
  /// Registrierung eine Sitzung im Browser zurück, schlägt sonst jeder weitere
  /// Anmeldeversuch fehl – mit einer Meldung, die fälschlich das Passwort
  /// beschuldigt.
  Future<void> _clearExistingSession() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException {
      // Keine Sitzung vorhanden – nichts aufzuräumen.
    }
  }

  /// Übersetzt Appwrite-Fehler in Meldungen, die dem Nutzer weiterhelfen.
  AuthFailure _mapError(AppwriteException e, String fallback) {
    return switch (e.type) {
      'user_invalid_credentials' =>
        const AuthFailure('E-Mail-Adresse oder Passwort ist falsch.'),
      'user_already_exists' || 'user_email_already_exists' => const AuthFailure(
          'Für diese E-Mail-Adresse existiert bereits ein Konto.'),
      'user_blocked' => const AuthFailure('Dieses Konto ist gesperrt.'),
      'user_session_already_exists' => const AuthFailure(
          'Es besteht bereits eine aktive Sitzung. Bitte lade die Seite neu.'),
      'general_rate_limit_exceeded' => const AuthFailure(
          'Zu viele Versuche. Bitte warte einen Moment und versuche es erneut.'),
      'password_personal_data' => const AuthFailure(
          'Das Passwort darf keine persönlichen Daten enthalten.'),
      _ => AuthFailure(e.message ?? fallback),
    };
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _clearExistingSession();
      await _account.createEmailPasswordSession(
          email: email, password: password);
      return await _fetchCurrentUser();
    } on AppwriteException catch (e) {
      throw _mapError(e, 'Anmeldung fehlgeschlagen.');
    }
  }

  Future<UserModel> registerAzubi({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? profession,
    String? city,
  }) async {
    final models.User created;
    try {
      await _clearExistingSession();
      created = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: '$firstName $lastName',
      );
      await _account.createEmailPasswordSession(
          email: email, password: password);
      await _account.updatePrefs(prefs: {
        'role': 'azubi',
        'first_name': firstName,
        'last_name': lastName,
        if (profession != null) 'profession': profession,
        if (city != null) 'city': city,
      });
    } on AppwriteException catch (e) {
      throw _mapError(e, 'Registrierung fehlgeschlagen.');
    }

    await _createProfileDocument(
      userId: created.$id,
      data: {
        'email': email,
        'role': 'azubi',
        'first_name': firstName,
        'last_name': lastName,
        if (profession != null) 'profession': profession,
        if (city != null) 'city': city,
      },
    );
    await _sendVerificationEmail();

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
    final models.User created;
    try {
      await _clearExistingSession();
      created = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: '$contactFirstName $contactLastName',
      );
      await _account.createEmailPasswordSession(
          email: email, password: password);
      await _account.updatePrefs(prefs: {
        'role': 'betrieb',
        'first_name': contactFirstName,
        'last_name': contactLastName,
        'company_name': companyName,
        if (industry != null) 'industry': industry,
        if (city != null) 'city': city,
      });
    } on AppwriteException catch (e) {
      throw _mapError(e, 'Registrierung fehlgeschlagen.');
    }

    await _createProfileDocument(
      userId: created.$id,
      data: {
        'email': email,
        'role': 'betrieb',
        'first_name': contactFirstName,
        'last_name': contactLastName,
        'company_name': companyName,
        if (industry != null) 'industry': industry,
        if (city != null) 'city': city,
      },
    );
    await _sendVerificationEmail();

    return UserModel(
      id: created.$id,
      email: email,
      role: 'betrieb',
      firstName: contactFirstName,
      lastName: contactLastName,
      companyName: companyName,
      emailVerified: false,
      createdAt: DateTime.now(),
    );
  }

  /// Legt das Profildokument an, aus dem die App die Rolle liest.
  ///
  /// Schlägt das fehl (Collection fehlt, Attribut unbekannt, Berechtigung),
  /// darf die Registrierung nicht scheitern: Konto und Sitzung bestehen zu
  /// diesem Zeitpunkt bereits, und die Rolle liegt zusätzlich in den
  /// Account-Prefs, auf die [_fetchCurrentUser] zurückfällt. Andernfalls
  /// bliebe ein angelegtes Konto zurück, das die App als Fehlschlag meldet.
  Future<void> _createProfileDocument({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.profilesCollection,
        documentId: userId,
        data: data,
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Profildokument konnte nicht angelegt werden (${e.type}): ${e.message}. '
          'Die Rolle wird aus den Account-Prefs gelesen.',
        );
      }
    }
  }

  /// Verschickt die Bestätigungsmail.
  ///
  /// Appwrite prüft die Ziel-URL gegen die im Projekt hinterlegten Plattformen.
  /// Ist `verificationUrl` nicht eingetragen, schlägt der Aufruf fehl – das darf
  /// eine ansonsten erfolgreiche Registrierung nicht mitreißen.
  Future<void> _sendVerificationEmail() async {
    try {
      await _account.createVerification(url: AppwriteConstants.verificationUrl);
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Bestätigungsmail konnte nicht verschickt werden (${e.type}): ${e.message}. '
          'Prüfe AppwriteConstants.verificationUrl und die Plattformen des Projekts.',
        );
      }
    }
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
    throw UnimplementedError(
        'Account deletion requires a server-side Appwrite Function.');
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
        companyName: doc.data['company_name'] as String?,
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
        companyName: prefs.data['company_name'] as String?,
        emailVerified: user.emailVerification,
        createdAt: DateTime.parse(user.$createdAt),
      );
    }
  }
}
