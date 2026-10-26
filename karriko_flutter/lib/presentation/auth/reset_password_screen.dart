import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';
import 'login_shell.dart';

/// Ziel des Links aus der Reset-Mail (Seiten-Tab 41): `userId` und `secret`
/// stehen in der Query und werden mit dem neuen Passwort eingelöst. Eine
/// Sitzung braucht es dafür nicht; danach enden alle anderen (E-3.12).
///
/// Der geheime Teil der Adresse erscheint nie auf der Seite (E-47).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

enum _Stand { formular, gespeichert, linkUngueltig }

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isBusy = false;

  /// Ablehnung des Passworts durch den Server, steht direkt am Feld.
  String? _feldFehler;

  _Stand? _stand;

  Map<String, String> get _query =>
      GoRouterState.of(context).uri.queryParameters;

  bool get _isBetrieb => _query['zugang'] == 'betrieb';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ein Link ohne beide Teile lässt sich nicht einlösen; dieselbe Meldung
    // wie bei einem abgelaufenen.
    _stand ??= _query['userId'] == null || _query['secret'] == null
        ? _Stand.linkUngueltig
        : _Stand.formular;
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _feldFehler = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);
    try {
      await ref.read(authRepositoryProvider).completeRecovery(
            userId: _query['userId']!,
            secret: _query['secret']!,
            password: _passwordCtrl.text,
          );
      if (mounted) setState(() => _stand = _Stand.gespeichert);
    } on AuthLinkInvalid {
      if (mounted) setState(() => _stand = _Stand.linkUngueltig);
    } catch (e) {
      if (mounted) setState(() => _feldFehler = e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sie = _isBetrieb;
    final loginRoute = sie ? '/login/betrieb' : '/login/azubi';
    const minLen = Validators.passwordMinLength;

    return switch (_stand!) {
      _Stand.linkUngueltig => LoginShell(
          appBarTitle: 'Neues Passwort',
          eyebrow: 'PASSWORT',
          headline: 'Dieser Link\ngilt nicht mehr.',
          lede: sie
              ? 'Er ist abgelaufen, wurde schon benutzt oder ist unvollständig. '
                  'Fordern Sie einfach einen neuen an.'
              : 'Er ist abgelaufen, wurde schon benutzt oder ist unvollständig. '
                  'Fordere einfach einen neuen an.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go(sie
                      ? '/forgot-password?zugang=betrieb'
                      : '/forgot-password'),
                  child: const Text('Neuen Link anfordern'),
                ),
              ),
              const SizedBox(height: AppLayout.s16),
              LoginWayLink(
                label: 'Zur Anmeldung',
                icon: Icons.arrow_back,
                onPressed: () => context.go(loginRoute),
              ),
            ],
          ),
        ),
      _Stand.gespeichert => LoginShell(
          appBarTitle: 'Neues Passwort',
          eyebrow: 'PASSWORT',
          headline: sie
              ? 'Ihr Passwort\nist geändert.'
              : 'Dein Passwort\nist geändert.',
          lede: sie
              ? 'Auf allen anderen Geräten sind Sie jetzt abgemeldet.'
              : 'Auf allen anderen Geräten bist du jetzt abgemeldet.',
          child: Semantics(
            liveRegion: true,
            container: true,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go(loginRoute),
                child: const Text('Jetzt anmelden'),
              ),
            ),
          ),
        ),
      _Stand.formular => LoginShell(
          appBarTitle: 'Neues Passwort',
          eyebrow: 'PASSWORT',
          headline: 'Neues Passwort\nsetzen.',
          lede: 'Mindestens $minLen Zeichen. Ein Satz aus mehreren Wörtern '
              'ist leicht zu merken und schwer zu erraten.',
          aside: const LoginTrustNote(loginTrustText),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LoginLabeledField(
                    label: 'Neues Passwort',
                    field: TextFormField(
                      controller: _passwordCtrl,
                      autofocus: true,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        errorText: _feldFehler,
                        errorMaxLines: 3,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.muted,
                          ),
                          tooltip: _obscure
                              ? 'Passwort anzeigen'
                              : 'Passwort verbergen',
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                      onFieldSubmitted: (_) {
                        if (!_isBusy) _submit();
                      },
                    ),
                  ),
                  const SizedBox(height: AppLayout.s8),
                  Text(
                    sie
                        ? 'Danach werden Sie auf allen anderen Geräten '
                            'abgemeldet.'
                        : 'Danach wirst du auf allen anderen Geräten abgemeldet.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppLayout.s24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _submit,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Passwort speichern'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    };
  }
}
