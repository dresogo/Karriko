import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/tap_target.dart';

/// Zustimmung bei der Registrierung (T-11.9, Seiten-Tab 35).
///
/// Zugestimmt wird nur den AGB. Einer Datenschutzerklärung stimmt man nicht
/// zu, man wird über sie informiert; deshalb steht sie als Satz ohne Haken
/// darunter. Beide sind echte Links und öffnen in einem neuen Tab, damit das
/// halb ausgefüllte Formular stehen bleibt. Der Wortlaut ist anwaltlich noch
/// zu prüfen (T-5.1); ein Haken zum Mindestalter folgt mit T-5.18.
class TermsConsent extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const TermsConsent({super.key, required this.value, required this.onChanged});

  static const _style =
      TextStyle(color: AppColors.ink, fontSize: 14, height: 1.45);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          value: value,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Ich akzeptiere die '),
              _link('AGB', '/agb', 14),
              const TextSpan(text: '.'),
            ]),
            style: _style,
          ),
        ),
        Padding(
          // Bündig mit dem Text des Hakens, nicht mit dem Kästchen.
          padding: const EdgeInsets.only(left: 56),
          child: Text.rich(
            TextSpan(children: [
              const TextSpan(
                  text: 'Wie Karriko mit personenbezogenen Daten umgeht, '
                      'steht in der '),
              _link('Datenschutzerklärung', '/datenschutz', 13),
              const TextSpan(text: '.'),
            ]),
            style: const TextStyle(
                color: AppColors.muted, fontSize: 13, height: 1.45),
          ),
        ),
      ],
    );
  }

  /// Ein Text in einer WidgetSpan erbt den Stil des Absatzes nicht, deshalb
  /// die Schriftgröße ausdrücklich.
  static InlineSpan _link(String label, String path, double size) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Link(
          uri: Uri(path: path),
          target: LinkTarget.blank,
          builder: (context, followLink) => TapTarget(
            onTap: followLink,
            isLink: true,
            builder: (context, active) => Text(
              label,
              style: TextStyle(
                color: AppColors.accentDark,
                fontSize: size,
                height: 1.45,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.accentDark,
                decorationThickness: active ? 2 : 1,
              ),
            ),
          ),
        ),
      );
}
