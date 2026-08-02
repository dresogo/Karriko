import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../common/app_bar_widget.dart';

class BetriebProfileScreen extends ConsumerStatefulWidget {
  const BetriebProfileScreen({super.key});

  @override
  ConsumerState<BetriebProfileScreen> createState() => _BetriebProfileScreenState();
}

class _BetriebProfileScreenState extends ConsumerState<BetriebProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Musterbetrieb GmbH');
  final _descCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _industry;
  bool _editing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Unternehmensprofil'),
      drawer: const KarrikoDrawer(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Profildaten', style: Theme.of(context).textTheme.headlineSmall),
                      const Spacer(),
                      if (!_editing)
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Bearbeiten'),
                          onPressed: () => setState(() => _editing = true),
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
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Unternehmensname'),
                                validator: (v) => Validators.required(v, label: 'Name'),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descCtrl,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Beschreibung',
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _industry,
                                decoration: const InputDecoration(labelText: 'Branche'),
                                items: AppConstants.industries
                                    .where((i) => i != 'Alle Branchen')
                                    .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                                    .toList(),
                                onChanged: (v) => setState(() => _industry = v),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _cityCtrl,
                                decoration: const InputDecoration(labelText: 'Stadt'),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _websiteCtrl,
                                decoration: const InputDecoration(labelText: 'Website'),
                                validator: Validators.url,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => setState(() => _editing = false),
                                      child: const Text('Abbrechen'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() => _editing = false);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Profil gespeichert!')));
                                        }
                                      },
                                      child: const Text('Speichern'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            _InfoRow('Name', _nameCtrl.text.isNotEmpty ? _nameCtrl.text : '–'),
                            _InfoRow('Branche', _industry ?? '–'),
                            _InfoRow('Stadt', _cityCtrl.text.isNotEmpty ? _cityCtrl.text : '–'),
                            _InfoRow('Website', _websiteCtrl.text.isNotEmpty ? _websiteCtrl.text : '–'),
                            if (_descCtrl.text.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text('Beschreibung', style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 8),
                              Text(_descCtrl.text, style: Theme.of(context).textTheme.bodyLarge),
                            ],
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.business, size: 36, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Musterbetrieb GmbH', style: Theme.of(context).textTheme.headlineMedium),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text('Betrieb', style: TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ],
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
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
