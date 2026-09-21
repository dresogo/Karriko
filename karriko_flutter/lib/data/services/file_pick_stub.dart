/// Eine ausgewaehlte Datei.
class PickedFile {
  final String name;
  final List<int> bytes;
  final String? contentType;

  const PickedFile({
    required this.name,
    required this.bytes,
    this.contentType,
  });

  int get size => bytes.length;
}

/// Siehe `file_pick.dart` fuer die Begruendung.
Future<PickedFile?> pickFile({List<String> extensions = const []}) {
  throw UnsupportedError(
    'Das Hochladen eines Nachweises ist derzeit nur im Browser moeglich.',
  );
}
