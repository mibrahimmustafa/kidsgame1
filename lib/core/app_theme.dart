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
  const CarPreviewPainter(
    this.car, {
    this.bounce = 0,
    this.bodyStyle = BodyStyle.classic,
    this.mods = const <String>[],
  });
  final CarSpec car;
  final double bounce;
  final BodyStyle bodyStyle;
  final List<String> mods;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.66 - bounce * 12;
    final w = size.width * 0.68 * (bodyStyle == BodyStyle.monster ? 0.92 : 1.0);
    final bodyH = w * (bodyStyle == BodyStyle.sport ? 0.21 : 0.24);
    final lift =
        bodyStyle == BodyStyle.monster ? bodyH * 0.5 : bodyH * 0.0;
    final x0 = cx - w / 2;
    final y0 = cy - bodyH - lift;

    final body = car.bodyColor;
    final bodyRect = Rect.fromLTWH(x0, y0, w, bodyH);

    final grad = LinearGradient(
      colors: [
        lightenBody(body, .22),
        body,
        darken(body, .28),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final ink = AppTheme.inkDark;

    // ---- soft parking shadow under the car ----
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + bodyH * 0.60),
            width: w * 1.05,
            height: bodyH * 0.42),
        Paint()..color = const Color(0x2E000000));

    // ---- neon underglow (mod) ----
    if (mods.contains('neon')) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, cy + bodyH * 0.5),
              width: w * 1.25,
              height: bodyH * 0.55),
          Paint()..color = const Color(0xFF7C4DFF).withValues(alpha: 0.38));
    }

    // ---- body silhouette varies per style ----
    final bodyPath = Path();
    if (bodyStyle == BodyStyle.monster) {
      bodyPath
        ..moveTo(x0 + w * 0.04, y0 + bodyH * 0.30)
        ..lineTo(x0 + w * 0.08, y0)
        ..lineTo(x0 + w * 0.72, y0)
        ..quadraticBezierTo(
            x0 + w * 0.88, y0 + bodyH * 0.02, x0 + w * 0.94, y0 + bodyH * 0.5)
        ..lineTo(x0 + w * 0.96, y0 + bodyH * 0.8)
        ..lineTo(x0 + w * 0.06, y0 + bodyH * 0.8)
        ..close();
    } else if (bodyStyle == BodyStyle.classic) {
      // Modern EV fastback — sleek Tesla-like silhouette: long flowing
      // roofline, low nose with an LED light bar, integrated tail lip.
      bodyPath
        ..moveTo(x0 + w * 0.03, y0 + bodyH * 1.02)
        ..lineTo(x0 + w * 0.02, y0 + bodyH * 0.34)
        ..quadraticBezierTo(
            x0 + w * 0.02, y0 + bodyH * 0.24, x0 + w * 0.06, y0 + bodyH * 0.22)
        ..quadraticBezierTo(
            x0 + w * 0.16, y0 + bodyH * 0.02, x0 + w * 0.34, y0 - bodyH * 0.30)
        ..quadraticBezierTo(
            x0 + w * 0.46, y0 - bodyH * 0.62, x0 + w * 0.60, y0 - bodyH * 0.60)
        ..quadraticBezierTo(
            x0 + w * 0.76, y0 - bodyH * 0.52, x0 + w * 0.88, y0 - bodyH * 0.16)
        ..quadraticBezierTo(
            x0 + w * 0.98, y0 - bodyH * 0.02, x0 + w * 0.995, y0 + bodyH * 0.32)
        ..quadraticBezierTo(
            x0 + w * 1.0, y0 + bodyH * 0.55, x0 + w * 0.99, y0 + bodyH * 0.72)
        ..quadraticBezierTo(
            x0 + w * 0.98, y0 + bodyH, x0 + w * 0.93, y0 + bodyH * 1.02)
        ..close();
    } else {
      bodyPath
        ..moveTo(x0 + w * 0.02, y0 + bodyH * 0.42)
        ..quadraticBezierTo(
            x0, y0 + bodyH * 0.30, x0 + w * 0.03, y0 + bodyH * 0.18)
        ..lineTo(x0 + w * 0.06, y0)
        ..lineTo(x0 + w * 0.34, y0 + bodyH * 0.04);
      if (bodyStyle == BodyStyle.sport) {
        bodyPath
          ..quadraticBezierTo(
              x0 + w * 0.48, y0 - bodyH * 0.75, x0 + w * 0.70, y0 - bodyH * 0.62)
          ..quadraticBezierTo(
              x0 + w * 0.86, y0 - bodyH * 0.45, x0 + w * 0.90, y0 - bodyH * 0.12)
          ..quadraticBezierTo(
              x0 + w * 0.97, y0 + bodyH * 0.08, x0 + w, y0 + bodyH * 0.55);
      } else {
        bodyPath
          ..quadraticBezierTo(
              x0 + w * 0.46, y0 - bodyH * 0.95, x0 + w * 0.66, y0 - bodyH * 0.8)
          ..quadraticBezierTo(
              x0 + w * 0.80, y0 - bodyH * 0.68, x0 + w * 0.86, y0 - bodyH * 0.18)
          ..quadraticBezierTo(
              x0 + w * 0.97, y0 + bodyH * 0.05, x0 + w, y0 + bodyH * 0.5);
      }
      bodyPath
        ..quadraticBezierTo(
            x0 + w * 0.99, y0 + bodyH, x0 + w * 0.92, y0 + bodyH * 1.02)
        ..lineTo(x0 + w * 0.08, y0 + bodyH * 1.02)
        ..quadraticBezierTo(x0, y0 + bodyH, x0 + w * 0.02, y0 + bodyH * 0.42)
        ..close();
    }
    canvas.drawPath(bodyPath,
        Paint()..shader = grad.createShader(bodyRect));
    // gloss streak across the shoulders
    canvas.drawPath(
        bodyPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [const Color(0x49FFFFFF), const Color(0x00FFFFFF)],
          ).createShader(bodyRect));
    canvas.drawPath(bodyPath,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = ink.withValues(alpha: .35));

    // ---- side glass (not on the monster flat deck) ----
    if (bodyStyle != BodyStyle.monster) {
      final glassRect = Rect.fromLTWH(
          x0 + w * 0.40, y0 - bodyH * 0.62, w * 0.40, bodyH * 0.66);
      final glassPath = Path()
        ..moveTo(glassRect.left, glassRect.bottom)
        ..quadraticBezierTo(glassRect.left - w * 0.015, glassRect.top,
            glassRect.left + w * 0.05, glassRect.top)
        ..lineTo(glassRect.right - w * 0.04, glassRect.top)
        ..quadraticBezierTo(glassRect.right, glassRect.top + bodyH * 0.08,
            glassRect.right, glassRect.bottom)
        ..close();
      canvas.drawPath(
          glassPath,
          Paint()
            ..shader = (bodyStyle == BodyStyle.classic
                ? const LinearGradient(
                    // panoramic EV tinted glass
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D566B), Color(0xFF101B26)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEFF9FF), Color(0xFF8FC4E2)],
                  ))
                .createShader(glassRect));
      if (bodyStyle != BodyStyle.classic) {
        canvas.drawLine(
            Offset(glassRect.center.dx + w * 0.02, glassRect.top + 2),
            Offset(glassRect.center.dx + w * 0.02, glassRect.bottom),
            Paint()..color = ink.withValues(alpha: .30)..strokeWidth = 2);
      } else {
        // glass reflection streak
        canvas.drawPath(
            glassPath,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .30),
                  Colors.white.withValues(alpha: .0),
                ],
              ).createShader(glassRect));
      }
    }

    // ---- accent skirt + door seam + handle (cartoon bodies only) ----
    if (bodyStyle == BodyStyle.classic) {
      // flush EV look: subtle lower shade + a flush door handle pill
      canvas.drawRect(
          Rect.fromLTWH(x0 + w * 0.10, y0 + bodyH * 0.92, w * 0.80,
              bodyH * 0.08),
          Paint()
            ..color = darken(body, .45).withValues(alpha: 0.75));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x0 + w * 0.45, y0 + bodyH * 0.30, w * 0.075,
                  bodyH * 0.09),
              Radius.circular(bodyH * 0.05)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.65));
    } else {
      canvas.drawRect(
          Rect.fromLTWH(x0 + w * 0.10, y0 + bodyH * 0.90, w * 0.80,
              bodyH * 0.10),
          Paint()..color = darken(body, .45));
      canvas.drawLine(
          Offset(x0 + w * 0.42, y0 + bodyH * 0.10),
          Offset(x0 + w * 0.42, y0 + bodyH * 0.85),
          Paint()..color = ink.withValues(alpha: .25)..strokeWidth = 1.4);
    }

    // ---- racing stripes: bold twin bands with the mod ----
    if (mods.contains('stripes')) {
      canvas.drawLine(
          Offset(x0 + w * 0.08, y0 + bodyH * 0.30),
          Offset(x0 + w * 0.90, y0 + bodyH * 0.16),
          Paint()..color = car.accentColor..strokeWidth = bodyH * 0.10);
      canvas.drawLine(
          Offset(x0 + w * 0.10, y0 + bodyH * 0.70),
          Offset(x0 + w * 0.88, y0 + bodyH * 0.86),
          Paint()..color = car.accentColor..strokeWidth = bodyH * 0.10);
    } else {
      canvas.drawLine(
          Offset(x0 + w * 0.08, y0 + bodyH * 0.08),
          Offset(x0 + w * 0.92, y0 + bodyH * 0.08),
          Paint()
            ..color = car.accentColor.withValues(alpha: .55)
            ..strokeWidth = 2.4);
    }

    // ---- muscle hood scoop ----
    if (bodyStyle == BodyStyle.muscle) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  x0 + w * 0.55, y0 - bodyH * 0.28, w * 0.10, bodyH * 0.26),
              Radius.circular(bodyH * 0.10)),
          Paint()..color = darken(body, .35));
    }

    // ---- rear wing (grand with spoiler mod, standard on sport) ----
    final wantsWing =
        mods.contains('spoiler') || bodyStyle == BodyStyle.sport;
    if (wantsWing) {
      final wingH = mods.contains('spoiler') ? bodyH * 0.40 : bodyH * 0.22;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x0 - w * 0.055, y0 - bodyH * 0.42 - wingH,
                  w * 0.09, wingH),
              Radius.circular(wingH * 0.24)),
          Paint()..color = darken(body, .42));
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x0 + w * 0.01, y0 - bodyH * 0.28),
              width: w * 0.02,
              height: bodyH * 0.52),
          Paint()..color = darken(body, .50));
    }

    // ---- twin mega exhaust (mod) ----
    if (mods.contains('exhaust')) {
      canvas.drawCircle(Offset(x0, y0 + bodyH * 0.55), bodyH * 0.10,
          Paint()..color = const Color(0xFF455A64));
      canvas.drawCircle(Offset(x0, y0 + bodyH * 0.85), bodyH * 0.10,
          Paint()..color = const Color(0xFF455A64));
    }

    // ---- lights: head + tail (EV light bars on the classic) ----
    if (bodyStyle == BodyStyle.classic) {
      // front LED light bar hugging the nose + soft glow
      final nose = Rect.fromLTWH(
          x0 + w * 0.985, y0 + bodyH * 0.10, bodyH * 0.10, bodyH * 0.55);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(x0 + w * 0.985, y0 + bodyH * 0.38),
                  width: bodyH * 0.09,
                  height: bodyH * 0.55),
              Radius.circular(bodyH * 0.08)),
          Paint()..color = const Color(0xFFEFFBFF));
      canvas.drawCircle(
          Offset(x0 + w * 0.985, y0 + bodyH * 0.38),
          bodyH * 0.42,
          Paint()..color = const Color(0x2E80DEEA));
      // full-width tail light bar
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  x0 + w * 0.005, y0 + bodyH * 0.26, w * 0.045,
                  bodyH * 0.10),
              Radius.circular(bodyH * 0.05)),
          Paint()..color = const Color(0xFFFF4757));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  x0 + w * 0.005, y0 + bodyH * 0.26, w * 0.045,
                  bodyH * 0.10),
              Radius.circular(bodyH * 0.05)),
          Paint()..color = const Color(0x40FF4757));
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(x0 + w * 0.945, y0 + bodyH * 0.34),
                  width: w * 0.030,
                  height: bodyH * 0.18),
              Radius.circular(bodyH * 0.06)),
          Paint()..color = const Color(0xFFFFF3C4));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(x0 + w * 0.028, y0 + bodyH * 0.30),
                  width: w * 0.022,
                  height: bodyH * 0.22),
              Radius.circular(bodyH * 0.06)),
          Paint()..color = const Color(0xFFFF5252));
    }

    // ---- wheels: monster gets giants ----
    final wheelR = bodyStyle == BodyStyle.monster
        ? bodyH * 0.66
        : bodyH * (bodyStyle == BodyStyle.sport ? 0.44 : 0.52);
    for (final offset in [x0 + w * 0.22, x0 + w * 0.76]) {
      final cyW = cy + bodyH * 0.28 + lift * 0.4;
      canvas.drawCircle(Offset(offset, cyW), wheelR,
          Paint()..color = const Color(0xFF17191D));
      canvas.drawCircle(Offset(offset, cyW), wheelR * 0.62,
          Paint()..color = const Color(0xFFD9DEE3));
      final spokes = Paint()
        ..color = const Color(0xFF9AA3AC)
        ..strokeWidth = wheelR * 0.15
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 5; i++) {
        final ang = i * 2 * math.pi / 5 + 0.4;
        canvas.drawLine(
            Offset(offset, cyW + wheelR * 0.16),
            Offset(offset + wheelR * 0.55 * math.cos(ang),
                cyW + wheelR * 0.55 * math.sin(ang)),
            spokes);
      }
      canvas.drawCircle(Offset(offset, cyW), wheelR * 0.16,
          Paint()..color = ink);
    }

    // ---- roof add-ons ----
    if (mods.contains('lightbar')) {
      for (var i = 0; i < 4; i++) {
        canvas.drawCircle(
            Offset(x0 + w * (0.44 + i * 0.07), y0 - bodyH * 0.58),
            bodyH * 0.07,
            Paint()..color = const Color(0xFFFFF59D));
      }
    }
    if (mods.contains('flag')) {
      final top = Offset(
          x0 + w * 0.70,
          y0 - bodyH * (bodyStyle == BodyStyle.monster ? 0.05 : 0.95));
      canvas.drawLine(
          top,
          top.translate(0, -bodyH * 0.55),
          Paint()
            ..color = const Color(0xFF37474F)
            ..strokeWidth = 2);
      final wave = math.sin(bounce * 6 + cy * 0.2) * 3;
      final pennant = Path()
        ..moveTo(top.dx, top.dy - bodyH * 0.55)
        ..lineTo(top.dx + bodyH * 0.5, top.dy - bodyH * 0.42 + wave)
        ..lineTo(top.dx, top.dy - bodyH * 0.28)
        ..close();
      canvas.drawPath(pennant, Paint()..color = car.accentColor);
    }
    if (mods.contains('roundel')) {
      final rc = Offset(x0 + w * 0.30, y0 + bodyH * 0.35);
      canvas.drawCircle(rc, bodyH * 0.24, Paint()..color = Colors.white);
      final tp = TextPainter(
          text: const TextSpan(text: '7'),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(rc.dx - tp.width / 2, rc.dy - tp.height / 2));
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

Color lightenBody(Color color, [double amount = .2]) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness * (1 + amount)).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * 0.92).clamp(0.0, 1.0))
      .toColor();
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
