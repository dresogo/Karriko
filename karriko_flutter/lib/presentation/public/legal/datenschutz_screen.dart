import 'package:flutter/material.dart';
import 'legal_page.dart';

class DatenschutzScreen extends StatelessWidget {
  const DatenschutzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPage(
      appBarTitle: 'Datenschutz',
      eyebrow: 'RECHTLICHES',
      title: 'Datenschutzerklärung',
      sections: [
        (
          '1. Verantwortlicher',
          'Hier gehört die vollständige Angabe des Verantwortlichen hinein, inklusive '
              'Name, Anschrift, E-Mail-Adresse und gegebenenfalls weiterer '
              'Kontaktinformationen.'
        ),
        (
          '2. Datenarten und Verarbeitung',
          'Beschreibe hier, welche personenbezogenen Daten erhoben werden und zu welchen '
              'Zwecken sie verarbeitet werden.'
        ),
        (
          '3. Rechtsgrundlagen',
          'Ergänze hier die jeweiligen Rechtsgrundlagen nach Art. 6 DSGVO für '
              'Registrierung, Nutzung, Support, Sicherheit und Analyse.'
        ),
        (
          '4. Speicherdauer',
          'Definiere hier, wie lange Daten gespeichert werden und nach welchen Kriterien '
              'eine Löschung oder Anonymisierung erfolgt.'
        ),
        (
          '5. Betroffenenrechte',
          'Nenne hier die Rechte auf Auskunft, Berichtigung, Löschung, Einschränkung, '
              'Datenübertragbarkeit und Widerspruch.'
        ),
        (
          '6. Cookies',
          'Erkläre hier den Einsatz von Cookies, Session-Speichern und etwaigen '
              'Consent-Mechanismen.'
        ),
        (
          '7. Drittanbieter',
          'Liste hier externe Dienste wie Hosting, Authentifizierung, Speicher, Analyse '
              'oder E-Mail-Provider auf.'
        ),
        (
          '8. Datenschutzbeauftragter',
          'Falls ein Datenschutzbeauftragter erforderlich ist, trage hier dessen '
              'Kontaktdaten ein.'
        ),
      ],
      notice: LegalNotice(
        'WICHTIG: Diese Datenschutzerklärung muss vor Go-Live von einem Rechtsanwalt '
        'geprüft werden.',
      ),
    );
  }
}
