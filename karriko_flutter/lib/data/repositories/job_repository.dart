import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as aw_enums;
import 'package:appwrite/models.dart' as aw;
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../../core/constants/appwrite_constants.dart';
import '../../core/constants/questionnaire_constants.dart';
import '../models/job_model.dart';
import '../services/appwrite_service.dart';

/// Zugriff auf die Ausbildungsstellen.
///
/// Gelesen wird direkt aus `jobs`, geschrieben nur ueber die Function
/// `job_posting` (T-4.31): Frueher setzte der Client `company_id` und die
/// Angaben zum Betrieb selbst, und ein bestaetigtes Konto konnte so eine
/// Stelle im Namen eines fremden Betriebs anlegen. Jetzt nimmt der Server den
/// Betrieb aus dem angemeldeten Konto, setzt die Zeilenrechte (veroeffentlicht
/// fuer alle lesbar, Entwurf nur fuer den Eigentuemer) und laesst
/// Veroeffentlichen erst mit Abzeichen zu.
class JobRepository {
  /// [db] und [functions] ersetzen in Tests den Zugriff auf Appwrite.
  JobRepository({TablesDB? db, Functions? functions})
      : _dbOverride = db,
        _functionsOverride = functions;

  final TablesDB? _dbOverride;
  final Functions? _functionsOverride;

  TablesDB get _db => _dbOverride ?? TablesDB(AppwriteService.client);
  Functions get _functions =>
      _functionsOverride ?? Functions(AppwriteService.client);

