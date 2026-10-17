import 'package:flutter/material.dart';

import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';
import '../core/app_theme.dart';
import 'settings_dialog.dart';

/// Title screen: playful sky, bobbing car preview, and the three
/// “big kid buttons”: Races, Garage, Free Drive.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.save, super.key});
  final GameSave save;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AudioHub.instance.playMusic('menu_music');
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.skyGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // decorative clouds
              Positioned(
                top: 12,
                left: -30,
                child: _cloud(58),
              ),
              Positioned(
                top: 32,
                right: -20,
                child: _cloud(70),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'SPEEDY',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontSize: 44,
                              color: AppTheme.inkDark,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: const [
                                Shadow(
                                    color: Colors.white, offset: Offset(0, 3)),
                              ],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'STARS RACING',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontSize: 30,
                              color: AppTheme.nicePink,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          AudioHub.instance.play(Sfx.click);
                          Navigator.of(context)
                              .pushNamed('/garage', arguments: 'mods');
                        },
                        child: Column(
                          children: [
                            CarBadge(
                              car: car,
                              size: 132,
                              bodyStyle: BodyStyle.byId(save.bodyId),
                              mods: save.equippedMods,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .75),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons
                                      .handyman_rounded, size: 16, color: AppTheme.niceOrange),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'TAP TO CUSTOMIZE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.inkDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ContinueCard(
                        save: save,
                        onStart: () => _startRace(
                            LevelSpec.levels[save.maxUnlockedLevel]),
                      ),
                      const SizedBox(height: 14),
                      _GlassStatsRow(save: save),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BigButton(
                            color: AppTheme.niceGreen,
                            icon: Icons.emoji_events_rounded,
                            label: 'RACES',
                            onPressed: () {
                              AudioHub.instance.play(Sfx.click);
                              Navigator.of(context).pushNamed('/levels');
                            },
                          ),
                          const SizedBox(width: 12),
                          BigButton(
                            color: AppTheme.niceBlue,
                            icon: Icons.directions_car_rounded,
                            label: 'GARAGE',
                            onPressed: () {
                              AudioHub.instance.play(Sfx.click);
                              Navigator.of(context).pushNamed('/garage');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BigButton(
                        color: AppTheme.niceOrange,
                        icon: Icons.sports_esports_rounded,
                        label: 'FREE DRIVE',
                        onPressed: () => _startRace(LevelSpec.freeDrive),
                      ),
                    ],
                  ),
                ),
              ),
              // settings gear, kid-sized
              Positioned(
                right: 12,
                bottom: 12,
                child: _CircleIconButton(
                  icon: Icons.settings_rounded,
                  onTap: () {
                    AudioHub.instance.play(Sfx.click);
                    showParentSettingsDialog(context, save);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cloud(double s) {
    return Container(
      width: s,
      height: s * 0.42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(s),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.save, required this.onStart});
  final GameSave save;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final level =
        LevelSpec.levels[save.maxUnlockedLevel.clamp(0, LevelSpec.levels.length - 1)];
    final isNext = save.starsFor(level.index) == 0;
    return GestureDetector(
      onTap: onStart,
      child: Container(
        width: 312,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.gradientFor(level.theme),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(
                isNext ? Icons.play_arrow_rounded : Icons.replay_rounded,
                size: 30,
                color: AppTheme.niceGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNext ? 'NEXT RACE'.toUpperCase() : 'CONTINUE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: Colors.white.withValues(alpha: .8)),
                  ),
                  Text(level.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 19,
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
    );
  }
}

class _GlassStatsRow extends StatelessWidget {
  const _GlassStatsRow({required this.save});
  final GameSave save;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _glassChip(Icons.monetization_on_rounded, '${save.coins}',
            AppTheme.coinGold),
        const SizedBox(width: 10),
        _glassChip(Icons.star_rounded, '${save.totalStars}', AppTheme.nicePink),
        const SizedBox(width: 10),
        _glassChip(Icons.directions_car_rounded,
            CarSpec.byId(save.selectedCarId).name, AppTheme.niceBlue),
      ],
    );
  }

  Widget _glassChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  color: AppTheme.inkDark)),
        ],
      ),
    );
  }
}

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
        color: Colors.black12,
        borderRadius: BorderRadius.circular(24),
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

class BigButton extends StatelessWidget {
  const BigButton({
    required this.label,
    required this.color,
    this.icon,
    this.onPressed,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const width = 210.0;
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: width,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, darken(color, .16)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .45),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            AudioHub.instance.play(Sfx.click);
            onPressed?.call();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 26, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Icon(icon, color: AppTheme.inkDark),
      ),
    );
  }
}
