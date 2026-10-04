import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:questionnaire_core/questionnaire_core.dart';

import '../../core/constants/appwrite_constants.dart';
import '../../core/constants/questionnaire_constants.dart';
import '../models/questionnaire_release.dart';
import '../services/appwrite_service.dart';
import '../services/questionnaire_cache.dart';

/// Woher eine geladene Definition stammt. Nur fuer Protokoll und Anzeige.
enum QuestionnaireQuelle { storage, cache, asset }

class LoadedQuestionnaire {
  final Questionnaire questionnaire;
  final QuestionnaireQuelle quelle;

  const LoadedQuestionnaire(this.questionnaire, this.quelle);

  int get version => questionnaire.version;
}

/// Laedt die Fragendefinition.
///
/// Die Reihenfolge ist: aktive Version aus `questionnaire_releases` lesen,
/// Datei aus dem Storage holen, lokal ablegen — und wenn davon etwas scheitert,
/// auf das mitgelieferte Asset zurueckfallen.
///
/// Der Rueckfall ist ausdruecklich kein Notnagel, sondern Teil des Entwurfs:
/// Ein Azubi, der bewerten will, soll nicht daran scheitern, dass gerade eine
/// Datei nicht erreichbar ist. Der Preis ist, dass er dann unter Umstaenden
/// eine aeltere Fassung ausfuellt — deshalb traegt jede Einreichung ihre
/// `schema_version` mit, und die Function prueft gegen genau diese.
class QuestionnaireRepository {
  final QuestionnaireCache _cache;

  QuestionnaireRepository({QuestionnaireCache? cache})
      : _cache = cache ?? QuestionnaireCache();

  TablesDB get _db => TablesDB(AppwriteService.client);
  Storage get _storage => Storage(AppwriteService.client);

  /// Die Definition, die ein neuer Fragebogen benutzt.
  Future<LoadedQuestionnaire> loadActive({
    String locale = QuestionnaireConstants.locale,
  }) async {
    QuestionnaireRelease? release;
    try {
      release = await _activeRelease(locale);
    } on AppwriteException catch (e) {
      debugPrint('Fragebogen: Release nicht lesbar (${e.message}).');
    }

    if (release != null) {
      await _cache.writeActiveVersion(locale, release.version);

      final zwischengespeichert = await _parseOrNull(
        await _cache.read(locale, release.version),
      );
      if (zwischengespeichert != null) {
        return LoadedQuestionnaire(
            zwischengespeichert, QuestionnaireQuelle.cache);
      }

      final geladen = await _download(release);
      if (geladen != null) {
        await _cache.write(locale, release.version, geladen.$2);
        return LoadedQuestionnaire(geladen.$1, QuestionnaireQuelle.storage);
      }
    }

    // Kein Release erreichbar: Die zuletzt bekannte Version aus dem Cache ist
    // immer noch besser als das Asset, weil sie neuer sein kann.
    final bekannt = await _cache.readActiveVersion(locale);
    if (bekannt != null) {
      final zwischengespeichert =
          await _parseOrNull(await _cache.read(locale, bekannt));
      if (zwischengespeichert != null) {
        return LoadedQuestionnaire(
            zwischengespeichert, QuestionnaireQuelle.cache);
      }
    }

    return LoadedQuestionnaire(await loadBundled(), QuestionnaireQuelle.asset);
  }

