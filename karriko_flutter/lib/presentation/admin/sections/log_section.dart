import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_models.dart';
import '../../common/app_page.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

class LogSection extends ConsumerWidget {
  const LogSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(adminLogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          eyebrow: 'PROTOKOLL',
          title: 'Entscheidungen',
          lede: 'Jede Freigabe und Ablehnung mit Zeitpunkt, Begründung und '
              'wer entschieden hat. Eine Moderation ohne nachvollziehbaren '
              'Urheber ist keine.',
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(adminLogProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Aktualisieren'),
          ),
        ),
        const SizedBox(height: AppLayout.s32),
        liste.when(
          loading: () => const AdminLoadingList(count: 5, height: 72),
          error: (e, _) => AdminErrorBox(
            error: e,
            onRetry: () => ref.invalidate(adminLogProvider),
          ),
          data: (eintraege) => eintraege.isEmpty
              ? const AdminEmpty(
                  icon: Icons.history_rounded,
                  title: 'Noch keine Entscheidungen',
                  text: 'Das Protokoll füllt sich mit der ersten Freigabe '
                      'oder Ablehnung.',
                )
              : AppRowGroup(
                  children: [for (final e in eintraege) LogRow(entry: e)],
                ),
        ),
      ],
    );
  }
}

/// Eine Zeile des Protokolls.
class LogRow extends StatelessWidget {
  final ModerationLogItem entry;

  const LogRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final freigabe = entry.isApproval;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.s24, vertical: AppLayout.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: AdminBadge(
              freigabe ? 'Freigegeben' : 'Abgelehnt',
              icon: freigabe
                  ? Icons.check_circle_outline_rounded
                  : Icons.block_rounded,
              tone: freigabe ? AdminTone.positive : AdminTone.danger,
            ),
          ),
          const SizedBox(width: AppLayout.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.companyName ?? 'Bewertung ${entry.reviewId ?? ''}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDateTime(entry.createdAt)} · '
                  '${entry.moderatorName ?? entry.moderatorId ?? 'unbekannt'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (entry.reason?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  Text(
                    '„${entry.reason!.trim()}"',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (entry.flags.any((f) => f != 'text_needs_review'))
            const Padding(
              padding: EdgeInsets.only(left: AppLayout.s8),
              child: Tooltip(
                message: 'War mit Qualitäts-Flags markiert',
                child:
                    Icon(Icons.flag_outlined, size: 18, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
