import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karriko_flutter/core/theme/app_theme.dart';
import 'package:karriko_flutter/data/models/user_model.dart';
import 'package:karriko_flutter/data/repositories/auth_repository.dart';
import 'package:karriko_flutter/presentation/public/kontakt_screen.dart';
import 'package:karriko_flutter/providers/auth_provider.dart';
import 'package:url_launcher/link.dart';

/// T-2.11: Die Kontaktseite verspricht nichts, was sie nicht tut.
///
/// Vorher meldete ein Formular „Nachricht gesendet!“, ohne etwas zu senden.

class _OfflineAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Kontakt führt per mailto an die echte Adresse, ohne Formular',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_OfflineAuthRepository()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const KontaktScreen()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Nachricht senden'), findsNothing);
    expect(find.text('E-Mail schreiben'), findsOneWidget);
    expect(find.text('demharter@dresogo.de'), findsOneWidget);

    final ziele = tester
        .widgetList<Link>(find.byType(Link))
        .map((l) => l.uri.toString())
        .toSet();
    expect(ziele, {'mailto:demharter@dresogo.de'});
  });
}
