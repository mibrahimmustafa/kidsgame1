import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'world.dart';

/// Renders one frame of the race. 100% procedural vector art:
/// every car, coin, cloud and hill is drawn with paths/gradients,
/// so the game is razor-sharp "HD" on any Android DPI.
class RacePainter extends CustomPainter {
  RacePainter(this.world, this.theme, this.tick);

  final GameWorld world;
  final TrackTheme theme;
  final double tick;

  // geometry fractions
  static const double _skyFrac = 0.17;
  static const double _roadBottomFrac = 0.87;

  // dynamic caches
  static final Map<int, Paint> _paintCache = {};

  static Paint _fill(Color c, {double? alpha}) {
    final id = c.toARGB32() * 100 + ((alpha ?? 1) * 100).round();
    final p = _paintCache[id];
    if (p != null) return p;
    final np = Paint()
      ..color = alpha == null ? c : c.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    _paintCache[id] = np;
    return np;
  }

  static Paint _stroke(Color c, double w, {double? alpha}) {
    final id = c.toARGB32() * 100 + ((alpha ?? 1) * 100).round() + 7777000;
    final p = _paintCache[id];
    if (p != null) return p;
    final np = Paint()
      ..color = alpha == null ? c : c.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    _paintCache[id] = np;
    return np;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final viewH = size.height;
    final viewW = size.width;
    final skyBottom = viewH * _skyFrac;
    final roadTop = skyBottom; // road begins right where sky band ends
    final roadBottom = viewH * _roadBottomFrac;
    final roadH = roadBottom - roadTop;
    final playerX = viewW * 0.30;
    final unitPx = viewH / 26;

    // --- screen shake (very subtle)
    final shakePx = world.shake * 5;
    canvas.save();
    if (shakePx > 0.01) {
      canvas.translate(
          math.sin(tick * 61) * shakePx, math.cos(tick * 47) * shakePx * 0.7);
    }

    // ---------- sky band + far hills ----------
    final skyRect = Rect.fromLTWH(0, -viewH, viewW, skyBottom + viewH);
    canvas.drawRect(skyRect,
        Paint()..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.skyTop, theme.skyBottom],
        ).createShader(skyRect));

    if (theme.stars) _drawStars(canvas, viewW, skyBottom);
    _drawHills(canvas, viewW, skyBottom, roadTop, theme.hillFar, 0.30);
    _drawHills(canvas, viewW, skyBottom, roadTop, theme.hill, 0.55);
    if (theme.night) _drawCityBackdrop(canvas, viewW, skyBottom, roadTop);
    _drawClouds(canvas, viewW, skyBottom);
    if (!theme.night) _drawSun(canvas, viewW, skyBottom);

    // ---------- ground band ----------
    canvas.drawRect(
        Rect.fromLTWH(0, roadBottom, viewW, viewH * 2),
        _fill(theme.groundA));
    _drawGroundStripes(canvas, viewW, roadBottom, viewH);
    _drawRoadsideProps(canvas, viewW, roadBottom, viewH);

    // ---------- road ----------
    final roadRect = Rect.fromLTRB(0, roadTop, viewW, roadBottom);
    if (theme.rainbowRoad) {
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF7F5AF0),
          Color(0xFF2CB1BC),
          Color(0xFFEF476F),
          Color(0xFFFFD166),
          Color(0xFF7F5AF0),
        ],
      ).createShader(roadRect);
      canvas.drawRect(
          Rect.fromLTWH(0, roadTop, viewW, roadH), Paint()..shader = shader);
      // soft dark overlay so it reads as tarmac, not candy.
      canvas.drawRect(
          Rect.fromLTWH(0, roadTop, viewW, roadH),
          _fill(const Color(0x66222A38)));
    } else {
      canvas.drawRect(Rect.fromLTWH(0, roadTop, viewW, roadH), Paint()..shader =
          LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.road.withValues(alpha: 0.92),
          theme.road,
          theme.road.withValues(alpha: 0.95),
        ],
      ).createShader(roadRect));
    }

    _drawLaneDashes(canvas, viewW, roadTop, roadBottom, roadH);
    _drawRoadEdges(canvas, roadTop, roadBottom, viewW);

    // ---------- finish banner ----------
    _drawFinish(canvas, viewW, roadTop, roadBottom, roadH, playerX, unitPx);

    // ---------- entities ----------
    _drawEntities(canvas, playerX, roadTop, roadBottom, roadH, unitPx);

    // ---------- particles ----------
    _drawParticles(canvas, playerX, roadTop, roadBottom, roadH, unitPx);

    // ---------- player ----------
    _drawPlayerCar(canvas, playerX, roadTop, roadBottom, roadH);

    // ---------- rain / embers overlays ----------
    if (theme.rain) _drawRain(canvas, viewW, viewH);
    if (theme.embers) _drawEmbers(canvas, viewW, roadTop, roadBottom);

    canvas.restore();

    // ---------- white flash on crash ----------
    if (world.flash > 0.01) {
      canvas.drawRect(
          Offset.zero & size,
          _fill(const Color(0xFFFFFFFF), alpha: world.flash * 0.45));
    }
    // ---------- speed lines while boosting ----------
    if (world.boosting) _drawSpeedLines(canvas, viewW, roadTop, roadBottom);
  }

  // ------------------------------------------------------------ sky decor
  void _drawSun(Canvas c, double viewW, double skyBottom) {
    final cx = (viewW * 0.8 - world.distance * 1.4) % (viewW + 160) - 80;
    final cy = skyBottom * 0.34;
    c.drawCircle(Offset(cx, cy), 26, _fill(const Color(0xFFFFD75E)));
    c.drawCircle(Offset(cx, cy), 34, _fill(const Color(0xFFFFE79E), alpha: 0.35));
  }

  void _drawClouds(Canvas c, double viewW, double skyBottom) {
    for (var i = 0; i < 5; i++) {
      final base = i * 210.0;
      final x = (base + world.distance * (1.1 + i * 0.07)) % (viewW + 320) - 160;
      final y = skyBottom * (0.25 + 0.11 * ((i * 7) % 3));
      final s = 0.7 + (i % 3) * 0.16;
      final path = Path()
        ..addOval(Rect.fromCenter(
            center: Offset(x, y), width: 74 * s, height: 30 * s))
        ..addOval(Rect.fromCenter(
            center: Offset(x + 34 * s, y + 5 * s), width: 56 * s, height: 26 * s))
        ..addOval(Rect.fromCenter(
            center: Offset(x - 30 * s, y + 8 * s), width: 48 * s, height: 22 * s));
      c.drawPath(path, _fill(Colors.white, alpha: 0.85));
    }
  }

  void _drawStars(Canvas c, double viewW, double skyBottom) {
    for (var i = 0; i < 46; i++) {
      final x = ((i * 97 + 23) % 1000) / 1000 * viewW;
      final y = ((i * 53 + 11) % 100) / 100 * skyBottom * 0.8;
      final tw = 0.5 + 0.5 * math.sin(tick * 2.4 + i * 1.3);
      c.drawCircle(Offset(x, y), 1.3 + (i % 3) * 0.5,
          _fill(const Color(0xFFFFFFFF), alpha: 0.45 + 0.5 * tw));
    }
  }

  void _drawCityBackdrop(Canvas c, double viewW, double y0, double y1) {
    const bandH = 0.56;
    final h = (y1 - y0) * bandH;
    final y = y1 - h;
    for (var i = 0; i < 10; i++) {
      final w = 52.0 + (i % 3) * 34;
      final px = ((i * 141.0) + world.distance * 1.2) % (viewW + 240) - 120;
      c.drawRect(Rect.fromLTWH(px, y, w, h), _fill(theme.hill));
      // windows: golden little squares
      for (var r = 0; r < 5; r++) {
        for (var cc = 0; cc < 3; cc++) {
          final lit = ((i * 7 + r * 3 + cc) % 5) < 3;
          if (!lit) continue;
          c.drawRect(
              Rect.fromCenter(
                center: Offset(px + 10 + cc * (w - 24) / 2,
                    y + 8 + r * (h - 18) / 5),
                width: 5,
                height: 6,
              ),
              _fill(const Color(0xFFFFC94D), alpha: 0.85));
        }
      }
    }
  }

  void _drawHills(Canvas c, double viewW, double y0, double y1, Color color,
      double parallax) {
    final path = Path()..moveTo(0, y1);
    final span = 120.0;
    for (var x = -span; x <= viewW + span; x += span / 4) {
      final phase =
          math.sin((x + world.distance * parallax * 24) / span * math.pi);
      final hh = 30 + phase.abs() * 34;
      path.lineTo(x, y1 - hh);
      path.lineTo(x + span / 8, y1 - hh * 0.5);
    }
    path.lineTo(viewW, y1);
    path.close();
    c.drawPath(path, _fill(color));
  }

  // --------------------------------------------------------- ground decor
  void _drawGroundStripes(Canvas c, double viewW, double y0, double viewH) {
    final stripeW = 64.0;
    final offset = (world.distance * 6) % (stripeW * 2);
    final paintA = _fill(theme.groundA);
    final paintB = _fill(theme.groundB);
    for (double x = -offset; x < viewW + stripeW; x += stripeW * 2) {
      c.drawRect(Rect.fromLTWH(x, y0, stripeW, viewH), paintB);
    }
    // subtle texture dots
    for (var i = 0; i < 20; i++) {
      final x = ((i * 173 + 37) % 1000) / 1000 * viewW;
      final y = y0 + 14 + ((i * 89) % 100) / 100 * 44;
      c.drawCircle(Offset(x, y), 3, paintA);
    }
  }

  void _drawRoadsideProps(Canvas c, double viewW, double y0, double viewH) {
    for (var i = 0; i < 8; i++) {
      final x = ((i * 231 + world.distance * 22.0) % (viewW + 220)) - 110;
      final y = y0 + 22 + ((i * 57) % 40);
      _drawTree(c, Offset(x, y));
    }
  }

  void _drawTree(Canvas c, Offset at) {
    const trunkColor = Color(0xFF8B5A2B);
    final leafA = const Color(0xFF2E7D32).withValues(alpha: 0.9);
    c.drawRect(
        Rect.fromCenter(center: at + const Offset(0, 8), width: 6, height: 20),
        _fill(trunkColor));
    c.drawCircle(at, 13, _fill(leafA));
    c.drawCircle(at - const Offset(9, 8), 10, _fill(leafA));
    c.drawCircle(at + const Offset(10, -7), 11, _fill(leafA));
  }

  // ----------------------------------------------------------------- road
  void _drawLaneDashes(Canvas c, double viewW, double roadTop,
      double roadBottom, double roadH) {
    final lanes = 3; // separators between 4 lanes
    final dashW = 46.0;
    final gap = 64.0;
    final period = dashW + gap;
    final scroll = (world.distance * 8) % period;
    for (var l = 1; l <= lanes; l++) {
      final y = roadTop + roadH * l / (lanes + 1);
      for (double x = -scroll; x < viewW + period; x += period) {
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y - 2.5, dashW, 5), const Radius.circular(3)),
            _fill(theme.laneDash, alpha: 0.85));
      }
    }
  }

  void _drawRoadEdges(Canvas c, double roadTop, double roadBottom, double viewW) {
    // glowing edge = kid-friendly guidance
    final glowPaint = Paint()
      ..color = theme.roadEdge.withValues(alpha: 0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    c.drawRect(Rect.fromLTWH(0, roadTop - 2, viewW, 6), _stroke(theme.roadEdge, 4));
    c.drawRect(Rect.fromLTWH(0, roadBottom - 4, viewW, 6), _stroke(theme.roadEdge, 4));
    c.drawRect(Rect.fromLTWH(0, roadTop - 3, viewW, 6), glowPaint);
    c.drawRect(Rect.fromLTWH(0, roadBottom - 3, viewW, 6), glowPaint);
  }

  void _drawFinish(Canvas c, double viewW, double roadTop, double roadBottom,
      double roadH, double playerX, double unitPx) {
    final remaining = world.level.targetDistance - world.distance;
    if (remaining < -40 || remaining > 14) return; // too far / passed
    final x = playerX + remaining * unitPx;
    if (x > viewW + 40 || x < -40) return;
    const sq = 14.0;
    for (double yy = roadTop, i = 0; yy < roadBottom - sq / 2; yy += sq, i++) {
      for (double xx = x, j = 0; xx < x + sq * 2.2; xx += sq, j++) {
        final even = ((i + j) % 2 == 0);
        c.drawRect(Rect.fromLTWH(xx, yy, sq, sq),
            _fill(even ? Colors.white : Colors.black54));
      }
    }
    // banner pole
    c.drawRect(Rect.fromLTWH(x - 3, roadTop - 26, 6, 28), _fill(Colors.black54));
    c.drawCircle(Offset(x, roadTop - 30), 7, _fill(const Color(0xFFFFD75E)));
  }

  // ------------------------------------------------------------- entities
  void _drawEntities(Canvas c, double playerX, double roadTop,
      double roadBottom, double roadH, double unitPx) {
    final entities = world.entities
        .where((e) => e.y < 15 && e.y > -2)
        .toList()
      ..sort((a, b) => b.y.compareTo(a.y)); // far first
    Offset toScreen(double lateral, double yAxis) => Offset(
          playerX + yAxis * unitPx,
          roadTop + roadH * (0.5 + (lateral / 2)),
        );

    for (final e in entities) {
      final pos = toScreen(e.x, e.y);
      switch (e.kind) {
        case EntityKind.trafficCar:
          _drawCar(
            c,
            pos,
            facingLeft: true,
            body: e.color ?? const Color(0xFF94A3B8),
            accent: Colors.white,
            scale: unitPx / 26 * 1.9,
            bob: math.sin(e.phase) * 2,
          );
        case EntityKind.coin:
          _drawCoin(c, pos, unitPx, e.phase);
        case EntityKind.star:
          _drawStar(c, pos, unitPx * 0.62, e.phase);
        case EntityKind.heart:
          _drawHeart(c, pos, unitPx * 0.6, e.phase);
        case EntityKind.boostPowerUp:
          _drawBoostPickup(c, pos, unitPx * 0.55, e.phase);
        case EntityKind.cone:
          _drawCone(c, pos, unitPx * 0.5);
        case EntityKind.oilSlick:
          _drawOil(c, pos, unitPx);
      }
    }
  }

  void _drawCoin(Canvas c, Offset p, double unitPx, double phase) {
    final wob = math.cos(phase); // -1..1
    final halfW = unitPx * 0.34 * wob.abs().clamp(0.2, 1);
    final r = Rect.fromCenter(center: p, width: halfW * 2, height: unitPx * 0.62);
    c.drawOval(r, _fill(const Color(0xFFFFC93C)));
    c.drawOval(
        Rect.fromCenter(
            center: p, width: halfW * 1.4, height: unitPx * 0.44),
        _fill(const Color(0xFFFFE9A3)));
    final sheen = Rect.fromCenter(
        center: p.translate(-halfW * 0.3, -unitPx * 0.1),
        width: halfW * 0.4,
        height: unitPx * 0.36);
    c.drawOval(sheen, _fill(const Color(0xFFFFFFFF), alpha: 0.7));
  }

  void _drawStar(Canvas c, Offset center, double radius, double phase) {
    final spin = phase * 0.8;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? radius : radius * 0.45;
      final ang = spin + i * math.pi / 5 - math.pi / 2;
      final pt = Offset(center.dx + rad * math.cos(ang),
          center.dy + rad * math.sin(ang));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    c.drawShadow(path, Colors.black26, 2, true);
    c.drawPath(path, _fill(const Color(0xFFFFD93B)));
    c.drawPath(path, _stroke(const Color(0xFFFFB300), 1.6));
    c.drawCircle(
        center.translate(-radius * 0.2, -radius * 0.25),
        radius * 0.14,
        _fill(const Color(0xFFFFFFFF), alpha: 0.85));
  }

  void _drawHeart(Canvas c, Offset center, double radius, double phase) {
    final beat = 1 + 0.1 * math.sin(phase * 2);
    final r = radius * beat;
    final path = Path()
      ..moveTo(center.dx, center.dy + r * 0.85)
      ..cubicTo(center.dx - r * 1.4, center.dy - r * 0.2, center.dx - r * 0.5,
          center.dy - r * 1.1, center.dx, center.dy - r * 0.35)
      ..cubicTo(center.dx + r * 0.5, center.dy - r * 1.1, center.dx + r * 1.4,
          center.dy - r * 0.2, center.dx, center.dy + r * 0.85);
    c.drawPath(path, _fill(const Color(0xFFFF5D7E)));
    c.drawPath(path, _stroke(const Color(0xFFD63D64), 1.4));
    c.drawCircle(center.translate(-r * 0.4, -r * 0.3), r * 0.15,
        _fill(Colors.white, alpha: 0.6));
  }

  void _drawBoostPickup(Canvas c, Offset center, double radius, double phase) {
    final glow = 0.5 + 0.5 * math.sin(phase * 3);
    c.drawCircle(center, radius * (1.25 + glow * 0.2),
        _fill(const Color(0xFF64E3F1), alpha: 0.3));
    final path = Path()
      ..moveTo(center.dx + radius * 0.25, center.dy - radius * 1.05)
      ..lineTo(center.dx - radius * 0.55, center.dy + radius * 0.1)
      ..lineTo(center.dx - radius * 0.02, center.dy + radius * 0.1)
      ..lineTo(center.dx - radius * 0.25, center.dy + radius * 1.05)
      ..lineTo(center.dx + radius * 0.55, center.dy - radius * 0.08)
      ..lineTo(center.dx + radius * 0.05, center.dy - radius * 0.08)
      ..close();
    c.drawPath(path, _fill(const Color(0xFFFFF176)));
    c.drawPath(path, _stroke(const Color(0xFFF9A825), 1.4));
  }

  void _drawCone(Canvas c, Offset center, double radius) {
    c.drawOval(
        Rect.fromCenter(
            center: center.translate(0, radius * 0.9),
            width: radius * 1.9,
            height: radius * 0.55),
        _fill(const Color(0x3E000000)));
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 1.35)
      ..lineTo(center.dx + radius * 0.85, center.dy + radius * 0.75)
      ..lineTo(center.dx - radius * 0.85, center.dy + radius * 0.75)
      ..close();
    c.drawPath(path, _fill(const Color(0xFFFF7043)));
    c.drawRect(
        Rect.fromLTWH(center.dx - radius * 0.45, center.dy - radius * 0.1,
            radius * 0.9, radius * 0.3),
        _fill(const Color(0xFFFFFFFF)));
  }

  void _drawOil(Canvas c, Offset center, double unitPx) {
    final r = Rect.fromCenter(
        center: center, width: unitPx * 1.9, height: unitPx * 0.9);
    c.drawOval(r, _fill(const Color(0xFF2A3843), alpha: 0.75));
    c.drawOval(
        Rect.fromCenter(
            center: center.translate(-unitPx * 0.3, -unitPx * 0.06),
            width: unitPx * 0.85,
            height: unitPx * 0.34),
        _fill(const Color(0xFF5C748A), alpha: 0.5));
  }

  // ----------------------------------------------------------------- cars
  void _drawCar(
    Canvas c,
    Offset at, {
    required bool facingLeft,
    required Color body,
    required Color accent,
    required double scale,
    double bob = 0,
    double tilt = 0,
    bool boostFlames = false,
    bool isPlayer = false,
  }) {
    final center = at.translate(0, bob);
    // facing: left = traffic (toward player), right = player direction.
    c.save();
    c.translate(center.dx, center.dy);
    if (facingLeft) c.rotate(math.pi);
    if (tilt != 0) c.rotate(tilt);
    final scaleF = scale;
    final L = 54 * scaleF; // length along +x (facing direction)
    final W = 30 * scaleF;

    // shadow
    c.drawOval(
        Rect.fromCenter(
            center: Offset(-2 * scaleF, W * 0.42),
            width: L * 1.02,
            height: W * 0.56),
        _fill(const Color(0x42000000)));

    if (boostFlames) {
      final flick = 6 + math.sin(_rngseed() * 40) * 3;
      final flame = Path()
        ..moveTo(-L * 0.56, -W * 0.16)
        ..relativeLineTo(-flick * scaleF, 0)
        ..relativeLineTo(flick * 0.5 * scaleF, W * 0.09)
        ..relativeLineTo(-flick * 0.6 * scaleF, W * 0.07)
        ..close();
      c.drawPath(flame, _fill(const Color(0xFFFFB300), alpha: 0.9));
      c.drawPath(flame, _fill(const Color(0xFFFF7043), alpha: 0.85));
    }

    // body
    final bodyRect = Rect.fromLTWH(-L / 2, -W / 2, L, W);
    c.drawRRect(
        RRect.fromRectAndRadius(bodyRect, Radius.circular(9 * scaleF)),
        Paint()..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [body.withValues(alpha: 0.90), body, landShade(body)],
        ).createShader(bodyRect));
    if (isPlayer) {
      // little racing stripe (accent color)
      c.drawRect(
          Rect.fromLTWH(-L / 2 + 4 * scaleF, -W * 0.10, L - 8 * scaleF,
              W * 0.14),
          _fill(accent, alpha: 0.85));
    }
    // spoiler (back edge)
    c.drawRect(
        Rect.fromLTWH(-L / 2 - 5 * scaleF, -W * 0.42, 6 * scaleF, W * 0.84),
        _fill(darken(body, 0.35)));
    // cockpit glass
    final glass = RRect.fromRectAndRadius(
        Rect.fromLTWH(-L * 0.05, -W * 0.30, L * 0.30, W * 0.60),
        Radius.circular(5 * scaleF));
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFFE3F5FF), const Color(0xFF9FD0EA)],
      ).createShader(Rect.fromLTWH(-L * 0.05, -W * 0.30, L * 0.30, W * 0.60));
    c.drawRRect(glass, glassPaint);
    // wheels
    final wheelH = 7 * scaleF;
    for (final wx in [-L * 0.32, L * 0.30]) {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(wx, W * 0.42),
              width: 14 * scaleF,
              height: wheelH),
          _fill(const Color(0xFF22252B)));
    }
    // headlight
    c.drawCircle(
        Offset(L * 0.47, -W * 0.18),
        2.6 * scaleF,
        _fill(const Color(0xFFFFF59D), alpha: 0.95));
    // taillights
    c.drawCircle(Offset(-L * 0.49, -W * 0.2), 2.2 * scaleF,
        _fill(const Color(0xFFFF5252), alpha: 0.9));
    c.drawCircle(Offset(-L * 0.49, W * 0.2), 2.2 * scaleF,
        _fill(const Color(0xFFFF5252), alpha: 0.9));
    c.restore();
  }

  double _rngseed() => world.elapsedSeconds * 8;

  void _drawPlayerCar(Canvas c, double playerX, double roadTop,
      double roadBottom, double roadH) {
    final lateralY =
        roadTop + roadH * (0.5 + world.lateral / 2).clamp(0.06, 0.94);
    final tilt = (world.targetLateral - world.lateral) * 0.25;
    final blink = world.invulnSeconds > 0 && (math.sin(tick * 22) < 0);
    final unitPx = (roadBottom - roadTop) / 20;
    if (!blink) {
      _drawCar(
        c,
        Offset(playerX, lateralY),
        facingLeft: false,
        body: world.car.bodyColor,
        accent: world.car.accentColor,
        scale: unitPx / 26 * 2.1,
        tilt: tilt,
        boostFlames: world.boosting,
        isPlayer: true,
      );
    }
  }

  // --------------------------------------------------------------- particles
  void _drawParticles(Canvas c, double playerX, double roadTop,
      double roadBottom, double roadH, double unitPx) {
    for (final p in world.particles) {
      final alpha = (p.life * 2).clamp(0.0, 1.0);
      final pos = Offset(
          playerX + p.y * unitPx, roadTop + roadH * (0.5 + (p.x) / 2));
      c.drawCircle(pos, unitPx * 0.14 * (0.5 + alpha * 0.5),
          _fill(p.color, alpha: alpha * 0.9));
    }
  }

  // -------------------------------------------------------------- overlays
  void _drawRain(Canvas c, double viewW, double viewH) {
    final paint = _fill(const Color(0xFFB7D9E8), alpha: 0.35);
    final paintThick = _fill(const Color(0xFFDFF1FA), alpha: 0.55);
    for (var i = 0; i < 44; i++) {
      final seedx = ((i * 137) % 100) / 100 * viewW;
      final speed = 340 + (i % 5) * 90;
      final y = ((tick * speed + i * 97) % (viewH + 120)) - 60;
      final x = seedx + ((y / viewH) * 44);
      final thick = i % 4 == 0;
      c.drawLine(
          Offset(x, y),
          Offset(x - 12, y + (thick ? 30 : 22)),
          thick ? paintThick : paint);
    }
  }

  void _drawEmbers(Canvas c, double viewW, double roadTop, double roadBottom) {
    final paint = _fill(const Color(0xFFFF7043), alpha: 0.5);
    final paintHot = _fill(const Color(0xFFFFB300), alpha: 0.6);
    for (var i = 0; i < 18; i++) {
      final x = ((i * 211) % 100) / 100 * viewW;
      final riseSpeed = 130 + (i % 4) * 47;
      final y = roadBottom - ((tick * riseSpeed + i * 61) % (roadBottom - roadTop + 90));
      final flick = 0.5 + 0.5 * math.sin(tick * 6 + i);
      c.drawCircle(Offset(x + math.sin(tick + i) * 9, y), 2 + flick * 1.4,
          i.isEven ? paint : paintHot);
    }
  }

  void _drawSpeedLines(Canvas c, double viewW, double roadTop, double roadBottom) {
    final paint = _fill(Colors.white, alpha: 0.10);
    for (var i = 0; i < 10; i++) {
      final y = roadTop + ((i * 173 + 31) % 100) / 100 * (roadBottom - roadTop);
      final x0 = ((tick * 900 + i * 269) % (viewW + 300)) - 150;
      c.drawRect(Rect.fromLTWH(viewW - x0, y, 120, 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RacePainter oldDelegate) => true;
}

// ------------------------------------------------------------ color helpers
Color darken(Color color, [double amount = .3]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final darker = hsl.withLightness((hsl.lightness * (1 - amount)).clamp(0, 1));
  return darker.toColor();
}

Color landShade(Color color) => darken(color, .22);
