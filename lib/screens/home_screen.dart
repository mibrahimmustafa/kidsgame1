import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';
import '../core/app_theme.dart';
import 'settings_dialog.dart';

/// Title screen: playful sky, bobbing car preview, and the three
/// "big kid buttons": Races, Garage, Free Drive.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.save, super.key});
  final GameSave save;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Entry animation
  late final AnimationController _enterCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))
    ..forward();

  @override
  void initState() {
    super.initState();
    AudioHub.instance.playMusic('menu_music');
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  void _startRace(LevelSpec level) {
    AudioHub.instance.play(Sfx.click);
    Navigator.of(context).pushNamed('/race', arguments: {
      'level': level,
      'car': CarSpec.byId(widget.save.selectedCarId),
    });
  }

  @override
  Widget build(BuildContext context) {
    final save = widget.save;
    final car = CarSpec.byId(save.selectedCarId);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated drifting clouds
              const _DriftingClouds(),

              // Animated sun
              Positioned(
                top: 10,
                right: 24,
                child: _PulsingSun(),
              ),

              // Currency HUD Capsules (Top-Left)
              Positioned(
                left: 16,
                top: 12,
                child: _StatsPill(save: save),
              ),

              // Settings gear (spinning - Top-Right)
              Positioned(
                right: 14,
                top: 12,
                child: _SpinningSettingsButton(save: save),
              ),

              // Main Arcade Console Dashboard (All on screen, no vertical stacking!)
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title lockup: SPEEDY on top, STARS RACING directly below
                          ShimmerSweep(
                            duration: const Duration(seconds: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AnimatedTitle(
                                  text: 'SPEEDY',
                                  fontSize: 58,
                                  color: AppTheme.inkDark,
                                  letterSpacing: 3.5,
                                  delay: 0,
                                  ctrl: _enterCtrl,
                                ),
                                const SizedBox(height: 3),
                                _AnimatedSubtitle(
                                  text: 'STARS RACING',
                                  fontSize: 24,
                                  color: AppTheme.nicePink,
                                  letterSpacing: 3.5,
                                  delay: 120,
                                  ctrl: _enterCtrl,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Interactive 3D Showroom Turntable Stage
                          _GlowingCarBadge(car: car),

                          const SizedBox(height: 16),

                          // Horizontal Action Console Dock (All 3 buttons side-by-side!)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Left: GARAGE Button
                              _StaggeredButton(
                                index: 1,
                                ctrl: _enterCtrl,
                                child: BigButton(
                                  color: AppTheme.niceBlue,
                                  icon: Icons.directions_car_rounded,
                                  label: 'GARAGE',
                                  subtitle: 'CARS & TUNING',
                                  width: 180,
                                  height: 58,
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/garage');
                                  },
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Center: RACES (Hero Big Play Button!)
                              _StaggeredButton(
                                index: 0,
                                ctrl: _enterCtrl,
                                child: BigButton(
                                  color: AppTheme.niceGreen,
                                  icon: Icons.emoji_events_rounded,
                                  label: 'RACES',
                                  subtitle: 'PLAY CHAMPIONSHIP',
                                  isHero: true,
                                  width: 240,
                                  height: 68,
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/levels');
                                  },
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Right: FREE DRIVE Button
                              _StaggeredButton(
                                index: 2,
                                ctrl: _enterCtrl,
                                child: BigButton(
                                  color: AppTheme.niceOrange,
                                  icon: Icons.sports_esports_rounded,
                                  label: 'FREE DRIVE',
                                  subtitle: 'PRACTICE TRACK',
                                  width: 180,
                                  height: 58,
                                  onPressed: () =>
                                      _startRace(LevelSpec.freeDrive),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Drifting Clouds ─────────────────────────────────────────────────────────

class _DriftingClouds extends StatefulWidget {
  const _DriftingClouds();

  @override
  State<_DriftingClouds> createState() => _DriftingCloudsState();
}

class _DriftingCloudsState extends State<_DriftingClouds>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 30))
    ..repeat();

  static const _clouds = [
    (x0: -0.15, y: 0.04, size: 70.0, speed: 1.0),
    (x0: 0.60, y: 0.02, size: 90.0, speed: 0.7),
    (x0: 0.20, y: 0.12, size: 55.0, speed: 1.3),
    (x0: 0.80, y: 0.08, size: 65.0, speed: 0.9),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          children: _clouds.map((c) {
            final x = ((c.x0 + _ctrl.value * c.speed) % 1.3) * size.width;
            final y = c.y * size.height;
            return Positioned(
              left: x - c.size / 2,
              top: y,
              child: _cloudWidget(c.size),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _cloudWidget(double s) {
    return Container(
      width: s,
      height: s * 0.42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .80),
        borderRadius: BorderRadius.circular(s),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing Sun ─────────────────────────────────────────────────────────────

class _PulsingSun extends StatefulWidget {
  @override
  State<_PulsingSun> createState() => _PulsingSunState();
}

class _PulsingSunState extends State<_PulsingSun>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final glow = 6 + _ctrl.value * 12;
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.coinGold,
            boxShadow: [
              BoxShadow(
                  color: AppTheme.coinGold.withValues(alpha: 0.7),
                  blurRadius: glow,
                  spreadRadius: glow * 0.3),
            ],
          ),
        );
      },
    );
  }
}

// ─── Animated Title & Subtitle ───────────────────────────────────────────────

class _AnimatedTitle extends StatelessWidget {
  const _AnimatedTitle({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.delay,
    required this.ctrl,
    this.letterSpacing = 3.0,
  });

  final String text;
  final double fontSize;
  final Color color;
  final int delay;
  final AnimationController ctrl;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final Animation<double> fade = CurvedAnimation(
      parent: ctrl,
      curve: Interval(delay / 700, 1.0, curve: Curves.easeOutBack),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.4),
          end: Offset.zero,
        ).animate(fade),
        child: Text(
          text,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: fontSize,
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: letterSpacing,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.95),
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    offset: const Offset(0, 4),
                    blurRadius: 6,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 8),
                    blurRadius: 10,
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _AnimatedSubtitle extends StatelessWidget {
  const _AnimatedSubtitle({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.delay,
    required this.ctrl,
    this.letterSpacing = 3.5,
  });

  final String text;
  final double fontSize;
  final Color color;
  final int delay;
  final AnimationController ctrl;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final Animation<double> fade = CurvedAnimation(
      parent: ctrl,
      curve: Interval(delay / 700, 1.0, curve: Curves.easeOutBack),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(fade),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.star_rounded,
              color: AppTheme.coinGold,
              size: fontSize * 0.95,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: fontSize,
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: letterSpacing,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.95),
                        offset: const Offset(0, 2),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        offset: const Offset(0, 3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.star_rounded,
              color: AppTheme.coinGold,
              size: fontSize * 0.95,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glowing Car Badge / Interactive Showroom Stage ──────────────────────────

class _GlowingCarBadge extends StatefulWidget {
  const _GlowingCarBadge({required this.car});
  final CarSpec car;

  @override
  State<_GlowingCarBadge> createState() => _GlowingCarBadgeState();
}

class _GlowingCarBadgeState extends State<_GlowingCarBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 126.0;
    return GestureDetector(
      onTap: () {
        AudioHub.instance.play(Sfx.click);
        Navigator.of(context).pushNamed('/garage');
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final bob = math.sin(_ctrl.value * 2 * math.pi) * 3.5;
          final pulse = 0.5 + 0.5 * math.sin(_ctrl.value * 2 * math.pi);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating car with stage turntable shadow
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Turntable ground shadow
                  Positioned(
                    bottom: -8,
                    child: Container(
                      width: size * 1.5,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15 + pulse * 0.08),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: widget.car.bodyColor
                                .withValues(alpha: 0.32 + pulse * 0.18),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating car
                  Transform.translate(
                    offset: Offset(0, bob),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.45),
                            blurRadius: 10 + pulse * 6,
                          ),
                        ],
                      ),
                      child: CarBadge(car: widget.car, size: size),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Interactive car pill: "⚡ SPEEDY • TAP TO CHANGE ➔"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: widget.car.bodyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      widget.car.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.inkDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.swap_horiz_rounded,
                        size: 15, color: AppTheme.inkDark),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Staggered Button ────────────────────────────────────────────────────────

class _StaggeredButton extends StatelessWidget {
  const _StaggeredButton({
    required this.index,
    required this.ctrl,
    required this.child,
  });

  final int index;
  final AnimationController ctrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.15).clamp(0.0, 0.9);
    final anim = CurvedAnimation(
      parent: ctrl,
      curve: Interval(start, 1.0, curve: Curves.easeOutBack),
    );
    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(scale: anim, child: child),
    );
  }
}

// ─── Stats Pill ──────────────────────────────────────────────────────────────

class _StatsPill extends StatelessWidget {
  const _StatsPill({required this.save});
  final GameSave save;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Coins capsule
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.coinGold.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on_rounded,
                  color: AppTheme.coinGold, size: 22),
              const SizedBox(width: 6),
              Text(
                '${save.coins}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.inkDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Stars capsule
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.coinGold.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded,
                  color: AppTheme.coinGold, size: 22),
              const SizedBox(width: 6),
              Text(
                '${save.totalStars}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.inkDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Spinning Settings Button ─────────────────────────────────────────────────

class _SpinningSettingsButton extends StatefulWidget {
  const _SpinningSettingsButton({required this.save});
  final GameSave save;

  @override
  State<_SpinningSettingsButton> createState() =>
      _SpinningSettingsButtonState();
}

class _SpinningSettingsButtonState extends State<_SpinningSettingsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableButton(
      onPressed: () {
        AudioHub.instance.play(Sfx.click);
        showParentSettingsDialog(context, widget.save);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Transform.rotate(
            angle: _ctrl.value * 2 * math.pi,
            child: child,
          ),
          child: const Icon(Icons.settings_rounded, color: AppTheme.inkDark),
        ),
      ),
    );
  }
}

// ─── Public reusable widgets ──────────────────────────────────────────────────

class CarBadge extends StatelessWidget {
  const CarBadge({required this.car, this.size = 120, super.key});
  final CarSpec car;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.6,
      height: size * 0.85,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(24),
      ),
      child: CustomPaint(
        size: Size(size * 1.6, size * 0.85),
        painter: CarPreviewPainter(car),
      ),
    );
  }
}

