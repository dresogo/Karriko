/// Welche Version der Fragendefinition gerade aktiv ist und wo sie liegt.
///
/// Die Definition selbst steht nicht in der Datenbank, sondern als Datei im
/// Storage. Hier steht nur der Verweis — so laesst sich eine neue Version
/// ausrollen, ohne die App neu zu bauen, und alte Versionen bleiben abrufbar.
/// Eine begonnene Bewertung bleibt bei ihrer Version, auch wenn inzwischen
/// eine neue aktiv ist.
class QuestionnaireRelease {
  final String id;
  final String locale;
  final int version;
  final String bucketId;
  final String fileId;
  final String? checksum;
  final bool active;
  final DateTime publishedAt;

  const QuestionnaireRelease({
    required this.id,
    required this.locale,
    required this.version,
    required this.bucketId,
    required this.fileId,
    required this.active,
    required this.publishedAt,
    this.checksum,
  });

  factory QuestionnaireRelease.fromJson(Map<String, dynamic> json) {
    return QuestionnaireRelease(
      id: json['id'] as String,
      locale: json['locale'] as String,
      version: (json['version'] as num).toInt(),
      bucketId: json['bucket_id'] as String,
      fileId: json['file_id'] as String,
      checksum: json['checksum'] as String?,
      active: json['active'] as bool? ?? false,
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }

  @override
  String toString() => 'QuestionnaireRelease($locale v$version)';
}
