/// Was `moderation_desk` an den Admin-Bereich liefert.
///
/// Bewusst schlanke Abbildungen: Die Function entscheidet, was hier ankommt —
/// insbesondere, was **nicht** ankommt (siehe `withheldFromModeration`).
library;

DateTime? _datum(Object? roh) =>
    roh is String ? DateTime.tryParse(roh)?.toLocal() : null;

List<String> _liste(Object? roh) => [
      if (roh is List)
        for (final w in roh)
          if (w != null) w.toString()
    ];

int _zahl(Object? roh) => roh is num ? roh.toInt() : 0;

class AdminOverview {
  final int pending;
  final int scheduled;
  final int approved;
  final int rejected;
  final int openReports;
  final int companies;
  final int companiesUnverified;
  final List<ModerationLogItem> recentLog;

  const AdminOverview({
    required this.pending,
    required this.scheduled,
    required this.approved,
    required this.rejected,
    required this.openReports,
    required this.companies,
    required this.companiesUnverified,
    required this.recentLog,
  });

  factory AdminOverview.fromJson(Map<String, Object?> json) {
    final c = (json['counts'] as Map?)?.cast<String, Object?>() ?? const {};
    return AdminOverview(
      pending: _zahl(c['pending_moderation']),
      scheduled: _zahl(c['scheduled']),
      approved: _zahl(c['approved']),
      rejected: _zahl(c['rejected']),
      openReports: _zahl(c['open_reports']),
      companies: _zahl(c['companies']),
      companiesUnverified: _zahl(c['companies_unverified']),
      recentLog: [
        for (final e in (json['recent_log'] as List? ?? const []))
          if (e is Map) ModerationLogItem.fromJson(e.cast<String, Object?>()),
      ],
    );
  }
}

/// Eine Bewertung in der Warteschlange.
class QueueItem {
  final String reviewId;
  final String status;
  final DateTime? submittedAt;
  final String? companyName;
  final String? companySlug;
  final String? berufName;
  final int? startYear;
  final int? endYear;
  final bool invited;
  final String? freitextGut;
  final String? freitextSchlecht;
  final List<String> flags;
  final List<String> notes;

  /// Weiterempfehlung, 0 bis 10.
  final int? recommend;

  /// Gesamturteil K6, 0 bis 100.
  final int? overall;

  /// Aus den Einzelfragen gerechnet, 1,0 bis 5,0.
  final double? detailOverall;
  final bool verified;
  final bool hasVerification;
  final DateTime? publishAfter;
  final int reportCount;

  const QueueItem({
    required this.reviewId,
    required this.status,
    this.submittedAt,
    this.companyName,
    this.companySlug,
    this.berufName,
    this.startYear,
    this.endYear,
    this.invited = false,
    this.freitextGut,
    this.freitextSchlecht,
    this.flags = const [],
    this.notes = const [],
    this.recommend,
    this.overall,
    this.detailOverall,
    this.verified = false,
    this.hasVerification = false,
    this.publishAfter,
    this.reportCount = 0,
  });

  factory QueueItem.fromJson(Map<String, Object?> json) => QueueItem(
        reviewId: json['review_id'] as String? ?? '',
        status: json['status'] as String? ?? '',
        submittedAt: _datum(json['submitted_at']),
        companyName: json['company_name'] as String?,
        companySlug: json['company_slug'] as String?,
        berufName: json['beruf_name'] as String?,
        startYear: (json['start_year'] as num?)?.toInt(),
        endYear: (json['end_year'] as num?)?.toInt(),
        invited: json['invited'] == true,
        freitextGut: json['freitext_gut'] as String?,
        freitextSchlecht: json['freitext_schlecht'] as String?,
        flags: _liste(json['quality_flags']),
        notes: _liste(json['quality_notes']),
        recommend: (json['k5_recommend'] as num?)?.toInt(),
        overall: (json['k6_overall'] as num?)?.toInt(),
        detailOverall: (json['detail_overall'] as num?)?.toDouble(),
        verified: json['verified'] == true,
        hasVerification: json['has_verification'] == true,
        publishAfter: _datum(json['publish_after']),
        reportCount: _zahl(json['report_count']),
      );
}

