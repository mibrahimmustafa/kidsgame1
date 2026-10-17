import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/models.dart';

/// Bright, friendly, kid-tested visual language for the whole app.
class AppTheme {
  AppTheme._();

  static const Color sky = Color(0xFF6BB8F7);
  static const Color skyLight = Color(0xFFB9E4FF);
  static const Color grass = Color(0xFF4ED07E);
  static const Color grassDark = Color(0xFF34B362);
  static const Color road = Color(0xFF3B4252);
  static const Color sun = Color(0xFFFFD75E);
  static const Color blood = Color(0xFFFF5D7E);
  static const Color nitro = Color(0xFF4DD0E1);
  static const Color boost = Color(0xFFFFA726);
  static const Color coinGold = Color(0xFFFFC93C);
  static const Color inkDark = Color(0xFF3A2E2B);
  static const Color niceGreen = Color(0xFF53B175);
  static const Color niceOrange = Color(0xFFF98F3E);
  static const Color niceBlue = Color(0xFF5A9CF8);
  static const Color nicePink = Color(0xFFF76A8B);

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8FD6FD), Color(0xFFCDECFF)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFA06B), Color(0xFF6BB8F7)],
  );

  static const LinearGradient boostGradient = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
  );

  static const LinearGradient nitroGradient = LinearGradient(
    colors: [Color(0xFF26C6DA), Color(0xFF26A69A)],
  );

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF262C4F), Color(0xFF4C4B79)],
  );

  static const LinearGradient beachGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF67CBDA), Color(0xFFFBE08A)],
  );

  static LinearGradient gradientFor(ThemeKind kind) => switch (kind) {
        ThemeKind.meadow => skyGradient,
        ThemeKind.beach => beachGradient,
        ThemeKind.snow || ThemeKind.desert => sunsetGradient,
        ThemeKind.nightCity || ThemeKind.galaxy => nightGradient,
        ThemeKind.forestRain || ThemeKind.volcano => sunsetGradient,
      };

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
        seedColor: niceOrange, brightness: Brightness.light);
    return ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: base.copyWith(primary: niceOrange, secondary: niceBlue),
      scaffoldBackgroundColor: skyLight,
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(22))),
      ),
      sliderTheme: const SliderThemeData(),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Procedurally drawn cartoon race car preview (garage/home) —
/// side profile, no bitmaps, crisp on every DPI.
class CarPreviewPainter extends CustomPainter {
  const CarPreviewPainter(this.car, {this.bounce = 0});
  final CarSpec car;
  final double bounce;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.62 - bounce * 12;
    final w = size.width * 0.66;
    final bodyH = w * 0.30;

    final bodyTop = Rect.fromLTWH(cx - w / 2, cy - bodyH, w, bodyH);
    final bodyRect =
        RRect.fromRectAndRadius(bodyTop, Radius.circular(bodyH * 0.42));
    final grad = LinearGradient(
      colors: [car.bodyColor.withValues(alpha: .95), darken(car.bodyColor, .25)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    // cabin
    final cabinTop = Rect.fromCenter(
        center: Offset(cx - w * 0.02, cy - bodyH - bodyH * 0.42),
        width: w * 0.42,
        height: bodyH * 0.95);
    final cabin = RRect.fromRectAndRadius(
        cabinTop, Radius.circular(bodyH * 0.32));

    // spoiler
    final spoiler = Rect.fromLTWH(
        cx - w / 2 - w * 0.06, cy - bodyH - bodyH * 0.5, w * 0.10, bodyH * 0.55);

    final bodyPaint = Paint()..shader = grad.createShader(bodyTop);
    final glassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEFF9FF), Color(0xFF9ED2EA)],
      ).createShader(cabinTop);
    final inkPaint = Paint()..color = AppTheme.inkDark;

    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(cabin, glassPaint);
    canvas.drawRRect(cabin,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = inkPaint.color.withValues(alpha: .5));
    canvas.drawRect(spoiler, inkPaint);
    // decal
    canvas.drawCircle(
        Offset(cx + w * 0.30, cy - bodyH * 0.55), bodyH * 0.28,
        Paint()..color = car.accentColor..style = PaintingStyle.fill);
    // wheels
    final wheelR = bodyH * 0.42;
    for (final offset in [-w * 0.32, w * 0.30]) {
      canvas.drawCircle(
          Offset(cx + offset, cy + wheelR * 0.4), wheelR + 2,
          Paint()..color = AppTheme.inkDark);
      canvas.drawCircle(
          Offset(cx + offset, cy + wheelR * 0.4), wheelR * 0.55,
          Paint()..color = const Color(0xFFEDEDED));
    }
  }

  @override
  bool shouldRepaint(covariant CarPreviewPainter old) =>
      old.bounce != bounce || old.car != car;
}

Color darken(Color color, [double amount = .2]) {
  final hsl = HSLColor.fromColor(color);
  final darker =
      hsl.withLightness((hsl.lightness * (1 - amount)).clamp(0, 1));
  return darker.toColor();
}

/// Gentle looping bounce used to make previews feel alive.
class Bouncy extends StatefulWidget {
  const Bouncy({super.key, required this.child});
  final Widget child;

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final bounce = (math.sin(t * math.pi * 2) + 1) / 2;
        return Transform.translate(
          offset: Offset(0, -bounce * 5),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
