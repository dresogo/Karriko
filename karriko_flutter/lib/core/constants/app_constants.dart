class AppConstants {
  static const appName = 'Karriko';
  static const appTagline =
      'Bewertungsplattform für duale Ausbildung im DACH-Markt';

  static const appwriteProjectIdEnvKey = 'APPWRITE_PROJECT_ID';

  static const roleAzubi = 'azubi';
  static const roleBetrieb = 'betrieb';

  static const List<String> industries = [
    'Alle Branchen',
    'Handwerk',
    'Industrie',
    'IT & Technik',
    'Kaufmännisch',
    'Gesundheit & Pflege',
    'Gastronomie & Tourismus',
    'Bildung & Soziales',
    'Logistik & Transport',
    'Energie & Umwelt',
    'Medien & Kreatives',
    'Banken & Versicherungen',
    'Chemie & Pharma',
    'Öffentlicher Dienst',
    'Sonstiges',
  ];

  static const List<String> countries = [
    'Deutschland',
    'Österreich',
    'Schweiz'
  ];

  static const maxRating = 5;
  static const reviewMinLength = 100;
  static const reviewMaxLength = 2000;

  static const pageSize = 20;
}
