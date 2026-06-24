import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  static const _posts = [
    _BlogPost('Wie finde ich den richtigen Ausbildungsbetrieb?', 'Tipps & Tricks', '5 Min Lesezeit', 'tipps-ausbildungsbetrieb'),
    _BlogPost('DSGVO und Ausbildungsbewertungen', 'Datenschutz', '3 Min Lesezeit', 'dsgvo-bewertungen'),
    _BlogPost('Warum Azubi-Feedback Betrieben hilft', 'Für Betriebe', '4 Min Lesezeit', 'azubi-feedback-betriebe'),
    _BlogPost('Top 10 Ausbildungsberufe 2025', 'Karriere', '6 Min Lesezeit', 'top-ausbildungsberufe-2025'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Blog'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Blog', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text('Insights rund um Ausbildung, Karriere und Betriebe.',
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListView.separated(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _BlogCard(post: _posts[i]),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

class _BlogPost {
  final String title;
  final String category;
  final String readTime;
  final String slug;
  const _BlogPost(this.title, this.category, this.readTime, this.slug);
}

class _BlogCard extends StatelessWidget {
  final _BlogPost post;
  const _BlogCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(post.category,
                    style: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(post.readTime, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Weiterlesen →', style: TextStyle(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
