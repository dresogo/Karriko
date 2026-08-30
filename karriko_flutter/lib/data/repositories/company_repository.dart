import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;
import '../../core/constants/appwrite_constants.dart';
import '../models/company_model.dart';
import '../services/appwrite_service.dart';

/// Bildet aus einem Firmennamen den Teil der oeffentlichen Adresse.
///
/// Bewusst als freie Funktion und nicht als Methode: So laesst sich die Regel
/// pruefen, ohne Appwrite zu brauchen – dasselbe Muster wie bei
/// `oauth2TokenUrl` in der Auth-Schicht.
///
/// Umlaute werden ausgeschrieben statt entfernt: aus "Müller GmbH" wird
/// `mueller-gmbh`, nicht `mller-gmbh`. Fuer den DACH-Markt ist das kein
/// Randfall, sondern der Normalfall.
String companySlug(String name) {
  final ersetzt = name.toLowerCase().replaceAllMapped(
        RegExp('[äöüßáàâéèêíìîóòôúùû]'),
        (m) => const {
          'ä': 'ae',
          'ö': 'oe',
          'ü': 'ue',
          'ß': 'ss',
          'á': 'a',
          'à': 'a',
          'â': 'a',
          'é': 'e',
          'è': 'e',
          'ê': 'e',
          'í': 'i',
          'ì': 'i',
          'î': 'i',
          'ó': 'o',
          'ò': 'o',
          'ô': 'o',
          'ú': 'u',
          'ù': 'u',
          'û': 'u',
        }[m[0]]!,
      );
  final slug = ersetzt
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  // Ein Name ganz ohne lateinische Buchstaben (etwa rein kyrillisch) ergaebe
  // sonst eine leere Adresse. Lieber ein neutraler Platzhalter, den der
  // Eindeutigkeits-Zusatz unterscheidbar macht.
  return slug.isEmpty ? 'unternehmen' : slug;
}

class CompanyRepository {
  TablesDB get _db => TablesDB(AppwriteService.client);

