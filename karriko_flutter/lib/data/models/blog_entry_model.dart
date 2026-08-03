import '../../core/utils/date_format.dart';

/// Art eines Eintrags im Blog- und Neuigkeiten-Stream.
enum BlogEntryKind {
  /// Redaktioneller Artikel mit eigener Detailseite.
  article,

  /// Produkt-Update bzw. neue Funktion. Steht für sich, ohne Detailseite.
  update,
}

/// Art der Produktänderung. Wird zusätzlich zur Farbe immer mit Icon und Text
/// ausgewiesen, damit die Bedeutung nicht allein über Farbe transportiert wird.
enum UpdateKind {
  neu('Neu'),
  verbessert('Verbessert'),
  behoben('Behoben');

  const UpdateKind(this.label);

  final String label;
}

/// Ein Eintrag im gemeinsamen Stream aus Artikeln und Produkt-Updates.
class BlogEntry {
  final BlogEntryKind kind;
  final String title;
  final String teaser;
  final DateTime date;

  /// Rubrik des Artikels, z. B. „Tipps & Tricks“. Nur bei [BlogEntryKind.article].
  final String? category;

  /// Lesezeit in Minuten. Nur bei [BlogEntryKind.article].
  final int? readingMinutes;

  /// Slug der Detailseite. Nur bei [BlogEntryKind.article].
  final String? slug;

  /// Versionsbezeichnung, z. B. „v1.4“. Nur bei [BlogEntryKind.update].
  final String? version;

  /// Art der Änderung. Nur bei [BlogEntryKind.update].
  final UpdateKind? updateKind;

  const BlogEntry.article({
    required this.title,
    required this.teaser,
    required this.date,
    required String this.category,
    required int this.readingMinutes,
    required String this.slug,
  })  : kind = BlogEntryKind.article,
        version = null,
        updateKind = null;

  const BlogEntry.update({
    required this.title,
    required this.teaser,
    required this.date,
    required String this.version,
    required UpdateKind this.updateKind,
  })  : kind = BlogEntryKind.update,
        category = null,
        readingMinutes = null,
        slug = null;

  bool get isArticle => kind == BlogEntryKind.article;

  String get formattedDate => germanDate(date);
}
