import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../common/app_page.dart';

class BetriebSettingsScreen extends ConsumerStatefulWidget {
  const BetriebSettingsScreen({super.key});

  @override
  ConsumerState<BetriebSettingsScreen> createState() => _BetriebSettingsScreenState();
}

class _BetriebSettingsScreenState extends ConsumerState<BetriebSettingsScreen> {
  bool _emailNewReviews = true;
  bool _emailWeeklyDigest = true;
  bool _emailMarketing = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return AppPage(
      appBarTitle: 'Einstellungen',
      eyebrow: 'EINSTELLUNGEN',
      title: 'Konto, Tarif\nund Benachrichtigungen.',
      lede: user?.companyName?.isNotEmpty == true
          ? 'Einstellungen für ${user!.companyName}'
          : 'Alles rund um deinen Betriebszugang.',
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
              subtitle: 'Wir schicken dir einen Link per E-Mail',
              onTap: () => context.go('/forgot-password'),
            ),
            AppRow(
              icon: Icons.mail_outline,
              title: 'Kontakt-E-Mail',
              value: user?.email ?? '–',
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Team & Tarif'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.group_outlined,
              title: 'Team',
              subtitle: 'Zugriffe im Unternehmen verwalten',
              onTap: () => context.go('/team'),
            ),
            AppRow(
              icon: Icons.card_membership_outlined,
              title: 'Abonnement',
              subtitle: 'Aktuell: Basis (kostenlos)',
              onTap: () => context.go('/subscription'),
            ),
            AppRow(
              icon: Icons.flag_outlined,
              title: 'Bewertungen melden',
              subtitle: 'Regelverstösse prüfen lassen',
              onTap: () => context.go('/reports'),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Benachrichtigungen'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppSwitchRow(
              icon: Icons.star_outline,
              title: 'Neue Bewertungen',
              subtitle: 'E-Mail bei jeder neuen Bewertung',
              value: _emailNewReviews,
              onChanged: (v) => setState(() => _emailNewReviews = v),
            ),
            AppSwitchRow(
              icon: Icons.summarize_outlined,
              title: 'Wöchentlicher Digest',
              subtitle: 'Zusammenfassung jeden Montag',
              value: _emailWeeklyDigest,
              onChanged: (v) => setState(() => _emailWeeklyDigest = v),
            ),
            AppSwitchRow(
              icon: Icons.campaign_outlined,
              title: 'Produktneuigkeiten',
              subtitle: 'Neue Funktionen und Tipps',
              value: _emailMarketing,
              onChanged: (v) => setState(() => _emailMarketing = v),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s16),
        const _NotPersistedHint(),
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Schnittstelle'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.code,
              title: 'API-Schlüssel',
              subtitle: 'Teil des Premium-Tarifs',
              value: 'Gesperrt',
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

/// Solange die Schalter nicht gespeichert werden, wird das offen gesagt.
class _NotPersistedHint extends StatelessWidget {
  const _NotPersistedHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(left: BorderSide(color: AppColors.line, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
          const SizedBox(width: AppLayout.s8),
          Expanded(
            child: Text(
              'Diese Schalter werden noch nicht gespeichert und stehen nach dem '
              'Neuladen wieder auf dem Ausgangswert.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
