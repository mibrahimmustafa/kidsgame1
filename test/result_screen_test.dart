import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedy_stars/game/models.dart';
import 'package:speedy_stars/game/save.dart';
import 'package:speedy_stars/screens/result_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('ResultScreen displays victory prize, level progression, and ALL LEVELS button',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final save = await GameSave.load();
    const result = RunResult(
      levelIndex: 0,
      finished: true,
      distanceTravelled: 1000,
      coinsCollected: 15,
      starsCollected: 10,
      heartsLeft: 3,
      elaspsed: Duration(seconds: 24),
    );

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/levels': (context) => const Scaffold(body: Text('LEVEL SELECT MAP')),
        },
        home: ResultScreen(result: result, save: save),
      ),
    );

    // Let entry controller advance
    await tester.pump(const Duration(milliseconds: 900));

    // Verifies Header & Level Clear
    expect(find.text('🏆 LEVEL 1 CLEARED!'), findsOneWidget);

    // Verifies Prize Showcase & Newly Unlocked Track
    expect(find.textContaining('PRIZE UNLOCKED: LEVEL 4'), findsOneWidget);

    // Verifies Championship Level Map display
    expect(find.text('CHAMPIONSHIP LEVELS'), findsOneWidget);
    expect(find.text('L1'), findsOneWidget);
    expect(find.text('L2'), findsOneWidget);
    expect(find.text('L3'), findsOneWidget);
    expect(find.text('L4'), findsOneWidget);

    // Verifies navigation buttons
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('ALL LEVELS'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
    expect(find.text('PLAY LEVEL 4!'), findsOneWidget);

    // Tap ALL LEVELS to verify navigation
    await tester.tap(find.text('ALL LEVELS'));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL SELECT MAP'), findsOneWidget);
  });
}
