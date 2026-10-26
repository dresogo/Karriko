import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Kopf und Fuß aller Seiten (Seiten-Tab 00). Phase 1: immer „Anmelden“,
/// der Link führt in die App unter /app (E-08).
class Geruest extends StatelessComponent {
  final List<Component> children;

  const Geruest(this.children, {super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'seite', [
      header(classes: 'kopf', [
        div(classes: 'band kopf-innen', [
          a(href: '/', classes: 'marke', [.text('Karriko')]),
          nav(
            classes: 'kopf-nav',
            attributes: {'aria-label': 'Hauptnavigation'},
            [
              a(href: '/suche', [.text('Suche')]),
              a(href: '/fuer-betriebe', [.text('Für Betriebe')]),
              a(href: '/blog', [.text('Blog')]),
            ],
          ),
          a(href: '/app/login', classes: 'anmelden', [.text('Anmelden')]),
        ]),
      ]),
      main_(children),
      footer(classes: 'fuss', [
        div(classes: 'band', [
          p([
            .text(
              'Prototyp der Karriko-Website (T-12.1). Alle Betriebe und '
              'Bewertungen auf diesen Seiten sind Testdaten.',
            ),
          ]),
          nav(
            attributes: {'aria-label': 'Rechtliches'},
            [
              a(href: '/impressum', [.text('Impressum')]),
              a(href: '/datenschutz', [.text('Datenschutz')]),
            ],
          ),
        ]),
      ]),
    ]);
  }
}
