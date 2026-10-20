import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/account_repository.dart';

/// Konto loeschen, eigene Bewertung loeschen, Daten herunterladen
/// (T-2.8 bis T-2.10), alles ueber die Function `my_account`.
final accountRepositoryProvider =
    Provider<AccountRepository>((ref) => AccountRepository());
