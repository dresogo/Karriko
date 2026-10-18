import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../common/app_page.dart';

class AzubiSettingsScreen extends ConsumerStatefulWidget {
  const AzubiSettingsScreen({super.key});

  @override
  ConsumerState<AzubiSettingsScreen> createState() =>
      _AzubiSettingsScreenState();
}

class _AzubiSettingsScreenState extends ConsumerState<AzubiSettingsScreen> {
  // Schalter für Sichtbarkeit und Benachrichtigungen stehen hier erst wieder,
  // wenn es ein öffentliches Profil und Benachrichtigungen gibt (E-30, T-2.13).

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return AppPage(
      appBarTitle: 'Einstellungen',
      eyebrow: 'EINSTELLUNGEN',
      title: 'Dein Konto\nund was daran hängt.',
      lede: 'Zugangsdaten, Anmeldung und Rechtliches an einem Ort.',
      children: [
        const SectionLabel('Konto'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.person_outline,
              title: 'Profil bearbeiten',
              subtitle: 'Name und Angaben ändern',
              onTap: () => context.go('/profile'),
            ),
            AppRow(
              icon: Icons.lock_outline,
              title: 'Passwort ändern',
              subtitle: 'Wir schicken dir einen Link per E-Mail',
              onTap: () => context.go('/forgot-password'),
            ),
            AppRow(
              icon: Icons.fingerprint,
              title: 'Passkeys',
              subtitle: 'Anmelden mit Fingerabdruck, Gesicht oder Geräte-PIN',
              onTap: () => context.go('/settings/passkeys'),
            ),
            AppRow(
              icon: Icons.shield_outlined,
              title: 'Zwei-Faktor-Bestätigung',
              subtitle: 'Zusätzlicher Code bei jeder Anmeldung',
              value: (auth.user?.mfaEnabled ?? false) ? 'Aktiv' : 'Inaktiv',
              onTap: () => context.go('/settings/mfa'),
            ),
            AppRow(
              icon: Icons.mail_outline,
              title: 'E-Mail-Adresse',
              value: auth.user?.email ?? '–',
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Rechtliches'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.shield_outlined,
              title: 'Datenschutzerklärung',
              onTap: () => context.go('/datenschutz'),
            ),
            AppRow(
              icon: Icons.article_outlined,
              title: 'AGB',
              onTap: () => context.go('/agb'),
            ),
            AppRow(
              icon: Icons.help_outline,
              title: 'Häufige Fragen',
              onTap: () => context.go('/faq'),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Konto verwalten'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.logout,
              title: 'Abmelden',
              subtitle: 'Auf diesem Gerät',
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s24),
        // Loeschung raeumlich abgesetzt, damit sie nicht versehentlich neben
        // dem Abmelden getroffen wird.
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.delete_outline,
              title: 'Konto löschen',
              subtitle: 'Unwiderruflich, inklusive aller Bewertungen',
              destructive: true,
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.ink),
          borderRadius: BorderRadius.zero,
        ),
        title: Text('Konto löschen?',
            style: Theme.of(context).textTheme.headlineMedium),
        content: Text(
          'Dein Konto und alle deine Bewertungen werden unwiderruflich gelöscht. '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppLayout.s24,
          0,
          AppLayout.s24,
          AppLayout.s16,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.accentDark),
            child: const Text('Konto löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Die Löschung ist serverseitig noch nicht umgesetzt
    // (AuthRepository.deleteAccount wirft UnimplementedError). Statt still
    // abzumelden und Löschung vorzutäuschen, wird das hier offen gesagt.
    _showDeletionUnavailableHint();
  }

  void _showDeletionUnavailableHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: const Text(
          'Die Löschung ist noch nicht freigeschaltet. Bitte wende dich an den '
          'Support – dein Konto bleibt bis dahin bestehen.',
          style: TextStyle(color: AppColors.paper),
        ),
        action: SnackBarAction(
          label: 'Kontakt',
          textColor: AppColors.paper,
          onPressed: () => context.go('/kontakt'),
        ),
      ),
    );
  }
}
