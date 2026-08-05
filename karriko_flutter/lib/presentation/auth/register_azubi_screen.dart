import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import 'widgets/social_sign_in_buttons.dart';

class RegisterAzubiScreen extends ConsumerStatefulWidget {
  const RegisterAzubiScreen({super.key});

  @override
  ConsumerState<RegisterAzubiScreen> createState() =>
      _RegisterAzubiScreenState();
}

class _RegisterAzubiScreenState extends ConsumerState<RegisterAzubiScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;

  /// Reihenfolge: Zugangsdaten zuerst. Dort stehen auch die Wege ohne Passwort
  /// – wer sie nimmt, soll nicht erst zwei Schritte ausfuellen muessen, die
  /// danach hinfaellig sind.
  final _zugangKey = GlobalKey<FormState>();
  final _personKey = GlobalKey<FormState>();
  final _ausbildungKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _cityCtrl.dispose();
    _professionCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final valid = switch (_step) {
      0 => _zugangKey.currentState!.validate(),
      1 => _personKey.currentState!.validate(),
      _ => false,
    };
    if (!valid) return;
    setState(() => _step++);
    _pageCtrl.animateToPage(_step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageCtrl.animateToPage(_step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    if (!_ausbildungKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte stimme den AGB zu.')));
      return;
    }
    await ref.read(authProvider.notifier).registerAzubi(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          profession: _professionCtrl.text.trim().isEmpty
              ? null
              : _professionCtrl.text.trim(),
          city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next.isAuthenticated) context.go('/verify-email');
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Text('Als Azubi registrieren',
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 24),
                  _StepIndicator(current: _step, total: 3),
                  const SizedBox(height: 32),
                  Container(
                    // Feste Hoehe, damit der Wechsel zwischen den Schritten
                    // nicht springt. Der Inhalt jedes Schritts scrollt darin –
                    // sonst laeuft der laengste Schritt auf schmalen Fenstern
                    // ueber, was hier frueher der Fall war.
                    height: 520,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StepZugang(
                          formKey: _zugangKey,
                          emailCtrl: _emailCtrl,
                          passwordCtrl: _passwordCtrl,
                          confirmCtrl: _confirmCtrl,
                          obscurePassword: _obscurePassword,
                          obscureConfirm: _obscureConfirm,
                          onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onToggleConfirm: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          onNext: _next,
                          error: auth.error,
                        ),
                        _StepPersonal(
                          formKey: _personKey,
                          firstNameCtrl: _firstNameCtrl,
                          lastNameCtrl: _lastNameCtrl,
                          onNext: _next,
                          onBack: _back,
                        ),
                        _StepAusbildung(
                          formKey: _ausbildungKey,
                          professionCtrl: _professionCtrl,
                          cityCtrl: _cityCtrl,
                          agreeTerms: _agreeTerms,
                          onAgreeChanged: (v) =>
                              setState(() => _agreeTerms = v ?? false),
                          onBack: _back,
                          onSubmit: _submit,
                          isLoading: auth.isLoading,
                          error: auth.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Wrap statt Row: Auf schmalen Fenstern und bei vergroesserter
                  // Systemschrift bricht die Zeile um, statt ueberzulaufen.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Bereits ein Konto? ',
                          style: Theme.of(context).textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text('Anmelden',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gemeinsames Geruest eines Schritts.
///
/// Der Inhalt scrollt innerhalb der festen Hoehe des Rahmens. Frueher stand
/// hier eine Column mit `Spacer`, die den laengsten Schritt auf schmalen
/// Fenstern ueberlaufen liess.
class _StepFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? error;
  final List<Widget> children;

  const _StepFrame({
    required this.title,
    this.subtitle,
    this.error,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          if (error != null) ...[
            Semantics(
              liveRegion: true,
              container: true,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(error!,
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// Schritt 1: Zugangsdaten — und die Wege, die ohne Passwort auskommen.
class _StepZugang extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onNext;
  final String? error;

  const _StepZugang({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onNext,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: _StepFrame(
        title: 'Zugangsdaten',
        error: error,
        children: [
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-Mail-Adresse'),
            validator: Validators.email,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passwordCtrl,
            obscureText: obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Passwort',
              suffixIcon: IconButton(
                icon: Icon(obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                tooltip: obscurePassword
                    ? 'Passwort anzeigen'
                    : 'Passwort verbergen',
                onPressed: onTogglePassword,
              ),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: confirmCtrl,
            obscureText: obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Passwort bestätigen',
              suffixIcon: IconButton(
                icon: Icon(obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                tooltip:
                    obscureConfirm ? 'Passwort anzeigen' : 'Passwort verbergen',
                onPressed: onToggleConfirm,
              ),
            ),
            validator: (v) => Validators.confirmPassword(v, passwordCtrl.text),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Weiter'),
            ),
          ),
          const SizedBox(height: 20),
          const _Trenner('oder ohne Passwort'),
          const SizedBox(height: 16),
          // Beide Wege legen bei unbekannter Adresse ein Konto an, taugen also
          // zum Registrieren. Ein Passkey braucht dagegen ein bestehendes
          // Konto – siehe den Hinweis unten.
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/login/azubi/magic'),
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text('E-Mail-Link', overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(height: 8),
          const SocialSignInButtons(),
          const SizedBox(height: 16),
          Text(
            'Einen Passkey richtest du nach der Registrierung in den '
            'Einstellungen ein – er gehört zu einem bestehenden Konto.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StepPersonal extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _StepPersonal({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: _StepFrame(
        title: 'Persönliche Daten',
        children: [
          TextFormField(
            controller: firstNameCtrl,
            autofillHints: const [AutofillHints.givenName],
            decoration: const InputDecoration(labelText: 'Vorname'),
            validator: (v) => Validators.required(v, label: 'Vorname'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: lastNameCtrl,
            autofillHints: const [AutofillHints.familyName],
            decoration: const InputDecoration(labelText: 'Nachname'),
            validator: (v) => Validators.required(v, label: 'Nachname'),
          ),
          const SizedBox(height: 24),
          _ZurueckWeiter(onBack: onBack, onNext: onNext),
        ],
      ),
    );
  }
}

class _StepAusbildung extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController professionCtrl;
  final TextEditingController cityCtrl;
  final bool agreeTerms;
  final ValueChanged<bool?> onAgreeChanged;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? error;

  const _StepAusbildung({
    required this.formKey,
    required this.professionCtrl,
    required this.cityCtrl,
    required this.agreeTerms,
    required this.onAgreeChanged,
    required this.onBack,
    required this.onSubmit,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: _StepFrame(
        title: 'Ausbildungsinfo',
        subtitle: 'Optional – hilft dir bei personalisierten Empfehlungen.',
        error: error,
        children: [
          TextFormField(
            controller: professionCtrl,
            decoration:
                const InputDecoration(labelText: 'Ausbildungsberuf (optional)'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: cityCtrl,
            decoration: const InputDecoration(labelText: 'Wohnort (optional)'),
          ),
          const SizedBox(height: 12),
          // Die Zustimmung steht bei der Schaltflaeche, die sie ausloest.
          CheckboxListTile(
            value: agreeTerms,
            onChanged: onAgreeChanged,
            contentPadding: EdgeInsets.zero,
            title: const Text(
                'Ich stimme den AGB und der Datenschutzerklärung zu.',
                style: TextStyle(fontSize: 12)),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                      onPressed: onBack, child: const Text('Zurück')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSubmit,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Registrieren'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZurueckWeiter extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _ZurueckWeiter({required this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child:
                OutlinedButton(onPressed: onBack, child: const Text('Zurück')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child:
                ElevatedButton(onPressed: onNext, child: const Text('Weiter')),
          ),
        ),
      ],
    );
  }
}

/// Haarlinie mit Beschriftung in der Mitte.
class _Trenner extends StatelessWidget {
  final String label;

  const _Trenner(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    const labels = ['Zugangsdaten', 'Persönliche Daten', 'Ausbildungsinfo'];
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        // Kreis und Verbindungslinie in einer eigenen Zeile, die Beschriftung
        // darunter ueber die volle Zellenbreite. Frueher stand die
        // Beschriftung neben der Linie in derselben Zeile – sie bekam dort
        // keine Breitenbegrenzung und lief je nach Wortlaenge ueber.
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done || active
                          ? AppColors.primary
                          : AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done || active
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color:
                                    active ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                  if (i < total - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: done ? AppColors.primary : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: active ? AppColors.primary : AppColors.textMuted,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
