/// Eine Textdatei zum Herunterladen anbieten, je Plattform.
///
/// Auf Web ueber einen Blob und einen unsichtbaren Link. Auf allen anderen
/// Plattformen derzeit nicht verfuegbar, aus demselben Grund wie bei
/// `file_pick.dart`: Die App zielt zunaechst auf Web. Der Aufruf scheitert
/// dort mit klarer Meldung, statt einen halben Weg vorzutaeuschen.
library;

export 'save_file_stub.dart' if (dart.library.js_interop) 'save_file_web.dart';
