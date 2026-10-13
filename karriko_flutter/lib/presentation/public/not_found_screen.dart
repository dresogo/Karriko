import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

/// Fehlerseite fuer Adressen, die der Router nicht kennt.
///
/// Mit Kopfzeile, Navigation und Footer, damit niemand auf einer leeren Seite
/// festsitzt. Die aufgerufene Adresse steht nur als Pfad da, ohne Query: Dort
/// koennen Einmal-Geheimnisse aus Mail-Links stehen.
class NotFoundScreen extends StatelessWidget {
  final Uri uri;

  const NotFoundScreen({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 720;

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Seite nicht gefunden'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentBand(
              padding: EdgeInsets.only(
                top: isWide ? AppLayout.s64 : AppLayout.s48,
                bottom: isWide ? AppLayout.s64 * 2 : AppLayout.s64,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FEHLER 404',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.32,
                    ),
                  ),
                  const SizedBox(height: AppLayout.s16),
                  Text(
                    'Diese Seite gibt es nicht.',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppLayout.s16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      'Unter „${uri.path}“ ist nichts hinterlegt. Vielleicht '
                      'hat sich ein Tippfehler eingeschlichen, oder der Link '
                      'ist veraltet.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 17,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppLayout.s32),
                  Wrap(
                    spacing: AppLayout.s16,
                    runSpacing: AppLayout.s16,
                    children: [
                      FilledButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Zur Startseite'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/search'),
                        child: const Text('Betrieb suchen'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}
