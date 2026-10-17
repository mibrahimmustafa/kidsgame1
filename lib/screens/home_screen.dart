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
                      CarBadge(car: car, size: 132),
                      const SizedBox(height: 18),
                      BigButton(
                        color: AppTheme.niceGreen,
                        icon: Icons.emoji_events_rounded,
                        label: 'RACES',
                        onPressed: () {
                          AudioHub.instance.play(Sfx.click);
                          Navigator.of(context).pushNamed('/levels');
                        },
                      ),
                      const SizedBox(height: 12),
                      BigButton(
                        color: AppTheme.niceBlue,
                        icon: Icons.directions_car_rounded,
                        label: 'GARAGE',
                        onPressed: () {
                          AudioHub.instance.play(Sfx.click);
                          Navigator.of(context).pushNamed('/garage');
                        },
                      ),
                      const SizedBox(height: 12),
                      BigButton(
                        color: AppTheme.niceOrange,
                        icon: Icons.sports_esports_rounded,
                        label: 'FREE DRIVE',
                        onPressed: () => _startRace(LevelSpec.freeDrive),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            color: AppTheme.coinGold,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${save.coins}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 18),
                          Icon(
                            Icons.star_rounded,
                            color: AppTheme.coinGold,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${save.totalStars}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ],
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
    return SizedBox(
      width: width,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          elevation: 6,
          shadowColor: color.withValues(alpha: .4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          AudioHub.instance.play(Sfx.click);
          onPressed?.call();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 26),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
              ),
            ),
          ],
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
