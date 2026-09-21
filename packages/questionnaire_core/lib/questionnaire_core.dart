/// Die Fragebogenlogik von Karriko.
///
/// Drei Schichten, und dies ist die mittlere:
///
/// * **Inhalt** liegt als versionierte JSON-Definition vor. Fragetexte,
///   Optionen, Reihenfolge, Bedingungen, Gewichte, Schwellenwerte — alles.
///   In diesem Paket steht kein einziger Fragetext.
/// * **Darstellung** ist in Flutter hartcodiert. Die Definition verweist über
///   eine Typkennung auf ein Widget; welche Kennungen es gibt, weiß dieses
///   Paket nicht und muss es nicht wissen.
/// * **Logik**, die Client und Server gleichermaßen brauchen, steht hier:
///   Bedingungen auswerten, Ablauf steuern, prüfen, rechnen, markieren.
///
/// Reines Dart, ohne Flutter und ohne Laufzeitabhängigkeiten. Derselbe Code
/// läuft im Browser und in der Appwrite Function. Dass Client und Server zum
/// selben Ergebnis kommen, ist deshalb keine Absprache zwischen zwei
/// Umsetzungen, sondern dieselbe.
library;

export 'src/condition/condition.dart'
    show
        AllCondition,
        AnsweredCondition,
        AnswerOperand,
        AnyCondition,
        BinaryCondition,
        ComputedOperand,
        Condition,
        EvalContext,
        LiteralOperand,
        NotCondition,
        Operand,
        RankedTopCondition,
        deepEquals;
export 'src/flow/answers.dart';
export 'src/flow/flow.dart';
export 'src/model/config.dart';
export 'src/model/json_reader.dart';
export 'src/model/module.dart';
export 'src/model/question.dart';
export 'src/model/questionnaire.dart';
export 'src/quality/quality.dart';
export 'src/scoring/company_aggregate.dart';
export 'src/scoring/normalize.dart';
export 'src/scoring/review_scores.dart';
export 'src/validation/validation.dart';
