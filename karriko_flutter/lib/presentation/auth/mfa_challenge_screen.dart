import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'login_shell.dart';

/// Zweiter Schritt der Anmeldung: Bestaetigung ueber einen Einmalcode.
///
/// Der Bildschirm wird nicht angesteuert, sondern vom Router erzwungen, sobald
/// [AuthState.mfaRequired] gilt. Solange das der Fall ist, fuehrt jeder andere
/// geschuetzte Pfad hierher zurueck.
class MfaChallengeScreen extends ConsumerStatefulWidget {
  const MfaChallengeScreen({super.key});

  @override
  ConsumerState<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends ConsumerState<MfaChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  /// Gewaehltes Verfahren. Beim ersten Aufbau der erste hinterlegte Faktor –
  /// ein zusaetzlicher Klick waere reine Zeremonie, solange es nur einen gibt.
  String? _factor;

  /// Laufende Challenge, Ladezustand und Fehlermeldung liegen hier statt im
  /// [AuthState]: an dem haengt der `refreshListenable` des Routers, und eine
  /// Aenderung waehrend go_router diese Route installiert, verwirft die
  /// Navigation. Der Nutzer landete dann wieder auf der Startseite.
  String? _challengeId;
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startIfNeeded());
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startIfNeeded() {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (!auth.mfaRequired || _challengeId != null) return;
    _start(auth.mfaFactors.first);
  }

  Future<void> _start(String factor) async {
    setState(() {
      _factor = factor;
      _isBusy = true;
      _error = null;
    });
    try {
      final id = await ref.read(authRepositoryProvider).startMfaChallenge(
            factor,
          );
      if (mounted) setState(() => _challengeId = id);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _switchFactor(String factor) async {
    _codeCtrl.clear();
    setState(() => _challengeId = null);
    await _start(factor);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final challengeId = _challengeId;
    if (challengeId == null) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      // Bei Erfolg wechselt der AuthState auf den angemeldeten Nutzer, der
      // Router traegt uns von hier fort – deshalb danach kein setState mehr.
      await ref.read(authProvider.notifier).submitMfaChallenge(
            challengeId: challengeId,
            otp: _codeCtrl.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final factors = auth.mfaFactors;
    final istWiederherstellung = _factor == 'recoverycode';

    return LoginShell(
      appBarTitle: 'Bestätigung',
      eyebrow: 'SICHERHEIT',
      headline: 'Noch ein\nSchritt.',
      lede: auth.pendingEmail != null
          ? 'Für ${auth.pendingEmail} ist eine Zwei-Faktor-Bestätigung '
              'eingerichtet. Gib den Code aus deiner Authenticator-App ein.'
          : 'Für dieses Konto ist eine Zwei-Faktor-Bestätigung eingerichtet.',
      aside: const LoginTrustNote(
        'Der Code wechselt alle 30 Sekunden und lässt sich nur einmal nutzen.',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              LoginErrorBanner(_error!),
              const SizedBox(height: AppLayout.s24),
            ],
            _LabeledField(
              label: istWiederherstellung
                  ? 'Wiederherstellungscode'
                  : 'Sechsstelliger Code',
              field: TextFormField(
                controller: _codeCtrl,
                autofocus: true,
                keyboardType: istWiederherstellung
                    ? TextInputType.text
                    : TextInputType.number,
                // Auf iOS und Android bietet die Tastatur den Code aus der
                // SMS beziehungsweise dem Schluesselbund direkt an.
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: istWiederherstellung
                    ? null
                    : [FilteringTextInputFormatter.digitsOnly],
                maxLength: istWiederherstellung ? null : 6,
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Bitte gib den Code ein.';
                  if (!istWiederherstellung && value.length != 6) {
                    return 'Der Code besteht aus sechs Ziffern.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isBusy ? null : _submit,
                child: _isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Bestätigen'),
              ),
            ),
            if (factors.contains('recoverycode') && !istWiederherstellung) ...[
              const SizedBox(height: AppLayout.s8),
              TextButton(
                onPressed: () => _switchFactor('recoverycode'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: const Text('Ich habe keinen Zugriff auf die App'),
              ),
            ],
            if (istWiederherstellung && factors.contains('totp')) ...[
              const SizedBox(height: AppLayout.s8),
              TextButton(
                onPressed: () => _switchFactor('totp'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: const Text('Doch die Authenticator-App verwenden'),
              ),
            ],
            const SizedBox(height: AppLayout.s16),
            const Divider(color: AppColors.line, height: 1),
            const SizedBox(height: AppLayout.s16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                // Meldet serverseitig ab. Ohne das bliebe die halbfertige
                // Sitzung bestehen und der naechste Anmeldeversuch scheiterte.
                onPressed: () =>
                    ref.read(authProvider.notifier).cancelMfaChallenge(),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Anmeldung abbrechen'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eingabefeld mit sichtbarem Label darueber.
///
/// Gleiches Muster wie auf der Anmeldeseite: ein Platzhalter allein verschwindet
/// beim Tippen und taugt nicht als Beschriftung.
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget field;

  const _LabeledField({required this.label, required this.field});

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
          field,
        ],
      ),
    );
  }
}
