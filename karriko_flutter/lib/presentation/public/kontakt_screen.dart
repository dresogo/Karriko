import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

class KontaktScreen extends StatefulWidget {
  const KontaktScreen({super.key});

  @override
  State<KontaktScreen> createState() => _KontaktScreenState();
}

class _KontaktScreenState extends State<KontaktScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Kontakt'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kontakt', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text('Schreib uns – wir antworten innerhalb von 24 Stunden.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 32),
                  _sent
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle, size: 48, color: AppColors.success),
                              const SizedBox(height: 16),
                              Text('Nachricht gesendet!', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text('Wir melden uns bald bei dir.',
                                  style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Name'),
                                validator: (v) => Validators.required(v, label: 'Name'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'E-Mail-Adresse'),
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _subjectCtrl,
                                decoration: const InputDecoration(labelText: 'Betreff'),
                                validator: (v) => Validators.required(v, label: 'Betreff'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _messageCtrl,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Nachricht',
                                  alignLabelWithHint: true,
                                ),
                                validator: (v) => Validators.minLength(v, 20, label: 'Nachricht'),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  child: const Text('Nachricht senden'),
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 40),
                  Text('Alternativ erreichst du uns unter:', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  const _ContactInfo(icon: Icons.email_outlined, label: 'hallo@karriko.de'),
                  const SizedBox(height: 8),
                  const _ContactInfo(icon: Icons.location_on_outlined, label: 'Deutschland · DACH-Region'),
                ],
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
