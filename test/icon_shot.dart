// Renders the launcher icon artwork to PNG files (one image per process —
// flutter_tester tolerates exactly one toImage). Opt-in via dart-define:
//   flutter test test/icon_shot.dart --dart-define=ICON_SHOT=true --plain-name main
//   flutter test test/icon_shot.dart --dart-define=ICON_SHOT=true --dart-define=ICON_MASKABLE=true --plain-name main
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedy_stars/core/app_icon.dart';

const bool _manual = bool.fromEnvironment('ICON_SHOT');
const bool _maskable = bool.fromEnvironment('ICON_MASKABLE');

void main() {
  testWidgets('icon shot', skip: !_manual, (tester) async {
    await tester.pumpWidget(
        const MediaQuery(data: MediaQueryData(),
            child: RepaintBoundary(child: AppIcon(maskable: _maskable))));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).last);
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    Directory('build/icon').createSync(recursive: true);
    final name = _maskable ? 'icon_maskable_512' : 'app_icon';
    File('build/icon/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
    debugPrint('ICON SAVED: build/icon/$name.png');
  });
}
