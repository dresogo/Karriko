# karriko_flutter

Die Flutter-Anwendung von Karriko — Bewertungsplattform für die duale Ausbildung im DACH-Markt.

Projektübersicht, Tech-Stack, Konfiguration und der aktuelle Entwicklungsstand stehen in der [README im Repository-Wurzelverzeichnis](../README.md).

## Kurzbefehle

```bash
flutter pub get
flutter run -d chrome

dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Für Bestätigungs- und Passwort-Reset-Mails muss die Ziel-URL gesetzt sein, sonst zeigen alle Links auf `http://localhost`:

```bash
flutter run -d chrome --dart-define=APPWRITE_VERIFICATION_URL=https://deine-domain.example
```
