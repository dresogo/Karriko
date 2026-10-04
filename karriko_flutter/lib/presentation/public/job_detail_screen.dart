import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/company_model.dart';
import '../../data/models/job_model.dart';
import '../../providers/company_provider.dart';
import '../../providers/job_provider.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

/// Seite eines einzelnen Stellenangebots.
///
/// Anders als das Betriebsprofil steht hier die Stelle im Vordergrund: grosser
/// Titel, Eckdaten und Inhalt der Ausschreibung. Der Betrieb kommt nur als
/// schmaler Streifen vor, der auf sein Profil führt.
class JobDetailScreen extends ConsumerWidget {
  final String id;
  const JobDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(jobByIdProvider(id));

    return Scaffold(
      appBar: const KarrikoAppBar(),
      drawer: const KarrikoDrawer(),
      body: job.when(
        data: (j) => _JobDetailBody(job: j),
        loading: () => const _LoadingState(),
        error: (_, __) => const _NotFoundState(),
      ),
    );
  }
}

class _JobDetailBody extends ConsumerWidget {
  final JobModel job;
  const _JobDetailBody({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Für den Betriebsstreifen: Note und Anzahl der Bewertungen stehen im
    // Unternehmensdokument, nicht an der Stelle.
    final company = ref.watch(companyBySlugProvider(job.companySlug));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _JobHeroBand(job: job),
          _FactsBand(job: job),
          _CompanyStrip(job: job, company: company.valueOrNull),
          if (job.hasDetails) _JobContentBand(job: job),
          _ApplyBand(job: job),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _JobHeroBand extends StatelessWidget {
  final JobModel job;

  const _JobHeroBand({required this.job});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 980;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: EdgeInsets.only(
          top: isWide ? AppLayout.s64 : AppLayout.s48,
          bottom: isWide ? AppLayout.s64 : AppLayout.s48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppLayout.s16,
              runSpacing: AppLayout.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Eyebrow(
                  text: [
                    (job.employmentType ?? 'AUSBILDUNGSSTELLE').toUpperCase(),
                    if (job.industry != null && job.industry!.isNotEmpty)
                      job.industry!.toUpperCase(),
                  ].join(' · '),
                  color: AppColors.accent,
                ),
                if (job.badge.isNotEmpty) _JobBadge(job: job),
              ],
            ),
            const SizedBox(height: AppLayout.s24),
            // Die Stelle trägt die Seite: Titel so gross, wie die Breite es
            // hergibt, auf Textlänge begrenzt.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Text(
                job.title,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: (width * 0.055).clamp(34.0, 72.0),
                  fontWeight: FontWeight.w800,
                  height: 0.98,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            Wrap(
              spacing: AppLayout.s24,
              runSpacing: AppLayout.s8,
              children: [
                if (job.location.isNotEmpty)
                  _MetaItem(icon: Icons.place_outlined, label: job.location),
                if (job.profession != null && job.profession!.isNotEmpty)
                  _MetaItem(icon: Icons.work_outline, label: job.profession!),
                if (job.startDate != null)
                  _MetaItem(
                    icon: Icons.event_outlined,
                    label:
                        'Start ${DateFormat('MM.yyyy').format(job.startDate!)}',
                  ),
                if (job.duration != null && job.duration!.isNotEmpty)
                  _MetaItem(
                      icon: Icons.schedule_outlined, label: job.duration!),
                if (job.salary != null && job.salary!.isNotEmpty)
                  _MetaItem(icon: Icons.payments_outlined, label: job.salary!),
              ],
            ),
            const SizedBox(height: AppLayout.s32),
            Wrap(
              spacing: AppLayout.s16,
              runSpacing: AppLayout.s16,
              children: [
                _ApplyButton(job: job),
                OutlinedButton.icon(
                  onPressed: () => context.go('/company/${job.companySlug}'),
                  icon: const Icon(Icons.business_outlined, size: 18),
                  label: const Text('Betrieb ansehen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Primäre Handlung. Ohne hinterlegten Bewerbungsweg führt sie auf das
/// Betriebsprofil, statt einen zu behaupten.
class _ApplyButton extends StatelessWidget {
  final JobModel job;

  const _ApplyButton({required this.job});

  @override
  Widget build(BuildContext context) {
    final contact = job.contactEmail;

    if (job.applyUrl == null && contact == null) {
      return ElevatedButton.icon(
        onPressed: () => context.go('/company/${job.companySlug}'),
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text('Zum Betrieb bewerben'),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => _ApplyDialog(job: job),
      ),
      icon: const Icon(Icons.send_outlined, size: 18),
      label: const Text('Jetzt bewerben'),
    );
  }
}

/// Zeigt den Bewerbungsweg zum Kopieren an. Die App öffnet weder Mail- noch
/// Web-Adressen selbst – dafür fehlt die Abhängigkeit.
class _ApplyDialog extends StatelessWidget {
  final JobModel job;

  const _ApplyDialog({required this.job});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.ink, width: 2),
      ),
      title:
          Text('Bewerbung', style: Theme.of(context).textTheme.headlineSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Die Bewerbung läuft direkt über ${job.company}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppLayout.s16),
          if (job.contactEmail != null)
            SelectableText(
              job.contactEmail!,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          if (job.applyUrl != null)
            SelectableText(
              job.applyUrl!,
              style: Theme.of(context).textTheme.labelLarge,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schliessen'),
        ),
      ],
    );
  }
}

class _JobBadge extends StatelessWidget {
  final JobModel job;

  const _JobBadge({required this.job});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (job.badgeVariant) {
      JobBadgeVariant.isNew => (AppColors.accent, Colors.white),
      JobBadgeVariant.recent => (AppColors.audienceBeige, AppColors.ink),
      JobBadgeVariant.days => (AppColors.paper, AppColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: job.badgeVariant == JobBadgeVariant.isNew
              ? AppColors.accent
              : AppColors.line,
        ),
      ),
      child: Text(
        job.badge.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.88,
        ),
      ),
    );
  }
}

