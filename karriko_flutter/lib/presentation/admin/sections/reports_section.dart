import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

class ReportsSection extends ConsumerStatefulWidget {
  const ReportsSection({super.key});

  @override
  ConsumerState<ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends ConsumerState<ReportsSection> {
  bool _nurOffene = true;

  @override
  Widget build(BuildContext context) {
    final liste = ref.watch(adminReportsProvider(_nurOffene));
    final offen = ref.watch(adminOverviewProvider).valueOrNull?.openReports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          eyebrow: 'MELDUNGEN',
          title: 'Gemeldete Bewertungen',
          lede: 'Eine Meldung ist kein Urteil. Prüfe die Bewertung: Verstößt '
              'sie gegen die Richtlinien, lehne sie ab — sonst verwirf die '
              'Meldung. Automatisch gelöscht wird nichts.',
          action: OutlinedButton.icon(
            onPressed: () => invalidateAdminData(ref),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Aktualisieren'),
          ),
        ),
        const SizedBox(height: AppLayout.s32),
        AdminSegments<bool>(
          options: [(true, 'Offen', offen), (false, 'Alle', null)],
          selected: _nurOffene,
          onSelected: (v) => setState(() => _nurOffene = v),
        ),
        const SizedBox(height: AppLayout.s24),
        liste.when(
          loading: () => const AdminLoadingList(height: 200),
          error: (e, _) => AdminErrorBox(
            error: e,
            onRetry: () => ref.invalidate(adminReportsProvider(_nurOffene)),
          ),
          data: (eintraege) {
            if (eintraege.isEmpty) {
              return AdminEmpty(
                icon: Icons.task_alt_rounded,
                title:
                    _nurOffene ? 'Keine offenen Meldungen' : 'Keine Meldungen',
                text: _nurOffene
                    ? 'Alles geprüft. Neue Meldungen erscheinen hier.'
                    : 'Bisher wurde keine Bewertung gemeldet.',
              );
            }
            return Column(
              children: [
                for (var i = 0; i < eintraege.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppLayout.s16),
                  ReportCard(
                      key: ValueKey(eintraege[i].reportId), item: eintraege[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class ReportCard extends ConsumerStatefulWidget {
  final ReportItem item;

  const ReportCard({super.key, required this.item});

  @override
  ConsumerState<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<ReportCard> {
  bool _laeuft = false;

  ReportItem get _m => widget.item;

  Future<void> _verwerfen() async {
    final notiz = await showNoteDialog(
      context,
      title: 'Meldung verwerfen',
      confirmLabel: 'Verwerfen',
      explanation: 'Die Bewertung bleibt unverändert. Die Meldung gilt als '
          'geprüft und verschwindet aus der offenen Liste.',
    );
    if (notiz == null || !mounted) return;
    await _ausfuehren(
        () => ref
            .read(adminRepositoryProvider)
            .resolveReport(_m.reportId, resolution: 'dismissed', note: notiz),
        'Meldung verworfen.');
  }

  Future<void> _ablehnen() async {
    final grund = await showRejectDialog(context, subject: _m.companyName);
    if (grund == null || !mounted) return;
    await _ausfuehren(() async {
      final repo = ref.read(adminRepositoryProvider);
      // Erst ablehnen, dann die Meldung schließen. Scheitert das Ablehnen,
      // bleibt die Meldung offen — so geht nichts verloren.
      await repo.reject(_m.reviewId!, grund);
      await repo.resolveReport(_m.reportId,
          resolution: 'actioned', note: grund);
    }, 'Bewertung abgelehnt, Meldung erledigt.');
  }

  Future<void> _ausfuehren(Future<void> Function() aktion, String ok) async {
    setState(() => _laeuft = true);
    try {
      await aktion();
      if (!mounted) return;
      showAdminSnack(context, ok);
      invalidateAdminData(ref);
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final erledigt = !_m.isOpen;
    final schonAbgelehnt = _m.reviewStatus == 'rejected';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: _laeuft ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            left: BorderSide(
              color: erledigt ? AppColors.line : AppColors.accent,
              width: 3,
            ),
            top: const BorderSide(color: AppColors.line),
            right: const BorderSide(color: AppColors.line),
            bottom: const BorderSide(color: AppColors.line),
          ),
        ),
        padding: const EdgeInsets.all(AppLayout.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppLayout.s16,
              runSpacing: AppLayout.s8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _m.companyName ?? 'Bewertung nicht gefunden',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (_m.berufName != null) _m.berufName!,
                        'gemeldet ${relativeAge(_m.createdAt)}',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Wrap(
                  spacing: AppLayout.s8,
                  children: [
                    if (_m.reviewStatus != null)
                      reviewStatusBadge(_m.reviewStatus),
                    _meldungsBadge(_m.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppLayout.s16),
            // Der Meldegrund, hervorgehoben: Er ist der Anlass.
            Container(
              padding: const EdgeInsets.all(AppLayout.s16),
              color: AppColors.primaryLight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.outlined_flag_rounded,
                      size: 18, color: AppColors.accentDark),
                  const SizedBox(width: AppLayout.s8),
                  Expanded(
                    child: SelectableText(
                      _m.reason.isEmpty
                          ? 'Ohne Begründung gemeldet.'
                          : _m.reason,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_m.reviewFound) ...[
              const SizedBox(height: AppLayout.s16),
              if (_m.freitextGut?.trim().isNotEmpty ?? false)
                QuoteBlock(
                    label: 'Was gut ist',
                    text: _m.freitextGut!.trim(),
                    positive: true),
              if ((_m.freitextGut?.trim().isNotEmpty ?? false) &&
                  (_m.freitextSchlecht?.trim().isNotEmpty ?? false))
                const SizedBox(height: AppLayout.s8),
              if (_m.freitextSchlecht?.trim().isNotEmpty ?? false)
                QuoteBlock(
                    label: 'Was besser sein könnte',
                    text: _m.freitextSchlecht!.trim(),
                    positive: false),
              if (_m.flags.isNotEmpty) ...[
                const SizedBox(height: AppLayout.s16),
                Wrap(
                  spacing: AppLayout.s8,
                  runSpacing: AppLayout.s8,
                  children: [for (final f in _m.flags) FlagBadge(f)],
                ),
              ],
            ] else ...[
              const SizedBox(height: AppLayout.s16),
              Text(
                'Die gemeldete Bewertung (${_m.reportedId ?? '–'}) existiert '
                'nicht mehr. Die Meldung kann verworfen werden.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (erledigt && _m.resolutionNote != null) ...[
              const SizedBox(height: AppLayout.s16),
              Text(
                'Notiz: ${_m.resolutionNote} · ${formatDateTime(_m.resolvedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (!erledigt) ...[
              const SizedBox(height: AppLayout.s24),
              Wrap(
                spacing: AppLayout.s8,
                runSpacing: AppLayout.s8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _laeuft ? null : _verwerfen,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Meldung verwerfen'),
                  ),
                  if (_m.reviewFound && !schonAbgelehnt)
                    FilledButton.icon(
                      onPressed: _laeuft ? null : _ablehnen,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentDark),
                      icon: const Icon(Icons.block_rounded, size: 18),
                      label: const Text('Bewertung ablehnen'),
                    ),
                  if (schonAbgelehnt)
                    FilledButton.icon(
                      onPressed: _laeuft
                          ? null
                          : () => _ausfuehren(
                                () => ref
                                    .read(adminRepositoryProvider)
                                    .resolveReport(_m.reportId,
                                        resolution: 'actioned'),
                                'Meldung erledigt.',
                              ),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Als erledigt markieren'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

AdminBadge _meldungsBadge(String status) => switch (status) {
      'dismissed' => const AdminBadge('Verworfen',
          icon: Icons.close_rounded, tone: AdminTone.neutral),
      'actioned' => const AdminBadge('Erledigt',
          icon: Icons.task_alt_rounded, tone: AdminTone.positive),
      _ => const AdminBadge('Offen',
          icon: Icons.outlined_flag_rounded, tone: AdminTone.danger),
    };
