import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;
import '../../core/constants/appwrite_constants.dart';
import '../models/question_model.dart';
import '../services/appwrite_service.dart';

/// Lädt den Fragenkatalog, den Azubis zu ihrem Betrieb beantworten.
///
/// Die Fragen liegen in der Appwrite-Collection `questions`. Solange diese noch
/// nicht befüllt ist, liefert [fetchQuestions] den unten hinterlegten
/// Standardkatalog zurück, damit die Seite bereits bedienbar ist.
class QuestionRepository {
  Databases get _db => Databases(AppwriteService.client);

  Future<List<QuestionModel>> fetchQuestions() async {
    try {
      final result = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.questionsCollection,
        queries: [Query.orderAsc('sort_order'), Query.limit(100)],
      );
      if (result.documents.isEmpty) return defaultQuestions;
      return result.documents
          .map((d) => QuestionModel.fromJson(_toMap(d)))
          .toList();
    } on AppwriteException {
      // Collection existiert noch nicht oder ist nicht lesbar.
      return defaultQuestions;
    }
  }

  Map<String, dynamic> _toMap(aw.Document doc) => {
        ...doc.data,
        '\$id': doc.$id,
      };

  /// Platzhalter-Katalog, bis die Fragen in der Datenbank gepflegt sind.
  static const defaultQuestions = <QuestionModel>[
    QuestionModel(
      id: 'default-1',
      category: 'Ausbildungsqualität',
      text: 'Wie gut werden dir die Ausbildungsinhalte vermittelt?',
      type: QuestionType.rating,
      isRequired: true,
      sortOrder: 1,
    ),
    QuestionModel(
      id: 'default-2',
      category: 'Ausbildungsqualität',
      text: 'Wird der Ausbildungsplan eingehalten?',
      type: QuestionType.yesNo,
      isRequired: true,
      sortOrder: 2,
    ),
    QuestionModel(
      id: 'default-3',
      category: 'Betreuung',
      text: 'Wie erreichbar ist deine Ausbilderin oder dein Ausbilder?',
      type: QuestionType.rating,
      isRequired: true,
      sortOrder: 3,
    ),
    QuestionModel(
      id: 'default-4',
      category: 'Betreuung',
      text: 'Bekommst du regelmäßig Feedback zu deiner Arbeit?',
      type: QuestionType.yesNo,
      isRequired: false,
      sortOrder: 4,
    ),
    QuestionModel(
      id: 'default-5',
      category: 'Arbeitsalltag',
      text: 'Wie bewertest du die Work-Life-Balance?',
      type: QuestionType.rating,
      isRequired: true,
      sortOrder: 5,
    ),
    QuestionModel(
      id: 'default-6',
      category: 'Arbeitsalltag',
      text: 'Werden Überstunden ausgeglichen?',
      type: QuestionType.yesNo,
      isRequired: false,
      sortOrder: 6,
    ),
    QuestionModel(
      id: 'default-7',
      category: 'Perspektive',
      text: 'Wie schätzt du deine Übernahmechancen ein?',
      type: QuestionType.rating,
      isRequired: false,
      sortOrder: 7,
    ),
    QuestionModel(
      id: 'default-8',
      category: 'Perspektive',
      text: 'Was sollte dein Betrieb an der Ausbildung verbessern?',
      hint: 'Beschreibe konkret, was dir fehlt oder gut gefällt.',
      type: QuestionType.text,
      isRequired: false,
      sortOrder: 8,
    ),
  ];
}
