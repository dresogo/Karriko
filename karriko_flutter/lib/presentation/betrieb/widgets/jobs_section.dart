import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/company_model.dart';
import '../../../data/models/job_model.dart';
import '../../../providers/company_provider.dart';
import '../../../providers/job_provider.dart';
import '../../common/app_page.dart';

/// Verwaltung der Ausbildungsstellen im Unternehmensprofil.
///
/// Der Bereich zeigt die eigenen Stellen – veröffentlichte wie Entwürfe – und
/// legt neue an. Das Formular erscheint erst auf Wunsch: Wer nur nachsehen
/// will, wie viele Stellen laufen, soll nicht an zwanzig Feldern vorbeiscrollen.
class BetriebJobsSection extends ConsumerStatefulWidget {
  final CompanyModel? company;
  final String? ownerId;

  const BetriebJobsSection({
    super.key,
    required this.company,
    required this.ownerId,
  });

  @override
  ConsumerState<BetriebJobsSection> createState() => _BetriebJobsSectionState();
}

class _BetriebJobsSectionState extends ConsumerState<BetriebJobsSection> {
  bool _formOffen = false;

  void _formSchliessen() => setState(() => _formOffen = false);

  void _melden(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        content: Text(text, style: const TextStyle(color: AppColors.paper)),
      ),
    );
  }

  /// Verwirft alles, was Stellen zeigt: die eigene Liste, das Band auf dem
  /// öffentlichen Profil und das Vorschlagsband der Suche.
  void _stellenNeuLaden() {
    ref.invalidate(myJobsProvider);
    ref.invalidate(jobSuggestionsProvider);
    final slug = widget.company?.slug;
    if (slug != null) ref.invalidate(companyJobsProvider(slug));
  }

  Future<void> _umschalten(JobModel job) async {
    try {
      await ref
          .read(jobRepositoryProvider)
          .setActive(jobId: job.id, isActive: !job.isActive);
      _stellenNeuLaden();
      _melden(job.isActive
          ? 'Stelle zurückgezogen. Sie ist jetzt ein Entwurf.'
          : 'Stelle veröffentlicht.');
    } catch (_) {
      _melden('Die Stelle konnte nicht geändert werden.');
    }
  }

  Future<void> _loeschen(JobModel job) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('Stelle löschen?',
            style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          '„${job.title}“ wird endgültig entfernt. Das lässt sich nicht '
          'rückgängig machen – zum Pausieren genügt „Zurückziehen“.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentDark),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (bestaetigt != true) return;

    try {
      await ref.read(jobRepositoryProvider).deleteJob(job.id);
      _stellenNeuLaden();
      _melden('Stelle gelöscht.');
    } catch (_) {
      _melden('Die Stelle konnte nicht gelöscht werden.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    // Ohne Unternehmen laesst sich keine Stelle anlegen – sie braucht dessen
    // Kennung und Adresse. Ob das Laden noch laeuft oder gescheitert ist,
    // entscheidet, was hier steht: Warten hilft nur im ersten Fall.
    final companyState = ref.watch(myCompanyProvider);
    final jobs = ref.watch(myJobsProvider);
    final liste = jobs.valueOrNull ?? const <JobModel>[];
    final veroeffentlicht = liste.where((j) => j.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Ausbildungsstellen')),
            if (liste.isNotEmpty)
              Text(
                '$veroeffentlicht von ${liste.length} veröffentlicht',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: AppLayout.s16),
        if (company == null)
          companyState.hasError
              ? const _Hinweis(
                  icon: Icons.error_outline,
                  text: 'Die Unternehmensdaten konnten nicht geladen werden. '
                      'Solange sie fehlen, lässt sich keine Stelle '
                      'ausschreiben – lade die Seite neu.',
                )
              : const _Hinweis(
                  icon: Icons.hourglass_empty,
                  text: 'Die Unternehmensdaten werden geladen. Danach lassen '
                      'sich Stellen anlegen.',
                )
        else if (jobs.hasError)
          const _Hinweis(
            icon: Icons.error_outline,
            text: 'Die Stellen konnten nicht geladen werden. Prüfe die '
                'Verbindung und lade die Seite neu.',
          )
        else ...[
          if (liste.isEmpty && !_formOffen)
            AppEmptyState(
              title: 'Noch keine Stelle ausgeschrieben',
              description:
                  'Veröffentliche deine erste Ausbildungsstelle. Sie erscheint '
                  'auf deinem Profil und in der Suche.',
              actionLabel: 'Stelle erstellen',
              onAction: () => setState(() => _formOffen = true),
            )
          else ...[
            for (final job in liste) ...[
              _JobRow(
                job: job,
                onToggle: () => _umschalten(job),
                onDelete: () => _loeschen(job),
              ),
              const SizedBox(height: AppLayout.s16),
            ],
            if (!_formOffen)
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _formOffen = true),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Weitere Stelle erstellen'),
                ),
              ),
          ],
          if (_formOffen) ...[
            const SizedBox(height: AppLayout.s8),
            _JobForm(
              company: company,
              ownerId: widget.ownerId,
              onCancel: _formSchliessen,
              onCreated: (veroeffentlicht) {
                _stellenNeuLaden();
                _formSchliessen();
                _melden(veroeffentlicht
                    ? 'Stelle veröffentlicht.'
                    : 'Entwurf gespeichert. Veröffentlichen kannst du ihn '
                        'jederzeit.');
              },
              onError: _melden,
            ),
          ],
        ],
      ],
    );
  }
}