  Future<List<CompanyModel>> searchCompanies({
    String? query,
    String? industry,
    String? city,
    double? minRating,
    int limit = 20,
    int offset = 0,
  }) async {
    final queries = <String>[
      Query.orderDesc('average_rating'),
      Query.limit(limit),
      Query.offset(offset),
    ];
    if (query != null && query.isNotEmpty) {
      queries.add(Query.search('name', query));
    }
    if (industry != null && industry != 'Alle Branchen') {
      queries.add(Query.equal('industry', industry));
    }
    if (city != null && city.isNotEmpty) {
      queries.add(Query.search('city', city));
    }
    if (minRating != null) {
      queries.add(Query.greaterThanEqual('average_rating', minRating));
    }

    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      queries: queries,
    );
    return result.rows.map((d) => CompanyModel.fromJson(_toMap(d))).toList();
  }

  Future<CompanyModel> getCompanyBySlug(String slug) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      queries: [Query.equal('slug', slug), Query.limit(1)],
    );
    if (result.rows.isEmpty) throw Exception('Unternehmen nicht gefunden');
    return CompanyModel.fromJson(_toMap(result.rows.first));
  }

  Future<CompanyModel> getCompanyById(String id) async {
    final doc = await _db.getRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      rowId: id,
    );
    return CompanyModel.fromJson(_toMap(doc));
  }

  Future<List<CompanyModel>> getFeaturedCompanies({int limit = 6}) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      queries: [
        Query.equal('is_premium', true),
        Query.orderDesc('average_rating'),
        Query.limit(limit),
      ],
    );
    return result.rows.map((d) => CompanyModel.fromJson(_toMap(d))).toList();
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      queries: [Query.search('name', query), Query.limit(5)],
    );
    return result.rows.map((d) => d.data['name'] as String).toList();
  }

  /// Sucht das Unternehmen, das einem Konto gehoert.
  ///
  /// Gegenstueck zur Verknuepfung im Profil: Faellt die dort aus – etwa weil
  /// das Konto vor deren Einfuehrung entstand –, laesst sich das Unternehmen
  /// hierueber wiederfinden, statt ein zweites anzulegen.
  Future<CompanyModel?> findCompanyByOwner(String ownerId) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      queries: [Query.equal('owner_id', ownerId), Query.limit(1)],
    );
    if (result.rows.isEmpty) return null;
    return CompanyModel.fromJson(_toMap(result.rows.first));
  }

  /// Legt das Unternehmen zu einem Betriebskonto an.
  ///
  /// Rechte am Dokument:
  /// - **Lesen fuer alle.** Unternehmensprofile sind der oeffentliche Teil der
  ///   Plattform; ohne das faende die Suche sie fuer Besucher nicht.
  /// - **Schreiben nur fuer den Eigentuemer.**
  /// - **Kein Loeschrecht**, auch nicht fuer den Eigentuemer. Beim Loeschen
  ///   eines Betriebskontos bleiben die Bewertungen erhalten und das Profil
  ///   wird lediglich inaktiv (projekt-referenz.md Paragraf 3.4) – ein
  ///   Loeschrecht am Dokument wuerde genau das aushebeln.
  ///
  /// Das ersetzt keine serverseitige Regel: Dokumentrechte greifen erst,
  /// nachdem der Client sie gesetzt hat. Die tragende Grenze sind die
  /// Berechtigungen der Collection.
  Future<CompanyModel> createCompany({
    required String ownerId,
    required String name,
    String? industry,
    String? city,
  }) async {
    final row = await _db.createRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      rowId: ID.unique(),
      data: {
        'slug': await _freierSlug(name),
        'name': name,
        'owner_id': ownerId,
        if (industry != null) 'industry': industry,
        if (city != null) 'city': city,
        'review_count': 0,
        'is_premium': false,
        // Das Verifizierungs-Abzeichen vergibt ein Mensch, nicht die
        // Registrierung (projekt-referenz.md Paragraf 3.2).
        'is_verified': false,
      },
      permissions: [
        Permission.read(Role.any()),
        Permission.update(Role.user(ownerId)),
      ],
    );
    return CompanyModel.fromJson(_toMap(row));
  }

  /// Liefert einen Slug, der noch nicht vergeben ist.
  ///
  /// Zwei Betriebe mit demselben Namen sind im DACH-Raum keine Ausnahme.
  /// Kollidiert der Name, haengt ein kurzer Zusatz an. Das ist keine Garantie –
  /// zwischen Pruefung und Anlegen kann ein zweiter Client dazwischenkommen –
  /// aber gegen den realistischen Fall (gleicher Name, verschiedene Zeitpunkte)
  /// wirksam. Verbindlich waere nur ein eindeutiger Index auf `slug`.
  Future<String> _freierSlug(String name) async {
    final basis = companySlug(name);
    try {
      final vergeben = await _db.listRows(
        databaseId: AppwriteConstants.databaseId,
        tableId: AppwriteConstants.companiesCollection,
        queries: [Query.equal('slug', basis), Query.limit(1)],
      );
      if (vergeben.rows.isEmpty) return basis;
    } on AppwriteException {
      // Laesst sich die Kollision nicht pruefen, ist der Zusatz die sichere
      // Wahl: ein doppelter Slug waere schlimmer als ein haesslicher.
    }
    return '$basis-${ID.unique().substring(0, 6)}';
  }

  /// Aendert die Stammdaten eines Unternehmens.
  ///
  /// Der Slug bleibt dabei **unberuehrt**, auch wenn sich der Name aendert:
  /// Er steht in der oeffentlichen Adresse des Profils, und die soll nicht
  /// unter geteilten Links wegbrechen. Eine Umbenennung aendert die Anzeige,
  /// nicht die Adresse.
  Future<CompanyModel> updateCompanyProfile({
    required String companyId,
    String? name,
    String? description,
    String? website,
    String? logoUrl,
    String? city,
    String? country,
    String? industry,
  }) async {
    await _db.updateRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.companiesCollection,
      rowId: companyId,
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (website != null) 'website': website,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (industry != null) 'industry': industry,
      },
    );
    return getCompanyById(companyId);
  }

  Future<void> bookmarkCompany(String userId, String companyId) async {
    final existing = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    if (existing.rows.isNotEmpty) return;
    await _db.createRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      rowId: ID.unique(),
      data: {'user_id': userId, 'company_id': companyId},
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<void> removeBookmark(String userId, String companyId) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    if (result.rows.isEmpty) return;
    await _db.deleteRow(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      rowId: result.rows.first.$id,
    );
  }

  Future<List<CompanyModel>> getBookmarkedCompanies(String userId) async {
    final bookmarks = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      queries: [Query.equal('user_id', userId), Query.limit(100)],
    );
    final companies = await Future.wait(
      bookmarks.rows.map((b) => getCompanyById(b.data['company_id'] as String)),
    );
    return companies;
  }

  Future<bool> isBookmarked(String userId, String companyId) async {
    final result = await _db.listRows(
      databaseId: AppwriteConstants.databaseId,
      tableId: AppwriteConstants.bookmarksCollection,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('company_id', companyId),
        Query.limit(1),
      ],
    );
    return result.rows.isNotEmpty;
  }

  Map<String, dynamic> _toMap(aw.Row doc) => {
        'id': doc.$id,
        'created_at': doc.$createdAt,
        ...doc.data,
      };
}
