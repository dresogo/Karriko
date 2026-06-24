import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class RegisterAzubiScreen extends ConsumerStatefulWidget {
  const RegisterAzubiScreen({super.key});

  @override
  ConsumerState<RegisterAzubiScreen> createState() => _RegisterAzubiScreenState();
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

  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

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
      0 => _step0Key.currentState!.validate(),
      1 => _step1Key.currentState!.validate(),
      _ => false,
    };
    if (!valid) return;
    setState(() => _step++);
    _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    if (!_step2Key.currentState!.validate()) return;
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
      profession: _professionCtrl.text.trim().isEmpty ? null : _professionCtrl.text.trim(),
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
                  Text('Als Azubi registrieren', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 24),
                  _StepIndicator(current: _step, total: 3),
                  const SizedBox(height: 32),
                  Container(
                    height: 480,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StepPersonal(
                          formKey: _step0Key,
                          firstNameCtrl: _firstNameCtrl,
                          lastNameCtrl: _lastNameCtrl,
                          onNext: _next,
                        ),
                        _StepAusbildung(
                          formKey: _step1Key,
                          professionCtrl: _professionCtrl,
                          cityCtrl: _cityCtrl,
                          onNext: _next,
                          onBack: _back,
                        ),
                        _StepAccount(
                          formKey: _step2Key,
                          emailCtrl: _emailCtrl,
                          passwordCtrl: _passwordCtrl,
                          confirmCtrl: _confirmCtrl,
                          obscurePassword: _obscurePassword,
                          obscureConfirm: _obscureConfirm,
                          agreeTerms: _agreeTerms,
                          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          onAgreeChanged: (v) => setState(() => _agreeTerms = v ?? false),
                          onBack: _back,
                          onSubmit: _submit,
                          isLoading: auth.isLoading,
                          error: auth.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Bereits ein Konto? ', style: Theme.of(context).textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text('Anmelden',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
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

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final labels = ['Persönliche Daten', 'Ausbildungsinfo', 'Zugangsdaten'];
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done || active ? AppColors.primary : AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done || active ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: active ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: active ? AppColors.primary : AppColors.textMuted,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (i < total - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: done ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepPersonal extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final VoidCallback onNext;

  const _StepPersonal({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Persönliche Daten', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextFormField(
              controller: firstNameCtrl,
              decoration: const InputDecoration(labelText: 'Vorname'),
              validator: (v) => Validators.required(v, label: 'Vorname'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Nachname'),
              validator: (v) => Validators.required(v, label: 'Nachname'),
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Weiter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepAusbildung extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController professionCtrl;
  final TextEditingController cityCtrl;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _StepAusbildung({
    required this.formKey,
    required this.professionCtrl,
    required this.cityCtrl,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ausbildungsinfo', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Optional – hilft dir bei personalisierten Empfehlungen.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextFormField(
              controller: professionCtrl,
              decoration: const InputDecoration(labelText: 'Ausbildungsberuf (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'Wohnort (optional)'),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: onBack, child: const Text('Zurück')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(onPressed: onNext, child: const Text('Weiter')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepAccount extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool agreeTerms;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final ValueChanged<bool?> onAgreeChanged;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? error;

  const _StepAccount({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.agreeTerms,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onAgreeChanged,
    required this.onBack,
    required this.onSubmit,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Zugangsdaten', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-Mail-Adresse'),
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Passwort',
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
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
                  icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: onToggleConfirm,
                ),
              ),
              validator: (v) => Validators.confirmPassword(v, passwordCtrl.text),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: agreeTerms,
              onChanged: onAgreeChanged,
              contentPadding: EdgeInsets.zero,
              title: const Text('Ich stimme den AGB und der Datenschutzerklärung zu.',
                  style: TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Zurück'))),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSubmit,
                      child: isLoading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Registrieren'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
