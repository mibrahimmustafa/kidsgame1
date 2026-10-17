import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'models.dart';
import 'theme.dart';
import 'world.dart';

/// The signature experience: a first-person COCKPIT view. The road rushes
/// toward a vanishing point with real projections, the dashboard, a
/// rotating steering wheel and a working speedometer. Everything is
/// procedural vector art â€” no bitmaps.
class CockpitPainter extends CustomPainter {
  CockpitPainter(
    this.world,
    this.theme,
    this.tick, {
    this.mods = const <String>{},
  });

  final GameWorld world;
  final TrackTheme theme;
  final double tick;
  final Set<String> mods;

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    final speedFactor = (world.activeSpeed / world.level.cruiseSpeed).clamp(0.0, 2.2);
    final curve = world.roadCurve;
    // gentle body roll opposite to the turn, plus a touch of shake
    final roll = -world.steer * 0.028 - curve * 0.015;
    final shakeX = (world.shake + world.bumpSeconds) > 0
        ? math.sin(tick * 47) * 2.2 * world.shake
        : 0.0;
    final shakeY =
        world.shake > 0 ? math.cos(tick * 41) * 2.6 * world.shake : 0.0;
    final horizon = H * 0.40 - speedFactor * 2.0 + shakeY; // FOV push
    final roadDown = H * 0.86; // road meets the hood below dash area

    double s(double z) => 1.0 / (1.0 + z * 0.085);
    double dpy(double z) => horizon + (roadDown - horizon) * math.pow(s(z), 1.1);
    double halfW(double z) => W * 0.66 * s(z);
    double shift(double z) => -curve * math.pow(1 - s(z), 1.8) * W * 0.55;

    canvas.save();
    // shake, then opposing body roll â€” pivot around the horizon center
    canvas.translate(shakeX, 0);
    final pivot = Offset(W / 2, horizon + (roadDown - horizon) * 0.45);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(roll);
    canvas.translate(-pivot.dx, -pivot.dy);

