import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../common/app_bar_widget.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id ?? '';
    final bookmarks = ref.watch(bookmarkedCompaniesProvider(userId));

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Merkliste'),
      body: bookmarks.when(
        data: (companies) => companies.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_border, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('Keine gespeicherten Betriebe', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Merke dir interessante Betriebe, um sie später wiederzufinden.',
                        style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/search'),
                      child: const Text('Betriebe entdecken'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: companies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final c = companies[i];
                  return GestureDetector(
                    onTap: () => context.go('/company/${c.slug}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [AppColors.cardShadow],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.business, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: Theme.of(context).textTheme.labelLarge),
                                if (c.location.isNotEmpty)
                                  Text(c.location, style: Theme.of(context).textTheme.bodySmall),
                                if (c.industry != null)
                                  Text(c.industry!, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark, color: AppColors.primary),
                            tooltip: 'Aus Merkliste entfernen',
                            onPressed: () async {
                              await ref.read(companyRepositoryProvider).removeBookmark(userId, c.id);
                              ref.invalidate(bookmarkedCompaniesProvider(userId));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Fehler beim Laden.')),
      ),
    );
  }
}
