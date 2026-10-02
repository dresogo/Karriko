enum JobBadgeVariant { isNew, recent, days }

class JobModel {
  final String id;

  /// Unternehmen, dem die Stelle gehoert. Die Kennung traegt die Abfrage, der
  /// Slug die oeffentliche Adresse, der Name die Anzeige.
  final String companyId;
  final String company;
  final String companySlug;
  final String? companyLogoUrl;

  final String title;
  final String location;
  final String? profession;
  final String? industry;

  /// Veroeffentlicht oder Entwurf. Nur aktive Stellen erscheinen oeffentlich.
  final bool isActive;
  final DateTime createdAt;

  // ─── Angaben der Stellenseite ──────────────────────────────────────────────
  //
  // Alle optional: Die Uebersichtskarten kommen ohne sie aus, und die
  // Detailseite blendet aus, wofuer nichts hinterlegt ist.

  /// Beschreibungstext der Stelle.
  final String? description;

  /// Aufgaben, Anforderungen und Angebote als einzelne Punkte.
  final List<String> tasks;
  final List<String> requirements;
  final List<String> benefits;

  /// Art der Stelle, z. B. „Ausbildung“ oder „Praktikum“.
  final String? employmentType;

  /// Ausbildungsbeginn und -dauer.
  final DateTime? startDate;
  final String? duration;

  /// Verguetung als Freitext, damit Angaben wie „1. Jahr 1.050 €“ passen.
  final String? salary;

  /// Weg der Bewerbung. Ohne beides fuehrt die Seite auf das Betriebsprofil.
  final String? applyUrl;
  final String? contactEmail;

  const JobModel({
    required this.id,
    required this.companyId,
    required this.title,
    required this.company,
    required this.companySlug,
    this.companyLogoUrl,
    required this.location,
    this.profession,
    this.industry,
    this.isActive = true,
    required this.createdAt,
    this.description,
    this.tasks = const [],
    this.requirements = const [],
    this.benefits = const [],
    this.employmentType,
    this.startDate,
    this.duration,
    this.salary,
    this.applyUrl,
    this.contactEmail,
  });

  /// Hat die Stelle ueber die Eckdaten hinaus Inhalt?
  bool get hasDetails =>
      (description != null && description!.trim().isNotEmpty) ||
      tasks.isNotEmpty ||
      requirements.isNotEmpty ||
      benefits.isNotEmpty;

  /// Alter der Ausschreibung in Tagen.
  int get _ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Kennzeichnung aus dem Alter der Ausschreibung – nicht gespeichert,
  /// sondern gerechnet: Ein gespeichertes „Neu“ waere nach einer Woche falsch.
  String get badge {
    final days = _ageInDays;
    if (days <= 7) return 'Neu';
    if (days <= 30) return 'Vor $days Tagen';
    final months = days ~/ 30;
    return months <= 1 ? 'Vor einem Monat' : 'Vor $months Monaten';
  }

  JobBadgeVariant get badgeVariant {
    final days = _ageInDays;
    if (days <= 7) return JobBadgeVariant.isNew;
    if (days <= 30) return JobBadgeVariant.recent;
    return JobBadgeVariant.days;
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    List<String> list(String key) =>
        (json[key] as List?)?.whereType<String>().toList() ?? const [];

    DateTime? date(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.tryParse(value);
    }

    return JobModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String? ?? '',
      title: json['title'] as String,
      company: json['company'] as String? ?? '',
      companySlug: json['company_slug'] as String? ?? '',
      companyLogoUrl: json['company_logo_url'] as String?,
      location: json['location'] as String? ?? '',
      profession: json['profession'] as String?,
      industry: json['industry'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: date('created_at') ?? DateTime.now(),
      description: json['description'] as String?,
      tasks: list('tasks'),
      requirements: list('requirements'),
      benefits: list('benefits'),
      employmentType: json['employment_type'] as String?,
      startDate: date('start_date'),
      duration: json['duration'] as String?,
      salary: json['salary'] as String?,
      applyUrl: json['apply_url'] as String?,
      contactEmail: json['contact_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'title': title,
        'company': company,
        'company_slug': companySlug,
        'company_logo_url': companyLogoUrl,
        'location': location,
        'profession': profession,
        'industry': industry,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'description': description,
        'tasks': tasks,
        'requirements': requirements,
        'benefits': benefits,
        'employment_type': employmentType,
        'start_date': startDate?.toIso8601String(),
        'duration': duration,
        'salary': salary,
        'apply_url': applyUrl,
        'contact_email': contactEmail,
      };
}
