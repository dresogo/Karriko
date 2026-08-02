import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'login_shell.dart';

/// Einstieg in den Login: trennt Azubis und Betriebe, bevor die eigentliche
/// Anmeldemaske geöffnet wird. Ein vorhandener `next`-Parameter wird an die
/// jeweilige Maske durchgereicht.
class LoginChoiceScreen extends StatelessWidget {
  const LoginChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    String target(String base) =>
        next == null ? base : '$base?next=${Uri.encodeComponent(next)}';

    return LoginShell(
      appBarTitle: 'Anmelden',
      eyebrow: 'ANMELDEN',
      headline: 'Wer bist\ndu?',
      lede: 'Azubis und Betriebe arbeiten in unterschiedlichen Bereichen der '
          'Plattform. Wähle deinen Zugang, um dich anzumelden.',
      aside: const LoginTrustNote(
        'Geschützt durch Appwrite Auth · SSL-verschlüsselt',
      ),
      child: Column(
        // stretch statt start: die Auswahlliste soll die Panelbreite ausfüllen,
        // nicht auf ihre Inhaltsbreite schrumpfen.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ZUGANG WÄHLEN',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.96,
            ),
          ),
          const SizedBox(height: AppLayout.s16),
          Material(
            color: AppColors.surface,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
              child: Column(
                children: [
                  _RoleRow(
                    icon: Icons.school_outlined,
                    title: 'Ich bin Azubi',
                    description: 'Bewertungen schreiben, Betriebe merken und dein '
                        'Profil verwalten.',
                    onTap: () => context.go(target('/login/azubi')),
                  ),
                  const Divider(color: AppColors.line, height: 1),
                  _RoleRow(
                    icon: Icons.business_outlined,
                    title: 'Ich bin Betrieb',
                    description: 'Unternehmensprofil pflegen, Feedback einsehen und '
                        'auf Bewertungen antworten.',
                    onTap: () => context.go(target('/login/betrieb')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppLayout.s32),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: AppLayout.s24),
          Text(
            'Noch kein Konto?',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppLayout.s8),
          Wrap(
            spacing: AppLayout.s24,
            runSpacing: AppLayout.s8,
            children: [
              _RegisterLink(
                label: 'Als Azubi registrieren',
                onTap: () => context.go('/register/azubi'),
              ),
              _RegisterLink(
                label: 'Als Betrieb registrieren',
                onTap: () => context.go('/register/betrieb'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Auswahlzeile mit sichtbaren Hover-, Fokus- und Druckzuständen. Der Fokus wird
/// zusätzlich als 2 px starke Tintenkante gezeichnet, damit er per Tastatur
/// eindeutig erkennbar ist.
class _RoleRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_RoleRow> createState() => _RoleRowState();
}

class _RoleRowState extends State<_RoleRow> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.description}',
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (v) => setState(() => _focused = v),
        onHover: (v) => setState(() => _hovered = v),
        hoverColor: AppColors.paper,
        focusColor: AppColors.audienceBeige,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(AppLayout.s24),
          decoration: BoxDecoration(
            border: Border.all(
              color: _focused ? AppColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.audienceBeige,
                  border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
                ),
                child: Icon(widget.icon, size: 22, color: AppColors.ink),
              ),
              const SizedBox(width: AppLayout.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppLayout.s16),
              AnimatedSlide(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                offset: _hovered || _focused ? const Offset(0.25, 0) : Offset.zero,
                child: const Icon(Icons.arrow_forward, size: 20, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RegisterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(label),
    );
  }
}
