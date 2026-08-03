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
