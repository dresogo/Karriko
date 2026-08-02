import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class KarrikoAppBar extends ConsumerWidget implements PreferredSizeWidget {
  /// Höhe der Kopfzeile. Seiten, die eine Sektion auf volle Bildschirmhöhe
  /// ziehen, rechnen diesen Wert von der Viewport-Höhe ab.
  static const double height = 76;

  final String? title;
  final bool showBack;

  const KarrikoAppBar({super.key, this.title, this.showBack = true});

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 980;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.paper.withOpacity(0.94),
        border: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 18),
        child: isWide
            ? _WideHeader(auth: auth, showBack: showBack, title: title)
            : _NarrowHeader(auth: auth, showBack: showBack, title: title),
      ),
    );
  }
}

class _WideHeader extends ConsumerWidget {
  final AuthState auth;
  final bool showBack;
  final String? title;

  const _WideHeader({required this.auth, required this.showBack, this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Brand (left)
        GestureDetector(
          onTap: () => context.go('/'),
          child: const _BrandMark(),
        ),
        // Nav (center)
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavLink('Für Azubis', '/', context),
                const SizedBox(width: 34),
                _NavLink('Für Betriebe', '/fuer-betriebe', context),
                const SizedBox(width: 34),
                _NavLink('Blog', '/blog', context),
                const SizedBox(width: 34),
                _NavLink('Über uns', '/ueber-uns', context),
              ],
            ),
          ),
        ),
        // Action (right)
        if (!auth.isAuthenticated)
          _HeaderActionButton(
            label: 'Anmelden',
            onTap: () => context.go('/login'),
          )
        else
          _UserMenuButton(auth: auth),
      ],
    );
  }
}

class _NarrowHeader extends ConsumerWidget {
  final AuthState auth;
  final bool showBack;
  final String? title;

  const _NarrowHeader({required this.auth, required this.showBack, this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (showBack && context.canPop())
          GestureDetector(
            onTap: () => context.pop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_back, color: AppColors.ink, size: 20),
            ),
          ),
        // Flexible statt fester Breite: bei schmalen Viewports oder vergrößerter
        // Systemschrift schrumpft der Schriftzug, statt die Zeile zu sprengen.
        Flexible(
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: const _BrandMark(),
          ),
        ),
        const Spacer(),
        if (!auth.isAuthenticated)
          _HeaderActionButton(
            label: 'Anmelden',
            onTap: () => context.go('/login'),
          )
        else
          _UserMenuButton(auth: auth),
        const SizedBox(width: 12),
        Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: const Icon(Icons.menu, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Karriko',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
    );
  }
}

Widget _NavLink(String label, String route, BuildContext context) {
  return GestureDetector(
    onTap: () => context.go(route),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _HeaderActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Ohne Umrandung: InkWell statt GestureDetector, damit Hover, Druck und
    // Tastaturfokus weiterhin sichtbar bleiben und die Tap-Fläche erhalten ist.
    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.audienceBeige,
      focusColor: AppColors.audienceBeige,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _UserMenuButton extends ConsumerWidget {
  final AuthState auth;

  const _UserMenuButton({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              auth.user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.ink),
          ],
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'dashboard':
            context.go(auth.isBetrieb ? '/betrieb-dashboard' : '/dashboard');
          case 'profile':
            context.go(auth.isBetrieb ? '/betrieb-profile' : '/profile');
          case 'settings':
            context.go(auth.isBetrieb ? '/betrieb-settings' : '/settings');
          case 'logout':
            ref.read(authProvider.notifier).signOut();
            context.go('/');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            auth.user?.displayName ?? '',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'dashboard', child: Text('Dashboard')),
        const PopupMenuItem(value: 'profile', child: Text('Profil')),
        const PopupMenuItem(value: 'settings', child: Text('Einstellungen')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('Abmelden')),
      ],
    );
  }
}

class KarrikoDrawer extends ConsumerWidget {
  const KarrikoDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const _BrandMark(),
            ),
            const Divider(color: AppColors.line),
            _DrawerItem(label: 'Für Azubis', route: '/'),
            _DrawerItem(label: 'Für Betriebe', route: '/fuer-betriebe'),
            _DrawerItem(label: 'Blog', route: '/blog'),
            _DrawerItem(label: 'Über uns', route: '/ueber-uns'),
            _DrawerItem(label: 'Kontakt', route: '/kontakt'),
            _DrawerItem(label: 'Häufige Fragen', route: '/faq'),
            const Divider(color: AppColors.line),
            if (!auth.isAuthenticated) ...[
              _DrawerItem(label: 'Anmelden', route: '/login'),
              _DrawerItem(label: 'Als Azubi registrieren', route: '/register/azubi'),
              _DrawerItem(label: 'Als Betrieb registrieren', route: '/register/betrieb'),
            ] else if (auth.isAzubi) ...[
              _DrawerItem(label: 'Dashboard', route: '/dashboard'),
              _DrawerItem(label: 'Mein Profil', route: '/profile'),
              _DrawerItem(label: 'Bewertung schreiben', route: '/reviews/new'),
              _DrawerItem(label: 'Fragen bewerten', route: '/fragen-bewerten'),
              _DrawerItem(label: 'Meine Bewertungen', route: '/my-reviews'),
              _DrawerItem(label: 'Merkliste', route: '/bookmarks'),
              _DrawerItem(label: 'Benachrichtigungen', route: '/notifications'),
              _DrawerItem(label: 'Einstellungen', route: '/settings'),
              const Divider(color: AppColors.line),
              ListTile(
                title: const Text('Abmelden', style: TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  context.pop();
                  ref.read(authProvider.notifier).signOut();
                },
              ),
            ] else if (auth.isBetrieb) ...[
              _DrawerItem(label: 'Dashboard', route: '/betrieb-dashboard'),
              _DrawerItem(label: 'Unternehmensprofil', route: '/betrieb-profile'),
              _DrawerItem(label: 'Bewertungen', route: '/betrieb-reviews'),
              _DrawerItem(label: 'Analytics', route: '/analytics'),
              _DrawerItem(label: 'Einstellungen', route: '/betrieb-settings'),
              const Divider(color: AppColors.line),
              ListTile(
                title: const Text('Abmelden', style: TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  context.pop();
                  ref.read(authProvider.notifier).signOut();
                },
              ),
            ],
            const Divider(color: AppColors.line),
            _DrawerItem(label: 'Impressum', route: '/impressum'),
            _DrawerItem(label: 'Datenschutz', route: '/datenschutz'),
            _DrawerItem(label: 'AGB', route: '/agb'),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final String route;

  const _DrawerItem({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          )),
      onTap: () {
        context.pop();
        context.go(route);
      },
    );
  }
}
