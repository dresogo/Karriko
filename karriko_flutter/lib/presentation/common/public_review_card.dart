import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/public_review.dart';

/// Eine Bewertung, so wie sie öffentlich aussieht.
///
/// **Dasselbe Widget an beiden Stellen**: in der Vorschau vor dem Absenden und
/// in der öffentlichen Ansicht danach. Zwei getrennte Darstellungen würden
/// unweigerlich auseinanderlaufen, und dann verspräche die Vorschau etwas, das
/// die Veröffentlichung nicht hält. Da auf Karriko Einzelbewertungen anklickbar
/// sind, ist genau das das Vertrauensproblem, das die Plattform lösen will.
class PublicReviewCard extends StatelessWidget {
  final PublicReview review;

  /// In der Vorschau steht kein Datum und kein Verweis auf den Betrieb — die
  /// Bewertung ist noch nicht veröffentlicht und gehört zu dem Betrieb, den
  /// man gerade bewertet.
  final bool vorschau;

  final bool zeigeBetrieb;
  final VoidCallback? onTap;

  const PublicReviewCard({
    super.key,
    required this.review,
    this.vorschau = false,
    this.zeigeBetrieb = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final karte = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppLayout.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Kopf(review: review, vorschau: vorschau, zeigeBetrieb: zeigeBetrieb),
          if (review.overallScore != null) ...[
            const SizedBox(height: AppLayout.s16),
            ScoreBalken(
              label: 'Gesamt',
              wert: review.overallScore!,
              betont: true,
            ),
          ],
          if (review.subscores.isNotEmpty) ...[
            const SizedBox(height: AppLayout.s16),
            for (final eintrag in review.subscores.entries)
              ScoreBalken(
                label: dimensionLabel(eintrag.key),
                wert: eintrag.value,
              ),
          ],
          if (review.berufsschule != null) ...[
            const SizedBox(height: AppLayout.s8),
            ScoreBalken(
              label: dimensionLabel('berufsschule'),
              wert: review.berufsschule!,
              getrennt: true,
            ),
          ],
          if (review.hasFreitext) ...[
            const SizedBox(height: AppLayout.s24),
            if (review.freitextGut?.trim().isNotEmpty ?? false)
              _Freitext(titel: 'Was lief gut', text: review.freitextGut!),
            if (review.freitextSchlecht?.trim().isNotEmpty ?? false)
              _Freitext(
                titel: 'Was lief schlecht',
                text: review.freitextSchlecht!,
              ),
          ],
          if (review.recommend != null) ...[
            const SizedBox(height: AppLayout.s16),
            Text(
              'Weiterempfehlung: ${review.recommend} von 10',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return karte;
    return InkWell(onTap: onTap, child: karte);
  }

  /// Die Anzeigenamen der Dimensionen.
  ///
  /// Das sind keine Fragetexte, sondern Beschriftungen der Auswertung — sie
  /// stehen in keiner Frage und gehören deshalb nicht in die Definition.
  static String dimensionLabel(String dimension) => switch (dimension) {
        'fachlich' => 'Fachliche Qualität',
        'betreuung' => 'Betreuung',
        'umgang' => 'Umgang',
        'belastung' => 'Arbeitszeit und Belastung',
        'verguetung' => 'Vergütung und Leistungen',
        'perspektive' => 'Perspektive',
        'berufsschule' => 'Berufsschule',
        _ => dimension,
      };
}

class _Kopf extends StatelessWidget {
  final PublicReview review;
  final bool vorschau;
  final bool zeigeBetrieb;

  const _Kopf({
    required this.review,
    required this.vorschau,
    required this.zeigeBetrieb,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppLayout.s8,
      runSpacing: AppLayout.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (zeigeBetrieb && review.companyName != null)
          Text(
            review.companyName!,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        if (review.berufName != null) _Merkmal(review.berufName!),
        if (review.zeitraum.isNotEmpty) _Merkmal(review.zeitraum),
        if (review.verified) const _Verifiziert(),
        if (review.isAged) const _Alt(),
        if (!vorschau) ...[
          const Spacer(),
          Text(
            DateFormat('MM.yyyy').format(review.publishedAt),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _Merkmal extends StatelessWidget {
  final String text;

  const _Merkmal(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.muted),
      ),
    );
  }
}

class _Verifiziert extends StatelessWidget {
  const _Verifiziert();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: const BoxDecoration(color: AppColors.audienceBeige),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 13, color: AppColors.green),
          SizedBox(width: 4),
          Text(
            'Ausbildung nachgewiesen',
            style: TextStyle(fontSize: 13, color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

/// Bewertungen älter als die Alterungsgrenze bekommen eine sichtbare
/// Kennzeichnung.
///
/// Ausbildungsqualität hängt oft an einzelnen Personen und ändert sich mit
/// deren Wechsel. Eine vier Jahre alte Bewertung ist nicht falsch, aber sie
/// beschreibt womöglich einen anderen Betrieb als den heutigen.
class _Alt extends StatelessWidget {
  const _Alt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(border: Border.all(color: AppColors.muted)),
      child: const Text(
        'älter als drei Jahre',
        style: TextStyle(fontSize: 13, color: AppColors.muted),
      ),
    );
  }
}

class _Freitext extends StatelessWidget {
  final String titel;
  final String text;

  const _Freitext({required this.titel, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titel.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.96,
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(height: 1.55)),
        ],
      ),
    );
  }
}

/// Ein Subscore als Balken.
///
/// Keine Sterne: Fünf Sterne suggerieren eine Genauigkeit, die ein
/// geschrumpfter Mittelwert aus drei Bewertungen nicht hat.
class ScoreBalken extends StatelessWidget {
  final String label;
  final double wert;
  final bool betont;

  /// Wird getrennt ausgewiesen und fließt nicht in den Betriebsscore ein.
  final bool getrennt;

  const ScoreBalken({
    super.key,
    required this.label,
    required this.wert,
    this.betont = false,
    this.getrennt = false,
  });

  @override
  Widget build(BuildContext context) {
    final anteil = ((wert - 1) / 4).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.s8),
      child: Row(
        children: [
          SizedBox(
            width: 168,
            child: Text(
              label,
              style: TextStyle(
                fontSize: betont ? 16 : 14,
                fontWeight: betont ? FontWeight.w700 : FontWeight.w400,
                color: getrennt ? AppColors.muted : AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: betont ? 10 : 6,
              color: AppColors.line,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: anteil,
                child: Container(
                  color: getrennt ? AppColors.muted : AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppLayout.s16),
          SizedBox(
            width: 36,
            child: Text(
              wert.toStringAsFixed(1).replaceAll('.', ','),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: betont ? 16 : 14,
                fontWeight: betont ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
