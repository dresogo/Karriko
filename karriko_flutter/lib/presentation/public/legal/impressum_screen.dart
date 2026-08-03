import 'package:flutter/material.dart';
import 'legal_page.dart';

class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPage(
      appBarTitle: 'Impressum',
      eyebrow: 'RECHTLICHES',
      title: 'Impressum',
      subtitle: 'Angaben gemäß § 5 TMG',
      sections: [
        (
          'Verantwortlicher',
          'Trage hier die vollständigen Angaben des Betreibers ein, einschließlich Name, '
              'Rechtsform, Anschrift, E-Mail und Telefonnummer.'
        ),
        (
          'USt-ID',
          'Falls vorhanden, ergänze hier die Umsatzsteuer-Identifikationsnummer.'
        ),
        (
          'Vertreter',
          'Wenn eine juristische Person Betreiber ist, nenne hier die '
              'vertretungsberechtigten Personen.'
        ),
        (
          'Kontakt',
          'Hier gehören die direkten Kontaktmöglichkeiten des Verantwortlichen hinein.'
        ),
        (
          'Streitschlichtung',
          'Ergänze hier die Hinweise zur Streitbeilegung und zur Teilnahme an '
              'Verbraucherschlichtungsverfahren.'
        ),
      ],
      notice: LegalNotice(
        'Diese Angaben sind Platzhalter und müssen vor Go-Live vollständig '
        'ausgefüllt und rechtlich geprüft werden.',
      ),
    );
  }
}
