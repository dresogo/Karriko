/// Was mit den Daten eines Kontos geschieht: Löschen (Art. 17), Löschen
/// einer einzelnen Bewertung und Export (Art. 20).
///
/// Reine Funktionen ohne Netz. Wer prüfen will, was gelöscht, behalten oder
/// ausgeliefert würde, muss dafür nichts löschen.
library;

import 'dart:convert';

import 'review_row.dart' show ReviewStatus;

/// Wie lange sich eine Kontolöschung zurücknehmen lässt (E-50).
const defaultDeletionGraceDays = 14;

/// Ersatz für `user_id` in einer Bewertung, die nach der Kontolöschung
/// stehen bleibt (E-50: der Nutzerbezug wird entfernt).
///
/// Aus der Zeilenkennung gebildet und nicht leer oder gleich für alle: Der
/// eindeutige Index `user_company_unique` auf `(user_id, company_id)` ließe
/// sonst nur eine verwaiste Bewertung je Betrieb zu. Die Zeilenkennung ist
/// zufällig und sagt nichts über das Konto.
String deletedUserMarker(String rowId) => 'geloescht-$rowId';

/// Ob eine Bewertung bei der Kontolöschung erhalten bleibt.
///
/// Nur veröffentlichte: Sie stehen öffentlich und tragen zum Score bei, und
/// ohne Nutzerbezug sind sie keinem Konto mehr zuzuordnen. Alles, was noch
/// nicht veröffentlicht ist (in Moderation, zurückgestellt, abgelehnt), wird
/// gelöscht. Entschieden mit dem Nutzer am 20.10.2026.
bool keepReviewOnAccountDeletion(String? status) =>
    status == ReviewStatus.approved;

/// Was an einer erhaltenen Bewertung geändert wird, damit sie keinem Konto
/// mehr zuzuordnen ist. Der Gerätehash fällt mit weg: Über ihn ließe sich
/// eine Bewertung mit späteren desselben Geräts verbinden.
Map<String, Object?> detachReviewFromUser(String rowId) => {
      'user_id': deletedUserMarker(rowId),
      'device_hash': null,
      'verification_file_id': null,
    };

/// Der Zeitpunkt, ab dem `cleanup` ein Konto endgültig löscht.
DateTime deletionDueAt(DateTime requestedAt,
        {int graceDays = defaultDeletionGraceDays}) =>
    requestedAt.toUtc().add(Duration(days: graceDays));

// ── Export (Art. 20) ────────────────────────────────────────────────────────

/// Die Spalten einer eigenen Bewertung, die in den Export gehen.
///
/// Art. 20 betrifft Daten, die die Person selbst bereitgestellt hat: ihre
/// Antworten und Texte, dazu der Status. **Nicht** enthalten sind interne
/// Prüfmerkmale (`quality_flags`, `quality_notes`, `timings_json`,
/// `device_hash`), die gerechneten Werte und die Kennung des Nachweises.
/// Ob eine Auskunft nach Art. 15 mehr umfassen muss, ist juristisch zu
/// prüfen (Entscheidung des Nutzers vom 20.10.2026; Frage an den Anwalt).
const exportedReviewFields = [
  'company_id',
  'status',
  'beruf_name',
  'start_year',
  'end_year',
  'freitext_gut',
  'freitext_schlecht',
  'answers_json',
  'publish_after',
  'publish_after_training_end',
  'verified',
];

/// Die Spalten eines Entwurfs im Export.
const exportedDraftFields = ['company_id', 'answers_json', 'updated_at'];

/// Die Spalten einer eigenen Meldung im Export.
const exportedReportFields = ['review_id', 'reason', 'status'];

/// Baut die Exportdatei.
///
/// [account] sind die Kontodaten aus Appwrite (Name, Adresse, Anlage),
/// [profile] die Profilzeile oder `null`. Alle Zeilen kommen als
/// `(id, createdAt, data)`. JSON-Spalten werden entpackt, damit die Datei
/// lesbar ist und nicht Text in Text enthält.
Map<String, Object?> buildAccountExport({
  required DateTime exportedAt,
  required Map<String, Object?> account,
  Map<String, Object?>? profile,
  required List<ExportRow> reviews,
  required List<ExportRow> drafts,
  required List<ExportRow> bookmarks,
  required List<ExportRow> reports,
  Map<String, String> companyNames = const {},
}) {
  Map<String, Object?> auswahl(ExportRow zeile, List<String> felder) => {
        'id': zeile.id,
        'created_at': zeile.createdAt,
        for (final feld in felder)
          if (zeile.data.containsKey(feld)) feld: _entpackt(zeile.data[feld]),
      };

  String? name(Object? id) => id is String ? companyNames[id] : null;

  return {
    'format': 'karriko-export-1',
    'exported_at': exportedAt.toUtc().toIso8601String(),
    'account': account,
    if (profile != null) 'profile': _ohneInterna(profile),
    'reviews': [
      for (final z in reviews)
        {
          ...auswahl(z, exportedReviewFields),
          'company_name': name(z.data['company_id']),
        },
    ],
    'drafts': [
      for (final z in drafts)
        {
          ...auswahl(z, exportedDraftFields),
          'company_name': name(z.data['company_id']),
        },
    ],
    'bookmarks': [
      for (final z in bookmarks)
        {
          'company_id': z.data['company_id'],
          'company_name': name(z.data['company_id']),
          'created_at': z.createdAt,
        },
    ],
    'reports': [for (final z in reports) auswahl(z, exportedReportFields)],
  };
}

/// Eine Zeile, wie der Export sie braucht.
class ExportRow {
  final String id;
  final String createdAt;
  final Map<String, Object?> data;

  const ExportRow(this.id, this.createdAt, this.data);
}

/// Eine JSON-Spalte als Struktur statt als Text. Was sich nicht lesen lässt,
/// bleibt Text.
Object? _entpackt(Object? wert) {
  if (wert is! String) return wert;
  final t = wert.trimLeft();
  if (!(t.startsWith('{') || t.startsWith('['))) return wert;
  try {
    return jsonDecode(wert);
  } catch (_) {
    return wert;
  }
}

/// Appwrite-Metadaten (`$id`, `$permissions` …) gehören nicht in den Export.
Map<String, Object?> _ohneInterna(Map<String, Object?> zeile) => {
      for (final e in zeile.entries)
        if (!e.key.startsWith(r'$')) e.key: e.value,
    };

/// Name der Pref, in der `my_account` den Löschtermin für die App ablegt.
const accountDeletionPref = 'deletion_pending_until';
