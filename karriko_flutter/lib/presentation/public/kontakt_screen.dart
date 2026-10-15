import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';
import '../common/tap_target.dart';

/// Adresse für alle Anfragen über die Kontaktseite.
const kontaktEmail = 'demharter@dresogo.de';

/// Kontakt per E-Mail.
///
/// Hier stand ein Formular, das nichts verschickte und trotzdem „Nachricht
/// gesendet!“ meldete (T-2.11). Bis es einen Eingang dafür gibt (T-2.29),
/// öffnet die Seite ehrlich das Mailprogramm. Die Adresse steht zusätzlich als
/// Text da, für alle ohne eingerichtetes Mailprogramm.
class KontaktScreen extends StatelessWidget {
  const KontaktScreen({super.key});

  static final _mailto = Uri(scheme: 'mailto', path: kontaktEmail);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Kontakt'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kontakt',
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text('Fragen, Hinweise oder Kritik: Schreib uns eine E-Mail.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 32),
                  Link(
                    uri: _mailto,
                    builder: (context, followLink) => SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: followLink,
                        icon: const Icon(Icons.email_outlined, size: 18),
                        label: const Text('E-Mail schreiben'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text('Oder direkt an:',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  _ContactInfo(
                      icon: Icons.email_outlined,
                      label: kontaktEmail,
                      uri: _mailto),
                  const SizedBox(height: 8),
                  const _ContactInfo(
                      icon: Icons.location_on_outlined,
                      label: 'Deutschland · DACH-Region'),
                ],
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Macht die Angabe zum echten Link (im Web ein <a href>).
  final Uri? uri;

  const _ContactInfo({required this.icon, required this.label, this.uri});

  @override
  Widget build(BuildContext context) {
    // Flexible: Auf dem Smartphone ist eine lange Angabe wie die E-Mail-Adresse
    // breiter als die Zeile und lief um bis zu 264 px ueber. Jetzt bricht sie
    // um; das Symbol bleibt oben an der ersten Zeile.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: uri == null
              ? Text(label, style: Theme.of(context).textTheme.bodyLarge)
              : Link(
                  uri: uri,
                  builder: (context, followLink) => TapTarget(
                    onTap: followLink,
                    builder: (context, active) => Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            decoration: active
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
