import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

/// Meldet mit einem Passkey an.
///
/// Erscheint nur, wenn der Browser WebAuthn beherrscht. Ältere Browser und alle
/// Nicht-Web-Plattformen bekommen die Schaltfläche gar nicht zu sehen, statt
/// einen Knopf, der beim Drücken scheitert.
///
/// **Ohne Conditional UI.** Die bequeme Variante — der Passkey wird direkt im
/// Anmeldefeld vorgeschlagen — setzt ein echtes `<input>` im Dokument voraus.
/// Flutter Web zeichnet Textfelder auf eine Canvas, es gibt also keins. Deshalb
/// eine ausdrückliche Schaltfläche.
class PasskeyButton extends ConsumerStatefulWidget {
  const PasskeyButton({super.key});

  @override
  ConsumerState<PasskeyButton> createState() => _PasskeyButtonState();
}

class _PasskeyButtonState extends ConsumerState<PasskeyButton> {
  bool _isBusy = false;
  String? _error;

  Future<void> _anmelden() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      // Bei Erfolg wechselt der AuthState, und die Anmeldeseite navigiert
      // weiter – danach ist dieses Widget fort.
      await ref.read(authProvider.notifier).signInWithPasskey();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : _anmelden,
            icon: _isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fingerprint, size: 20),
            label: const Text('Passkey', overflow: TextOverflow.ellipsis),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppLayout.s8),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.accentDark,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
