import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../common/app_bar_widget.dart';

class AzubiProfileScreen extends ConsumerStatefulWidget {
  const AzubiProfileScreen({super.key});

  @override
  ConsumerState<AzubiProfileScreen> createState() => _AzubiProfileScreenState();
}

class _AzubiProfileScreenState extends ConsumerState<AzubiProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameCtrl = TextEditingController();
  late final _lastNameCtrl = TextEditingController();
  bool _editing = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
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
    if (mounted) setState(() { _editing = false; _saved = true; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Mein Profil'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.lightGreen,
                    child: Text(
                      user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(color: AppColors.primaryDark, fontSize: 32, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.displayName ?? '', style: Theme.of(context).textTheme.headlineMedium),
                  Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text('Azubi', style: TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_saved) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    SizedBox(width: 8),
                    Text('Profil gespeichert!', style: TextStyle(color: AppColors.darkGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Text('Profildaten', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (!_editing)
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Bearbeiten'),
                    onPressed: () => setState(() { _editing = true; _saved = false; }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _editing
                ? Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstNameCtrl,
                          decoration: const InputDecoration(labelText: 'Vorname'),
                          validator: (v) => Validators.required(v, label: 'Vorname'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameCtrl,
                          decoration: const InputDecoration(labelText: 'Nachname'),
                          validator: (v) => Validators.required(v, label: 'Nachname'),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(
                              onPressed: () => setState(() => _editing = false),
                              child: const Text('Abbrechen'),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _save,
                              child: auth.isLoading
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Speichern'),
                            )),
                          ],
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _InfoRow('Vorname', user?.firstName ?? '–'),
                      _InfoRow('Nachname', user?.lastName ?? '–'),
                      _InfoRow('E-Mail', user?.email ?? '–'),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
