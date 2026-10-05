import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_models.dart';
import '../../common/app_page.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Die Status, nach denen sich die Warteschlange filtern lässt.
const _filter = [
  ('pending_moderation', 'Wartet'),
  ('scheduled', 'Zurückgestellt'),
  ('approved', 'Freigegeben'),
  ('rejected', 'Abgelehnt'),
];

class ModerationSection extends ConsumerStatefulWidget {
  const ModerationSection({super.key});

  @override
  ConsumerState<ModerationSection> createState() => _ModerationSectionState();
}

class _ModerationSectionState extends ConsumerState<ModerationSection> {
  String _status = 'pending_moderation';

  @override
  Widget build(BuildContext context) {
    final liste = ref.watch(adminQueueProvider(_status));
    final zahlen = ref.watch(adminOverviewProvider).valueOrNull;

    int? anzahl(String status) => switch (status) {
          'pending_moderation' => zahlen?.pending,
          'scheduled' => zahlen?.scheduled,
          'approved' => zahlen?.approved,
          'rejected' => zahlen?.rejected,
          _ => null,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          eyebrow: 'MODERATION',
          title: 'Warteschlange',
          lede: 'Was hier freigegeben wird, erscheint öffentlich auf der '
              'Betriebsseite. Die älteste Bewertung steht oben. Verfasser '
              'bleiben anonym — auch hier.',
          action: OutlinedButton.icon(
            onPressed: () => invalidateAdminData(ref),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Aktualisieren'),
          ),
        ),
        const SizedBox(height: AppLayout.s32),
        AdminSegments<String>(
          options: [for (final (w, l) in _filter) (w, l, anzahl(w))],
          selected: _status,
          onSelected: (s) => setState(() => _status = s),
        ),
        const SizedBox(height: AppLayout.s24),
        liste.when(
          loading: () => const AdminLoadingList(height: 220),
          error: (e, _) => AdminErrorBox(
            error: e,
            onRetry: () => ref.invalidate(adminQueueProvider(_status)),
          ),
          data: (eintraege) {
            if (eintraege.isEmpty) {
              return AdminEmpty(
                icon: Icons.task_alt_rounded,
                title: _status == 'pending_moderation'
                    ? 'Alles erledigt'
                    : 'Keine Bewertungen',
                text: _status == 'pending_moderation'
                    ? 'Keine Bewertung wartet auf eine Entscheidung.'
                    : 'In diesem Status liegt gerade nichts.',
              );
            }
            return Column(
              children: [
                for (var i = 0; i < eintraege.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppLayout.s16),
                  ReviewCard(
                    key: ValueKey(eintraege[i].reviewId),
                    item: eintraege[i],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Eine Bewertung mit allem, was für die Entscheidung nötig ist.
class ReviewCard extends ConsumerStatefulWidget {
  final QueueItem item;

  const ReviewCard({super.key, required this.item});

  @override
  ConsumerState<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<ReviewCard> {
  bool _laeuft = false;
  late bool _nachweisBelegt = widget.item.verified;

  QueueItem get _i => widget.item;

  Future<void> _freigeben() async {
    setState(() => _laeuft = true);
    try {
      await ref.read(adminRepositoryProvider).approve(
            _i.reviewId,
            verified: _i.hasVerification ? _nachweisBelegt : null,
          );
      if (!mounted) return;
      showAdminSnack(
          context, 'Freigegeben — die Bewertung ist jetzt öffentlich.');
      invalidateAdminData(ref);
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  Future<void> _ablehnen() async {
    final grund = await showRejectDialog(context, subject: _i.companyName);
    if (grund == null || !mounted) return;
    setState(() => _laeuft = true);
    try {
      await ref.read(adminRepositoryProvider).reject(_i.reviewId, grund);
      if (!mounted) return;
      showAdminSnack(context, 'Abgelehnt. Der Verfasser sieht die Begründung.');
      invalidateAdminData(ref);
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zeitraum = switch ((_i.startYear, _i.endYear)) {
      (final int s, final int e) => '$s – $e',
      (final int s, null) => 'seit $s',
      _ => null,
    };
    final echteFlags = _i.flags.where((f) => f != 'text_needs_review').toList();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: _laeuft ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            left: BorderSide(
              color: echteFlags.isNotEmpty || _i.reportCount > 0
                  ? AppColors.warning
                  : AppColors.ink,
              width: 3,
            ),
            top: const BorderSide(color: AppColors.line),
            right: const BorderSide(color: AppColors.line),
            bottom: const BorderSide(color: AppColors.line),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kopf
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Wrap(
                spacing: AppLayout.s16,
                runSpacing: AppLayout.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _i.companyName ?? 'Unbekannter Betrieb',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (_i.berufName != null) _i.berufName!,
                          if (zeitraum != null) zeitraum,
                          'eingereicht ${relativeAge(_i.submittedAt)}',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  reviewStatusBadge(_i.status),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            // Markierungen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: AppLayout.s8,
                runSpacing: AppLayout.s8,
                children: [
                  if (_i.reportCount > 0)
                    AdminBadge(
                      '${_i.reportCount}× gemeldet',
                      icon: Icons.outlined_flag_rounded,
                      tone: AdminTone.danger,
                    ),
                  for (final f in _i.flags) FlagBadge(f),
                  if (_i.hasVerification)
                    AdminBadge(
                      _i.verified ? 'Nachweis bestätigt' : 'Nachweis liegt vor',
                      icon: Icons.verified_outlined,
                      tone: _i.verified ? AdminTone.positive : AdminTone.info,
                      tooltip:
                          'Den Nachweis öffnest du in der Appwrite-Console '
                          '(Storage → verification_documents).',
                    ),
                  if (_i.invited)
                    const AdminBadge('Über Einladung',
                        icon: Icons.mail_outline_rounded),
                  if (_i.publishAfter != null)
                    AdminBadge(
                      'Frühestens ${formatDateTime(_i.publishAfter)}',
                      icon: Icons.schedule_rounded,
                      tone: AdminTone.info,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            // Freitexte
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (_i.freitextGut?.trim().isNotEmpty ?? false)
                    QuoteBlock(
                        label: 'Was gut ist',
                        text: _i.freitextGut!.trim(),
                        positive: true),
                  if ((_i.freitextGut?.trim().isNotEmpty ?? false) &&
                      (_i.freitextSchlecht?.trim().isNotEmpty ?? false))
                    const SizedBox(height: AppLayout.s8),
                  if (_i.freitextSchlecht?.trim().isNotEmpty ?? false)
                    QuoteBlock(
                        label: 'Was besser sein könnte',
                        text: _i.freitextSchlecht!.trim(),
                        positive: false),
                  if ((_i.freitextGut?.trim().isEmpty ?? true) &&
                      (_i.freitextSchlecht?.trim().isEmpty ?? true))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Ohne Freitext.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.s16),
            // Werte
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: AppLayout.s32,
                runSpacing: AppLayout.s16,
                children: [
                  if (_i.overall != null)
                    MetaPair('Gesamturteil',
                        (1 + 4 * _i.overall! / 100).toStringAsFixed(1)),
                  if (_i.detailOverall != null)
                    MetaPair('Aus Einzelfragen',
                        _i.detailOverall!.toStringAsFixed(1)),
                  if (_i.recommend != null)
                    MetaPair('Weiterempfehlung', '${_i.recommend} / 10'),
                  MetaPair('Eingereicht', formatDateTime(_i.submittedAt)),
                ],
              ),
            ),
            if (_i.notes.isNotEmpty) ...[
              const SizedBox(height: AppLayout.s16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _Hinweise(notes: _i.notes),
              ),
            ],
            const SizedBox(height: AppLayout.s24),
            const Divider(height: 1),
            // Aktionen
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Wrap(
                spacing: AppLayout.s16,
                runSpacing: AppLayout.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  if (_i.hasVerification)
                    InkWell(
                      onTap: _laeuft
                          ? null
                          : () => setState(
                              () => _nachweisBelegt = !_nachweisBelegt),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _nachweisBelegt,
                              onChanged: _laeuft
                                  ? null
                                  : (v) => setState(
                                      () => _nachweisBelegt = v ?? false),
                              activeColor: AppColors.ink,
                            ),
                            const Text('Nachweis geprüft und belegt',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink)),
                          ],
                        ),
                      ),
                    )
                  else
                    SelectableText(
                      'ID ${_i.reviewId}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  Wrap(
                    spacing: AppLayout.s8,
                    runSpacing: AppLayout.s8,
                    children: [
                      if (_i.status != 'rejected')
                        OutlinedButton.icon(
                          onPressed: _laeuft ? null : _ablehnen,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentDark,
                            side: const BorderSide(color: AppColors.accentDark),
                          ),
                          icon: const Icon(Icons.block_rounded, size: 18),
                          label: Text(_i.status == 'approved'
                              ? 'Nachträglich ablehnen'
                              : 'Ablehnen'),
                        ),
                      if (_i.status != 'approved')
                        FilledButton.icon(
                          onPressed: _laeuft ? null : _freigeben,
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.ink),
                          icon: _laeuft
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_i.status == 'rejected'
                              ? 'Doch freigeben'
                              : 'Freigeben'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Die ausformulierten Gründe der Flags, eingeklappt.
class _Hinweise extends StatelessWidget {
  final List<String> notes;

  const _Hinweise({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppLayout.s8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: const SectionLabel('Warum markiert'),
        children: [
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('· $n', style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
