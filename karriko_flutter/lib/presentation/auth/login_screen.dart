import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import 'login_shell.dart';

/// Zielgruppe der Anmeldemaske. Die Maske ist technisch identisch, unterscheidet
/// sich aber in Ansprache und Registrierungs-Link.
enum LoginRole { azubi, betrieb }

class LoginScreen extends ConsumerStatefulWidget {
  final LoginRole role;

  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  bool get _isBetrieb => widget.role == LoginRole.betrieb;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        // Signalisiert dem Passwortmanager, dass die Anmeldung erfolgreich war.
        TextInput.finishAutofillContext();
        final nextRoute =
            GoRouterState.of(context).uri.queryParameters['next'] ?? '/';
        context.go(next.isBetrieb ? '/betrieb-dashboard' : nextRoute);
      }
    });

    return LoginShell(
      appBarTitle: _isBetrieb ? 'Login Betrieb' : 'Login Azubi',
      eyebrow: _isBetrieb ? 'FÜR BETRIEBE' : 'FÜR AZUBIS',
      headline: _isBetrieb ? 'Betrieb\nanmelden.' : 'Azubi\nanmelden.',
      lede: _isBetrieb
          ? 'Melde dich an, um dein Unternehmensprofil zu pflegen und auf '
              'Bewertungen zu antworten.'
          : 'Melde dich an, um Bewertungen zu schreiben, Betriebe zu merken und '
              'dein Profil zu verwalten.',
      aside: const LoginTrustNote(
        'Geschützt durch Appwrite Auth · SSL-verschlüsselt',
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BackToChoice(isBetrieb: _isBetrieb),
              const SizedBox(height: AppLayout.s24),
              if (auth.error != null) ...[
                LoginErrorBanner(auth.error!),
                const SizedBox(height: AppLayout.s24),
              ],
              _LabeledField(
                label: 'E-Mail-Adresse',
                field: TextFormField(
                  controller: _emailCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email
                  ],
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText:
                        _isBetrieb ? 'name@betrieb.de' : 'name@beispiel.de',
                  ),
                  validator: Validators.email,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
              ),
              const SizedBox(height: AppLayout.s24),
              _LabeledField(
                label: 'Passwort',
                field: TextFormField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Dein Passwort',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.muted,
                      ),
                      tooltip: _obscurePassword
                          ? 'Passwort anzeigen'
                          : 'Passwort verbergen',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Passwort ist erforderlich'
                      : null,
                  onFieldSubmitted: (_) {
                    if (!auth.isLoading) _submit();
                  },
                ),
              ),
              const SizedBox(height: AppLayout.s16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: const Text('Passwort vergessen?'),
                ),
              ),
              const SizedBox(height: AppLayout.s24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Anmelden'),
                ),
              ),
              const SizedBox(height: AppLayout.s32),
              const Divider(color: AppColors.line, height: 1),
              const SizedBox(height: AppLayout.s24),
              Text(
                'Noch kein Konto?',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppLayout.s8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context
                      .go(_isBetrieb ? '/register/betrieb' : '/register/azubi'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: Text(
                    _isBetrieb
                        ? 'Betrieb registrieren'
                        : 'Als Azubi registrieren',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eingabefeld mit sichtbarem Label darüber – ein Platzhalter allein verschwindet
/// beim Tippen und taugt nicht als Beschriftung. [MergeSemantics] verbindet Label
/// und Feld zu einem Knoten, damit Screenreader den Namen korrekt vorlesen.
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget field;

  const _LabeledField({required this.label, required this.field});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          field,
        ],
      ),
    );
  }
}

class _BackToChoice extends StatelessWidget {
  final bool isBetrieb;

  const _BackToChoice({required this.isBetrieb});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.arrow_back, size: 16),
        label: Text(
          isBetrieb
              ? 'Kein Betrieb? Zugang wechseln'
              : 'Kein Azubi? Zugang wechseln',
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    );
  }
}
