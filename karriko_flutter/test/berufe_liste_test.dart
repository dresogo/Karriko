import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/presentation/questionnaire/question_context.dart';
import 'package:karriko_flutter/presentation/questionnaire/widgets/input_widgets.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

/// Die Berufsliste für S3 aus dem DKZ-Verzeichnis der BA (T-2.30).
///
/// Erzeugt mit `tools/berufe_aus_ba.dart`; hier steht, was sie erfüllen muss,
/// damit `SearchSelect` damit arbeiten kann.
void main() {
  final daten = jsonDecode(
    File('assets/data/berufe.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final berufe = (daten['berufe']! as List).cast<Map<String, Object?>>();

  test('jeder Eintrag hat Code, Name und Bereich', () {
    for (final b in berufe) {
      expect(b['code'], isA<String>().having((s) => s, 'code', isNotEmpty));
      expect(b['name'], isA<String>().having((s) => s, 'name', isNotEmpty));
      expect(b['bereich'], isA<String>());
    }
  });

  test('Codes und Namen sind eindeutig', () {
    expect(berufe.map((b) => b['code']).toSet().length, berufe.length);
    expect(berufe.map((b) => b['name']).toSet().length, berufe.length);
  });

  test('amtliche Kennziffern mit zehn Stellen, außer dem Auffangeintrag', () {
    for (final b in berufe.take(berufe.length - 1)) {
      expect(b['code'], matches(RegExp(r'^\d{10}$')), reason: '${b['name']}');
    }
  });

  test('der Auffangeintrag steht zuletzt', () {
    // Ohne ihn bliebe hängen, wessen Beruf die Liste nicht kennt.
    expect(berufe.last['code'], 'sonstiger');
  });

  test('gängige Ausbildungsberufe sind da', () {
    final namen = berufe.map((b) => b['name']).toSet();
    for (final name in [
      'Mechatroniker/in',
      'Industriekaufmann/-frau',
      'Kaufmann/-frau - Büromanagement',
      'Fachinformatiker/in - Anwendungsentwicklung',
      'Medizinische/r Fachangestellte/r',
      'Pflegefachmann/-frau (Ausbildung)',
    ]) {
      expect(namen, contains(name));
    }
  });

  testWidgets('S3 findet Berufe aus der neuen Liste und übernimmt den Namen',
      (tester) async {
    final bogen = Questionnaire.parse(
      jsonDecode(
        File('assets/questionnaire/questionnaire_v1.json').readAsStringSync(),
      ) as Map<String, Object?>,
    );
    final frage = bogen.question('s3_beruf')!;
    expect(frage.config['asset'], 'assets/data/berufe.json');

    Object? antwort;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SearchSelect(
            context: QuestionContext(
              question: frage,
              answer: antwort,
              tense: Tense.current,
              questionnaire: bogen,
              onChanged: (neu) => setState(() => antwort = neu),
              onAdvance: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 200),
        ));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Mechatr');
    await tester.pump();
    expect(find.text('Mechatroniker/in'), findsOneWidget);

    await tester.tap(find.text('Mechatroniker/in'));
    await tester.pump();
    expect(antwort, 'Mechatroniker/in');
  });
}
