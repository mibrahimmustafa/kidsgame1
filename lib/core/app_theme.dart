import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/models.dart';

/// Bright, friendly, kid-tested visual language for the whole app.
class AppTheme {
  AppTheme._();

  // ── Palette ────────────────────────────────────────────────────────────────
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

  // ── Gradients ──────────────────────────────────────────────────────────────
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

  static const LinearGradient meadowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2EC4B6), Color(0xFF20BF6B)],
  );

  static const LinearGradient beachGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B4D8), Color(0xFF48CAE4), Color(0xFFFFB703)],
  );

  static const LinearGradient snowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4EA8DE), Color(0xFF90E0EF), Color(0xFFD0F4DE)],
  );

  static const LinearGradient desertGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF77F00), Color(0xFFFCBF49), Color(0xFFF4A261)],
  );

  static const LinearGradient nightCityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A0CA3), Color(0xFF7209B7), Color(0xFFF72585)],
  );

  static const LinearGradient forestRainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF134E5E), Color(0xFF2D6A4F), Color(0xFF52B788)],
  );

  static const LinearGradient volcanoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD00000), Color(0xFFDC2F02), Color(0xFFFFBA08)],
  );

  static const LinearGradient galaxyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10002B), Color(0xFF3C096C), Color(0xFF9D4EDD)],
  );

  static LinearGradient gradientFor(ThemeKind kind) => switch (kind) {
        ThemeKind.meadow => meadowGradient,
        ThemeKind.beach => beachGradient,
        ThemeKind.snow => snowGradient,
        ThemeKind.desert => desertGradient,
        ThemeKind.nightCity => nightCityGradient,
        ThemeKind.forestRain => forestRainGradient,
        ThemeKind.volcano => volcanoGradient,
        ThemeKind.galaxy => galaxyGradient,
      };

  static Color depthColorFor(ThemeKind kind) => switch (kind) {
        ThemeKind.meadow => const Color(0xFF0F7A43),
        ThemeKind.beach => const Color(0xFF0077B6),
        ThemeKind.snow => const Color(0xFF023E8A),
        ThemeKind.desert => const Color(0xFFB35400),
        ThemeKind.nightCity => const Color(0xFF240046),
        ThemeKind.forestRain => const Color(0xFF0B2B1B),
        ThemeKind.volcano => const Color(0xFF6A040F),
        ThemeKind.galaxy => const Color(0xFF0A0017),
      };

  static IconData iconFor(ThemeKind kind) => switch (kind) {
        ThemeKind.meadow => Icons.park_rounded,
        ThemeKind.beach => Icons.beach_access_rounded,
        ThemeKind.snow => Icons.ac_unit_rounded,
        ThemeKind.desert => Icons.wb_sunny_rounded,
        ThemeKind.nightCity => Icons.location_city_rounded,
        ThemeKind.forestRain => Icons.water_drop_rounded,
        ThemeKind.volcano => Icons.local_fire_department_rounded,
        ThemeKind.galaxy => Icons.auto_awesome_rounded,
      };

  static String tagFor(ThemeKind kind) => switch (kind) {
        ThemeKind.meadow => 'MEADOW',
        ThemeKind.beach => 'BEACH',
        ThemeKind.snow => 'SNOW',
        ThemeKind.desert => 'DESERT',
        ThemeKind.nightCity => 'NEON CITY',
        ThemeKind.forestRain => 'RAIN FOREST',
        ThemeKind.volcano => 'VOLCANO',
        ThemeKind.galaxy => 'GALAXY',
      };

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData light() {
    final base =
        ColorScheme.fromSeed(seedColor: niceOrange, brightness: Brightness.light);

    TextTheme merged;
    try {
      final fredoka = GoogleFonts.fredokaTextTheme().copyWith(
        headlineLarge: GoogleFonts.fredoka(
            fontSize: 44, fontWeight: FontWeight.w600, letterSpacing: 1.5),
        headlineMedium: GoogleFonts.fredoka(
            fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: 1.0),
        titleLarge: GoogleFonts.fredoka(
            fontSize: 22, fontWeight: FontWeight.w600),
      );

      final nunito = GoogleFonts.nunitoTextTheme();

      merged = nunito.copyWith(
        headlineLarge: fredoka.headlineLarge,
        headlineMedium: fredoka.headlineMedium,
        titleLarge: fredoka.titleLarge,
      );
    } catch (_) {
      merged = ThemeData.light().textTheme;
    }

    return ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: base.copyWith(primary: niceOrange, secondary: niceBlue),
      scaffoldBackgroundColor: skyLight,
      textTheme: merged,
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(22))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI Utilities
// ─────────────────────────────────────────────────────────────────────────────