// ─── Eckdaten ────────────────────────────────────────────────────────────────

class _FactsBand extends StatelessWidget {
  final JobModel job;

  const _FactsBand({required this.job});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 720;

    final cells = <(String, String)>[
      (job.profession ?? '–', 'Beruf'),
      (job.location.isEmpty ? '–' : job.location, 'Standort'),
      (
        job.startDate != null
            ? DateFormat('MM.yyyy').format(job.startDate!)
            : (job.duration ?? '–'),
        job.startDate != null ? 'Beginn' : 'Dauer',
      ),
      (DateFormat('dd.MM.yyyy').format(job.createdAt), 'Veröffentlicht'),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        // Table statt Row mit IntrinsicHeight: Die Zeilenhöhe stimmt auch bei
        // umbrechenden Werten, und die Trennlinien laufen über die volle Höhe.
        child: isWide
            ? Table(
                defaultColumnWidth: const FlexColumnWidth(),
                border: const TableBorder(
                  verticalInside: BorderSide(color: AppColors.line),
                ),
                children: [
                  TableRow(
                    children: [
                      for (var i = 0; i < cells.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            top: AppLayout.s32,
                            bottom: AppLayout.s32,
                            right: AppLayout.s24,
                            left: i == 0 ? 0 : AppLayout.s24,
                          ),
                          child:
                              _FactCell(value: cells[i].$1, label: cells[i].$2),
                        ),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cells.length; i++)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: i == cells.length - 1
                              ? BorderSide.none
                              : const BorderSide(color: AppColors.line),
                        ),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppLayout.s24),
                      child: _FactCell(value: cells[i].$1, label: cells[i].$2),
                    ),
                ],
              ),
      ),
    );
  }
}

class _FactCell extends StatelessWidget {
  final String value;
  final String label;

  const _FactCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Betrieb ─────────────────────────────────────────────────────────────────

/// Der Betrieb bleibt bewusst schmal: eine Zeile mit Zeichen, Name und Note,
/// die auf das Profil führt.
class _CompanyStrip extends StatefulWidget {
  final JobModel job;
  final CompanyModel? company;

  const _CompanyStrip({required this.job, required this.company});

  @override
  State<_CompanyStrip> createState() => _CompanyStripState();
}

class _CompanyStripState extends State<_CompanyStrip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final rating = company?.averageRating;
    final reviewCount = company?.reviewCount ?? 0;

