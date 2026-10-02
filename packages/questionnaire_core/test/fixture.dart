import 'package:questionnaire_core/questionnaire_core.dart';

/// Ein Fragebogen in der Form, die die echte v1 haben wird — nur kürzer.
///
/// Bewusst **nicht** die echte v1: Die entsteht in Etappe B und wird dann
/// zusätzlich gegen dieselben Personas geprüft. Hier geht es um die Mechanik,
/// und die ist mit fünfundzwanzig Fragen vollständig auszureizen. Ein
/// Testfragebogen, der jede Änderung am Inhalt mitmacht, prüft die Mechanik
/// nicht mehr, sondern nur noch sich selbst.
///
/// Die Texte hier sind Attrappen. Sie sind kurz gehalten, damit beim Lesen der
/// Tests die Struktur im Vordergrund steht.
Map<String, Object?> fixtureJson() => {
      'id': 'fixture',
      'version': 1,
      'locale': 'de-DE',
      'phases': [
        {'id': 's', 'label': 'Steuerfragen', 'estimatedSeconds': 45},
        {'id': 'core', 'label': 'Kern', 'estimatedSeconds': 150},
        {
          'id': 'modules',
          'label': 'Vertiefung',
          'holdsModules': true,
        },
        {'id': 'close', 'label': 'Abschluss', 'estimatedSeconds': 90},
      ],
      'flow': {
        'tenseQuestion': 's1_status',
        'pastValues': [
          'ausgelernt_geblieben',
          'ausgelernt_gegangen',
          'abgebrochen',
        ],
        'priorityQuestion': 'k12_prioritaeten',
        'priorityTopN': 3,
        'secondsPerQuestion': 10,
      },
      'questions': [
        // ── Phase 0 ────────────────────────────────────────────────────────
        _choice(
          id: 's1_status',
          specRef: 'S1',
          phase: 's',
          type: 'single_choice_tiles',
          required: true,
          options: const [
            ('in_ausbildung', 'noch in der Ausbildung', null),
            ('ausgelernt_geblieben', 'ausgelernt, geblieben', null),
            ('ausgelernt_gegangen', 'ausgelernt, gegangen', null),
            ('abgebrochen', 'vorzeitig beendet', null),
          ],
        ),
        _choice(
          id: 's4_lehrjahr',
          specRef: 'S4',
          phase: 's',
          type: 'segmented',
          condition: {
            'eq': [
              {'answer': 's1_status'},
              'in_ausbildung',
            ],
          },
          options: const [
            ('probezeit', 'Probezeit', null),
            ('1', '1. Jahr', null),
            ('2', '2. Jahr', null),
            ('3', '3. Jahr', null),
            ('4', '4. Jahr', null),
          ],
        ),
        _choice(
          id: 's6_azubis',
          specRef: 'S6',
          phase: 's',
          type: 'single_choice_tiles',
          options: const [
            ('nur_ich', 'nur ich', null),
            ('2_5', '2 bis 5', null),
            ('6_20', '6 bis 20', null),
            ('mehr', 'mehr', null),
            ('weiss_nicht', 'weiß ich nicht', null),
          ],
        ),
        _choice(
          id: 's7_form',
          specRef: 'S7',
          phase: 's',
          type: 'single_choice_tiles',
          options: const [
            ('dual', 'klassisch dual', null),
            ('duales_studium', 'duales Studium', null),
            ('teilzeit', 'Teilzeit', null),
            ('verbund', 'Verbundausbildung', null),
          ],
        ),
        {
          'id': 's8_alltag',
          'specRef': 'S8',
          'type': 'swipe_binary',
          'phase': 's',
          'text': {
            'current': 'Was trifft auf deinen Arbeitsalltag zu?',
            'past': 'Was traf auf deinen Arbeitsalltag zu?',
          },
          'config': {
            'yesValue': 'ja',
            'noValue': 'nein',
            'cards': [
              {
                'id': 'schicht',
                'label': {'current': 'Schichtarbeit'},
              },
              {
                'id': 'wochenende',
                'label': {'current': 'Wochenenddienste'},
              },
              {
                'id': 'koerperlich',
                'label': {'current': 'körperlich schwere Arbeit'},
              },
            ],
          },
        },
        _choice(
          id: 's9_minderjaehrig',
          specRef: 'S9',
          phase: 's',
          type: 'single_choice_tiles',
          options: const [
            ('ja', 'ja', null),
            ('nein', 'nein', null),
          ],
        ),

        // ── Phase 1, Fakten ────────────────────────────────────────────────
        {
          'id': 'k3_ueberstunden',
          'specRef': 'K3',
          'type': 'stepper',
          'phase': 'core',
          'text': {
            'current': 'Überstunden in den letzten vier Wochen?',
            'past': 'Überstunden in einem typischen Monat?',
          },
          'config': {
            'min': 0,
            'max': 200,
            'step': 5,
            'special': ['weiss_nicht'],
            // Nicht linear: Die ersten fünf Überstunden wiegen anders als die
            // fünfundvierzigsten.
            'scoreBands': [
              {'max': 0, 'score': 1.0},
              {'max': 10, 'score': 0.75},
              {'max': 20, 'score': 0.5},
              {'max': 40, 'score': 0.25},
              {'max': null, 'score': 0.0},
            ],
          },
        },
        _choice(
          id: 'k3_1_ausgleich',
          specRef: 'K3.1',
          phase: 'core',
          type: 'single_choice_tiles',
          condition: {
            'gt': [
              {'answer': 'k3_ueberstunden'},
              0,
            ],
          },
          options: const [
            ('ausgezahlt', 'werden ausgezahlt', 1.0),
            ('abgefeiert', 'abgefeiert', 1.0),
            ('teils', 'teils teils', 0.5),
            ('nichts', 'gar nichts', 0.0),
            ('weiss_nicht', 'weiß ich nicht', null),
          ],
        ),
        _choice(
          id: 'k4_erreichbarkeit',
          specRef: 'K4',
          phase: 'core',
          type: 'verbal_choice',
          required: true,
          options: _erreichbarkeit,
        ),
        {
          'id': 'k5_empfehlung',
          'specRef': 'K5',
          'type': 'scale_0_10',
          'phase': 'core',
          'required': true,
          'text': {'current': 'Weiterempfehlung?', 'past': 'Weiterempfehlung?'},
          'config': {'min': 0, 'max': 10},
        },
        {
          'id': 'k6_gesamt',
          'specRef': 'K6',
          'type': 'vas_unnumbered',
          'phase': 'core',
          'required': true,
          'public': true,
          'text': {
            'current': 'Wie gut ist die Ausbildung insgesamt?',
            'past': 'Wie gut war die Ausbildung insgesamt?',
          },
          'config': {'min': 0, 'max': 100},
        },

        // ── Phase 1, die fünf Dimensionen ──────────────────────────────────
        _choice(
          id: 'k7_anleitung',
          specRef: 'K7',
          phase: 'core',
          type: 'verbal_choice',
          options: _fuenf,
        ),
        _choice(
          id: 'k8_lernwert',
          specRef: 'K8',
          phase: 'core',
          type: 'verbal_choice',
          options: _fuenf,
        ),
        _choice(
          id: 'k9_umgang',
          specRef: 'K9',
          phase: 'core',
          type: 'verbal_choice',
          options: const [
            ('augenhoehe', 'auf Augenhöhe', 1.0),
            ('freundlich', 'überwiegend freundlich', 0.75),
            ('sachlich', 'sachlich, mehr nicht', 0.5),
            ('von_oben', 'oft von oben herab', 0.25),
            ('respektlos', 'respektlos', 0.0),
          ],
        ),
        // Umgekehrt gepolt: Position 1 ist hier die *schlechte* Antwort,
        // anders als bei K7, K8, K9 und K11. Genau daran hängt der
        // Straightlining-Index — wer überall die erste Option antippt,
        // widerspricht sich hier.
        _choice(
          id: 'k10_belastung',
          specRef: 'K10',
          phase: 'core',
          type: 'verbal_choice',
          reversePolarity: true,
          options: const [
            ('fast_taeglich', 'fast täglich', 0.0),
            ('oft', 'oft', 0.25),
            ('manchmal', 'manchmal', 0.5),
            ('selten', 'selten', 0.75),
            ('fast_nie', 'fast nie', 1.0),
          ],
        ),
        _choice(
          id: 'k11_planung',
          specRef: 'K11',
          phase: 'core',
          type: 'verbal_choice',
          options: _fuenf,
        ),
        {
          'id': 'k12_prioritaeten',
          'specRef': 'K12',
          'type': 'rank_top_n',
          'phase': 'core',
          'required': true,
          'text': {
            'current': 'Was zählt am meisten?',
            'past': 'Was zählte am meisten?'
          },
          'config': {'topN': 3},
          'options': [
            for (final entry in const [
              ('fachlich', 'Was ich fachlich lerne'),
              ('umgang', 'Wie mit mir umgegangen wird'),
              ('geld', 'Geld und Sachleistungen'),
              ('arbeitszeit', 'Arbeitszeiten und freie Zeit'),
              ('ausbilder', 'Mein Ausbilder'),
              ('pruefung', 'Vorbereitung auf die Prüfung'),
              ('uebernahme', 'Übernahme und Zukunft'),
              ('team', 'Stimmung im Team'),
            ])
              {
                'id': entry.$1,
                'label': {'current': entry.$2, 'past': entry.$2},
              },
          ],
        },

        // ── Phase 2, Modulfragen ───────────────────────────────────────────
        {
          'id': 'm_ausbilder_gespraeche',
          'specRef': 'Modul Ausbilder',
          'type': 'stepper',
          'phase': 'modules',
          'module': 'ausbilder',
          'text': {
            'current':
                'Gespräche über deinen Stand in den letzten drei Monaten?',
            'past': 'Gespräche über deinen Stand in einem typischen Quartal?',
          },
          'config': {
            'min': 0,
            'max': 12,
            'step': 1,
            'scoreBands': [
              {'max': 0, 'score': 0.0},
              {'max': 2, 'score': 0.4},
              {'max': 5, 'score': 0.8},
              {'max': null, 'score': 1.0},
            ],
          },
        },
        _choice(
          id: 'm_ausbilder_erreichbar',
          specRef: 'Modul Ausbilder',
          phase: 'modules',
          module: 'ausbilder',
          type: 'verbal_choice',
          options: _erreichbarkeit,
        ),
        _choice(
          id: 'm_arbeitszeit_planbarkeit',
          specRef: 'Modul Arbeitszeit',
          phase: 'modules',
          module: 'arbeitszeit',
          type: 'verbal_choice',
          options: const [
            ('lange_vorher', 'lange vorher', 1.0),
            ('woche_vorher', 'eine Woche vorher', 0.5),
            ('kurzfristig', 'kurzfristig', 0.0),
          ],
        ),
        _choice(
          id: 'm_pruefung_lernzeit',
          specRef: 'Modul Prüfung',
          phase: 'modules',
          module: 'pruefung',
          type: 'verbal_choice',
          options: const [
            ('ja_geregelt', 'ja, geregelt', 1.0),
            ('auf_nachfrage', 'auf Nachfrage', 0.5),
            ('nein', 'nein', 0.0),
          ],
        ),
        _choice(
          id: 'm_uebernahme_zeitpunkt',
          specRef: 'Modul Übernahme',
          phase: 'modules',
          module: 'uebernahme',
          type: 'single_choice_tiles',
          options: const [
            ('frueh', 'früh und von selbst', 1.0),
            ('spaet', 'spät, auf Nachfrage', 0.5),
            ('gar_nicht', 'gar nicht', 0.0),
          ],
        ),
        {
          'id': 'm_jas_karten',
          'specRef': 'Modul Jugendarbeitsschutz',
          'type': 'swipe_binary',
          'phase': 'modules',
          'module': 'jugendarbeitsschutz',
          'sensitive': true,
          'text': {
            'current': 'Was trifft zu?',
            'past': 'Was traf zu?',
          },
          'config': {
            'yesValue': 'ja',
            'noValue': 'nein',
            'otherValues': ['weiss_nicht'],
            'cards': [
              {
                'id': 'berufsschultag',
                'label': {'current': 'Freistellung am Berufsschultag'},
              },
              {
                'id': 'nach20uhr',
                'label': {'current': 'Keine Arbeit nach 20 Uhr'},
              },
              {
                'id': 'samstag',
                'label': {'current': 'Keine Samstagsarbeit'},
              },
            ],
          },
        },
        _choice(
          id: 'm_schule_interesse',
          specRef: 'Modul Berufsschule',
          phase: 'modules',
          module: 'berufsschule',
          type: 'verbal_choice',
          options: const [
            ('ja_aktiv', 'ja, aktiv', 1.0),
            ('wenn_ich_erzaehle', 'wenn ich erzähle', 0.5),
            ('nein', 'nein', 0.0),
            ('weiss_nicht', 'weiß ich nicht', null),
          ],
        ),
        _choice(
          id: 'm_konflikt_haeufigkeit',
          specRef: 'Modul Konflikte',
          phase: 'modules',
          module: 'konflikte',
          type: 'verbal_choice',
          sensitive: true,
          options: const [
            ('nie', 'nie', null),
            ('einmal', 'einmal', null),
            ('mehrfach', 'mehrfach', null),
          ],
        ),
        {
          'id': 'm_abbruch_ausschlag',
          'specRef': 'Modul Abbruch',
          'type': 'multi_select',
          'phase': 'modules',
          'module': 'abbruch',
          'text': {
            'current': 'Was gab den Ausschlag?',
            'past': 'Was gab den Ausschlag?',
          },
          'config': {'minSelect': 1},
          'options': [
            for (final entry in const [
              ('betrieb', 'Gründe im Betrieb'),
              ('beruf', 'falscher Beruf'),
              ('privat', 'Gründe außerhalb des Betriebs'),
            ])
              {
                'id': entry.$1,
                'label': {'current': entry.$2, 'past': entry.$2},
              },
          ],
        },
        {
          'id': 'm_geld_verguetung',
          'specRef': 'Modul Geld',
          'type': 'number',
          'phase': 'modules',
          'module': 'geld',
          'text': {
            'current': 'Vergütung pro Monat brutto?',
            'past': 'Vergütung pro Monat brutto?',
          },
          'config': {'min': 0, 'max': 3000, 'scoreMin': 0, 'scoreMax': 1500},
        },

        // ── Phase 3 ────────────────────────────────────────────────────────
        {
          'id': 'a1_freitext',
          'specRef': 'A1',
          'type': 'text_pair',
          'phase': 'close',
          'public': true,
          'text': {
            'current': 'Was lief gut, was lief schlecht?',
            'past': 'Was lief gut, was lief schlecht?',
          },
          'config': {
            'maxLength': 4000,
            'fields': [
              {
                'id': 'gut',
                'label': {'current': 'Was lief gut?'},
              },
              {
                'id': 'schlecht',
                'label': {'current': 'Was lief schlecht?'},
              },
            ],
          },
        },
        _choice(
          id: 'a3_tagesform',
          specRef: 'A3',
          phase: 'close',
          type: 'mood',
          options: const [
            ('sehr_gut', 'sehr guter Tag', null),
            ('gut', 'guter Tag', null),
            ('mittel', 'mittel', null),
            ('schlecht', 'schlechter Tag', null),
            ('sehr_schlecht', 'sehr schlechter Tag', null),
          ],
        ),
      ],
      'modules': [
        {
          'id': 'ausbilder',
          'label': {'current': 'Ausbilder', 'past': 'Ausbilder'},
          'teaser': {
            'current': 'Noch zwei Fragen zu deinem Ausbilder?',
            'past': 'Noch zwei Fragen zu deinem Ausbilder?',
          },
          'priorityKey': 'ausbilder',
          'trigger': {
            'in': [
              {'answer': 'k4_erreichbarkeit'},
              ['haelfte', 'selten', 'nie'],
            ],
          },
          'estimatedSeconds': 40,
          'questions': ['m_ausbilder_gespraeche', 'm_ausbilder_erreichbar'],
        },
        {
          'id': 'arbeitszeit',
          'label': {'current': 'Arbeitszeit', 'past': 'Arbeitszeit'},
          'priorityKey': 'arbeitszeit',
          // K12, S8 Schicht oder Wochenende, oder viele Überstunden.
          'trigger': {
            'any': [
              {
                'eq': [
                  {'answer': 's8_alltag', 'field': 'schicht'},
                  'ja',
                ],
              },
              {
                'eq': [
                  {'answer': 's8_alltag', 'field': 'wochenende'},
                  'ja',
                ],
              },
              {
                'gt': [
                  {'answer': 'k3_ueberstunden'},
                  20,
                ],
              },
            ],
          },
          'questions': ['m_arbeitszeit_planbarkeit'],
        },
        {
          'id': 'pruefung',
          'label': {'current': 'Prüfung', 'past': 'Prüfung'},
          'priorityKey': 'pruefung',
          'trigger': {
            'any': [
              {
                'in': [
                  {'answer': 's4_lehrjahr'},
                  ['2', '3', '4'],
                ],
              },
              {
                'in': [
                  {'answer': 's1_status'},
                  ['ausgelernt_geblieben', 'ausgelernt_gegangen'],
                ],
              },
            ],
          },
          'questions': ['m_pruefung_lernzeit'],
        },
        {
          'id': 'uebernahme',
          'label': {'current': 'Übernahme', 'past': 'Übernahme'},
          'priorityKey': 'uebernahme',
          'trigger': {
            'any': [
              {
                'in': [
                  {'answer': 's4_lehrjahr'},
                  ['3', '4'],
                ],
              },
              {
                'in': [
                  {'answer': 's1_status'},
                  ['ausgelernt_geblieben', 'ausgelernt_gegangen'],
                ],
              },
            ],
          },
          'questions': ['m_uebernahme_zeitpunkt'],
        },
        {
          'id': 'geld',
          'label': {'current': 'Geld', 'past': 'Geld'},
          'priorityKey': 'geld',
          // Vollständig gebaut, standardmäßig aus. Abschnitt 11 der
          // Spezifikation lässt die Frage offen, ob Vergütung erhoben wird.
          'featureFlag': 'module_verguetung',
          'questions': ['m_geld_verguetung'],
        },
        {
          'id': 'jugendarbeitsschutz',
          'label': {
            'current': 'Jugendarbeitsschutz',
            'past': 'Jugendarbeitsschutz',
          },
          'trigger': {
            'eq': [
              {'answer': 's9_minderjaehrig'},
              'ja',
            ],
          },
          'questions': ['m_jas_karten'],
        },
        {
          // Weder Prioritätsschlüssel noch Auslöser: immer dabei.
          'id': 'berufsschule',
          'label': {'current': 'Berufsschule', 'past': 'Berufsschule'},
          'questions': ['m_schule_interesse'],
        },
        {
          'id': 'konflikte',
          'label': {
            'current': 'Konflikte und Grenzen',
            'past': 'Konflikte und Grenzen'
          },
          // Wird nie unangekündigt eingeblendet.
          'gated': true,
          'trigger': {
            'in': [
              {'answer': 'k9_umgang'},
              ['von_oben', 'respektlos'],
            ],
          },
          'questions': ['m_konflikt_haeufigkeit'],
        },
        {
          'id': 'abbruch',
          'label': {'current': 'Abbruch', 'past': 'Abbruch'},
          'trigger': {
            'eq': [
              {'answer': 's1_status'},
              'abgebrochen',
            ],
          },
          'questions': ['m_abbruch_ausschlag'],
        },
      ],
      'scoring': {
        'dimensions': [
          'fachlich',
          'betreuung',
          'umgang',
          'belastung',
          'verguetung',
          'perspektive',
        ],
        'separate': ['berufsschule'],
        'overallQuestion': 'k6_gesamt',
        'recommendQuestion': 'k5_empfehlung',
        'subscores': {
          'fachlich': {
            'items': [
              {'question': 'k8_lernwert'},
              {'question': 'k11_planung', 'weight': 0.5},
              {'question': 'm_pruefung_lernzeit', 'weight': 0.5},
            ],
          },
          'betreuung': {
            'items': [
              {'question': 'k4_erreichbarkeit'},
              {'question': 'k7_anleitung'},
              {'question': 'm_ausbilder_gespraeche', 'weight': 0.5},
            ],
          },
          'umgang': {
            'items': [
              {'question': 'k9_umgang'},
            ],
          },
          'belastung': {
            'items': [
              {'question': 'k10_belastung'},
              {'question': 'k3_ueberstunden', 'weight': 0.5},
              {'question': 'm_arbeitszeit_planbarkeit', 'weight': 0.5},
            ],
          },
          'verguetung': {
            'items': [
              {'question': 'm_geld_verguetung'},
            ],
          },
          'perspektive': {
            'items': [
              {'question': 'm_uebernahme_zeitpunkt'},
            ],
          },
          'berufsschule': {
            'items': [
              {'question': 'm_schule_interesse'},
            ],
          },
        },
        'defaultWeights': {
          'fachlich': 0.2,
          'betreuung': 0.2,
          'umgang': 0.2,
          'belastung': 0.15,
          'verguetung': 0.1,
          'perspektive': 0.15,
        },
        'dimensionFlags': {'verguetung': 'module_verguetung'},
        'priorityToDimension': {
          'fachlich': 'fachlich',
          'umgang': 'umgang',
          'geld': 'verguetung',
          'arbeitszeit': 'belastung',
          'ausbilder': 'betreuung',
          'pruefung': 'fachlich',
          'uebernahme': 'perspektive',
          'team': 'umgang',
        },
        'weightFloor': 0.05,
        'priorMean': 3.2,
        'shrinkage': {'strength': 5},
        'aging': {'years': 3, 'weight': 0.5},
      },
      'visibility': {
        'scoreMinReviews': 3,
        'numbersMinReviews': 5,
        'numberBands': {
          'verguetung': [
            {
              'max': 700,
              'label': {'current': 'unter 700 €'},
            },
            {
              'max': 900,
              'label': {'current': '700 bis 900 €'},
            },
            {
              'label': {'current': 'über 900 €'},
            },
          ],
        },
      },
      'quality': {
        'minScreenMillis': 1200,
        'straightlining': {
          'questions': [
            'k7_anleitung',
            'k8_lernwert',
            'k9_umgang',
            'k10_belastung',
            'k11_planung',
          ],
          'maxVariance': 0.01,
        },
        'pairs': [
          {
            'id': 'k4_vs_ausbilder',
            'a': 'k4_erreichbarkeit',
            'b': 'm_ausbilder_erreichbar',
            'maxDelta': 0.5,
          },
        ],
        'overallMismatch': {'maxDelta': 1.0},
        'impossible': [
          {
            'id': 'ueberstunden_belastung',
            'condition': {
              'all': [
                {
                  'eq': [
                    {'answer': 'k3_ueberstunden'},
                    0,
                  ],
                },
                {
                  'eq': [
                    {'answer': 'k10_belastung'},
                    'fast_taeglich',
                  ],
                },
              ],
            },
            'reason': {
              'current':
                  'Null Überstunden bei täglicher Erschöpfung durch Mehrarbeit.',
            },
          },
        ],
        'freeTextQuestions': ['a1_freitext'],
      },
      'featureFlags': {
        'module_verguetung': false,
        'delayed_publish_small_business': true,
      },
      'texts': {
        'anonymity.intro': {'current': 'Was der Betrieb sieht und was nicht.'},
        'help.anlaufstellen': [
          {'current': 'Ausbildungsberatung der Kammer'},
          {'current': 'JAV'},
          {'current': 'Gewerkschaftsberatung'},
        ],
      },
    };

