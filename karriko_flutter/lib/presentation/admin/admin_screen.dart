import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/admin_repository.dart';
import '../../providers/auth_provider.dart';

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository());

/// Die Teams des angemeldeten Kontos. Hängt an der Nutzerkennung, damit ein
/// Kontowechsel nicht die Rollen des vorigen Kontos stehen lässt.
final adminRolesProvider = FutureProvider.autoDispose<AdminRoles>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  return ref.read(adminRepositoryProvider).loadRoles();
});

/// Interner Bereich unter `/admin`.
///
/// **Bewusst ohne Verweis aus der Oberfläche** — erreichbar nur über die
/// Adresse. Das ist kein Schutz, nur Ruhe: Geschützt sind die Aktionen durch
/// die Ausführungsrechte der Functions. Wer kein Mitglied von `admins` oder
/// `moderators` ist, sieht nach der Anmeldung nur „kein Zugang".
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    final Widget body;
    if (!auth.isAuthenticated) {
      body = const _AdminLogin();
    } else {
      body = ref.watch(adminRolesProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Hinweis(
              'Die Teams des Kontos ließen sich nicht lesen: $e',
              mitAbmelden: true,
            ),
            data: (rollen) => rollen.mayModerate
                ? _AdminPanel(rollen: rollen, email: auth.user!.email)
                : const _Hinweis(
                    'Kein Zugang. Dieses Konto ist weder im Team „admins" '
                    'noch in „moderators".',
                    mitAbmelden: true,
                  ),
          );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Karriko Admin'),
        automaticallyImplyLeading: false,
      ),
      body: body,
    );
  }
}

// ── Anmeldung ───────────────────────────────────────────────────────────────

class _AdminLogin extends ConsumerStatefulWidget {
  const _AdminLogin();

  @override
  ConsumerState<_AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends ConsumerState<_AdminLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (ref.read(authProvider).isAuthenticated) {
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return _Spalte(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Anmelden', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppLayout.s24),
              if (auth.error != null) ...[
                Text(auth.error!,
                    style: const TextStyle(color: AppColors.accentDark)),
                const SizedBox(height: AppLayout.s16),
              ],
              TextFormField(
                controller: _emailCtrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'E-Mail-Adresse'),
                validator: Validators.email,
              ),
              const SizedBox(height: AppLayout.s16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Passwort'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Passwort ist erforderlich' : null,
                onFieldSubmitted: (_) {
                  if (!auth.isLoading) _submit();
                },
              ),
              const SizedBox(height: AppLayout.s24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Anmelden'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bereich ─────────────────────────────────────────────────────────────────

class _AdminPanel extends StatelessWidget {
  final AdminRoles rollen;
  final String email;

  const _AdminPanel({required this.rollen, required this.email});

  @override
  Widget build(BuildContext context) {
    final rolle = rollen.isAdmin ? 'Admin' : 'Moderation';
    return _Spalte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('$email · $rolle',
                    style: const TextStyle(color: AppColors.muted)),
              ),
              const _AbmeldenKnopf(),
            ],
          ),
          const SizedBox(height: AppLayout.s24),
          const _ModerationKarte(),
          if (rollen.isAdmin) ...[
            const SizedBox(height: AppLayout.s24),
            const _NeuberechnungKarte(),
          ],
        ],
      ),
    );
  }
}

/// Nachweis-Angabe für die Freigabe. `unveraendert` schickt kein `verified`
/// mit — die Function lässt den bisherigen Stand dann stehen.
enum _Nachweis { unveraendert, belegt, nichtBelegt }

class _ModerationKarte extends ConsumerStatefulWidget {
  const _ModerationKarte();

  @override
  ConsumerState<_ModerationKarte> createState() => _ModerationKarteState();
}

class _ModerationKarteState extends ConsumerState<_ModerationKarte> {
  final _idCtrl = TextEditingController();
  final _grundCtrl = TextEditingController();
  _Nachweis _nachweis = _Nachweis.unveraendert;
  bool _laeuft = false;
  String? _ergebnis;
  bool _fehler = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _grundCtrl.dispose();
    super.dispose();
  }

  Future<void> _ausfuehren({required bool freigeben}) async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      setState(() {
        _ergebnis = 'Bewertungs-ID fehlt.';
        _fehler = true;
      });
      return;
    }
    final grund = _grundCtrl.text.trim();
    if (!freigeben && grund.isEmpty) {
      setState(() {
        _ergebnis = 'Eine Ablehnung braucht eine Begründung.';
        _fehler = true;
      });
      return;
    }

    setState(() => _laeuft = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      final antwort = freigeben
          ? await repo.approve(id,
              verified: switch (_nachweis) {
                _Nachweis.unveraendert => null,
                _Nachweis.belegt => true,
                _Nachweis.nichtBelegt => false,
              })
          : await repo.reject(id, grund);
      setState(() {
        _ergebnis = _formatieren(antwort);
        _fehler = false;
      });
    } catch (e) {
      setState(() {
        _ergebnis = e.toString();
        _fehler = true;
      });
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Karte(
      titel: 'Bewertung moderieren',
      hinweis: 'Offene Bewertungen stehen in der Appwrite-Console unter '
          'Databases → reviews mit Status „pending_moderation". '
          'Die Zeilen-ID hier eintragen.',
      children: [
        TextField(
          controller: _idCtrl,
          decoration: const InputDecoration(labelText: 'Bewertungs-ID'),
        ),
        const SizedBox(height: AppLayout.s16),
        DropdownButtonFormField<_Nachweis>(
          initialValue: _nachweis,
          decoration:
              const InputDecoration(labelText: 'Nachweis (bei Freigabe)'),
          items: const [
            DropdownMenuItem(
                value: _Nachweis.unveraendert, child: Text('Unverändert')),
            DropdownMenuItem(
                value: _Nachweis.belegt, child: Text('Geprüft und belegt')),
            DropdownMenuItem(
                value: _Nachweis.nichtBelegt, child: Text('Nicht belegt')),
          ],
          onChanged: (v) => setState(() => _nachweis = v ?? _nachweis),
        ),
        const SizedBox(height: AppLayout.s16),
        TextField(
          controller: _grundCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Begründung (Pflicht bei Ablehnung)',
            helperText:
                'Der Verfasser sieht die Begründung, nicht deinen Namen.',
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        Wrap(
          spacing: AppLayout.s8,
          runSpacing: AppLayout.s8,
          children: [
            ElevatedButton(
              onPressed: _laeuft ? null : () => _ausfuehren(freigeben: true),
              child: const Text('Freigeben'),
            ),
            OutlinedButton(
              onPressed: _laeuft ? null : () => _ausfuehren(freigeben: false),
              child: const Text('Ablehnen'),
            ),
          ],
        ),
        if (_laeuft) ...[
          const SizedBox(height: AppLayout.s16),
          const LinearProgressIndicator(),
        ],
        if (_ergebnis != null) ...[
          const SizedBox(height: AppLayout.s16),
          _Ausgabe(_ergebnis!, fehler: _fehler),
        ],
      ],
    );
  }
}

