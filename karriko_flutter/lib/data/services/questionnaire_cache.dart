import 'package:shared_preferences/shared_preferences.dart';

/// Legt geladene Fragendefinitionen lokal ab.
///
/// Je Version ein Eintrag, und alte Versionen bleiben liegen. Das ist Absicht:
/// Wer eine Bewertung unter v1 begonnen hat, fuellt v1 zu Ende, auch wenn
/// inzwischen v2 aktiv ist — und dann muss v1 noch da sein, ohne dass der
/// Storage erreichbar sein muss.
///
/// Der Cache ist nie die Wahrheit, immer nur eine Abkuerzung. Faellt er aus,
/// wird neu geladen; ist das Laden nicht moeglich, greift das mitgelieferte
/// Asset.
class QuestionnaireCache {
  static const _praefix = 'questionnaire';

  /// Jeder Zugriff in try/catch: Im privaten Fenster, bei blockierten
  /// Seitendaten oder auf einem vollen Geraet wirft `shared_preferences`, und
  /// ein fehlgeschlagener Cache-Zugriff darf den Fragebogen nicht anhalten.
  Future<String?> read(String locale, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key(locale, version));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String locale, int version, String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(locale, version), json);
    } catch (_) {
      // Nicht gespeichert, nicht schlimm — beim naechsten Mal neu laden.
    }
  }

  /// Die zuletzt als aktiv bekannte Version.
  ///
  /// Damit laesft sich der Fragebogen auch dann in der richtigen Fassung
  /// oeffnen, wenn gerade keine Verbindung besteht.
  Future<int?> readActiveVersion(String locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_praefix.active.$locale');
    } catch (_) {
      return null;
    }
  }

  Future<void> writeActiveVersion(String locale, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_praefix.active.$locale', version);
    } catch (_) {
      // siehe oben
    }
  }

  String _key(String locale, int version) => '$_praefix.$locale.v$version';
}
