const _months = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

/// Deutsches Langdatum, z. B. „3. August 2026".
///
/// Bewusst ohne `intl`: `DateFormat` mit Locale `de` verlangt ein vorher
/// geladenes Locale-Paket und wirft sonst zur Laufzeit.
String germanDate(DateTime date) =>
    '${date.day}. ${_months[date.month - 1]} ${date.year}';

/// Quartal als Kurzform, z. B. „Q4 2026".
///
/// Für öffentliche Bewertungen: Gespeichert ist nur der Quartalsbeginn, und
/// ein Monat in der Anzeige verspräche eine Genauigkeit, die es nicht gibt
/// (T-5.21). Gerechnet wird in UTC wie beim Speichern.
String quarterLabel(DateTime date) {
  final utc = date.toUtc();
  return 'Q${(utc.month - 1) ~/ 3 + 1} ${utc.year}';
}
