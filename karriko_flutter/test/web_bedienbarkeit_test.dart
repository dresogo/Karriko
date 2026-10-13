import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karriko_flutter/app/app.dart';
import 'package:karriko_flutter/presentation/common/footer_widget.dart';
import 'package:karriko_flutter/presentation/common/tap_target.dart';

/// Prueft, dass die App im Browser wie eine Website bedienbar ist: Text laesst
/// sich markieren und kopieren, Klickziele zeigen den Hand-Cursor und sind per
/// Tastatur erreichbar.

const _lesetext = 'Die Ausbildung beginnt im August.';

Widget _app(Widget body) => MaterialApp(
      builder: selectableAppBuilder,
      home: Scaffold(body: body),
    );

/// Faehrt mit der Maus ueber [finder] und liefert den Cursor, den der
/// Browser an dieser Stelle zeigen wuerde.
Future<MouseCursor?> _cursorUeber(WidgetTester tester, Finder finder) async {
  final maus = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await maus.addPointer(location: Offset.zero);
  addTearDown(maus.removePointer);
  await maus.moveTo(tester.getCenter(finder));
  await tester.pump();
  return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
}

/// Faengt ab, was in die Zwischenablage geschrieben wird.
String? Function() _zwischenablage(WidgetTester tester) {
  String? inhalt;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        inhalt = (call.arguments as Map)['text'] as String?;
      }
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return () => inhalt;
}

Future<void> _markieren(WidgetTester tester, Finder von, Finder bis) async {
  final maus = await tester.startGesture(
    tester.getTopLeft(von) + const Offset(1, 4),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
  await maus.moveTo(tester.getBottomRight(bis) - const Offset(1, 4));
  await tester.pump();
  await maus.up();
  await tester.pump();
}

Future<void> _kopieren(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pump();
}

void main() {
  group('Textauswahl', () {
    testWidgets('Lesetext laesst sich markieren und kopieren', (tester) async {
      final kopiert = _zwischenablage(tester);
      await tester.pumpWidget(_app(const Center(child: Text(_lesetext))));

      await _markieren(tester, find.text(_lesetext), find.text(_lesetext));
      await _kopieren(tester);

      expect(kopiert(), _lesetext);
    });

    testWidgets('Beschriftung eines Klickziels wird nicht mitmarkiert',
        (tester) async {
      final kopiert = _zwischenablage(tester);
      await tester.pumpWidget(_app(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(_lesetext),
          TapTarget(onTap: () {}, builder: (_, __) => const Text('Weiter')),
        ],
      )));

      await _markieren(tester, find.text(_lesetext), find.text('Weiter'));
      await _kopieren(tester);

      expect(kopiert(), _lesetext);
    });
  });

  group('Klickziele', () {
    testWidgets('TapTarget hat einen MouseRegion mit Hand-Cursor',
        (tester) async {
      await tester.pumpWidget(_app(Center(
        child: TapTarget(onTap: () {}, builder: (_, __) => const Text('Los')),
      )));

      final regionen = tester.widgetList<MouseRegion>(find.descendant(
        of: find.byType(TapTarget),
        matching: find.byType(MouseRegion),
      ));
      expect(regionen.map((r) => r.cursor), contains(SystemMouseCursors.click));
      expect(await _cursorUeber(tester, find.text('Los')),
          SystemMouseCursors.click);
    });

    testWidgets('Deaktiviertes TapTarget zeigt keinen Hand-Cursor',
        (tester) async {
      await tester.pumpWidget(_app(Center(
        child: TapTarget(onTap: null, builder: (_, __) => const Text('Los')),
      )));

      expect(await _cursorUeber(tester, find.text('Los')),
          isNot(SystemMouseCursors.click));
    });

    testWidgets('Hover meldet den aktiven Zustand an den Inhalt',
        (tester) async {
      await tester.pumpWidget(_app(Center(
        child: TapTarget(
          onTap: () {},
          builder: (_, active) => Text(active ? 'aktiv' : 'ruhig'),
        ),
      )));

      expect(find.text('ruhig'), findsOneWidget);
      await _cursorUeber(tester, find.text('ruhig'));
      expect(find.text('aktiv'), findsOneWidget);
    });

    testWidgets('Per Tab erreichbar und mit Enter ausloesbar', (tester) async {
      var ausgeloest = 0;
      await tester.pumpWidget(_app(Center(
        child: TapTarget(
          onTap: () => ausgeloest++,
          builder: (_, __) => const Text('Los'),
        ),
      )));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(ausgeloest, 1);
    });

    testWidgets('Footer-Links zeigen den Hand-Cursor', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(
        const SingleChildScrollView(child: FooterWidget()),
      ));

      expect(await _cursorUeber(tester, find.text('Impressum')),
          SystemMouseCursors.click);
    });
  });
}
