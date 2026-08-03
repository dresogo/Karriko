class ReviewModel {
  final String id;
  final String companyId;
  final String companyName;
  final String? companySlug;
  final String authorId;
  final String? authorName;
  final bool isAnonymous;
  final int overallRating;
  final int? trainingQuality;
  final int? mentoring;
  final int? workLifeBalance;
  final int? careerOpportunities;
  final String title;
  final String text;
  final String? pros;
  final String? cons;
  final String? apprenticeshipYear;
  final String? profession;
  final bool isVerified;
  final String status;
  final String? betriebReply;
  final DateTime? betriebRepliedAt;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.companySlug,
    required this.authorId,
    this.authorName,
    required this.isAnonymous,
    required this.overallRating,
    this.trainingQuality,
    this.mentoring,
    this.workLifeBalance,
    this.careerOpportunities,
    required this.title,
    required this.text,
    this.pros,
    this.cons,
    this.apprenticeshipYear,
    this.profession,
    required this.isVerified,
    required this.status,
    this.betriebReply,
    this.betriebRepliedAt,
    required this.createdAt,
  });

  String get displayAuthor =>
      isAnonymous ? 'Anonymer Azubi' : (authorName ?? 'Unbekannt');

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      companySlug: json['company_slug'] as String?,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? true,
      overallRating: json['overall_rating'] as int,
      trainingQuality: json['training_quality'] as int?,
      mentoring: json['mentoring'] as int?,
      workLifeBalance: json['work_life_balance'] as int?,
      careerOpportunities: json['career_opportunities'] as int?,
      title: json['title'] as String,
      text: json['text'] as String,
      pros: json['pros'] as String?,
      cons: json['cons'] as String?,
      apprenticeshipYear: json['apprenticeship_year'] as String?,
      profession: json['profession'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      status: json['status'] as String? ?? 'published',
      betriebReply: json['betrieb_reply'] as String?,
      betriebRepliedAt: json['betrieb_replied_at'] != null
          ? DateTime.parse(json['betrieb_replied_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'company_name': companyName,
        'company_slug': companySlug,
        'author_id': authorId,
        'author_name': authorName,
        'is_anonymous': isAnonymous,
        'overall_rating': overallRating,
        'training_quality': trainingQuality,
        'mentoring': mentoring,
        'work_life_balance': workLifeBalance,
        'career_opportunities': careerOpportunities,
        'title': title,
        'text': text,
        'pros': pros,
        'cons': cons,
        'apprenticeship_year': apprenticeshipYear,
        'profession': profession,
        'is_verified': isVerified,
        'status': status,
        'betrieb_reply': betriebReply,
        'betrieb_replied_at': betriebRepliedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
