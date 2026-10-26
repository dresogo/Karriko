import 'package:flutter/widgets.dart';
import 'package:url_launcher/link.dart';
import 'tap_target.dart';

/// Ein Verweis auf eine Seite der App als echter Link (T-11.22).
///
/// Im Browser liegt darunter ein `<a href>`: Mittelklick, Strg-Klick und
/// „In neuem Tab öffnen“ funktionieren, und Screenreader nennen ihn „Link“
/// statt „Schaltfläche“. Ein normaler Klick navigiert wie `context.go` im
/// selben Tab. Aussehen, Hand-Cursor, Hover und Tastatur kommen wie bisher
/// von [TapTarget] (E-10).
class RouteLink extends StatelessWidget {
  final String route;
  final Widget Function(BuildContext context, bool active) builder;
  final HitTestBehavior? behavior;
  final String? semanticLabel;

  const RouteLink({
    super.key,
    required this.route,
    required this.builder,
    this.behavior,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: Uri.parse(route),
      builder: (context, followLink) => TapTarget(
        onTap: followLink,
        isLink: true,
        behavior: behavior,
        semanticLabel: semanticLabel,
        builder: builder,
      ),
    );
  }
}
