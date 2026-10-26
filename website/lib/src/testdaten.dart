import 'package:questionnaire_core/questionnaire_core.dart';

/// Testdaten für den Prototyp. Ein erfundener Betrieb mit erfundenen
/// Bewertungen, nur damit die Seite etwas zum Rechnen und Zeigen hat. Im
/// Betrieb kommen die Daten aus Appwrite (`companies`, `public_reviews`).
class Testbetrieb {
  final String slug;
  final String name;
  final String ort;
  final String branche;
  final String beschreibung;
  final List<AggregateInput> bewertungen;
  final List<Freitext> freitexte;

  const Testbetrieb({
    required this.slug,
    required this.name,
    required this.ort,
    required this.branche,
    required this.beschreibung,
    required this.bewertungen,
    required this.freitexte,
  });
}

class Freitext {
  final String beruf;
  final String quartal;
  final String gut;
  final String schlecht;

  const Freitext({
    required this.beruf,
    required this.quartal,
    required this.gut,
    required this.schlecht,
  });
}

final testbetriebe = <String, Testbetrieb>{
  for (final b in [_mitScore, _unterSchwelle]) b.slug: b,
};

/// Vier Bewertungen: über der Grenze für den Score (3), unter der für Zahlen
/// (5, E-22).
final _mitScore = Testbetrieb(
  slug: 'testbetrieb-metallbau',
  name: 'Testbetrieb Metallbau',
  ort: 'Musterstadt',
  branche: 'Handwerk',
  beschreibung:
      'Erfundener Betrieb für den Prototyp der Website. '
      'Alle Angaben und Bewertungen sind Testdaten.',
  bewertungen: [
    _bewertung(4.4, 4.0, 4.2, 3.4, 4.1, DateTime.utc(2026, 7, 1)),
    _bewertung(3.9, 3.2, 3.8, 2.9, 3.6, DateTime.utc(2026, 4, 1)),
    _bewertung(4.7, 4.5, 4.4, 3.8, 4.3, DateTime.utc(2026, 1, 1)),
    _bewertung(3.1, 2.8, 3.5, 2.6, 3.0, DateTime.utc(2025, 10, 1)),
  ],
  freitexte: const [
    Freitext(
      beruf: 'Metallbauer/in',
      quartal: 'Q3 2026',
      gut: 'Testtext: Viel Zeit an echten Aufträgen, feste Ansprechperson.',
      schlecht: 'Testtext: In Spitzenzeiten wenig Raum für die Berufsschule.',
    ),
    Freitext(
      beruf: 'Metallbauer/in',
      quartal: 'Q2 2026',
      gut: 'Testtext: Werkstatt gut ausgestattet.',
      schlecht: 'Testtext: Überstunden werden spät ausgeglichen.',
    ),
  ],
);

/// Zwei Bewertungen: unter der Grenze, kein Score (E-22).
final _unterSchwelle = Testbetrieb(
  slug: 'testbetrieb-kanzlei',
  name: 'Testbetrieb Kanzlei',
  ort: 'Musterstadt',
  branche: 'Kaufmännisch',
  beschreibung:
      'Erfundener Betrieb mit zu wenigen Bewertungen für einen '
      'Score. Alle Angaben sind Testdaten.',
  bewertungen: [
    _bewertung(4.0, 4.2, 4.1, 3.9, 3.8, DateTime.utc(2026, 7, 1)),
    _bewertung(3.6, 3.4, 3.9, 3.5, 3.7, DateTime.utc(2026, 4, 1)),
  ],
  freitexte: const [],
);

AggregateInput _bewertung(
  double fachlich,
  double betreuung,
  double umgang,
  double belastung,
  double perspektive,
  DateTime veroeffentlicht,
) => AggregateInput(
  subscores: {
    'fachlich': fachlich,
    'betreuung': betreuung,
    'umgang': umgang,
    'belastung': belastung,
    'perspektive': perspektive,
  },
  publishedAt: veroeffentlicht,
);
