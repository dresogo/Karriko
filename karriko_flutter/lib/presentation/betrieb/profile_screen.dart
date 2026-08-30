import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/company_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
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
  bool _saving = false;

  /// Stand, aus dem die Felder zuletzt befuellt wurden.
  ///
  /// Verhindert, dass ein erneutes Bauen die Eingaben ueberschreibt, waehrend
  /// der Nutzer tippt: Befuellt wird nur, wenn sich das Unternehmen tatsaechlich
  /// geaendert hat.
  String? _befuelltVon;

  void _befuellen(CompanyModel company) {
    _befuelltVon = company.id;
    _nameCtrl.text = company.name;
    _descCtrl.text = company.description ?? '';
    _websiteCtrl.text = company.website ?? '';
    _cityCtrl.text = company.city ?? '';
    _industry = company.industry;
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
    final company = ref.read(myCompanyProvider).valueOrNull;
    setState(() {
      if (company != null) _befuellen(company);
      _editing = false;
    });
  }

  Future<void> _save(CompanyModel company) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    String? fehler;
    try {
      await ref.read(companyRepositoryProvider).updateCompanyProfile(
            companyId: company.id,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            website: _websiteCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            industry: _industry,
          );
      // Der Provider haelt den Stand, aus dem die Felder befuellt werden. Ohne
      // das Verwerfen zeigte die Seite nach dem Speichern weiter die alten
      // Werte – genau die Art stiller Abweichung, die hier vorher stand.
      ref.invalidate(myCompanyProvider);
    } catch (e) {
      fehler = 'Die Änderungen konnten nicht gespeichert werden.';
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (fehler == null) _editing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        content: Text(
          fehler ?? 'Unternehmensprofil gespeichert.',
          style: const TextStyle(color: AppColors.paper),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final company = ref.watch(myCompanyProvider);

    // Befuellen gehoert nicht in den Bauvorgang, sondern daneben: setState
    // waehrend build ist verboten, und die Controller zu aendern waehrend das
    // Formular gebaut wird, verwirft die Eingabemarke.
    final geladen = company.valueOrNull;
    if (geladen != null && geladen.id != _befuelltVon && !_editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _befuellen(geladen));
      });
    }

    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : (geladen?.name ?? user?.companyName ?? '');

    return AppPage(
      appBarTitle: 'Unternehmensprofil',
      eyebrow: 'UNTERNEHMENSPROFIL',
      title: name.isNotEmpty ? name : 'Dein Unternehmen',
      lede: user?.email,
      headerAction: _editing || geladen == null
          ? null
          : OutlinedButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Bearbeiten'),
            ),
      children: [
        if (company.isLoading) ...[
          const _Ladehinweis(),
          const SizedBox(height: AppLayout.s32),
        ] else if (company.hasError) ...[
          const _Fehlerhinweis(),
          const SizedBox(height: AppLayout.s32),
        ],
        const SectionLabel('Unternehmensdaten'),
        const SizedBox(height: AppLayout.s16),
        if (_editing && geladen != null)
          _EditForm(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            descCtrl: _descCtrl,
            cityCtrl: _cityCtrl,
            websiteCtrl: _websiteCtrl,
            industry: _industry,
            saving: _saving,
            onIndustry: (v) => setState(() => _industry = v),
            onCancel: _cancel,
            onSave: () => _save(geladen),
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
  final bool saving;
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
    required this.saving,
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
                    onPressed: saving ? null : onCancel,
                    child: const Text('Abbrechen'),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : onSave,
                    child: Text(saving ? 'Wird gespeichert …' : 'Speichern'),
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

/// Gemeinsames Geruest der beiden Zustandshinweise.
class _Hinweis extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hinweis({required this.icon, required this.text});

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
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: AppLayout.s8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _Ladehinweis extends StatelessWidget {
  const _Ladehinweis();

  @override
  Widget build(BuildContext context) => const _Hinweis(
        icon: Icons.hourglass_empty,
        text: 'Die Unternehmensdaten werden geladen.',
      );
}

/// Der Unterschied zum frueheren Hinweis ist wesentlich: Hier steht, dass
/// gerade etwas **nicht** funktioniert – nicht, dass es nie vorgesehen war.
class _Fehlerhinweis extends StatelessWidget {
  const _Fehlerhinweis();

  @override
  Widget build(BuildContext context) => const _Hinweis(
        icon: Icons.error_outline,
        text: 'Die Unternehmensdaten konnten nicht geladen werden. '
            'Bearbeiten ist deshalb gerade nicht möglich.',
      );
}
