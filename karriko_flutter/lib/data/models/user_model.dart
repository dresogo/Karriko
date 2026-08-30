class UserModel {
  final String id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  /// Name des Unternehmens. Nur bei Betriebskonten gesetzt.
  final String? companyName;

  /// Verknuepfung zum `companies`-Dokument. Nur bei Betriebskonten gesetzt.
  ///
  /// Ohne sie hat das Betriebskonto keine Firma, gegen die es schreiben
  /// koennte – weder das Unternehmensprofil noch die Zuordnung von Bewertungen
  /// haetten eine Zieladresse. Bei Konten, die vor der Einfuehrung dieses
  /// Feldes entstanden sind, ist der Wert `null`; [AuthRepository.ensureCompany]
  /// zieht ihn dann nach.
  final String? companyId;

  final bool emailVerified;

  /// Ob fuer dieses Konto eine Zwei-Faktor-Bestaetigung aktiv ist.
  final bool mfaEnabled;

  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.companyName,
    this.companyId,
    required this.emailVerified,
    this.mfaEnabled = false,
    required this.createdAt,
  });

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
  String get displayName =>
      fullName.isNotEmpty ? fullName : email.split('@').first;

  bool get isAzubi => role.toLowerCase() == 'azubi';
  bool get isBetrieb => role.toLowerCase() == 'betrieb';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'azubi',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      companyName: json['company_name'] as String?,
      companyId: json['company_id'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
        'avatar_url': avatarUrl,
        'company_name': companyName,
        'company_id': companyId,
        'email_verified': emailVerified,
        'mfa_enabled': mfaEnabled,
        'created_at': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? companyName,
    String? companyId,
    bool? emailVerified,
    bool? mfaEnabled,
  }) {
    return UserModel(
      id: id,
      email: email,
      role: role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      companyName: companyName ?? this.companyName,
      companyId: companyId ?? this.companyId,
      emailVerified: emailVerified ?? this.emailVerified,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      createdAt: createdAt,
    );
  }
}
