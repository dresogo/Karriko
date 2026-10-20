/// Was ein Betrieb an seinem Profil selbst setzen darf.
///
/// Appwrite kennt keine Rechte je Spalte. Solange der Client direkt in
/// `companies` schrieb, konnte er beim Anlegen wie beim Ändern auch
/// `is_verified`, `is_premium`, `average_rating`, `review_count` und
/// `owner_id` setzen (T-4.2). Deshalb gibt es keinen Schreibweg mehr am
/// Server vorbei: `company_profile` übernimmt nur die Felder aus
/// [companyEditableFields], alles andere setzt der Server oder die Moderation.
///
/// Reine Funktionen ohne Netz, damit sich prüfen lässt, was gespeichert würde.
library;

/// Die Felder, die ein Betrieb selbst setzen darf, mit ihrer Höchstlänge.
///
/// Die Längen sind die der Spalten in `companies`. `null` heißt: Die Spalte
/// begrenzt selbst (`text`, `url`).
const companyEditableFields = <String, int?>{
  'name': 200,
  'description': null,
  'website': null,
  'logo_url': null,
  'city': 100,
  'country': 100,
  'industry': 100,
};

/// Felder, die eine Adresse enthalten und deshalb nur `http` oder `https`
/// sein dürfen. Eine `javascript:`-Adresse wäre sonst ein Einfallstor, sobald
/// die App sie verlinkt (E-46).
const companyUrlFields = {'website', 'logo_url'};

/// Ergebnis der Prüfung: entweder [data] zum Speichern oder [errors].
class CompanyProfileInput {
  final Map<String, Object?> data;
  final List<String> errors;

  const CompanyProfileInput._(this.data, this.errors);

  bool get isValid => errors.isEmpty;
}

/// Prüft einen Rumpf und behält nur die erlaubten Felder.
///
/// * Unbekannte Felder werden **verworfen und gemeldet**, nicht still
///   ignoriert: Wer `is_verified` mitschickt, soll es im Log sehen.
/// * Ein leerer Text bei einem optionalen Feld heißt „leeren“ und wird zu
///   `null`. Appwrite nimmt in einer `url`-Spalte keinen leeren Text an.
/// * `name` ist beim Anlegen Pflicht und darf nie leer werden.
CompanyProfileInput parseCompanyProfile(
  Map<String, Object?> fields, {
  required bool creating,
}) {
  final data = <String, Object?>{};
  final errors = <String>[];

  for (final MapEntry(:key, :value) in fields.entries) {
    if (!companyEditableFields.containsKey(key)) {
      errors.add('Feld nicht erlaubt: $key');
      continue;
    }
    if (value != null && value is! String) {
      errors.add('$key muss Text sein.');
      continue;
    }
    final text = (value as String?)?.trim() ?? '';
    if (text.isEmpty) {
      if (key == 'name') {
        errors.add('Der Unternehmensname darf nicht leer sein.');
      } else {
        data[key] = null;
      }
      continue;
    }
    final max = companyEditableFields[key];
    if (max != null && text.length > max) {
      errors.add('$key ist länger als $max Zeichen.');
      continue;
    }
    if (companyUrlFields.contains(key) && !isHttpUrl(text)) {
      errors.add(key == 'website'
          ? 'Die Website muss mit http:// oder https:// beginnen.'
          : '$key muss mit http:// oder https:// beginnen.');
      continue;
    }
    data[key] = text;
  }

  if (creating && data['name'] == null) {
    if (!errors.any((e) => e.startsWith('Der Unternehmensname'))) {
      errors.add('Der Unternehmensname darf nicht leer sein.');
    }
  }

  return CompanyProfileInput._(
    errors.isEmpty ? data : const {},
    errors,
  );
}

/// `true` für eine absolute Adresse mit `http` oder `https` und Host.
bool isHttpUrl(String text) {
  final uri = Uri.tryParse(text.trim());
  if (uri == null) return false;
  return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

/// Die Zeile, mit der ein neuer Betrieb entsteht.
///
/// Was der Betrieb nicht selbst setzen darf, steht hier fest: Das Abzeichen
/// vergibt ein Mensch (Referenz §3.2), Premium kommt aus der Abrechnung, die
/// Bewertung aus `aggregate_company`.
Map<String, Object?> buildNewCompanyRow({
  required String ownerId,
  required String slug,
  required Map<String, Object?> fields,
}) =>
    {
      ...fields,
      'slug': slug,
      'owner_id': ownerId,
      'review_count': 0,
      'is_premium': false,
      'is_verified': false,
    };

/// Bildet aus einem Firmennamen den Teil der öffentlichen Adresse.
///
/// Dieselbe Regel wie `companySlug` in der App
/// (`karriko_flutter/lib/data/repositories/company_repository.dart`); die App
/// legt seit T-4.2 keine Firma mehr selbst an, braucht die Regel aber weiter
/// für Verweise. Umlaute werden ausgeschrieben statt entfernt.
String companySlug(String name) {
  const ersatz = {
    'ä': 'ae',
    'ö': 'oe',
    'ü': 'ue',
    'ß': 'ss',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
  };
  final ersetzt = name.toLowerCase().replaceAllMapped(
        RegExp('[äöüßáàâéèêíìîóòôúùû]'),
        (m) => ersatz[m[0]]!,
      );
  final slug = ersetzt
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'unternehmen' : slug;
}

/// Was der Client über die Firma zurückbekommt: die Zeile, wie er sie auch
/// aus der Tabelle lesen würde.
Map<String, Object?> companyResponse({
  required String id,
  required String createdAt,
  required Map<String, Object?> data,
}) =>
    {
      'id': id,
      'created_at': createdAt,
      ...data,
    };
