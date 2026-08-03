import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../common/app_page.dart';

class AzubiProfileScreen extends ConsumerStatefulWidget {
  const AzubiProfileScreen({super.key});

  @override
  ConsumerState<AzubiProfileScreen> createState() => _AzubiProfileScreenState();
}

class _AzubiProfileScreenState extends ConsumerState<AzubiProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  bool _editing = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _resetFields();
  }

  void _resetFields() {
    final user = ref.read(authProvider).user;
    _firstNameCtrl.text = user?.firstName ?? '';
    _lastNameCtrl.text = user?.lastName ?? '';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).updateProfile(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
        );
    if (!mounted) return;
    final failed = ref.read(authProvider).error != null;
    setState(() {
      _editing = failed;
      _saved = !failed;
    });
  }

  void _cancel() {
    // Verworfene Eingaben zurücksetzen, sonst stehen sie beim naechsten
    // Bearbeiten wieder da.
    _resetFields();
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return AppPage(
      appBarTitle: 'Mein Profil',
      eyebrow: 'MEIN PROFIL',
      title: user?.displayName ?? 'Profil',
      lede: user?.email,
      headerAction: _editing
          ? null
          : OutlinedButton.icon(
              onPressed: () => setState(() {
                _editing = true;
                _saved = false;
              }),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Bearbeiten'),
            ),
      children: [
        if (_saved) ...[
          const _SavedBanner(),
          const SizedBox(height: AppLayout.s24),
        ],
        if (auth.error != null) ...[
          _ErrorBanner(auth.error!),
          const SizedBox(height: AppLayout.s24),
        ],
        const SectionLabel('Profildaten'),
        const SizedBox(height: AppLayout.s16),
        if (_editing)
          _EditForm(
            formKey: _formKey,
            firstNameCtrl: _firstNameCtrl,
            lastNameCtrl: _lastNameCtrl,
            isSaving: auth.isLoading,
            onCancel: _cancel,
            onSave: _save,
          )
        else
          AppRowGroup(
            children: [
              AppRow(
                icon: Icons.badge_outlined,
                title: 'Vorname',
                value: user?.firstName?.isNotEmpty == true
                    ? user!.firstName!
                    : '–',
              ),
              AppRow(
                icon: Icons.badge_outlined,
                title: 'Nachname',
                value:
                    user?.lastName?.isNotEmpty == true ? user!.lastName! : '–',
              ),
              AppRow(
                icon: Icons.mail_outline,
                title: 'E-Mail',
                value: user?.email ?? '–',
              ),
            ],
          ),
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Konto'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.verified_outlined,
              title: 'E-Mail bestätigt',
              value: (user?.emailVerified ?? false) ? 'Ja' : 'Nein',
              subtitle: (user?.emailVerified ?? false)
                  ? null
                  : 'Bestätige deine Adresse, um alle Bereiche zu nutzen.',
              onTap: (user?.emailVerified ?? false)
                  ? null
                  : () => context.go('/verify-email'),
            ),
            AppRow(
              icon: Icons.school_outlined,
              title: 'Rolle',
              value: (user?.isBetrieb ?? false) ? 'Betrieb' : 'Azubi',
            ),
            if (user != null)
              AppRow(
                icon: Icons.event_outlined,
                title: 'Mitglied seit',
                value: germanDate(user.createdAt),
              ),
          ],
        ),
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Weiter zu'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.rate_review_outlined,
              title: 'Meine Bewertungen',
              onTap: () => context.go('/my-reviews'),
            ),
            AppRow(
              icon: Icons.tune,
              title: 'Einstellungen',
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _EditForm({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(
              label: 'Vorname',
              controller: firstNameCtrl,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppLayout.s24),
            _Field(
              label: 'Nachname',
              controller: lastNameCtrl,
              textInputAction: TextInputAction.done,
              onSubmitted: isSaving ? null : onSave,
            ),
            const SizedBox(height: AppLayout.s32),
            // Umbruchfaehig statt zwei feste Haelften – bei grosser Schrift
            // passen die Beschriftungen sonst nicht nebeneinander.
            Wrap(
              spacing: AppLayout.s16,
              runSpacing: AppLayout.s16,
              children: [
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: isSaving ? null : onCancel,
                    child: const Text('Abbrechen'),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : onSave,
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Speichern'),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  const _Field({
    required this.label,
    required this.controller,
    required this.textInputAction,
    this.onSubmitted,
  });

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
          TextFormField(
            controller: controller,
            textInputAction: textInputAction,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
            validator: (v) => Validators.required(v, label: label),
            onFieldSubmitted:
                onSubmitted == null ? null : (_) => onSubmitted!(),
          ),
        ],
      ),
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppLayout.s16),
        decoration: const BoxDecoration(
          color: AppColors.audienceBeige,
          border: Border(left: BorderSide(color: AppColors.green, width: 3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check, size: 18, color: AppColors.green),
            const SizedBox(width: AppLayout.s8),
            Expanded(
              child: Text(
                'Profil gespeichert.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppLayout.s16),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline,
                size: 18, color: AppColors.accentDark),
            const SizedBox(width: AppLayout.s8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
