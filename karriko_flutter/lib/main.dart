import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/app.dart';
import 'data/services/appwrite_service.dart';

void main() async {
  // Adressen ohne `#/` (T-11.2): Die Links in Bestaetigungs-, Reset- und
  // Magic-Link-Mails zeigen auf Pfade wie /verify-email. Mit der Hash-Variante
  // kam dort nur eine 404. Der Server liefert dafuer jede unbekannte Adresse
  // als index.html aus (web/.htaccess). Ausserhalb des Browsers ohne Wirkung.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await AppwriteService.initialize();
  runApp(const ProviderScope(child: KarrikoApp()));
}