/// Press-to-scale wrapper — shrinks to 0.93 on tap, springs back.
/// Drop-in replacement around any tappable widget.
class PressableButton extends StatefulWidget {
  const PressableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.scale = 0.93,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double scale;

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 100));
  late final Animation<double> _scaleAnim = Tween<double>(
    begin: 1.0,
    end: widget.scale,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) => _ctrl.forward();

  void _up(TapUpDetails _) {
    _ctrl.reverse();
    HapticFeedback.selectionClick();
    widget.onPressed?.call();
  }

  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Diagonal white shimmer sweep that plays on loop over any widget.
class ShimmerSweep extends StatefulWidget {
  const ShimmerSweep({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _ctrl.value;
            final start = t * 1.6 - 0.8;
            return LinearGradient(
              begin: Alignment(start - 0.4, -1),
              end: Alignment(start + 0.4, 1),
              colors: const [
                Colors.transparent,
                Color(0x33FFFFFF),
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Adds a colored outer glow (BoxShadow) around any widget.
class GlowBox extends StatelessWidget {
  const GlowBox({
    super.key,
    required this.child,
    required this.color,
    this.blurRadius = 18,
    this.spreadRadius = 2,
  });

  final Widget child;
  final Color color;
  final double blurRadius;
  final double spreadRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Shake-left-right feedback widget — call shake() to trigger.
class ShakeFeedback extends StatefulWidget {
  const ShakeFeedback({super.key, required this.child});
  final Widget child;

  @override
  State<ShakeFeedback> createState() => ShakeFeedbackState();
}

class ShakeFeedbackState extends State<ShakeFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));

  late final Animation<double> _shake = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  void shake() {
    HapticFeedback.mediumImpact();
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) =>
          Transform.translate(offset: Offset(_shake.value, 0), child: child),
      child: widget.child,
    );
  }
}

/// Confetti rain — colored squares fall from the top for ~1.8 s.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..forward();

  static final _rng = math.Random(42);

  static final _pieces = List.generate(40, (i) {
    return _ConfettiPiece(
      x: _rng.nextDouble(),
      startY: -0.05 - _rng.nextDouble() * 0.3,
      color: [
        const Color(0xFFFFC93C),
        const Color(0xFFF76A8B),
        const Color(0xFF53B175),
        const Color(0xFF5A9CF8),
        const Color(0xFFF98F3E),
        const Color(0xFFB983FF),
      ][i % 6],
      size: 6 + _rng.nextDouble() * 8,
      speed: 0.6 + _rng.nextDouble() * 0.4,
      angle: _rng.nextDouble() * 2 * math.pi,
      spin: (_rng.nextBool() ? 1 : -1) * (1 + _rng.nextDouble() * 3),
    );
  });

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ConfettiPainter(_pieces, _ctrl.value),
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.color,
    required this.size,
    required this.speed,
    required this.angle,
    required this.spin,
  });

  final double x, startY, size, speed, angle, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.pieces, this.t);
  final List<_ConfettiPiece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final y = p.startY + t * p.speed * 1.2;
      if (y > 1.05) continue;
      final cx = p.x * size.width;
      final cy = y * size.height;
      final angle = p.angle + t * p.spin;
      paint.color = p.color.withValues(alpha: (1 - t * 0.6).clamp(0, 1));
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Car preview painter (unchanged — car is sacred!)
// ─────────────────────────────────────────────────────────────────────────────

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
    canvas.drawRRect(
        cabin,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = inkPaint.color.withValues(alpha: .5));
    canvas.drawRect(spoiler, inkPaint);
    // decal
    canvas.drawCircle(
        Offset(cx + w * 0.30, cy - bodyH * 0.55),
        bodyH * 0.28,
        Paint()..color = car.accentColor..style = PaintingStyle.fill);
    // wheels
    final wheelR = bodyH * 0.42;
    for (final offset in [-w * 0.32, w * 0.30]) {
      canvas.drawCircle(Offset(cx + offset, cy + wheelR * 0.4), wheelR + 2,
          Paint()..color = AppTheme.inkDark);
      canvas.drawCircle(Offset(cx + offset, cy + wheelR * 0.4), wheelR * 0.55,
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

Color lighten(Color color, [double amount = .2]) {
  final hsl = HSLColor.fromColor(color);
  final lighter =
      hsl.withLightness((hsl.lightness + (1 - hsl.lightness) * amount).clamp(0, 1));
  return lighter.toColor();
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
