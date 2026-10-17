import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedy_stars/game/save.dart';
import 'package:speedy_stars/screens/garage_screen.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget boot() => MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(fontSize: 24, color: Colors.black),
          ),
        ),
        home: Builder(builder: (context) {
          return FutureBuilder<GameSave>(
            future: GameSave.load(),
            builder: (context, snap) {
              if (snap.data == null) {
                return const SizedBox();
              }
              return GarageScreen(save: snap.data!);
            },
          );
        }),
      );

  testWidgets('Garage shows three customization tabs', (tester) async {
    await tester.pumpWidget(boot());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('CARS'), findsOneWidget);
    expect(find.text('BODIES'), findsOneWidget);
    expect(find.text('MODS'), findsOneWidget);
  });

  testWidgets('Bodies tab lists every chassis and shows equip state',
      (tester) async {
    await tester.pumpWidget(boot());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('BODIES'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Muscle'), findsOneWidget);
    expect(find.text('Sprint'), findsOneWidget);
    // The other two visible cards show a FREE equip pill; the far-away
    // monster card is not built until we swipe (lazy viewport).
    expect(find.textContaining('FREE — EQUIP'), findsNWidgets(2));
    // Classic is default-equipped.
    expect(find.text('EQUIPPED ✓'), findsOneWidget);

    // Swipe the horizontal list to reveal the last chassis.
    await tester.drag(find.byType(ListView), const Offset(-420, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Monster Truck'), findsOneWidget);
    expect(find.textContaining('FREE — EQUIP'), findsWidgets);
  });

  testWidgets('Mods tab lists the bolt-on catalog and toggles gear',
      (tester) async {
    await tester.pumpWidget(boot());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('MODS'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Neon Underglow'), findsOneWidget);
    expect(find.text('Hero Stripes'), findsOneWidget);
    expect(find.text('Champion Flag'), findsOneWidget);

    // Customization is free: tap any FREE — ADD pill to unlock + equip.
    await tester.tap(find.textContaining('FREE — ADD').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // After unlocking, the mod becomes an ON/OFF toggle.
    expect(find.textContaining('ON ✓'), findsWidgets);
    await tester.tap(find.text('ON ✓').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('OFF'), findsWidgets);
  });
}
