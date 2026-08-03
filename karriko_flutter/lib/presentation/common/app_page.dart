import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_bar_widget.dart';

/// Gerüst der angemeldeten Bereiche.
///
/// Kopfband auf weißer Fläche mit Eyebrow, Titel und optionaler Aktion, darunter
/// der Inhalt im Raster der Website. Hält Dashboard, Profil und Einstellungen
/// auf derselben vertikalen Rhythmik.
class AppPage extends StatelessWidget {
  final String appBarTitle;
  final String eyebrow;
  final String title;
  final String? lede;

  /// Aktion rechts im Kopfband, breit daneben, schmal darunter.
  final Widget? headerAction;

  final List<Widget> children;

  const AppPage({
    super.key,
    required this.appBarTitle,
    required this.eyebrow,
    required this.title,
    this.lede,
    this.headerAction,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 720;

    return Scaffold(
      appBar: KarrikoAppBar(title: appBarTitle),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: ContentBand(
                padding: EdgeInsets.symmetric(
                  vertical: isWide ? AppLayout.s48 : AppLayout.s32,
                ),
                child: _Header(
                  eyebrow: eyebrow,
                  title: title,
                  lede: lede,
                  action: headerAction,
                  isWide: isWide,
                ),
              ),
            ),
            ContentBand(
              padding: const EdgeInsets.only(
                top: AppLayout.s48,
                bottom: AppLayout.s64,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? lede;
  final Widget? action;
  final bool isWide;

  const _Header({
    required this.eyebrow,
    required this.title,
    required this.lede,
    required this.action,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: AppLayout.s16),
        Text(
          title,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: isWide ? 40 : 30,
            fontWeight: FontWeight.w800,
            height: 1.02,
            letterSpacing: -0.5,
          ),
        ),
        if (lede != null) ...[
          const SizedBox(height: AppLayout.s16),
          Text(lede!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );

    if (action == null) return text;

    // Breit nebeneinander, schmal untereinander – so bleibt die Aktion auch bei
    // langen Titeln und grosser Systemschrift vollstaendig sichtbar.
    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: text),
              const SizedBox(width: AppLayout.s24),
              action!,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              const SizedBox(height: AppLayout.s24),
              action!,
            ],
          );
  }
}

/// Versalien-Label über einem Abschnitt.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.96,
      ),
    );
  }
}

/// Weisse Fläche mit Haarlinie – kein Radius, kein Schatten.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppLayout.s24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

/// Liste mit Haarlinien als Trenner, umschlossen von einem Rahmen.
class AppRowGroup extends StatelessWidget {
  final List<Widget> children;

  const AppRowGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(color: AppColors.line, height: 1),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Zeile mit Icon, Titel und optionalem Zusatz. Bei [onTap] mit sichtbarem
/// Hover-, Druck- und Fokuszustand; der Fokus wird als Tintenkante gezeichnet.
class AppRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// Rechts stehender Zusatz, z. B. die eigene E-Mail-Adresse.
  final String? value;

  final VoidCallback? onTap;

  /// Hebt Beschriftung und Icon in der Akzentfarbe hervor (löschende Aktionen).
  final bool destructive;

  const AppRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.destructive = false,
  });

  @override
  State<AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<AppRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.destructive ? AppColors.accentDark : AppColors.ink;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.s24,
        vertical: AppLayout.s16,
      ),
      child: Row(
        children: [
          Icon(widget.icon,
              size: 20, color: widget.destructive ? color : AppColors.muted),
          const SizedBox(width: AppLayout.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(widget.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (widget.value != null) ...[
            const SizedBox(width: AppLayout.s16),
            Flexible(
              child: Text(
                widget.value!,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          if (widget.onTap != null) ...[
            const SizedBox(width: AppLayout.s8),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
          ],
        ],
      ),
    );

    if (widget.onTap == null) return content;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (v) => setState(() => _focused = v),
        hoverColor: AppColors.paper,
        focusColor: AppColors.audienceBeige,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 56),
          foregroundDecoration: BoxDecoration(
            border: Border.all(
              color: _focused ? AppColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Zeile mit Schalter. Der Zustand wird zusätzlich als Text benannt, damit er
/// nicht allein über Farbe und Position erkennbar ist.
class AppSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.s24,
            vertical: AppLayout.s16,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.muted),
              const SizedBox(width: AppLayout.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle == null
                          ? (value ? 'An' : 'Aus')
                          : '${subtitle!} · ${value ? 'An' : 'Aus'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppLayout.s16),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.paper,
                activeTrackColor: AppColors.ink,
                inactiveThumbColor: AppColors.surface,
                inactiveTrackColor: AppColors.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kennzahl mit Bezeichnung. Zahlen in Tabellenziffern, damit sie beim
/// Aktualisieren nicht springen.
class StatTile extends StatelessWidget {
  final String value;
  final String label;

  const StatTile({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppLayout.s8),
          SectionLabel(label),
        ],
      ),
    );
  }
}

/// Hinweis, wenn ein Abschnitt leer ist – mit Weg nach vorn statt leerer Fläche.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppLayout.s8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppLayout.s24),
          Align(
            alignment: Alignment.centerLeft,
            child:
                OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}
