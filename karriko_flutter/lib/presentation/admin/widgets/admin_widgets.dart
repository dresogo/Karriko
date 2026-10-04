import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../common/app_page.dart';

// ── Töne ────────────────────────────────────────────────────────────────────

/// Bedeutung einer Markierung. Farbe allein trägt nie die Aussage — jedes
/// Abzeichen hat zusätzlich Icon und Text.
enum AdminTone { neutral, positive, warning, danger, info }

class _ToneColors {
  final Color background;
  final Color foreground;
  final Color border;

  const _ToneColors(this.background, this.foreground, this.border);
}

/// Alle Paare erreichen mindestens 4,5:1 Kontrast für kleine Schrift.
_ToneColors _farben(AdminTone tone) => switch (tone) {
      AdminTone.neutral =>
        const _ToneColors(AppColors.paper, AppColors.ink, AppColors.line),
      AdminTone.positive => const _ToneColors(
          Color(0xFFEDF2EE), Color(0xFF3B5241), Color(0xFFB9C9BD)),
      AdminTone.warning => const _ToneColors(
          Color(0xFFFFF4DB), Color(0xFF7A4B00), Color(0xFFF0D49A)),
      AdminTone.danger => const _ToneColors(
          AppColors.primaryLight, AppColors.accentDark, Color(0xFFF5B5B2)),
      AdminTone.info => const _ToneColors(
          AppColors.audienceBeige, AppColors.ink, AppColors.line),
    };

// ── Abzeichen ───────────────────────────────────────────────────────────────

class AdminBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AdminTone tone;
  final String? tooltip;

  const AdminBadge(
    this.label, {
    super.key,
    this.icon,
    this.tone = AdminTone.neutral,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final f = _farben(tone);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: f.background,
        border: Border.all(color: f.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: f.foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: f.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? badge : Tooltip(message: tooltip!, child: badge);
  }
}

/// Status einer Bewertung als Abzeichen.
AdminBadge reviewStatusBadge(String? status) => switch (status) {
      'pending_moderation' => const AdminBadge('Wartet',
          icon: Icons.hourglass_top_rounded, tone: AdminTone.warning),
      'scheduled' => const AdminBadge('Zurückgestellt',
          icon: Icons.schedule_rounded, tone: AdminTone.info),
      'approved' => const AdminBadge('Freigegeben',
          icon: Icons.check_circle_outline_rounded, tone: AdminTone.positive),
      'rejected' => const AdminBadge('Abgelehnt',
          icon: Icons.block_rounded, tone: AdminTone.danger),
      _ => AdminBadge(status ?? 'Unbekannt', icon: Icons.help_outline),
    };

/// Bezeichnung und Erklärung der Qualitäts-Flags aus `questionnaire_core`.
(String, String) flagText(String code) => switch (code) {
      'too_fast' => (
          'Zu schnell',
          'Die Antworten kamen schneller, als man die Fragen lesen kann.'
        ),
      'straightlining' => (
          'Gleichförmig',
          'Viele Fragen in Folge mit derselben Antwort.'
        ),
      'inconsistent_pair' => (
          'Widerspruch',
          'Zwei Antworten, die sich gegenseitig ausschließen.'
        ),
      'overall_detail_mismatch' => (
          'Gesamturteil passt nicht',
          'Das Gesamturteil weicht stark von den Einzelfragen ab.'
        ),
      'impossible_combination' => (
          'Unmögliche Angabe',
          'Eine Kombination, die es so nicht geben kann.'
        ),
      'text_needs_review' => (
          'Freitext prüfen',
          'Jeder Freitext geht durch die Moderation — kein Hinweis auf ein '
              'Problem.'
        ),
      _ => (code, 'Unbekannte Markierung.'),
    };

class FlagBadge extends StatelessWidget {
  final String code;

  const FlagBadge(this.code, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, erklaerung) = flagText(code);
    final harmlos = code == 'text_needs_review';
    return AdminBadge(
      label,
      icon: harmlos ? Icons.notes_rounded : Icons.flag_outlined,
      tone: harmlos ? AdminTone.neutral : AdminTone.warning,
      tooltip: erklaerung,
    );
  }
}

// ── Textblöcke ──────────────────────────────────────────────────────────────

/// Ein Freitext mit Kennzeichnung, ob er Lob oder Kritik ist.
class QuoteBlock extends StatelessWidget {
  final String label;
  final String text;
  final bool positive;

  const QuoteBlock({
    super.key,
    required this.label,
    required this.text,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(
          left: BorderSide(
            color: positive ? AppColors.green : AppColors.accent,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                positive ? Icons.add_rounded : Icons.remove_rounded,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              SectionLabel(label),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kennzahl mit Bezeichnung als Zeile: „Weiterempfehlung  7 / 10".
class MetaPair extends StatelessWidget {
  final String label;
  final String value;

  const MetaPair(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(label),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ── Kopf eines Abschnitts ───────────────────────────────────────────────────

class AdminSectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? lede;
  final Widget? action;

  const AdminSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.lede,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final breit = MediaQuery.sizeOf(context).width >= 720;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.32,
          ),
        ),
        const SizedBox(height: AppLayout.s8),
        Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: breit ? 40 : 30,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (lede != null) ...[
          const SizedBox(height: AppLayout.s16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(lede!, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ],
    );

    if (action == null) return text;
    if (!breit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [text, const SizedBox(height: AppLayout.s16), action!],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        const SizedBox(width: AppLayout.s24),
        action!,
      ],
    );
  }
}

// ── Zustände ────────────────────────────────────────────────────────────────

/// Platzhalter, solange geladen wird. Hält die Höhe, damit nichts springt.
class AdminLoadingList extends StatelessWidget {
  final int count;
  final double height;

  const AdminLoadingList({super.key, this.count = 3, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wird geladen',
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: AppLayout.s16),
            _Pulse(height: height),
          ],
        ],
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  final double height;

  const _Pulse({required this.height});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduzierte Bewegung: stehende Fläche statt Pulsieren.
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.all(AppLayout.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 180, height: 14, color: AppColors.paper),
            const SizedBox(height: 12),
            Container(width: 280, height: 10, color: AppColors.paper),
          ],
        ),
      ),
    );
  }
}

