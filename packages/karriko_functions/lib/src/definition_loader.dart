import 'dart:convert';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:questionnaire_core/questionnaire_core.dart';

import 'config.dart';

/// Lädt eine Fragendefinition serverseitig.
///
/// **Immer genau die Version, mit der die Einreichung erstellt wurde.** Es gibt
/// hier keinen Rückfall auf die aktive Version und keinen auf ein mitgeliefertes
/// Asset: Eine Einreichung gegen eine andere Fassung zu prüfen, als der Azubi
/// gesehen hat, würde entweder gültige Antworten ablehnen oder ungültige
/// durchlassen. Fehlt die Version, bricht die Prüfung ab — und das ist richtig.
class DefinitionLoader {
  final Client client;
  final FunctionConfig config;

  /// Innerhalb einer Ausführung wird jede Version höchstens einmal geladen.
  ///
  /// `recompute_all` geht über tausende Bewertungen, die fast alle dieselbe
  /// Version tragen. Ohne diesen Zwischenspeicher wären das tausend Downloads.
  final Map<String, Questionnaire> _cache = {};

  DefinitionLoader({required this.client, required this.config});

  TablesDB get _db => TablesDB(client);
  Storage get _storage => Storage(client);

  Future<Questionnaire> load(
    int version, {
    String locale = 'de-DE',
  }) async {
    final key = '$locale.v$version';
    final bekannt = _cache[key];
    if (bekannt != null) return bekannt;

    final release = await _db.listRows(
      databaseId: config.databaseId,
      tableId: config.releasesTable,
      queries: [
        Query.equal('locale', locale),
        Query.equal('version', version),
        Query.limit(1),
      ],
    );

    if (release.rows.isEmpty) {
      throw DefinitionNotFoundException(locale, version);
    }

    final zeile = release.rows.first.data;
    final bucketId =
        zeile['bucket_id'] as String? ?? config.questionnairesBucket;
    final fileId = zeile['file_id'] as String?;
    if (fileId == null) {
      throw DefinitionNotFoundException(locale, version);
    }

    final bytes = await _storage.getFileDownload(
      bucketId: bucketId,
      fileId: fileId,
    );

    final questionnaire = Questionnaire.parseJsonString(utf8.decode(bytes));
    if (questionnaire.version != version) {
      throw DefinitionMismatchException(version, questionnaire.version);
    }

    _cache[key] = questionnaire;
    return questionnaire;
  }

  /// Die aktive Version. Wird nur gebraucht, wo keine Einreichung eine Version
  /// vorgibt — etwa in `aggregate_company`, das die Parameter der Berechnung
  /// braucht.
  Future<Questionnaire> loadActive({String locale = 'de-DE'}) async {
    final release = await _db.listRows(
      databaseId: config.databaseId,
      tableId: config.releasesTable,
      queries: [
        Query.equal('locale', locale),
        Query.equal('active', true),
        Query.orderDesc('version'),
        Query.limit(1),
      ],
    );
    if (release.rows.isEmpty) {
      throw DefinitionNotFoundException(locale, -1);
    }
    final version = (release.rows.first.data['version'] as num).toInt();
    return load(version, locale: locale);
  }
}

class DefinitionNotFoundException implements Exception {
  final String locale;
  final int version;

  const DefinitionNotFoundException(this.locale, this.version);

  @override
  String toString() => version < 0
      ? 'Fuer $locale ist keine Version als aktiv markiert.'
      : 'Version $version des Fragebogens ($locale) ist nicht abrufbar. '
          'Alte Versionen duerfen nie geloescht werden — siehe '
          'notes/APPWRITE_SETUP.md.';
}

/// Die Datei im Storage gehört zu einer anderen Version als das Release.
///
/// Das ist ein Einrichtungsfehler und kein Datenfehler: Jemand hat eine Datei
/// unter der Kennung einer anderen Version hochgeladen. Still weiterzurechnen
/// hieße, gegen die falsche Fassung zu prüfen.
class DefinitionMismatchException implements Exception {
  final int erwartet;
  final int gefunden;

  const DefinitionMismatchException(this.erwartet, this.gefunden);

  @override
  String toString() =>
      'Das Release verweist auf Version $erwartet, die Datei enthaelt aber '
      'Version $gefunden.';
}
