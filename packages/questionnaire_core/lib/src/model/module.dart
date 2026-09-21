import '../condition/condition.dart';
import 'json_reader.dart';
import 'question.dart';

/// Ein Vertiefungsmodul aus Phase 2.
///
/// Ein Modul wird angeboten, wenn es entweder über K12 gewählt wurde
/// ([priorityKey] steht unter den ersten drei) oder seine [trigger]-Bedingung
/// greift. Angeboten heißt nicht gestellt: Davor steht immer der Teaser mit
/// Fragenzahl und geschätzter Dauer, und jedes Modul ist einzeln abwählbar.
class Module {
  final String id;
  final TextVariants label;

  /// Der Text des Teasers („Noch vier Fragen zu deinem Ausbilder?").
  final TextVariants? teaser;

  /// Automatischer Auslöser laut Tabelle in Abschnitt 5 der Spezifikation.
  final Condition? trigger;

  /// Option der Prioritätenfrage K12, die dieses Modul anbietet.
  final String? priorityKey;

  final List<String> questionIds;

  /// Feste Schätzung in Sekunden. Fehlt sie, wird über die Fragenzahl
  /// geschätzt.
  final int? estimatedSeconds;

  /// Merkmalsschalter, an dem das Modul hängt. Steht er auf `false`, wird das
  /// Modul nie angeboten — so ist `module_verguetung` vollständig gebaut und
  /// trotzdem aus.
  final String? featureFlag;

  /// Die Fragen dieses Moduls stehen hinter einem Tor: Das Modul erscheint erst
  /// nach ausdrücklicher Zustimmung, nicht schon durch den Teaser. Trifft auf
  /// „Konflikte und Grenzen" zu.
  final bool gated;

  const Module({
    required this.id,
    required this.label,
    this.teaser,
    this.trigger,
    this.priorityKey,
    this.questionIds = const [],
    this.estimatedSeconds,
    this.featureFlag,
    this.gated = false,
  });

  /// Die ID der Teaserfrage.
  ///
  /// Die Teaserfrage steht nicht in der Definition, sie wird aus dem Modul
  /// gebaut. Sonst müsste jedes Modul zweimal gepflegt werden — einmal als
  /// Modul, einmal als Frage — und die beiden könnten auseinanderlaufen.
  String get teaserQuestionId => '${id}__teaser';

  /// Die Antwort auf die Teaserfrage, die das Modul öffnet.
  static const acceptValue = 'ja';

  /// Die Antwort, die es überspringt.
  static const skipValue = 'nein';

  /// Die synthetische Teaserfrage.
  Question teaserQuestion(String phase) => Question(
        id: teaserQuestionId,
        specRef: 'Modul $id',
        type: 'module_teaser',
        phase: phase,
        module: id,
        text: teaser ?? label,
        config: {'moduleId': id, 'gated': gated},
      );

  static Module parse(JsonNode node) => Module(
        id: node.require('id').asString,
        label: TextVariants.parse(node.require('label')),
        teaser: TextVariants.parseOrNull(node.child('teaser')),
        trigger: Condition.parseOrNull(node.child('trigger')),
        priorityKey: node.child('priorityKey').exists
            ? node.child('priorityKey').asString
            : null,
        questionIds: node.child('questions').exists
            ? node.child('questions').asStringList
            : const [],
        estimatedSeconds: node.child('estimatedSeconds').exists
            ? node.child('estimatedSeconds').asInt
            : null,
        featureFlag: node.child('featureFlag').exists
            ? node.child('featureFlag').asString
            : null,
        gated: node.child('gated').boolOr(false),
      );
}