    // ================================================================ sky
    final skyRect = Rect.fromLTRB(0, 0, W, horizon + 2);
    canvas.drawRect(
        Rect.fromLTRB(0, -40, W, horizon + 2),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.skyTop, theme.skyBottom],
          ).createShader(skyRect));

    // decorative sky chips: sun/moon, stars, embers
    if (theme.stars) {
      for (var i = 0; i < 42; i++) {
        final rx = ((i * 97) % 100) / 100;
        final ry = ((i * 53) % 100) / 100;
        final tw = 0.5 + 0.5 * math.sin(tick * 3 + i);
        canvas.drawCircle(
          Offset(rx * W, ry * horizon * 0.85),
          1.6 * s(H) * 260 * 260 * 1e-4,
          _fill(Colors.white, alpha: 0.28 + 0.30 * tw),
        );
      }
    }
    if (theme.embers) {
      for (var i = 0; i < 14; i++) {
        final drift = ((tick * 22 + i * 61) % (horizon + 60));
        final x = ((i * 137) % 100) / 100 * W;
        canvas.drawCircle(
          Offset(x + math.sin(tick * 2 + i) * 8, horizon - drift * 0.8 + 40),
          2.2,
          _fill(const Color(0xFFFF8A50), alpha: 0.5),
        );
      }
    }
    if (!theme.night) {
      // big soft sun/moon
      final sunX = W * 0.68;
      final sunY = horizon * 0.42;
      canvas.drawCircle(Offset(sunX, sunY), H * 0.075,
          _fill(const Color(0xFFFFFFFF), alpha: 0.35));
      canvas.drawCircle(Offset(sunX, sunY), H * 0.052,
          _fill(const Color(0xFFFFEC9A), alpha: 0.95));
    }

    if (theme.night) {
      // city silhouette along the horizon
      final paint = _fill(theme.hillFar, alpha: 0.9);
      for (var i = 0; i < 26; i++) {
        final bx = (i / 26) * W;
        final bw = W / 34;
        final bh = H * (0.05 + (((i * 31) % 17) / 17) * 0.075);
        canvas.drawRect(Rect.fromLTWH(bx, horizon - bh, bw, bh), paint);
        // lit windows
        if (((i * 13) % 3) == 0) {
          canvas.drawCircle(
            Offset(bx + bw * 0.5, horizon - bh * 0.55),
            1.5,
            _fill(const Color(0xFFFFE9A8), alpha: 0.75),
          );
        }
      }
    } else {
      // rolling hills along the horizon
      final hillPaint = _fill(theme.hillFar);
      final hill = Path()
        ..moveTo(0, horizon)
        ..lineTo(0, horizon - H * 0.045)
        ..quadraticBezierTo(W * 0.25, horizon - H * 0.10, W * 0.5, horizon - H * 0.04)
        ..quadraticBezierTo(W * 0.75, horizon + H * 0.02, W, horizon - H * 0.05)
        ..lineTo(W, horizon)
        ..close();
      canvas.drawPath(hill, hillPaint);
      final hill2 = Path()
        ..moveTo(0, horizon)
        ..lineTo(0, horizon - H * 0.02)
        ..quadraticBezierTo(W * 0.35, horizon + H * 0.03, W * 0.62, horizon - H * 0.055)
        ..quadraticBezierTo(W * 0.85, horizon + H * 0.01, W, horizon - H * 0.02)
        ..lineTo(W, horizon)
        ..close();
      canvas.drawPath(hill2, _fill(theme.hill));
    }

    // ============================================================= ground
    canvas.drawRect(
        Rect.fromLTRB(0, horizon, W, roadDown + 60),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.groundA, theme.groundB],
          ).createShader(Rect.fromLTRB(0, horizon, W, roadDown + 60)));

    // moving grass bands: strong forward-motion cue
    const bandLen = 7.0;
    final bandPhase = world.distance % (bandLen * 2);
    for (var i = 0; i < 26; i++) {
      final z0 = i * bandLen - bandPhase;
      if (z0 < 0.4) continue;
      final z1 = z0 + bandLen;
      if (dpy(z1) - dpy(z0) < 0.6) break;
      final isA = (i ~/ 1) % 2 == 0;
      for (final side in [false, true]) {
        final quad = Path()
          ..moveTo(side ? W : -20, dpy(z0))
          ..lineTo(side ? W : -20, dpy(z1))
          ..lineTo(W / 2 + shift(z1) + halfW(z1) * 1.06, dpy(z1))
          ..lineTo(W / 2 + shift(z0) + halfW(z0) * 1.06, dpy(z0))
          ..close();
        canvas.drawPath(quad, _fill(isA ? theme.groundA : theme.groundB, alpha: isA ? 0.0 : 0.35));
      }
    }

    // ============================================================== road
    // asphalt sheet in depth bands for a subtle speed texture
    const zFar = 120.0;
    for (var i = 0; i < 30; i++) {
      final z0 = (math.pow(i / 30, 2.1)) * zFar;
      final z1 = (math.pow((i + 1) / 30, 2.1)) * zFar;
      if (z1 < 0.35) continue;
      final y0 = dpy(z0);
      final y1 = dpy(z1);
      final quad = Path()
        ..moveTo(W / 2 + shift(z0) - halfW(z0), y0)
        ..lineTo(W / 2 + shift(z1) - halfW(z1), math.min(y1, horizon + 1))
        ..lineTo(W / 2 + shift(z1) + halfW(z1), math.min(y1, horizon + 1))
        ..lineTo(W / 2 + shift(z0) + halfW(z0), y0)
        ..close();
      final bright = i % 2 == 0 ? 0.055 : 0.0;
      canvas.drawPath(
          quad, _fill(Color.lerp(theme.road, Colors.white, bright)!));
    }
    // horizon haze on the road so it melts into distance
    canvas.drawRect(
        Rect.fromLTRB(0, horizon, W, horizon + H * 0.035),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.groundA.withValues(alpha: 0.9),
              theme.groundA.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTRB(0, horizon, W, horizon + H * 0.035)));

    double roadX(double xUnit, double z) =>
        W / 2 + shift(z) + xUnit * halfW(z);

    // edges: one sleek continuous line each side + white lane borders
    for (final edge in [-0.95, 0.95]) {
      _drawEdgeStripe(
          canvas, edge, halfW, shift, dpy, W, zFar, theme.roadEdge, 0.022, 0.95);
    }
    for (final edge in [-0.88, 0.88]) {
      _drawEdgeStripe(canvas, edge, halfW, shift, dpy, W, zFar,
          theme.laneDash, 0.010, 0.8);
    }

    // dashed lane dividers scrolling toward the driver
    const dashEvery = 5.2;
    final dashPhase = world.distance % dashEvery;
    for (final divider in [-0.45, 0.0, 0.45]) {
      for (var i = 0; i < 22; i++) {
        final z0 = i * dashEvery - dashPhase + 0.3;
        if (z0 < 0.5) continue;
        final z1 = z0 + 1.6 + z0 * 0.10; // dashes stretch with depth
        if (dpy(z0) - dpy(z1) < 1.2) continue;
        final dash = Path()
          ..moveTo(roadX(divider - 0.012, z0), dpy(z0))
          ..lineTo(roadX(divider - 0.012, z1), dpy(z1))
          ..lineTo(roadX(divider + 0.012, z1), dpy(z1))
          ..lineTo(roadX(divider + 0.012, z0), dpy(z0))
          ..close();
        canvas.drawPath(dash, _fill(theme.laneDash, alpha: 0.92));
      }
    }

    if (theme.rainbowRoad) {
      // galaxy charm: rainbow shimmer bands along the tarmac
      final colors = const [
        Color(0x33FF5252),
        Color(0x33FFCA28),
        Color(0x3366FFA6),
        Color(0x334FC3F7),
        Color(0x33AB47BC),
      ];
      for (var c = 0; c < colors.length; c++) {
        for (var i = 0; i < 10; i += colors.length ~/ 2 == 0 ? 1 : 2) {
          final z0 = (i + c * 0.4) * 3.0 - (world.distance % 3.0);
          if (z0 < 0.4) continue;
          final z1 = z0 + 0.9;
          final quad = Path()
            ..moveTo(W / 2 + shift(z0) - halfW(z0), dpy(z0))
            ..lineTo(W / 2 + shift(z1) - halfW(z1), dpy(z1))
            ..lineTo(W / 2 + shift(z1) - halfW(z1) * 0.98, dpy(z1))
            ..lineTo(W / 2 + shift(z0) - halfW(z0) * 0.98, dpy(z0))
            ..close();
          canvas.drawPath(quad,
              _fill(colors[c], alpha: colors[c].a));
        }
      }
    }

    // night: warm headlight cones cutting the road
    if (theme.night) {
      final lightPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFFFF3C0).withValues(alpha: 0.30),
            const Color(0xFFFFF3C0).withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTRB(0, horizon, W, roadDown));
      final beam = Path()
        ..moveTo(W * 0.30, roadDown)
        ..lineTo(roadX(-0.55, zFar), horizon)
        ..lineTo(roadX(0.55, zFar), horizon)
        ..lineTo(W * 0.70, roadDown)
        ..close();
      canvas.drawPath(beam, lightPaint);
    }

    // ====================================================== roadside props
    _drawProps(canvas, s, dpy, halfW, shift, W, H, zFar);
    // ========================================================== world stuff
    _drawEntities(canvas, s, dpy, halfW, shift, W, H, zFar, roadDown);

    // rain droplets ride on the windshield
    if (theme.rain) _drawRain(canvas, W, H, tick);
    if (theme.rain) _drawRainStreaks(canvas, W, horizon, roadDown, speedFactor);

    canvas.restore();
    // everything below rolls with the car â€” the windshield & dash
    canvas.save();
    canvas.translate(shakeX, shakeY * 0.4);

    _drawHood(canvas, W, H);
    _drawDash(canvas, W, H);
    _drawSpeedometer(canvas, W, H);
    _drawNitroGauge(canvas, W, H);
    _drawSteeringWheel(canvas, W, H);
    _drawAilerons(canvas, W, H);
    _drawGlassOverlay(canvas, W, H, horizon, speedFactor);
    _drawSpeedLines(canvas, W, H, horizon, roadDown, speedFactor);

    canvas.restore();
  }

  /// One continuous road-edge stripe from the hood up to the horizon.
  void _drawEdgeStripe(
    Canvas c,
    double xUnit,
    double Function(double) halfW,
    double Function(double) shift,
    double Function(double) dpy,
    double W,
    double zFar,
    Color color,
    double widthUnits,
    double alpha,
  ) {
    final hull = Path();
    final outer = <Offset>[];
    var first = true;
    for (var i = 0; i <= 36; i++) {
      final z = math.pow(i / 36, 1.9) * zFar * 0.92;
      final y = dpy(z);
      final innerX =
          W / 2 + shift(z) + (xUnit - widthUnits * 0.5) * halfW(z);
      final outerX =
          W / 2 + shift(z) + (xUnit + widthUnits * 0.5) * halfW(z);
      if (first) {
        hull.moveTo(innerX, y);
        first = false;
      } else {
        hull.lineTo(innerX, y);
      }
      outer.add(Offset(outerX, y));
    }
    // walk the outer edge back from far to near to close the hull
    for (final p in outer.reversed) {
      hull.lineTo(p.dx, p.dy);
    }
    hull.close();
    c.drawPath(hull, _fill(color, alpha: alpha));
  }
  void _drawProps(
      Canvas c,
      double Function(double) s,
      double Function(double) dpy,
      double Function(double) halfW,
      double Function(double) shift,
      double W,
      double H,
      double zFar) {
    const gap = 6.5;
    final phase = world.distance % gap;
    for (var i = 0; i < 14; i++) {
      final z = i * gap - phase + 1.5;
      if (z < 0.5 || z > zFar) continue;
      final h1 = ((i * 127 + (world.distance ~/ 100)) % 100) / 100;
      for (final sideDir in [-1.0, 1.0]) {
        final r = _hash01(i * 31 + (sideDir < 0 ? 7 : 13));
        final xUnit = sideDir * (1.28 + r * 0.55);
        final sc = s(z);
        final px = W / 2 + shift(z) + xUnit * halfW(z);
        final py = dpy(z) + 4 * sc * 30;
        final size = H * 0.22 * sc;
        if (size < 3) continue;
        _drawPropByTheme(c, px, py, size, h1, theme);
      }
    }
  }

  double _hash01(int n) {
    final x = math.sin(n * 12.9898) * 43758.5453;
    return x - x.floor();
  }

  void _drawPropByTheme(Canvas c, double x, double y, double size,
      double seedVal, TrackTheme theme) {
    switch (theme.name) {
      case 'Sunny Beach':
        // palm-ish: trunk + leaf fan
        c.save();
        c.translate(x, y);
        c.drawRect(Rect.fromLTWH(-size * 0.04, -size, size * 0.08, size),
            _fill(const Color(0xFF8D6E63)));
        for (var i = 0; i < 5; i++) {
          final ang = -math.pi / 2 + (i - 2) * 0.5;
          final leaf = Path()
            ..moveTo(0, -size)
            ..quadraticBezierTo(
                math.cos(ang) * size * 0.5,
                -size + math.sin(ang) * size * 0.6,
                math.cos(ang) * size * 0.62,
                -size + math.sin(ang) * size * 0.5 + size * 0.12)
            ..quadraticBezierTo(math.cos(ang) * size * 0.3, -size + size * 0.06,
                0, -size)
            ..close();
          c.drawPath(leaf, _fill(const Color(0xFF2E7D32)));
        }
        c.restore();
      case 'Snowy Hills':
        // pine
        c.save();
        c.translate(x, y);
        c.drawRect(Rect.fromLTWH(-size * 0.05, 0, size * 0.1, -size * 0.22),
            _fill(const Color(0xFF6D4C41)));
        for (var layer = 0; layer < 3; layer++) {
          final ly = -size * (0.24 + layer * 0.25);
          final lw = size * (0.30 - layer * 0.07);
          final tri = Path()
            ..moveTo(0, ly - size * 0.32)
            ..lineTo(-lw, ly)
            ..lineTo(lw, ly)
            ..close();
          c.drawPath(tri, _fill(const Color(0xFF2E7D5B)));
          c.drawPath(tri, _fill(const Color(0xFFFFFFFF), alpha: layer * 0.16));
        }
        c.restore();
      case 'Cookie Desert':
        // cactus
        c.save();
        c.translate(x, y);
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(-size * 0.08, -size, size * 0.16, size),
                Radius.circular(size * 0.08)),
            _fill(const Color(0xFF4C8C4A)));
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(-size * 0.30, -size * 0.65, size * 0.24,
                    size * 0.10),
                Radius.circular(size * 0.05)),
            _fill(const Color(0xFF4C8C4A)));
        c.save();
        c.rotate(-0.4);
        c.restore();
        c.restore();
      case 'Twinkle City':
        // street lamp with a glow pool
        c.save();
        c.translate(x, y);
        c.drawRect(Rect.fromLTWH(-size * 0.035, -size * 0.9, size * 0.07, size * 0.9),
            _fill(const Color(0xFF37474F)));
        c.drawCircle(Offset(0, -size * 0.92), size * 0.09,
            _fill(const Color(0xFFFFE9A8)));
        c.drawCircle(Offset(0, -size * 0.92), size * 0.16,
            _fill(const Color(0xFFFFE9A8), alpha: 0.25));
        c.restore();
      case 'Volcano Valley':
        // lava rock
        c.drawCircle(Offset(x, y - size * 0.18), size * 0.22,
            _fill(const Color(0xFF5D4037)));
        c.drawCircle(Offset(x - size * 0.06, y - size * 0.28), size * 0.10,
            _fill(const Color(0xFFFF7043), alpha: 0.8));
      case 'Galaxy Loop':
        // glowing crystal
        c.save();
        c.translate(x, y - size * 0.3);
        c.rotate(seedVal * 0.8 - 0.4);
        final cry = Path()
          ..moveTo(0, -size * 0.4)
          ..lineTo(-size * 0.12, 0)
          ..lineTo(0, size * 0.16)
          ..lineTo(size * 0.12, 0)
          ..close();
        c.drawPath(cry,
            _fill(const Color(0xFFBA68C8), alpha: 0.8));
        c.restore();
      default:
        // leafy meadow/forest tree with a trunk shadow
        c.save();
        c.translate(x, y);
        c.drawOval(
            Rect.fromCenter(
                center: Offset(0, 2), width: size * 0.34, height: size * 0.10),
            _fill(const Color(0x33000000)));
        c.drawRect(Rect.fromLTWH(-size * 0.05, -size * 0.34, size * 0.10, size * 0.34),
            _fill(const Color(0xFF8D6E63)));
        c.drawCircle(Offset(0, -size * 0.42), size * 0.30, _fill(theme.hill));
        c.drawCircle(Offset(-size * 0.16, -size * 0.32), size * 0.22,
            _fill(theme.hill));
        c.drawCircle(Offset(size * 0.16, -size * 0.34), size * 0.20,
            _fill(theme.hillFar));
        c.drawCircle(
            Offset(-size * 0.08, -size * 0.46), size * 0.16,
            _fill(const Color(0xFFFFFFFF), alpha: 0.14));
        c.restore();
    }
  }

  // --------------------------------------------------------------- entities
  void _drawEntities(
      Canvas c,
      double Function(double) s,
      double Function(double) dpy,
      double Function(double) halfW,
      double Function(double) shift,
      double W,
      double H,
      double zFar,
      double roadDown) {
    final ws = world;
    // sort so the nearest draws last (painter's algorithm)
    final sorted = [...ws.entities]..sort((a, b) => b.y.compareTo(a.y));
    for (final e in sorted) {
      final z = e.y;
      if (z < 0.6 || z > zFar) continue;
      final sc = s(z);
      final px = W / 2 + shift(z) + e.x * halfW(z) + (e.nudge * halfW(z));
      final py = dpy(z);
      final size = H * 0.16 * sc;
      if (size < 2.2) continue;
      switch (e.kind) {
        case EntityKind.trafficCar:
          _drawTrafficRear(c, px, py, size, e);
        case EntityKind.coin:
          c.drawOval(Rect.fromCenter(
              center: Offset(px, py - size * 0.1),
              width: size * 0.30,
              height: size * 0.36), _fill(const Color(0xFFFFC531)));
          c.drawOval(Rect.fromCenter(
              center: Offset(px, py - size * 0.1),
              width: size * 0.22,
              height: size * 0.28), _fill(const Color(0xFFFFE082)));
          c.drawOval(Rect.fromCenter(
              center: Offset(px, py - size * 0.1),
              width: size * 0.34,
              height: size * 0.1), _fill(const Color(0x55FFE082)));
        case EntityKind.star:
          _drawStar(c, px, py - size * 0.15, size * 0.2,
              const Color(0xFFffe082), phase: e.phase);
        case EntityKind.boostPowerUp:
          c.drawCircle(Offset(px, py - size * 0.15), size * 0.22,
              _fill(const Color(0xFF80DEEA), alpha: 0.9));
          c.drawCircle(Offset(px, py - size * 0.15), size * 0.30,
              _fill(const Color(0xFF80DEEA), alpha: 0.35));
          _drawBolt(c, px, py - size * 0.15, size * 0.16, Colors.white);
        case EntityKind.heart:
          _drawHeart(c, px, py - size * 0.15, size * 0.2,
              const Color(0xFFFF8FA3), phase: e.phase);
        case EntityKind.cone:
          final w = size * 0.16;
          final cone = Path()
            ..moveTo(px, py - size)
            ..lineTo(px - w, py)
            ..lineTo(px + w, py)
            ..close();
          c.drawPath(cone, _fill(const Color(0xFFFF7043)));
          c.drawRect(Rect.fromLTWH(px - w * 0.75, py - size * 0.55, w * 1.5,
              size * 0.12), _fill(const Color(0xFFF4F7FB)));
        case EntityKind.oilSlick:
          c.drawOval(
              Rect.fromCenter(
                  center: Offset(px, py), width: size * 0.5, height: size * 0.2),
              _fill(const Color(0xFF263238), alpha: 0.85));
          c.drawOval(
              Rect.fromCenter(
                  center: Offset(px - size * 0.06, py - size * 0.03),
                  width: size * 0.18,
                  height: size * 0.06),
              _fill(const Color(0xFF80CBC4), alpha: 0.25));
      }
    }
  }

  /// Traffic seen from behind (rears, taillights, tires) since we chase it.
  void _drawTrafficRear(Canvas c, double px, double py, double size, Entity e) {
    final livery = e.color ?? const Color(0xFF90A4AE);
    final carW = size * (e.variant == 0 ? 0.62 : e.variant == 1 ? 0.72 : 0.58);
    final carH = size * 0.46;
    // shadow
    c.drawOval(
        Rect.fromCenter(
            center: Offset(px, py + carH * 0.36),
            width: carW * 1.05,
            height: carH * 0.22),
        _fill(const Color(0x2E000000)));
    // wheels
    for (final side in [-1.0, 1.0]) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(px + side * carW * 0.48, py + carH * 0.3),
                  width: carW * 0.14,
                  height: carH * 0.30),
              Radius.circular(2)),
          _fill(const Color(0xFF17191D)));
    }
    // body
    final bodyRect = Rect.fromCenter(
        center: Offset(px, py - carH * 0.15), width: carW, height: carH);
    c.drawRRect(
        RRect.fromRectAndRadius(
            bodyRect, Radius.circular(carW * 0.12)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(livery, Colors.white, .18)!, livery],
          ).createShader(bodyRect));
    // rear window
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(px - carW * 0.36, bodyRect.top - carH * 0.02,
                carW * 0.72, carH * 0.30),
            Radius.circular(carW * 0.08)),
        _fill(const Color(0xFFB0BEC5), alpha: 0.7));
    // roof
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(px - carW * 0.34, bodyRect.top - carH * 0.10,
                carW * 0.68, carH * 0.12),
            Radius.circular(carW * 0.05)),
        _fill(Color.lerp(livery, Colors.black, .25)!));
    // taillights â€” bright so they read at distance
    for (final side in [-1.0, 1.0]) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(px + side * carW * 0.35, bodyRect.bottom - carH * 0.22),
                  width: carW * 0.14,
                  height: carH * 0.16),
              Radius.circular(2)),
          _fill(const Color(0xFFFF5252)));
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(px + side * carW * 0.35, bodyRect.bottom - carH * 0.22),
                  width: carW * 0.17,
                  height: carH * 0.20),
              Radius.circular(3)),
          _fill(const Color(0xFFFF5252), alpha: 0.28));
    }
    // plate
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                px - carW * 0.11, bodyRect.bottom - carH * 0.16,
                carW * 0.22, carH * 0.12),
            Radius.circular(2)),
        _fill(const Color(0xFFECEFF1)));
  }

  // ========================================================== cockpit parts
  /// The player's hood with their livery/stripes â€” ties the cockpit to
  /// the actual car & chosen mods.
  void _drawHood(Canvas c, double W, double H) {
    final car = world.car;
    final hasStripes = mods.contains('stripes');
    final noseY = H * 0.60;
    final baseY = H * 1.02;
    final hood = Path()
      ..moveTo(W * 0.5 - W * 0.86, baseY)
      ..quadraticBezierTo(
          W * 0.5, noseY - H * 0.06, W * 0.5 + W * 0.86, baseY)
      ..lineTo(W * 0.5 + W * 0.86, baseY + 30)
      ..lineTo(W * 0.5 - W * 0.86, baseY + 30)
      ..close();
    c.drawPath(
        hood,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(car.bodyColor, Colors.white, .30)!,
              car.bodyColor,
              darken(car.bodyColor, .28),
            ],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(Rect.fromLTRB(0, noseY - 30, W, baseY)));
    // twin stripes when equipped
    if (hasStripes) {
      for (final side in [-1.0, 1.0]) {
        c.save();
        final stripe = Path()
          ..moveTo(W * 0.5 + side * W * 0.03 - W * 0.025, baseY)
          ..quadraticBezierTo(W * 0.5 + side * W * 0.028, noseY - H * 0.02,
              W * 0.5 + side * W * 0.026 - W * 0.02 + W * 0.04, baseY)
          ..close();
        c.drawPath(stripe, _fill(car.accentColor, alpha: 0.85));
        c.restore();
      }
    }
    // windshield scoop/cowl reflection
    c.drawPath(
        hood,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [const Color(0x42FFFFFF), const Color(0x00FFFFFF)],
          ).createShader(Rect.fromLTRB(0, noseY - 30, W, baseY * 0.7)));
  }

  /// Dashboard: leather + ambient accent light + console glow.
  void _drawDash(Canvas c, double W, double H) {
    final car = world.car;
    final top = H * 0.72;
    final dash = Path()
      ..moveTo(0, H)
      ..lineTo(0, top + H * 0.05)
      ..quadraticBezierTo(W * 0.5, top - H * 0.035, W, top + H * 0.05)
      ..lineTo(W, H)
      ..close();
    c.drawPath(
        dash,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFF2B323A), Color(0xFF171C22)],
          ).createShader(Rect.fromLTRB(0, top, W, H)));
    // top rim highlight
    final rim = Path()
      ..moveTo(0, top + H * 0.05)
      ..quadraticBezierTo(W * 0.5, top - H * 0.035, W, top + H * 0.05)
      ..lineTo(W, top + H * 0.065)
      ..quadraticBezierTo(W * 0.5, top - H * 0.02, 0, top + H * 0.065)
      ..close();
    c.drawPath(rim, _fill(const Color(0x66FFFFFF)));
    // ambient accent light strip in the player's livery color
    final strip = Path()
      ..moveTo(0, top + H * 0.075)
      ..quadraticBezierTo(W * 0.5, top - H * 0.012, W, top + H * 0.075)
      ..lineTo(W, top + H * 0.085)
      ..quadraticBezierTo(W * 0.5, top - H * 0.005, 0, top + H * 0.085)
      ..close();
    c.drawPath(strip, _fill(car.accentColor, alpha: 0.55));
    // console: small screen
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(W * 0.28, H * 0.83),
                width: W * 0.08,
                height: H * 0.10),
            Radius.circular(8)),
        _fill(const Color(0xFF0D1114)));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(W * 0.28, H * 0.83),
                width: W * 0.07,
                height: H * 0.085),
            Radius.circular(6)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF263238), Color(0xFF37474F)],
          ).createShader(Rect.fromCenter(
                center: Offset(W * 0.28, H * 0.83),
                width: W * 0.07,
                height: H * 0.09)));
    _paintText(c, 'SPEEDY-OS', Offset(W * 0.28, H * 0.815),
        size: H * 0.018, color: const Color(0xFF80DEEA));
    _paintText(c, '${world.coinsCollected}\$', Offset(W * 0.28, H * 0.845),
        size: H * 0.022, color: const Color(0xFFFFC531));
  }

  /// Working analog speedometer (0..200 km/h) with a needle & digital read.
  void _drawSpeedometer(Canvas c, double W, double H) {
    final cx = W * 0.735;
    final cy = H * 0.855;
    final R = H * 0.115;
    // bezel
    c.drawCircle(Offset(cx, cy), R + H * 0.012,
        _fill(const Color(0xFF3A424B)));
    c.drawCircle(Offset(cx, cy), R, _fill(const Color(0xFF0D1114)));
    // needle angle: 0..200 km/h sweeps -125..+125 degrees
    final kmh = world.speedKmh.clamp(0.0, 200.0);
    // colored arc zones (green cruise / amber / red top end)
    void zone(double from, double to, Color color) {
      final p = Path();
      const startA = -125.0 * math.pi / 180;
      const sweepFull = 250.0 * math.pi / 180;
      final a0 = startA + sweepFull * (from / 200);
      final a1 = startA + sweepFull * (to / 200);
      p.moveTo(cx + math.cos(a0) * R * 0.80, cy + math.sin(a0) * R * 0.80);
      p.arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: R * 0.80),
          a0,
          a1 - a0,
          false);
      c.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = R * 0.10
            ..strokeCap = StrokeCap.round
            ..color = color);
    }

    zone(0, 90, const Color(0xFF4CAF50));
    zone(90, 140, const Color(0xFFFFC531));
    zone(140, 200, const Color(0xFFEF5350));
    // ticks
    for (var i = 0; i <= 10; i++) {
      final a = -125 * math.pi / 180 + (250 * math.pi / 180) * (i / 10);
      final r0 = R * (i % 5 == 0 ? 0.66 : 0.74);
      c.drawLine(
          Offset(cx + math.cos(a) * r0, cy + math.sin(a) * r0),
          Offset(cx + math.cos(a) * R * 0.86, cy + math.sin(a) * R * 0.86),
          Paint()
            ..color = Colors.white.withValues(alpha: i % 5 == 0 ? 0.9 : 0.4)
            ..strokeWidth = i % 5 == 0 ? 2.4 : 1.2
            ..strokeCap = StrokeCap.round);
    }
    // needle
    final a = (-125 + 250 * (kmh / 200)) * math.pi / 180;
    c.drawLine(
        Offset(cx - math.cos(a) * R * 0.12, cy - math.sin(a) * R * 0.12),
        Offset(cx + math.cos(a) * R * 0.72, cy + math.sin(a) * R * 0.72),
        Paint()
          ..color = const Color(0xFFFF5252)
          ..strokeWidth = R * 0.05
          ..strokeCap = StrokeCap.round);
    c.drawCircle(Offset(cx, cy), R * 0.10, _fill(const Color(0xFF3A424B)));
    c.drawCircle(Offset(cx, cy), R * 0.05, _fill(Colors.white));
    _paintText(c, '${kmh.round()}', Offset(cx, cy + R * 0.42),
        size: R * 0.34, color: Colors.white, weight: FontWeight.w800);
    _paintText(c, 'km/h', Offset(cx, cy + R * 0.66),
        size: R * 0.16, color: Colors.white54);
  }

  /// Nitro bottle gauge on the left of the dash.
  void _drawNitroGauge(Canvas c, double W, double H) {
    final gx = W * 0.16;
    final gy = H * 0.855;
    final gw = H * 0.13;
    final gh = H * 0.035;
    final frac = (world.nitro / 100).clamp(0.0, 1.0);
    final bar = Rect.fromCenter(center: Offset(gx, gy), width: gw, height: gh);
    c.drawRRect(
        RRect.fromRectAndRadius(bar, Radius.circular(gh / 2)),
        _fill(const Color(0xFF0D1114)));
    if (frac > 0.01) {
      final fill = Rect.fromCenter(
          center: Offset(gx - gw * (1 - frac) / 2, gy),
          width: gw * frac,
          height: gh);
      c.drawRRect(
          RRect.fromRectAndRadius(fill, Radius.circular(gh / 2)),
          Paint()
            ..shader = AppTheme.nitroGradient.createShader(fill));
    }
    _paintText(c, 'N2O', Offset(gx, gy - gh * 1.05),
        size: gh * 0.52, color: Colors.white60);
    _paintText(c, '${world.nitro.round()}%', Offset(gx, gy + gh * 1.05),
        size: gh * 0.48, color: Colors.white38);
  }

  /// The rotating steering wheel: elliptical rim torus, two side spokes
  /// (they rotate with the wheel) and a horn button in the hub.
  void _drawSteeringWheel(Canvas c, double W, double H) {
    final cx = W * 0.5;
    final cy = H * 1.06; // wheel rises up from the bottom edge
    final rx = W * 0.165;
    final ry = rx * 0.36; // perspective squash
    final rimW = rx * 0.135;
    final spokeAngle = -world.steer * (110 * math.pi / 180.0);

    c.save();
    c.translate(cx, cy);

    // deep cutout behind the wheel so it reads as mounted in the dash
    c.drawOval(
        Rect.fromCenter(
            center: Offset(0, -ry * 0.4), width: rx * 2.4, height: ry * 3.0),
        _fill(const Color(0x52000000)));

    // rim torus
    final rimRect = Rect.fromCenter(
        center: Offset(0, -ry * 0.2), width: rx * 2, height: ry * 2);
    c.drawOval(
        rimRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rimW
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFF2A313A), Color(0xFF12161B)],
          ).createShader(rimRect));
    // glossy top highlight
    c.drawOval(
        Rect.fromCenter(
            center: Offset(0, -ry * 0.2),
            width: rx * 2 - rimW * 0.8,
            height: ry * 2 - rimW * 0.55),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rimW * 0.30
          ..color = const Color(0x4AFFFFFF));

    // rotating spoke cluster (2 o'clock / 10 o'clock feel)
    c.save();
    c.translate(0, -ry * 0.2);
    c.rotate(spokeAngle);
    for (final dir in [-1.0, 1.0]) {
      final spoke = Rect.fromCenter(
          center: Offset(dir * rx * 0.52, ry * 0.18),
          width: rx * 0.62,
          height: rimW * 1.05);
      c.save();
      c.translate(dir * rx * 0.52, ry * 0.18);
      c.rotate(dir * 0.18);
      c.translate(-dir * rx * 0.52, -ry * 0.18);
      c.drawRRect(RRect.fromRectAndRadius(spoke, Radius.circular(rimW * 0.55)),
          _fill(const Color(0xFF232930)));
      c.drawRRect(
          RRect.fromRectAndRadius(
              spoke.deflate(rimW * 0.22), Radius.circular(rimW * 0.4)),
          _fill(const Color(0x38FFFFFF)));
      c.restore();
    }
    // center hub + horn button
    c.save();
    final hub = Rect.fromCenter(
        center: Offset(0, 0), width: rx * 0.58, height: ry * 1.55);
    c.drawRRect(
        RRect.fromRectAndRadius(
            hub.inflate(rimW * 0.28), Radius.circular(rimW * 0.7)),
        _fill(const Color(0xFF0E1216)));
    final pressed = world.hornHeld;
    final hubColor =
        pressed ? const Color(0xFFFF8A50) : const Color(0xFF2C343C);
    c.drawRRect(
        RRect.fromRectAndRadius(hub, Radius.circular(rimW * 0.6)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(hubColor, Colors.white, .16)!,
              hubColor,
            ],
          ).createShader(hub));
    // little horn speaker icon
    final hornScale = ry * 0.28;
    final horn = Path()
      ..moveTo(-hornScale * 1.1, 0)
      ..lineTo(hornScale * 0.25, -hornScale * 0.95)
      ..lineTo(hornScale * 0.25, hornScale * 0.95)
      ..close();
    c.drawPath(horn, _fill(Colors.white, alpha: 0.92));
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white54;
    for (final r in [1.35, 1.95]) {
      c.drawArc(
          Rect.fromCenter(
              center: Offset(-hornScale * 0.7, 0),
              width: hornScale * r * 1.3,
              height: hornScale * r * 2.1),
          -0.9,
          1.8,
          false,
          arcPaint);
    }
    c.restore(); // spoke rotation
    c.restore(); // wheel local space
  }

  void _drawAilerons(Canvas c, double W, double H) {
    // A-pillars framing the windshield, leaning with the roll
    for (final side in [false, true]) {
      final x0 = side ? W : 0.0;
      final dir = side ? -1.0 : 1.0;
      final pillar = Path()
        ..moveTo(x0, 0)
        ..lineTo(x0 - dir * W * 0.085, 0)
        ..lineTo(x0 - dir * W * 0.155, H)
        ..lineTo(x0, H)
        ..close();
      c.drawPath(
          pillar,
          Paint()
            ..shader = LinearGradient(
              begin: side ? Alignment.centerRight : Alignment.centerLeft,
              end: side ? Alignment.centerLeft : Alignment.centerRight,
              colors: const [Color(0xFF23292F), Color(0xFF0F1216)],
            ).createShader(Rect.fromLTRB(0, 0, W, H)));
    }
  }

  void _drawGlassOverlay(
      Canvas c, double W, double H, double horizon, double speedFactor) {
    // windshield tint down into the distance
    c.drawRect(
        Rect.fromLTRB(0, 0, W, horizon + H * 0.10),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0x36101821),
              const Color(0x00101821),
            ],
          ).createShader(Rect.fromLTRB(0, 0, W, horizon + H * 0.10)));
    // slow reflections sliding with steering
    final slideX = -world.steer * 30;
    for (final band in [-0.1, 0.16]) {
      final ref = Path()
        ..moveTo(W * (0.35 + band) + slideX, 0)
        ..lineTo(W * (0.42 + band) + slideX, 0)
        ..lineTo(W * (0.66 + band) + slideX, horizon)
        ..lineTo(W * (0.60 + band) + slideX, horizon)
        ..close();
      c.drawPath(ref, _fill(Colors.white, alpha: 0.05));
    }
    // soft vignette on the glass edges
    final vigRect = Rect.fromLTRB(0, 0, W, H);
    final vig = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 1.05,
        colors: [
          Color(0x00000000),
          Color(0x2A101418),
        ],
        stops: [0.62, 1.0],
      ).createShader(vigRect);
    c.drawRect(vigRect, vig);
  }

  /// FOV speed-lines when the car is really flying.
  void _drawSpeedLines(Canvas c, double W, double H, double horizon,
      double roadDown, double speedFactor) {
    final boostK = (speedFactor - 1.05).clamp(0.0, 1.2);
    if (boostK <= 0) return;
    final n = 26;
    final alpha = (0.10 + 0.24 * boostK).clamp(0.0, 0.4);
    for (var i = 0; i < n; i++) {
      final t = (tick * 2.2 + i * 0.37) % 1.0;
      final yTop = horizon + t * (roadDown - horizon);
      final yBot = horizon + math.min(1.0, t + 0.30) * (roadDown - horizon);
      final xCenter = W * (((i * 61) % 100) / 100);
      final off = 1.0 + t * 2.4;
      c.drawLine(
          Offset(xCenter * off * 0.3 + W * 0.5 * (1 - (t - 0.5).abs() * (t - 0.5).abs() * 0 + (t > 0.5 ? 0.02 : -0.02)), yTop),
          Offset(xCenter * (2.4 - off) + W * 0.5, yBot),
          Paint()
            ..color = Colors.white.withValues(alpha: alpha * (1 - t))
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round);
    }
  }

  /// Light rain streaks across the windshield.
  void _drawRain(Canvas c, double W, double H, double tick) {
    final rand = math.Random(7);
    for (var i = 0; i < 34; i++) {
      final x = rand.nextDouble() * W;
      final baseY = rand.nextDouble() * H;
      final speed = 28 + rand.nextDouble() * 46;
      final y = (baseY + tick * speed) % H;
      c.drawLine(
          Offset(x, y),
          Offset(x + 2.4, y + 9 + rand.nextDouble() * 9),
          _stroke(const Color(0x66CFE8F5), 1.4));
    }
  }

  /// Slightly bigger streaks that flow toward the driver with speed.
  void _drawRainStreaks(
      Canvas c, double W, double horizon, double roadDown, double speedFactor) {
    for (var i = 0; i < 12; i++) {
      final t = ((tick * (1.4 + speedFactor * 0.5)) + i * 0.27) % 1.0;
      final y0 = horizon + t * (roadDown - horizon);
      final len = (roadDown - horizon) * 0.14 * t;
      final side = i % 2 == 0 ? -1.0 : 1.0;
      final x = W * 0.5 + side * W * (0.24 + (i % 5) * 0.05);
      c.drawLine(
          Offset(x, y0),
          Offset(x + side * W * 0.01, y0 + len),
          _stroke(const Color(0x55CFE8F5), 2.2 + t * 2));
    }
  }

  // ----------------------------------------------------------------- utils
  void _drawStar(Canvas c, double x, double y, double r, Color color,
      {double phase = 0}) {
    c.save();
    c.translate(x, y);
    final spin = phase;
    c.rotate(spin);
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final ox = r * math.cos(a);
      final oy = r * math.sin(a);
      final a2 = a + math.pi / 5;
      final ix = r * 0.45 * math.cos(a2);
      final iy = r * 0.45 * math.sin(a2);
      if (i == 0) path.moveTo(ox, oy);
      path.lineTo(ix, iy);
      path.lineTo(
          r * math.cos(a + 2 * math.pi / 5), r * math.sin(a + 2 * math.pi / 5));
    }
    path.close();
    c.drawPath(path, _fill(color));
    c.drawCircle(Offset(0, 0), r * 0.4, _fill(color, alpha: 0.35));
    c.restore();
  }

  void _drawHeart(Canvas c, double x, double y, double r, Color color,
      {double phase = 0}) {
    final s = 1.0 + 0.08 * math.sin(phase * 2);
    c.save();
    c.translate(x, y + r * s * 0.2);
    final path = Path()
      ..moveTo(0, r * s * 0.6)
      ..cubicTo(r * s, -r * s * 0.2, r * s * 0.55, -r * s, 0, -r * s * 0.35)
      ..cubicTo(-r * s * 0.55, -r * s, -r * s, -r * s * 0.2, 0, r * s * 0.6)
      ..close();
    c.drawPath(path, _fill(color));
    c.drawCircle(Offset(-r * 0.28, -r * 0.40), r * 0.16,
        _fill(const Color(0xFFFFFFFF), alpha: 0.6));
    c.restore();
  }

  void _drawBolt(Canvas c, double x, double y, double r, Color color) {
    c.save();
    c.translate(x, y);
    final path = Path()
      ..moveTo(-r * 0.25, -r)
      ..lineTo(r * 0.42, -r)
      ..lineTo(r * 0.06, -r * 0.14)
      ..lineTo(r * 0.46, -r * 0.14)
      ..lineTo(-r * 0.34, r)
      ..lineTo(-r * 0.04, r * 0.02)
      ..lineTo(-r * 0.48, r * 0.02)
      ..close();
    c.drawPath(path, _fill(color));
    c.restore();
  }

  void _paintText(
    Canvas c,
    String text,
    Offset at, {
    required double size,
    Color color = Colors.black,
    FontWeight weight = FontWeight.w700,
  }) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: size, color: color, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(at.dx - tp.width / 2, at.dy - tp.height / 2));
  }

  Paint _fill(Color color, {double alpha = 1.0}) {
    final a = (alpha * color.a).clamp(0.0, 1.0);
    return Paint()..color = color.withValues(alpha: a);
  }

  Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  static Color darken(Color c, double amount) {
    final f = (1.0 - amount).clamp(0.0, 1.0);
    return Color.fromARGB(
      ((c.a * 255.0).round()).clamp(0, 255),
      (((c.r * 255.0) * f).round()).clamp(0, 255),
      (((c.g * 255.0) * f).round()).clamp(0, 255),
      (((c.b * 255.0) * f).round()).clamp(0, 255),
    );
  }

  @override
  bool shouldRepaint(CockpitPainter oldDelegate) => true;
}
