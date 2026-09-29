import 'dart:convert';

import 'package:crypto/crypto.dart';
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

    // Die Pruefsumme, wenn eine hinterlegt ist. Sie ist nicht Pflicht — eine
    // Version aus der Zeit vor dieser Pruefung hat keine —, aber wenn sie da
    // ist, gilt sie. Die Versionsnummer allein faengt den Fall nicht: Zwei
    // Dateien koennen dieselbe Version nennen und verschiedene Punktwerte
    // tragen, und dann haengt jeder Score daran, welche gerade im Bucket liegt.
    final hinterlegt = (zeile['checksum'] as String?)?.trim().toLowerCase();
    if (hinterlegt != null && hinterlegt.isNotEmpty) {
      final gerechnet = sha256.convert(bytes).toString();
      if (gerechnet != hinterlegt) {
        throw DefinitionChecksumException(locale, version, hinterlegt, gerechnet);
      }
    }

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

/// Oberbegriff für „diese Fassung der Definition ist nicht verwendbar".
///
/// Die drei Fälle darunter unterscheiden sich darin, was schiefgelaufen ist, und
/// nicht darin, was eine Function tun soll: In allen drei Fällen wäre das
/// Weiterrechnen ein Rechnen gegen eine unbekannte Fassung. Deshalb fangen die
/// Functions diesen Typ und nicht die Einzelfälle — ein neuer Fall wird sonst an
/// fünf Stellen vergessen.
abstract interface class DefinitionException implements Exception {}

class DefinitionNotFoundException implements DefinitionException {
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

/// Die Datei im Storage ist nicht die, auf die das Release zeigt.
///
/// Anders als eine fehlende Version ist das kein Betriebszustand, mit dem sich
/// weiterarbeiten lässt: Entweder wurde eine andere Datei hochgeladen, oder die
/// hinterlegte Summe ist falsch. In beiden Fällen weiß niemand, gegen welche
/// Fassung gerechnet würde.
class DefinitionChecksumException implements DefinitionException {
  final String locale;
  final int version;
  final String erwartet;
  final String gefunden;

  const DefinitionChecksumException(
    this.locale,
    this.version,
    this.erwartet,
    this.gefunden,
  );

  @override
  String toString() =>
      'Die Pruefsumme von Version $version ($locale) stimmt nicht. Hinterlegt '
      'ist $erwartet, die Datei ergibt $gefunden. Entweder liegt eine andere '
      'Datei im Bucket oder die Summe in questionnaire_releases ist falsch — '
      'siehe notes/APPWRITE_SETUP.md.';
}

/// Die Datei im Storage gehört zu einer anderen Version als das Release.
///
/// Das ist ein Einrichtungsfehler und kein Datenfehler: Jemand hat eine Datei
/// unter der Kennung einer anderen Version hochgeladen. Still weiterzurechnen
/// hieße, gegen die falsche Fassung zu prüfen.
class DefinitionMismatchException implements DefinitionException {
  final int erwartet;
  final int gefunden;

  const DefinitionMismatchException(this.erwartet, this.gefunden);

  @override
  String toString() =>
      'Das Release verweist auf Version $erwartet, die Datei enthaelt aber '
      'Version $gefunden.';
}
