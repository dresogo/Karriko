import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../common/app_bar_widget.dart';

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
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Einstellungen'),
      body: ListView(
        children: [
          _SectionHeader('Konto'),
          ListTile(
            leading: const Icon(Icons.business_outlined, color: AppColors.textSecondary),
            title: const Text('Unternehmensprofil'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.go('/betrieb-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            title: const Text('Passwort ändern'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.go('/forgot-password'),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
            title: const Text('Kontakt-E-Mail'),
            subtitle: Text(auth.user?.email ?? ''),
          ),
          const Divider(),
          _SectionHeader('Abonnement'),
          ListTile(
            leading: const Icon(Icons.card_membership_outlined, color: AppColors.textSecondary),
            title: const Text('Abonnement verwalten'),
            subtitle: const Text('Aktuell: Basis (Kostenlos)'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.go('/subscription'),
          ),
          const Divider(),
          _SectionHeader('Benachrichtigungen'),
          SwitchListTile(
            secondary: const Icon(Icons.star_outline, color: AppColors.textSecondary),
            title: const Text('Neue Bewertungen'),
            subtitle: const Text('E-Mail bei neuen Bewertungen.'),
            value: _emailNewReviews,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _emailNewReviews = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.summarize_outlined, color: AppColors.textSecondary),
            title: const Text('Wöchentlicher Digest'),
            subtitle: const Text('Zusammenfassung jede Woche.'),
            value: _emailWeeklyDigest,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _emailWeeklyDigest = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined, color: AppColors.textSecondary),
            title: const Text('Marketing-E-Mails'),
            value: _emailMarketing,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _emailMarketing = v),
          ),
          const Divider(),
          _SectionHeader('API'),
          ListTile(
            leading: const Icon(Icons.code, color: AppColors.textSecondary),
            title: const Text('API-Schlüssel'),
            subtitle: const Text('Nur in Premium verfügbar.'),
            trailing: const Icon(Icons.lock, size: 16, color: AppColors.textMuted),
          ),
          const Divider(),
          _SectionHeader('Rechtliches'),
          ListTile(
            leading: const Icon(Icons.gavel_outlined, color: AppColors.textSecondary),
            title: const Text('Datenschutzerklärung'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.go('/datenschutz'),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined, color: AppColors.textSecondary),
            title: const Text('AGB'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.go('/agb'),
          ),
          const Divider(),
          _SectionHeader('Konto verwalten'),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.textSecondary),
            title: const Text('Abmelden'),
            onTap: () {
              ref.read(authProvider.notifier).signOut();
              context.go('/');
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}