class AdminErrorBox extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const AdminErrorBox({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppLayout.s24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline,
                    size: 18, color: AppColors.accentDark),
                SizedBox(width: AppLayout.s8),
                Text(
                  'Laden fehlgeschlagen',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.s8),
            Text('$error', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppLayout.s16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const AdminEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.s24, vertical: AppLayout.s48),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.green),
          const SizedBox(height: AppLayout.s16),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppLayout.s8),
          Text(text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ── Filter ──────────────────────────────────────────────────────────────────

/// Segmentierte Auswahl im Swiss-Stil: Haarlinien, aktive Fläche in Tinte.
class AdminSegments<T> extends StatelessWidget {
  final List<(T, String, int?)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const AdminSegments({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppLayout.s8,
      runSpacing: AppLayout.s8,
      children: [
        for (final (wert, label, anzahl) in options)
          _Segment(
            label: anzahl == null ? label : '$label  $anzahl',
            active: wert == selected,
            onTap: () => onSelected(wert),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Segment(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? AppColors.ink : AppColors.surface,
        child: InkWell(
          onTap: onTap,
          hoverColor: active ? null : AppColors.paper,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border:
                  Border.all(color: active ? AppColors.ink : AppColors.line),
            ),
            // Kein `alignment`: Ein ausgerichteter Container dehnt sich auf
            // die volle Breite, die Segmente stünden dann untereinander.
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.paper : AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dialoge ─────────────────────────────────────────────────────────────────

/// Häufige Ablehnungsgründe. Der Verfasser liest die Begründung — sie muss
/// ohne Kontext verständlich sein.
const _vorlagen = [
  'Der Freitext nennt Personen beim Namen.',
  'Der Freitext enthält Beleidigungen.',
  'Die Bewertung ist offensichtlich nicht ernst gemeint.',
  'Die Angaben widersprechen sich so, dass die Bewertung nicht aussagekräftig ist.',
  'Kein Bezug zum Ausbildungsbetrieb erkennbar.',
];

/// Fragt die Begründung einer Ablehnung ab. `null` heißt abgebrochen.
Future<String?> showRejectDialog(BuildContext context, {String? subject}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RejectDialog(subject: subject),
  );
}

class _RejectDialog extends StatefulWidget {
  final String? subject;

  const _RejectDialog({this.subject});

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _ctrl = TextEditingController();
  bool _versucht = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _absenden() {
    if (_ctrl.text.trim().isEmpty) {
      setState(() => _versucht = true);
      return;
    }
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 2),
      ),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(widget.subject == null
          ? 'Bewertung ablehnen'
          : 'Bewertung zu ${widget.subject} ablehnen'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Der Verfasser sieht diese Begründung, nicht deinen Namen. Die '
              'Bewertung wird nicht gelöscht und lässt sich später freigeben.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppLayout.s16),
            const SectionLabel('Vorlagen'),
            const SizedBox(height: AppLayout.s8),
            Wrap(
              spacing: AppLayout.s8,
              runSpacing: AppLayout.s8,
              children: [
                for (final v in _vorlagen)
                  ActionChip(
                    label: Text(v),
                    onPressed: () => setState(() {
                      _ctrl.text = v;
                      _versucht = false;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppLayout.s16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Begründung *',
                alignLabelWithHint: true,
                errorText: _versucht
                    ? 'Eine Ablehnung braucht eine Begründung.'
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _absenden,
          icon: const Icon(Icons.block_rounded, size: 18),
          label: const Text('Ablehnen'),
        ),
      ],
    );
  }
}

/// Fragt eine freiwillige Notiz ab. `null` heißt abgebrochen, ein leerer Text
/// heißt bestätigt ohne Notiz.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? explanation,
}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 2),
      ),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (explanation != null) ...[
              Text(explanation,
                  style: Theme.of(dialogContext).textTheme.bodySmall),
              const SizedBox(height: AppLayout.s16),
            ],
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notiz (optional, nur intern)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ).whenComplete(ctrl.dispose);
}

// ── Formatierung ────────────────────────────────────────────────────────────

String formatDateTime(DateTime? d) {
  if (d == null) return '–';
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${germanDate(d)}, $hh:$mm';
}

/// „vor 3 Tagen" — für die Warteschlange, in der das Alter zählt.
String relativeAge(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'gerade eben';
  if (diff.inHours < 1) return 'vor ${diff.inMinutes} Min.';
  if (diff.inDays < 1) return 'vor ${diff.inHours} Std.';
  if (diff.inDays == 1) return 'vor 1 Tag';
  return 'vor ${diff.inDays} Tagen';
}

void showAdminSnack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 480,
        backgroundColor: error ? AppColors.accentDark : AppColors.ink,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: AppColors.paper,
              size: 18,
            ),
            const SizedBox(width: AppLayout.s8),
            Expanded(
              child: Text(text, style: const TextStyle(color: AppColors.paper)),
            ),
          ],
        ),
      ),
    );
}
