import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/job_model.dart';
import '../data/repositories/job_repository.dart';
import 'company_provider.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) => JobRepository());

/// Zuletzt veroeffentlichte Stellen fuer das Vorschlagsband der Suche.
final jobSuggestionsProvider = FutureProvider<List<JobModel>>((ref) {
  return ref.watch(jobRepositoryProvider).recentJobs();
});

/// Veroeffentlichte Stellen eines Unternehmens, angesprochen ueber seine
/// oeffentliche Adresse. Eine leere Liste blendet den Stellenbereich auf dem
/// Betriebsprofil aus.
final companyJobsProvider =
    FutureProvider.family<List<JobModel>, String>((ref, slug) async {
  final company = await ref.watch(companyBySlugProvider(slug).future);
  return ref.watch(jobRepositoryProvider).jobsForCompany(company.id);
});

/// Einzelne Stelle.
final jobByIdProvider = FutureProvider.family<JobModel, String>((ref, id) {
  return ref.watch(jobRepositoryProvider).getJob(id);
});

/// Stellen des eigenen Betriebs – inklusive Entwuerfe, denn der Eigentuemer
/// verwaltet sie hier.
final myJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final company = await ref.watch(myCompanyProvider.future);
  if (company == null) return const [];
  return ref
      .watch(jobRepositoryProvider)
      .jobsForCompany(company.id, onlyActive: false);
});
