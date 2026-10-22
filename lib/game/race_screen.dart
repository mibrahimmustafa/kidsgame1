import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import 'audio.dart';
import 'models.dart';
import 'painter.dart';
import 'theme.dart';
import 'world.dart';

/// The main racing screen. Owns the game loop (Ticker), touch input,
/// HUD, pause overlay, and hands the final [RunResult] to the
/// result screen when the race ends.
class RaceScreen extends StatefulWidget {
  const RaceScreen({
    super.key,
    required this.level,
    required this.car,
  });

  final LevelSpec level;
  final CarSpec car;

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final GameWorld _world;
  late final TrackTheme _theme;
  late final Ticker _ticker;
  Duration? _lastElapsed;
  double _tickElapsed = 0;
  bool _resultPushed = false;
  bool _paused = false;
  double _nitroFill = 0.55;
  int _prevHearts = 3;
  bool _heartFlash = false;

  // Nitro glow animation
  late final AnimationController _nitroGlowCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _theme = TrackTheme.themeFor(widget.level.theme);
    _world = GameWorld(level: widget.level, car: widget.car);
    _prevHearts = _world.hearts;
    _ticker = createTicker(_onTick)..start();
    AudioHub.instance.playMusic('race_music');
  }

  @override
  void dispose() {
    _ticker.stop();
    _nitroGlowCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  // ------------------------------------------------------------- game loop
  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == null
        ? 0.0
        : ((elapsed - _lastElapsed!).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    final step = dt.toDouble();

    if (!_paused) {
      _tickElapsed += step;
      _world.update(step);
      _drainEvents();

      // Heart-loss flash
      if (_world.hearts < _prevHearts) {
        _heartFlash = true;
        Future.delayed(const Duration(milliseconds: 400),
            () { if (mounted) setState(() => _heartFlash = false); });
      }
      _prevHearts = _world.hearts;

      if (!_resultPushed && !_world.running) {
        _resultPushed = true;
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(
            '/result',
            arguments: _world.buildResult(),
          );
        });
      }
      _nitroFill = _world.nitro / 100;
    }
    setState(() {});
  }

  void _drainEvents() {
    if (_world.events.isEmpty) return;
    final hub = AudioHub.instance;
    for (final e in _world.events) {
      if (e == GameEvent.coin) {
        hub.play(Sfx.coin, volume: 0.5);
      } else if (e == GameEvent.star) {
        hub.play(Sfx.star);
      } else if (e == GameEvent.heart) {
        hub.play(Sfx.star, volume: 0.8);
      } else if (e == GameEvent.boostUp) {
        hub.play(Sfx.boost, volume: 0.6);
      } else if (e == GameEvent.boostStart) {
        hub.play(Sfx.boost, volume: 0.85);
      } else if (e == GameEvent.boostEnd) {
        hub.play(Sfx.click, volume: 0.4);
      } else if (e == GameEvent.bounce) {
        hub.play(Sfx.bounce);
        HapticFeedback.selectionClick();
      } else if (e == GameEvent.splash) {
        hub.play(Sfx.splash);
      } else if (e == GameEvent.boom) {
        hub.play(Sfx.oops);
        HapticFeedback.mediumImpact();
      } else if (e == GameEvent.win) {
        hub.play(Sfx.win);
        HapticFeedback.mediumImpact();
      } else if (e == GameEvent.honk) {
        hub.play(Sfx.honk, volume: 0.5);
      } else if (e == GameEvent.oops) {
        hub.play(Sfx.oops);
        HapticFeedback.heavyImpact();
      }
    }
    _world.events.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      setState(() => _paused = true);
    }
  }

  // ---------------------------------------------------------------- input
  void _onDrag(DragUpdateDetails d) {
    if (_paused) return;
    final size = MediaQuery.of(context).size;
    final roadBand = size.height * 0.70;
    final dy = d.delta.dy;
    _world.setSteerTarget(_world.targetLateral + dy / roadBand * 2.4);
  }

  void _togglePause() {
    AudioHub.instance.play(Sfx.click);
    setState(() => _paused = !_paused);
  }

  void _goHome() {
    AudioHub.instance.play(Sfx.click);
    AudioHub.instance.playMusic('menu_music');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // --------------------------------------------------------------- visuals
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _theme.skyTop,
      body: PopScope(
        canPop: false,
        child: GestureDetector(
          onPanUpdate: _onDrag,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                isComplex: true,
                willChange: true,
                painter: RacePainter(_world, _theme, _tickElapsed),
              ),
              _buildHud(size),
              _buildBoostButton(size),
              if (_paused) _buildPauseOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud(Size size) {
    final progress = _world.progress;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              _GlassChip(
                icon: Icons.pause_rounded,
                onTap: _togglePause,
              ),
              const SizedBox(width: 10),
              // Hearts — flash red on loss
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _heartFlash
                      ? Colors.red.withValues(alpha: 0.7)
                      : Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 5),
                    Text('${_world.hearts}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _GlassChip(
                  icon: Icons.star_rounded,
                  iconColor: AppTheme.coinGold,
                  label: '${_world.starsCollected}'),
              const SizedBox(width: 10),
              _GlassChip(
                  icon: Icons.monetization_on_rounded,
                  iconColor: AppTheme.coinGold,
                  label: '${_world.coinsCollected}'),
              const SizedBox(width: 10),
              _GlassChip(
                icon: Icons.flag_rounded,
                iconColor: AppTheme.coinGold,
                label: widget.level.index >= 0
                    ? 'LEVEL ${widget.level.index + 1}: ${widget.level.name.toUpperCase()}'
                    : 'FREE DRIVE',
              ),
              const Spacer(),
              _NitroBadge(fillFraction: _nitroFill),
            ],
          ),
          const SizedBox(height: 8),
          // Gradient progress bar with moving flag icon
          LayoutBuilder(
            builder: (context, constraints) {
              const barH = 10.0;
              final total = constraints.maxWidth;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(barH)),
                    child: Container(
                      height: barH,
                      color: Colors.white24,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(barH)),
                      child: Container(
                        height: barH,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFD93D), Color(0xFF6BCB77)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Moving flag icon
                  Positioned(
                    left: (progress.clamp(0.0, 0.95) * total - 10)
                        .clamp(0, total - 20),
                    child: const Icon(Icons.flag_rounded,
                        size: 18, color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoostButton(Size size) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: GestureDetector(
          onPanDown: (_) {
            if (_paused) return;
            _world.toggleBoost(true);
          },
          onPanEnd: (_) => _world.toggleBoost(false),
          onTapDown: (_) => _world.toggleBoost(true),
          onTapUp: (_) => _world.toggleBoost(false),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Nitro glow when full
                if (_nitroFill >= 0.95)
                  AnimatedBuilder(
                    animation: _nitroGlowCtrl,
                    builder: (_, __) => Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent
                                .withValues(alpha: 0.4 + _nitroGlowCtrl.value * 0.4),
                            blurRadius: 16 + _nitroGlowCtrl.value * 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                CircularProgressIndicator(
                  value: _nitroFill == 0 ? null : _nitroFill.clamp(0, 1),
                  strokeWidth: 6,
                  color: Colors.cyanAccent,
                  backgroundColor: Colors.white24,
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _world.boosting
                        ? AppTheme.boostGradient
                        : AppTheme.nitroGradient,
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF202736),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 24),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '⏸ PAUSED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.level.index >= 0
                      ? 'LEVEL ${widget.level.index + 1}: ${widget.level.name.toUpperCase()}'
                      : 'FREE DRIVE PRACTICE',
                  style: const TextStyle(
                    color: AppTheme.coinGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Home Button
                    PressableButton(
                      onPressed: _goHome,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.niceBlue.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.home_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'HOME',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Continue Button
                    PressableButton(
                      onPressed: _togglePause,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.niceGreen.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'CONTINUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Glass HUD chip ───────────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, this.label, this.onTap, this.iconColor});
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor ?? Colors.white),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(label!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Nitro badge ──────────────────────────────────────────────────────────────

class _NitroBadge extends StatelessWidget {
  const _NitroBadge({required this.fillFraction});
  final double fillFraction;

  @override
  Widget build(BuildContext context) {
    const width = 74.0;
    return Container(
      width: width,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.cyanAccent, size: 18),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(color: Colors.white24),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fillFraction.clamp(0, 1),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.cyanAccent, Color(0xFF26C6DA)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
