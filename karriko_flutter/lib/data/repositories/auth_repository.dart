import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import '../../core/constants/appwrite_constants.dart';
import '../models/company_model.dart';
import '../models/passkey_credential.dart';
import '../models/user_model.dart';
import '../services/appwrite_service.dart';
import '../services/oauth_redirect.dart';
import '../services/passkey_api.dart';
import '../services/passkey_client.dart';
import 'auth_error_mapper.dart';
import 'company_repository.dart';

// AuthFailure liegt beim Mapper, wird hier aber weitergereicht: Aufrufer
// beziehen Repository und Fehlertyp seit jeher aus derselben Datei.
export 'auth_error_mapper.dart' show AuthFailure, MfaRequired;

/// Adresse, an die der Browser fuer die Anbieter-Anmeldung geht.
///
/// Bewusst als freie Funktion und nicht im Repository: So laesst sich der
/// Aufbau der Adresse pruefen, ohne einen Browser oder Appwrite zu brauchen.
/// Sie entspricht dem, was `Account.createOAuth2Token` intern zusammenbaut –
/// dessen Popup-Weg ist auf Web aber unbrauchbar (siehe `oauth_redirect.dart`).
Uri oauth2TokenUrl(String provider) {
  final endpoint = Uri.parse(AppwriteConstants.endpoint);
  return endpoint.replace(
    path: '${endpoint.path}/account/tokens/oauth2/$provider',
    queryParameters: {
      'project': AppwriteConstants.projectId,
      'success': AppwriteConstants.oauthSuccessUrl,
      'failure': AppwriteConstants.oauthFailureUrl,
    },
  );
}

class AuthRepository {
  /// Zugriff auf den eigenen WebAuthn-Dienst.
  ///
  /// Ueber den Konstruktor austauschbar, damit Tests ihn ersetzen koennen –
  /// die Appwrite-Aufrufe daneben sind das bis heute nicht.
  AuthRepository({PasskeyApi? passkeyApi, CompanyRepository? companyRepository})
      : _passkeys = passkeyApi ?? PasskeyApi(),
        _companies = companyRepository ?? CompanyRepository();

  final PasskeyApi _passkeys;

  /// Zugriff auf die Unternehmen.
  ///
  /// Die Betriebsregistrierung legt beides an – Konto und Firma –, deshalb
  /// braucht die Auth-Schicht hier eine Abhaengigkeit. Ueber den Konstruktor
  /// austauschbar, damit Tests sie ersetzen koennen.
  final CompanyRepository _companies;

  Account get _account => AppwriteService.account;
  TablesDB get _db => TablesDB(AppwriteService.client);

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

  AuthFailure _mapError(
    AppwriteException e,
    String fallback, {
    AuthContext context = AuthContext.general,
  }) =>
      mapAppwriteError(e, fallback, context: context);

