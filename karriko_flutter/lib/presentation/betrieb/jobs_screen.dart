import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../common/app_page.dart';
import 'widgets/jobs_section.dart';

/// Eigene Seite für die Ausbildungsstellen eines Betriebs.
///
/// Derselbe Bereich steht auch im Unternehmensprofil – dort als Teil der
/// Selbstdarstellung, hier als eigenes Ziel: Wer eine Stelle ausschreiben will,
/// sucht keine Unterüberschrift auf einer langen Profilseite.
class BetriebJobsScreen extends ConsumerWidget {
  const BetriebJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final company = ref.watch(myCompanyProvider).valueOrNull;

    return AppPage(
      appBarTitle: 'Ausbildungsstellen',
      eyebrow: 'AUSBILDUNGSSTELLEN',
      title: 'Stellen\nausschreiben.',
      lede: 'Veröffentlichte Stellen erscheinen auf deinem Betriebsprofil und '
          'in der Suche. Entwürfe sieht nur dein Betrieb.',
      headerAction: company == null
          ? null
          : OutlinedButton.icon(
              onPressed: () => context.go('/company/${company.slug}'),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Profil ansehen'),
            ),
      children: [
        BetriebJobsSection(company: company, ownerId: user?.id),
        const SizedBox(height: AppLayout.s48),
        const SectionLabel('Weiter zu'),
        const SizedBox(height: AppLayout.s16),
        AppRowGroup(
          children: [
            AppRow(
              icon: Icons.business_outlined,
              title: 'Unternehmensprofil',
              onTap: () => context.go('/betrieb-profile'),
            ),
            AppRow(
              icon: Icons.rate_review_outlined,
              title: 'Bewertungen',
              onTap: () => context.go('/betrieb-reviews'),
            ),
          ],
        ),
      ],
    );
  }
}