class ReportItem {
  final String reportId;
  final DateTime? createdAt;
  final String reason;
  final String status;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final String? reportedId;
  final String? reviewId;
  final bool reviewFound;
  final String? reviewStatus;
  final String? berufName;
  final String? freitextGut;
  final String? freitextSchlecht;
  final List<String> flags;
  final String? publicReviewId;
  final String? companyName;
  final String? companySlug;

  const ReportItem({
    required this.reportId,
    required this.reason,
    required this.status,
    this.createdAt,
    this.resolvedAt,
    this.resolutionNote,
    this.reportedId,
    this.reviewId,
    this.reviewFound = false,
    this.reviewStatus,
    this.berufName,
    this.freitextGut,
    this.freitextSchlecht,
    this.flags = const [],
    this.publicReviewId,
    this.companyName,
    this.companySlug,
  });

  bool get isOpen => status == 'open';

  factory ReportItem.fromJson(Map<String, Object?> json) => ReportItem(
        reportId: json['report_id'] as String? ?? '',
        createdAt: _datum(json['created_at']),
        reason: json['reason'] as String? ?? '',
        status: json['status'] as String? ?? 'open',
        resolvedAt: _datum(json['resolved_at']),
        resolutionNote: json['resolution_note'] as String?,
        reportedId: json['reported_id'] as String?,
        reviewId: json['review_id'] as String?,
        reviewFound: json['review_found'] == true,
        reviewStatus: json['review_status'] as String?,
        berufName: json['beruf_name'] as String?,
        freitextGut: json['freitext_gut'] as String?,
        freitextSchlecht: json['freitext_schlecht'] as String?,
        flags: _liste(json['quality_flags']),
        publicReviewId: json['public_review_id'] as String?,
        companyName: json['company_name'] as String?,
        companySlug: json['company_slug'] as String?,
      );
}

class ModerationLogItem {
  final String logId;
  final String? reviewId;
  final String? moderatorId;
  final String? moderatorName;
  final String action;
  final String? reason;
  final List<String> flags;
  final DateTime? createdAt;
  final String? companyName;

  const ModerationLogItem({
    required this.logId,
    required this.action,
    this.reviewId,
    this.moderatorId,
    this.moderatorName,
    this.reason,
    this.flags = const [],
    this.createdAt,
    this.companyName,
  });

  bool get isApproval => action == 'approve';

  factory ModerationLogItem.fromJson(Map<String, Object?> json) =>
      ModerationLogItem(
        logId: json['log_id'] as String? ?? '',
        reviewId: json['review_id'] as String?,
        moderatorId: json['moderator_id'] as String?,
        moderatorName: json['moderator_name'] as String?,
        action: json['action'] as String? ?? '',
        reason: json['reason'] as String?,
        flags: _liste(json['flags']),
        createdAt: _datum(json['created_at']),
        companyName: json['company_name'] as String?,
      );
}

class CompanyItem {
  final String companyId;
  final String name;
  final String? slug;
  final String? city;
  final String? industry;
  final bool isVerified;
  final bool isPremium;
  final int reviewCount;
  final double? averageRating;
  final bool hasOwner;

  const CompanyItem({
    required this.companyId,
    required this.name,
    this.slug,
    this.city,
    this.industry,
    this.isVerified = false,
    this.isPremium = false,
    this.reviewCount = 0,
    this.averageRating,
    this.hasOwner = false,
  });

  CompanyItem copyWith({bool? isVerified}) => CompanyItem(
        companyId: companyId,
        name: name,
        slug: slug,
        city: city,
        industry: industry,
        isVerified: isVerified ?? this.isVerified,
        isPremium: isPremium,
        reviewCount: reviewCount,
        averageRating: averageRating,
        hasOwner: hasOwner,
      );

  factory CompanyItem.fromJson(Map<String, Object?> json) => CompanyItem(
        companyId: json['company_id'] as String? ?? '',
        name: json['name'] as String? ?? 'Ohne Namen',
        slug: json['slug'] as String?,
        city: json['city'] as String?,
        industry: json['industry'] as String?,
        isVerified: json['is_verified'] == true,
        isPremium: json['is_premium'] == true,
        reviewCount: _zahl(json['review_count']),
        averageRating: (json['average_rating'] as num?)?.toDouble(),
        hasOwner: json['has_owner'] == true,
      );
}
