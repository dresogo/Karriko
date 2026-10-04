import 'dart:convert';
import 'dart:io';

import 'package:karriko_functions/karriko_functions.dart';
import 'package:questionnaire_core/questionnaire_core.dart';
import 'package:test/test.dart';

/// Geprüft wird gegen die **echte** v1, nicht gegen einen Testfragebogen.
///
/// Was hier zur Debatte steht, ist die Abbildung zwischen Definition und
/// Datenbankzeile: welche Angabe in welche Spalte geht, was in `public_reviews`
/// landet und was nicht. Gegen eine Attrappe geprüft würde genau die Frage
/// nicht beantwortet, um die es geht.
final _v1 = Questionnaire.parseJsonString(
  File('../../karriko_flutter/assets/questionnaire/questionnaire_v1.json')
      .readAsStringSync(),
);

FunctionConfig _config([Map<String, String> extra = const {}]) =>
    FunctionConfig.fromEnvironment({
      'APPWRITE_FUNCTION_PROJECT_ID': 'projekt',
      'KARRIKO_DATABASE_ID': 'datenbank',
      ...extra,
    });

/// Eine vollständige, gültige Einreichung für Persona 4 — ausgelernt und
/// gegangen, alle Module übersprungen.
Answers _antworten({Map<String, Object?> extra = const {}}) => Answers.from({
      'intro_anonymitaet': true,
      's1_status': 'ausgelernt_gegangen',
      's2_startjahr': 2020,
      's2_1_endjahr': 2023,
      's3_beruf': 'Fachinformatiker/in für Anwendungsentwicklung',
      's5_betriebsgroesse': '50_249',
      's6_azubizahl': '6_20',
      's7_ausbildungsform': 'dual',
      's8_arbeitsalltag': {
        'schichtarbeit': 'nein',
        'wochenenddienste': 'nein',
        'montage': 'nein',
        'kundenkontakt': 'nein',
        'fahrerei': 'nein',
        'koerperlich_schwer': 'nein',
        'bildschirm': 'ja',
      },
      's9_minderjaehrig': 'nein',
      's10_berufsschule_form': 'block',
      'k1_fakten': {
        'k1_1_ausbildungsplan': 'ja',
        'k1_2_ansprechpartner': 'ja',
        'k1_3_berichtsheft': 'ja',
        'k1_4_berufsschule': 'ja',
        'k1_5_ausruestung': 'ja',
        'k1_6_gespraeche': 'nein',
      },
      'k2_ausbildungsfremd': 'gar_nichts',
      'k3_ueberstunden': 0,
      'k4_erreichbarkeit': 'meistens',
      'k5_empfehlung': 7,
      'k6_gesamt': 70,
      'k7_anleitung': 'in_eile',
      'k8_lernwert': 'das_meiste',
      'k9_umgang': 'freundlich',
      'k10_belastung': 'selten',
      'k11_planung': 'ungefaehr',
      'k12_prioritaeten': ['fachlich', 'umgang', 'team'],
      'fachliche_qualitaet__teaser': 'nein',
      'pruefung__teaser': 'nein',
      'uebernahme__teaser': 'nein',
      'berufsschule__teaser': 'nein',
      'a1_freitexte': {
        'a1_gut': 'Die Kollegen.',
        'a1_schlecht': 'Ich hatte das Gefühl, kaum etwas Neues zu lernen.',
      },
      'a3_tagesform': 'gut',
      'a4_vorschau': true,
      ...extra,
    });

