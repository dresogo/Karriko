class CompanyModel {
  final String id;
  final String slug;
  final String name;
  final String? logoUrl;
  final String? description;
  final String? industry;
  final String? city;
  final String? country;
  final String? website;
  final double? averageRating;
  final int reviewCount;
  final bool isPremium;
  final bool isVerified;
  final DateTime createdAt;

  const CompanyModel({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
    this.description,
    this.industry,
    this.city,
    this.country,
    this.website,
    this.averageRating,
    required this.reviewCount,
    required this.isPremium,
    required this.isVerified,
    required this.createdAt,
  });

  String get location => [city, country].where((s) => s != null && (s?.isNotEmpty ?? false)).join(', ');

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      industry: json['industry'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      website: json['website'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int? ?? 0,
      isPremium: json['is_premium'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'name': name,
        'logo_url': logoUrl,
        'description': description,
        'industry': industry,
        'city': city,
        'country': country,
        'website': website,
        'average_rating': averageRating,
        'review_count': reviewCount,
        'is_premium': isPremium,
        'is_verified': isVerified,
        'created_at': createdAt.toIso8601String(),
      };
}
