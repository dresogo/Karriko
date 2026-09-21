import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/presentation/questionnaire/question_context.dart';
import 'package:karriko_flutter/presentation/questionnaire/widget_registry.dart';
import 'package:karriko_flutter/presentation/questionnaire/widgets/rank_top_n.dart';
import 'package:karriko_flutter/presentation/questionnaire/widgets/swipe_binary.dart';
import 'package:karriko_flutter/presentation/questionnaire/widgets/vas_unnumbered.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

/// Ein Fragebogen mit genau einer Frage.
///
/// Die Widgets brauchen den ganzen Fragebogen nur für die Texte aus `texts` —
/// die Beschriftungen der Schaltflächen stehen dort und nicht im Dart-Code.
Questionnaire _bogen(Map<String, Object?> frage) => Questionnaire.parse({
      'id': 'test',
      'version': 1,
      'locale': 'de-DE',
      'phases': [
        {
          'id': 'kern',
          'label': {'current': 'Kern'},
        },
        {
          'id': 'module',
          'label': {'current': 'Module'},
          'holdsModules': true,
        },
      ],
      'flow': {
        'tenseQuestion': frage['id'],
        'pastValues': <String>[],
        'priorityQuestion': frage['id'],
      },
      'questions': [frage],
      'scoring': {
        'dimensions': <String>[],
        'subscores': {
          'x': {
            'items': [
              {'question': frage['id']},
            ],
          },
        },
        'defaultWeights': <String, Object?>{},
      },
      'texts': {
        'ui.yes': {'current': 'Ja'},
        'ui.no': {'current': 'Nein'},
        'ui.unknown': {'current': 'Weiß ich nicht'},
        'ui.undo': {'current': 'Zurücknehmen'},
        'ui.rank_hint': {'current': 'Zieh die drei wichtigsten nach oben.'},
        'ui.rank_reset': {'current': 'Auswahl zurücksetzen'},
        'ui.not_answered': {'current': 'noch nicht beantwortet'},
        'ui.draft_saved': {'current': 'Alles beantwortet'},
      },
    });

/// Baut das Widget und gibt den zuletzt gemeldeten Wert heraus.
class _Buehne {
  Object? wert;
  var weiter = 0;
}

Future<_Buehne> _zeigen(
  WidgetTester tester,
  Map<String, Object?> frageJson,
  Widget Function(QuestionContext) bauen, {
  Object? start,
}) async {
  final bogen = _bogen(frageJson);
  final frage = bogen.question(frageJson['id']! as String)!;
  final buehne = _Buehne()..wert = start;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => bauen(
            QuestionContext(
              question: frage,
              answer: buehne.wert,
              tense: Tense.current,
              questionnaire: bogen,
              onChanged: (neu) => setState(() => buehne.wert = neu),
              onAdvance: () => buehne.weiter++,
            ),
          ),
        ),
      ),
    ),
  );
  return buehne;
}