void main() {
  group('Konfiguration', () {
    test('eine fehlende Pflichtvariable nennt sich selbst', () {
      // Ein Standardwert für die Datenbank-ID würde gegen eine erfundene
      // Datenbank laufen und eine Fehlermeldung erzeugen, die auf alles andere
      // hindeutet.
      expect(
        () => FunctionConfig.fromEnvironment(const {
          'APPWRITE_FUNCTION_PROJECT_ID': 'projekt',
        }),
        throwsA(
          isA<MissingConfigException>().having(
            (e) => e.name,
            'name',
            'KARRIKO_DATABASE_ID',
          ),
        ),
      );
    });

    test('Tabellennamen haben sprechende Voreinstellungen', () {
      final config = _config();
      expect(config.reviewsTable, 'reviews');
      expect(config.publicReviewsTable, 'public_reviews');
      expect(config.moderatorsTeam, 'moderators');
    });

    test('Fristen lassen sich über die Umgebung setzen', () {
      final config = _config(const {
        'KARRIKO_DRAFT_RETENTION_DAYS': '30',
        'KARRIKO_VERIFICATION_RETENTION_DAYS': '7',
      });
      expect(config.draftRetentionDays, 30);
      expect(config.verificationRetentionDays, 7);
    });

    test('ein unlesbarer Zahlenwert fällt auf die Voreinstellung zurück', () {
      // Eine Function, die wegen eines Tippfehlers in einer Frist gar nicht
      // startet, räumt nichts weg — und das ist schlechter als 90 Tage.
      expect(
        _config(const {'KARRIKO_DRAFT_RETENTION_DAYS': 'neunzig'})
            .draftRetentionDays,
        90,
      );
    });

    test('ohne Salz gibt es kein Salz, keinen Ersatzwert', () {
      expect(_config().deviceHashSalt, isNull);
      expect(_config(const {'KARRIKO_DEVICE_HASH_SALT': '  '}).deviceHashSalt,
          isNull);
    });
  });

  group('Gerätekennung', () {
    test('ohne Salz wird nicht gehasht', () {
      // Ein eingebautes Ersatzsalz stünde im öffentlichen Repository, und dann
      // ließe sich zu jedem Hash die Kennung zurückrechnen.
      expect(hashDeviceKey('abc', null), isNull);
      expect(hashDeviceKey('abc', ''), isNull);
    });

    test('ohne Kennung auch nicht', () {
      expect(hashDeviceKey(null, 'salz'), isNull);
      expect(hashDeviceKey('   ', 'salz'), isNull);
    });

    test('gleiche Eingabe, gleicher Hash', () {
      expect(hashDeviceKey('abc', 'salz'), hashDeviceKey('abc', 'salz'));
    });

    test('anderes Salz, anderer Hash', () {
      expect(
        hashDeviceKey('abc', 'salz'),
        isNot(hashDeviceKey('abc', 'pfeffer')),
      );
    });

    test('der Hash gibt die Kennung nicht her', () {
      final hash = hashDeviceKey('abc', 'salz')!;
      expect(hash, hasLength(64));
      expect(hash, isNot(contains('abc')));
    });
  });

  group('Veröffentlichung', () {
    final jetzt = DateTime.utc(2026, 9, 28, 12);

    PublishDecision entscheide(Map<String, Object?> extra) => decidePublishing(
          questionnaire: _v1,
          answers: _antworten(extra: extra),
          config: _config(),
          now: jetzt,
        );

    test('ohne Wunsch geht es sofort in die Moderation', () {
      final entscheidung = entscheide(const {});
      expect(entscheidung.status, ReviewStatus.pendingModeration);
      expect(entscheidung.publishAfter, isNull);
      expect(entscheidung.isScheduled, isFalse);
    });

    test('„in drei Tagen nochmal draufschauen" verschiebt um drei Tage', () {
      final entscheidung = entscheide(const {
        'a3_tagesform': 'sehr_schlecht',
        'a3_1_verschieben': 'in_drei_tagen',
      });
      expect(entscheidung.status, ReviewStatus.scheduled);
      expect(entscheidung.publishAfter, DateTime.utc(2026, 10, 1, 12));
      expect(entscheidung.untilTrainingEnd, isFalse);
    });

    test('„jetzt abschicken" verschiebt nichts', () {
      // Beide Wege bleiben offen — niemand wird gesperrt.
      final entscheidung = entscheide(const {
        'a3_tagesform': 'sehr_schlecht',
        'a3_1_verschieben': 'jetzt',
      });
      expect(entscheidung.status, ReviewStatus.pendingModeration);
    });

    test('„erst nach Ausbildungsende" wartet auf das Endjahr', () {
      final entscheidung = entscheide(const {
        's6_azubizahl': 'nur_ich',
        's2_1_endjahr': 2027,
        'a3_2_kleinbetrieb': 'nach_ausbildungsende',
      });
      expect(entscheidung.status, ReviewStatus.scheduled);
      expect(entscheidung.publishAfter, DateTime.utc(2027, 12, 31));
      expect(entscheidung.untilTrainingEnd, isTrue);
    });

    test('ein Endjahr in der Vergangenheit verschiebt nicht', () {
      // Die Ausbildung ist vorbei; es gibt nichts abzuwarten.
      final entscheidung = entscheide(const {
        's6_azubizahl': 'nur_ich',
        's2_1_endjahr': 2023,
        'a3_2_kleinbetrieb': 'nach_ausbildungsende',
      });
      expect(entscheidung.publishAfter, jetzt);
    });

    test('kommen zwei Gründe zusammen, gilt der spätere', () {
      // Sonst höbe der kürzere den längeren auf — und der längere ist der
      // schützende.
      final entscheidung = entscheide(const {
        's6_azubizahl': 'nur_ich',
        's2_1_endjahr': 2027,
        'a3_tagesform': 'sehr_schlecht',
        'a3_1_verschieben': 'in_drei_tagen',
        'a3_2_kleinbetrieb': 'nach_ausbildungsende',
      });
      expect(entscheidung.publishAfter, DateTime.utc(2027, 12, 31));
    });

    test('„trotzdem sofort" im Kleinbetrieb verschiebt nicht', () {
      final entscheidung = entscheide(const {
        's6_azubizahl': 'nur_ich',
        'a3_2_kleinbetrieb': 'sofort',
      });
      expect(entscheidung.status, ReviewStatus.pendingModeration);
    });
  });

  group('Die Zeile in reviews', () {
    Map<String, Object?> zeile({Map<String, Object?> extra = const {}}) {
      final answers = _antworten(extra: extra);
      final scores = ReviewScores.compute(_v1, answers);
      return buildReviewRow(
        questionnaire: _v1,
        answers: answers,
        scores: scores,
        flags: evaluateQuality(
          questionnaire: _v1,
          answers: answers,
          scores: scores,
        ),
        companyId: 'betrieb1',
        userId: 'nutzer1',
        status: ReviewStatus.pendingModeration,
        timings: const {'k6_gesamt': 4200},
        inviteSource: 'probezeit',
        deviceHash: hashDeviceKey('geraet', 'salz'),
      );
    }

    test(
        'trägt alles, wonach gefiltert oder aggregiert wird, als eigene Spalte',
        () {
      final row = zeile();
      expect(row['company_id'], 'betrieb1');
      expect(row['user_id'], 'nutzer1');
      expect(row['schema_version'], _v1.version);
      expect(row['respondent_status'], 'ausgelernt_gegangen');
      expect(row['start_year'], 2020);
      expect(row['end_year'], 2023);
      expect(row['k5_recommend'], 7);
      expect(row['k6_overall'], 70);
      expect(row['invited'], isTrue);
      expect(row['invite_source'], 'probezeit');
    });

    test('die sechs Subscores stehen in ihren Spalten', () {
      final row = zeile();
      expect(row['sub_fachlich'], isA<double>());
      expect(row['sub_betreuung'], isA<double>());
      expect(row['sub_umgang'], isA<double>());
      expect(row['sub_belastung'], isA<double>());
      // Ohne Module gibt es keine Perspektive — und null ist hier die richtige
      // Aussage, nicht 0.
      expect(row['sub_perspektive'], isNull);
      // Das Vergütungsmodul ist abgeschaltet.
      expect(row['sub_verguetung'], isNull);
    });

    test('die Rohantworten liegen daneben', () {
      // Ohne sie ließe sich eine Bewertung nach einer Parameteränderung nicht
      // neu rechnen — und genau das macht recompute_all.
      final row = zeile();
      final roh = jsonDecode(row['answers_json']! as String) as Map;
      expect(roh['k6_gesamt'], 70);
      final zeiten = jsonDecode(row['timings_json']! as String) as Map;
      expect(zeiten['k6_gesamt'], 4200);
    });

    test('die beiden Freitexte stehen getrennt', () {
      final row = zeile();
      expect(row['freitext_gut'], 'Die Kollegen.');
      expect(row['freitext_schlecht'], contains('kaum etwas Neues'));
    });

    test('ein Freitext setzt ein Flag, aber keinen Löschgrund', () {
      final row = zeile();
      expect(row['quality_flags'], contains(QualityFlag.textNeedsReview));
      expect(row['status'], ReviewStatus.pendingModeration);
    });

    test('der Korrekturregler aus A2 überschreibt K6', () {
      // Genau das ist sein Zweck: Wer sein Urteil neu setzt, meint den neuen
      // Wert.
      final row = zeile(extra: const {
        'a2_abgleich': 'neu',
        'a2_1_korrektur': 35,
      });
      expect(row['k6_overall'], 35);
    });

    test('die Gerätekennung steht nur als Hash da', () {
      final row = zeile();
      expect(row['device_hash'], hasLength(64));
      expect(row.values.join(' '), isNot(contains('geraet')));
    });
  });

  group('Die Zeile in public_reviews', () {
    Map<String, Object?> oeffentlich({bool alt = false}) {
      final answers = _antworten();
      final scores = ReviewScores.compute(_v1, answers);
      final review = buildReviewRow(
        questionnaire: _v1,
        answers: answers,
        scores: scores,
        flags: evaluateQuality(
          questionnaire: _v1,
          answers: answers,
          scores: scores,
        ),
        companyId: 'betrieb1',
        userId: 'nutzer1',
        status: ReviewStatus.approved,
        timings: const {'k6_gesamt': 4200},
        deviceHash: hashDeviceKey('geraet', 'salz'),
      );
      return buildPublicReviewRow(
        reviewId: 'r1',
        reviewRow: review,
        isAged: alt,
        companyName: 'Muster GmbH',
        companySlug: 'muster-gmbh',
      );
    }

    test('zeigt, was öffentlich gehört', () {
      final row = oeffentlich();
      expect(row['review_id'], 'r1');
      expect(row['company_id'], 'betrieb1');
      expect(row['beruf_name'], contains('Fachinformatiker'));
      expect(row['start_year'], 2020);
      expect(row['k6_overall'], 70);
      expect(row['sub_umgang'], isA<double>());
      expect(row['freitext_gut'], 'Die Kollegen.');
    });

    test('und trägt nichts davon', () {
      // Der eigentliche Punkt der Trennung. Appwrite vergibt Rechte pro Zeile,
      // nicht pro Spalte — was hier stünde, dürfte jeder lesen.
      final row = oeffentlich();
      for (final verboten in [
        'user_id',
        'answers_json',
        'timings_json',
        'quality_flags',
        'quality_notes',
        'device_hash',
        'invite_source',
        'invited',
      ]) {
        expect(row.containsKey(verboten), isFalse, reason: verboten);
      }
    });

    test('verlinkt den Betrieb', () {
      // Ohne Name und Slug zeigte die Einzelansicht keinen Verweis auf den
      // Betrieb — der Knopf dorthin haengt an `company_slug`.
      final row = oeffentlich();
      expect(row['company_name'], 'Muster GmbH');
      expect(row['company_slug'], 'muster-gmbh');
    });

    test('kennzeichnet alte Bewertungen', () {
      expect(oeffentlich(alt: true)['is_aged'], isTrue);
      expect(oeffentlich()['is_aged'], isFalse);
    });
  });

  group('Aggregate', () {
    AggregateInput? aus(Map<String, Object?> row) =>
        aggregateInputFromRow(row, priorities: const ['umgang', 'fachlich']);

    test('liest die Subscores aus den Spalten', () {
      final eingabe = aus({
        'sub_umgang': 4.0,
        'sub_fachlich': 3.5,
        'sub_berufsschule': 2.0,
        'k5_recommend': 8,
        'published_at': '2026-09-01T10:00:00.000Z',
      })!;
      expect(eingabe.subscores['umgang'], 4.0);
      expect(eingabe.subscores['fachlich'], 3.5);
      expect(eingabe.separate['berufsschule'], 2.0);
      expect(eingabe.recommend, 8);
      expect(eingabe.priorities, ['umgang', 'fachlich']);
    });

    test('ohne Zeitpunkt gibt es keine Eingabe', () {
      // Ohne Datum liesse sich die Alterung nicht rechnen, und eine Bewertung
      // ohne Alter wuerde als brandneu gewichtet.
      expect(aus({'sub_umgang': 4.0}), isNull);
      expect(aus({'sub_umgang': 4.0, 'published_at': 'gestern'}), isNull);
    });

    test('unter der Schwelle steht kein Score in der Zeile', () {
      final aggregat = CompanyAggregate.compute(
        questionnaire: _v1,
        reviews: [
          AggregateInput(
            subscores: const {'umgang': 4.0},
            publishedAt: DateTime.utc(2026, 9, 1),
          ),
        ],
        now: DateTime.utc(2026, 9, 28),
      );
      final row = buildCompanyScoresRow(
        aggregat,
        questionnaire: _v1,
        zahlenangaben: const {},
      );
      expect(row['score_visible'], isFalse);
      expect(row['overall'], isNull);
      expect(row['sub_umgang'], isNull);
      // Die Zahl der Bewertungen steht trotzdem da: Sie verrät nichts und
      // erklärt, warum kein Score zu sehen ist.
      expect(row['review_count'], 1);
    });

    test('ab drei Bewertungen steht er da', () {
      final aggregat = CompanyAggregate.compute(
        questionnaire: _v1,
        reviews: [
          for (var i = 0; i < 3; i++)
            AggregateInput(
              subscores: const {'umgang': 4.0},
              priorities: const ['umgang'],
              publishedAt: DateTime.utc(2026, 9, 1),
            ),
        ],
        now: DateTime.utc(2026, 9, 28),
      );
      final row = buildCompanyScoresRow(
        aggregat,
        questionnaire: _v1,
        zahlenangaben: const {},
      );
      expect(row['score_visible'], isTrue);
      expect(row['overall'], isA<double>());
      expect(row['sub_umgang'], isA<double>());
    });

    test('Zahlenangaben erscheinen erst ab fünf und nur als Spanne', () {
      List<AggregateInput> bewertungen(int n) => [
            for (var i = 0; i < n; i++)
              AggregateInput(
                subscores: const {'umgang': 4.0},
                publishedAt: DateTime.utc(2026, 9, 1),
              ),
          ];

      Map<String, Object?> zeile(int n) => buildCompanyScoresRow(
            CompanyAggregate.compute(
              questionnaire: _v1,
              reviews: bewertungen(n),
              now: DateTime.utc(2026, 9, 28),
            ),
            questionnaire: _v1,
            zahlenangaben: const {'verguetung': 847},
          );

      expect(jsonDecode(zeile(4)['bands_json']! as String), isEmpty);

      final spannen =
          jsonDecode(zeile(5)['bands_json']! as String) as Map<String, Object?>;
      // Der genaue Mittelwert steht nirgends: Aus „847 €" und der Zahl der
      // Bewertungen liessen sich einzelne Angaben zurueckrechnen.
      expect(spannen['verguetung'], '700 bis 900 €');
      expect(zeile(5).toString(), isNot(contains('847')));
    });
  });

  group('Antworten', () {
    test('ok trägt ok: true', () {
      final antwort = FunctionResponse.ok({'review_id': 'r1'});
      expect(antwort.status, 200);
      expect(antwort.isOk, isTrue);
      expect(antwort.payload['review_id'], 'r1');
    });

    test('jeder Fehler trägt einen maschinenlesbaren Code', () {
      for (final antwort in [
        FunctionResponse.invalid('x'),
        FunctionResponse.duplicate('x'),
        FunctionResponse.unauthorized('x'),
        FunctionResponse.forbidden('x'),
        FunctionResponse.unavailable('x'),
      ]) {
        expect(antwort.isOk, isFalse);
        expect(antwort.payload['code'], isA<String>());
        expect(antwort.payload['message'], 'x');
        expect(antwort.status, greaterThanOrEqualTo(400));
      }
    });
  });

  group('Die eigene Liste aus my_reviews', () {
    Map<String, Object?> eintrag({
      String status = ReviewStatus.pendingModeration,
      String? grund,
      String? oeffentlicheId,
    }) {
      final answers = _antworten();
      final scores = ReviewScores.compute(_v1, answers);
      final review = buildReviewRow(
        questionnaire: _v1,
        answers: answers,
        scores: scores,
        flags: evaluateQuality(
          questionnaire: _v1,
          answers: answers,
          scores: scores,
        ),
        companyId: 'betrieb1',
        userId: 'nutzer1',
        status: status,
        timings: const {'k6_gesamt': 4200},
        deviceHash: hashDeviceKey('geraet', 'salz'),
      );
      return buildOwnReviewEntry(
        reviewId: 'r1',
        reviewRow: review,
        submittedAt: '2026-09-01T10:00:00.000Z',
        companyName: 'Muster GmbH',
        companySlug: 'muster-gmbh',
        publicReviewId: oeffentlicheId,
        publishedAt: oeffentlicheId == null ? null : '2026-09-05T08:00:00.000Z',
        rejectionReason: grund,
      );
    }

    test('zeigt dem Verfasser seine eigenen Angaben', () {
      final e = eintrag();
      expect(e['review_id'], 'r1');
      expect(e['company_name'], 'Muster GmbH');
      expect(e['company_slug'], 'muster-gmbh');
      expect(e['status'], ReviewStatus.pendingModeration);
      expect(e['submitted_at'], '2026-09-01T10:00:00.000Z');
      expect(e['beruf_name'], contains('Fachinformatiker'));
      expect(e['start_year'], 2020);
      expect(e['freitext_gut'], 'Die Kollegen.');
    });

    test('und nichts, was der Moderation gehört', () {
      // Der eigentliche Punkt dieser Function. Jeder Eintrag in
      // `withheldFromAuthor` traegt einen Grund — hier wird er durchgesetzt.
      final e = eintrag();
      for (final verboten in withheldFromAuthor.keys) {
        expect(
          e.containsKey(verboten),
          isFalse,
          reason: '$verboten: ${withheldFromAuthor[verboten]}',
        );
      }
    });

    test('die Qualitätsmarkierungen kommen nirgends durch', () {
      // Gegen die naheliegende Luecke: Ein Flag koennte auch im Text eines
      // anderen Feldes landen. Wer erfaehrt, dass er markiert wurde, weiss
      // beim naechsten Mal, wie er es vermeidet.
      final e = eintrag();
      final alles = e.values.map((v) => '$v').join(' ');
      for (final code in [
        'too_fast',
        'straightlining',
        'inconsistent_pair',
        'overall_detail_mismatch',
        'impossible_combination',
        'text_needs_review',
      ]) {
        expect(alles, isNot(contains(code)), reason: code);
      }
    });

    test('verlinkt die öffentliche Zeile erst, wenn es eine gibt', () {
      expect(eintrag().containsKey('public_review_id'), isFalse);
      expect(eintrag().containsKey('published_at'), isFalse);

      final frei = eintrag(status: ReviewStatus.approved, oeffentlicheId: 'p1');
      expect(frei['public_review_id'], 'p1');
      expect(frei['published_at'], '2026-09-05T08:00:00.000Z');
    });

    test('eine Ablehnung kommt mit Begründung an', () {
      // `moderate_review` weist eine Ablehnung ohne Begruendung zurueck, und
      // zwar genau deshalb: Sie waere fuer den Verfasser nicht nachvollziehbar.
      // Hier kommt sie bei ihm an — ohne den Namen des Moderators.
      final e = eintrag(
        status: ReviewStatus.rejected,
        grund: 'Der Freitext nennt einen Kollegen beim Namen.',
      );
      expect(e['status'], ReviewStatus.rejected);
      expect(e['rejection_reason'], contains('Kollegen beim Namen'));
      expect(e.containsKey('moderator_id'), isFalse);
    });

    test('eine leere Begründung ist keine', () {
      expect(
        eintrag(status: ReviewStatus.rejected, grund: '   ')
            .containsKey('rejection_reason'),
        isFalse,
      );
    });

    test('jede zurückgehaltene Spalte hat einen Grund', () {
      // Damit niemand eine Zeile ohne Begruendung ergaenzt und damit auch nicht
      // begruenden muss, warum sie fehlt.
      //
      // Ein Querverweis gilt: „Wie detail_overall." ist eine Begruendung,
      // solange der Eintrag, auf den er zeigt, eine traegt. Deshalb wird
      // aufgeloest statt an der Laenge gemessen.
      expect(withheldFromAuthor, isNotEmpty);

      String aufgeloest(String key, [int tiefe = 0]) {
        final wert = withheldFromAuthor[key]!.trim();
        if (tiefe > 3) return wert;
        for (final anderer in withheldFromAuthor.keys) {
          if (anderer != key && wert.startsWith('Wie $anderer')) {
            return aufgeloest(anderer, tiefe + 1);
          }
        }
        return wert;
      }

      for (final key in withheldFromAuthor.keys) {
        final grund = aufgeloest(key);
        expect(grund, isNotEmpty, reason: key);
        expect(
          grund.length,
          greaterThan(40),
          reason: '$key: „$grund" erklärt nicht, warum die Spalte fehlt.',
        );
      }
    });
  });

  group('JSON-Spalten', () {
    test('ein kaputter Wert hält keinen Stapellauf an', () {
      expect(decodeJsonColumn('{'), isEmpty);
      expect(decodeJsonColumn(null), isEmpty);
      expect(decodeJsonColumn('[]'), isEmpty);
      expect(decodeJsonColumn('{"a":1}'), {'a': 1});
    });
  });
}