class BigButton extends StatefulWidget {
  const BigButton({
    required this.label,
    required this.color,
    this.subtitle,
    this.icon,
    this.onPressed,
    this.isHero = false,
    this.width,
    this.height,
    super.key,
  });

  final String label;
  final String? subtitle;
  final Color color;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isHero;
  final double? width;
  final double? height;

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color;
    final depthColor = darken(baseColor, 0.40);
    final topHighlight = lighten(baseColor, 0.26);
    final midColor = lighten(baseColor, 0.06);

    final width = widget.width ?? (widget.isHero ? 240.0 : 180.0);
    final height = widget.height ?? (widget.isHero ? 68.0 : 58.0);
    const bevelDepth = 5.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        AudioHub.instance.play(Sfx.click);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        width: width,
        height: height + bevelDepth,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // 3D Bottom Bevel Extrusion
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: bevelDepth,
              child: Container(
                decoration: BoxDecoration(
                  color: depthColor,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: depthColor.withValues(alpha: widget.isHero ? 0.55 : 0.40),
                      blurRadius: widget.isHero ? 14 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),

            // Top Moving Face Layer (compresses down into bevel on tap)
            Positioned(
              left: 0,
              right: 0,
              top: _pressed ? bevelDepth * 0.75 : 0,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [topHighlight, midColor, baseColor],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.6,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(height / 2),
                  child: Stack(
                    children: [
                      // Upper glossy reflection sheen
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: height * 0.44,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.35),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Periodic shimmer sweep on hero button
                      if (widget.isHero)
                        Positioned.fill(
                          child: ShimmerSweep(
                            duration: const Duration(seconds: 3),
                            delay: const Duration(milliseconds: 400),
                            child: const SizedBox.expand(),
                          ),
                        ),

                      // Button Content: Icon Badge + Text Column + Chevron
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: widget.isHero ? 12 : 10),
                        child: Row(
                          children: [
                            // 3D Embossed Icon Badge
                            if (widget.icon != null) ...[
                              Container(
                                width: widget.isHero ? 42 : 34,
                                height: widget.isHero ? 42 : 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.24),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: depthColor.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: widget.isHero ? 24 : 19,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: widget.isHero ? 10 : 8),
                            ],

                            // Text Column (Title + Subtitle)
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.label,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: widget.isHero ? 21 : 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                        shadows: [
                                          Shadow(
                                            color: depthColor,
                                            offset: const Offset(0, 2),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (widget.subtitle != null) ...[
                                    const SizedBox(height: 1),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        widget.subtitle!,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.88),
                                          fontSize: widget.isHero ? 10 : 8.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Right Arrow / Chevron
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isHero
                                    ? Icons.play_arrow_rounded
                                    : Icons.arrow_forward_ios_rounded,
                                size: widget.isHero ? 16 : 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