// ─── Eine Stelle in der Liste ────────────────────────────────────────────────

class _JobRow extends StatelessWidget {
  final JobModel job;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _JobRow({
    required this.job,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (job.profession != null && job.profession!.isNotEmpty) job.profession!,
      if (job.location.isNotEmpty) job.location,
      if (job.startDate != null)
        'Start ${DateFormat('MM.yyyy').format(job.startDate!)}',
    ].join(' · ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: AppLayout.s16),
              _StatusTag(isActive: job.isActive),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppLayout.s8),
            Text(meta, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: AppLayout.s16),
          Wrap(
            spacing: AppLayout.s8,
            runSpacing: AppLayout.s8,
            children: [
              // Nur das Löschen traegt die Warnfarbe. Faerbte sie auch die
              // harmlosen Aktionen, hiesse Rot hier gar nichts mehr.
              TextButton.icon(
                onPressed: () => context.go('/stellen/${job.id}'),
                style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Ansehen'),
              ),
              TextButton.icon(
                onPressed: onToggle,
                style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                icon: Icon(
                  job.isActive ? Icons.visibility_off_outlined : Icons.publish,
                  size: 16,
                ),
                label: Text(job.isActive ? 'Zurückziehen' : 'Veröffentlichen'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.accentDark),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Löschen'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Zustand der Stelle. Text trägt die Bedeutung, die Farbe unterstützt sie nur.
class _StatusTag extends StatelessWidget {
  final bool isActive;

  const _StatusTag({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.audienceBeige : AppColors.paper,
        border: Border.all(
          color: isActive ? AppColors.green : AppColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.public : Icons.edit_note,
            size: 12,
            color: isActive ? AppColors.green : AppColors.muted,
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'VERÖFFENTLICHT' : 'ENTWURF',
            style: TextStyle(
              color: isActive ? AppColors.green : AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formular ────────────────────────────────────────────────────────────────

/// Auswahl der Stellenart. Steht auch als Aufmacher auf der Stellenseite.
const _arten = [
  'Ausbildung',
  'Duales Studium',
  'Praktikum',
  'Einstiegsqualifizierung',
];

class _JobForm extends ConsumerStatefulWidget {
  final CompanyModel company;
  final String? ownerId;
  final VoidCallback onCancel;
  final ValueChanged<bool> onCreated;
  final ValueChanged<String> onError;

  const _JobForm({
    required this.company,
    required this.ownerId,
    required this.onCancel,
    required this.onCreated,
    required this.onError,
  });

  @override
  ConsumerState<_JobForm> createState() => _JobFormState();
}

class _JobFormState extends ConsumerState<_JobForm> {
  final _formKey = GlobalKey<FormState>();
  final _titelCtrl = TextEditingController();
  final _berufCtrl = TextEditingController();
  final _ortCtrl = TextEditingController();
  final _dauerCtrl = TextEditingController();
  final _verguetungCtrl = TextEditingController();
  final _beschreibungCtrl = TextEditingController();
  final _aufgabenCtrl = TextEditingController();
  final _anforderungenCtrl = TextEditingController();
  final _angeboteCtrl = TextEditingController();
  final _mailCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  String _art = _arten.first;
  DateTime? _beginn;
  bool _veroeffentlichen = true;
  bool _speichert = false;

  @override
  void initState() {
    super.initState();
    // Standort und Beruf stehen im Unternehmensprofil – die Stelle erbt sie als
    // Vorschlag, statt sie erneut abzufragen.
    _ortCtrl.text = widget.company.location;
    _berufCtrl.text = widget.company.industry ?? '';
  }

  @override
  void dispose() {
    _titelCtrl.dispose();
    _berufCtrl.dispose();
    _ortCtrl.dispose();
    _dauerCtrl.dispose();
    _verguetungCtrl.dispose();
    _beschreibungCtrl.dispose();
    _aufgabenCtrl.dispose();
    _anforderungenCtrl.dispose();
    _angeboteCtrl.dispose();
    _mailCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  /// Eine Zeile ist ein Punkt. Leerzeilen und führende Aufzählungszeichen
  /// fallen weg, damit Einfügen aus einem Word-Dokument nicht auffällt.
  List<String> _punkte(TextEditingController ctrl) => ctrl.text
      .split('\n')
      .map((z) => z.replaceFirst(RegExp(r'^\s*[-•*]\s*'), '').trim())
      .where((z) => z.isNotEmpty)
      .toList();

  Future<void> _beginnWaehlen() async {
    final jetzt = DateTime.now();
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _beginn ?? DateTime(jetzt.year + 1, 8, 1),
      firstDate: DateTime(jetzt.year - 1),
      lastDate: DateTime(jetzt.year + 5),
      helpText: 'Ausbildungsbeginn',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (gewaehlt != null) setState(() => _beginn = gewaehlt);
  }

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    final ownerId = widget.ownerId;
    if (ownerId == null) {
      widget.onError('Das Konto ist nicht vollständig geladen.');
      return;
    }

    setState(() => _speichert = true);
    try {
      await ref.read(jobRepositoryProvider).createJob(
            ownerId: ownerId,
            companyId: widget.company.id,
            companyName: widget.company.name,
            companySlug: widget.company.slug,
            companyLogoUrl: widget.company.logoUrl,
            title: _titelCtrl.text,
            location: _ortCtrl.text,
            profession: _berufCtrl.text,
            industry: widget.company.industry,
            employmentType: _art,
            description: _beschreibungCtrl.text,
            tasks: _punkte(_aufgabenCtrl),
            requirements: _punkte(_anforderungenCtrl),
            benefits: _punkte(_angeboteCtrl),
            startDate: _beginn,
            duration: _dauerCtrl.text,
            salary: _verguetungCtrl.text,
            applyUrl: _linkCtrl.text,
            contactEmail: _mailCtrl.text,
            isActive: _veroeffentlichen,
          );
      if (!mounted) return;
      widget.onCreated(_veroeffentlichen);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      widget.onError('Die Stelle konnte nicht gespeichert werden.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 720;

    return AppCard(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Neue Ausbildungsstelle',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppLayout.s8),
            Text(
              'Pflicht sind Titel und Standort. Alles Weitere erscheint auf der '
              'Stellenseite, sobald es ausgefüllt ist.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppLayout.s32),
            _Labeled(
              label: 'Titel der Stelle',
              child: TextFormField(
                controller: _titelCtrl,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
                decoration: const InputDecoration(
                  hintText: 'Ausbildung zur Zerspanungsmechanikerin (m/w/d)',
                ),
                validator: (v) => Validators.required(v, label: 'Titel'),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            _Zeile(
              isWide: isWide,
              links: _Labeled(
                label: 'Art der Stelle',
                child: DropdownButtonFormField<String>(
                  initialValue: _art,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  items: _arten
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => _art = v ?? _arten.first),
                ),
              ),
              rechts: _Labeled(
                label: 'Beruf',
                child: TextFormField(
                  controller: _berufCtrl,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  decoration:
                      const InputDecoration(hintText: 'Zerspanungsmechanik'),
                ),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            _Zeile(
              isWide: isWide,
              links: _Labeled(
                label: 'Standort',
                child: TextFormField(
                  controller: _ortCtrl,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  validator: (v) => Validators.required(v, label: 'Standort'),
                ),
              ),
              rechts: _Labeled(
                label: 'Ausbildungsbeginn',
                child: _DateField(
                  value: _beginn,
                  onTap: _beginnWaehlen,
                  onClear: () => setState(() => _beginn = null),
                ),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            _Zeile(
              isWide: isWide,
              links: _Labeled(
                label: 'Dauer',
                child: TextFormField(
                  controller: _dauerCtrl,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  decoration: const InputDecoration(hintText: '3,5 Jahre'),
                ),
              ),
              rechts: _Labeled(
                label: 'Vergütung',
                child: TextFormField(
                  controller: _verguetungCtrl,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  decoration:
                      const InputDecoration(hintText: '1. Jahr 1.050 €'),
                ),
              ),
            ),
            const SizedBox(height: AppLayout.s32),
            _Labeled(
              label: 'Beschreibung',
              child: TextFormField(
                controller: _beschreibungCtrl,
                maxLines: 5,
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
                decoration: const InputDecoration(
                  hintText: 'Worum geht es in dieser Ausbildung?',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: AppLayout.s24),
            _ListenFeld(
              label: 'Aufgaben',
              hilfe: 'Eine Zeile pro Punkt.',
              controller: _aufgabenCtrl,
              hint: 'CNC-Maschinen einrichten und bedienen',
            ),
            const SizedBox(height: AppLayout.s24),
            _ListenFeld(
              label: 'Anforderungen',
              hilfe: 'Eine Zeile pro Punkt.',
              controller: _anforderungenCtrl,
              hint: 'Mittlere Reife oder Sekundarabschluss',
            ),
            const SizedBox(height: AppLayout.s24),
            _ListenFeld(
              label: 'Das bietet ihr',
              hilfe: 'Eine Zeile pro Punkt.',
              controller: _angeboteCtrl,
              hint: 'Feste Ansprechperson über die gesamte Ausbildung',
            ),
            const SizedBox(height: AppLayout.s32),
            _Zeile(
              isWide: isWide,
              links: _Labeled(
                label: 'Bewerbung per E-Mail',
                child: TextFormField(
                  controller: _mailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  decoration:
                      const InputDecoration(hintText: 'ausbildung@betrieb.de'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? null
                      : Validators.email(v),
                ),
              ),
              rechts: _Labeled(
                label: 'Oder Link zum Bewerbungsformular',
                child: TextFormField(
                  controller: _linkCtrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  decoration: const InputDecoration(hintText: 'https://'),
                  validator: Validators.url,
                ),
              ),
            ),
            const SizedBox(height: AppLayout.s8),
            Text(
              'Ohne beides führt die Stellenseite auf euer Betriebsprofil.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppLayout.s32),
            AppRowGroup(
              children: [
                AppSwitchRow(
                  icon: Icons.public,
                  title: 'Sofort veröffentlichen',
                  subtitle: _veroeffentlichen
                      ? 'Erscheint im Profil und in der Suche'
                      : 'Wird als Entwurf gespeichert',
                  value: _veroeffentlichen,
                  onChanged: (v) => setState(() => _veroeffentlichen = v),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.s32),
            Wrap(
              spacing: AppLayout.s16,
              runSpacing: AppLayout.s16,
              children: [
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _speichert ? null : widget.onCancel,
                    child: const Text('Abbrechen'),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _speichert ? null : _speichern,
                    child: Text(
                      _speichert
                          ? 'Wird gespeichert …'
                          : (_veroeffentlichen
                              ? 'Veröffentlichen'
                              : 'Als Entwurf speichern'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bausteine des Formulars ─────────────────────────────────────────────────

/// Zwei Felder nebeneinander, auf schmalen Viewports untereinander.
class _Zeile extends StatelessWidget {
  final bool isWide;
  final Widget links;
  final Widget rechts;

  const _Zeile({
    required this.isWide,
    required this.links,
    required this.rechts,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          links,
          const SizedBox(height: AppLayout.s24),
          rechts,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: links),
        const SizedBox(width: AppLayout.s24),
        Expanded(child: rechts),
      ],
    );
  }
}

class _ListenFeld extends StatelessWidget {
  final String label;
  final String hilfe;
  final String hint;
  final TextEditingController controller;

  const _ListenFeld({
    required this.label,
    required this.hilfe,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _Labeled(
      label: label,
      hilfe: hilfe,
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        style: const TextStyle(fontSize: 16, color: AppColors.ink),
        decoration: InputDecoration(hintText: hint, alignLabelWithHint: true),
      ),
    );
  }
}

/// Datumsfeld ohne Tastatureingabe: Der Kalender ist hier verlässlicher als ein
/// Freitext, den anschliessend jemand deuten müsste.
class _DateField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Kein Datum gewählt'
        : DateFormat('MM.yyyy').format(value!);

    return Semantics(
      button: true,
      label: 'Ausbildungsbeginn: $text',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: AppLayout.s16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
          child: Row(
            children: [
              const Icon(Icons.event_outlined,
                  size: 18, color: AppColors.muted),
              const SizedBox(width: AppLayout.s16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: value == null ? AppColors.muted : AppColors.ink,
                  ),
                ),
              ),
              if (value != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, size: 18),
                  color: AppColors.muted,
                  tooltip: 'Datum entfernen',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final String? hilfe;
  final Widget child;

  const _Labeled({required this.label, required this.child, this.hilfe});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          if (hilfe != null) ...[
            const SizedBox(height: 2),
            Text(hilfe!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: AppLayout.s8),
          child,
        ],
      ),
    );
  }
}

class _Hinweis extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hinweis({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s16),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(left: BorderSide(color: AppColors.line, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: AppLayout.s8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
