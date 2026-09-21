import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'question_context.dart';
import 'widgets/choice_widgets.dart';
import 'widgets/input_widgets.dart';
import 'widgets/rank_top_n.dart';
import 'widgets/scale_widgets.dart';
import 'widgets/swipe_binary.dart';
import 'widgets/vas_unnumbered.dart';

typedef QuestionWidgetBuilder = Widget Function(QuestionContext context);

/// Jede Typkennung aus der Definition hat genau ein Widget.
///
/// Das ist die einzige Stelle, an der Inhalt und Darstellung aufeinandertreffen.
/// Die Definition kennt nur eine Zeichenkette; welches Widget dahintersteht,
/// entscheidet sich hier — und nur hier.
///
/// Vier Typen fehlen in dieser Tabelle, weil sie mehr brauchen als die Frage
/// selbst: [module_teaser] braucht die Zahlen aus der Ablaufsteuerung,
/// [preview] die Projektion des Antwortstands, [verification] den Upload und
/// [intro]/[anonymity_notice] nichts davon, aber sie werden vom Bildschirm
/// zusammen mit den Hinweistexten gebaut. Der Bildschirm reicht sie über
/// [override] herein, statt hier Abhängigkeiten aufzuziehen, die 17 andere
/// Widgets nicht brauchen.
class QuestionWidgetRegistry {
  QuestionWidgetRegistry._();

  static final Map<String, QuestionWidgetBuilder> _builders = {
    // Regler ohne Zahl — genau zwei im ganzen Bogen.
    'vas_unnumbered': (ctx) => VasUnnumbered(context: ctx),

    // Wischkarten, nur für Fakten.
    'swipe_binary': (ctx) => SwipeBinary(context: ctx),

    // Elf Kacheln, nur für die Weiterempfehlung.
    'scale_0_10': (ctx) => Scale0To10(context: ctx),

    // Ausformulierte Antworten in der Reihenfolge der Definition.
    'verbal_choice': (ctx) => VerbalChoice(context: ctx),
    'single_choice_tiles': (ctx) => VerbalChoice(context: ctx, alsKacheln: true),
    'segmented': (ctx) => SegmentedChoice(context: ctx),
    'multi_select': (ctx) => MultiSelect(context: ctx),
    'mood': (ctx) => MoodChoice(context: ctx),
    'consistency_check': (ctx) => ConsistencyCheck(context: ctx),
    'publish_options': (ctx) => PublishOptions(context: ctx),
    'gate': (ctx) => GateChoice(context: ctx),

    // Zahlen, die der Azubi wirklich weiß.
    'stepper': (ctx) => StepperInput(context: ctx),

    // Ordnen, wo Ordnen inhaltlich Sinn ergibt.
    'rank_top_n': (ctx) => RankTopN(context: ctx),

    // Eingaben.
    'text_pair': (ctx) => TextPair(context: ctx),
    'dropdown': (ctx) => YearDropdown(context: ctx),
    'search_select': (ctx) => SearchSelect(context: ctx),
  };

  /// Alle Kennungen, die diese Tabelle kennt. Ohne die vier, die der
  /// Bildschirm selbst baut.
  static Iterable<String> get bekannteTypen => _builders.keys;

  /// Das Widget zu einer Frage.
  ///
  /// `null` heißt: unbekannter Typ. Was dann passiert, entscheidet der
  /// Bildschirm — und zwar unterschiedlich je nach Bauart:
  ///
  /// * **In der Entwicklung** ein sichtbarer Fehlerkasten. Ein still
  ///   übersprungener Bildschirm fällt beim Durchklicken nicht auf, und dann
  ///   geht eine Frage verloren, ohne dass es jemand merkt.
  /// * **Im Release** überspringen und protokollieren. Eine neue Definition mit
  ///   einem Typ, den diese App-Fassung noch nicht kennt, darf einen Azubi
  ///   nicht vor eine kaputte Seite setzen.
  static Widget? buildOrNull(QuestionContext context) {
    final builder = _builders[context.question.type];
    if (builder != null) return builder(context);

    if (kDebugMode) return _UnbekannterTyp(typ: context.question.type, id: context.question.id);

    debugPrint(
      'Fragebogen: unbekannte Typkennung "${context.question.type}" '
      'bei "${context.question.id}" — Bildschirm übersprungen.',
    );
    return null;
  }

  static bool kennt(String typ) => _builders.containsKey(typ);
}

class _UnbekannterTyp extends StatelessWidget {
  final String typ;
  final String id;

  const _UnbekannterTyp({required this.typ, required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.accentDark),
              const SizedBox(width: AppLayout.s8),
              Text(
                'Unbekannte Typkennung',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppLayout.s8),
          SelectableText(
            'Die Frage "$id" verlangt ein Widget für "$typ". In der Registry '
            'gibt es keins.\n\n'
            'Entweder fehlt der Eintrag in QuestionWidgetRegistry, oder die '
            'Definition benutzt eine Kennung, die diese App-Fassung noch nicht '
            'kennt. Im Release wird der Bildschirm übersprungen und '
            'protokolliert.',
            style: const TextStyle(height: 1.55),
          ),
        ],
      ),
    );
  }
}
