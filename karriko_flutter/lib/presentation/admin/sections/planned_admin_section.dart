import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../planned/planned_page.dart';
import '../widgets/admin_widgets.dart';

export '../../planned/planned_page.dart' show PlannedSection;

/// Grobgerüst eines Admin-Bereichs, der laut Sitemap gebraucht wird, aber
/// noch keine Function dahinter hat.
class PlannedAdminSection extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String lede;
  final List<String> refs;
  final List<PlannedSection> sections;

  const PlannedAdminSection({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.lede,
    required this.refs,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(eyebrow: eyebrow, title: title, lede: lede),
        const SizedBox(height: AppLayout.s16),
        Wrap(
          spacing: AppLayout.s8,
          runSpacing: AppLayout.s8,
          children: [
            for (final r in refs)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration:
                    BoxDecoration(border: Border.all(color: AppColors.line)),
                child: Text(
                  r,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppLayout.s32),
        PlannedSectionList(sections: sections),
      ],
    );
  }
}
