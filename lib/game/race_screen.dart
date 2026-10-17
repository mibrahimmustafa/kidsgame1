import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import 'audio.dart';
import 'cockpit.dart';
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
    this.bodyStyle = BodyStyle.classic,
    this.mods = const <String>[],
    this.cockpit = true,
  });

  final LevelSpec level;
  final CarSpec car;
  final BodyStyle bodyStyle;
  final List<String> mods;
  final bool cockpit;

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

  // cockpit driving input
  double _dragSteer = 0;
  bool _dragging = false;
  final Set<LogicalKeyboardKey> _keysDown = <LogicalKeyboardKey>{};
  final FocusNode _focus = FocusNode();

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
    AudioHub.instance.engineStop();
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
      _applySteering(step);
      _world.update(step);
      _drainEvents();
      AudioHub.instance.engine(_world.running ? _world.engineLoad : 0.0);

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
    } else {
      AudioHub.instance.engineStop();
    }
    setState(() {}); // repaint the scene every tick
  }

  /// Analog wheel: keyboard steer wins while held, otherwise the last
  /// drag position eases back to center like a real steering wheel.
  void _applySteering(double dt) {
    if (widget.cockpit) {
      final key = _keysDown.contains(LogicalKeyboardKey.arrowRight) ||
              _keysDown.contains(LogicalKeyboardKey.keyD)
          ? 1.0
          : _keysDown.contains(LogicalKeyboardKey.arrowLeft) ||
                  _keysDown.contains(LogicalKeyboardKey.keyA)
              ? -1.0
              : 0.0;
      if (key != 0.0) {
        _dragSteer = key;
        _dragging = true;
      } else if (!_dragging) {
        _dragSteer *= (1 - 4.5 * dt).clamp(0.0, 1.0);
        if (_dragSteer.abs() < 0.02) _dragSteer = 0;
      }
      _world.setSteer(_dragSteer.clamp(-1.0, 1.0));
      _world.setBrake(
          _keysDown.contains(LogicalKeyboardKey.arrowDown) ||
              _keysDown.contains(LogicalKeyboardKey.keyS) ||
              _brakeHeld);
    } else {
      // sky view keeps its gentle assist steering
      _world.setSteer(0);
      _world.setBrake(false);
    }
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
      } else if (e == GameEvent.screech) {
        hub.play(Sfx.screech, volume: 0.55);
        HapticFeedback.selectionClick();
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
  bool _brakeHeld = false;

  /// Human interface device: horizontal shoulder-drag on the cockpit
  /// screen (like pulling the wheel), vertical drag still works for the
  /// sky view. Also accepts keyboard arrows from the desktop.
  void _onDrag(DragUpdateDetails d) {
    if (_paused || _world.running == false) return;
    if (widget.cockpit) {
      final size = MediaQuery.of(context).size;
      _dragging = true;
      _dragSteer =
          (_dragSteer + d.delta.dx / (size.width * 0.34)).clamp(-1.0, 1.0);
    } else {
      final size = MediaQuery.of(context).size;
      final roadBand = size.height * 0.70; // matches painter's road band
      final dy = d.delta.dy;
      // up-drag (dy<0) steers toward -1 (top lane). Invert for natural feel:
      _world.setSteerTarget(_world.targetLateral + dy / roadBand * 2.4);
    }
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
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: GestureDetector(
            onPanUpdate: _onDrag,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // the scene itself — cockpit camera is the star
                CustomPaint(
                  isComplex: true,
                  willChange: true,
                  painter: widget.cockpit
                      ? CockpitPainter(
                          _world,
                          _theme,
                          _tickElapsed,
                          mods: widget.mods.toSet(),
                        )
                      : RacePainter(
                          _world,
                          _theme,
                          _tickElapsed,
                          bodyStyle: widget.bodyStyle,
                          mods: widget.mods.toSet(),
                        ),
                ),
                _buildHud(size),
                if (widget.cockpit) _buildBrakePedal(size),
                if (widget.cockpit) _buildHornButton(size),
                if (widget.cockpit) _buildSteerHint(size),
                _buildBoostButton(size),
                if (_paused) _buildPauseOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final k = event.logicalKey;
    if ([
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.keyS,
    ].contains(k)) {
      setState(() {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          _keysDown.add(k);
          if (k == LogicalKeyboardKey.arrowUp) _world.toggleBoost(true);
          if (k == LogicalKeyboardKey.space && !_paused) _world.doHonk();
        } else {
          _keysDown.remove(k);
          if (k == LogicalKeyboardKey.arrowUp) _world.toggleBoost(false);
        }
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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
                    widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                    child: Container(
                      height: barH,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC531), Color(0xFFFF7043)],
                        ),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(barH)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC531).withValues(alpha: .6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
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

  /// Brake pedal — bottom left, hold to scrub speed. Kid-friendly and
  /// forgiving: releasing it snaps back to full power.
  Widget _buildBrakePedal(Size size) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: GestureDetector(
          onPanDown: (_) => _brakeHeld = true,
          onPanEnd: (_) => _brakeHeld = false,
          onTapDown: (_) => _brakeHeld = true,
          onTapUp: (_) => _brakeHeld = false,
          onTapCancel: () => _brakeHeld = false,
          child: AnimatedScale(
            scale: _brakeHeld ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brakeHeld
                    ? const Color(0xFFEF5350)
                    : Colors.black45,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(
                Icons.traffic_outlined,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Transparent tap zone over the wheel hub — blowing the HORN startles
  /// nearby traffic into swerving away.
  Widget _buildHornButton(Size size) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTapDown: (_) {
          _world.hornHeld = true;
          _world.doHonk();
        },
        onTapUp: (_) => _world.hornHeld = false,
        onTapCancel: () => _world.hornHeld = false,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size.width * 0.11,
          height: size.height * 0.14,
          color: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildSteerHint(Size size) {
    if (_tickElapsed < 3.2) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(
              top: size.height * 0.14,
              left: 12,
              right: 12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'DRAG LEFT / RIGHT TO STEER • SPACE = HORN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPauseOverlay() {    return Positioned.fill(
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
