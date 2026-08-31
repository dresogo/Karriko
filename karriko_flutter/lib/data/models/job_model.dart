enum JobBadgeVariant { isNew, recent, days }

class JobModel {
  final String id;
  final String title;
  final String company;
  final String companySlug;
  final String? companyLogoUrl;
  final String location;
  final String? profession;
  final String? industry;
  final String badge;
  final JobBadgeVariant badgeVariant;
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
    required this.title,
    required this.company,
    required this.companySlug,
    this.companyLogoUrl,
    required this.location,
    this.profession,
    this.industry,
    required this.badge,
    required this.badgeVariant,
    required this.isActive,
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

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final badgeStr = json['badge_variant'] as String? ?? 'days';
    final badgeVariant = switch (badgeStr) {
      'new' => JobBadgeVariant.isNew,
      'recent' => JobBadgeVariant.recent,
      _ => JobBadgeVariant.days,
    };

    List<String> list(String key) =>
        (json[key] as List?)?.whereType<String>().toList() ?? const [];

    DateTime? date(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.tryParse(value);
    }

    return JobModel(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      companySlug: json['company_slug'] as String,
      companyLogoUrl: json['company_logo_url'] as String?,
      location: json['location'] as String,
      profession: json['profession'] as String?,
      industry: json['industry'] as String?,
      badge: json['badge'] as String? ?? 'Neu',
      badgeVariant: badgeVariant,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
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
        'title': title,
        'company': company,
        'company_slug': companySlug,
        'company_logo_url': companyLogoUrl,
        'location': location,
        'profession': profession,
        'industry': industry,
        'badge': badge,
        'badge_variant': badgeVariant.name,
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
