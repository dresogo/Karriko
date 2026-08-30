import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_shell.dart';
import '../common/app_bar_widget.dart';

/// Schritte der Einrichtung.
///
/// Die Reihenfolge ist bewusst festgelegt: die Wiederherstellungscodes kommen
/// **vor** dem Scharfschalten. Wer MFA aktiviert und danach den Zugriff auf die
/// App verliert, kaeme sonst nicht mehr an sein Konto.
enum _Step { intro, scan, recovery, done }

class MfaSetupScreen extends ConsumerStatefulWidget {
  /// Wohin "Fertig" zurueckfuehrt. Azubis und Betriebe haben getrennte
  /// Einstellungsseiten.
  final String settingsPath;

  const MfaSetupScreen({super.key, this.settingsPath = '/settings'});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  final _codeCtrl = TextEditingController();

  _Step _step = _Step.intro;
  bool _isBusy = false;
  String? _error;

  String? _secret;
  String? _otpauthUri;
  List<String> _recoveryCodes = const [];
  bool _codesGesichert = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _start() => _run(() async {
        final repo = ref.read(authRepositoryProvider);
        final enrollment = await repo.startTotpEnrollment();
        if (!mounted) return;
        setState(() {
          _secret = enrollment.secret;
          _otpauthUri = enrollment.uri;
          _step = _Step.scan;
        });
      });

  Future<void> _confirm() => _run(() async {
        final repo = ref.read(authRepositoryProvider);
        await repo.confirmTotpEnrollment(_codeCtrl.text.trim());
        final codes = await repo.createMfaRecoveryCodes();
        if (!mounted) return;
        setState(() {
          _recoveryCodes = codes;
          _step = _Step.recovery;
        });
      });

  Future<void> _activate() => _run(() async {
        final repo = ref.read(authRepositoryProvider);
        await repo.setMfaEnabled(true);
        await ref.read(authProvider.notifier).refresh();
        if (!mounted) return;
        setState(() => _step = _Step.done);
      });

  Future<void> _deactivate() => _run(() async {
        final repo = ref.read(authRepositoryProvider);
        // Erst abschalten, dann den Authenticator entfernen. Andersherum bliebe
        // ein Konto zurueck, das eine Bestaetigung verlangt, fuer die es kein
        // Verfahren mehr gibt.
        await repo.setMfaEnabled(false);
        await repo.deleteTotpAuthenticator();
        await ref.read(authProvider.notifier).refresh();
        if (!mounted) return;
        context.go(widget.settingsPath);
      });

  @override
  Widget build(BuildContext context) {
    final istAktiv = ref.watch(authProvider).user?.mfaEnabled ?? false;

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Zwei-Faktor-Bestätigung'),
      drawer: const KarrikoDrawer(),
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppLayout.s24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  LoginErrorBanner(_error!),
                  const SizedBox(height: AppLayout.s24),
                ],
                switch (_step) {
                  // Ist die Bestaetigung schon aktiv, waere die Einrichtung
                  // der falsche Einstieg – dann geht es nur noch ums Abschalten.
                  _Step.intro when istAktiv =>
                    _Active(isBusy: _isBusy, onDeactivate: _deactivate),
                  _Step.intro => _Intro(isBusy: _isBusy, onStart: _start),
                  _Step.scan => _Scan(
                      secret: _secret ?? '',
                      otpauthUri: _otpauthUri ?? '',
                      controller: _codeCtrl,
                      isBusy: _isBusy,
                      onConfirm: _confirm,
                    ),
                  _Step.recovery => _Recovery(
                      codes: _recoveryCodes,
                      gesichert: _codesGesichert,
                      isBusy: _isBusy,
                      onGesichert: (v) =>
                          setState(() => _codesGesichert = v ?? false),
                      onActivate: _activate,
                    ),
                  _Step.done => _Done(settingsPath: widget.settingsPath),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String title;
  final String body;

  const _Heading(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        Text(
          body,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 16,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onStart;

  const _Intro({required this.isBusy, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading(
          'Zusätzlich absichern',
          'Nach der Eingabe deines Passworts fragen wir zusätzlich einen Code '
              'aus einer Authenticator-App ab. Wer dein Passwort kennt, kommt '
              'damit trotzdem nicht in dein Konto.',
        ),
        const SizedBox(height: AppLayout.s24),
        const Text(
          'Du brauchst dafür eine Authenticator-App, etwa Aegis, '
          '2FAS, Google Authenticator oder 1Password.',
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: AppLayout.s32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isBusy ? null : onStart,
            child: const Text('Einrichtung starten'),
          ),
        ),
      ],
    );
  }
}

class _Active extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onDeactivate;

