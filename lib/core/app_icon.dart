import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The launcher icon artwork: a glossy dark tile with a radial glow,
/// diagonal speed streaks, the Tesla-style EV car, and a gold star.
/// `maskable` keeps all art inside the 80% safe zone for Android
/// adaptive masking.
class AppIcon extends StatelessWidget {
  const AppIcon({this.maskable = false, super.key});
  final bool maskable;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(512, 512),
      painter: _AppIconPainter(maskable: maskable),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  _AppIconPainter({required this.maskable});
  final bool maskable;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 512;

    // ---- background: deep night gradient ----
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF081226), Color(0xFF0B1026), Color(0xFF171233)],
          ).createShader(Offset.zero & size));

    // ---- radial glow behind the car (teal-to-pink neon) ----
    _glow(canvas, const Offset(150, 110), 190 * r, const Color(0x2E4FC3F7));
    _glow(canvas, const Offset(400, 330), 210 * r, const Color(0x2EFF7BD5));

    // ---- diagonal speed streaks ----
    final streak = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9 * r;
    final streaks = <(double, double, double, double, Color)>[
      (60, 150, 240, 130, const Color(0x33FFFFFF)),
      (300, 60, 470, 90, const Color(0x2EFFFFFF)),
      (90, 380, 300, 340, const Color(0x26FFFFFF)),
      (350, 440, 480, 410, const Color(0x2EFFFFFF)),
    ];
    for (final s in streaks) {
      streak.color = s.$5;
      canvas.drawLine(
          Offset(s.$1 * r, s.$2 * r), Offset(s.$3 * r, s.$4 * r), streak);
    }

    // ---- the car, hero of the tile (dedicated icon-scale artwork) ----
    final carW = (maskable ? 280.0 : 360.0) * r;
    final carH = carW * (210.0 / 380.0);
    final carOffset = Offset(size.width / 2 - carW / 2,
        size.height * (maskable ? 0.52 : 0.55) - carH / 2);
    canvas.save();
    canvas.translate(carOffset.dx, carOffset.dy);
    _drawCar(canvas, carW, carH);
    canvas.restore();

    // ---- gold star, top right ----
    final starC = Offset(maskable ? 130 * r + 110 * r : 428 * r,
        maskable ? 96 * r : 92 * r);
    _glow(canvas, starC, 56 * r, const Color(0x4EFFE082));
    final path = Path();
    const starR = 42.0;
    for (var i = 0; i < 10; i++) {
      final ang = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? starR : starR * 0.44;
      final p = Offset(
          starC.dx + radius * r * math.cos(ang),
          starC.dy + radius * r * math.sin(ang));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawShadow(path, const Color(0x88000000), 6 * r, false);
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF176), Color(0xFFFFB300)],
          ).createShader(Rect.fromCircle(center: starC, radius: starR * r)));
  }

  /// Side-view EV fastback drawn in a fixed 380x210 art space, scaled to
  /// fit [w]x[h]. Crisp at icon sizes — separate from the in-game preview.
  void _drawCar(Canvas c, double w, double h) {
    final s = w / 380.0;
    final ground = 186 * s;
    final wheelR = 40 * s;
    final wheels = <Offset>[
      Offset(102 * s, ground),
      Offset(288 * s, ground),
    ];

    // parking shadow
    c.drawOval(
        Rect.fromCenter(
            center: Offset(195 * s, ground + wheelR * 0.92),
            width: w * 0.82,
            height: 26 * s),
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0x59000000),
            const Color(0x00000000),
          ]).createShader(Rect.fromCenter(
              center: Offset(195 * s, ground + wheelR * 0.92),
              width: w * 0.82,
              height: 26 * s)));

    // ---- silhouette: smooth fastback ----
    final body = Path()
      ..moveTo(34 * s, 176 * s)
      ..lineTo(26 * s, 148 * s) // front bumper face
      ..quadraticBezierTo(
          24 * s, 128 * s, 48 * s, 120 * s) // rounded nose
      ..quadraticBezierTo(
          70 * s, 113 * s, 92 * s, 108 * s) // short hood
      ..quadraticBezierTo(
          118 * s, 102 * s, 142 * s, 74 * s) // windshield rake
      ..quadraticBezierTo(
          190 * s, 52 * s, 238 * s, 56 * s) // glossy roofline
      ..quadraticBezierTo(
          300 * s, 68 * s, 340 * s, 118 * s) // fastback taper
      ..quadraticBezierTo(
          356 * s, 140 * s, 354 * s, 176 * s) // rear face
      ..lineTo(34 * s, 176 * s)
      ..close();
    c.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0xFFFF5A6E),
              Color(0xFFE63C55),
              Color(0xFFB12038),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromLTWH(0, 40 * s, w, 150 * s)));

    // body-side shading + beltline highlight
    c.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                const Color(0x00FFFFFF),
                Colors.white.withValues(alpha: .05),
                const Color(0x00000000),
              ])
              .createShader(Rect.fromLTWH(0, 0, w, h)));
    c.drawLine(
        Offset(52 * s, 116 * s),
        Offset(340 * s, 128 * s),
        Paint()
          ..strokeWidth = 3.2 * s
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .35));

    // ---- tinted glass canopy ----
    final glass = Path()
      ..moveTo(148 * s, 80 * s)
      ..quadraticBezierTo(192 * s, 62 * s, 234 * s, 66 * s)
      ..quadraticBezierTo(
          282 * s, 78 * s, 310 * s, 116 * s) // rear glass slope
      ..quadraticBezierTo(
          250 * s, 104 * s, 196 * s, 100 * s) // beltline return
      ..close();
    c.drawPath(
        glass,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF9FD8FF).withValues(alpha: .55),
              const Color(0xFF16233B).withValues(alpha: .95),
            ],
          ).createShader(Rect.fromLTWH(140 * s, 56 * s, 180 * s, 60 * s)));

    // flush door handle
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(206 * s, 112 * s),
                width: 26 * s,
                height: 6 * s),
            Radius.circular(3 * s)),
        Paint()..color = Colors.white.withValues(alpha: .75));

    // ---- light signature ----
    // LED headlight strip (front)
    final nose = Rect.fromLTWH(24 * s, 126 * s, 44 * s, 7 * s);
    c.drawRRect(RRect.fromRectAndRadius(nose, Radius.circular(4 * s)),
        Paint()..color = const Color(0xFF03172E));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(28 * s, 127.5 * s, 38 * s, 4 * s),
            Radius.circular(2.5 * s)),
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFBFF3FF),
            Color(0xFF7FE7FF),
          ]).createShader(nose)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2.5 * s));
    // tail light bar (rear)
    final tail = Rect.fromLTWH(344 * s, 124 * s, 7 * s, 44 * s);
    c.drawRRect(RRect.fromRectAndRadius(tail, Radius.circular(4 * s)),
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFFF8A80),
            Color(0xFFFF4438),
          ]).createShader(tail)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 3 * s));

    // aero skirt along the bottom
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(60 * s, 176 * s, 280 * s, 8 * s),
            Radius.circular(4 * s)),
        Paint()..color = const Color(0xFF201014));

    // ---- aero wheels ----
    for (final ctr in wheels) {
      c.drawCircle(ctr, wheelR, Paint()..color = const Color(0xFF14171C));
      c.drawCircle(ctr, wheelR * .80, Paint()..color = const Color(0xFF2A2F36));
      c.drawCircle(
          ctr,
          wheelR * .80,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = wheelR * .07
            ..color = const Color(0xFF525A63));
      final blade = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = wheelR * .09
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF5C646D);
      for (var i = 0; i < 9; i++) {
        c.drawArc(
            Rect.fromCircle(center: ctr, radius: wheelR * .58),
            i * 2 * 3.14159 / 9,
            .5,
            false,
            blade);
      }
      c.drawCircle(ctr, wheelR * .13, Paint()..color = const Color(0xFF10131A));
      c.drawCircle(
          ctr, wheelR * .05, Paint()..color = const Color(0xFF93A0AB));
    }
  }

  void _glow(Canvas c, Offset at, double radius, Color color) {
    c.drawCircle(
        at,
        radius,
        Paint()
          ..shader = RadialGradient(
                  colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: at, radius: radius)));
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter oldDelegate) =>
      oldDelegate.maskable != maskable;
}
