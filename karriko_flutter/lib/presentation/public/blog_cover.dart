import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Farbe, Schriftfarbe und Icon einer Blog-Rubrik.
typedef BlogCategoryStyle = ({
  Color background,
  Color foreground,
  IconData icon
});

BlogCategoryStyle blogCategoryStyle(String category) => switch (category) {
      'Tipps & Tricks' => (
          background: AppColors.green,
          foreground: AppColors.paper,
          icon: Icons.lightbulb_outline,
        ),
      'Datenschutz' => (
          background: AppColors.ink,
          foreground: AppColors.paper,
          icon: Icons.shield_outlined,
        ),
      'Für Betriebe' => (
          background: AppColors.audienceBeige,
          foreground: AppColors.ink,
          icon: Icons.storefront_outlined,
        ),
      'Karriere' => (
          background: AppColors.accentDark,
          foreground: Colors.white,
          icon: Icons.trending_up,
        ),
      _ => (
          background: AppColors.audienceBeige,
          foreground: AppColors.ink,
          icon: Icons.article_outlined,
        ),
    };

/// Farbfläche je Rubrik – dieselbe Sprache wie die Zielgruppen-Kacheln auf der
/// Startseite. Die Rubrik steht als Text darauf oder daneben, Farbe und Icon
/// sind nur zusätzliche Orientierung.
class BlogCover extends StatelessWidget {
  final String category;
  final double? height;
  final double iconSize;

  /// Bei schmalen Kacheln steht die Rubrik im Text daneben statt darauf.
  final bool showLabel;

  const BlogCover({
    super.key,
    required this.category,
    required this.iconSize,
    this.height,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = blogCategoryStyle(category);

    if (!showLabel) {
      return ExcludeSemantics(
        child: Container(
          height: height,
          color: style.background,
          alignment: Alignment.center,
          child: Icon(style.icon, size: iconSize, color: style.foreground),
        ),
      );
    }

    return ExcludeSemantics(
      child: Container(
        height: height,
        color: style.background,
        padding: const EdgeInsets.all(AppLayout.s24),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: style.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(style.icon, size: iconSize, color: style.foreground),
            ),
          ],
        ),
      ),
    );
  }
}
