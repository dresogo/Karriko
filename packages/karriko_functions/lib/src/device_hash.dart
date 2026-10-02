import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Der gesalzene Hash einer Gerätekennung.
///
/// Wozu: Abschnitt 9 nennt „Geräte- und Zeitmuster gegen mehrfache Bewertungen
/// desselben Betriebs". Dafür muss sich wiedererkennen lassen, dass zwei
/// Einreichungen vom selben Gerät kamen.
///
/// Was hier **nicht** passiert: Die Rohkennung wird nirgends gespeichert. Sie
/// kommt in der Anfrage, wird gehasht und fällt danach weg. IP-Adressen werden
/// nie gespeichert — auch nicht gehasht.
///
/// Ohne Salz wird nicht gehasht, sondern `null` zurückgegeben. Ein eingebautes
/// Ersatzsalz wäre kein Salz: Es stünde im öffentlichen Repository, und dann
/// ließe sich zu jedem Hash die Kennung zurückrechnen, die ihn erzeugt hat.
String? hashDeviceKey(String? rawKey, String? salt) {
  if (rawKey == null || rawKey.trim().isEmpty) return null;
  if (salt == null || salt.trim().isEmpty) return null;

  final digest = sha256.convert(utf8.encode('$salt:${rawKey.trim()}'));
  return digest.toString();
}
