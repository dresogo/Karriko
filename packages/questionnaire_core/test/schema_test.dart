import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:test/test.dart';

/// Prüft die **Form** der Definition.
///
/// Das Schema und [Questionnaire.parse] machen zwei verschiedene Dinge, und
/// beide werden gebraucht:
///
/// * Das Schema kennt die erlaubten Felder. Es fängt einen Tippfehler im
///   Schlüsselnamen — `"conditon"` statt `"condition"` — den der Parser
///   stillschweigend als „keine Bedingung" durchwinken würde.
/// * Der Parser kennt den Zusammenhang. Dass ein Antwortverweis auf eine Frage
///   zeigt, die es gibt, kann ein JSON-Schema nicht wissen.
void main() {
  final schemaDatei = File('schema/questionnaire.schema.json');
  final v1Datei =
      File('../../karriko_flutter/assets/questionnaire/questionnaire_v1.json');

  late JsonSchema schema;

  setUpAll(() {
    schema = JsonSchema.create(
      jsonDecode(schemaDatei.readAsStringSync()) as Object,
      schemaVersion: SchemaVersion.draft2020_12,
    );
  });

  test('v1 entspricht dem Schema', () {
    final ergebnis = schema.validate(jsonDecode(v1Datei.readAsStringSync()));
    expect(
      ergebnis.isValid,
      isTrue,
      reason: ergebnis.errors
          .map((e) => '${e.instancePath}: ${e.message}')
          .join('\n'),
    );
  });

  group('Das Schema fängt, was der Parser durchließe', () {
    Map<String, Object?> v1Mit(
        void Function(Map<String, Object?> json) change) {
      final json =
          jsonDecode(v1Datei.readAsStringSync()) as Map<String, Object?>;
      change(json);
      return json;
    }

    List<Object?> fragen(Map<String, Object?> json) =>
        json['questions']! as List<Object?>;

    Map<String, Object?> frage(Map<String, Object?> json, String id) =>
        fragen(json).cast<Map<String, Object?>>().firstWhere(
              (q) => q['id'] == id,
            );

    test('Ein verschriebener Feldname', () {
      // Der Parser läse hier schlicht keine Bedingung und zeigte die Frage
      // immer. Genau der Fall, für den es das Schema gibt.
      final json = v1Mit((json) {
        final q = frage(json, 'k3_1_ausgleich');
        q['conditon'] = q.remove('condition');
      });
      expect(schema.validate(json).isValid, isFalse);
    });

    test('Ein Punktwert über 1,0', () {
      final json = v1Mit((json) {
        (frage(json, 'k9_umgang')['options']! as List<Object?>)
            .cast<Map<String, Object?>>()[0]['score'] = 5;
      });
      expect(schema.validate(json).isValid, isFalse);
    });

    test('Eine Kennung in Großbuchstaben', () {
      final json =
          v1Mit((json) => frage(json, 'k9_umgang')['id'] = 'K9_Umgang');
      expect(schema.validate(json).isValid, isFalse);
    });

    test('Ein Text ohne "current"', () {
      final json = v1Mit(
          (json) => frage(json, 'k9_umgang')['text'] = {'past': 'nur damals'});
      expect(schema.validate(json).isValid, isFalse);
    });

    test('Zwei Operatoren in einer Bedingung', () {
      final json = v1Mit((json) {
        frage(json, 'k3_1_ausgleich')['condition'] = {
          'gt': [
            {'answer': 'k3_ueberstunden'},
            0,
          ],
          'lt': [
            {'answer': 'k3_ueberstunden'},
            100,
          ],
        };
      });
      expect(schema.validate(json).isValid, isFalse);
    });

    test('Ein unbekannter Schlüssel an einem Operanden', () {
      final json = v1Mit((json) {
        frage(json, 'k3_1_ausgleich')['condition'] = {
          'gt': [
            {'answer': 'k3_ueberstunden', 'feld': 'x'},
            0,
          ],
        };
      });
      expect(schema.validate(json).isValid, isFalse);
    });

    test('Eine fehlende Pflichtangabe', () {
      final json = v1Mit((json) => json.remove('scoring'));
      expect(schema.validate(json).isValid, isFalse);
    });

    test('Ein Modul ohne Fragen', () {
      final json = v1Mit((json) {
        (json['modules']! as List<Object?>).cast<Map<String, Object?>>()[0]
            ['questions'] = <Object?>[];
      });
      expect(schema.validate(json).isValid, isFalse);
    });
  });
}
