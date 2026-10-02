/// Auswahl einer Datei vom Geraet, je Plattform.
///
/// Auf Web ueber ein verstecktes `<input type="file">`. Auf allen anderen
/// Plattformen derzeit nicht verfuegbar: Dort braeuchte es einen nativen
/// Dateidialog, und die App zielt zunaechst auf Web (siehe README). Der Aufruf
/// scheitert dort mit klarer Meldung, statt einen halb funktionierenden Pfad
/// vorzutaeuschen — die Verifikation laesst sich dann spaeter im Browser
/// nachholen, die Bewertung geht auch ohne sie durch.
library;

export 'file_pick_stub.dart' if (dart.library.js_interop) 'file_pick_web.dart';
