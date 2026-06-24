import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../common/app_bar_widget.dart';

class AzubiSettingsScreen extends ConsumerStatefulWidget {
  const AzubiSettingsScreen({super.key});

  @override
  ConsumerState<AzubiSettingsScreen> createState() => _AzubiSettingsScreenState();
}

class _AzubiSettingsScreenState extends ConsumerState<AzubiSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _publicProfile = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Einstellungen'),
      body: ListView(
        children: [
          _SectionHeader('Konto'),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.textSecondary),
            title: const Text('Profil bearbeiten'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.go('/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            title: const Text('Passwort ändern'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.go('/forgot-password'),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
            title: const Text('E-Mail-Adresse'),
            subtitle: Text(auth.user?.email ?? ''),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          const Divider(),
          _SectionHeader('Datenschutz'),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_outlined, color: AppColors.textSecondary),
            title: const Text('Öffentliches Profil'),
            subtitle: const Text('Andere Nutzer können dein Profil sehen.'),
            value: _publicProfile,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _publicProfile = v),
          ),
          const Divider(),
          _SectionHeader('Benachrichtigungen'),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
            title: const Text('E-Mail-Benachrichtigungen'),
            value: _emailNotifications,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            title: const Text('Push-Benachrichtigungen'),
            value: _pushNotifications,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _pushNotifications = v),
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
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Konto löschen', style: TextStyle(color: AppColors.error)),
            onTap: () => _showDeleteAccountDialog(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konto löschen?'),
        content: const Text(
          'Dein Konto und alle deine Bewertungen werden unwiderruflich gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Konto löschen'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go('/');
    }
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
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    );
  }
}
