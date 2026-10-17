import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The launcher icon artwork — modern streaming-era game-cover style:
/// electric radial burst, glass light sweep, a HUGE edge-cropped hero car,
/// a 3D faceted gold star with sparkles, and a soft edge vignette.
/// `maskable` keeps all art inside the Android adaptive safe zone.
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
    final tile = Offset.zero & size;
    canvas.clipRect(tile);

    // ================= background: electric radial burst =================
    canvas.drawRect(
        tile,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0.0, 0.24),
            radius: 1.15,
            colors: [
              Color(0xFF3A8DFF),
              Color(0xFF1C4BB8),
              Color(0xFF0A1233),
            ],
            stops: [0.0, 0.52, 1.0],
          ).createShader(tile));

    // sky sheen across the upper half (soft blue, not grey)
    final sweep = Path()
      ..moveTo(-size.width * .2, 0)
      ..lineTo(size.width * .62, 0)
      ..lineTo(size.width * .28, size.height * .62)
      ..lineTo(-size.width * .2, size.height * .62)
      ..close();
    canvas.drawPath(
        sweep,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0x2E6FB6FF), Color(0x006FB6FF)],
          ).createShader(tile));

    // subtle speed ring behind everything (halo circle)
    final ringC = Offset(maskable ? 256 * r : 288 * r,
        maskable ? 256 * r : 236 * r);
    canvas.drawCircle(
        ringC,
        194 * r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20 * r
          ..color = Colors.white.withValues(alpha: .08));
    canvas.drawArc(
        Rect.fromCircle(center: ringC, radius: 194 * r),
        -math.pi * 0.9,
        math.pi * 0.55,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5 * r
          ..color = Colors.white.withValues(alpha: .30));

    // ================= art block (scaled for maskable safe zone) ========
    final f = maskable ? 0.74 : 1.0;
    canvas.save();
    canvas.translate(size.width * (1 - f) / 2, size.height * (1 - f) / 2);
    canvas.scale(f, f);

    // neon floor glow under the car
    _glow(
        canvas,
        Offset(size.width * .5, size.height * .97),
        size.width * .50,
        const Color(0x4D28C7FF));

    // --- 3D gold star (drawn before the car so the car overlaps: depth) --
    final starC = Offset(size.width * .77, size.height * .24);
    final starR = size.width * .175;
    _glow(canvas, starC, starR * 2.6, const Color(0x8CFFD54F));
    _star(canvas, starC, starR, r);

    // --- sparkles ---
    _sparkle(canvas, Offset(size.width * .93, size.height * .09), 13 * r);
    _sparkle(canvas, Offset(size.width * .62, size.height * .10), 9 * r);
    _sparkle(canvas, Offset(size.width * .09, size.height * .46), 10 * r);

    // ================= the huge hero car (edge-cropped) ==================
    final carW = size.width * 1.02;
    final carH = carW * (210.0 / 380.0);
    final carOffset = Offset(
        size.width / 2 - carW / 2,                    // slight crop both ends
        size.height * .90 - carH * (226.0 / 210.0)); // wheels near bottom
    canvas.save();
    canvas.translate(carOffset.dx, carOffset.dy);
    _drawCar(canvas, carW, carH);
    canvas.restore();

    canvas.restore();

    // ================= vignette (cinematic edges) =======================
    canvas.drawRect(
        tile,
        Paint()
          ..shader = RadialGradient(
            radius: 1.0,
            colors: [
              const Color(0x00000000),
              Colors.black.withValues(alpha: .45),
            ],
            stops: const [0.56, 1.0],
          ).createShader(Rect.fromCircle(
              center: size.center(Offset.zero), radius: 380 * r)));
  }

  // ------------------------------------------------------------------
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

    // (no ground shadow — icons read cleaner floating on the poster glow)

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
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF7B8C),
              Color(0xFFEF3D5B),
              Color(0xFFA91230),
            ],
            stops: [0.0, 0.55, 1.0],
          ).createShader(Rect.fromLTWH(0, 40 * s, w, 150 * s)));

    // side sheen sweep
    c.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                const Color(0x00FFFFFF),
                Colors.white.withValues(alpha: .10),
                const Color(0x33000000),
              ])
              .createShader(Rect.fromLTWH(0, 0, w, h)));
    c.drawLine(
        Offset(52 * s, 116 * s),
        Offset(340 * s, 128 * s),
        Paint()
          ..strokeWidth = 3.4 * s
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .42));

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
              const Color(0xFFBDE8FF).withValues(alpha: .60),
              const Color(0xFF101E36).withValues(alpha: .96),
            ],
          ).createShader(Rect.fromLTWH(140 * s, 56 * s, 180 * s, 60 * s)));

    // glass reflection streak
    c.drawLine(
        Offset(162 * s, 78 * s),
        Offset(220 * s, 70 * s),
        Paint()
          ..strokeWidth = 4 * s
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .35));

    // flush door handle
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(206 * s, 112 * s),
                width: 26 * s,
                height: 6 * s),
            Radius.circular(3 * s)),
        Paint()..color = Colors.white.withValues(alpha: .78));

    // ---- light signature ----
    final nose = Rect.fromLTWH(24 * s, 126 * s, 44 * s, 7 * s);
    c.drawRRect(RRect.fromRectAndRadius(nose, Radius.circular(4 * s)),
        Paint()..color = const Color(0xFF03172E));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(28 * s, 127.5 * s, 38 * s, 4 * s),
            Radius.circular(2.5 * s)),
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFD8FBFF),
            Color(0xFF7FE7FF),
          ]).createShader(nose)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2.5 * s));
    final tail = Rect.fromLTWH(344 * s, 124 * s, 7 * s, 44 * s);
    c.drawRRect(RRect.fromRectAndRadius(tail, Radius.circular(4 * s)),
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFFF9A90),
            Color(0xFFFF3B2E),
          ]).createShader(tail)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 3.5 * s));

    // aero skirt
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(60 * s, 176 * s, 280 * s, 8 * s),
            Radius.circular(4 * s)),
        Paint()..color = const Color(0xFF1C0D12));

    // ---- aero wheels ----
    for (final ctr in wheels) {
      c.drawCircle(ctr, wheelR, Paint()..color = const Color(0xFF12161D));
      c.drawCircle(ctr, wheelR * .80, Paint()..color = const Color(0xFF2C323B));
      c.drawCircle(
          ctr,
          wheelR * .80,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = wheelR * .07
            ..color = const Color(0xFF59636E));
      final blade = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = wheelR * .09
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF646E78);
      for (var i = 0; i < 9; i++) {
        c.drawArc(Rect.fromCircle(center: ctr, radius: wheelR * .58),
            i * 2 * math.pi / 9, .5, false, blade);
      }
      c.drawCircle(ctr, wheelR * .13, Paint()..color = const Color(0xFF0E1117));
      c.drawCircle(
          ctr, wheelR * .05, Paint()..color = const Color(0xFF9AA7B3));
    }
  }

  // ------------------------------------------------------------------

  /// 3D faceted 5-point star.
  void _star(Canvas c, Offset center, double radius, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final ang = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? radius : radius * 0.44;
      final p = Offset(center.dx + rad * math.cos(ang),
          center.dy + rad * math.sin(ang));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    // drop depth first
    final deep = Path.from(path)
      ..shift(Offset(0, 12 * r));
    c.drawPath(
        deep,
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFB26A00),
            Color(0xFF7A3E00),
          ]).createShader(Rect.fromCircle(
              center: center + const Offset(0, 12), radius: radius)));

    // base gold gradient fill
    c.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xFFFFA000), Color(0xFFFFE680)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)));

    // glossy light band across a clipped star
    final band = Rect.fromCenter(
        center: Offset(center.dx - radius * .35, center.dy - radius * .3),
        width: radius * 1.6,
        height: radius * .5);
    c.save();
    c.clipPath(path);
    c.drawOval(
        band,
        Paint()
          ..color = Colors.white.withValues(alpha: .35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .28));
    c.restore();

    // sparkle eye
    c.drawCircle(center - Offset(radius * .55, radius * .15), radius * .07,
        Paint()..color = Colors.white.withValues(alpha: .9));
  }

  /// 4-ray twinkle.
  void _sparkle(Canvas c, Offset at, double size) {
    final p = Path()
      ..moveTo(at.dx, at.dy - size)
      ..quadraticBezierTo(at.dx, at.dy, at.dx + size, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + size)
      ..quadraticBezierTo(at.dx, at.dy, at.dx - size, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - size)
      ..close();
    c.drawPath(
        p,
        Paint()
          ..color = Colors.white.withValues(alpha: .8)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, size * .12));
  }

  void _glow(Canvas c, Offset at, double radius, Color color) {
    c.drawCircle(
        at,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            color,
            color.withValues(alpha: 0)
          ]).createShader(Rect.fromCircle(center: at, radius: radius)));
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter oldDelegate) =>
      oldDelegate.maskable != maskable;
}
