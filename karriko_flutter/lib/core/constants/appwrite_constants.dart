class AppwriteConstants {
  static const endpoint = 'https://cloud.appwrite.io/v1';

  // Set via --dart-define=APPWRITE_PROJECT_ID=xxx
  static const projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: 'YOUR_PROJECT_ID',
  );

  // Redirect URL after email verification (deep-link or web URL)
  static const verificationUrl = String.fromEnvironment(
    'APPWRITE_VERIFICATION_URL',
    defaultValue: 'http://localhost',
  );

  // Database & collection IDs (must match what you create in the Appwrite console)
  static const databaseId = 'karriko';
  static const profilesCollection = 'profiles';
  static const companiesCollection = 'companies';
  static const reviewsCollection = 'reviews';
  static const bookmarksCollection = 'bookmarks';
  static const reviewReportsCollection = 'review_reports';
}
