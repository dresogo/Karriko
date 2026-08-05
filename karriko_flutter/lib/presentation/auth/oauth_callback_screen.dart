import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'login_shell.dart';

/// Nimmt die Rueckleitung eines Anbieters entgegen (Google, Apple).
///
/// Wie bei den Anmeldelinks laesst der Waechter diesen Pfad unberuehrt durch
/// (`callbackPaths`): `userId` und `secret` stehen in der Query, und jede
/// Weiterleitung von hier wuerde sie verschlucken, bevor sie eingeloest sind.
class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  ConsumerState<OAuthCallbackScreen> createState() =>
      _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  /// Ladezustand und Fehler liegen lokal, nicht im [AuthState] – siehe
  /// `magic_link_callback_screen.dart`.
  bool _isBusy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _einloesen());
  }

  Future<void> _einloesen() async {
    if (!mounted) return;
    final query = GoRouterState.of(context).uri.queryParameters;

    // Appwrite ruft die failure-Adresse mit '?error=1' auf, wenn der Anbieter
    // abgelehnt hat oder der Nutzer abgebrochen ist.
    if (query['error'] != null) {
      setState(() {
        _isBusy = false;
        _error = 'Die Anmeldung über den Anbieter wurde abgebrochen '
            'oder abgelehnt.';
      });
      return;
    }

    final userId = query['userId'];
    final secret = query['secret'];
    if (userId == null || secret == null) {
      setState(() {
        _isBusy = false;
        _error = 'Die Rückmeldung des Anbieters war unvollständig. '
            'Bitte versuche es erneut.';
      });
      return;
    }

    try {
      await ref.read(authProvider.notifier).completeOAuth(
            userId: userId,
            secret: secret,
          );
      if (!mounted) return;
      // `replace` statt `go`: Das Einmal-Geheimnis darf nicht im Verlauf
      // zurueckbleiben. Das Ziel bestimmt danach der Waechter.
      context.replace('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginShell(
      appBarTitle: 'Anmelden',
      eyebrow: 'ANMELDUNG',
      headline: _isBusy ? 'Einen\nMoment.' : 'Das hat\nnicht geklappt.',
      lede: _isBusy
          ? 'Wir schließen die Anmeldung ab.'
          : 'Die Anmeldung über den Anbieter ist nicht durchgegangen.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isBusy)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppLayout.s32),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            if (_error != null) ...[
              LoginErrorBanner(_error!),
              const SizedBox(height: AppLayout.s24),
            ],
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/login/azubi'),
                child: const Text('Zurück zur Anmeldung'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