void main() {
  group('vas_unnumbered — der Regler ohne Zahl', () {
    final frage = <String, Object?>{
      'id': 'k6_gesamt',
      'type': 'vas_unnumbered',
      'phase': 'kern',
      'text': {'current': 'Wie gut insgesamt?'},
      'config': {
        'min': 0,
        'max': 100,
        'endLabels': {
          'min': {'current': 'schlecht'},
          'max': {'current': 'sehr gut'},
        },
      },
    };

    testWidgets('zeigt keinen Griff, solange niemand ihn angefasst hat',
        (tester) async {
      await _zeigen(tester, frage, (ctx) => VasUnnumbered(context: ctx));
      expect(find.byKey(griffKey), findsNothing);
    });

    testWidgets('zeigt nie eine Zahl', (tester) async {
      final buehne =
          await _zeigen(tester, frage, (ctx) => VasUnnumbered(context: ctx));

      // Auf die Bahn tippen, nicht irgendwohin: Die Spalte fuellt die Hoehe
      // des Bildschirms, ihr Mittelpunkt liegt im Leeren.
      await tester.tapAt(tester.getCenter(find.byType(GestureDetector)));
      await tester.pump();

      expect(buehne.wert, isNotNull);
      // Die Beschriftung an den Enden steht da, sonst kein Text — und schon
      // gar keine Prozentzahl, an der die Antwort einrasten könnte.
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(
          RegExp(r'\d').hasMatch(text.data ?? ''),
          isFalse,
          reason: 'Sichtbarer Text mit Ziffer: "${text.data}"',
        );
      }
    });

    testWidgets('beschriftet nur die beiden Enden', (tester) async {
      await _zeigen(tester, frage, (ctx) => VasUnnumbered(context: ctx));
      expect(find.text('schlecht'), findsOneWidget);
      expect(find.text('sehr gut'), findsOneWidget);
    });

    testWidgets('ein Klick setzt einen Wert und lässt den Griff erscheinen',
        (tester) async {
      final buehne =
          await _zeigen(tester, frage, (ctx) => VasUnnumbered(context: ctx));

      await tester.tapAt(tester.getCenter(find.byType(GestureDetector)));
      await tester.pump();

      expect(buehne.wert, isA<int>());
      expect(find.byKey(griffKey), findsOneWidget);
    });

    testWidgets('null ist ein Wert und nicht „unbeantwortet"', (tester) async {
      // Wer den Regler ganz nach links zieht, hat geantwortet. Der Griff muss
      // dastehen — sonst sähe die Antwort aus wie gar keine.
      await _zeigen(
        tester,
        frage,
        (ctx) => VasUnnumbered(context: ctx),
        start: 0,
      );
      expect(find.byKey(griffKey), findsOneWidget);
    });

    testWidgets('lässt sich mit der Tastatur bedienen', (tester) async {
      final buehne =
          await _zeigen(tester, frage, (ctx) => VasUnnumbered(context: ctx));

      // Erst den Fokus holen, dann die Pfeiltaste.
      await tester.tapAt(tester.getCenter(find.byType(GestureDetector)));
      await tester.pump();
      final vorher = buehne.wert! as int;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(buehne.wert, greaterThan(vorher));
    });
  });

  group('swipe_binary — Wischkarten', () {
    final frage = <String, Object?>{
      'id': 'k1_fakten',
      'type': 'swipe_binary',
      'phase': 'kern',
      'text': {'current': 'Trifft das zu?'},
      'config': {
        'yesValue': 'ja',
        'noValue': 'nein',
        'otherValues': ['weiss_nicht'],
        'cards': [
          {
            'id': 'plan',
            'label': {'current': 'Es gibt einen Ausbildungsplan.'},
          },
          {
            'id': 'person',
            'label': {'current': 'Es gibt eine feste Person.'},
          },
        ],
      },
    };

    testWidgets('bietet immer alle drei Antworten als Schaltfläche an',
        (tester) async {
      // Ohne diese drei ist die Frage mit Maus, Tastatur oder Screenreader
      // nicht zu beantworten — eine Wischgeste allein schließt Nutzer aus.
      await _zeigen(tester, frage, (ctx) => SwipeBinary(context: ctx));
      expect(find.widgetWithText(OutlinedButton, 'Ja'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Nein'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Weiß ich nicht'),
        findsOneWidget,
      );
    });

    testWidgets('beantwortet die erste Karte und legt die zweite vor',
        (tester) async {
      final buehne =
          await _zeigen(tester, frage, (ctx) => SwipeBinary(context: ctx));

      expect(find.text('Es gibt einen Ausbildungsplan.'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Ja'));
      await tester.pumpAndSettle();

      expect(buehne.wert, {'plan': 'ja'});
      expect(find.text('Es gibt eine feste Person.'), findsOneWidget);
    });

    testWidgets('zählt mit, wie viele Karten schon beantwortet sind',
        (tester) async {
      await _zeigen(tester, frage, (ctx) => SwipeBinary(context: ctx));
      expect(find.text('0 / 2'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Nein'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('nimmt die letzte Karte zurück', (tester) async {
      final buehne =
          await _zeigen(tester, frage, (ctx) => SwipeBinary(context: ctx));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Ja'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Zurücknehmen'));
      await tester.pumpAndSettle();

      expect(buehne.wert, isNull);
      expect(find.text('Es gibt einen Ausbildungsplan.'), findsOneWidget);
    });
  });

  group('rank_top_n — die Prioritäten', () {
    final frage = <String, Object?>{
      'id': 'k12_prioritaeten',
      'type': 'rank_top_n',
      'phase': 'kern',
      'text': {'current': 'Was zählt am meisten?'},
      'config': {'topN': 3},
      'options': [
        for (final eintrag in const [
          ('fachlich', 'Was ich fachlich lerne'),
          ('umgang', 'Wie mit mir umgegangen wird'),
          ('geld', 'Geld und Sachleistungen'),
          ('team', 'Stimmung im Team'),
        ])
          {
            'id': eintrag.$1,
            'label': {'current': eintrag.$2},
          },
      ],
    };

    testWidgets('lässt sich ohne Ziehen bedienen', (tester) async {
      // Drag and Drop ist mit Tastatur und Screenreader nicht zu bedienen, und
      // K12 steuert die Gewichte des Gesamtscores — wer hier aussteigt, fällt
      // aus der Bewertung.
      final buehne =
          await _zeigen(tester, frage, (ctx) => RankTopN(context: ctx));

      await tester.tap(find.text('Wie mit mir umgegangen wird'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Geld und Sachleistungen'));
      await tester.pumpAndSettle();

      expect(buehne.wert, ['umgang', 'geld']);
    });

    testWidgets('zeigt die Reihenfolge als Platznummern', (tester) async {
      await _zeigen(
        tester,
        frage,
        (ctx) => RankTopN(context: ctx),
        start: const ['umgang', 'geld'],
      );
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('bietet nach drei Rängen keine weitere Option mehr an',
        (tester) async {
      await _zeigen(
        tester,
        frage,
        (ctx) => RankTopN(context: ctx),
        start: const ['umgang', 'geld', 'team'],
      );
      // Die vierte Karte steht nicht mehr zur Wahl — die Liste ist voll.
      expect(find.text('Was ich fachlich lerne'), findsNothing);
    });

    testWidgets('nimmt einen Rang durch erneutes Antippen zurück',
        (tester) async {
      final buehne = await _zeigen(
        tester,
        frage,
        (ctx) => RankTopN(context: ctx),
        start: const ['umgang'],
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(buehne.wert, isNull);
    });

    testWidgets('setzt die ganze Auswahl zurück', (tester) async {
      final buehne = await _zeigen(
        tester,
        frage,
        (ctx) => RankTopN(context: ctx),
        start: const ['umgang', 'geld'],
      );

      await tester.tap(find.text('Auswahl zurücksetzen'));
      await tester.pumpAndSettle();

      expect(buehne.wert, isNull);
    });
  });

  group('Die Registry', () {
    testWidgets('meldet einen unbekannten Typ in der Entwicklung sichtbar',
        (tester) async {
      // Still überspringen fällt beim Durchklicken nicht auf — und dann geht
      // eine Frage verloren, ohne dass es jemand merkt.
      await _zeigen(
        tester,
        {
          'id': 'x',
          'type': 'gibt_es_nicht',
          'phase': 'kern',
          'text': {'current': 'x'},
        },
        (ctx) =>
            QuestionWidgetRegistry.buildOrNull(ctx) ?? const SizedBox.shrink(),
      );
      expect(find.textContaining('gibt_es_nicht'), findsOneWidget);
    });

    test('kennt jeden Typ, den sie kennen soll', () {
      expect(QuestionWidgetRegistry.kennt('vas_unnumbered'), isTrue);
      expect(QuestionWidgetRegistry.kennt('rank_top_n'), isTrue);
      expect(QuestionWidgetRegistry.kennt('gibt_es_nicht'), isFalse);
    });
  });
}
