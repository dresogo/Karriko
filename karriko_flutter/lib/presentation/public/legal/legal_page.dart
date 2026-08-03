import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/app_bar_widget.dart';
import '../../common/footer_widget.dart';

/// Gemeinsames Gerüst für die Rechtstexte, damit Impressum, Datenschutz und AGB
/// dasselbe Standard-Layout der Website verwenden.
class LegalPage extends StatelessWidget {
  final String appBarTitle;
  final String eyebrow;
  final String title;
  final String? subtitle;

  /// Abschnitte als (Überschrift, Text).
  final List<(String, String)> sections;

  /// Optionaler Hinweiskasten unterhalb der Abschnitte.
  final Widget? notice;

  const LegalPage({
    super.key,
    required this.appBarTitle,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.sections,
    this.notice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KarrikoAppBar(title: appBarTitle),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentBand(
              padding: const EdgeInsets.only(
                top: AppLayout.s48,
                bottom: AppLayout.s64,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
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
                    Text(title,
                        style: Theme.of(context).textTheme.displaySmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppLayout.s8),
                      Text(subtitle!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: AppLayout.s48),
                    for (final s in sections) ...[
                      Text(s.$1,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppLayout.s8),
                      Text(
                        s.$2,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: AppLayout.s32),
                    ],
                    if (notice != null) notice!,
                  ],
                ),
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

/// Hinweiskasten im Stil der Website (kein Radius, Beige-Fläche).
class LegalNotice extends StatelessWidget {
  final String text;

  const LegalNotice(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.s24),
      decoration: const BoxDecoration(
        color: AppColors.audienceBeige,
        border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: AppColors.ink, size: 20),
          const SizedBox(width: AppLayout.s16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
