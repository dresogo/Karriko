class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'E-Mail-Adresse ist erforderlich';
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Ungültige E-Mail-Adresse';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Passwort ist erforderlich';
    if (value.length < 8) return 'Passwort muss mindestens 8 Zeichen lang sein';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Passwort muss mindestens einen Großbuchstaben enthalten';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Passwort muss mindestens eine Ziffer enthalten';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Passwort-Bestätigung ist erforderlich';
    if (value != original) return 'Passwörter stimmen nicht überein';
    return null;
  }

  static String? required(String? value, {String label = 'Dieses Feld'}) {
    if (value == null || value.trim().isEmpty) return '$label ist erforderlich';
    return null;
  }

  static String? minLength(String? value, int min, {String label = 'Dieses Feld'}) {
    if (value == null || value.trim().length < min) {
      return '$label muss mindestens $min Zeichen lang sein';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String label = 'Dieses Feld'}) {
    if (value != null && value.trim().length > max) {
      return '$label darf maximal $max Zeichen lang sein';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleaned)) {
      return 'Ungültige Telefonnummer';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return 'Ungültige URL';
    return null;
  }

  static String? postalCode(String? value) {
    if (value == null || value.isEmpty) return 'PLZ ist erforderlich';
    if (!RegExp(r'^\d{4,5}$').hasMatch(value.trim())) return 'Ungültige Postleitzahl';
    return null;
  }

  static String? reviewText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bewertungstext ist erforderlich';
    if (value.trim().length < 100) return 'Bewertung muss mindestens 100 Zeichen lang sein';
    if (value.trim().length > 2000) return 'Bewertung darf maximal 2000 Zeichen lang sein';
    return null;
  }
}