  /// Meldet mit E-Mail und Passwort an.
  ///
  /// Wirft [MfaRequired], wenn fuer das Konto ein zweiter Faktor hinterlegt
  /// ist. Die Sitzung besteht dann bereits, ist aber unvollstaendig: jeder
  /// weitere Aufruf scheitert mit `user_more_factors_required`, bis die
  /// Abfrage bestanden ist.
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
      if (e.type == 'user_more_factors_required') {
        throw MfaRequired(await _availableMfaFactors());
      }
      throw _mapError(e, 'Anmeldung fehlgeschlagen.');
    }
  }

  /// Fragt ab, welche zweiten Faktoren fuer das Konto bereitstehen.
  ///
  /// Faellt auf `totp` zurueck: der Aufruf ist nur dazu da, dem Nutzer die
  /// passende Auswahl anzuzeigen. Scheitert er, ist eine Abfrage mit dem
  /// haeufigsten Verfahren besser als eine abgebrochene Anmeldung.
  Future<List<String>> _availableMfaFactors() async {
    try {
      final factors = await _account.listMFAFactors();
      final available = <String>[
        if (factors.totp) 'totp',
        if (factors.email) 'email',
        if (factors.phone) 'phone',
        if (factors.recoveryCode) 'recoverycode',
      ];
      return available.isEmpty ? const ['totp'] : available;
    } on AppwriteException {
      return const ['totp'];
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

    // Das Unternehmen entsteht vor dem Profil, weil dessen ID hineingehoert.
    // Scheitert es, bleibt companyId leer und die Registrierung laeuft trotzdem
    // durch – Konto und Sitzung bestehen an dieser Stelle bereits, ein Abbruch
    // hinterliesse ein Konto, das die App als Fehlschlag meldet. [ensureCompany]
    // zieht die Verknuepfung beim naechsten Zugriff nach.
    final companyId = await _createCompanyForOwner(
      ownerId: created.$id,
      companyName: companyName,
      industry: industry,
      city: city,
    );

    await _createProfileDocument(
      userId: created.$id,
      data: {
        'email': email,
        'role': 'betrieb',
        'first_name': contactFirstName,
        'last_name': contactLastName,
        'company_name': companyName,
        if (companyId != null) 'company_id': companyId,
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
      companyId: companyId,
      emailVerified: false,
      createdAt: DateTime.now(),
    );
  }

  /// Legt das Unternehmen an und haelt die ID auch in den Account-Prefs fest.
  ///
  /// Die Prefs sind der Rueckfallweg von [_fetchCurrentUser]: Ist das
  /// Profildokument nicht lesbar, kommt die Verknuepfung von dort. Ohne diesen
  /// zweiten Ort waere die Firma bei jedem Ausfall der Profil-Collection
  /// unerreichbar, obwohl sie existiert.
  ///
  /// Liefert `null`, wenn das Anlegen fehlschlaegt. Der Aufrufer darf daran
  /// nicht scheitern.
  Future<String?> _createCompanyForOwner({
    required String ownerId,
    required String companyName,
    String? industry,
    String? city,
  }) async {
    try {
      final company = await _companies.createCompany(
        ownerId: ownerId,
        name: companyName,
        industry: industry,
        city: city,
      );
      try {
        final prefs = await _account.getPrefs();
        await _account
            .updatePrefs(prefs: {...prefs.data, 'company_id': company.id});
      } on AppwriteException catch (e) {
        if (kDebugMode) {
          debugPrint('company_id konnte nicht in die Prefs (${e.type}).');
        }
      }
      return company.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Unternehmen konnte nicht angelegt werden: $e. '
          'Die Verknuepfung wird beim naechsten Zugriff nachgezogen.',
        );
      }
      return null;
    }
  }

  /// Stellt sicher, dass ein Betriebskonto ein Unternehmen hat, und liefert es.
  ///
  /// Deckt zwei Faelle ab, die sonst dauerhaft ohne Firma blieben:
  /// Konten aus der Zeit vor dieser Verknuepfung, und Registrierungen, bei
  /// denen das Anlegen fehlschlug.
  ///
  /// **Sucht erst, legt dann an.** Ohne die Suche ueber `owner_id` entstuende
  /// bei jedem Konto mit verlorener Verknuepfung ein zweites Unternehmen – mit
  /// eigener Adresse, eigenen Bewertungen und ohne Weg zurueck.
  ///
  /// Wird bewusst **nicht** bei jedem Laden aufgerufen, sondern erst, wenn ein
  /// Betrieb seine Daten tatsaechlich braucht: Sonst kostete jeder Seitenaufruf
  /// eine zusaetzliche Abfrage.
  Future<CompanyModel?> ensureCompany(UserModel user) async {
    if (!user.isBetrieb) return null;

    if (user.companyId != null) {
      try {
        return await _companies.getCompanyById(user.companyId!);
      } on AppwriteException {
        // Verknuepfung zeigt ins Leere – unten weitersuchen.
      }
    }

    final vorhanden = await _companies.findCompanyByOwner(user.id);
    final company = vorhanden ??
        await _companies.createCompany(
          ownerId: user.id,
          name: user.companyName?.trim().isNotEmpty == true
              ? user.companyName!
              : user.displayName,
        );

    await _linkCompany(userId: user.id, companyId: company.id);
    return company;
  }

  /// Schreibt die Verknuepfung an beide Orte, an denen sie gelesen wird.
  Future<void> _linkCompany({
    required String userId,
    required String companyId,
  }) async {
    try {
      await _db.updateRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: AppwriteConstants.profilesCollection,
        rowId: userId,
        data: {'company_id': companyId},
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        debugPrint('company_id konnte nicht ins Profil (${e.type}).');
      }
    }
    try {
      final prefs = await _account.getPrefs();
      await _account
          .updatePrefs(prefs: {...prefs.data, 'company_id': companyId});
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        debugPrint('company_id konnte nicht in die Prefs (${e.type}).');
      }
    }
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
      await _db.createRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: AppwriteConstants.profilesCollection,
        rowId: userId,
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
      await _account.createEmailVerification(
          url: AppwriteConstants.verificationUrl);
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

  /// Stoesst den Passwort-Reset an.
  ///
  /// Kehrt auch dann normal zurueck, wenn zu der Adresse kein Konto existiert.
  /// Andernfalls koennte man an der Fehlermeldung ablesen, welche Adressen
  /// registriert sind – notes/projekt-referenz.md Paragraf 3.2 verlangt in
  /// beiden Faellen dieselbe Antwort.
  Future<void> resetPassword(String email) async {
    try {
      await _account.createRecovery(
        email: email,
        url: AppwriteConstants.recoveryUrl,
      );
    } on AppwriteException catch (e) {
      if (e.type == 'user_not_found') {
        if (kDebugMode) {
          debugPrint('Passwort-Reset fuer unbekannte Adresse angefordert.');
        }
        return;
      }
      throw _mapError(e, 'Passwort-Reset fehlgeschlagen.');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await _account.updatePassword(password: newPassword);
  }

  Future<void> resendVerificationEmail() async {
    await _account.createEmailVerification(
        url: AppwriteConstants.verificationUrl);
  }

  /// Liefert den angemeldeten Nutzer oder `null`, wenn keine Sitzung besteht.
  ///
  /// [MfaRequired] wird bewusst **nicht** verschluckt. Sonst saehe eine
  /// halbfertige Sitzung nach dem Neuladen der Seite wie "abgemeldet" aus –
  /// serverseitig bestuende sie aber weiter, und der naechste Anmeldeversuch
  /// liefe in `user_session_already_exists`.
  Future<UserModel?> getCurrentUser() async {
    try {
      return await _fetchCurrentUser();
    } on MfaRequired {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  // --- Anmeldung ueber Einmal-Geheimnis ------------------------------------

  /// Fordert einen Anmeldelink an.
  ///
  /// Kehrt immer normal zurueck, wenn zur Adresse kein Konto existiert – die
  /// Oberflaeche zeigt in jedem Fall denselben Text. Ein Enumerationsorakel
  /// entsteht hier ohnehin nicht: `createMagicURLToken` legt bei unbekannter
  /// Adresse ein Konto an, statt zu scheitern.
  ///
  /// Fehler beim Versand werden **nicht** geschluckt (anders als bei der
  /// Bestaetigungsmail): Wer auf einen Knopf drueckt und keinen Link bekommt,
  /// muss erfahren, dass etwas schiefging.
  Future<void> requestMagicLink(String email) async {
    try {
      await _account.createMagicURLToken(
        userId: ID.unique(),
        email: email,
        url: AppwriteConstants.magicLinkUrl,
      );
    } on AppwriteException catch (e) {
      if (e.type == 'user_not_found') {
        if (kDebugMode) {
          debugPrint('Anmeldelink fuer unbekannte Adresse angefordert.');
        }
        return;
      }
      throw _mapError(
        e,
        'Der Anmeldelink konnte nicht verschickt werden.',
        context: AuthContext.link,
      );
    }
  }

  /// Loest den Anmeldelink ein.
  Future<UserModel> completeMagicLink({
    required String userId,
    required String secret,
  }) =>
      _signInWithToken(userId: userId, secret: secret);

  /// Schickt den Browser zur Anmeldeseite des Anbieters.
  ///
  /// Kehrt im Erfolgsfall **nicht** zurueck – die Seite wird verlassen.
  /// Appwrite leitet nach dem Anbieter auf [AppwriteConstants.oauthSuccessUrl]
  /// zurueck, mit `userId` und `secret` in der Query.
  void signInWithOAuth(String provider) {
    try {
      redirectToProvider(oauth2TokenUrl(provider));
    } on UnsupportedError catch (e) {
      throw AuthFailure(e.message ?? 'Nicht verfügbar.');
    }
  }

  /// Loest die Rueckleitung des Anbieters ein.
  Future<UserModel> completeOAuth({
    required String userId,
    required String secret,
  }) =>
      _signInWithToken(userId: userId, secret: secret);

  /// Tauscht ein Einmal-Geheimnis gegen eine Sitzung.
  ///
  /// Derselbe Weg fuer Anmeldelink, OAuth-Rueckleitung und spaeter den
  /// Passkey-Dienst: Alle drei liefern ein Paar aus `userId` und `secret`, das
  /// `createSession` in eine Sitzung uebersetzt. `updateMagicURLSession` waere
  /// der aeltere, verfahrensgebundene Weg – seit Appwrite 1.6 ueberholt.
  Future<UserModel> _signInWithToken({
    required String userId,
    required String secret,
  }) async {
    await _createSessionFromToken(userId: userId, secret: secret);
    return _finishTokenSignIn();
  }

  /// Tauscht das Geheimnis gegen eine Sitzung, ohne weitere Regeln.
  ///
  /// Getrennt von [_signInWithToken], weil die Betriebssperre dort **nicht**
  /// fuer alle Verfahren gilt: Passkeys werden beiden Rollen angeboten. Ein
  /// Betrieb, der einen Passkey eingerichtet hat, muss sich damit auch anmelden
  /// koennen – die Sperre soll nur verhindern, dass jemand die Firmenpruefung
  /// ueber einen Anmeldelink oder ein Google-Konto umgeht.
  Future<UserModel> _createSessionFromToken({
    required String userId,
    required String secret,
  }) async {
    try {
      await _clearExistingSession();
      await _account.createSession(userId: userId, secret: secret);
    } on AppwriteException catch (e) {
      throw _mapError(
        e,
        'Die Anmeldung ist fehlgeschlagen.',
        context: AuthContext.link,
      );
    }
    return _fetchCurrentUser();
  }

  /// Gemeinsamer Abschluss aller Anmeldungen ueber ein Einmal-Geheimnis
  /// (Anmeldelink, OAuth, spaeter Passkey).
  ///
  /// Zwei Dinge passieren hier, die der Passwort-Weg nicht braucht:
  ///
  /// 1. **Betriebssperre.** Appwrite verknuepft Identitaeten ueber die E-Mail.
  ///    Ohne diese Pruefung kaeme ein Betrieb mit passendem Google- oder
  ///    Mail-Konto ohne Passwort und ohne Firmenpruefung hinein.
  /// 2. **Rollen-Nachzug.** Nach einer Anmeldung ohne Registrierung gibt es
  ///    weder Profildokument noch Rolle in den Prefs. [_fetchCurrentUser]
  ///    faellt still auf `azubi` zurueck – fuer neue Nutzer das gewuenschte
  ///    Ergebnis, aber aus dem falschen Grund. Deshalb wird es festgeschrieben.
  Future<UserModel> _finishTokenSignIn() async {
    final user = await _fetchCurrentUser();
    if (user.isBetrieb) {
      await signOut();
      throw const AuthFailure(
        'Betriebskonten melden sich mit E-Mail und Passwort an.',
      );
    }
    await _ensureAzubiProfile(user);
    return user;
  }

  /// Legt Profildokument und Rolle an, falls sie fehlen.
  Future<void> _ensureAzubiProfile(UserModel user) async {
    try {
      await _db.getRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: AppwriteConstants.profilesCollection,
        rowId: user.id,
      );
      return;
    } on AppwriteException {
      // Kein Profil vorhanden – wird gleich angelegt.
    }

    await _createProfileDocument(
      userId: user.id,
      data: {'email': user.email, 'role': 'azubi'},
    );
    try {
      final prefs = await _account.getPrefs();
      await _account.updatePrefs(prefs: {...prefs.data, 'role': 'azubi'});
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        debugPrint('Rolle konnte nicht in den Prefs gesetzt werden: ${e.type}');
      }
    }
  }

  // --- Passkeys (WebAuthn) -------------------------------------------------

  /// Meldet mit einem Passkey an.
  ///
  /// Der Ablauf: Optionen vom eigenen Dienst holen, den Browser den Schluessel
  /// abfragen lassen, die Antwort pruefen lassen, und das zurueckgelieferte
  /// `{userId, secret}` gegen eine Appwrite-Sitzung tauschen.
  ///
  /// Ohne Betriebssperre: Passkeys stehen beiden Rollen offen.
  Future<UserModel> signInWithPasskey() async {
    final optionen = await _passkeys.anmeldeOptionen();
    final challenge = optionen['challenge'] as String;

    final String antwortJson;
    try {
      antwortJson = await passkeyAbfragen(jsonEncode(optionen));
    } catch (e) {
      // Bricht der Nutzer die Abfrage des Betriebssystems ab, landet das hier.
      // Das ist kein Fehler, den man ihm vorwerfen muesste.
      throw const AuthFailure(
          'Die Anmeldung mit dem Passkey wurde abgebrochen.');
    }

    final token = await _passkeys.anmeldungBestaetigen(
      challenge: challenge,
      antwort: jsonDecode(antwortJson) as Map<String, dynamic>,
    );
    return _createSessionFromToken(
      userId: token.userId,
      secret: token.secret,
    );
  }

  /// Richtet einen Passkey fuer das angemeldete Konto ein.
  Future<void> registerPasskey(String geraetename) async {
    final jwt = await _jwt();
    final optionen = await _passkeys.registrierungsOptionen(jwt);
    final challenge = optionen['challenge'] as String;

    final String antwortJson;
    try {
      antwortJson = await passkeyAnlegen(jsonEncode(optionen));
    } catch (e) {
      throw const AuthFailure('Die Einrichtung wurde abgebrochen.');
    }

    await _passkeys.registrierungBestaetigen(
      jwt: jwt,
      challenge: challenge,
      antwort: jsonDecode(antwortJson) as Map<String, dynamic>,
      geraetename: geraetename,
    );
  }

  Future<List<PasskeyCredential>> listPasskeys() async =>
      _passkeys.auflisten(await _jwt());

  Future<void> deletePasskey(String id) async =>
      _passkeys.loeschen(jwt: await _jwt(), id: id);

  /// Kurzlebiges Token, mit dem sich der eigene Dienst bei Appwrite
  /// vergewissert, wer da anfragt.
  Future<String> _jwt() async {
    try {
      return (await _account.createJWT()).jwt;
    } on AppwriteException catch (e) {
      throw _mapError(e, 'Die Sitzung konnte nicht bestätigt werden.');
    }
  }

  // --- Zwei-Faktor-Bestaetigung -------------------------------------------

  /// Startet die Abfrage des zweiten Faktors und liefert die Challenge-ID.
  Future<String> startMfaChallenge(String factor) async {
    try {
      final challenge = await _account.createMFAChallenge(
        factor: _authenticationFactor(factor),
      );
      return challenge.$id;
    } on AppwriteException catch (e) {
      throw _mapError(
        e,
        'Die Bestätigung konnte nicht gestartet werden.',
        context: AuthContext.mfa,
      );
    }
  }

  /// Loest die Abfrage mit dem eingegebenen Code ein.
  Future<UserModel> completeMfaChallenge({
    required String challengeId,
    required String otp,
  }) async {
    try {
      await _account.updateMFAChallenge(challengeId: challengeId, otp: otp);
      return await _fetchCurrentUser();
    } on AppwriteException catch (e) {
      throw _mapError(
        e,
        'Die Bestätigung ist fehlgeschlagen.',
        context: AuthContext.mfa,
      );
    }
  }

  AuthenticationFactor _authenticationFactor(String factor) => switch (factor) {
        'email' => AuthenticationFactor.email,
        'phone' => AuthenticationFactor.phone,
        'recoverycode' => AuthenticationFactor.recoverycode,
        _ => AuthenticationFactor.totp,
      };

  /// Legt einen TOTP-Authenticator an und liefert Geheimnis und `otpauth`-URI.
  ///
  /// Der Authenticator gilt erst nach [confirmTotpEnrollment] als bestaetigt.
  Future<({String secret, String uri})> startTotpEnrollment() async {
    try {
      final authenticator = await _account.createMFAAuthenticator(
        type: AuthenticatorType.totp,
      );
      return (secret: authenticator.secret, uri: authenticator.uri);
    } on AppwriteException catch (e) {
      throw _mapError(e, 'Die Einrichtung konnte nicht gestartet werden.');
    }
  }

  /// Bestaetigt den TOTP-Authenticator mit einem Code aus der App.
  Future<void> confirmTotpEnrollment(String otp) async {
    try {
      await _account.updateMFAAuthenticator(
        type: AuthenticatorType.totp,
        otp: otp,
      );
    } on AppwriteException catch (e) {
      throw _mapError(
        e,
        'Der Code konnte nicht bestätigt werden.',
        context: AuthContext.mfa,
      );
    }
  }

  /// Erzeugt die Wiederherstellungscodes.
  ///
  /// Appwrite zeigt sie **nur bei diesem Aufruf** im Klartext. Danach sind sie
  /// nicht mehr auslesbar, nur noch ersetzbar.
  Future<List<String>> createMfaRecoveryCodes() async {
    try {
      final codes = await _account.createMFARecoveryCodes();
      return codes.recoveryCodes;
    } on AppwriteException catch (e) {
      throw _mapError(
        e,
        'Die Wiederherstellungscodes konnten nicht erzeugt werden.',
      );
    }
  }

  /// Schaltet die Zwei-Faktor-Pflicht fuer das Konto ein oder aus.
  Future<void> setMfaEnabled(bool enabled) async {
    try {
      await _account.updateMFA(mfa: enabled);
    } on AppwriteException catch (e) {
      throw _mapError(e, 'Die Einstellung konnte nicht gespeichert werden.');
    }
  }

  /// Entfernt den TOTP-Authenticator.
  Future<void> deleteTotpAuthenticator() async {
    try {
      await _account.deleteMFAAuthenticator(type: AuthenticatorType.totp);
    } on AppwriteException catch (e) {
      throw _mapError(e, 'Das Verfahren konnte nicht entfernt werden.');
    }
  }

  /// Meldet, ob bereits ein bestaetigter TOTP-Authenticator existiert.
  Future<bool> hasTotpAuthenticator() async {
    try {
      return (await _account.listMFAFactors()).totp;
    } on AppwriteException {
      return false;
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
      await _db.updateRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: AppwriteConstants.profilesCollection,
        rowId: userId,
        data: updates,
      );
    } catch (_) {
      await _db.createRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: AppwriteConstants.profilesCollection,
        rowId: userId,
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
    final models.User user;
    try {
      user = await _account.get();
    } on AppwriteException catch (e) {
      // Die Sitzung besteht, ist aber erst zur Haelfte aufgebaut. Das ist kein
      // Fehler, sondern der Punkt, an dem die Abfrage des zweiten Faktors
      // beginnt – deshalb eine eigene Ausnahme statt eines AuthFailure.
      if (e.type == 'user_more_factors_required') {
        throw MfaRequired(await _availableMfaFactors());
      }
      rethrow;
    }
    try {
      final doc = await _db.getRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: AppwriteConstants.profilesCollection,
        rowId: user.$id,
      );
      return UserModel(
        id: user.$id,
        email: user.email,
        role: doc.data['role'] as String? ?? 'azubi',
        firstName: doc.data['first_name'] as String?,
        lastName: doc.data['last_name'] as String?,
        avatarUrl: doc.data['avatar_url'] as String?,
        companyName: doc.data['company_name'] as String?,
        companyId: doc.data['company_id'] as String?,
        emailVerified: user.emailVerification,
        mfaEnabled: user.mfa,
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
        companyId: prefs.data['company_id'] as String?,
        emailVerified: user.emailVerification,
        mfaEnabled: user.mfa,
        createdAt: DateTime.parse(user.$createdAt),
      );
    }
  }
}
