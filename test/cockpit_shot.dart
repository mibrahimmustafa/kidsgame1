// Renders the cockpit view headlessly and saves snapshots to build/cockpit/
// â€” used to eyeball the scene without launching a browser. Opt-in only
// (flutter_tester tolerates one toImage per process), so it skips itself
// during normal `flutter test` runs:
//   flutter test test/cockpit_shot.dart --dart-define=COCKPIT_SHOT=true --plain-name day
//   flutter test test/cockpit_shot.dart --dart-define=COCKPIT_SHOT=true --plain-name night
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedy_stars/game/cockpit.dart';
import 'package:speedy_stars/game/models.dart';
import 'package:speedy_stars/game/theme.dart';
import 'package:speedy_stars/game/world.dart';

const bool _manual = bool.fromEnvironment('COCKPIT_SHOT');
const bool skipWhenAuto = !_manual;

Future<void> _snap(WidgetTester tester, String name, Widget scene) async {
  await tester.pumpWidget(
      MediaQuery(data: const MediaQueryData(size: Size(1000, 460)),
          child: RepaintBoundary(child: scene)));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).last);
  final image = await boundary.toImage(pixelRatio: 1.0);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  image.dispose();
  Directory('build/cockpit').createSync(recursive: true);
  File('build/cockpit/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  debugPrint('SHOT SAVED: build/cockpit/$name.png');
}

GameWorld _drivenWorld() {
  final w = GameWorld(level: LevelSpec.freeDrive, car: CarSpec.byId('speedy'));
  const step = 1 / 60;
  for (var i = 0; i < 420; i++) {
    w.update(step);
  }
  return w;
}

void main() {
  testWidgets('day shot', skip: skipWhenAuto, (tester) async {
    final day = _drivenWorld()..setSteer(0.35);
    await _snap(
        tester,
        'day_meadow',
        CustomPaint(
            size: const Size(1000, 460),
            painter: CockpitPainter(day, TrackTheme.meadow, 4.0,
                mods: const {'stripes', 'neon'})));
  });

  testWidgets('night shot', skip: skipWhenAuto, (tester) async {
    final night = _drivenWorld()..setSteer(-0.5);
    await _snap(
        tester,
        'night_city',
        CustomPaint(
            size: const Size(1000, 460),
            painter: CockpitPainter(night, TrackTheme.city, 9.0)));
  });
}