  /// Oeffentliche Stellenliste eines Unternehmens.
  ///
  /// [onlyActive] blendet Entwuerfe aus. Das Betriebsprofil des Eigentuemers
  /// braucht auch die unveroeffentlichten.
  Future<List<JobModel>> jobsForCompany(
    String companyId, {
    bool onlyActive = true,
  }) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.jobsTable,
      queries: [
        Query.equal('company_id', companyId),
        if (onlyActive) Query.equal('is_active', true),
        Query.orderDesc('\$createdAt'),
        Query.limit(50),
      ],
    );
    return result.rows.map((r) => JobModel.fromJson(_toMap(r))).toList();
  }

  /// Zuletzt veroeffentlichte Stellen – Grundlage des Vorschlagsbands auf der
  /// Suchseite.
  Future<List<JobModel>> recentJobs({int limit = 12}) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.jobsTable,
      queries: [
        Query.equal('is_active', true),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ],
    );
    return result.rows.map((r) => JobModel.fromJson(_toMap(r))).toList();
  }

  Future<JobModel> getJob(String id) async {
    final row = await _db.getRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.jobsTable,
      rowId: id,
    );
    return JobModel.fromJson(_toMap(row));
  }

  /// Legt eine Stelle des eigenen Betriebs an.
  ///
  /// Mit [isActive] wird sie gleich veroeffentlicht; das lehnt der Server ab,
  /// solange der Betrieb nicht verifiziert ist ([JobPostingException]).
  Future<JobModel> createJob({
    required String title,
    required String location,
    String? profession,
    String? employmentType,
    String? description,
    List<String> tasks = const [],
    List<String> requirements = const [],
    List<String> benefits = const [],
    DateTime? startDate,
    String? duration,
    String? salary,
    String? applyUrl,
    String? contactEmail,
    bool isActive = true,
  }) =>
      _stelle({
        'action': 'create',
        'fields': fieldsFor(
          title: title,
          location: location,
          profession: profession,
          employmentType: employmentType,
          description: description,
          tasks: tasks,
          requirements: requirements,
          benefits: benefits,
          startDate: startDate,
          duration: duration,
          salary: salary,
          applyUrl: applyUrl,
          contactEmail: contactEmail,
          isActive: isActive,
        ),
      });

  /// Ueberschreibt eine Stelle mit dem Stand des Formulars. Geleerte Felder
  /// werden auf dem Server `null`, sonst bliebe ein geloeschter Text stehen.
  Future<JobModel> updateJob({
    required String jobId,
    required String title,
    required String location,
    String? profession,
    String? employmentType,
    String? description,
    List<String> tasks = const [],
    List<String> requirements = const [],
    List<String> benefits = const [],
    DateTime? startDate,
    String? duration,
    String? salary,
    String? applyUrl,
    String? contactEmail,
    required bool isActive,
  }) =>
      _stelle({
        'action': 'update',
        'job_id': jobId,
        'fields': fieldsFor(
          title: title,
          location: location,
          profession: profession,
          employmentType: employmentType,
          description: description,
          tasks: tasks,
          requirements: requirements,
          benefits: benefits,
          startDate: startDate,
          duration: duration,
          salary: salary,
          applyUrl: applyUrl,
          contactEmail: contactEmail,
          isActive: isActive,
        ),
      });

  /// Veroeffentlicht eine Stelle oder nimmt sie zurueck; die Zeilenrechte
  /// setzt der Server mit.
  Future<void> setActive({
    required String jobId,
    required bool isActive,
  }) =>
      _stelle({'action': 'set_active', 'job_id': jobId, 'is_active': isActive});

  Future<void> deleteJob(String jobId) =>
      _aufruf({'action': 'delete', 'job_id': jobId});

  /// Die Felder, die das Formular schickt. Immer alle, auch leere: Der Server
  /// ueberschreibt die Stelle und macht aus leeren Texten `null`. Betrieb,
  /// Branche und Logo fehlen absichtlich, die setzt der Server.
  @visibleForTesting
  static Map<String, Object?> fieldsFor({
    required String title,
    required String location,
    String? profession,
    String? employmentType,
    String? description,
    required List<String> tasks,
    required List<String> requirements,
    required List<String> benefits,
    DateTime? startDate,
    String? duration,
    String? salary,
    String? applyUrl,
    String? contactEmail,
    required bool isActive,
  }) =>
      {
        'title': title,
        'location': location,
        'profession': profession ?? '',
        'employment_type': employmentType ?? '',
        'description': description ?? '',
        'tasks': tasks,
        'requirements': requirements,
        'benefits': benefits,
        'start_date': startDate?.toIso8601String(),
        'duration': duration ?? '',
        'salary': salary ?? '',
        'apply_url': applyUrl ?? '',
        'contact_email': contactEmail ?? '',
        'is_active': isActive,
      };

  Future<JobModel> _stelle(Map<String, Object?> body) async {
    final antwort = await _aufruf(body);
    final stelle = antwort['job'];
    if (stelle is! Map) {
      throw const JobPostingException(
          'Die Stelle konnte nicht gespeichert werden.');
    }
    return JobModel.fromJson(stelle.cast<String, dynamic>());
  }

  Future<Map<String, Object?>> _aufruf(Map<String, Object?> body) async {
    final execution = await _functions.createExecution(
      functionId: QuestionnaireConstants.jobPostingFunction,
      body: jsonEncode(body),
      xasync: false,
      method: aw_enums.ExecutionMethod.pOST,
      path: '/',
    );
    Map<String, Object?> antwort = const {};
    try {
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is Map) antwort = decoded.cast<String, Object?>();
    } on FormatException {
      // bleibt leer, unten als Fehler behandelt
    }
    if (execution.responseStatusCode >= 400 || antwort['ok'] != true) {
      throw JobPostingException(
        antwort['message'] as String? ??
            'Die Stelle konnte nicht gespeichert werden.',
      );
    }
    return antwort;
  }

  Map<String, dynamic> _toMap(aw.Row doc) => {
        'id': doc.$id,
        'created_at': doc.$createdAt,
        ...doc.data,
      };
}

/// Die Function `job_posting` hat abgelehnt oder ist nicht erreichbar.
/// [message] richtet sich an den Betrieb.
class JobPostingException implements Exception {
  const JobPostingException(this.message);

  final String message;

  @override
  String toString() => message;
}
