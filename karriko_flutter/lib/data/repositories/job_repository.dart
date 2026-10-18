import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../../core/constants/appwrite_constants.dart';
import '../models/job_model.dart';
import '../services/appwrite_service.dart';

/// Zugriff auf die Ausbildungsstellen.
///
/// Die Sammlung `jobs` muss in der Appwrite-Console angelegt sein – wie bei den
/// uebrigen Sammlungen auch (siehe [AppwriteConstants]). Die erwarteten Spalten
/// stehen in [createJob].
class JobRepository {
  TablesDB get _db => TablesDB(AppwriteService.client);

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

  /// Legt eine Stelle an.
  ///
  /// Rechte an der Zeile – dasselbe Muster wie beim Unternehmensprofil:
  /// - **Lesen fuer alle**, sonst faende die Suche die Stelle nicht.
  /// - **Aendern und Loeschen nur fuer den Eigentuemer** des Betriebskontos.
  ///
  /// Das ersetzt keine serverseitige Regel: Zeilenrechte greifen erst,
  /// nachdem der Client sie gesetzt hat. Die tragende Grenze sind die
  /// Berechtigungen der Sammlung.
  ///
  /// Erwartete Spalten der Sammlung `jobs`:
  /// `company_id`, `company`, `company_slug`, `company_logo_url`, `title`,
  /// `location`, `profession`, `industry`, `employment_type`, `description`,
  /// `tasks[]`, `requirements[]`, `benefits[]`, `start_date`, `duration`,
  /// `salary`, `apply_url`, `contact_email`, `is_active`.
  Future<JobModel> createJob({
    required String ownerId,
    required String companyId,
    required String companyName,
    required String companySlug,
    String? companyLogoUrl,
    required String title,
    required String location,
    String? profession,
    String? industry,
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
  }) async {
    final row = await _db.createRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.jobsTable,
      rowId: ID.unique(),
      data: payloadFor(
        companyId: companyId,
        companyName: companyName,
        companySlug: companySlug,
        companyLogoUrl: companyLogoUrl,
        title: title,
        location: location,
        profession: profession,
        industry: industry,
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
      permissions: permissionsFor(ownerId: ownerId, isActive: isActive),
    );
    return JobModel.fromJson(_toMap(row));
  }

  /// Ueberschreibt eine bestehende Stelle mit dem Stand des Formulars.
  ///
  /// Anders als beim Anlegen gehen geleerte Felder als `null` mit: Sonst
  /// bliebe ein geloeschter Text in der Zeile stehen, und die Stellenseite
  /// zeigte ihn weiter. Die Rechte werden mit dem Zustand neu gesetzt, damit
  /// ein Entwurf beim Speichern nicht versehentlich oeffentlich lesbar wird
  /// (siehe [permissionsFor]).
  Future<JobModel> updateJob({
    required String jobId,
    required String ownerId,
    required String companyId,
    required String companyName,
    required String companySlug,
    String? companyLogoUrl,
    required String title,
    required String location,
    String? profession,
    String? industry,
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
  }) async {
    final row = await _db.updateRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.jobsTable,
      rowId: jobId,
      data: payloadFor(
        companyId: companyId,
        companyName: companyName,
        companySlug: companySlug,
        companyLogoUrl: companyLogoUrl,
        title: title,
        location: location,
        profession: profession,
        industry: industry,
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
        leereFelderLeeren: true,
      ),
      permissions: permissionsFor(ownerId: ownerId, isActive: isActive),
    );
    return JobModel.fromJson(_toMap(row));
  }

  /// Zeilenrechte einer Stelle.
  ///
  /// Ein Entwurf ist nur fuer den Eigentuemer lesbar, eine veroeffentlichte
  /// Stelle fuer alle. Frueher bekam jede Stelle `read("any")`, und die
  /// oeffentliche Liste filterte nur nach `is_active` – ueber die API oder
  /// die Adresse `/stellen/<id>` war ein Entwurf trotzdem fuer jeden lesbar.
  ///
  /// Wirkt erst vollstaendig, wenn die Tabelle `jobs` selbst kein
  /// `read("any")` mehr traegt, siehe tools/appwrite-setup.mjs.
  static List<String> permissionsFor({
    required String ownerId,
    required bool isActive,
  }) =>
      [
        Permission.read(isActive ? Role.any() : Role.user(ownerId)),
        Permission.update(Role.user(ownerId)),
        Permission.delete(Role.user(ownerId)),
      ];

  /// Schaltet eine Stelle oeffentlich oder nimmt sie zurueck – samt
  /// Leserecht, siehe [permissionsFor].
  Future<void> setActive({
    required String jobId,
    required bool isActive,
    required String ownerId,
  }) async {
    await _db.updateRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.jobsTable,
      rowId: jobId,
      data: {'is_active': isActive},
      permissions: permissionsFor(ownerId: ownerId, isActive: isActive),
    );
  }

  Future<void> deleteJob(String jobId) async {
    await _db.deleteRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.jobsTable,
      rowId: jobId,
    );
  }

  /// Leere Freitextfelder werden weggelassen statt als leerer String
  /// gespeichert: Die Stellenseite entscheidet an `null`, ob ein Abschnitt
  /// ueberhaupt erscheint.
  ///
  /// Mit [leereFelderLeeren] gehen sie stattdessen als `null` mit – beim
  /// Bearbeiten, wo Weglassen den alten Wert stehen liesse.
  @visibleForTesting
  static Map<String, dynamic> payloadFor({
    required String companyId,
    required String companyName,
    required String companySlug,
    String? companyLogoUrl,
    required String title,
    required String location,
    String? profession,
    String? industry,
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
    bool leereFelderLeeren = false,
  }) {
    String? clean(String? value) {
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    }

    final optional = <String, Object?>{
      'company_logo_url': clean(companyLogoUrl),
      'profession': clean(profession),
      'industry': clean(industry),
      'employment_type': clean(employmentType),
      'description': clean(description),
      'start_date': startDate?.toIso8601String(),
      'duration': clean(duration),
      'salary': clean(salary),
      'apply_url': clean(applyUrl),
      'contact_email': clean(contactEmail),
    };

    return {
      'company_id': companyId,
      'company': companyName,
      'company_slug': companySlug,
      'title': title.trim(),
      'location': location.trim(),
      'tasks': tasks,
      'requirements': requirements,
      'benefits': benefits,
      'is_active': isActive,
      for (final e in optional.entries)
        if (e.value != null || leereFelderLeeren) e.key: e.value,
    };
  }

  Map<String, dynamic> _toMap(aw.Row doc) => {
        'id': doc.$id,
        'created_at': doc.$createdAt,
        ...doc.data,
      };
}