  const _Active({required this.isBusy, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading(
          'Bereits aktiv',
          'Für dieses Konto ist eine Zwei-Faktor-Bestätigung eingerichtet. Bei '
              'jeder Anmeldung fragen wir zusätzlich einen Code ab.',
        ),
        const SizedBox(height: AppLayout.s24),
        const Text(
          'Schaltest du sie ab, schützt nur noch dein Passwort das Konto.',
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: AppLayout.s32),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: isBusy ? null : onDeactivate,
            child: const Text('Zwei-Faktor-Bestätigung abschalten'),
          ),
        ),
      ],
    );
  }
}

class _Scan extends StatelessWidget {
  final String secret;
  final String otpauthUri;
  final TextEditingController controller;
  final bool isBusy;
  final VoidCallback onConfirm;

  const _Scan({
    required this.secret,
    required this.otpauthUri,
    required this.controller,
    required this.isBusy,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading(
          'Code scannen',
          'Scanne den Code mit deiner Authenticator-App und gib danach die '
              'sechs Ziffern ein, die sie anzeigt.',
        ),
        const SizedBox(height: AppLayout.s24),
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppLayout.s16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.line),
            ),
            child: QrImageView(
              data: otpauthUri,
              size: 200,
              // Fester Hintergrund: ein transparenter QR-Code ist auf dunklen
              // Flaechen fuer Kameras nicht mehr sicher lesbar.
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppLayout.s24),
        const Text(
          'Kamera nicht zur Hand? Gib diesen Schlüssel manuell ein:',
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: AppLayout.s8),
        _CopyBox(text: secret),
        const SizedBox(height: AppLayout.s24),
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Code aus der App',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppLayout.s8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                ),
                onSubmitted: (_) => onConfirm(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.s24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isBusy ? null : onConfirm,
            child: const Text('Weiter'),
          ),
        ),
      ],
    );
  }
}

class _Recovery extends StatelessWidget {
  final List<String> codes;
  final bool gesichert;
  final bool isBusy;
  final ValueChanged<bool?> onGesichert;
  final VoidCallback onActivate;

  const _Recovery({
    required this.codes,
    required this.gesichert,
    required this.isBusy,
    required this.onGesichert,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading(
          'Wiederherstellungscodes',
          'Verlierst du dein Gerät, sind das deine einzige Möglichkeit, wieder '
              'ins Konto zu kommen. Jeder Code lässt sich einmal verwenden.',
        ),
        const SizedBox(height: AppLayout.s16),
        const Text(
          'Wir zeigen sie dir nur dieses eine Mal. Bewahre sie an einem '
          'sicheren Ort auf, am besten im Passwortmanager – nicht als '
          'Screenshot auf demselben Gerät.',
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: AppLayout.s24),
        _CopyBox(text: codes.join('\n'), monospaceLines: codes),
        const SizedBox(height: AppLayout.s24),
        CheckboxListTile(
          value: gesichert,
          onChanged: onGesichert,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Ich habe die Codes an einem sicheren Ort gespeichert.',
            style: TextStyle(color: AppColors.ink, fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            // Erst wenn die Codes bestaetigt sind. Sonst waere die Aktivierung
            // ein Weg, sich selbst auszusperren.
            onPressed: (!gesichert || isBusy) ? null : onActivate,
            child: const Text('Zwei-Faktor-Bestätigung aktivieren'),
          ),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  final String settingsPath;

  const _Done({required this.settingsPath});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading(
          'Aktiv',
          'Ab jetzt fragen wir bei jeder Anmeldung zusätzlich einen Code ab.',
        ),
        const SizedBox(height: AppLayout.s32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go(settingsPath),
            child: const Text('Zurück zu den Einstellungen'),
          ),
        ),
      ],
    );
  }
}

/// Auswaehlbarer Textblock mit Kopierknopf.
///
/// Der Text liegt in einem [SelectableText], damit er sich auch ohne den Knopf
/// markieren laesst – auf dem Desktop ist das oft der schnellere Weg.
class _CopyBox extends StatelessWidget {
  final String text;
  final List<String>? monospaceLines;

  const _CopyBox({required this.text, this.monospaceLines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              monospaceLines?.join('\n') ?? text,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                height: 1.7,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Kopieren',
            icon: const Icon(Icons.copy_outlined, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('In die Zwischenablage kopiert.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
