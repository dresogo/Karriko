import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../../providers/auth_provider.dart';

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository());

/// Die Teams des angemeldeten Kontos. Hängt an der Nutzerkennung, damit ein
/// Kontowechsel nicht die Rollen des vorigen Kontos stehen lässt.
final adminRolesProvider = FutureProvider.autoDispose<AdminRoles>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  return ref.read(adminRepositoryProvider).loadRoles();
});

final adminOverviewProvider = FutureProvider.autoDispose<AdminOverview>(
    (ref) => ref.read(adminRepositoryProvider).overview());

/// Warteschlange je Status.
final adminQueueProvider = FutureProvider.autoDispose
    .family<List<QueueItem>, String>(
        (ref, status) => ref.read(adminRepositoryProvider).queue(status));

/// Meldungen; `true` heißt nur offene.
final adminReportsProvider = FutureProvider.autoDispose
    .family<List<ReportItem>, bool>((ref, onlyOpen) =>
        ref.read(adminRepositoryProvider).reports(onlyOpen: onlyOpen));

final adminLogProvider = FutureProvider.autoDispose<List<ModerationLogItem>>(
    (ref) => ref.read(adminRepositoryProvider).log());

final adminCompaniesProvider = FutureProvider.autoDispose
    .family<List<CompanyItem>, String>((ref, search) =>
        ref.read(adminRepositoryProvider).companies(search: search));

/// Nach einer Entscheidung ist alles veraltet, was Zahlen oder Listen zeigt.
void invalidateAdminData(WidgetRef ref) {
  ref.invalidate(adminOverviewProvider);
  ref.invalidate(adminQueueProvider);
  ref.invalidate(adminReportsProvider);
  ref.invalidate(adminLogProvider);
}
