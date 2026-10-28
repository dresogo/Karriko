import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../common/app_page.dart';

class BetriebSettingsScreen extends ConsumerStatefulWidget {
  const BetriebSettingsScreen({super.key});

  @override
  ConsumerState<BetriebSettingsScreen> createState() =>
      _BetriebSettingsScreenState();
}

class _BetriebSettingsScreenState extends ConsumerState<BetriebSettingsScreen> {
  // Benachrichtigungen und API-Schlüssel stehen hier erst wieder, wenn es sie
  // gibt (E-30, T-2.13).

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return AppPage(
      appBarTitle: 'Einstellungen',
      eyebrow: 'EINSTELLUNGEN',
      title: 'Ihr Betriebskonto\nund was daran hängt.',
      lede: user?.companyName?.isNotEmpty == true
          ? 'Einstellungen für ${user!.companyName}'
          : 'Alles rund um Ihren Betriebszugang.',
      children: [
        const SectionLabel('Konto'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.business_outlined,
              title: 'Unternehmensprofil',
              subtitle: 'Angaben, Beschreibung und Standort',
              onTap: () => context.go('/betrieb-profile'),
            ),
            AppRow(
              icon: Icons.lock_outline,
              title: 'Passwort ändern',
              subtitle: 'Wir schicken Ihnen einen Link per E-Mail',
              onTap: () => context.go('/forgot-password'),
            ),
            AppRow(
              icon: Icons.fingerprint,
              title: 'Passkeys',
              subtitle: 'Anmelden mit Fingerabdruck, Gesicht oder Geräte-PIN',
              onTap: () => context.go('/betrieb-settings/passkeys'),
            ),
            AppRow(
              icon: Icons.shield_outlined,
              title: 'Zwei-Faktor-Bestätigung',
              subtitle: 'Zusätzlicher Code bei jeder Anmeldung',
              value: (user?.mfaEnabled ?? false) ? 'Aktiv' : 'Inaktiv',
              onTap: () => context.go('/betrieb-settings/mfa'),
            ),
            AppRow(
              icon: Icons.mail_outline,
              title: 'Kontakt-E-Mail',
              value: user?.email ?? '–',
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s48),
        // Team und Abonnement stehen hier wieder, sobald sie echt sind.
        const SectionLabel('Meldungen'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.flag_outlined,
              title: 'Bewertungen melden',
              subtitle: 'Regelverstösse prüfen lassen',
              onTap: () => context.go('/reports'),
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
      ],
    );
  }
}
