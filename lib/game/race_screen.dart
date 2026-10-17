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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GameWorld _world;
  late final TrackTheme _theme;
  late final Ticker _ticker;
  Duration? _lastElapsed;
  double _tickElapsed = 0;
  bool _resultPushed = false;
  bool _paused = false;
  double _nitroFill = 0.55;

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
    _ticker = createTicker(_onTick)..start();
    AudioHub.instance.playMusic('race_music');
  }

  @override
  void dispose() {
    _ticker.stop();
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
    setState(() {}); // repaint the scene every tick
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
    final roadBand = size.height * 0.70; // matches painter's road band
    final dy = d.delta.dy;
    // up-drag (dy<0) steers toward -1 (top lane). Invert for natural feel:
    _world.setSteerTarget(_world.targetLateral + dy / roadBand * 2.4);
  }

  void _togglePause() => setState(() => _paused = !_paused);

  // --------------------------------------------------------------- visuals
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _theme.skyTop,
      body: PopScope(
        canPop: false, // in-race: let the pause overlay handle it
        child: GestureDetector(
          onPanUpdate: _onDrag,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // the scene itself
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
              _IconChip(
                icon: Icons.pause_rounded,
                onTap: _togglePause,
              ),
              const SizedBox(width: 10),
              // stars guideline
              _IconChip(icon: Icons.favorite_rounded, label: '${_world.hearts}'),
              const SizedBox(width: 10),
              _IconChip(
                  icon: Icons.star_rounded, label: '${_world.starsCollected}'),
              const SizedBox(width: 10),
              _IconChip(
                  icon: Icons.monetization_on_rounded,
                  label: '${_world.coinsCollected}'),
              const Spacer(),
              // nitro HUD
              _NitroBadge(fillFraction: _nitroFill),
            ],
          ),
          const SizedBox(height: 8),
          // progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              const barH = 10.0;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.all(Radius.circular(barH)),
                    child: Container(
                      height: barH,
                      color: Colors.white24,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor:
                        (progress).clamp(0.0, 1.0).toDouble(),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(barH)),
                      child: Container(height: barH, color: Colors.amber),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Transform.translate(
                      offset: Offset(4, -4),
                      child: Icon(
                        Icons.flag_rounded,
                        size: 22,
                        color: Colors.black38,
                      ),
                    ),
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
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.niceGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.fromLTRB(34, 14, 34, 14),
                  textStyle: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
                onPressed: _togglePause,
                label: const Text('CONTINUE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- small HUD cavviets
class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, this.label, this.onTap});
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
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

class _NitroBadge extends StatelessWidget {
  const _NitroBadge({required this.fillFraction});
  final double fillFraction;

  @override
  Widget build(BuildContext context) {
    final width = 74.0;
    return Container(
      width: width,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
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
                    child: Container(color: Colors.cyanAccent),
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
