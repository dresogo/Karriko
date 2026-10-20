import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/account_repository.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../common/app_page.dart';

/// Die einzige Seite, die ein Konto in den 14 Tagen bis zur Löschung sieht
/// (E-50, T-2.8).
///
/// Der Router schickt jedes angemeldete Konto mit beantragter Löschung
/// hierher; öffentliche Seiten bleiben erreichbar. Bewerten lehnt auch der
/// Server ab (`submit_review`), die Seite ist also nicht die einzige Schranke.
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  bool _laeuft = false;

  Future<void> _zuruecknehmen() async {
    setState(() => _laeuft = true);
    String? fehler;
    try {
      await ref.read(accountRepositoryProvider).cancelDeletion();
      // Der neue Stand kommt aus den Prefs; danach leitet der Router weiter.
      await ref.read(authProvider.notifier).refresh();
    } on AccountException catch (e) {
      fehler = e.message;
    } catch (_) {
      fehler = 'Die Löschung konnte nicht zurückgenommen werden.';
    }
    if (!mounted) return;
    setState(() => _laeuft = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        content: Text(
          fehler ?? 'Die Löschung ist zurückgenommen. Willkommen zurück.',
          style: const TextStyle(color: AppColors.paper),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final termin = ref.watch(authProvider).user?.deletionPendingUntil;
    final datum = termin == null
        ? 'in Kürze'
        : 'am ${DateFormat('dd.MM.yyyy').format(termin.toLocal())}';

    return AppPage(
      appBarTitle: 'Konto wird gelöscht',
      eyebrow: 'KONTO',
      title: 'Dein Konto wird\n$datum gelöscht.',
      lede: 'Bis dahin kannst du die Löschung zurücknehmen. Danach ist sie '
          'endgültig.',
      children: [
        Text(
          'Was passiert: Veröffentlichte Bewertungen bleiben stehen, aber ohne '
          'jede Verbindung zu dir. Alles andere wird gelöscht – Bewertungen, '
          'die noch nicht veröffentlicht sind, Entwürfe, Merkliste, Profil und '
          'Nachweise.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppLayout.s32),
        Wrap(
          spacing: AppLayout.s16,
          runSpacing: AppLayout.s16,
          children: [
            ElevatedButton(
              onPressed: _laeuft ? null : _zuruecknehmen,
              child: Text(_laeuft ? 'Einen Moment …' : 'Löschung zurücknehmen'),
            ),
            OutlinedButton(
              onPressed: _laeuft
                  ? null
                  : () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) context.go('/');
                    },
              child: const Text('Abmelden'),
            ),
          ],
        ),
      ],
    );
  }
}
