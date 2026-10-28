/// Prüfungen für Kennungen, die eine Einreichung mitbringt.
///
/// `submit_review` arbeitet mit dem Schlüssel der Function. Jede Kennung aus
/// dem Rumpf, mit der es etwas anfasst, muss deshalb vorher dem Aufrufer
/// zugeordnet werden — sonst handelt die Function mit ihren Rechten im Auftrag
/// von jemandem, der diese Rechte nicht hat.
library;

/// Ob der Entwurf mit den Daten [draftData] dem Aufrufer [userId] gehört
/// (T-2.41).
///
/// `null` heißt: Es gibt ihn nicht. Dann ist nichts zu löschen.
bool draftOwnedBy(Map<String, Object?>? draftData, String userId) =>
    draftData != null && draftData['user_id'] == userId;

/// Was mit einem mitgeschickten Nachweis geschehen darf (T-2.42).
enum VerificationFileCheck {
  /// Kein Nachweis mitgeschickt.
  none,

  /// Die Datei liegt im Bucket und hängt an keiner Bewertung.
  usable,

  /// Die Datei gibt es nicht (mehr).
  missing,

  /// Die Datei hängt schon an einer anderen Bewertung.
  alreadyUsed,
}

/// Bewertet einen mitgeschickten Nachweis.
///
/// Wer die Datei hochgeladen hat, lässt sich nicht prüfen, und das ist Absicht:
/// Nachweise tragen keine Rechte und keinen Namen, damit sie sich keinem Konto
/// zuordnen lassen (`VerificationRepository`). Was bleibt, reicht aber gegen
/// den Missbrauch: Eine fremde Datei, die schon an einer Bewertung hängt, lässt
/// sich nicht ein zweites Mal anhängen — und damit auch nicht über
/// `delete_review` oder `cleanup` der eigenen Bewertung löschen. Die Kennungen
/// sind zufällig; eine noch nicht eingereichte fremde Datei müsste man erraten.
VerificationFileCheck checkVerificationFile({
  required String? fileId,
  required bool exists,
  required bool usedByOtherReview,
}) {
  if (fileId == null || fileId.isEmpty) return VerificationFileCheck.none;
  if (!exists) return VerificationFileCheck.missing;
  if (usedByOtherReview) return VerificationFileCheck.alreadyUsed;
  return VerificationFileCheck.usable;
}
