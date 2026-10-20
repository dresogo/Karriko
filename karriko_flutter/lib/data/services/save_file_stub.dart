/// Siehe `save_file.dart` fuer die Begruendung.
Future<void> saveTextFile({
  required String name,
  required String content,
  String contentType = 'application/json',
}) {
  throw UnsupportedError(
    'Das Herunterladen ist derzeit nur im Browser möglich.',
  );
}

/// Siehe `save_file.dart`.
Future<void> openBytesInNewTab(List<int> bytes, {required String mimeType}) {
  throw UnsupportedError('Das Öffnen ist derzeit nur im Browser möglich.');
}
