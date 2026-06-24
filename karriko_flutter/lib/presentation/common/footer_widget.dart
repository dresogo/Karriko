import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 720;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: width > 720 ? 32 : 20,
        vertical: 40,
      ),
      child: isWide ? _WideFooter() : _NarrowFooter(),
    );
  }
}

class _WideFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand col
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FooterBrand(),
                  const SizedBox(height: 8),
                  const Text(
                    'Ausbildung transparent machen.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Platform col
            _FooterColumn(
              title: 'Platform',
              links: [
                ('Suche', '/search'),
                ('Für Betriebe', '/fuer-betriebe'),
                ('Blog', '/blog'),
              ],
            ),
            const SizedBox(width: 40),
            // Company col
            _FooterColumn(
              title: 'Karriko',
              links: [
                ('Über uns', '/ueber-uns'),
                ('Kontakt', '/kontakt'),
              ],
            ),
            const SizedBox(width: 40),
            // Legal col
            _FooterColumn(
              title: 'Rechtliches',
              links: [
                ('Impressum', '/impressum'),
                ('Datenschutz', '/datenschutz'),
                ('AGB', '/agb'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(color: AppColors.line),
        const SizedBox(height: 16),
        Text(
          '© ${DateTime.now().year} Karriko. Alle Rechte vorbehalten.',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _NarrowFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FooterBrand(),
        const SizedBox(height: 8),
        const Text(
          'Ausbildung transparent machen.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            ('Suche', '/search'),
            ('Für Betriebe', '/fuer-betriebe'),
            ('Blog', '/blog'),
            ('Über uns', '/ueber-uns'),
          ]
              .map((l) => Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => ctx.go(l.$2),
                      child: Text(l.$1,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            ('Impressum', '/impressum'),
            ('Datenschutz', '/datenschutz'),
            ('AGB', '/agb'),
          ]
              .map((l) => Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => ctx.go(l.$2),
                      child: Text(l.$1,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        Text(
          '© ${DateTime.now().year} Karriko. Alle Rechte vorbehalten.',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          color: AppColors.ink,
          child: const Center(
            child: Text('K',
                style: TextStyle(color: AppColors.paper, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 8),
        const Text('Karriko',
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<(String, String)> links;

  const _FooterColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.96,
          ),
        ),
        const SizedBox(height: 12),
        ...links.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => context.go(l.$2),
                child: Text(l.$1,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            )),
      ],
    );
  }
}
