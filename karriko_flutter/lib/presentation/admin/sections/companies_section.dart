import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_models.dart';
import '../../common/app_page.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

class CompaniesSection extends ConsumerStatefulWidget {
  final bool isAdmin;

  const CompaniesSection({super.key, required this.isAdmin});

  @override
  ConsumerState<CompaniesSection> createState() => _CompaniesSectionState();
}

class _CompaniesSectionState extends ConsumerState<CompaniesSection> {
  final _sucheCtrl = TextEditingController();
  String _suche = '';
  bool _nurUnverifiziert = false;
  Timer? _verzoegerung;

  @override
  void dispose() {
    _verzoegerung?.cancel();
    _sucheCtrl.dispose();
    super.dispose();
  }

  void _suchen(String text) {
    _verzoegerung?.cancel();
    _verzoegerung = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _suche = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final liste = ref.watch(adminCompaniesProvider(_suche));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          eyebrow: 'BETRIEBE',
          title: 'Betriebe',
          lede: widget.isAdmin
              ? 'Das Verifizierungs-Abzeichen bestätigt, dass hinter dem Profil '
                  'der echte Betrieb steht. Vergib es erst nach der Prüfung.'
              : 'Übersicht der Betriebe. Verifizieren dürfen nur '
                  'Administratoren.',
        ),
        const SizedBox(height: AppLayout.s32),
        Wrap(
          spacing: AppLayout.s16,
          runSpacing: AppLayout.s16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _sucheCtrl,
                onChanged: _suchen,
                decoration: const InputDecoration(
                  labelText: 'Nach Name suchen',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            AdminSegments<bool>(
              options: const [
                (false, 'Alle', null),
                (true, 'Unverifiziert', null)
              ],
              selected: _nurUnverifiziert,
              onSelected: (v) => setState(() => _nurUnverifiziert = v),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s24),
        liste.when(
          loading: () => const AdminLoadingList(count: 4, height: 72),
          error: (e, _) => AdminErrorBox(
            error: e,
            onRetry: () => ref.invalidate(adminCompaniesProvider(_suche)),
          ),
          data: (alle) {
            final betriebe = _nurUnverifiziert
                ? alle.where((b) => !b.isVerified).toList()
                : alle;
            if (betriebe.isEmpty) {
              return const AdminEmpty(
                icon: Icons.domain_outlined,
                title: 'Keine Betriebe gefunden',
                text: 'Ändere die Suche oder den Filter.',
              );
            }
            return AppRowGroup(
              children: [
                for (final b in betriebe)
                  _BetriebZeile(
                    key: ValueKey(b.companyId),
                    betrieb: b,
                    darfVerifizieren: widget.isAdmin,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BetriebZeile extends ConsumerStatefulWidget {
  final CompanyItem betrieb;
  final bool darfVerifizieren;

  const _BetriebZeile({
    super.key,
    required this.betrieb,
    required this.darfVerifizieren,
  });

  @override
  ConsumerState<_BetriebZeile> createState() => _BetriebZeileState();
}

class _BetriebZeileState extends ConsumerState<_BetriebZeile> {
  late bool _verifiziert = widget.betrieb.isVerified;
  bool _laeuft = false;

  Future<void> _umschalten(bool wert) async {
    setState(() {
      _laeuft = true;
      _verifiziert = wert;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .verifyCompany(widget.betrieb.companyId, wert);
      if (!mounted) return;
      showAdminSnack(
        context,
        wert
            ? '${widget.betrieb.name} ist jetzt verifiziert.'
            : 'Verifizierung von ${widget.betrieb.name} entfernt.',
      );
      ref.invalidate(adminOverviewProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifiziert = !wert);
      showAdminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.betrieb;
    final unterzeile = [
      if (b.industry?.isNotEmpty ?? false) b.industry!,
      if (b.city?.isNotEmpty ?? false) b.city!,
      '${b.reviewCount} ${b.reviewCount == 1 ? 'Bewertung' : 'Bewertungen'}',
      if (b.averageRating != null) 'Ø ${b.averageRating!.toStringAsFixed(1)}',
    ].join(' · ');

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.s24, vertical: AppLayout.s16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppLayout.s8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        b.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_verifiziert)
                        const AdminBadge('Verifiziert',
                            icon: Icons.verified_rounded,
                            tone: AdminTone.positive),
                      if (b.isPremium)
                        const AdminBadge('Premium',
                            icon: Icons.star_outline_rounded),
                      if (!b.hasOwner)
                        const AdminBadge('Ohne Konto',
                            icon: Icons.person_off_outlined,
                            tone: AdminTone.warning,
                            tooltip: 'Kein Betriebskonto verknüpft.'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(unterzeile,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (widget.darfVerifizieren) ...[
              const SizedBox(width: AppLayout.s16),
              Semantics(
                label: 'Verifiziert',
                toggled: _verifiziert,
                child: Switch(
                  value: _verifiziert,
                  onChanged: _laeuft ? null : _umschalten,
                  activeThumbColor: AppColors.paper,
                  activeTrackColor: AppColors.green,
                  inactiveThumbColor: AppColors.surface,
                  inactiveTrackColor: AppColors.line,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
