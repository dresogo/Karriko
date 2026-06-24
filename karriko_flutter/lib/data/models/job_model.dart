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
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final badgeStr = json['badge_variant'] as String? ?? 'days';
    final badgeVariant = switch (badgeStr) {
      'new' => JobBadgeVariant.isNew,
      'recent' => JobBadgeVariant.recent,
      _ => JobBadgeVariant.days,
    };

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
      };
}
