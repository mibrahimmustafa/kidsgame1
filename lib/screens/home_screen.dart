import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';
import '../core/app_theme.dart';
import 'settings_dialog.dart';

/// Title screen: dark cinematic garage-lobby look — starfield, neon
/// spotlight, a glossy car showpiece, and one big START ENGINE button.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.save, super.key});
  final GameSave save;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    AudioHub.instance.playMusic('menu_music');
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _startRace(LevelSpec level) {
    AudioHub.instance.play(Sfx.click);
    Navigator.of(context).pushNamed('/race', arguments: {
      'level': level,
      'car': CarSpec.byId(widget.save.selectedCarId),
      'body': widget.save.bodyId,
      'mods': widget.save.equippedMods,
      'cockpit': widget.save.cockpitView,
    });
  }

  @override
  Widget build(BuildContext context) {
    final save = widget.save;
    final car = CarSpec.byId(save.selectedCarId);
    final next =
        LevelSpec.levels[save.maxUnlockedLevel.clamp(0, LevelSpec.levels.length - 1)];
    final isNext = save.starsFor(next.index) == 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF090E1F), Color(0xFF101632), Color(0xFF170F33)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _HomeBackdrop()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---------------- title
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFFFFF), Color(0xFFB8CFFF)],
                        ).createShader(r),
                        child: const Text(
                          'SPEEDY',
                          style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: Colors.white),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFF7BD5)],
                        ).createShader(r),
                        child: const Text(
                          'STARS RACING',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 7,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // ---------------- car showcase
                      GestureDetector(
                        onTap: () {
                          AudioHub.instance.play(Sfx.click);
                          Navigator.of(context)
                              .pushNamed('/garage', arguments: 'mods');
                        },
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _float,
                              builder: (context, child) => CustomPaint(
                                size: const Size(280, 150),
                                isComplex: true,
                                painter: CarPreviewPainter(
                                  car,
                                  bounce: _float.value,
                                  bodyStyle: BodyStyle.byId(save.bodyId),
                                  mods: save.equippedMods,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // mod chips under the car
                            _ModChipRow(mods: save.equippedMods),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .07),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: .22)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.handyman_rounded,
                                      size: 14, color: AppTheme.niceOrange),
                                  SizedBox(width: 6),
                                  Text(
                                    'TAP TO CUSTOMIZE',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.4,
                                        color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ---------------- primary CTA
                      GestureDetector(
                        onTap: isNext
                            ? () => _startRace(next)
                            : () {
                                AudioHub.instance.play(Sfx.click);
                                Navigator.of(context).pushNamed('/levels');
                              },
                        child: Container(
                          width: 330,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.gradientFor(next.theme),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      AppTheme.niceOrange.withValues(alpha: .35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: Icon(
                                  isNext
                                      ? Icons.play_arrow_rounded
                                      : Icons.emoji_events_rounded,
                                  size: 28,
                                  color: AppTheme.niceGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        (isNext ? 'NEXT RACE' : 'RACE ALREADY WON')
                                            .toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.6,
                                            color: Colors.white
                                                .withValues(alpha: .75))),
                                    Text('SPEEDY',
                                        style:
                                            TextStyle(fontSize: 0)),
                                    Text(next.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Colors.white, size: 26),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ---------------- stats
                      _StatsRow(save: save),
                      const SizedBox(height: 14),
                      // ---------------- secondary actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GhostButton(
                            icon: Icons.emoji_events_rounded,
                            label: 'RACES',
                            onTap: () {
                              AudioHub.instance.play(Sfx.click);
                              Navigator.of(context).pushNamed('/levels');
                            },
                          ),
                          const SizedBox(width: 12),
                          _GhostButton(
                            icon: Icons.directions_car_rounded,
                            label: 'GARAGE',
                            onTap: () {
                              AudioHub.instance.play(Sfx.click);
                              Navigator.of(context).pushNamed('/garage');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _GhostButton(
                        icon: Icons.sports_esports_rounded,
                        label: 'FREE DRIVE',
                        accent: AppTheme.niceOrange,
                        onTap: () => _startRace(LevelSpec.freeDrive),
                      ),
                    ],
                  ),
                ),
              ),
              // settings gear, glassy
              Positioned(
                right: 14,
                bottom: 14,
                child: GestureDetector(
                  onTap: () {
                    AudioHub.instance.play(Sfx.click);
                    showParentSettingsDialog(context, save);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .18)),
                    ),
                    child: const Icon(Icons.settings_rounded,
                        color: Colors.white70, size: 24),
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

/// Twinkling starfield + road-to-horizon glow backdrop.
class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HomeBackdropPainter(),
      size: MediaQuery.of(context).size,
    );
  }
}

