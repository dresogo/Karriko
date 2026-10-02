import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;
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
      tableId: AppwriteConstants.jobsCollection,
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
      tableId: AppwriteConstants.jobsCollection,
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
      tableId: AppwriteConstants.jobsCollection,
      rowId: id,
    );
    return JobModel.fromJson(_toMap(row));
  }

  /// Legt eine Stelle an.
  ///
  /// Rechte am Dokument – dasselbe Muster wie beim Unternehmensprofil:
  /// - **Lesen fuer alle**, sonst faende die Suche die Stelle nicht.
  /// - **Aendern und Loeschen nur fuer den Eigentuemer** des Betriebskontos.
  ///
  /// Das ersetzt keine serverseitige Regel: Dokumentrechte greifen erst,
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
      tableId: AppwriteConstants.jobsCollection,
      rowId: ID.unique(),
      data: _payload(
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
      permissions: [
        Permission.read(Role.any()),
        Permission.update(Role.user(ownerId)),
        Permission.delete(Role.user(ownerId)),
      ],
    );
    return JobModel.fromJson(_toMap(row));
  }

  /// Schaltet eine Stelle oeffentlich oder nimmt sie zurueck.
  Future<void> setActive(
      {required String jobId, required bool isActive}) async {
    await _db.updateRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.jobsCollection,
      rowId: jobId,
      data: {'is_active': isActive},
    );
  }

  Future<void> deleteJob(String jobId) async {
    await _db.deleteRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.jobsCollection,
      rowId: jobId,
    );
  }

  /// Leere Freitextfelder werden weggelassen statt als leerer String
  /// gespeichert: Die Stellenseite entscheidet an `null`, ob ein Abschnitt
  /// ueberhaupt erscheint.
  Map<String, dynamic> _payload({
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
  }) {
    String? clean(String? value) {
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    }

    return {
      'company_id': companyId,
      'company': companyName,
      'company_slug': companySlug,
      if (clean(companyLogoUrl) != null)
        'company_logo_url': clean(companyLogoUrl),
      'title': title.trim(),
      'location': location.trim(),
      if (clean(profession) != null) 'profession': clean(profession),
      if (clean(industry) != null) 'industry': clean(industry),
      if (clean(employmentType) != null)
        'employment_type': clean(employmentType),
      if (clean(description) != null) 'description': clean(description),
      'tasks': tasks,
      'requirements': requirements,
      'benefits': benefits,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (clean(duration) != null) 'duration': clean(duration),
      if (clean(salary) != null) 'salary': clean(salary),
      if (clean(applyUrl) != null) 'apply_url': clean(applyUrl),
      if (clean(contactEmail) != null) 'contact_email': clean(contactEmail),
      'is_active': isActive,
    };
  }

  Map<String, dynamic> _toMap(aw.Row doc) => {
        'id': doc.$id,
        'created_at': doc.$createdAt,
        ...doc.data,
      };
}
