import 'package:questionnaire_core/questionnaire_core.dart';

import 'config.dart';
import 'review_row.dart';

/// Wann eine Bewertung in die Moderation geht.
class PublishDecision {
  final String status;

  /// Ab wann sie in die Moderation darf. `null` heißt: sofort.
  final DateTime? publishAfter;

  /// Der Azubi hat „erst nach Ende meiner Ausbildung" gewählt.
  final bool untilTrainingEnd;

  const PublishDecision({
    required this.status,
    this.publishAfter,
    this.untilTrainingEnd = false,
  });

  bool get isScheduled => status == ReviewStatus.scheduled;
}

/// Liest aus den Antworten, ob und wie lange zurückgestellt wird.
///
/// Welche Antwort welche Wirkung hat, steht **in der Definition**: Eine Frage
/// mit `config.publishActions` ordnet ihren Optionen eine Aktion zu, `delay`
/// oder `until_training_end`. Damit kennt diese Funktion keine einzige Frage-ID
/// — und eine neue Verschiebemöglichkeit ist eine Änderung an der Definition.
///
/// **Beide Wege bleiben offen.** Niemand wird gesperrt: Wer trotz schlechtem Tag
/// jetzt abschicken will, schickt jetzt ab. Was hier passiert, ist das
/// Einlösen einer Wahl, die der Azubi getroffen hat.
PublishDecision decidePublishing({
  required Questionnaire questionnaire,
  required Answers answers,
  required FunctionConfig config,
  required DateTime now,
}) {
  DateTime? spaetestens;
  var bisAusbildungsende = false;

  for (final question in questionnaire.questions) {
    final aktionen = question.config['publishActions'];
    if (aktionen is! Map) continue;

    final antwort = answers[question.id];
    if (antwort == null) continue;

    final aktion = aktionen[antwort];
    if (aktion is! String) continue;

    switch (aktion) {
      case 'delay':
        final tage =
            (question.config['delayDays'] as num?)?.round() ?? config.delayDays;
        spaetestens = _spaeteste(spaetestens, now.add(Duration(days: tage)));

      case 'until_training_end':
        bisAusbildungsende = true;
        spaetestens = _spaeteste(
          spaetestens,
          _ausbildungsende(questionnaire, answers, now, config),
        );
    }
  }

  if (spaetestens == null) {
    return const PublishDecision(status: ReviewStatus.pendingModeration);
  }

  return PublishDecision(
    status: ReviewStatus.scheduled,
    publishAfter: spaetestens,
    untilTrainingEnd: bisAusbildungsende,
  );
}

/// Wenn zwei Gründe zum Verschieben zusammenkommen, gilt der spätere.
///
/// Sonst hebt der kürzere den längeren auf — und der längere ist immer der
/// schützende: Er stammt aus dem Kleinbetriebsfall, wo der Chef sonst erkennen
/// kann, wer geschrieben hat.
DateTime _spaeteste(DateTime? a, DateTime b) =>
    a == null || b.isAfter(a) ? b : a;

/// Wann die Ausbildung endet.
///
/// Aus dem Endjahr, wenn es bekannt ist — der 31. Dezember, weil der Monat
/// nicht erhoben wird und eine genauere Annahme erfunden wäre. Wer noch in der
/// Ausbildung ist, hat kein Endjahr; dann greift die Frist aus der
/// Konfiguration.
DateTime _ausbildungsende(
  Questionnaire questionnaire,
  Answers answers,
  DateTime now,
  FunctionConfig config,
) {
  final felder = publicFields(questionnaire, answers);
  final endjahr = felder['end_year'];

  if (endjahr is num) {
    final ende = DateTime.utc(endjahr.round(), 12, 31);
    if (ende.isAfter(now)) return ende;
    // Liegt das Endjahr in der Vergangenheit, ist die Ausbildung vorbei und
    // es gibt nichts zu verschieben.
    return now;
  }

  return DateTime.utc(now.year, now.month + config.smallBusinessDelayMonths,
      now.day, now.hour, now.minute);
}
