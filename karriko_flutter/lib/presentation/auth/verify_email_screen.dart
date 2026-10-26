import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';
import 'login_shell.dart';

/// E-Mail bestätigen (Seiten-Tab 42), in zwei Rollen:
///
/// * **Zwischenstopp** nach der Registrierung und Tor 4 im Wächter (E-3.11):
///   ohne bestätigte Adresse kein Bewerten (E-3.12).
/// * **Ziel des Bestätigungslinks**: Mit `userId` und `secret` in der Query
///   löst die Seite den Link ein. Der Wächter lässt diesen Aufruf unberührt
///   durch, sonst ginge das Geheimnis bei einer Weiterleitung verloren.
class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final userId = query['userId'];
    final secret = query['secret'];
    if (userId != null && secret != null) {
      return _LinkEinloesen(userId: userId, secret: secret);
    }
    return const _Warten();
  }
}

// ─── Zwischenstopp ───────────────────────────────────────────────────────────

class _Warten extends ConsumerStatefulWidget {
  const _Warten();

  @override
  ConsumerState<_Warten> createState() => _WartenState();
}

class _WartenState extends ConsumerState<_Warten> {
  late final AppLifecycleListener _lifecycle;
  bool _isChecking = false;
  bool _nochNicht = false;
  int _erneutGesendet = 0;

