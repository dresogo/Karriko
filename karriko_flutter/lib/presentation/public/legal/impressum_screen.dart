import 'package:flutter/material.dart';
import '../../common/app_bar_widget.dart';

class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Impressum'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Impressum', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 32),
              _Section(
                title: 'Angaben gemäß § 5 TMG',
                children: [
                  _SubSection('Verantwortlicher', 'Trage hier die vollständigen Angaben des Betreibers ein, einschließlich Name, Rechtsform, Anschrift, E-Mail und Telefonnummer.'),
                  _SubSection('USt-ID', 'Falls vorhanden, ergänze hier die Umsatzsteuer-Identifikationsnummer.'),
                  _SubSection('Vertreter', 'Wenn eine juristische Person Betreiber ist, nenne hier die vertretungsberechtigten Personen.'),
                  _SubSection('Kontakt', 'Hier gehören die direkten Kontaktmöglichkeiten des Verantwortlichen hinein.'),
                  _SubSection('Streitschlichtung', 'Ergänze hier die Hinweise zur Streitbeilegung und zur Teilnahme an Verbraucherschlichtungsverfahren.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _SubSection extends StatelessWidget {
  final String title;
  final String text;

  const _SubSection(this.title, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
