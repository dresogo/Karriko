import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../presentation/public/home_screen.dart';
import '../presentation/public/search_screen.dart';
import '../presentation/public/company_detail_screen.dart';
import '../presentation/public/review_detail_screen.dart';
import '../presentation/public/fuer_betriebe_screen.dart';
import '../presentation/public/blog_screen.dart';
import '../presentation/public/blog_detail_screen.dart';
import '../presentation/public/ueber_uns_screen.dart';
import '../presentation/public/kontakt_screen.dart';
import '../presentation/public/legal/impressum_screen.dart';
import '../presentation/public/legal/datenschutz_screen.dart';
import '../presentation/public/legal/agb_screen.dart';
import '../presentation/public/faq_screen.dart';
import '../presentation/auth/login_choice_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_azubi_screen.dart';
import '../presentation/auth/register_betrieb_screen.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/auth/reset_password_screen.dart';
import '../presentation/auth/verify_email_screen.dart';
import '../presentation/azubi/dashboard_screen.dart';
import '../presentation/azubi/profile_screen.dart';
import '../presentation/azubi/new_review_screen.dart';
import '../presentation/azubi/fragen_bewerten_screen.dart';
import '../presentation/azubi/my_reviews_screen.dart';
import '../presentation/azubi/bookmarks_screen.dart';
import '../presentation/azubi/notifications_screen.dart';
import '../presentation/azubi/settings_screen.dart';
import '../presentation/betrieb/dashboard_screen.dart' as betrieb;
import '../presentation/betrieb/profile_screen.dart' as betrieb;
import '../presentation/betrieb/reviews_screen.dart' as betrieb;
import '../presentation/betrieb/analytics_screen.dart';
import '../presentation/betrieb/team_screen.dart';
import '../presentation/betrieb/subscription_screen.dart';
import '../presentation/betrieb/reports_screen.dart';
import '../presentation/betrieb/settings_screen.dart' as betrieb;

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthNotifierListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.uri.path;

      // '/verify-email' gehoert bewusst nicht hierher – siehe Sonderfall unten.
      const authPaths = [
        '/login',
        '/register',
        '/forgot-password',
        '/reset-password'
      ];
      const azubiPaths = [
        '/dashboard',
        '/profile',
        '/reviews/new',
        '/fragen-bewerten',
        '/my-reviews',
        '/bookmarks',
        '/notifications',
        '/settings'
      ];
      const betriebPaths = [
        '/betrieb-dashboard',
        '/betrieb-profile',
        '/betrieb-reviews',
        '/analytics',
        '/team',
        '/subscription',
        '/reports',
        '/betrieb-settings'
      ];

      bool isAuthPath =
          authPaths.any((p) => path == p || path.startsWith('$p/'));
      bool isAzubiPath =
          azubiPaths.any((p) => path == p || path.startsWith('$p/'));
      bool isBetriebPath =
          betriebPaths.any((p) => path == p || path.startsWith('$p/'));

      if (auth.isLoading) return null;

      // Die Bestaetigungsseite ist erst erledigt, wenn die Adresse bestaetigt
      // ist. Als gewoehnlicher Auth-Pfad behandelt, schickte sie jeden
      // angemeldeten Nutzer aufs Dashboard – das ihn mangels Bestaetigung
      // sofort zurueckwarf. Ergebnis war ein Hin und Her, bei dem weder
      // Dashboard, Profil noch Einstellungen erreichbar waren.
      if (path == '/verify-email') {
        if (!auth.isAuthenticated) return '/login';
        if (!auth.emailVerified) return null;
        return auth.isBetrieb ? '/betrieb-dashboard' : '/dashboard';
      }

      if (isAuthPath) {
        if (!auth.isAuthenticated) return null;
        return auth.isBetrieb ? '/betrieb-dashboard' : '/dashboard';
      }

      if (isAzubiPath || isBetriebPath) {
        if (!auth.isAuthenticated) {
          return '/login?next=${Uri.encodeComponent(path)}';
        }
        if (!auth.emailVerified) return '/verify-email';
        if (isAzubiPath && auth.isBetrieb) return '/betrieb-dashboard';
        if (isBetriebPath && auth.isAzubi) return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(
          path: '/company/:slug',
          builder: (_, s) =>
              CompanyDetailScreen(slug: s.pathParameters['slug']!)),
      // Muss vor '/reviews/:id' stehen, sonst schluckt der Platzhalter '/reviews/new'.
      GoRoute(
          path: '/reviews/new', builder: (_, __) => const NewReviewScreen()),
      GoRoute(
          path: '/reviews/:id',
          builder: (_, s) => ReviewDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(
          path: '/fuer-betriebe',
          builder: (_, __) => const FuerBetriebeScreen()),
      GoRoute(path: '/blog', builder: (_, __) => const BlogScreen()),
      GoRoute(
          path: '/blog/:slug',
          builder: (_, s) => BlogDetailScreen(slug: s.pathParameters['slug']!)),
      GoRoute(path: '/ueber-uns', builder: (_, __) => const UeberUnsScreen()),
      GoRoute(path: '/kontakt', builder: (_, __) => const KontaktScreen()),
      GoRoute(path: '/impressum', builder: (_, __) => const ImpressumScreen()),
      GoRoute(
          path: '/datenschutz', builder: (_, __) => const DatenschutzScreen()),
      GoRoute(path: '/agb', builder: (_, __) => const AgbScreen()),
      GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginChoiceScreen()),
      GoRoute(
          path: '/login/azubi',
          builder: (_, __) => const LoginScreen(role: LoginRole.azubi)),
      GoRoute(
          path: '/login/betrieb',
          builder: (_, __) => const LoginScreen(role: LoginRole.betrieb)),
      GoRoute(
          path: '/register/azubi',
          builder: (_, __) => const RegisterAzubiScreen()),
      GoRoute(
          path: '/register/betrieb',
          builder: (_, __) => const RegisterBetriebScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/reset-password',
          builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(
          path: '/verify-email', builder: (_, __) => const VerifyEmailScreen()),
      GoRoute(
          path: '/dashboard', builder: (_, __) => const AzubiDashboardScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const AzubiProfileScreen()),
      GoRoute(
          path: '/fragen-bewerten',
          builder: (_, __) => const FragenBewertenScreen()),
      GoRoute(path: '/my-reviews', builder: (_, __) => const MyReviewsScreen()),
      GoRoute(path: '/bookmarks', builder: (_, __) => const BookmarksScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: '/settings', builder: (_, __) => const AzubiSettingsScreen()),
      GoRoute(
          path: '/betrieb-dashboard',
          builder: (_, __) => const betrieb.BetriebDashboardScreen()),
      GoRoute(
          path: '/betrieb-profile',
          builder: (_, __) => const betrieb.BetriebProfileScreen()),
      GoRoute(
          path: '/betrieb-reviews',
          builder: (_, __) => const betrieb.BetriebReviewsScreen()),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/team', builder: (_, __) => const TeamScreen()),
      GoRoute(
          path: '/subscription',
          builder: (_, __) => const SubscriptionScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(
          path: '/betrieb-settings',
          builder: (_, __) => const betrieb.BetriebSettingsScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Seite nicht gefunden: ${state.uri}')),
    ),
  );
});

class _AuthNotifierListenable extends ChangeNotifier {
  final Ref _ref;
  late final _sub = _ref.listen(authProvider, (_, __) => notifyListeners());

  _AuthNotifierListenable(this._ref);

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