  @override
  void initState() {
    super.initState();
    // Kehrt man aus dem Postfach in den Tab zurück, prüft die Seite selbst.
    _lifecycle = AppLifecycleListener(onResume: () => _pruefen(still: true));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// [still]: beim automatischen Prüfen keine Meldung, wenn es noch nicht
  /// geklappt hat.
  Future<void> _pruefen({bool still = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      await ref.read(authProvider.notifier).refresh();
      final auth = ref.read(authProvider);
      if (!mounted) return;
      if (auth.emailVerified) {
        context.go(auth.isBetrieb ? '/betrieb-dashboard' : '/dashboard');
      } else if (!still) {
        setState(() => _nochNicht = true);
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _erneutSenden() async {
    await ref.read(authRepositoryProvider).resendVerificationEmail();
    if (mounted) setState(() => _erneutGesendet++);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final email = auth.user?.email ?? '';
    final sie = auth.isBetrieb;

    return LoginShell(
      appBarTitle: 'E-Mail bestätigen',
      eyebrow: 'FAST GESCHAFFT',
      headline: sie
          ? 'Bestätigen Sie\nIhre Adresse.'
          : 'Bestätige deine\nE-Mail-Adresse.',
      lede: sie
          ? 'Danach prüfen wir Ihren Betrieb. Bis dahin können Sie Ihr Profil '
              'pflegen.'
          : 'Ohne Bestätigung kannst du lesen, aber nicht bewerten.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Wir haben einen Link geschickt an',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 16,
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          // Groß, damit ein Tippfehler in der Adresse sofort auffällt.
          Text(
            email,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppLayout.s32),
          if (_nochNicht) ...[
            LoginErrorBanner(sie
                ? 'Die Adresse ist noch nicht bestätigt. Klicken Sie auf den '
                    'Link in der Mail.'
                : 'Die Adresse ist noch nicht bestätigt. Klick auf den Link '
                    'in der Mail.'),
            const SizedBox(height: AppLayout.s16),
          ],
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isChecking ? null : _pruefen,
              child: _isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Ich habe bestätigt'),
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          // Die erste Mail kann Tage alt sein (Rückkehr über den Wächter),
          // deshalb ohne Sperre am Anfang.
          LoginResendLink(
            label: 'E-Mail erneut senden',
            onResend: _erneutSenden,
            gesperrtAmAnfang: false,
          ),
          // Kommt nach zwei Versuchen nichts an, liegt es selten am Spamfilter.
          if (_erneutGesendet >= 2)
            Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.s8),
              child: Text(
                sie
                    ? 'Es kommt nichts an? Prüfen Sie den Spam-Ordner oder '
                        'schreiben Sie uns.'
                    : 'Es kommt nichts an? Prüf den Spam-Ordner oder schreib '
                        'uns.',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          if (_erneutGesendet >= 2)
            LoginWayLink(
              label: 'Zum Kontakt',
              onPressed: () => context.go('/kontakt'),
            ),
          LoginWayLink(
            label: 'Falsche Adresse? Abmelden und neu registrieren',
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

// ─── Bestätigungslink ────────────────────────────────────────────────────────

enum _Einloesung { pruefen, bestaetigt, fehler }

class _LinkEinloesen extends ConsumerStatefulWidget {
  final String userId;
  final String secret;

  const _LinkEinloesen({required this.userId, required this.secret});

  @override
  ConsumerState<_LinkEinloesen> createState() => _LinkEinloesenState();
}

class _LinkEinloesenState extends ConsumerState<_LinkEinloesen> {
  /// Wie lange die Bestätigung stehen bleibt, bevor es weitergeht.
  static const _pause = Duration(seconds: 2);

  _Einloesung _stand = _Einloesung.pruefen;
  String? _fehler;
  Timer? _weiter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _einloesen());
  }

  @override
  void dispose() {
    _weiter?.cancel();
    super.dispose();
  }

  Future<void> _einloesen() async {
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmEmail(userId: widget.userId, secret: widget.secret);
      // Den Zustand neu laden, damit der Wächter die bestätigte Adresse kennt.
      await ref.read(authProvider.notifier).refresh();
      if (!mounted) return;
      setState(() => _stand = _Einloesung.bestaetigt);
      _weiter = Timer(_pause, _weiterleiten);
    } on AuthLinkInvalid {
      if (mounted) setState(() => _stand = _Einloesung.fehler);
    } catch (e) {
      if (mounted) {
        setState(() {
          _stand = _Einloesung.fehler;
          _fehler = e.toString();
        });
      }
    }
  }

  /// `replace`, damit die Adresse mit dem Einmal-Geheimnis nicht im Verlauf
  /// bleibt. Das Ziel klärt der Wächter (Betrieb, nicht angemeldet).
  void _weiterleiten() {
    _weiter?.cancel();
    if (mounted) context.replace('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final angemeldet = ref.watch(authProvider).isAuthenticated;

    return switch (_stand) {
      _Einloesung.pruefen => const LoginShell(
          appBarTitle: 'E-Mail bestätigen',
          eyebrow: 'BESTÄTIGUNG',
          headline: 'Einen\nMoment.',
          lede: 'Wir prüfen den Bestätigungslink.',
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppLayout.s32),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      _Einloesung.bestaetigt => LoginShell(
          appBarTitle: 'E-Mail bestätigen',
          eyebrow: 'BESTÄTIGUNG',
          headline: 'Adresse\nbestätigt.',
          lede: 'Gleich geht es weiter.',
          child: Semantics(
            liveRegion: true,
            container: true,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _weiterleiten,
                child: const Text('Weiter'),
              ),
            ),
          ),
        ),
      _Einloesung.fehler => LoginShell(
          appBarTitle: 'E-Mail bestätigen',
          eyebrow: 'BESTÄTIGUNG',
          headline: 'Dieser Link\ngilt nicht mehr.',
          lede: 'Er ist abgelaufen, wurde schon benutzt oder ist '
              'unvollständig.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_fehler != null) ...[
                LoginErrorBanner(_fehler!),
                const SizedBox(height: AppLayout.s24),
              ],
              // Einen neuen Link verschickt nur ein angemeldetes Konto; der
              // Wächter führt von /verify-email aus zur Anmeldung.
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/verify-email'),
                  child: Text(angemeldet ? 'Neuen Link schicken' : 'Anmelden'),
                ),
              ),
            ],
          ),
        ),
    };
  }
}
