/// Die Definition ist ungültig.
///
/// Wird ausschließlich beim **Laden** geworfen, nie zur Laufzeit im Formular.
/// Genau darum geht es: Ein Tippfehler in einer Bedingung soll auffliegen,
/// bevor ein Azubi vor dem Bildschirm sitzt, und nicht erst dann, wenn die
/// Bedingung zufällig zum ersten Mal ausgewertet wird.
class QuestionnaireFormatException implements Exception {
  /// Wo in der Definition, als Punktpfad: `questions[12].condition.all[0]`.
  final String path;

  final String message;

  const QuestionnaireFormatException(this.path, this.message);

  @override
  String toString() => 'Fragebogen-Definition ungültig bei "$path": $message';
}

/// Ein Stück JSON zusammen mit dem Pfad, unter dem es gefunden wurde.
///
/// Der Pfad wird nur für Fehlermeldungen mitgeführt. Ohne ihn lautet die
/// Meldung „Zeichenkette erwartet" und man sucht sie in 2000 Zeilen JSON.
class JsonNode {
  final Object? value;
  final String path;

  const JsonNode(this.value, this.path);

  /// Wurzelknoten einer Definition.
  const JsonNode.root(Object? value) : this(value, r'$');

  Never fail(String message) =>
      throw QuestionnaireFormatException(path, message);

  bool get exists => value != null;

  Map<String, Object?> get asMap {
    final v = value;
    if (v is Map) {
      return v.map((key, value) => MapEntry(key.toString(), value));
    }
    fail('Objekt erwartet, gefunden: ${_describe(v)}');
  }

  List<Object?> get asList {
    final v = value;
    if (v is List) return v;
    fail('Liste erwartet, gefunden: ${_describe(v)}');
  }

  String get asString {
    final v = value;
    if (v is String) return v;
    fail('Zeichenkette erwartet, gefunden: ${_describe(v)}');
  }

  int get asInt {
    final v = value;
    if (v is int) return v;
    if (v is double && v == v.roundToDouble()) return v.toInt();
    fail('Ganze Zahl erwartet, gefunden: ${_describe(v)}');
  }

  double get asDouble {
    final v = value;
    if (v is num) return v.toDouble();
    fail('Zahl erwartet, gefunden: ${_describe(v)}');
  }

  bool get asBool {
    final v = value;
    if (v is bool) return v;
    fail('Wahrheitswert erwartet, gefunden: ${_describe(v)}');
  }

  /// Kind unter [key]. Fehlt der Schlüssel, ist [JsonNode.exists] falsch —
  /// der Aufrufer entscheidet, ob das ein Fehler ist.
  ///
  /// Fehlt schon der Knoten selbst, ist auch sein Kind nicht da. Das ist kein
  /// Fehler: `visibility` und `quality` sind optionale Blöcke, und ihre Leser
  /// sollen sie durchgehen können, ohne vorher zu prüfen, ob es sie gibt.
  /// Wo das Fehlen ein Fehler ist, steht [require] davor.
  JsonNode child(String key) {
    if (!exists) return JsonNode(null, '$path.$key');
    return JsonNode(asMap[key], '$path.$key');
  }

  JsonNode at(int index) => JsonNode(asList[index], '$path[$index]');

  /// Alle Elemente einer Liste, jedes mit eigenem Pfad.
  ///
  /// Ein fehlender Schlüssel ergibt die leere Folge. Das ist gewollt: `options`
  /// und `modules` sind optional, und ein `exists`-Vorbehalt an jeder
  /// Aufrufstelle verdeckt nur, was hier einmal stehen kann. Wo das Fehlen ein
  /// Fehler ist, steht [require] davor.
  Iterable<JsonNode> get items sync* {
    if (!exists) return;
    final list = asList;
    for (var i = 0; i < list.length; i++) {
      yield JsonNode(list[i], '$path[$i]');
    }
  }

  /// Alle Einträge eines Objekts, jeder mit eigenem Pfad. Fehlt der Schlüssel,
  /// ist die Folge leer — wie bei [items].
  Iterable<MapEntry<String, JsonNode>> get entries sync* {
    if (!exists) return;
    for (final entry in asMap.entries) {
      yield MapEntry(entry.key, JsonNode(entry.value, '$path.${entry.key}'));
    }
  }

  /// Wie [child], aber wirft, wenn der Schlüssel fehlt.
  JsonNode require(String key) {
    final node = child(key);
    if (!node.exists) fail('Pflichtfeld "$key" fehlt.');
    return node;
  }

  String stringOr(String fallback) => exists ? asString : fallback;

  int intOr(int fallback) => exists ? asInt : fallback;

  double doubleOr(double fallback) => exists ? asDouble : fallback;

  bool boolOr(bool fallback) => exists ? asBool : fallback;

  List<String> get asStringList => [for (final item in items) item.asString];

  /// Rohwerte durchreichen, etwa für `config`. Der Inhalt wird nicht geprüft,
  /// weil er je Typkennung verschieden aussieht; zuständig ist das Widget.
  Map<String, Object?> get asRawMap => exists ? asMap : const {};

  static String _describe(Object? v) {
    if (v == null) return 'nichts';
    if (v is Map) return 'Objekt';
    if (v is List) return 'Liste';
    if (v is String) return 'Zeichenkette "$v"';
    return '${v.runtimeType} ($v)';
  }
}
