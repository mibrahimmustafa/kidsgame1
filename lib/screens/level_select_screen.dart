import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';

/// Level select: 8 themed races + one vital rule — you unlock the next
/// race the moment you finish the previous one (no 3-stars required:
/// finishing is the win for a 7-year-old).
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({required this.save, super.key});
  final GameSave save;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    AudioHub.instance.playMusic('menu_music');
  }

  @override
  Widget build(BuildContext context) {
    final levels = LevelSpec.levels;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      AudioHub.instance.play(Sfx.click);
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  Text('RACES',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              color: AppTheme.inkDark,
                              fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.coinGold,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    margin: const EdgeInsets.only(right: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text('${widget.save.totalStars}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.15,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (context, i) {
                    final level = levels[i];
                    final unlocked =
                        widget.save.isLevelUnlocked(level.index);
                    return _LevelTile(
                      level: level,
                      stars: widget.save.starsFor(level.index),
                      unlocked: unlocked,
                      onTap: unlocked ? () => _start(level) : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _start(LevelSpec level) {
    AudioHub.instance.play(Sfx.click);
    Navigator.of(context).pushNamed('/race', arguments: {
      'level': level,
      'car': CarSpec.byId(widget.save.selectedCarId),
    });
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.onTap,
  });

  final LevelSpec level;
  final int stars;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.gradientFor(level.theme);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${level.index + 1}',
                      style: TextStyle(
                          fontSize: 34,
                          color: Colors.white.withValues(alpha: .65),
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(
                    level.name,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 4)
                        ]),
                  ),
                  Text(
                    level.subtitle,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: .55)),
                  ),
                ],
              ),
            ),
            if (!unlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.white, size: 30),
                        Text('Finish race ${level.index}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: List.generate(3, (i) {
                  return Icon(
                    Icons.star_rounded,
                    size: 22,
                    color: i < stars ? AppTheme.coinGold : Colors.white24,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
