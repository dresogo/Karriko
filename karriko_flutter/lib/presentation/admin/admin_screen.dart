import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/admin_repository.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_shell.dart';
import 'admin_providers.dart';
import 'admin_sections.dart';
import 'sections/companies_section.dart';
import 'sections/log_section.dart';
import 'sections/moderation_section.dart';
import 'sections/overview_section.dart';
import 'sections/reports_section.dart';
import 'sections/system_section.dart';

/// Interner Bereich unter `/admin`.
///
/// **Bewusst ohne Verweis aus der Oberfläche** — erreichbar nur über die
/// Adresse. Das ist kein Schutz, nur Ruhe: Geschützt sind die Aktionen durch
/// die Ausführungsrechte der Functions. Wer kein Mitglied von `admins` oder
/// `moderators` ist, sieht nach der Anmeldung nur „kein Zugang".
class AdminScreen extends ConsumerWidget {
  /// Adressteil des geöffneten Bereichs, aus `?bereich=`.
  final String? section;

  const AdminScreen({super.key, this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (!auth.isAuthenticated) return const _AdminLogin();

    return ref.watch(adminRolesProvider).when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.paper,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _KeinZugang(
            text: 'Die Teams des Kontos ließen sich nicht lesen: $e',
          ),
          data: (rollen) => rollen.mayModerate
              ? AdminShell(
                  rollen: rollen,
                  section: AdminSection.fromSlug(section),
                )
              : const _KeinZugang(
                  text: 'Dieses Konto ist weder im Team „admins" noch in '
                      '„moderators". Mitglieder trägt ein Administrator in '
                      'der Appwrite-Console ein.',
                ),
        );
  }
}

// ── Anmeldung ───────────────────────────────────────────────────────────────

class _AdminLogin extends ConsumerStatefulWidget {
  const _AdminLogin();

  @override
  ConsumerState<_AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends ConsumerState<_AdminLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _verdeckt = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (ref.read(authProvider).isAuthenticated) {
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final breit = MediaQuery.sizeOf(context).width >= 900;

    final marke = Container(
      color: AppColors.ink,
      padding: EdgeInsets.all(breit ? AppLayout.s64 : AppLayout.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'KARRIKO',
            style: TextStyle(
              color: AppColors.paper,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: breit ? AppLayout.s64 : AppLayout.s32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INTERN',
                style: TextStyle(
                  color: Color(0xFFFF8A86),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.32,
                ),
              ),
              const SizedBox(height: AppLayout.s16),
              Text(
                'Admin-\nBereich.',
                style: TextStyle(
                  color: AppColors.paper,
                  fontSize: breit ? 72 : 44,
                  fontWeight: FontWeight.w800,
                  height: 0.92,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: AppLayout.s24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const Text(
                  'Moderation, Meldungen und Betriebe. Zugang nur für '
                  'Mitglieder der Teams Administration und Moderation.',
                  style: TextStyle(
                    color: Color(0xFFC9C9C2),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
          if (breit) ...[
            const SizedBox(height: AppLayout.s64),
            const Text(
              'Jede Entscheidung wird mit Namen protokolliert.',
              style: TextStyle(color: Color(0xFF9A9A93), fontSize: 13),
            ),
          ],
        ],
      ),
    );

    final formular = Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: breit ? AppLayout.s64 : AppLayout.s24,
        vertical: AppLayout.s48,
      ),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Anmelden',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppLayout.s8),
                Text('Mit dem Konto, das in Appwrite einem der Teams angehört.',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppLayout.s32),
                if (auth.error != null) ...[
                  LoginErrorBanner(auth.error!),
                  const SizedBox(height: AppLayout.s24),
                ],
                TextFormField(
                  controller: _emailCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nutzername (E-Mail-Adresse)',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: Validators.email,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: AppLayout.s16),
                TextFormField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _verdeckt,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Passwort',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _verdeckt
                          ? 'Passwort anzeigen'
                          : 'Passwort verbergen',
                      icon: Icon(_verdeckt
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _verdeckt = !_verdeckt),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Passwort ist erforderlich'
                      : null,
                  onFieldSubmitted: (_) {
                    if (!auth.isLoading) _submit();
                  },
                ),
                const SizedBox(height: AppLayout.s32),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style:
                        FilledButton.styleFrom(backgroundColor: AppColors.ink),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Anmelden'),
                  ),
                ),
                const SizedBox(height: AppLayout.s16),
                const LoginTrustNote(
                    'Geschützt durch Appwrite Auth · SSL-verschlüsselt'),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: breit
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: marke),
                Expanded(flex: 6, child: formular),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [marke, formular],
              ),
            ),
    );
  }
}

class _KeinZugang extends ConsumerWidget {
  final String text;

