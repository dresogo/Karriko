import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'login_shell.dart';

/// Loest den Anmeldelink ein, auf den der Nutzer in seiner E-Mail geklickt hat.
///
/// Der Wächter im Router laesst diesen Pfad unberuehrt durch (`callbackPaths`).
/// Das ist notwendig: `userId` und `secret` stehen in der Query, und jede
/// Weiterleitung von hier wuerde sie verschlucken, bevor sie eingeloest sind –
/// der Link waere verbraucht und die Anmeldung gescheitert.
class MagicLinkCallbackScreen extends ConsumerStatefulWidget {
  const MagicLinkCallbackScreen({super.key});

  @override
  ConsumerState<MagicLinkCallbackScreen> createState() =>
      _MagicLinkCallbackScreenState();
}

class _MagicLinkCallbackScreenState
    extends ConsumerState<MagicLinkCallbackScreen> {
  /// Ladezustand und Fehler liegen hier statt im [AuthState]: an dem haengt der
  /// `refreshListenable` des Routers, und eine Aenderung waehrend go_router
  /// diese Route installiert, verwirft die laufende Navigation.
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
    final userId = query['userId'];
    final secret = query['secret'];

    if (userId == null || secret == null) {
      setState(() {
        _isBusy = false;
        _error = 'Dieser Link ist unvollständig. '
            'Fordere bitte einen neuen an.';
      });
      return;
    }

    try {
      await ref.read(authProvider.notifier).completeMagicLink(
            userId: userId,
            secret: secret,
          );
      if (!mounted) return;
      // `replace` statt `go`: Die Adresse mit dem Einmal-Geheimnis darf nicht
      // im Verlauf zurueckbleiben. Das Ziel bestimmt anschliessend der
      // Waechter – etwa wenn die Adresse noch bestaetigt werden muss.
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
          ? 'Wir prüfen deinen Anmeldelink.'
          : 'Der Link konnte nicht eingelöst werden.',
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
                onPressed: () => context.go('/login/azubi/magic'),
                child: const Text('Neuen Link anfordern'),
              ),
            ),
            const SizedBox(height: AppLayout.s8),
            TextButton(
              onPressed: () => context.go('/login/azubi'),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: const Text('Mit Passwort anmelden'),
            ),
          ],
        ],
      ),
    );
  }
}
