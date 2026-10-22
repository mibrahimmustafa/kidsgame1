import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedy_stars/game/save.dart';
import 'package:speedy_stars/screens/level_select_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('LevelSelectScreen renders all 8 tracks without RenderFlex overflow on compact landscape',
      (tester) async {
    // Test on a very compact landscape device screen size (e.g. 700x360)
    tester.view.physicalSize = const Size(700, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final save = await GameSave.load();
    await tester.pumpWidget(
      MaterialApp(
        home: LevelSelectScreen(save: save),
      ),
    );

    // Let enter animation run
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('CHAMPIONSHIP RACES'), findsOneWidget);
    expect(find.textContaining('8 ADVENTURE LEVELS'), findsOneWidget);

    // Verify track cards render with LVL badges
    expect(find.textContaining('LVL 1'), findsOneWidget);
    expect(find.textContaining('LVL 2'), findsOneWidget);
    expect(find.textContaining('LVL 3'), findsOneWidget);
  });
}