  const _KeinZugang({required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentUserProvider)?.email;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppLayout.s24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(AppLayout.s32),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border:
                    Border(top: BorderSide(color: AppColors.accent, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_person_outlined,
                      size: 32, color: AppColors.accentDark),
                  const SizedBox(height: AppLayout.s16),
                  Text('Kein Zugang',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: AppLayout.s16),
                  Text(text, style: Theme.of(context).textTheme.bodyMedium),
                  if (email != null) ...[
                    const SizedBox(height: AppLayout.s8),
                    Text('Angemeldet als $email',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: AppLayout.s24),
                  Wrap(
                    spacing: AppLayout.s8,
                    runSpacing: AppLayout.s8,
                    children: [
                      FilledButton(
                        onPressed: () =>
                            ref.read(authProvider.notifier).signOut(),
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink),
                        child: const Text('Mit anderem Konto anmelden'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Zur Website'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dashboard ───────────────────────────────────────────────────────────────

class AdminShell extends ConsumerWidget {
  final AdminRoles rollen;
  final AdminSection section;

  const AdminShell({super.key, required this.rollen, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breit = MediaQuery.sizeOf(context).width >= 1024;
    final user = ref.watch(currentUserProvider);

    // Ein Moderator, der `?bereich=system` aufruft, landet in der Übersicht.
    final aktiv =
        section.adminOnly && !rollen.isAdmin ? AdminSection.overview : section;

    void gehe(AdminSection s) {
      if (!breit) Navigator.of(context).maybePop();
      context.go('/admin?bereich=${s.slug}');
    }

    final inhalt = switch (aktiv) {
      AdminSection.overview => OverviewSection(
          name: user?.firstName?.isNotEmpty == true ? user!.firstName : null,
          onNavigate: gehe,
        ),
      AdminSection.moderation => const ModerationSection(),
      AdminSection.reports => const ReportsSection(),
      AdminSection.log => const LogSection(),
      AdminSection.companies => CompaniesSection(isAdmin: rollen.isAdmin),
      AdminSection.system => const SystemSection(),
    };

    final seitenleiste = _Seitenleiste(
      aktiv: aktiv,
      rollen: rollen,
      email: user?.email ?? '',
      onSelect: gehe,
    );

    final flaeche = SingleChildScrollView(
      key: PageStorageKey(aktiv),
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.gutter(MediaQuery.sizeOf(context).width) / 1.5,
        vertical: breit ? AppLayout.s64 : AppLayout.s32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(key: ValueKey(aktiv), child: inhalt),
          ),
        ),
      ),
    );

    if (breit) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 272, child: seitenleiste),
            Expanded(child: flaeche),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        iconTheme: const IconThemeData(color: AppColors.paper),
        titleTextStyle: const TextStyle(
          color: AppColors.paper,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        title: Text('Admin · ${aktiv.label}'),
      ),
      drawer: Drawer(
        width: 288,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: seitenleiste,
      ),
      body: flaeche,
    );
  }
}

class _Seitenleiste extends ConsumerWidget {
  final AdminSection aktiv;
  final AdminRoles rollen;
  final String email;
  final ValueChanged<AdminSection> onSelect;

  const _Seitenleiste({
    required this.aktiv,
    required this.rollen,
    required this.email,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zahlen = ref.watch(adminOverviewProvider).valueOrNull;

    int? zaehler(AdminSection s) => switch (s) {
          AdminSection.moderation => zahlen?.pending,
          AdminSection.reports => zahlen?.openReports,
          _ => null,
        };

    return Container(
      color: AppColors.ink,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KARRIKO',
                    style: TextStyle(
                      color: AppColors.paper,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ADMIN-BEREICH',
                    style: TextStyle(
                      color: Color(0xFFFF8A86),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.32,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final s in AdminSection.values)
                    if (!s.adminOnly || rollen.isAdmin)
                      _NavEintrag(
                        section: s,
                        aktiv: s == aktiv,
                        zaehler: zaehler(s),
                        onTap: () => onSelect(s),
                      ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2E2E2C), height: 1),
            Padding(
              padding: const EdgeInsets.all(AppLayout.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.paper,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rollen.isAdmin ? 'Administration' : 'Moderation',
                    style:
                        const TextStyle(color: Color(0xFF9A9A93), fontSize: 12),
                  ),
                  const SizedBox(height: AppLayout.s16),
                  // Untereinander: Nebeneinander passte „Abmelden" bei
                  // 272 px nicht mehr ganz hinein.
                  _LeisteKnopf(
                    icon: Icons.open_in_new_rounded,
                    label: 'Zur Website',
                    onTap: () => context.go('/'),
                  ),
                  const SizedBox(height: AppLayout.s8),
                  _LeisteKnopf(
                    icon: Icons.logout_rounded,
                    label: 'Abmelden',
                    onTap: () => ref.read(authProvider.notifier).signOut(),
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

class _NavEintrag extends StatelessWidget {
  final AdminSection section;
  final bool aktiv;
  final int? zaehler;
  final VoidCallback onTap;

  const _NavEintrag({
    required this.section,
    required this.aktiv,
    required this.zaehler,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final farbe = aktiv ? AppColors.paper : const Color(0xFFBDBDB6);
    return Semantics(
      selected: aktiv,
      button: true,
      child: Material(
        color: aktiv ? const Color(0xFF242422) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: const Color(0xFF1C1C1B),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: aktiv ? AppColors.accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(section.icon, size: 20, color: farbe),
                const SizedBox(width: AppLayout.s16),
                Expanded(
                  child: Text(
                    section.label,
                    style: TextStyle(
                      color: farbe,
                      fontSize: 15,
                      fontWeight: aktiv ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (zaehler != null && zaehler! > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    color: AppColors.accent,
                    child: Text(
                      '$zaehler',
                      semanticsLabel: '$zaehler offen',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeisteKnopf extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LeisteKnopf(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.paper,
        side: const BorderSide(color: Color(0xFF4A4A47)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(double.infinity, 44),
        alignment: Alignment.centerLeft,
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
