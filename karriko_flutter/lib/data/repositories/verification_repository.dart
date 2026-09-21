import 'package:appwrite/appwrite.dart';

import '../../core/constants/questionnaire_constants.dart';
import '../services/appwrite_service.dart';

/// Laedt den Nachweis des Ausbildungsverhaeltnisses hoch.
///
/// Hintergrund: Nach der Hamburger Rechtsprechung muss ein bewerteter Betrieb
/// pruefen koennen, ob ueberhaupt ein geschaeftlicher Kontakt bestand;
/// geschwaerzte Unterlagen allein reichten dem OLG nicht. Ohne belastbaren
/// Verifikationsprozess ist jede kritische Bewertung loeschungsgefaehrdet —
/// und damit genau der Inhalt, fuer den Azubis die Plattform benutzen.
///
/// Der Bucket ist so eingerichtet, dass Clients **schreiben, aber nicht lesen**
/// duerfen. Wer hochlaedt, kann die Datei danach nicht wieder abrufen; sehen
/// kann sie nur das Team `moderators`. Der Dateiname enthaelt keinen Namen und
/// keine Kennung des Nutzers.
class VerificationRepository {
  Storage get _storage => Storage(AppwriteService.client);

  /// Gibt die Datei-Kennung zurueck, die mit der Einreichung mitgeschickt wird.
  Future<String> upload({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final file = await _storage.createFile(
      bucketId: QuestionnaireConstants.verificationBucket,
      fileId: ID.unique(),
      file: InputFile.fromBytes(
        bytes: bytes,
        filename: _entschaerft(filename),
        contentType: contentType,
      ),
      // Bewusst leer: Es gelten die Rechte des Buckets. Wuerde der Client hier
      // ein Leserecht fuer sich selbst setzen, haette er einen Weg, die Datei
      // spaeter wieder abzurufen — und damit einen Weg, sie einem Konto
      // zuzuordnen.
      permissions: const [],
    );
    return file.$id;
  }

  /// Nimmt dem Dateinamen alles, was ihn zuordenbar macht.
  ///
  /// Ein Upload heisst gern „Ausbildungsvertrag_Mustermann_Anna.pdf". Der Name
  /// steht in Appwrite im Klartext und waere damit genau die Angabe, die die
  /// Anonymitaetszusage ausschliesst.
  String _entschaerft(String filename) {
    final punkt = filename.lastIndexOf('.');
    final endung = punkt > 0 && punkt < filename.length - 1
        ? filename.substring(punkt + 1).toLowerCase()
        : 'bin';
    return 'nachweis.$endung';
  }
}
