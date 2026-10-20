import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../presentation/public/home_screen.dart';
import '../presentation/public/search_screen.dart';
import '../presentation/public/company_detail_screen.dart';
import '../presentation/public/job_detail_screen.dart';
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
import '../presentation/auth/mfa_challenge_screen.dart';
import '../presentation/azubi/account_deletion_screen.dart';
import '../presentation/auth/magic_link_screen.dart';
import '../presentation/auth/magic_link_callback_screen.dart';
import '../presentation/auth/oauth_callback_screen.dart';
import '../presentation/settings/mfa_setup_screen.dart';
import '../presentation/settings/passkey_manage_screen.dart';
import '../presentation/azubi/dashboard_screen.dart';
import '../presentation/azubi/profile_screen.dart';
import '../presentation/questionnaire/questionnaire_screen.dart';
import '../presentation/azubi/my_reviews_screen.dart';
import '../presentation/azubi/settings_screen.dart';
import '../presentation/betrieb/dashboard_screen.dart' as betrieb;
import '../presentation/betrieb/profile_screen.dart' as betrieb;
import '../presentation/betrieb/jobs_screen.dart';
import '../presentation/betrieb/reviews_screen.dart' as betrieb;
import '../presentation/betrieb/reports_screen.dart';
import '../presentation/betrieb/settings_screen.dart' as betrieb;
import '../presentation/admin/admin_screen.dart';
import '../presentation/public/not_found_screen.dart';
import '../presentation/planned/planned_catalog.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Bewusst kein ref.watch(authProvider): Das wuerde bei jeder Zustands-
  // aenderung einen neuen GoRouter erzeugen, und ein neuer Router faengt bei
  // initialLocation an. Der Navigationsstand ginge also bei jeder Anmeldung,
  // jedem Ladewechsel und jeder Fehlermeldung verloren. Die Neuberechnung der
  // Weiterleitung erledigt refreshListenable – dafuer ist es da.
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
        '/betrieb-stellen',
        '/betrieb-reviews',
        '/betrieb-bewerbungen',
        '/betrieb-einladen',
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

      // Callback-Routen sind vom Waechter vollstaendig ausgenommen, und zwar
      // noch vor der Ladepruefung. Sie tragen ein Einmal-Geheimnis in der Query
      // und navigieren selbst weiter, sobald sie es eingeloest haben. Jede
      // Weiterleitung von hier verschluckt das Geheimnis, bevor es benutzt
      // wurde – der Link waere dann verbraucht und die Anmeldung gescheitert.
      const callbackPaths = ['/auth/magic', '/auth/oauth'];
      if (callbackPaths.contains(path)) return null;

      // Reihenfolge der Tore: Laden -> zweiter Faktor -> beantragte Loeschung
      // -> E-Mail-Bestaetigung -> Rolle (E-3.11). Wer sie umstellt, baut sich eine Weiterleitungsschleife: die
      // spaeteren Tore setzen eine vollstaendige Sitzung voraus, die die
      // frueheren erst herstellen.
      if (auth.isLoading) return null;

      // Der Admin-Bereich meldet selbst an und prueft selbst die Teams. Er
      // steht in keiner der Listen oben: Ein Admin-Konto hat keine Rolle
      // 'betrieb', die Azubi-Regeln wuerden es also aufs Dashboard schicken.
      // Nur der zweite Faktor muss vorher erledigt sein.
      if (path == '/admin') {
        return auth.mfaRequired ? '/mfa-challenge' : null;
      }

      // Wie '/verify-email' ein Zwischenzustand mit eigener Seite. Stuende der
      // Pfad in authPaths, schickte ihn der Block dort aufs Dashboard, das den
      // Nutzer mangels vollstaendiger Sitzung sofort zurueckwirft.
      if (path == '/mfa-challenge') {
        if (auth.mfaRequired) return null;
        if (!auth.isAuthenticated) return '/login';
        return auth.isBetrieb ? '/betrieb-dashboard' : '/dashboard';
      }

      if (auth.mfaRequired) {
        // Oeffentliche Seiten bleiben erreichbar – wer mitten in der Anmeldung
        // steckt, darf trotzdem das Impressum lesen.
        if (isAuthPath ||
            isAzubiPath ||
            isBetriebPath ||
            path == '/verify-email') {
          return '/mfa-challenge';
        }
        return null;
      }

      // Beantragte Loeschung (T-2.8, E-50): Bis sie greift, gibt es fuer das
      // Konto nur die Seite zum Zuruecknehmen. Oeffentliche Seiten bleiben
      // erreichbar. Steht vor der E-Mail-Bestaetigung, weil auch ein nie
      // bestaetigtes Konto geloescht werden darf.
      if (path == '/konto-loeschung') {
        if (!auth.isAuthenticated) return '/login';
        if (auth.deletionPending) return null;
        return auth.isBetrieb ? '/betrieb-dashboard' : '/dashboard';
      }
      if (auth.deletionPending &&
          (isAuthPath ||
              isAzubiPath ||
              isBetriebPath ||
              path == '/verify-email')) {
        return '/konto-loeschung';
      }

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
      GoRoute(
          path: '/konto-loeschung',
          builder: (_, __) => const AccountDeletionScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(
          path: '/company/:slug',
          builder: (_, s) =>
              CompanyDetailScreen(slug: s.pathParameters['slug']!)),
      GoRoute(
          path: '/stellen/:id',
          builder: (_, s) => JobDetailScreen(id: s.pathParameters['id']!)),
      // Muss vor '/reviews/:id' stehen, sonst schluckt der Platzhalter '/reviews/new'.
      //
      // Der Betrieb steht als Query-Parameter, nicht im Pfad: Ohne ihn zeigt
      // der Bildschirm die Betriebsauswahl, und das ist derselbe Einstieg.
      // `src` markiert eine Einladung — spontane Bewertungen fallen
      // systematisch extremer aus als angeforderte.
      GoRoute(
          path: '/reviews/new',
          builder: (_, s) => QuestionnaireScreen(
                companyId: s.uri.queryParameters['company'],
                inviteSource: s.uri.queryParameters['src'],
              )),
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
      // Zwischenzustand der Anmeldung. Bewusst kein Eintrag in authPaths –
      // siehe den Sonderfall im redirect.
      GoRoute(
          path: '/mfa-challenge',
          builder: (_, __) => const MfaChallengeScreen()),
      // Anmeldung ohne Passwort. Der Anforderungspfad liegt unter '/login/' und
      // ist damit ueber den Praefixvergleich in authPaths bereits abgedeckt.
      GoRoute(
          path: '/login/azubi/magic',
          builder: (_, __) => const MagicLinkScreen()),
      // Callback mit Einmal-Geheimnis in der Query – vom Waechter ausgenommen.
      GoRoute(
          path: '/auth/magic',
          builder: (_, __) => const MagicLinkCallbackScreen()),
      GoRoute(
          path: '/auth/oauth', builder: (_, __) => const OAuthCallbackScreen()),
      GoRoute(
          path: '/dashboard', builder: (_, __) => const AzubiDashboardScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const AzubiProfileScreen()),
      // Der alte Fragenkatalog ist im Fragebogen aufgegangen. Die Route
      // bleibt als Weiterleitung stehen, damit Lesezeichen und der Verweis
      // aus dem Azubi-Dashboard nicht ins Leere laufen.
      GoRoute(path: '/fragen-bewerten', redirect: (_, __) => '/reviews/new'),
      GoRoute(path: '/my-reviews', builder: (_, __) => const MyReviewsScreen()),
      // Die Merkliste laesst sich noch nicht fuellen, es gibt keinen
      // Merken-Knopf (E-30, T-6.23).
      GoRoute(path: '/bookmarks', redirect: (_, __) => '/dashboard'),
      // Benachrichtigungen gibt es noch nicht: keine Tabelle, nichts erzeugt
      // sie (E-30, T-2.13). Alte Lesezeichen landen auf dem Dashboard.
      GoRoute(path: '/notifications', redirect: (_, __) => '/dashboard'),
      GoRoute(
          path: '/settings', builder: (_, __) => const AzubiSettingsScreen()),
      // Ueber den Praefixvergleich in azubiPaths bereits geschuetzt.
      GoRoute(
          path: '/settings/mfa',
          builder: (_, __) => const MfaSetupScreen(settingsPath: '/settings')),
      GoRoute(
          path: '/settings/passkeys',
          builder: (_, __) => const PasskeyManageScreen()),
      GoRoute(
          path: '/betrieb-dashboard',
          builder: (_, __) => const betrieb.BetriebDashboardScreen()),
      GoRoute(
          path: '/betrieb-profile',
          builder: (_, __) => const betrieb.BetriebProfileScreen()),
      GoRoute(
          path: '/betrieb-stellen',
          builder: (_, __) => const BetriebJobsScreen()),
      GoRoute(
          path: '/betrieb-reviews',
          builder: (_, __) => const betrieb.BetriebReviewsScreen()),
      // Analytics, Team und Abonnement sind noch Attrappen ohne Datenquelle.
      // Bis sie echt sind, fuehren alte Links und Lesezeichen aufs Dashboard;
      // die Bildschirme liegen weiter unter presentation/betrieb/.
      for (final path in const ['/analytics', '/team', '/subscription'])
        GoRoute(path: path, redirect: (_, __) => '/betrieb-dashboard'),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(
          path: '/betrieb-settings',
          builder: (_, __) => const betrieb.BetriebSettingsScreen()),
      GoRoute(
          path: '/betrieb-settings/mfa',
          builder: (_, __) =>
              const MfaSetupScreen(settingsPath: '/betrieb-settings')),
      GoRoute(
          path: '/betrieb-settings/passkeys',
          builder: (_, __) => const PasskeyManageScreen()),
      // Bewusst ohne Verweis aus der Oberflaeche, nur ueber die Adresse.
      GoRoute(
          path: '/admin',
          builder: (_, s) =>
              AdminScreen(section: s.uri.queryParameters['bereich'])),
      // Grobgerueste der Seiten aus der Sitemap, die es noch nicht gibt. Nicht
      // verlinkt; geschuetzt sind sie ueber die Praefixe in den Listen oben.
      ...plannedRoutes(),
    ],
    errorBuilder: (_, state) => NotFoundScreen(uri: state.uri),
  );
});

/// Stoesst die Neuberechnung der Weiterleitung an, wenn sich der Anmeldezustand
/// aendert.
///
/// Das Abonnement wird **im Konstruktor** eingerichtet, nicht als `late final`
/// Feld. Ein `late final` wird erst beim ersten Lesen ausgewertet – und gelesen
/// wurde es nur in [dispose]. Das Abonnement kam damit nie zustande, der
/// Listener hat nie gefeuert, und die Weiterleitung wurde allein dadurch neu
/// berechnet, dass der Provider den ganzen Router neu baute.
class _AuthNotifierListenable extends ChangeNotifier {
  late final ProviderSubscription<AuthState> _sub;

  _AuthNotifierListenable(Ref ref) {
    _sub = ref.listen(authProvider, (_, __) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
