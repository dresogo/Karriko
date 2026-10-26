import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import 'login_shell.dart';

/// Passwort vergessen (Seiten-Tab 40): ein Feld, ein Button, immer dieselbe
/// Antwort, egal ob es zur Adresse ein Konto gibt (E-42).
///
/// Gilt für Azubis und Betriebe. `?zugang=betrieb` schaltet auf Sie und führt
/// zurück zum Betriebs-Login; den Anmeldelink gibt es nur für Azubis (E-40).
/// Die Adresse aus dem Login kommt als `extra` mit, nie in der URL.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isBusy = false;
  bool _verschickt = false;
  String? _error;
  bool _vorbefuellt = false;

  bool get _isBetrieb =>
      GoRouterState.of(context).uri.queryParameters['zugang'] == 'betrieb';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vorbefuellt) return;
    _vorbefuellt = true;
    final extra = GoRouterState.of(context).extra;
    if (extra is String) _emailCtrl.text = extra;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _senden() => ref
      .read(authRepositoryProvider)
      .resetPassword(_emailCtrl.text.trim(), betrieb: _isBetrieb);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await _senden();
      if (mounted) setState(() => _verschickt = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sie = _isBetrieb;
    final loginRoute = sie ? '/login/betrieb' : '/login/azubi';

    return LoginShell(
      appBarTitle: 'Passwort vergessen',
      eyebrow: 'PASSWORT',
      headline: 'Neues Passwort\nanfordern.',
      lede: sie
          ? 'Wir schicken Ihnen einen Link, mit dem Sie ein neues Passwort '
              'setzen.'
          : 'Wir schicken dir einen Link, mit dem du ein neues Passwort setzt.',
      aside: const LoginTrustNote(
        'Der Link gilt 60 Minuten und lässt sich nur einmal verwenden.',
      ),
      child: _verschickt
          ? _Postfach(
              email: _emailCtrl.text.trim(),
              sie: sie,
              loginRoute: loginRoute,
              onResend: _senden,
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    LoginErrorBanner(_error!),
                    const SizedBox(height: AppLayout.s24),
                  ],
                  LoginLabeledField(
                    label: 'E-Mail-Adresse',
                    field: TextFormField(
                      controller: _emailCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'name@beispiel.de',
                      ),
                      validator: Validators.email,
                      onFieldSubmitted: (_) {
                        if (!_isBusy) _submit();
                      },
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
                          : const Text('Link schicken'),
                    ),
                  ),
                  const SizedBox(height: AppLayout.s32),
                  const Divider(color: AppColors.line, height: 1),
                  const SizedBox(height: AppLayout.s16),
                  LoginWayLink(
                    label: 'Zurück zur Anmeldung',
                    icon: Icons.arrow_back,
                    onPressed: () => context.go(loginRoute),
                  ),
                  if (!sie)
                    LoginWayLink(
                      label: 'Ohne Passwort anmelden',
                      onPressed: () => context.go('/login/azubi/magic'),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Postfach-Zustand nach dem Versand. Der Satz bleibt im Konjunktiv, damit er
/// nicht verrät, ob es zur Adresse ein Konto gibt (E-42).
class _Postfach extends StatelessWidget {
  final String email;
  final bool sie;
  final String loginRoute;
  final Future<void> Function() onResend;

  const _Postfach({
    required this.email,
    required this.sie,
    required this.loginRoute,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sie ? 'Schauen Sie in Ihr Postfach.' : 'Schau in dein Postfach.',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Falls für '),
                TextSpan(
                  text: email,
                  style: const TextStyle(
                      color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text: ' ein Konto existiert, ist ein Link unterwegs. '
                      'Er gilt 60 Minuten.',
                ),
              ],
            ),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 16,
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          Text(
            sie
                ? 'Nichts angekommen? Sehen Sie im Spam-Ordner nach.'
                : 'Nichts angekommen? Sieh im Spam-Ordner nach.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppLayout.s24),
          LoginResendLink(label: 'Erneut senden', onResend: onResend),
          LoginWayLink(
            label: 'Zurück zur Anmeldung',
            icon: Icons.arrow_back,
            onPressed: () => context.go(loginRoute),
          ),
        ],
      ),
    );
  }
}
