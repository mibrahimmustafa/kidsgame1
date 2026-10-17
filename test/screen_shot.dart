// Renders the home or garage screen headlessly for visual eyeballing —
// same one-toImage-per-process rule as cockpit_shot.dart / icon_shot.dart.
//   flutter test test/screen_shot.dart --dart-define=SCREEN_SHOT=home
//   flutter test test/screen_shot.dart --dart-define=SCREEN_SHOT=garage
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedy_stars/game/save.dart';
import 'package:speedy_stars/screens/garage_screen.dart';
import 'package:speedy_stars/screens/home_screen.dart';
import 'package:speedy_stars/screens/level_select_screen.dart';

import 'dart:math' as math;

void main() {
  final mode = const String.fromEnvironment('SCREEN_SHOT').toLowerCase();

  testWidgets('screen shot', skip: mode != 'home' && mode != 'garage' && mode != 'bg' && mode != 'levels',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final save = await GameSave.load();

    final Widget scene;
    if (mode == 'garage') {
      scene = GarageScreen(save: save);
    } else if (mode == 'bg') {
      scene = Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF090E1F), Color(0xFF101632), Color(0xFF170F33)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    size: const Size(900, 430),
                    painter: _BackdropProbePainter(),
                  ),
                ),
                const Center(child: Text('PROBE')),
              ],
            ),
          ),
        ),
      );
    } else if (mode == 'levels') {
      scene = LevelSelectScreen(save: save);
    } else {
      scene = HomeScreen(save: save);
    }

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(900, 430)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(child: scene),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));

    // Capture the ROOT boundary (outermost) — inner ones exist around
    // scrollables and would snapshot only the content subtree.
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    Directory('build/screens').createSync(recursive: true);
    File('build/screens/$mode.png').writeAsBytesSync(bytes.buffer.asUint8List());
    debugPrint('SCREEN SAVED: build/screens/$mode.png');
  });
}

/// Copy of the home backdrop's drawing calls to isolate the white bug.
class _BackdropProbePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    for (var i = 0; i < 60; i++) {
      final rand = math.Random(50 + i);
      final x = rand.nextDouble() * w;
      final y = rand.nextDouble() * h * .7;
      canvas.drawCircle(
          Offset(x, y),
          .9 + (i % 3) * .6,
          Paint()..color = Colors.white.withValues(alpha: .14 + (i % 5) * .04));
    }
    _orb(canvas, Offset(w * .85, h * .16), w * .30, const Color(0x26FF7BD5));
    _orb(canvas, Offset(w * .12, h * .24), w * .28, const Color(0x224FC3F7));
    _orb(canvas, Offset(w * .55, h * .88), w * .40, const Color(0x15FFC531));
  }

  void _orb(Canvas c, Offset at, double r, Color color) {
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
  }

  @override
  bool shouldRepaint(covariant _BackdropProbePainter oldDelegate) => false;
}