Questionnaire fixtureQuestionnaire({Map<String, bool>? flags}) {
  final json = fixtureJson();
  if (flags != null) {
    json['featureFlags'] = {
      ...(json['featureFlags']! as Map<String, Object?>),
      ...flags,
    };
  }
  return Questionnaire.parse(json);
}

// ── Bausteine ────────────────────────────────────────────────────────────────

/// Die fünf ausformulierten Stufen, die bei mehreren Dimensionsfragen gleich
/// aussehen.
const _fuenf = <(String, String, double?)>[
  ('sehr_gut', 'sehr gut', 1.0),
  ('gut', 'gut', 0.75),
  ('mittel', 'mittel', 0.5),
  ('schlecht', 'schlecht', 0.25),
  ('sehr_schlecht', 'sehr schlecht', 0.0),
];

/// K4 und die Erreichbarkeitsfrage im Ausbildermodul müssen dieselbe Skala
/// haben — sonst ist der Abstand zwischen ihnen keine Aussage.
const _erreichbarkeit = <(String, String, double?)>[
  ('immer', 'eigentlich immer', 1.0),
  ('meistens', 'meistens', 0.75),
  ('haelfte', 'ungefähr die Hälfte der Zeit', 0.5),
  ('selten', 'selten', 0.25),
  ('nie', 'praktisch nie', 0.0),
];

Map<String, Object?> _choice({
  required String id,
  required String specRef,
  required String phase,
  required String type,
  required List<(String, String, double?)> options,
  String? module,
  Map<String, Object?>? condition,
  bool required = false,
  bool sensitive = false,
  bool reversePolarity = false,
}) =>
    {
      'id': id,
      'specRef': specRef,
      'type': type,
      'phase': phase,
      if (module != null) 'module': module,
      'text': {'current': '$specRef?', 'past': '$specRef (damals)?'},
      if (condition != null) 'condition': condition,
      if (required) 'required': true,
      if (sensitive) 'sensitive': true,
      if (reversePolarity) 'reversePolarity': true,
      'options': [
        for (final option in options)
          {
            'id': option.$1,
            'label': {'current': option.$2, 'past': option.$2},
            if (option.$3 != null) 'score': option.$3,
          },
      ],
    };
