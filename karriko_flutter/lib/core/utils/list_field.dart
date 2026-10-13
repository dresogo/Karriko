/// Zerlegt ein mehrzeiliges Feld in Aufzählungspunkte.
///
/// Eine Zeile ist ein Punkt. Leerzeilen und führende Aufzählungszeichen
/// (`-`, `•`, `*`) fallen weg, damit Einfügen aus einem Word-Dokument nicht
/// auffällt: Die Stellenseite setzt ihre eigenen Punkte davor.
List<String> splitListField(String text) => text
    .split('\n')
    .map((z) => z.replaceFirst(RegExp(r'^\s*[-•*]\s*'), '').trim())
    .where((z) => z.isNotEmpty)
    .toList();
