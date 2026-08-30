import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../data/models/passkey_credential.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_shell.dart';
import '../common/app_bar_widget.dart';

/// Verwaltung der registrierten Passkeys.
class PasskeyManageScreen extends ConsumerStatefulWidget {
  const PasskeyManageScreen({super.key});

  @override
  ConsumerState<PasskeyManageScreen> createState() =>
      _PasskeyManageScreenState();
}

class _PasskeyManageScreenState extends ConsumerState<PasskeyManageScreen> {
  final _nameCtrl = TextEditingController();

  List<PasskeyCredential>? _passkeys;
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _laden());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() aktion) async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await aktion();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _laden() => _run(() async {
        final liste = await ref.read(authRepositoryProvider).listPasskeys();
        if (mounted) setState(() => _passkeys = liste);
      });

  Future<void> _anlegen() => _run(() async {
        final name = _nameCtrl.text.trim();
        await ref.read(authRepositoryProvider).registerPasskey(
              name.isEmpty ? 'Dieses Gerät' : name,
            );
        _nameCtrl.clear();
        final liste = await ref.read(authRepositoryProvider).listPasskeys();
        if (mounted) setState(() => _passkeys = liste);
      });

  Future<void> _loeschen(PasskeyCredential passkey) => _run(() async {
        await ref.read(authRepositoryProvider).deletePasskey(passkey.id);
        final liste = await ref.read(authRepositoryProvider).listPasskeys();
        if (mounted) setState(() => _passkeys = liste);
      });

  @override
  Widget build(BuildContext context) {
    final unterstuetzt = ref.watch(passkeySupportProvider);
    final passkeys = _passkeys;

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Passkeys'),
      drawer: const KarrikoDrawer(),
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppLayout.s24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Passkeys',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppLayout.s16),
                const Text(
                  'Ein Passkey ersetzt dein Passwort durch Fingerabdruck, '
                  'Gesicht oder Geräte-PIN. Er lässt sich nicht abphishen, '
                  'weil er nur auf dieser Website funktioniert.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppLayout.s24),
                if (_error != null) ...[
                  LoginErrorBanner(_error!),
                  const SizedBox(height: AppLayout.s24),
                ],
                if (!unterstuetzt)
                  const _Hinweis(
                    'Dieser Browser unterstützt keine Passkeys. Nutze einen '
                    'aktuellen Chrome, Safari oder Firefox.',
                  )
                else ...[
                  _Anlegen(
                    controller: _nameCtrl,
                    isBusy: _isBusy,
                    onAnlegen: _anlegen,
                  ),
                  const SizedBox(height: AppLayout.s32),
                  if (passkeys == null)
                    const Center(child: CircularProgressIndicator())
                  else if (passkeys.isEmpty)
                    const _Hinweis(
                      'Noch kein Passkey eingerichtet. Solange schützt nur dein '
                      'Passwort das Konto.',
                    )
                  else
                    _Liste(
                      passkeys: passkeys,
                      isBusy: _isBusy,
                      onLoeschen: _loeschen,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Anlegen extends StatelessWidget {
  final TextEditingController controller;
  final bool isBusy;
  final VoidCallback onAnlegen;

  const _Anlegen({
    required this.controller,
    required this.isBusy,
    required this.onAnlegen,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Name für dieses Gerät',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'z. B. Laptop, Handy',
            ),
            onSubmitted: (_) => onAnlegen(),
          ),
          const SizedBox(height: AppLayout.s16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isBusy ? null : onAnlegen,
              icon: const Icon(Icons.fingerprint, size: 20),
              label: const Text('Passkey einrichten'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Liste extends StatelessWidget {
  final List<PasskeyCredential> passkeys;
  final bool isBusy;
  final ValueChanged<PasskeyCredential> onLoeschen;

  const _Liste({
    required this.passkeys,
    required this.isBusy,
    required this.onLoeschen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Eingerichtete Passkeys',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        for (final passkey in passkeys)
          Container(
            margin: const EdgeInsets.only(bottom: AppLayout.s8),
            padding: const EdgeInsets.all(AppLayout.s16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passkey.deviceName,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          'Eingerichtet am ${germanDate(passkey.createdAt)}',
                          if (passkey.lastUsedAt != null)
                            'zuletzt benutzt am '
                                '${germanDate(passkey.lastUsedAt!)}',
                          if (!passkey.backedUp) 'nur auf diesem Gerät',
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Der letzte Passkey bleibt loeschbar: Passwort und
                // Anmeldelink stehen weiter zur Verfuegung, niemand sperrt
                // sich damit aus.
                TextButton(
                  onPressed: isBusy ? null : () => onLoeschen(passkey),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: const Text('Entfernen'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Hinweis extends StatelessWidget {
  final String text;

  const _Hinweis(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
