/// Der gemeinsame Teil der Appwrite Functions von Karriko.
///
/// Was hier steht, ist Appwrite-Kleber und Abbildung zwischen Zeilen und
/// Modellen. Die Fragebogenlogik steht in `questionnaire_core` und wird von
/// Client und Function gleichermassen benutzt — dass beide Seiten dasselbe
/// rechnen, ist deshalb keine Absprache, sondern dasselbe Paket.
///
/// Die Teile, die etwas entscheiden, sind reine Funktionen ohne Netzzugriff:
/// [buildReviewRow], [buildPublicReviewRow], [buildCompanyScoresRow],
/// [aggregateInputFromRow] und [hashDeviceKey]. Nur so laesst sich pruefen,
/// was gespeichert wuerde, ohne es zu speichern.
library;

export 'src/aggregate_writer.dart';
export 'src/config.dart';
export 'src/context.dart';
export 'src/definition_loader.dart';
export 'src/device_hash.dart';
export 'src/moderation_desk.dart';
export 'src/my_reviews.dart';
export 'src/publish_decision.dart';
export 'src/responses.dart';
export 'src/review_row.dart';
export 'src/tables.dart';
export 'src/teams.dart';
