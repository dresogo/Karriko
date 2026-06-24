class UserModel {
  final String id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final bool emailVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    required this.emailVerified,
    required this.createdAt,
  });

  String get fullName => [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
  String get displayName => fullName.isNotEmpty ? fullName : email.split('@').first;

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
      emailVerified: json['email_verified'] as bool? ?? false,
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
        'email_verified': emailVerified,
        'created_at': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    bool? emailVerified,
  }) {
    return UserModel(
      id: id,
      email: email,
      role: role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
    );
  }
}
