/// Was ein Betrieb an einer Stellenanzeige selbst setzen darf.
///
/// Solange der Client direkt in `jobs` schrieb, setzte er auch `company_id`,
/// `company`, `company_slug` und `company_logo_url` selbst. Ein bestätigtes
/// Konto konnte so eine Stelle im Namen eines fremden Betriebs anlegen
/// (T-4.31). Jetzt kommen diese Angaben aus der Firma des Aufrufers, und die
/// Function `job_posting` übernimmt nur die Felder aus [jobTextFields],
/// [jobListFields], `start_date` und `is_active`.
///
/// Reine Funktionen ohne Netz, damit sich prüfen lässt, was gespeichert würde.
library;

import 'company_profile.dart' show isHttpUrl;

/// Textfelder mit ihrer Höchstlänge laut Spalte. `null`: Die Spalte (`text`)
/// begrenzt selbst.
const jobTextFields = <String, int?>{
  'title': 255,
  'location': 255,
  'profession': 255,
  'employment_type': 255,
  'duration': 255,
  'salary': 255,
  'description': null,
  'apply_url': 2048,
  'contact_email': 255,
};

/// Pflichtangaben einer Stelle, wie im Formular.
const jobRequiredFields = {'title', 'location'};

/// Listenfelder; jeder Punkt höchstens so lang wie die Spalte erlaubt.
const jobListFields = {'tasks', 'requirements', 'benefits'};
const jobListItemMax = 1000;

/// Ergebnis der Prüfung: entweder [data] zum Speichern oder [errors].
class JobPostingInput {
  final Map<String, Object?> data;
  final List<String> errors;

  const JobPostingInput._(this.data, this.errors);

  bool get isValid => errors.isEmpty;

  /// Ob die Stelle öffentlich sein soll.
  bool get isActive => data['is_active'] == true;
}

/// Prüft den Stand des Formulars und baut daraus die vollständigen Felder.
///
/// Das Formular schickt immer alles; eine Stelle wird beim Speichern
/// **überschrieben**. Leere optionale Felder werden deshalb `null`, sonst
/// bliebe ein gelöschter Text stehen. Unbekannte Felder lassen die Anfrage
/// scheitern, damit niemand `company_id` unbemerkt mitschickt.
JobPostingInput parseJobPosting(Map<String, Object?> fields) {
  final data = <String, Object?>{};
  final errors = <String>[];

  for (final key in fields.keys) {
    if (!jobTextFields.containsKey(key) &&
        !jobListFields.contains(key) &&
        key != 'start_date' &&
        key != 'is_active') {
      errors.add('Feld nicht erlaubt: $key');
    }
  }

  for (final MapEntry(key: key, value: max) in jobTextFields.entries) {
    final roh = fields[key];
    if (roh != null && roh is! String) {
      errors.add('$key muss Text sein.');
      continue;
    }
    final text = (roh as String?)?.trim() ?? '';
    if (text.isEmpty) {
      if (jobRequiredFields.contains(key)) {
        errors.add(key == 'title'
            ? 'Bitte gib einen Titel an.'
            : 'Bitte gib einen Ort an.');
      }
      data[key] = null;
      continue;
    }
    if (max != null && text.length > max) {
      errors.add('$key ist länger als $max Zeichen.');
      continue;
    }
    if (key == 'apply_url' && !isHttpUrl(text)) {
      errors.add('Der Bewerbungslink muss mit http:// oder https:// beginnen.');
      continue;
    }
    if (key == 'contact_email' && !isPlausibleEmail(text)) {
      errors.add('Die Kontakt-E-Mail sieht nicht wie eine Adresse aus.');
      continue;
    }
    data[key] = text;
  }

  for (final key in jobListFields) {
    final roh = fields[key];
    if (roh == null) {
      data[key] = const <String>[];
      continue;
    }
    if (roh is! List || roh.any((p) => p is! String)) {
      errors.add('$key muss eine Liste von Texten sein.');
      continue;
    }
    final punkte = [
      for (final p in roh.cast<String>())
        if (p.trim().isNotEmpty) p.trim(),
    ];
    if (punkte.any((p) => p.length > jobListItemMax)) {
      errors.add('Ein Punkt in $key ist länger als $jobListItemMax Zeichen.');
      continue;
    }
    data[key] = punkte;
  }

  final beginn = fields['start_date'];
  if (beginn == null || (beginn is String && beginn.trim().isEmpty)) {
    data['start_date'] = null;
  } else if (beginn is String && DateTime.tryParse(beginn) != null) {
    data['start_date'] = DateTime.parse(beginn).toUtc().toIso8601String();
  } else {
    errors.add('Der Ausbildungsbeginn ist kein Datum.');
  }

  final aktiv = fields['is_active'];
  if (aktiv is! bool) {
    errors.add('is_active muss wahr oder falsch sein.');
  } else {
    data['is_active'] = aktiv;
  }

  return JobPostingInput._(errors.isEmpty ? data : const {}, errors);
}

/// Grob genug, um Tippfehler zu fangen, ohne gültige Adressen abzuweisen:
/// ein `@`, davor etwas, danach ein Name mit Punkt, keine Leerzeichen.
bool isPlausibleEmail(String text) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text.trim());

/// Die Angaben zum Betrieb, die in jeder Stelle doppelt stehen, damit Liste
/// und Suche ohne zweite Abfrage auskommen. Immer aus der Firmenzeile, nie
/// aus der Anfrage; bei jeder Änderung neu, damit eine Umbenennung ankommt.
Map<String, Object?> jobCompanyFields({
  required String companyId,
  required Map<String, Object?> company,
}) =>
    {
      'company_id': companyId,
      'company': company['name'],
      'company_slug': company['slug'],
      'company_logo_url': company['logo_url'],
      'industry': company['industry'],
    };

/// Ob ein Betrieb diese Stelle so speichern darf.
///
/// Entwürfe darf jeder Betrieb anlegen; öffentlich wird eine Stelle erst,
/// wenn die Moderation den Betrieb verifiziert hat (Factsheet Abschnitt 1:
/// Betriebe sind menschlich verifiziert). `null` heißt erlaubt, sonst die
/// Meldung an den Betrieb.
String? jobPublishBlocked({
  required bool isActive,
  required bool companyVerified,
}) =>
    isActive && !companyVerified
        ? 'Veröffentlichen geht erst, wenn euer Betrieb verifiziert ist. '
            'Bis dahin kannst du die Stelle als Entwurf speichern.'
        : null;
