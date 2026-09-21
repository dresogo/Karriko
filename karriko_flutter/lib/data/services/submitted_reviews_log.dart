import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Eine abgeschickte Bewertung, so wie dieses Gerät sie kennt.
class SubmittedReview {
  final String reviewId;
  final String companyId;
  final String companyName;
  final DateTime submittedAt;

  /// `pending_moderation` oder `scheduled`, so wie die Function es gemeldet hat.
  final String status;

  const SubmittedReview({
    required this.reviewId,
    required this.companyId,
    required this.companyName,
    required this.submittedAt,
    required this.status,
  });

  Map<String, Object?> toJson() => {
        'review_id': reviewId,
        'company_id': companyId,
        'company_name': companyName,
        'submitted_at': submittedAt.toIso8601String(),
        'status': status,
      };

  static SubmittedReview? fromJson(Object? roh) {
    if (roh is! Map) return null;
    final id = roh['review_id'];
    final zeit = roh['submitted_at'];
    if (id is! String || zeit is! String) return null;
    return SubmittedReview(
      reviewId: id,
      companyId: roh['company_id'] as String? ?? '',
      companyName: roh['company_name'] as String? ?? '',
      submittedAt: DateTime.tryParse(zeit) ?? DateTime.now(),
      status: roh['status'] as String? ?? 'pending_moderation',
    );
  }
}

/// Merkt sich lokal, welche Bewertungen von diesem Gerät abgeschickt wurden.
///
/// **Warum das nötig ist:** `public_reviews` trägt keine `user_id`, und auf
/// `reviews` hat kein Client Zugriff. Das ist kein Versehen, sondern der Kern
/// der Trennung — eine öffentlich lesbare Zeile, die auf ein Konto zeigt, wäre
/// keine anonyme Bewertung. Der Preis ist, dass sich abgeschickte Bewertungen
/// nicht serverseitig einem Nutzer zuordnen lassen.
///
/// **Was dieser Weg kostet:** Die Liste steht nur auf diesem Gerät. Wer den
/// Browser wechselt oder die Seitendaten löscht, sieht seine früheren
/// Bewertungen hier nicht mehr — sie sind trotzdem da, nur nicht als „meine"
/// wiederzufinden. Das ist der ehrlichere Preis: Die Alternative wäre eine
/// Verknüpfung in der Datenbank, und genau die soll es nicht geben.
class SubmittedReviewsLog {
  static const _key = 'karriko.submitted_reviews';

  Future<List<SubmittedReview>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roh = prefs.getString(_key);
      if (roh == null || roh.isEmpty) return const [];
      final liste = jsonDecode(roh);
      if (liste is! List) return const [];
      return [
        for (final eintrag in liste)
          if (SubmittedReview.fromJson(eintrag) case final SubmittedReview e) e,
      ]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(SubmittedReview eintrag) async {
    try {
      final vorhanden = await read();
      if (vorhanden.any((e) => e.reviewId == eintrag.reviewId)) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode([
          eintrag.toJson(),
          for (final alt in vorhanden) alt.toJson(),
        ]),
      );
    } catch (_) {
      // Nicht gemerkt, nicht schlimm: Die Bewertung ist abgeschickt, nur die
      // Wiedervorlage auf diesem Gerät fehlt.
    }
  }
}
