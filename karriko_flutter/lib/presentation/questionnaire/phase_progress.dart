import 'package:flutter/material.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

import '../../core/theme/app_theme.dart';

/// Fortschritt **pro Phase**, nicht als Gesamtprozent.
///
/// Die Länge des Bogens hängt an den gewählten Modulen: Wer ein Modul annimmt,
/// bekommt vier Fragen dazu, wer es ablehnt, keine. Ein Gesamtbalken spränge
/// bei jeder dieser Entscheidungen zurück — und ein Balken, der zurückspringt,
/// ist schlimmer als keiner.
class PhaseProgressBar extends StatelessWidget {
  final Questionnaire questionnaire;
  final List<PhaseProgress> fortschritt;
  final String? aktuellePhase;
  final Tense tense;

  const PhaseProgressBar({
    super.key,
    required this.questionnaire,
    required this.fortschritt,
    required this.tense,
    this.aktuellePhase,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final phase in questionnaire.phases)
          Expanded(
            child: _Abschnitt(
              label: phase.label.forTense(tense),
              fortschritt: _fuer(phase.id),
              aktiv: phase.id == aktuellePhase,
              erledigt: _istErledigt(phase.id),
            ),
          ),
      ],
    );
  }

  PhaseProgress _fuer(String phaseId) => fortschritt.firstWhere(
        (eintrag) => eintrag.phaseId == phaseId,
        orElse: () => PhaseProgress(phaseId: phaseId, answered: 0, total: 0),
      );

  /// Eine Phase gilt als erledigt, wenn die aktuelle Frage dahinterliegt —
  /// nicht, wenn alle ihre Fragen beantwortet sind. Freiwillige Fragen darf
  /// man auslassen, ohne dass die Phase für immer offen aussieht.
  bool _istErledigt(String phaseId) {
    if (aktuellePhase == null) return false;
    final phasen = [for (final phase in questionnaire.phases) phase.id];
    return phasen.indexOf(phaseId) < phasen.indexOf(aktuellePhase!);
  }
}

class _Abschnitt extends StatelessWidget {
  final String label;
  final PhaseProgress fortschritt;
  final bool aktiv;
  final bool erledigt;

  const _Abschnitt({
    required this.label,
    required this.fortschritt,
    required this.aktiv,
    required this.erledigt,
  });

  @override
  Widget build(BuildContext context) {
    final anteil = erledigt ? 1.0 : (aktiv ? fortschritt.fraction : 0.0);

    return Padding(
      padding: const EdgeInsets.only(right: AppLayout.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            color: AppColors.line,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: anteil,
              child: Container(
                color: aktiv ? AppColors.accent : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: aktiv ? FontWeight.w800 : FontWeight.w400,
              color: aktiv ? AppColors.ink : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
