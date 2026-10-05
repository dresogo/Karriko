import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/questionnaire_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/app_page.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Werkzeuge, die selten gebraucht werden: Neuberechnung und Moderation über
/// eine Kennung. Nur für Administratoren.
class SystemSection extends StatelessWidget {
  const SystemSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(
          eyebrow: 'SYSTEM',
          title: 'Werkzeuge',
          lede: 'Selten gebraucht, mit Wirkung auf alle Bewertungen. Erst als '
              'Probelauf.',
        ),
        SizedBox(height: AppLayout.s48),
        _Neuberechnung(),
        SizedBox(height: AppLayout.s24),
        _ModerationPerId(),
        SizedBox(height: AppLayout.s24),
        _Konfiguration(),
      ],
    );
  }
}

class _Karte extends StatelessWidget {
  final IconData icon;
  final String titel;
  final String hinweis;
  final List<Widget> children;

  const _Karte({
    required this.icon,
    required this.titel,
    required this.hinweis,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.ink),
              const SizedBox(width: AppLayout.s8),
              Expanded(
                child: Text(titel,
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(hinweis, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: AppLayout.s24),
          ...children,
        ],
      ),
    );
  }
}

class _Ausgabe extends StatelessWidget {
  final String text;
  final bool fehler;

  const _Ausgabe(this.text, {required this.fehler});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: BoxDecoration(
        color: fehler ? AppColors.primaryLight : AppColors.paper,
        border: Border(
          left: BorderSide(
              color: fehler ? AppColors.accent : AppColors.ink, width: 3),
        ),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
          color: fehler ? AppColors.accentDark : AppColors.ink,
        ),
      ),
    );
  }
}

String _json(Map<String, Object?> m) =>
    const JsonEncoder.withIndent('  ').convert(m);

// ── Neuberechnung ───────────────────────────────────────────────────────────

class _Neuberechnung extends ConsumerStatefulWidget {
  const _Neuberechnung();

  @override
  ConsumerState<_Neuberechnung> createState() => _NeuberechnungState();
}

class _NeuberechnungState extends ConsumerState<_Neuberechnung> {
  final _versatzCtrl = TextEditingController(text: '0');
  bool _probelauf = true;
  bool _laeuft = false;
  String? _ergebnis;
  bool _fehler = false;

  @override
  void dispose() {
    _versatzCtrl.dispose();
    super.dispose();
  }

  Future<void> _starten() async {
    final versatz = int.tryParse(_versatzCtrl.text.trim()) ?? 0;
    setState(() => _laeuft = true);
    try {
      final antwort = await ref
          .read(adminRepositoryProvider)
          .recompute(offset: versatz, dryRun: _probelauf);
      setState(() {
        _ergebnis = _json(antwort);
        _fehler = false;
        // Die nächste Etappe gleich vorbereiten.
        final weiter = antwort['next_offset'];
        if (weiter is num) _versatzCtrl.text = weiter.round().toString();
      });
    } catch (e) {
      setState(() {
        _ergebnis = '$e';
        _fehler = true;
      });
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Karte(
      icon: Icons.calculate_outlined,
      titel: 'Alle Bewertungen neu rechnen',
      hinweis: 'Nötig, wenn sich Punktwerte, Gewichte oder Alterungsgrenzen '
          'geändert haben. Läuft in Etappen von 100; solange „done: false" '
          'kommt, mit dem eingetragenen Versatz erneut starten.',
      children: [
        Wrap(
          spacing: AppLayout.s24,
          runSpacing: AppLayout.s16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: TextField(
                controller: _versatzCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Versatz'),
              ),
            ),
            Semantics(
              toggled: _probelauf,
              child: InkWell(
                onTap: () => setState(() => _probelauf = !_probelauf),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _probelauf,
                        onChanged: (v) => setState(() => _probelauf = v),
                        activeThumbColor: AppColors.paper,
                        activeTrackColor: AppColors.ink,
                        inactiveThumbColor: AppColors.surface,
                        inactiveTrackColor: AppColors.line,
                      ),
                      const SizedBox(width: AppLayout.s8),
                      Text(
                        _probelauf
                            ? 'Probelauf – schreibt nichts'
                            : 'Ernstfall – schreibt alle Werte',
                        style: TextStyle(
                          color:
                              _probelauf ? AppColors.ink : AppColors.accentDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _laeuft ? null : _starten,
              style: _probelauf
                  ? FilledButton.styleFrom(backgroundColor: AppColors.ink)
                  : null,
              icon: _laeuft
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label:
                  Text(_probelauf ? 'Probelauf starten' : 'Jetzt neu rechnen'),
            ),
          ],
        ),
        if (_ergebnis != null) ...[
          const SizedBox(height: AppLayout.s16),
          _Ausgabe(_ergebnis!, fehler: _fehler),
        ],
      ],
    );
  }
}

// ── Moderation über die Kennung ─────────────────────────────────────────────

enum _Nachweis { unveraendert, belegt, nichtBelegt }

class _ModerationPerId extends ConsumerStatefulWidget {
  const _ModerationPerId();

