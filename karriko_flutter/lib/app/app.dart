import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class KarrikoApp extends ConsumerWidget {
  const KarrikoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Karriko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Ohne die Delegates stehen die eingebauten Material-Dialoge auf
      // Englisch – der Datumswaehler der Stellenanlage sagte „Cancel“.
      locale: const Locale('de'),
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: selectableAppBuilder,
    );
  }
}

/// Eine SelectionArea fuer alle Seiten: Im Browser laesst sich Text markieren
/// und kopieren wie auf einer Website. Sie liegt ueber dem Navigator und damit
/// ueber jedem Scaffold, Dialog und Drawer. Bedienflaechen nehmen sich mit
/// SelectionContainer.disabled aus.
///
/// Overlay.wrap, weil Markierungsgriffe und Kontextmenue ein Overlay oberhalb
/// der SelectionArea brauchen; das des Navigators liegt darunter.
///
/// Ohne Lupe: Auf Touchgeraeten erschien beim Markieren eine vergroessernde
/// Linse, die wie eine Zoom-Animation wirkte.
Widget selectableAppBuilder(BuildContext context, Widget? child) =>
    Overlay.wrap(
      child: SelectionArea(
        magnifierConfiguration: TextMagnifierConfiguration.disabled,
        child: child!,
      ),
    );
