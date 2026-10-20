import 'package:go_router/go_router.dart';

import 'planned_overview_screen.dart';
import 'planned_page.dart';

/// Alle Seiten aus der Sitemap (`notes/Karriko Sitemap.html`), die es noch
/// nicht gibt, als Grobgerüst.
///
/// Keine davon ist verlinkt (Factsheet E-30: nichts versprechen, was nicht
/// funktioniert). Erreichbar sind sie über die Adresse und gesammelt über
/// `/seitenuebersicht`. Bekommt eine Seite echten Inhalt, erhält sie einen
/// eigenen Bildschirm und fällt hier heraus.
const plannedPages = <PlannedPageSpec>[
  // ── Öffentlich ────────────────────────────────────────────────────────────
  PlannedPageSpec(
    path: '/vergleich',
    example: '/vergleich?ids=a,b',
    eyebrow: 'Betriebe vergleichen',
    title: 'Betriebe im Vergleich',
    lede: 'Zwei bis drei Betriebe nebeneinander. Scores erscheinen nur dort, '
        'wo die Sichtbarkeitsschwelle erreicht ist.',
    area: PlannedArea.public,
    refs: ['E-22'],
    sections: [
      PlannedSection('Auswahl',
          'Betriebe aus Suche oder Merkliste hinzufügen, höchstens drei.'),
      PlannedSection(
          'Kennzahlen nebeneinander',
          'Gesamtscore und Teilbewertungen ab drei Bewertungen, darunter ein '
              'Hinweis statt einer Zahl.'),
      PlannedSection('Profil und Stellen',
          'Offene Stellen und Weg zum jeweiligen Profil.'),
    ],
  ),
  PlannedPageSpec(
    path: '/berufe/:beruf',
    example: '/berufe/mechatroniker',
    eyebrow: 'Berufsseite',
    title: 'Ausbildung als {}',
    lede: 'Betriebe, Bewertungen und Stellen zu einem Ausbildungsberuf. '
        'Grundlage ist die Berufsliste der Bundesagentur für Arbeit.',
    area: PlannedArea.public,
    refs: ['E-08', 'T-2.30', 'T-8.3'],
    sections: [
      PlannedSection('Über den Beruf', 'Kurzbeschreibung und Dauer.'),
      PlannedSection('Betriebe mit Bewertungen',
          'Ausbildungsbetriebe für diesen Beruf, sortiert nach Bewertung.'),
      PlannedSection('Offene Stellen', 'Aktuelle Ausbildungsstellen.'),
      PlannedSection('Verwandte Seiten', 'Ähnliche Berufe und Orte.'),
    ],
  ),
  PlannedPageSpec(
    path: '/orte/:stadt',
    example: '/orte/muenchen',
    eyebrow: 'Ortsseite',
    title: 'Ausbildungsbetriebe in {}',
    lede: 'Ausbildungsbetriebe einer Stadt aus den Betriebsdaten.',
    area: PlannedArea.public,
    refs: ['E-08', 'T-8.3'],
    sections: [
      PlannedSection(
          'Betriebe vor Ort', 'Liste mit Score ab drei Bewertungen.'),
      PlannedSection('Häufige Berufe', 'Berufe, die hier ausgebildet werden.'),
      PlannedSection('Offene Stellen', 'Aktuelle Ausbildungsstellen am Ort.'),
    ],
  ),
  PlannedPageSpec(
    path: '/branchen/:branche',
    example: '/branchen/handwerk',
    eyebrow: 'Branchenseite',
    title: 'Ausbildung: {}',
    lede: 'Betriebe und Berufe einer Branche, aus den Branchen des '
        'Suchfilters.',
    area: PlannedArea.public,
    refs: ['E-08', 'T-8.3'],
    sections: [
      PlannedSection('Betriebe der Branche', 'Liste mit Score.'),
      PlannedSection('Berufe der Branche', 'Weg zu den Berufsseiten.'),
    ],
  ),
  PlannedPageSpec(
    path: '/reviews/:id/melden',
    example: '/reviews/beispiel/melden',
    eyebrow: 'Bewertung melden',
    title: 'Bewertung melden',
    lede: 'Meldeweg für jeden, auch ohne Konto. Heute können nur Betriebe '
        'über ihren Bereich melden.',
    area: PlannedArea.public,
    refs: ['T-6.18', 'T-5.10'],
    sections: [
      PlannedSection('Grund', 'Auswahl des Meldegrunds.'),
      PlannedSection('Beschreibung',
          'Was an der Bewertung nicht stimmt; Kontakt für Rückfragen optional.'),
      PlannedSection('Was danach passiert',
          'Prüfung durch die Moderation und eine begründete Entscheidung.'),
    ],
  ),
  PlannedPageSpec(
    path: '/partner',
    eyebrow: 'Für Kammern und Schulen',
    title: 'Karriko für Kammern und Schulen',
    lede: 'Einladungslinks für Azubis und Unterstützung der '
        'Ausbildungsberatung. Das Angebot steht noch nicht fest.',
    area: PlannedArea.public,
    refs: ['T-8.8'],
    sections: [
      PlannedSection(
          'Einladungslinks', 'Wie Kammern und Schulen Azubis einladen.'),
      PlannedSection('Angebot', 'Wird noch festgelegt.'),
      PlannedSection('Kontakt', 'Ansprechpartner für Kammern und Schulen.'),
    ],
  ),
  PlannedPageSpec(
    path: '/transparenz',
    eyebrow: 'So funktioniert Karriko',
    title: 'So funktioniert Karriko',
    lede: 'Wie Bewertungen entstehen, geprüft und sortiert werden. Was hier '
        'steht, prüft vorher der Anwalt.',
    area: PlannedArea.public,
    refs: ['E-29', 'T-5.15'],
    sections: [
      PlannedSection('Wie eine Bewertung entsteht',
          'Fragebogen, Prüfung und Veröffentlichung.'),
      PlannedSection('Echtheit und Moderation',
          'Nachweis des Ausbildungsverhältnisses und menschliche Prüfung.'),
      PlannedSection(
          'Reihenfolge',
          'Wonach sortiert wird – und dass sich Platzierungen nicht kaufen '
              'lassen.'),
      PlannedSection('Anonymität', 'Was Betriebe sehen und was nicht.'),
    ],
  ),
  PlannedPageSpec(
    path: '/hilfe',
    eyebrow: 'Hilfe und Anlaufstellen',
    title: 'Hilfe bei Problemen in der Ausbildung',
    lede: 'Anlaufstellen mit geprüften Kontaktdaten – dieselben wie im '
        'Fragebogen.',
    area: PlannedArea.public,
    refs: ['T-5.3', 'T-9.6'],
    sections: [
      PlannedSection(
          'Ausbildungsberatung der Kammer', 'Kontaktweg folgt nach Prüfung.'),
      PlannedSection(
          'Jugend- und Auszubildendenvertretung', 'Unterstützung im Betrieb.'),
      PlannedSection(
          'Gewerkschaftliche Beratung', 'Kontaktweg folgt nach Prüfung.'),
      PlannedSection('Bei akuter Gefahr', 'Notruf.'),
    ],
  ),
  PlannedPageSpec(
    path: '/presse',
    eyebrow: 'Presse',
    title: 'Presse',
    lede: 'Material und Ansprechpartner für Medienanfragen.',
    area: PlannedArea.public,
    sections: [
      PlannedSection('Pressekit', 'Kurzbeschreibung und Fakten.'),
      PlannedSection('Logo und Bilder', 'Zum Herunterladen.'),
      PlannedSection('Ansprechpartner', 'Kontakt für Medien.'),
    ],
  ),
  PlannedPageSpec(
    path: '/bewertungsrichtlinien',
    eyebrow: 'Rechtliches',
    title: 'Bewertungsrichtlinien',
    lede: 'Was in einer Bewertung stehen darf und was wir entfernen. '
        'Grundlage für Meldungen.',
    area: PlannedArea.public,
    refs: ['T-6.19', 'T-5.20'],
    sections: [
      PlannedSection('Was erlaubt ist', 'Meinungen und eigene Erfahrungen.'),
      PlannedSection('Was wir entfernen',
          'Beleidigungen und unwahre Tatsachenbehauptungen.'),
      PlannedSection('Namen von Privatpersonen', 'Umgang in Freitexten.'),
      PlannedSection('Meldung und Prüfung', 'Ablauf und Fristen.'),
    ],
  ),
  PlannedPageSpec(
    path: '/cookie-einstellungen',
    eyebrow: 'Rechtliches',
    title: 'Cookie-Einstellungen',
    lede: 'Ob ein Banner nötig ist, hängt davon ab, ob nicht notwendige '
        'Dienste laufen. Die Einstellungen müssen jederzeit erreichbar sein.',
    area: PlannedArea.public,
    refs: ['T-5.9', 'E-53'],
    sections: [
      PlannedSection('Notwendige Speicherung', 'Was ohne Einwilligung läuft.'),
      PlannedSection('Optionale Dienste', 'Derzeit keine.'),
      PlannedSection('Einstellungen ändern', 'Auswahl speichern.'),
    ],
  ),
  PlannedPageSpec(
    path: '/barrierefreiheit',
    eyebrow: 'Rechtliches',
    title: 'Erklärung zur Barrierefreiheit',
    lede: 'Nur nötig, wenn Karriko nicht als Kleinstunternehmen ausgenommen '
        'ist. Das klärt der Anwalt.',
    status: PlannedStatus.open,
    area: PlannedArea.public,
    refs: ['T-5.25'],
    sections: [
      PlannedSection('Stand der Vereinbarkeit', 'Prüfung nach WCAG 2.1 AA.'),
      PlannedSection('Bekannte Einschränkungen', 'Liste der offenen Punkte.'),
      PlannedSection('Rückmeldung', 'Kontakt für Hinweise.'),
    ],
  ),
  PlannedPageSpec(
    path: '/stellen',
    eyebrow: 'Ausbildungsbörse',
    title: 'Ausbildungsstellen',
    lede: 'Stellensuche über alle Betriebe. Hängt am Umfang der Börse.',
    status: PlannedStatus.open,
    area: PlannedArea.public,
    refs: ['E-28', 'T-8.5'],
    sections: [
      PlannedSection('Suche und Filter', 'Beruf, Ort, Beginn.'),
      PlannedSection('Stellenliste', 'Treffer mit Weg zur Stellenseite.'),
    ],
  ),

  // ── Anmeldung ─────────────────────────────────────────────────────────────
  PlannedPageSpec(
    path: '/register/betrieb/beanspruchen',
    eyebrow: 'Registrierung Betrieb',
    title: 'Profil beanspruchen',
    lede: 'Ein Betrieb übernimmt ein vorgeschlagenes Profil, statt ein '
        'zweites anzulegen.',
    area: PlannedArea.public,
    refs: ['T-2.27'],
    sections: [
      PlannedSection('Betrieb finden', 'Suche nach dem vorhandenen Profil.'),
      PlannedSection('Zugehörigkeit nachweisen', 'Nachweis für die Prüfung.'),
      PlannedSection('Prüfung', 'Freigabe durch einen Menschen.'),
    ],
  ),
  PlannedPageSpec(
    path: '/konto-wiederherstellen',
    eyebrow: 'Konto',
    title: 'Konto wiederherstellen',
    lede: 'Eine Kontolöschung lässt sich 14 Tage lang zurücknehmen, auch nach '
        'einer Löschung wegen Inaktivität.',
    area: PlannedArea.public,
    refs: ['E-50', 'E-52'],
    sections: [
      PlannedSection('Anmelden', 'Mit Zugangsdaten oder Link aus der Mail.'),
      PlannedSection('Frist', 'Wie lange die Wiederherstellung möglich ist.'),
      PlannedSection('Was zurückkommt', 'Profil, Merkliste, Bewertungen.'),
    ],
  ),

  // ── Azubi-Bereich ─────────────────────────────────────────────────────────
  PlannedPageSpec(
    path: '/my-reviews/:id',
    example: '/my-reviews/beispiel',
    eyebrow: 'Meine Bewertungen',
    title: 'Eigene Bewertung',
    lede: 'Status sehen, Freitext ändern oder zurückziehen.',
    area: PlannedArea.app,
    refs: ['T-6.17'],
    sections: [
      PlannedSection('Status',
          'In Prüfung, zurückgestellt, veröffentlicht oder abgelehnt.'),
      PlannedSection(
          'Begründung',
          'Bei einer Ablehnung, wie sie die '
              'Moderation geschrieben hat.'),
      PlannedSection('Freitext ändern', 'Nur der Text, nicht die Werte.'),
      PlannedSection('Zurückziehen', 'Mit Rückfrage.'),
    ],
  ),
  PlannedPageSpec(
    path: '/reviews/new/betrieb-vorschlagen',
    eyebrow: 'Bewerten',
    title: 'Betrieb vorschlagen',
    lede: 'Wenn ein Betrieb noch nicht auf Karriko ist. Heute endet die Suche '
        'dort ohne Weg weiter.',
    area: PlannedArea.app,
    refs: ['T-2.26'],
    sections: [
      PlannedSection('Angaben zum Betrieb', 'Name, Ort, Branche.'),
      PlannedSection('Dublettenprüfung', 'Ähnliche vorhandene Betriebe.'),
      PlannedSection('Freigabe', 'Prüfung durch die Moderation.'),
    ],
  ),

  // ── Betriebsbereich ───────────────────────────────────────────────────────
  PlannedPageSpec(
    path: '/betrieb-stellen/:id',
    example: '/betrieb-stellen/beispiel',
    eyebrow: 'Ausbildungsstellen',
    title: 'Stelle bearbeiten',
    lede: 'Heute heißt ein Tippfehler: zurückziehen und neu anlegen.',
    area: PlannedArea.app,
    refs: ['T-2.15'],
    sections: [
      PlannedSection('Eckdaten', 'Titel, Ort, Beginn, Dauer.'),
      PlannedSection('Inhalte', 'Aufgaben, Anforderungen, Angebote.'),
      PlannedSection('Veröffentlichung', 'Entwurf oder veröffentlicht.'),
    ],
  ),
  PlannedPageSpec(
    path: '/betrieb-bewerbungen',
    eyebrow: 'Bewerbungen',
    title: 'Bewerbungen',
    lede: 'Bewerbungen und Datei-Upload sind eigene Entscheidungen mit '
        'Datenschutzfolgen.',
    status: PlannedStatus.open,
    area: PlannedArea.app,
    refs: ['E-28', 'T-8.5'],
    sections: [
      PlannedSection('Eingang', 'Neue Bewerbungen.'),
      PlannedSection('Unterlagen', 'Ablage und Löschfristen.'),
      PlannedSection('Status', 'Rückmeldung an Bewerber.'),
    ],
  ),
  PlannedPageSpec(
    path: '/betrieb-einladen',
    eyebrow: 'Bewertungen',
    title: 'Azubis zum Bewerten einladen',
    lede: 'Offen ist, ob Einladungen durch den Betrieb zählen und wie sie '
        'gekennzeichnet werden.',
    status: PlannedStatus.open,
    area: PlannedArea.app,
    refs: ['T-8.8'],
    sections: [
      PlannedSection('Link und QR-Code', 'Für die eigenen Azubis.'),
      PlannedSection(
          'Kennzeichnung', 'Wie eingeladene Bewertungen erscheinen.'),
    ],
  ),
  PlannedPageSpec(
    path: '/subscription/abschluss',
    eyebrow: 'Abonnement',
    title: 'Premium abschließen',
    lede: 'Leistungen, Zahlungsanbieter und Vertragsbedingungen stehen noch '
        'nicht fest. Premium bringt nie einen Vorteil in der Reihenfolge.',
    area: PlannedArea.app,
    refs: ['T-8.4', 'E-29'],
    sections: [
      PlannedSection('Leistungen', 'Was Premium enthält.'),
      PlannedSection('Zahlung', 'Zahlungsart und Rechnungsadresse.'),
      PlannedSection('Vertrag', 'Bedingungen für Betriebe.'),
    ],
  ),
  PlannedPageSpec(
    path: '/subscription/rechnungen',
    eyebrow: 'Abonnement',
    title: 'Rechnungen',
    lede: 'Rechnungen als PDF und Zahlungsart ändern.',
    area: PlannedArea.app,
    refs: ['T-8.4'],
    sections: [
      PlannedSection('Rechnungen', 'Liste zum Herunterladen.'),
      PlannedSection('Zahlungsart', 'Ändern.'),
    ],
  ),
  PlannedPageSpec(
    path: '/betrieb-settings/konto-loeschen',
    eyebrow: 'Einstellungen',
    title: 'Betriebskonto löschen',
    lede: 'Das Profil wird inaktiv, Bewertungen bleiben erhalten.',
    area: PlannedArea.app,
    refs: ['T-2.24'],
    sections: [
      PlannedSection('Was passiert', 'Profil inaktiv, Antworten gelöscht.'),
      PlannedSection('Frist', '30 Tage reaktivierbar.'),
      PlannedSection('Bestätigen', 'Mit Rückfrage.'),
    ],
  ),
];

/// Lesbarer Wert aus einem Pfadparameter: `muenchen` → `Muenchen`,
/// `kfz-mechatroniker` → `Kfz mechatroniker`.
String _lesbar(String raw) {
  final s = raw.replaceAll('-', ' ').trim();
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

/// Routen für alle geplanten Seiten und die Übersicht.
List<GoRoute> plannedRoutes() => [
      GoRoute(
        path: '/seitenuebersicht',
        builder: (_, __) => const PlannedOverviewScreen(),
      ),
      for (final spec in plannedPages)
        GoRoute(
          path: spec.path,
          builder: (_, state) {
            final params = state.pathParameters.values;
            return PlannedPage(
              spec: spec,
              subject: params.isEmpty ? null : _lesbar(params.first),
            );
          },
        ),
    ];