  @override
  ConsumerState<_ModerationPerId> createState() => _ModerationPerIdState();
}

class _ModerationPerIdState extends ConsumerState<_ModerationPerId> {
  final _idCtrl = TextEditingController();
  _Nachweis _nachweis = _Nachweis.unveraendert;
  bool _laeuft = false;
  String? _ergebnis;
  bool _fehler = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _ausfuehren({required bool freigeben}) async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      setState(() {
        _ergebnis = 'Bewertungs-ID fehlt.';
        _fehler = true;
      });
      return;
    }
    String? grund;
    if (!freigeben) {
      grund = await showRejectDialog(context);
      if (grund == null) return;
    }

    setState(() => _laeuft = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      final antwort = freigeben
          ? await repo.approve(id,
              verified: switch (_nachweis) {
                _Nachweis.unveraendert => null,
                _Nachweis.belegt => true,
                _Nachweis.nichtBelegt => false,
              })
          : await repo.reject(id, grund!);
      setState(() {
        _ergebnis = _json(antwort);
        _fehler = false;
      });
      invalidateAdminData(ref);
    } catch (e) {
      setState(() {
        _ergebnis = '$e';
        _fehler = true;
      });
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Karte(
      icon: Icons.fingerprint_rounded,
      titel: 'Bewertung über die Kennung entscheiden',
      hinweis: 'Für Einzelfälle, die nicht in der Warteschlange stehen — etwa '
          'eine Kennung aus der Console oder aus einer Meldung per E-Mail.',
      children: [
        Wrap(
          spacing: AppLayout.s16,
          runSpacing: AppLayout.s16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _idCtrl,
                decoration: const InputDecoration(labelText: 'Bewertungs-ID'),
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<_Nachweis>(
                initialValue: _nachweis,
                decoration:
                    const InputDecoration(labelText: 'Nachweis (bei Freigabe)'),
                items: const [
                  DropdownMenuItem(
                      value: _Nachweis.unveraendert,
                      child: Text('Unverändert')),
                  DropdownMenuItem(
                      value: _Nachweis.belegt, child: Text('Geprüft, belegt')),
                  DropdownMenuItem(
                      value: _Nachweis.nichtBelegt,
                      child: Text('Nicht belegt')),
                ],
                onChanged: (v) => setState(() => _nachweis = v ?? _nachweis),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.s16),
        Wrap(
          spacing: AppLayout.s8,
          runSpacing: AppLayout.s8,
          children: [
            OutlinedButton.icon(
              onPressed: _laeuft ? null : () => _ausfuehren(freigeben: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentDark,
                side: const BorderSide(color: AppColors.accentDark),
              ),
              icon: const Icon(Icons.block_rounded, size: 18),
              label: const Text('Ablehnen'),
            ),
            FilledButton.icon(
              onPressed: _laeuft ? null : () => _ausfuehren(freigeben: true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Freigeben'),
            ),
          ],
        ),
        if (_ergebnis != null) ...[
          const SizedBox(height: AppLayout.s16),
          _Ausgabe(_ergebnis!, fehler: _fehler),
        ],
      ],
    );
  }
}

// ── Konfiguration ───────────────────────────────────────────────────────────

class _Konfiguration extends StatelessWidget {
  const _Konfiguration();

  @override
  Widget build(BuildContext context) {
    const zeilen = [
      ('Team Administration', QuestionnaireConstants.adminsTeam),
      ('Team Moderation', QuestionnaireConstants.moderatorsTeam),
      ('Arbeitstisch', QuestionnaireConstants.moderationDeskFunction),
      ('Entscheidung', QuestionnaireConstants.moderateReviewFunction),
      ('Neuberechnung', QuestionnaireConstants.recomputeAllFunction),
    ];
    return _Karte(
      icon: Icons.settings_ethernet_rounded,
      titel: 'Verbundene Kennungen',
      hinweis: 'Welche Teams und Functions dieser Build anspricht. Weichen sie '
          'von Appwrite ab, schlagen die Aufrufe mit 404 oder 403 fehl.',
      children: [
        for (final (label, wert) in zeilen)
          Padding(
            padding: const EdgeInsets.only(bottom: AppLayout.s8),
            child: Row(
              children: [
                SizedBox(width: 180, child: SectionLabel(label)),
                Expanded(
                  child: SelectableText(
                    wert,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
