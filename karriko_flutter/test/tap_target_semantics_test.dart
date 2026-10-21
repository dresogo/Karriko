import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/presentation/common/tap_target.dart';

/// T-11.15: Ein Knopf, der nur ein Icon zeigt, braucht einen Namen für
/// Screenreader.
void main() {
  testWidgets('semanticLabel wird vorgelesen', (tester) async {
    final semantik = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TapTarget(
          semanticLabel: 'Menü öffnen',
          onTap: () {},
          builder: (_, __) => const Icon(Icons.menu),
        ),
      ),
    ));

    expect(find.bySemanticsLabel('Menü öffnen'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Menü öffnen')),
      isSemantics(label: 'Menü öffnen', isButton: true),
    );
    semantik.dispose();
  });
}
