import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

import 'definition.dart';
import 'geruest.dart';
import 'testdaten.dart';

/// Betriebsprofil (Seiten-Tab 03) als serverseitiges HTML.
///
/// Score und Sichtbarkeit rechnet `questionnaire_core` wie in der Function
/// `aggregate_company` (E-04, E-22, E-23). Kein JavaScript: Die Balken sind
/// SVG mit Breitenattribut statt `style`, damit auch `style-src 'self'`
/// ohne Ausnahme gilt.
class Betriebsprofil extends StatelessComponent {
  final Testbetrieb betrieb;

  const Betriebsprofil(this.betrieb, {super.key});

  @override
  Component build(BuildContext context) {
    final aggregat = CompanyAggregate.compute(
      questionnaire: definition,
      reviews: betrieb.bewertungen,
      now: DateTime.utc(2026, 10, 26),
    );
    final anzahl = aggregat.reviewCount;

    return Geruest([
      section(classes: 'band kopfbereich', [
        p(classes: 'kicker', [.text('${betrieb.branche.toUpperCase()} · ${betrieb.ort.toUpperCase()}')]),
        h1([.text('${betrieb.name}.')]),
        p(classes: 'lead', [.text(betrieb.beschreibung)]),
      ]),
      section(classes: 'band raster', [
        div(classes: 'raster-kopf', [
          p(classes: 'kicker', [.text('BEWERTUNG')]),
          h2([.text('Was Azubis sagen.')]),
        ]),
        div(classes: 'raster-inhalt', [
          if (aggregat.scoreVisible && aggregat.overall != null) ...[
            div(classes: 'gesamt', [
              span(classes: 'gesamt-zahl', [.text(zahl(aggregat.overall!))]),
              span(classes: 'gesamt-von', [.text('von 5')]),
            ]),
            _balken('Gesamt', aggregat.overall!, betont: true),
            p(classes: 'hinweis', [
              .text(
                'Aus $anzahl Bewertungen, gewichtet nach den Prioritäten der '
                'Azubis. Bei wenigen Bewertungen zieht der Wert zur Mitte, '
                'ältere zählen halb.',
              ),
            ]),
            for (final dimension in definition.scoring.dimensions)
              if (aggregat.subscores[dimension] case final wert?) _balken(dimensionLabel(dimension), wert),
          ] else
            div(classes: 'schwelle', [
              p([
                .text(
                  'Noch kein Score: Es gibt $anzahl '
                  '${anzahl == 1 ? 'Bewertung' : 'Bewertungen'}. Ein Score '
                  'erscheint ab ${definition.visibility.scoreMinReviews}, '
                  'damit niemand erraten kann, von wem eine stammt.',
                ),
              ]),
            ]),
        ]),
      ]),
      if (betrieb.freitexte.isNotEmpty)
        section(classes: 'band raster', [
          div(classes: 'raster-kopf', [
            p(classes: 'kicker', [.text('ERFAHRUNGEN')]),
            h2([.text('In eigenen Worten.')]),
          ]),
          div(classes: 'raster-inhalt', [
            for (final text in betrieb.freitexte)
              article(classes: 'freitext', [
                p(classes: 'meta', [.text('${text.beruf} · ${text.quartal}')]),
                h3([.text('Was gut lief')]),
                p([.text(text.gut)]),
                h3([.text('Was schlecht lief')]),
                p([.text(text.schlecht)]),
              ]),
          ]),
        ]),
    ]);
  }

  /// Zahl mit flachem Balken auf der Skala 1 bis 5 (F-2, wie `ScoreBalken`).
  static Component _balken(String label, double wert, {bool betont = false}) {
    final anteil = ((wert - 1) / 4).clamp(0.0, 1.0);
    // Breite in Einheiten der viewBox (0 bis 100), als Attribut statt Style.
    final breite = (anteil * 100).toStringAsFixed(1);
    return div(classes: betont ? 'balken betont' : 'balken', [
      span(classes: 'balken-label', [.text(label)]),
      svg(
        classes: 'balken-spur',
        attributes: {
          'role': 'img',
          'aria-label': '$label: ${zahl(wert)} von 5',
          'preserveAspectRatio': 'none',
        },
        viewBox: '0 0 100 10',
        [
          rect(x: '0', y: '0', width: '100', height: '10', classes: 'leer', []),
          rect(x: '0', y: '0', width: breite, height: '10', classes: 'voll', []),
        ],
      ),
      span(classes: 'balken-zahl', [.text(zahl(wert))]),
    ]);
  }
}

/// 404 für unbekannte Betriebe (Seiten-Tab 29).
class UnbekannterBetrieb extends StatelessComponent {
  const UnbekannterBetrieb({super.key});

  @override
  Component build(BuildContext context) {
    context.setStatusCode(404);
    return Geruest([
      section(classes: 'band kopfbereich', [
        p(classes: 'kicker', [.text('404')]),
        h1([.text('Diesen Betrieb gibt es hier nicht.')]),
        p(classes: 'lead', [
          .text('Vielleicht hilft die '),
          a(href: '/suche', [.text('Suche')]),
          .text('.'),
        ]),
      ]),
    ]);
  }
}
