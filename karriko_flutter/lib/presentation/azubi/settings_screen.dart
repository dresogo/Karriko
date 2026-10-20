import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/services/save_file.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../common/app_page.dart';

class AzubiSettingsScreen extends ConsumerStatefulWidget {
  const AzubiSettingsScreen({super.key});

  @override
  ConsumerState<AzubiSettingsScreen> createState() =>
      _AzubiSettingsScreenState();
}

class _AzubiSettingsScreenState extends ConsumerState<AzubiSettingsScreen> {
  bool _exportiert = false;

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
              icon: Icons.download_outlined,
              title: 'Meine Daten herunterladen',
              subtitle: _exportiert
                  ? 'Wird vorbereitet …'
                  : 'Alles, was du eingegeben hast, als JSON-Datei',
              onTap: _exportiert ? null : _herunterladen,
            ),
            AppRow(
              icon: Icons.delete_outline,
              title: 'Konto löschen',
              subtitle: '14 Tage lang zurücknehmbar, danach endgültig',
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
          'Dein Konto wird in 14 Tagen gelöscht. Bis dahin kannst du die '
          'Löschung nach der Anmeldung zurücknehmen. Veröffentlichte '
          'Bewertungen bleiben ohne Verbindung zu dir stehen; alles andere '
          'wird gelöscht.',
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

    String? fehler;
    try {
      await ref.read(accountRepositoryProvider).requestDeletion();
      // Der Termin kommt ueber die Prefs; der Router zeigt danach nur noch
      // die Seite zum Zuruecknehmen.
      await ref.read(authProvider.notifier).refresh();
    } on AccountException catch (e) {
      fehler = e.message;
    } catch (_) {
      fehler = 'Die Löschung konnte nicht beantragt werden.';
    }
    if (fehler != null && mounted) _melden(fehler);
  }

  /// Der Export nach Art. 20 (T-2.10): was das Konto selbst eingegeben hat.
  Future<void> _herunterladen() async {
    setState(() => _exportiert = true);
    String? fehler;
    try {
      final json = await ref.read(accountRepositoryProvider).exportJson();
      final tag = DateTime.now().toIso8601String().substring(0, 10);
      await saveTextFile(name: 'karriko-daten-$tag.json', content: json);
    } on AccountException catch (e) {
      fehler = e.message;
    } on UnsupportedError catch (e) {
      fehler = e.message;
    } catch (_) {
      fehler = 'Deine Daten konnten nicht heruntergeladen werden.';
    }
    if (!mounted) return;
    setState(() => _exportiert = false);
    if (fehler != null) _melden(fehler);
  }

  void _melden(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: Text(text, style: const TextStyle(color: AppColors.paper)),
      ),
    );
  }
}
