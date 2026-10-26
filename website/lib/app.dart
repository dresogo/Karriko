import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'src/betriebsprofil.dart';
import 'src/geruest.dart';
import 'src/testdaten.dart';

/// Content-Security-Policy des Prototyps: keine Ausnahme für Skripte oder
/// Styles, keine fremden Quellen (Prüfbedingung 1 aus dem Tab „Website-Umbau
/// SEO“, E-06).
const contentSecurityPolicy =
    "default-src 'self'; script-src 'self'; "
    "style-src 'self'; img-src 'self'; font-src 'self'; "
    "object-src 'none'; base-uri 'self'; form-action 'self'; "
    "frame-ancestors 'none'";

/// Wurzel der Website. Seiten werden je Anfrage auf dem Server gerendert;
/// es gibt keine `@client`-Komponenten und damit kein JavaScript.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    context.setHeader('Content-Security-Policy', contentSecurityPolicy);
    context.setHeader('X-Content-Type-Options', 'nosniff');
    context.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

    return Router(
      routes: [
        Route(
          path: '/',
          title: 'Karriko – Prototyp',
          builder: (context, state) => const _Start(),
        ),
        Route(
          path: '/betrieb/:slug',
          builder: (context, state) {
            final betrieb = testbetriebe[state.params['slug']];
            return betrieb == null ? const UnbekannterBetrieb() : Betriebsprofil(betrieb);
          },
        ),
      ],
    );
  }
}

/// Einstieg des Prototyps: Liste der Testbetriebe.
class _Start extends StatelessComponent {
  const _Start();

  @override
  Component build(BuildContext context) {
    return Geruest([
      section(classes: 'band kopfbereich', [
        p(classes: 'kicker', [.text('PROTOTYP')]),
        h1([.text('Betriebe.')]),
        p(classes: 'lead', [
          .text(
            'Zwei Testbetriebe: einer über der Grenze für einen Score, '
            'einer darunter.',
          ),
        ]),
      ]),
      section(classes: 'band', [
        ul(classes: 'liste', [
          for (final b in testbetriebe.values)
            li([
              a(href: '/betrieb/${b.slug}', [.text(b.name)]),
              span(classes: 'meta', [.text(' · ${b.ort}')]),
            ]),
        ]),
      ]),
    ]);
  }
}
