/// Ein registrierter Passkey, wie ihn der Verwaltungsbildschirm zeigt.
///
/// Der öffentliche Schlüssel ist bewusst **nicht** enthalten: Er hilft der
/// Oberfläche nicht und verlässt den Dienst nie.
class PasskeyCredential {
  final String id;
  final String deviceName;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  /// Ob der Schlüssel beim Anbieter gesichert ist (Cloud-Passkey).
  ///
  /// Ein nicht gesicherter Schlüssel ist mit dem Gerät verloren — das ist der
  /// Unterschied, der beim Löschen des letzten Passkeys zählt.
  final bool backedUp;

  const PasskeyCredential({
    required this.id,
    required this.deviceName,
    required this.createdAt,
    this.lastUsedAt,
    required this.backedUp,
  });

  factory PasskeyCredential.fromJson(Map<String, dynamic> json) {
    final lastUsed = json['lastUsedAt'] as String?;
    return PasskeyCredential(
      id: json['id'] as String,
      deviceName: json['deviceName'] as String? ?? 'Unbenanntes Gerät',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: lastUsed == null ? null : DateTime.parse(lastUsed),
      backedUp: json['backedUp'] as bool? ?? false,
    );
  }
}
