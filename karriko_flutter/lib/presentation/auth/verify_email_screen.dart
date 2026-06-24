import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/supabase_service.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _resent = false;
  bool _isResending = false;

  Future<void> _resend() async {
    final email = ref.read(authProvider).user?.email;
    if (email == null) return;
    setState(() => _isResending = true);
    try {
      await SupabaseService.resendVerificationEmail(email);
      if (mounted) setState(() { _isResending = false; _resent = true; });
    } catch (_) {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _checkVerification() async {
    await ref.read(authProvider.notifier).refresh();
    final auth = ref.read(authProvider);
    if (auth.emailVerified && mounted) {
      context.go(auth.isBetrieb ? '/betrieb-dashboard' : '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final email = auth.user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.email_outlined, size: 56, color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text('E-Mail bestätigen', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    'Wir haben eine Bestätigungs-E-Mail an\n$email\ngesendet. Bitte klicke auf den Link in der E-Mail.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _checkVerification,
                      child: const Text('Ich habe bestätigt'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_resent)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('E-Mail wurde erneut gesendet!',
                          style: TextStyle(color: AppColors.darkGreen, fontSize: 13)),
                    )
                  else
                    TextButton(
                      onPressed: _isResending ? null : _resend,
                      child: _isResending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('E-Mail erneut senden'),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).signOut();
                      context.go('/login');
                    },
                    child: const Text('Abmelden', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