class _NeuberechnungKarte extends ConsumerStatefulWidget {
  const _NeuberechnungKarte();

  @override
  ConsumerState<_NeuberechnungKarte> createState() =>
      _NeuberechnungKarteState();
}

class _NeuberechnungKarteState extends ConsumerState<_NeuberechnungKarte> {
  final _versatzCtrl = TextEditingController(text: '0');
  bool _probelauf = true;
  bool _laeuft = false;
  String? _ergebnis;
  bool _fehler = false;

  @override
  void dispose() {
    _versatzCtrl.dispose();
    super.dispose();
  }

  Future<void> _starten() async {
    final versatz = int.tryParse(_versatzCtrl.text.trim()) ?? 0;
    setState(() => _laeuft = true);
    try {
      final antwort = await ref
          .read(adminRepositoryProvider)
          .recompute(offset: versatz, dryRun: _probelauf);
      setState(() {
        _ergebnis = _formatieren(antwort);
        _fehler = false;
        // Die nächste Etappe gleich vorbereiten.
        final weiter = antwort['next_offset'];
        if (weiter is num) _versatzCtrl.text = weiter.round().toString();
      });
    } catch (e) {
      setState(() {
        _ergebnis = e.toString();
        _fehler = true;
      });
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Karte(
      titel: 'Alle Bewertungen neu rechnen',
      hinweis: 'Läuft in Etappen von 100. Solange die Antwort „done: false" '
          'meldet, mit dem eingetragenen nächsten Versatz erneut starten. '
          'Erst als Probelauf.',
      children: [
        TextField(
          controller: _versatzCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Versatz (offset)'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _probelauf,
          onChanged: (v) => setState(() => _probelauf = v),
          title: const Text('Probelauf (dry_run)'),
          subtitle: const Text('Rechnet, schreibt aber nichts.'),
        ),
        const SizedBox(height: AppLayout.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: _laeuft ? null : _starten,
            child: Text(_probelauf ? 'Probelauf starten' : 'Neu rechnen'),
          ),
        ),
        if (_laeuft) ...[
          const SizedBox(height: AppLayout.s16),
          const LinearProgressIndicator(),
        ],
        if (_ergebnis != null) ...[
          const SizedBox(height: AppLayout.s16),
          _Ausgabe(_ergebnis!, fehler: _fehler),
        ],
      ],
    );
  }
}

// ── Bausteine ───────────────────────────────────────────────────────────────

String _formatieren(Map<String, Object?> antwort) =>
    const JsonEncoder.withIndent('  ').convert(antwort);

class _Spalte extends StatelessWidget {
  final Widget child;

  const _Spalte({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppLayout.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: child,
        ),
      ),
    );
  }
}

class _Karte extends StatelessWidget {
  final String titel;
  final String hinweis;
  final List<Widget> children;

  const _Karte({
    required this.titel,
    required this.hinweis,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppLayout.s8),
          Text(hinweis,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: AppLayout.s16),
          ...children,
        ],
      ),
    );
  }
}

class _Ausgabe extends StatelessWidget {
  final String text;
  final bool fehler;

  const _Ausgabe(this.text, {required this.fehler});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(
          left: BorderSide(
            color: fehler ? AppColors.accent : AppColors.line,
            width: 3,
          ),
        ),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: fehler ? AppColors.accentDark : AppColors.ink,
        ),
      ),
    );
  }
}

class _Hinweis extends StatelessWidget {
  final String text;
  final bool mitAbmelden;

  const _Hinweis(this.text, {this.mitAbmelden = false});

  @override
  Widget build(BuildContext context) {
    return _Spalte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (mitAbmelden) ...[
            const SizedBox(height: AppLayout.s16),
            const _AbmeldenKnopf(),
          ],
        ],
      ),
    );
  }
}

class _AbmeldenKnopf extends ConsumerWidget {
  const _AbmeldenKnopf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(authProvider.notifier).signOut(),
      child: const Text('Abmelden'),
    );
  }
}
