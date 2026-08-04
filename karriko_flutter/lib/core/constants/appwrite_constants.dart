class AppwriteConstants {
  static const endpoint = 'https://cloud.appwrite.io/v1';

  static const projectId = '6a3c45ef003356d7f16d';

  // Redirect URL after email verification (deep-link or web URL)
  static const verificationUrl = String.fromEnvironment(
    'APPWRITE_VERIFICATION_URL',
    defaultValue: 'http://localhost',
  );

  // Database & collection IDs (must match what you create in the Appwrite console)
  static const databaseId = '6a3ea0a4002b4cf10630';
  static const profilesCollection = 'profiles';
  static const companiesCollection = 'companies';
  static const reviewsCollection = 'reviews';
  static const bookmarksCollection = 'bookmarks';
  static const reviewReportsCollection = 'review_reports';
  static const questionsCollection = 'questions';
  static const notificationsCollection = 'notifications';
}