class _HomeBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // stars
    for (var i = 0; i < 60; i++) {
      final rand = math.Random(50 + i);
      final x = rand.nextDouble() * w;
      final y = rand.nextDouble() * h * .7;
      canvas.drawCircle(
          Offset(x, y),
          .9 + (i % 3) * .6,
          Paint()..color = Colors.white.withValues(alpha: .14 + (i % 5) * .04));
    }
    // neon orbs
    _orb(canvas, Offset(w * .85, h * .16), w * .30, const Color(0x26FF7BD5));
    _orb(canvas, Offset(w * .12, h * .24), w * .28, const Color(0x224FC3F7));
    _orb(canvas, Offset(w * .55, h * .88), w * .40, const Color(0x15FFC531));

    // perspective grid road
    final horizon = h * .74;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = 1;
    for (var i = -7; i <= 7; i++) {
      canvas.drawLine(
          Offset(w * .5 + i * w * .05, horizon),
          Offset(w * .5 + i * w * .36, h),
          gridPaint);
    }
    for (var i = 0; i < 5; i++) {
      final y = horizon + (h - horizon) * math.pow(i / 5, 2.2);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    // horizon glow band
    canvas.drawRect(
        Rect.fromLTRB(0, horizon - h * .015, w, horizon + h * .012),
        Paint()
          ..shader = LinearGradient(colors: [
            const Color(0x00FFFFFF),
            Colors.white.withValues(alpha: .25),
            const Color(0x00FFFFFF),
          ]).createShader(Rect.fromLTRB(0, horizon - h * .015, w, horizon + h * .012)));
  }

  void _orb(Canvas c, Offset at, double r, Color color) {
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(
                  colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
  }

  @override
  bool shouldRepaint(covariant _HomeBackdropPainter oldDelegate) => false;
}

/// Little frosted chips showing equipped bolt-ons.
class _ModChipRow extends StatelessWidget {
  const _ModChipRow({required this.mods});
  final List<String> mods;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final id in mods) {
      if (CarMod.byIdOrNull(id) == null) continue;
      final mod = CarMod.byIdOrNull(id)!;
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Text('${mod.emoji} ${mod.name}',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white70)),
      ));
    }
    if (chips.isEmpty) {
      return const SizedBox(height: 8);
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.save});
  final GameSave save;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statChip(Icons.monetization_on_rounded, '${save.coins}',
            AppTheme.coinGold),
        const SizedBox(width: 10),
        _statChip(Icons.star_rounded, '${save.totalStars}', AppTheme.nicePink),
        const SizedBox(width: 10),
        _statChip(Icons.directions_car_rounded,
            CarSpec.byId(save.selectedCarId).name, AppTheme.niceBlue),
      ],
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Ghost glass action button with an accent glow icon.
class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final a = accent ?? AppTheme.niceBlue;
    return GestureDetector(
      onTap: () {
        AudioHub.instance.play(Sfx.click);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: a.withValues(alpha: .55), width: 1.6),
          boxShadow: [
            BoxShadow(
                color: a.withValues(alpha: .28),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: a),
            const SizedBox(width: 9),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Small car canvas used by level-select too (unchanged public API).
class CarBadge extends StatelessWidget {
  const CarBadge({
    required this.car,
    this.size = 120,
    this.bodyStyle = BodyStyle.classic,
    this.mods = const <String>[],
    super.key,
  });
  final CarSpec car;
  final double size;
  final BodyStyle bodyStyle;
  final List<String> mods;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.6,
      height: size * 0.85,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: CustomPaint(
        size: Size(size * 1.6, size * 0.85),
        painter: CarPreviewPainter(
          car,
          bodyStyle: bodyStyle,
          mods: mods,
        ),
      ),
    );
  }
}
