import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import 'login_shell.dart';

/// Anmeldung ohne Passwort: Der Nutzer bekommt einen Link per E-Mail.
///
/// Nur fuer Azubis. Betriebe melden sich mit E-Mail und Passwort an, weil ihr
/// Zugang eine menschliche Firmenpruefung voraussetzt.
class MagicLinkScreen extends ConsumerStatefulWidget {
  const MagicLinkScreen({super.key});

  @override
  ConsumerState<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends ConsumerState<MagicLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isBusy = false;
  bool _verschickt = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestMagicLink(
            _emailCtrl.text.trim(),
          );
      if (mounted) setState(() => _verschickt = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginShell(
      appBarTitle: 'Anmelden',
      eyebrow: 'OHNE PASSWORT',
      headline: 'Link statt\nPasswort.',
      lede: 'Wir schicken dir einen Anmeldelink per E-Mail. Ein Klick darauf, '
          'und du bist drin – kein Passwort nötig.',
      aside: const LoginTrustNote(
        'Der Link gilt eine Stunde und lässt sich nur einmal verwenden.',
      ),
      child: _verschickt
          ? _Bestaetigung(email: _emailCtrl.text.trim())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    LoginErrorBanner(_error!),
                    const SizedBox(height: AppLayout.s24),
                  ],
                  _LabeledField(
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
                      onFieldSubmitted: (_) => _submit(),
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
                          : const Text('Anmeldelink schicken'),
                    ),
                  ),
                  const SizedBox(height: AppLayout.s32),
                  const Divider(color: AppColors.line, height: 1),
                  const SizedBox(height: AppLayout.s24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.go('/login/azubi'),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Lieber mit Passwort anmelden'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Bestaetigung nach dem Versand.
///
/// Der Text ist bewusst gleich, egal ob zu der Adresse ein Konto existiert.
/// Alles andere waere ein Orakel, mit dem sich Konten aufzaehlen lassen
/// (notes/projekt-referenz.md Paragraf 3.2).
class _Bestaetigung extends StatelessWidget {
  final String email;

  const _Bestaetigung({required this.email});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              size: 40, color: AppColors.ink),
          const SizedBox(height: AppLayout.s16),
          const Text(
            'Schau in dein Postfach',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          Text(
            'Falls für $email ein Konto existiert, ist der Anmeldelink '
            'unterwegs. Er gilt eine Stunde.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 16,
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          const Text(
            'Nichts angekommen? Sieh im Spam-Ordner nach.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppLayout.s32),
          TextButton.icon(
            onPressed: () => context.go('/login/azubi'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Zurück zur Anmeldung'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ],
      ),
    );
  }
}

/// Eingabefeld mit sichtbarem Label darueber – gleiches Muster wie auf der
/// Anmeldeseite.
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
