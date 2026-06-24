import 'package:flutter/material.dart';
import '../../common/app_bar_widget.dart';

class DatenschutzScreen extends StatelessWidget {
  const DatenschutzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = [
      ('1. Verantwortlicher', 'Hier gehört die vollständige Angabe des Verantwortlichen hinein, inklusive Name, Anschrift, E-Mail-Adresse und gegebenenfalls weiterer Kontaktinformationen.'),
      ('2. Datenarten und Verarbeitung', 'Beschreibe hier, welche personenbezogenen Daten erhoben werden und zu welchen Zwecken sie verarbeitet werden.'),
      ('3. Rechtsgrundlagen', 'Ergänze hier die jeweiligen Rechtsgrundlagen nach Art. 6 DSGVO für Registrierung, Nutzung, Support, Sicherheit und Analyse.'),
      ('4. Speicherdauer', 'Definiere hier, wie lange Daten gespeichert werden und nach welchen Kriterien eine Löschung oder Anonymisierung erfolgt.'),
      ('5. Betroffenenrechte', 'Nenne hier die Rechte auf Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit und Widerspruch.'),
      ('6. Cookies', 'Erkläre hier den Einsatz von Cookies, Session-Speichern und etwaigen Consent-Mechanismen.'),
      ('7. Drittanbieter', 'Liste hier externe Dienste wie Hosting, Authentifizierung, Speicher, Analyse oder E-Mail-Provider auf.'),
      ('8. Datenschutzbeauftragter', 'Falls ein Datenschutzbeauftragter erforderlich ist, trage hier dessen Kontaktdaten ein.'),
    ];

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Datenschutz'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Datenschutzerklärung', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 32),
              ...sections.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$1, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(s.$2, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, color: Color(0xFFB45309)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'WICHTIG: Diese Datenschutzerklärung muss vor Go-Live von einem Rechtsanwalt geprüft werden!',
                        style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