  /// Genau die Version, mit der eine Bewertung begonnen wurde.
  ///
  /// Eine begonnene Bewertung wechselt die Version nicht. Sonst verschwaenden
  /// mitten im Ausfuellen Fragen, waehrend andere auftauchten — und die schon
  /// gegebenen Antworten passten zu keiner der beiden Fassungen.
  Future<LoadedQuestionnaire> loadVersion(
    int version, {
    String locale = QuestionnaireConstants.locale,
  }) async {
    final zwischengespeichert =
        await _parseOrNull(await _cache.read(locale, version));
    if (zwischengespeichert != null) {
      return LoadedQuestionnaire(
          zwischengespeichert, QuestionnaireQuelle.cache);
    }

    try {
      final release = await _releaseByVersion(locale, version);
      if (release != null) {
        final geladen = await _download(release);
        if (geladen != null) {
          await _cache.write(locale, version, geladen.$2);
          return LoadedQuestionnaire(geladen.$1, QuestionnaireQuelle.storage);
        }
      }
    } on AppwriteException catch (e) {
      debugPrint('Fragebogen: Version $version nicht ladbar (${e.message}).');
    }

    final asset = await loadBundled();
    if (asset.version == version) {
      return LoadedQuestionnaire(asset, QuestionnaireQuelle.asset);
    }

    // Hier ist kein stiller Rueckfall moeglich: Eine Einreichung gegen eine
    // andere Version als die begonnene wuerde von der Function zu Recht
    // abgelehnt. Besser eine klare Fehlermeldung als eine Bewertung, die beim
    // Absenden zerfaellt.
    throw StateError(
      'Version $version des Fragebogens ist nicht verfuegbar. Der Entwurf '
      'laesst sich erst fortsetzen, wenn die Verbindung wieder steht.',
    );
  }

  /// Das mitgelieferte Asset.
  Future<Questionnaire> loadBundled() async {
    final json =
        await rootBundle.loadString(QuestionnaireConstants.bundledAsset);
    return Questionnaire.parseJsonString(json);
  }

  // ── Appwrite ──────────────────────────────────────────────────────────────

  Future<QuestionnaireRelease?> _activeRelease(String locale) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.releasesCollection,
      queries: [
        Query.equal('locale', locale),
        Query.equal('active', true),
        Query.orderDesc('version'),
        Query.limit(1),
      ],
    );
    if (result.rows.isEmpty) return null;
    return QuestionnaireRelease.fromJson(_toMap(result.rows.first));
  }

  Future<QuestionnaireRelease?> _releaseByVersion(
    String locale,
    int version,
  ) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: QuestionnaireConstants.releasesCollection,
      queries: [
        Query.equal('locale', locale),
        Query.equal('version', version),
        Query.limit(1),
      ],
    );
    if (result.rows.isEmpty) return null;
    return QuestionnaireRelease.fromJson(_toMap(result.rows.first));
  }

  /// Laedt die Datei und gibt Definition **und** Rohtext zurueck.
  ///
  /// Der Rohtext wird gebraucht, weil der Cache ihn speichert — und zwar
  /// genau so, wie er kam. Ein Umweg ueber ein erneutes Serialisieren waere
  /// eine zweite Fassung derselben Datei.
  Future<(Questionnaire, String)?> _download(
      QuestionnaireRelease release) async {
    try {
      final bytes = await _storage.getFileDownload(
        bucketId: release.bucketId,
        fileId: release.fileId,
      );
      final json = utf8.decode(bytes);
      return (Questionnaire.parseJsonString(json), json);
    } on AppwriteException catch (e) {
      debugPrint('Fragebogen: Datei nicht ladbar (${e.message}).');
      return null;
    } on QuestionnaireFormatException catch (e) {
      // Eine kaputte Definition im Storage ist schlimmer als keine: Sie wuerde
      // sonst in den Cache wandern und dort bleiben.
      debugPrint('Fragebogen: Definition im Storage ist ungueltig — $e');
      return null;
    } on FormatException catch (e) {
      debugPrint('Fragebogen: Datei ist kein gueltiges JSON — ${e.message}');
      return null;
    }
  }

  Future<Questionnaire?> _parseOrNull(String? json) async {
    if (json == null) return null;
    try {
      return Questionnaire.parseJsonString(json);
    } on QuestionnaireFormatException catch (e) {
      debugPrint('Fragebogen: zwischengespeicherte Fassung unbrauchbar — $e');
      return null;
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> _toMap(aw.Row row) => {
        'id': row.$id,
        ...row.data,
      };
}
