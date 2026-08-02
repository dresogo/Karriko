import 'package:flutter/material.dart';
import 'legal_page.dart';

class AgbScreen extends StatelessWidget {
  const AgbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPage(
      appBarTitle: 'AGB',
      eyebrow: 'RECHTLICHES',
      title: 'Allgemeine Geschäftsbedingungen',
      subtitle: 'Stand: Juni 2026',
      sections: [
        (
          '§ 1 Geltungsbereich',
          'Diese Allgemeinen Geschäftsbedingungen gelten für die Nutzung der Plattform '
              'Karriko, erreichbar unter karriko.de sowie über die zugehörigen Apps.'
        ),
        (
          '§ 2 Leistungen',
          'Karriko stellt eine Plattform zur Verfügung, auf der Auszubildende Bewertungen '
              'über Ausbildungsbetriebe verfassen und lesen können sowie Betriebe ihre '
              'Profile verwalten können.'
        ),
        (
          '§ 3 Registrierung',
          'Die Nutzung bestimmter Funktionen erfordert eine Registrierung. Der Nutzer ist '
              'verpflichtet, wahrheitsgemäße Angaben zu machen und sein Passwort sicher '
              'aufzubewahren.'
        ),
        (
          '§ 4 Nutzerpflichten',
          'Nutzer sind verpflichtet, keine falschen, irreführenden oder beleidigenden '
              'Inhalte zu veröffentlichen. Bewertungen müssen auf eigenen, echten '
              'Erfahrungen basieren.'
        ),
        (
          '§ 5 Haftungsbeschränkung',
          'Karriko übernimmt keine Haftung für die Richtigkeit der von Nutzern verfassten '
              'Bewertungen und Inhalte. Karriko ist eine neutrale Plattform.'
        ),
        (
          '§ 6 Datenschutz',
          'Die Verarbeitung personenbezogener Daten erfolgt gemäß unserer '
              'Datenschutzerklärung und den Vorgaben der DSGVO.'
        ),
        (
          '§ 7 Änderungen',
          'Karriko behält sich das Recht vor, diese AGB jederzeit zu ändern. Nutzer werden '
              'über wesentliche Änderungen per E-Mail informiert.'
        ),
      ],
      notice: LegalNotice(
        'Diese AGB sind ein Entwurf und müssen vor Go-Live rechtlich geprüft werden.',
      ),
    );
  }
}