    final subtitle = [
      if (rating != null)
        '${rating.toStringAsFixed(1).replaceAll('.', ',')} ★ '
            '($reviewCount ${reviewCount == 1 ? 'Bewertung' : 'Bewertungen'})',
      if (widget.job.location.isNotEmpty) widget.job.location,
    ].join(' · ');

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ContentBand(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.s16),
        child: Semantics(
          button: true,
          label: 'Betriebsprofil von ${widget.job.company} öffnen',
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/company/${widget.job.companySlug}'),
              onHover: (v) => setState(() => _hovered = v),
              onFocusChange: (v) => setState(() => _focused = v),
              hoverColor: AppColors.audienceBeige.withValues(alpha: 0.6),
              focusColor: AppColors.audienceBeige,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: AppLayout.s16),
                foregroundDecoration: BoxDecoration(
                  border: Border.all(
                    color: _focused ? AppColors.ink : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    _CompanyMark(name: widget.job.company),
                    const SizedBox(width: AppLayout.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _Eyebrow(text: 'AUSGESCHRIEBEN VON'),
                          const SizedBox(height: 4),
                          Text(
                            widget.job.company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppLayout.s16),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      offset: _hovered || _focused
                          ? const Offset(0.25, 0)
                          : Offset.zero,
                      child: const Icon(Icons.arrow_forward,
                          size: 20, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyMark extends StatelessWidget {
  final String name;

  const _CompanyMark({required this.name});

  @override
  Widget build(BuildContext context) {
    final words =
        name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).toList();
    final initials = words.isEmpty
        ? '?'
        : words.map((w) => w.characters.first.toUpperCase()).join();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Inhalt der Ausschreibung ────────────────────────────────────────────────

class _JobContentBand extends StatelessWidget {
  final JobModel job;

  const _JobContentBand({required this.job});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 980;

    final blocks = <Widget>[
      if (job.description != null && job.description!.trim().isNotEmpty)
        _ContentBlock(
          heading: 'Um die Stelle\ngeht es.',
          isWide: isWide,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              job.description!,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.muted, height: 1.6),
            ),
          ),
        ),
      if (job.tasks.isNotEmpty)
        _ContentBlock(
          heading: 'Deine\nAufgaben.',
          isWide: isWide,
          child: _NumberedList(items: job.tasks),
        ),
      if (job.requirements.isNotEmpty)
        _ContentBlock(
          heading: 'Das bringst\ndu mit.',
          isWide: isWide,
          child: _NumberedList(items: job.requirements),
        ),
      if (job.benefits.isNotEmpty)
        _ContentBlock(
          heading: 'Das bietet\nder Betrieb.',
          isWide: isWide,
          child: _NumberedList(items: job.benefits),
        ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            blocks[i],
          ],
        ],
      ),
    );
  }
}

class _ContentBlock extends StatelessWidget {
  final String heading;
  final Widget child;
  final bool isWide;

  const _ContentBlock({
    required this.heading,
    required this.child,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final title = Text(
      heading,
      style: Theme.of(context).textTheme.displaySmall,
    );

    return ContentBand(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 40, child: title),
                const SizedBox(width: AppLayout.s64),
                Expanded(flex: 60, child: child),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: AppLayout.s24),
                child,
              ],
            ),
    );
  }
}

/// Aufzählung im Stil der Startseite: laufende Nummer in Akzentfarbe, Text
/// daneben, Haarlinie darunter.
class _NumberedList extends StatelessWidget {
  final List<String> items;

  const _NumberedList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppLayout.s16),
            decoration: BoxDecoration(
              border: Border(
                bottom: i == items.length - 1
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.line),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    (i + 1).toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    items[i],
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Abschluss ───────────────────────────────────────────────────────────────

/// Tintenfläche am Seitenende: die Handlung noch einmal, ohne Ablenkung.
class _ApplyBand extends StatelessWidget {
  final JobModel job;

  const _ApplyBand({required this.job});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 980;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INTERESSE AN DIESER STELLE?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.96,
          ),
        ),
        const SizedBox(height: AppLayout.s16),
        Text(
          'Bewirb dich\nbei ${job.company}.',
          style: TextStyle(
            color: Colors.white,
            fontSize: (width * 0.04).clamp(28.0, 48.0),
            fontWeight: FontWeight.w800,
            height: 1.02,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: AppLayout.s16,
      runSpacing: AppLayout.s16,
      children: [
        _ApplyButton(job: job),
        OutlinedButton.icon(
          onPressed: () => context.go('/search'),
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Weitere Stellen'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
          ),
        ),
      ],
    );

    return Container(
      color: AppColors.ink,
      child: ContentBand(
        padding: EdgeInsets.symmetric(
          vertical: isWide ? AppLayout.s64 : AppLayout.s48,
        ),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppLayout.s32),
                  actions,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: AppLayout.s32),
                  actions,
                ],
              ),
      ),
    );
  }
}

// ─── Zustände ────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ContentBand(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 12, width: 200, color: AppColors.line),
          const SizedBox(height: AppLayout.s24),
          Container(height: 56, width: 520, color: AppColors.line),
          const SizedBox(height: AppLayout.s16),
          Container(height: 16, width: 280, color: AppColors.audienceBeige),
        ],
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    return ContentBand(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.s64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow(text: 'STELLENANGEBOT', color: AppColors.accent),
          const SizedBox(height: AppLayout.s16),
          Text(
            'Diese Stelle gibt\nes nicht mehr.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppLayout.s16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Das Angebot wurde zurückgezogen oder die Adresse stimmt nicht. '
              'Über die Suche findest du weitere Ausbildungsstellen.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppLayout.s24),
          OutlinedButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Zur Suche'),
          ),
        ],
      ),
    );
  }
}

// ─── Bausteine ───────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  final String text;
  final Color color;

  const _Eyebrow({required this.text, this.color = AppColors.muted});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.96,
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
