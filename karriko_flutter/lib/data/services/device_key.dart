import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Eine stabile Kennung dieses Browsers oder Geraets.
///
/// Wofuer: Abschnitt 9 der Spezifikation nennt „Geraete- und Zeitmuster gegen
/// mehrfache Bewertungen desselben Betriebs". Ohne irgendeine wiedererkennbare
/// Groesse laesst sich das nicht pruefen.
///
/// Was hier **nicht** passiert: Es wird nichts ausgelesen, was das Geraet
/// ohnehin preisgibt — kein Fingerprinting ueber Bildschirmgroesse, Schriften
/// oder Canvas. Es ist eine Zufallszahl, die beim ersten Mal gewuerfelt und
/// lokal abgelegt wird. Sie sagt nichts ueber das Geraet aus, sondern nur, dass
/// zwei Einreichungen vom selben ausgingen. Wer die Seitendaten loescht,
/// bekommt eine neue — das ist der Preis und er ist richtig so.
///
/// Der Rohwert verlaesst den Client, wird aber **nie gespeichert**: Die
/// Function salzt ihn mit einem Geheimnis aus einer Umgebungsvariablen und legt
/// nur den Hash ab. IP-Adressen werden nirgends gespeichert.
class DeviceKey {
  static const _key = 'karriko.device_key';

  /// Liest die Kennung oder legt beim ersten Mal eine an.
  ///
  /// `null`, wenn der lokale Speicher nicht zur Verfuegung steht — im privaten
  /// Fenster etwa. Dann fehlt die Dublettenpruefung fuer diese Einreichung,
  /// und das ist hinzunehmen: Ein Fragebogen, der sich ohne Speicherzugriff
  /// nicht abschicken laesst, waere die schlechtere Antwort.
  Future<String?> readOrCreate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vorhanden = prefs.getString(_key);
      if (vorhanden != null && vorhanden.isNotEmpty) return vorhanden;

      final neu = _wuerfeln();
      await prefs.setString(_key, neu);
      return neu;
    } catch (_) {
      return null;
    }
  }

  /// 32 Hexstellen aus `Random.secure()`.
  String _wuerfeln() {
    final zufall = Random.secure();
    final puffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      puffer.write(zufall.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return puffer.toString();
  }
}
