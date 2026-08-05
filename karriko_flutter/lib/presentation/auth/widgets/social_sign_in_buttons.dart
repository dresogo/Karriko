import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/appwrite_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

/// Anmeldung über Google und Apple.
///
/// Nur für Azubis. Betriebe melden sich mit E-Mail und Passwort an, weil ihr
/// Zugang eine menschliche Firmenprüfung voraussetzt.
///
/// **Es wird nichts von einem fremden Server geladen.** Weder Logos noch
/// Skripte — sonst entstünde allein durch das Anzeigen der Anmeldeseite eine
/// Datenübermittlung an Google, die einwilligungspflichtig wäre.
class SocialSignInButtons extends ConsumerStatefulWidget {
  const SocialSignInButtons({super.key});

  @override
  ConsumerState<SocialSignInButtons> createState() =>
      _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends ConsumerState<SocialSignInButtons> {
  String? _error;

  void _anmelden(String provider) {
    // Solange keine Client-Zugangsdaten in der Appwrite Console liegen, sind
    // die Schaltflaechen Platzhalter. Sie bleiben bedienbar und sagen beim
    // Druecken, woran es liegt – ein Weiterleiten wuerde die App verlassen und
    // auf einer Appwrite-Fehlerseite enden, von der niemand zurueckfindet.
    if (!AppwriteConstants.oauthEnabled) {
      setState(() => _error =
          'Die Anmeldung über Google und Apple ist noch nicht freigeschaltet. '
              'Nutze bitte Passwort, Passkey oder den E-Mail-Link.');
      return;
    }
    setState(() => _error = null);
    try {
      // Verlaesst im Erfolgsfall die Seite und kehrt nicht zurueck.
      ref.read(authRepositoryProvider).signInWithOAuth(provider);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
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
          const SizedBox(height: AppLayout.s16),
        ],
        // Nebeneinander statt gestapelt: Die Anmeldeseite bietet fuer Azubis
        // inzwischen vier Wege an: Passwort, Anmeldelink, Google und Apple.
        // Untereinander passt das nicht mehr in einen 900 px hohen Viewport,
        // und das Panel verliert seine vertikale Mitte.
        Row(
          children: [
            Expanded(
              child: _ProviderButton(
                label: 'Google',
                semanticLabel: 'Mit Google anmelden',
                mark: const _GoogleMark(),
                onPressed: () => _anmelden('google'),
              ),
            ),
            const SizedBox(width: AppLayout.s8),
            Expanded(
              child: _ProviderButton(
                label: 'Apple',
                semanticLabel: 'Mit Apple anmelden',
                // Das Apple-Zeichen liegt in den Material Icons, die mit
                // Flutter ausgeliefert werden – kein Asset noetig.
                mark: const Icon(Icons.apple, size: 20, color: AppColors.ink),
                onPressed: () => _anmelden('apple'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final String label;

  /// Vollstaendiger Name fuer Screenreader. Sichtbar steht nur der Anbieter,
  /// vorgelesen wird die ganze Handlung.
  final String semanticLabel;
  final Widget mark;

  final VoidCallback onPressed;

  const _ProviderButton({
    required this.label,
    required this.semanticLabel,
    required this.mark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      excludeSemantics: true,
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              mark,
              const SizedBox(width: AppLayout.s8),
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Platzhalter-Zeichen für Google.
///
/// **Vor dem Start ersetzen.** Googles Markenrichtlinien für „Sign in with
/// Google" verlangen das von Google bereitgestellte Logo in unveränderter Form;
/// ein nachgezeichnetes wäre weder richtlinienkonform noch markenrechtlich
/// sauber. Die Datei gehört heruntergeladen, unter `assets/icons/` abgelegt und
/// hier eingesetzt — nicht zur Laufzeit von einem Google-Server geladen, sonst
/// entsteht genau die Datenübermittlung, die dieser Aufbau vermeidet.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
