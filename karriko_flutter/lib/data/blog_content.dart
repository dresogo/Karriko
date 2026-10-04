import 'models/blog_entry_model.dart';

/// Statisch hinterlegte Inhalte für Blog und Neuigkeiten, absteigend nach
/// Datum sortiert. Liegt zentral, damit Übersicht und Detailseite dieselbe
/// Quelle nutzen.
class BlogContent {
  BlogContent._();

  static final entries = <BlogEntry>[
    BlogEntry.update(
      title: 'Fragebogen für Betriebsbewertungen',
      teaser:
          'Azubis beantworten jetzt strukturierte Fragen zu Ausbildungsqualität, '
          'Betreuung und Übernahmechancen statt nur Freitext zu schreiben.',
      date: DateTime(2026, 7, 24),
      version: 'v1.4',
      updateKind: UpdateKind.neu,
    ),
    BlogEntry.article(
      title: 'Wie finde ich den richtigen Ausbildungsbetrieb?',
      teaser:
          'Worauf es bei der Wahl wirklich ankommt – von der Branche über das '
          'Betriebsklima bis zu den Übernahmechancen.',
      date: DateTime(2026, 6, 18),
      category: 'Tipps & Tricks',
      readingMinutes: 4,
      slug: 'tipps-ausbildungsbetrieb',
      body: const [
        ArticleParagraph(
          'Die Wahl des Ausbildungsbetriebs prägt die nächsten zwei bis drei '
          'Jahre – und oft den Berufseinstieg danach. Trotzdem entscheiden '
          'viele nach dem ersten Eindruck aus der Stellenanzeige. Mit ein paar '
          'gezielten Fragen triffst du eine deutlich bessere Wahl.',
        ),
        ArticleHeading('Erst klären, was du willst'),
        ArticleParagraph(
          'Bevor du Betriebe vergleichst, lohnt ein ehrlicher Blick auf dich '
          'selbst. Welche Branche interessiert dich wirklich? Arbeitest du '
          'lieber in einem großen Unternehmen mit festen Abläufen oder in '
          'einem kleinen Team, in dem du schnell Verantwortung bekommst?',
        ),
        ArticleList([
          'Branche und Beruf: Was willst du in drei Jahren können?',
          'Betriebsgröße: Struktur und Programme oder kurze Wege?',
          'Ort: Wie lang darf der Arbeitsweg jeden Tag sein?',
          'Perspektive: Ist dir eine Übernahme wichtig?',
        ]),
        ArticleHeading('Bewertungen richtig lesen'),
        ArticleParagraph(
          'Auf Karriko berichten Azubis, wie ihre Ausbildung im Alltag '
          'aussieht: Betreuung, Lerninhalte, Betriebsklima und Übernahme. '
          'Einzelne Bewertungen können Ausreißer sein. Aussagekräftig wird es, '
          'wenn mehrere Azubis unabhängig voneinander dasselbe beschreiben.',
        ),
        ArticleCallout(
          title: 'Tipp',
          text: 'Achte auf das Datum. Eine Bewertung von vor vier Jahren sagt '
              'wenig über die heutige Ausbilderin oder den heutigen Ausbilder.',
        ),
        ArticleHeading('Im Gespräch nachfragen'),
        ArticleParagraph(
          'Das Vorstellungsgespräch ist keine Einbahnstraße. Gute Betriebe '
          'freuen sich über konkrete Fragen, weil sie zeigen, dass du dich '
          'ernsthaft interessierst.',
        ),
        ArticleList([
          'Wer ist im Alltag mein Ansprechpartner?',
          'Wie viele Azubis wurden in den letzten Jahren übernommen?',
          'Wie läuft die Prüfungsvorbereitung ab?',
          'Kann ich mit aktuellen Azubis sprechen?',
        ], ordered: true),
        ArticleHeading('Fazit'),
        ArticleParagraph(
          'Nutze alle Quellen zusammen: Bewertungen auf Karriko, ein Praktikum '
          'oder einen Probetag und das Gespräch mit Azubis vor Ort. So '
          'entscheidest du nicht nach Bauchgefühl allein, sondern mit einem '
          'klaren Bild davon, was dich erwartet.',
        ),
      ],
    ),
    BlogEntry.update(
      title: 'Schnellere Suche mit Branchenfiltern',
      teaser:
          'Die Betriebssuche filtert jetzt nach Branche, Ort und Mindestbewertung '
          'und liefert Ergebnisse spürbar schneller.',
      date: DateTime(2026, 6, 2),
      version: 'v1.3',
      updateKind: UpdateKind.verbessert,
    ),
    BlogEntry.article(
      title: 'DSGVO und Ausbildungsbewertungen',
      teaser:
          'Was Betriebe über anonyme Bewertungen wissen müssen und welche Rechte '
          'Azubis beim Veröffentlichen haben.',
      date: DateTime(2026, 5, 21),
      category: 'Datenschutz',
      readingMinutes: 3,
      slug: 'dsgvo-bewertungen',
      body: const [
        ArticleParagraph(
          'Bewertungen leben davon, dass Azubis offen schreiben können. '
          'Gleichzeitig geht es um echte Menschen und echte Betriebe. Die '
          'Datenschutz-Grundverordnung (DSGVO) setzt dafür den Rahmen – für '
          'beide Seiten.',
        ),
        ArticleHeading('Was Azubis wissen sollten'),
        ArticleParagraph(
          'Deine Bewertung erscheint ohne deinen Namen. Damit sie anonym '
          'bleibt, solltest du selbst auch keine Details nennen, über die man '
          'dich leicht erkennt.',
        ),
        ArticleList([
          'Keine Namen von Kolleginnen, Kollegen oder Vorgesetzten nennen.',
          'Bei sehr kleinen Teams auf eindeutige Details verzichten.',
          'Eigene Daten kannst du jederzeit einsehen und löschen lassen.',
        ]),
        ArticleHeading('Was Betriebe wissen sollten'),
        ArticleParagraph(
          'Betriebe haben keinen Anspruch darauf, zu erfahren, wer eine '
          'Bewertung geschrieben hat. Sie können aber auf Bewertungen '
          'antworten und Beiträge melden, die gegen die Richtlinien verstoßen '
          '– etwa bei Beleidigungen oder falschen Tatsachenbehauptungen.',
        ),
        ArticleCallout(
          title: 'Wie Karriko moderiert',
          text: 'Gemeldete Bewertungen prüft unser Team von Hand. Wir löschen '
              'keine Kritik, nur weil sie unbequem ist – aber wir entfernen '
              'Inhalte, die Personen bloßstellen.',
        ),
        ArticleHeading('Kurz zusammengefasst'),
        ArticleParagraph(
          'Ehrliche Kritik ist erlaubt und erwünscht, persönliche Angriffe '
          'nicht. Dieser Artikel gibt einen Überblick und ersetzt keine '
          'Rechtsberatung. Details stehen in unserer Datenschutzerklärung.',
        ),
      ],
    ),
    BlogEntry.update(
      title: 'Benachrichtigungen kamen doppelt an',
      teaser:
          'Ein Fehler hat Betrieben dieselbe Bewertungsbenachrichtigung mehrfach '
          'zugestellt. Das ist behoben.',
      date: DateTime(2026, 5, 8),
      version: 'v1.2.1',
      updateKind: UpdateKind.behoben,
    ),
    BlogEntry.article(
      title: 'Warum Azubi-Feedback Betrieben hilft',
      teaser:
          'Ehrliche Rückmeldungen decken auf, woran Ausbildung im Alltag scheitert '
          '– und was sich mit wenig Aufwand ändern lässt.',
      date: DateTime(2026, 4, 30),
      category: 'Für Betriebe',
      readingMinutes: 3,
      slug: 'azubi-feedback-betriebe',
      body: const [
        ArticleParagraph(
          'Viele Betriebe erfahren erst beim Abschlussgespräch – oder gar '
          'nicht –, was in der Ausbildung gehakt hat. Dann ist es zu spät, '
          'etwas zu ändern. Regelmäßiges Feedback dreht das um.',
        ),
        ArticleHeading('Probleme früh sehen'),
        ArticleParagraph(
          'Oft sind es Kleinigkeiten, die den Alltag schwer machen: kein '
          'fester Ansprechpartner in der Urlaubszeit, Aufgaben ohne Bezug zum '
          'Ausbildungsplan, zu wenig Zeit für die Berufsschule. Wer davon '
          'früh erfährt, kann gegensteuern, bevor jemand abbricht.',
        ),
        ArticleHeading('Besser gefunden werden'),
        ArticleParagraph(
          'Bewerberinnen und Bewerber lesen Bewertungen, bevor sie sich '
          'bewerben. Ein Betrieb, der auf Kritik sachlich antwortet und '
          'zeigt, was sich verändert hat, wirkt glaubwürdiger als einer mit '
          'ausschließlich perfekten Noten.',
        ),
        ArticleCallout(
          title: 'Tipp für den Einstieg',
          text: 'Antworte auf die drei jüngsten Bewertungen. Bedanke dich, '
              'gehe auf einen konkreten Punkt ein und sag, was du daraus '
              'mitnimmst.',
        ),
        ArticleHeading('Drei schnelle Hebel'),
        ArticleList([
          'Einen festen Ansprechpartner pro Azubi benennen.',
          'Alle drei Monate ein kurzes Feedbackgespräch einplanen.',
          'Lernzeit für die Berufsschule im Wochenplan blocken.',
        ], ordered: true),
      ],
    ),
    BlogEntry.article(
      title: 'Top 10 Ausbildungsberufe 2026',
      teaser:
          'Welche Ausbildungen aktuell am stärksten nachgefragt werden und wo die '
          'Übernahmequoten am höchsten liegen.',
      date: DateTime(2026, 3, 12),
      category: 'Karriere',
      readingMinutes: 3,
      slug: 'top-ausbildungsberufe-2026',
      body: const [
        ArticleParagraph(
          'Jedes Jahr beginnen Hunderttausende eine duale Ausbildung. Einige '
          'Berufe sind dabei besonders gefragt – bei Bewerberinnen und '
          'Bewerbern ebenso wie bei Betrieben, die händeringend Nachwuchs '
          'suchen.',
        ),
        ArticleHeading('Die gefragtesten Berufe'),
        ArticleParagraph(
          'Diese Ausbildungen gehören seit Jahren zu den beliebtesten. Die '
          'Reihenfolge schwankt je nach Jahr und Region.',
        ),
        ArticleList([
          'Kaufmann/-frau für Büromanagement',
          'Kraftfahrzeugmechatroniker/-in',
          'Kaufmann/-frau im Einzelhandel',
          'Medizinische/-r Fachangestellte/-r',
          'Fachinformatiker/-in',
          'Industriekaufmann/-frau',
          'Elektroniker/-in',
          'Verkäufer/-in',
          'Anlagenmechaniker/-in für Sanitär-, Heizungs- und Klimatechnik',
          'Zahnmedizinische/-r Fachangestellte/-r',
        ], ordered: true),
        ArticleHeading('Wo die Chancen besonders gut sind'),
        ArticleParagraph(
          'In Handwerk, Pflege und IT übersteigt die Zahl der offenen Stellen '
          'vielerorts die der Bewerbungen. Das verbessert deine '
          'Verhandlungsposition und die Aussicht auf eine Übernahme.',
        ),
        ArticleCallout(
          title: 'Bewertungen vergleichen',
          text: 'Wie es um Übernahme und Betreuung in einem konkreten Betrieb '
              'steht, verraten die Bewertungen auf Karriko oft besser als '
              'jede Statistik.',
        ),
      ],
    ),
  ];

  static List<BlogEntry> get articles =>
      entries.where((e) => e.isArticle).toList();

  static BlogEntry? articleBySlug(String slug) =>
      articles.where((e) => e.slug == slug).firstOrNull;
}
