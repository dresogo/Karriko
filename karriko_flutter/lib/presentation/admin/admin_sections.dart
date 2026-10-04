import 'package:flutter/material.dart';

/// Die Bereiche des Admin-Dashboards.
///
/// Jeder hat einen eigenen Adressteil (`/admin?bereich=meldungen`), damit sich
/// ein Bereich verlinken lässt und der Zurück-Knopf des Browsers funktioniert.
enum AdminSection {
  overview('uebersicht', 'Übersicht', Icons.space_dashboard_outlined),
  moderation('moderation', 'Moderation', Icons.inbox_outlined),
  reports('meldungen', 'Meldungen', Icons.outlined_flag_rounded),
  log('protokoll', 'Protokoll', Icons.history_rounded),
  companies('betriebe', 'Betriebe', Icons.domain_outlined),
  system('system', 'System', Icons.tune_rounded, adminOnly: true);

  final String slug;
  final String label;
  final IconData icon;

  /// Nur für das Team `admins` sichtbar.
  final bool adminOnly;

  const AdminSection(this.slug, this.label, this.icon,
      {this.adminOnly = false});

  static AdminSection fromSlug(String? slug) => AdminSection.values.firstWhere(
        (s) => s.slug == slug,
        orElse: () => AdminSection.overview,
      );
}
