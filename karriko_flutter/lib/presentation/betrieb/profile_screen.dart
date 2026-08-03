import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../common/app_page.dart';

class BetriebProfileScreen extends ConsumerStatefulWidget {
  const BetriebProfileScreen({super.key});

  @override
  ConsumerState<BetriebProfileScreen> createState() =>
      _BetriebProfileScreenState();
}

class _BetriebProfileScreenState extends ConsumerState<BetriebProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _industry;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    // Echter Unternehmensname aus dem Konto statt eines erfundenen Beispiels.
    _nameCtrl.text = ref.read(authProvider).user?.companyName ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _cancel() {
    setState(() {
      _nameCtrl.text = ref.read(authProvider).user?.companyName ?? '';
      _editing = false;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _editing = false);

    // Bewusst keine Erfolgsmeldung: CompanyRepository.updateCompanyProfile wird
    // von hier noch nicht aufgerufen, weil dem Betriebskonto die Verknüpfung zu
    // einem companies-Dokument fehlt. Vorher stand hier „Profil gespeichert!",
    // ohne dass etwas gespeichert wurde.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 6),
        content: Text(
          'Das Speichern ist noch nicht angebunden – deine Eingaben gelten nur '
          'für diese Sitzung.',
          style: TextStyle(color: AppColors.paper),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = _nameCtrl.text.trim();

    return AppPage(
      appBarTitle: 'Unternehmensprofil',
      eyebrow: 'UNTERNEHMENSPROFIL',
      title: name.isNotEmpty ? name : 'Dein Unternehmen',
      lede: user?.email,
      headerAction: _editing
          ? null
          : OutlinedButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Bearbeiten'),
            ),
      children: [
        const _NotConnectedHint(),
        const SizedBox(height: AppLayout.s32),
        const SectionLabel('Unternehmensdaten'),
        const SizedBox(height: AppLayout.s16),
        if (_editing)
          _EditForm(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            descCtrl: _descCtrl,
            cityCtrl: _cityCtrl,
            websiteCtrl: _websiteCtrl,
            industry: _industry,
            onIndustry: (v) => setState(() => _industry = v),
            onCancel: _cancel,
            onSave: _save,
          )
        else ...[
          AppRowGroup(
            children: [
              AppRow(
                icon: Icons.business_outlined,
                title: 'Unternehmensname',
                value: name.isNotEmpty ? name : '–',
              ),
              AppRow(
                icon: Icons.category_outlined,
                title: 'Branche',
                value: _industry ?? '–',
              ),
              AppRow(
                icon: Icons.place_outlined,
                title: 'Standort',
                value: _cityCtrl.text.trim().isNotEmpty
                    ? _cityCtrl.text.trim()
                    : '–',
              ),
              AppRow(
                icon: Icons.link,
                title: 'Website',
                value: _websiteCtrl.text.trim().isNotEmpty
                    ? _websiteCtrl.text.trim()
                    : '–',
              ),
            ],
          ),
          const SizedBox(height: AppLayout.s32),
          const SectionLabel('Beschreibung'),
          const SizedBox(height: AppLayout.s16),
          AppCard(
            child: Text(
              _descCtrl.text.trim().isNotEmpty
                  ? _descCtrl.text.trim()
                  : 'Noch keine Beschreibung hinterlegt. Erzähl Azubis, was deine '
                      'Ausbildung ausmacht.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: _descCtrl.text.trim().isNotEmpty
                        ? AppColors.ink
                        : AppColors.muted,
                  ),
            ),
          ),
        ],
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Ansprechpartner'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.person_outline,
              title: 'Name',
              value: user?.fullName.isNotEmpty == true ? user!.fullName : '–',
            ),
            AppRow(
              icon: Icons.mail_outline,
              title: 'E-Mail',
              value: user?.email ?? '–',
            ),
            AppRow(
              icon: Icons.verified_outlined,
              title: 'E-Mail bestätigt',
              value: (user?.emailVerified ?? false) ? 'Ja' : 'Nein',
              onTap: (user?.emailVerified ?? false)
                  ? null
                  : () => context.go('/verify-email'),
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
              title: 'Bewertungen',
              onTap: () => context.go('/betrieb-reviews'),
            ),
            AppRow(
              icon: Icons.tune,
              title: 'Einstellungen',
              onTap: () => context.go('/betrieb-settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController websiteCtrl;
  final String? industry;
  final ValueChanged<String?> onIndustry;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _EditForm({
    required this.formKey,
    required this.nameCtrl,
    required this.descCtrl,
    required this.cityCtrl,
    required this.websiteCtrl,
    required this.industry,
    required this.onIndustry,
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
            _Labeled(
              label: 'Unternehmensname',
              child: TextFormField(
                controller: nameCtrl,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
                validator: (v) =>
                    Validators.required(v, label: 'Unternehmensname'),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            _Labeled(
              label: 'Beschreibung',
              child: TextFormField(
                controller: descCtrl,
                maxLines: 4,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
                decoration: const InputDecoration(
                  hintText: 'Was macht die Ausbildung bei euch aus?',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            _Labeled(
              label: 'Branche',
              child: DropdownButtonFormField<String>(
                initialValue: industry,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
                items: AppConstants.industries
                    .where((i) => i != 'Alle Branchen')
                    .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                    .toList(),
                onChanged: onIndustry,
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            _Labeled(
              label: 'Standort',
              child: TextFormField(
                controller: cityCtrl,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            _Labeled(
              label: 'Website',
              child: TextFormField(
                controller: websiteCtrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
                decoration: const InputDecoration(hintText: 'https://'),
                validator: Validators.url,
              ),
            ),
            const SizedBox(height: AppLayout.s32),
            Wrap(
              spacing: AppLayout.s16,
              runSpacing: AppLayout.s16,
              children: [
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Abbrechen'),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onSave,
                    child: const Text('Übernehmen'),
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

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;

  const _Labeled({required this.label, required this.child});

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
          child,
        ],
      ),
    );
  }
}

/// Macht transparent, dass die Unternehmensdaten noch nicht gespeichert werden.
class _NotConnectedHint extends StatelessWidget {
  const _NotConnectedHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(left: BorderSide(color: AppColors.line, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
          const SizedBox(width: AppLayout.s8),
          Expanded(
            child: Text(
              'Die Unternehmensdaten werden noch nicht dauerhaft gespeichert. '
              'Änderungen gelten nur für diese Sitzung.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
