import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';

/// End of race: celebrates like crazy when they win, and when they
/// come short it says "try again" — never "you failed".
///
/// Features a dedicated Prize Showcase (revealing unlocked tracks & bonuses)
/// and a Championship Level Progression Map so the player clearly sees
/// all 8 levels, their completions, and what world unlocks next.
class ResultScreen extends StatefulWidget {
  const ResultScreen({required this.result, required this.save, super.key});
  final RunResult result;
  final GameSave save;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late int _stars = 0;
  late bool _unlockedNew = false;
  late bool _wasCompleted = false;
  late bool _firstTimeWin = false;
  LevelSpec? _newlyUnlockedLevel;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _stars = r.finished ? _rubricStars(r) : 0;
    _wasCompleted =
        r.levelIndex >= 0 && widget.save.isLevelCompleted(r.levelIndex);
    _firstTimeWin = r.finished && !_wasCompleted && r.levelIndex >= 0;

    _unlockedNew = widget.save.recordRun(r, _stars);
    final newMax = widget.save.maxUnlockedLevel;
    if (_unlockedNew && newMax < LevelSpec.levels.length) {
      _newlyUnlockedLevel = LevelSpec.levels[newMax];
    }

    if (r.finished) {
      AudioHub.instance.play(Sfx.win);
      if (_unlockedNew || _firstTimeWin) {
        Future.delayed(const Duration(milliseconds: 500), () {
          AudioHub.instance.play(Sfx.coin);
        });
      }
    } else {
      AudioHub.instance.play(Sfx.oops, volume: 0.6);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _rubricStars(RunResult r) {
    var s = 1;
    if (r.heartsLeft >= 2) s++;
    if (r.heartsLeft >= kMaxHearts || r.starsCollected >= 12) s++;
    return s.clamp(1, 3);
  }

  LevelSpec get _level => LevelSpec.levels[
      widget.result.levelIndex.clamp(0, LevelSpec.levels.length - 1)];

  bool get _hasNext {
    if (widget.result.levelIndex < 0) return false;
    if (_unlockedNew && _newlyUnlockedLevel != null) return true;
    return widget.result.levelIndex + 1 < LevelSpec.levels.length &&
        widget.save.isLevelUnlocked(widget.result.levelIndex + 1);
  }

  LevelSpec get _nextLevel {
    if (_unlockedNew && _newlyUnlockedLevel != null) {
      return _newlyUnlockedLevel!;
    }
    final nextIdx = (widget.result.levelIndex + 1)
        .clamp(0, LevelSpec.levels.length - 1);
    return LevelSpec.levels[nextIdx];
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final win = r.finished;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Celebratory or twilight background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.25,
                colors: win
                    ? const [Color(0xFF4CE888), Color(0xFF147A46)]
                    : const [Color(0xFF8C7B5E), Color(0xFF3E3628)],
              ),
            ),
          ),

          // Win confetti particles
          if (win)
            const Positioned.fill(
                child: IgnorePointer(child: ConfettiOverlay())),

          // Scaled landscape console layout
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header & Title
                      FadeTransition(
                        opacity: _ctrl,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.4),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _ctrl,
                            curve: Curves.easeOutBack,
                          )),
                          child: win
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ShimmerSweep(
                                      duration: const Duration(seconds: 3),
                                      child: Text(
                                        r.levelIndex >= 0
                                            ? '🏆 LEVEL ${r.levelIndex + 1} CLEARED!'
                                            : '🏆 YOU WIN!',
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black38,
                                              offset: Offset(0, 2),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_unlockedNew &&
                                        _newlyUnlockedLevel != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD54F),
                                              Color(0xFFFF9800),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.card_giftcard_rounded,
                                              size: 15,
                                              color: AppTheme.inkDark,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'PRIZE UNLOCKED: LEVEL ${_newlyUnlockedLevel!.index + 1} (${_newlyUnlockedLevel!.name.toUpperCase()}) + 50🪙 BONUS!',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.inkDark,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (_firstTimeWin) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Text(
                                          '🎉 FIRST-TIME VICTORY: +50🪙 BONUS EARNED!',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.coinGold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '😅 TRY AGAIN!',
                                      style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black38,
                                            offset: Offset(0, 2),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Keep going! Beat this track to unlock the next level!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 3 Popping Stars
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final filled = i < _stars;
                          final delay = i * 0.22;
                          final start = delay.clamp(0.0, 0.7);
                          final end =
                              (delay + 0.35).clamp(start + 0.05, 1.0);
                          final starAnim = CurvedAnimation(
                            parent: _ctrl,
                            curve: Interval(start, end,
                                curve: Curves.elasticOut),
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: filled
                                ? ScaleTransition(
                                    scale: starAnim,
                                    child: const Icon(
                                      Icons.star_rounded,
                                      size: 40,
                                      color: AppTheme.coinGold,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black26,
                                            blurRadius: 6),
                                      ],
                                    ),
                                  )
                                : const Icon(
                                    Icons.star_rounded,
                                    size: 40,
                                    color: Colors.black26,
                                  ),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),

                      // Dual Center Showcase:
                      // Left: Prize Showcase
                      // Right: Championship Level Progression Map
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _ctrl,
                          curve: const Interval(0.25, 1.0,
                              curve: Curves.easeOutBack),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 🎁 Prize Showcase Card
                            _PrizeShowcaseCard(
                              result: r,
                              stars: _stars,
                              unlockedNew: _unlockedNew,
                              firstTimeWin: _firstTimeWin,
                              unlockedLevel: _newlyUnlockedLevel,
                              currentLevel:
                                  r.levelIndex >= 0 ? _level : null,
                            ),

                            const SizedBox(width: 14),

                            // 🗺️ Championship Levels Progress Card
                            _ChampionshipProgressCard(
                              save: widget.save,
                              currentLevelIndex: r.levelIndex,
                              newlyUnlockedIndex: _newlyUnlockedLevel?.index,
                              win: win,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons Row (Home, All Levels, Retry, Next Level)
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _ctrl,
                          curve: const Interval(0.5, 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // HOME
                            _ResultButton(
                              label: 'HOME',
                              color: AppTheme.niceBlue,
                              icon: Icons.home_rounded,
                              onPressed: () => Navigator.popUntil(
                                context,
                                (route) =>
                                    route.settings.name == '/home' ||
                                    route.isFirst,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ALL LEVELS (Allows user to inspect the full level grid)
                            _ResultButton(
                              label: 'ALL LEVELS',
                              color: const Color(0xFF7C3AED), // Indigo / Purple
                              icon: Icons.emoji_events_rounded,
                              onPressed: () {
                                Navigator.of(context)
                                    .pushReplacementNamed('/levels');
                              },
                            ),

                            const SizedBox(width: 10),

                            // RETRY
                            _ResultButton(
                              label: 'RETRY',
                              color: AppTheme.niceOrange,
                              icon: Icons.refresh_rounded,
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(
                                  '/race',
                                  arguments: <String, dynamic>{
                                    'level': _level,
                                    'car': CarSpec.byId(
                                        widget.save.selectedCarId),
                                  },
                                );
                              },
                            ),

                            // NEXT LEVEL (or PLAY NEW LEVEL)
                            if (win && _hasNext) ...[
                              const SizedBox(width: 10),
                              _ResultButton(
                                label: _unlockedNew
                                    ? 'PLAY LEVEL ${_nextLevel.index + 1}!'
                                    : 'NEXT LEVEL',
                                color: AppTheme.niceGreen,
                                icon: Icons.play_arrow_rounded,
                                isHero: true,
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed(
                                    '/race',
                                    arguments: <String, dynamic>{
                                      'level': _nextLevel,
                                      'car': CarSpec.byId(
                                          widget.save.selectedCarId),
                                    },
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const int kMaxHearts = 3;

// ─── 🎁 Prize Showcase Card ──────────────────────────────────────────────────

class _PrizeShowcaseCard extends StatelessWidget {
  const _PrizeShowcaseCard({
    required this.result,
    required this.stars,
    required this.unlockedNew,
    required this.firstTimeWin,
    required this.unlockedLevel,
    required this.currentLevel,
  });

  final RunResult result;
  final int stars;
  final bool unlockedNew;
  final bool firstTimeWin;
  final LevelSpec? unlockedLevel;
  final LevelSpec? currentLevel;

  @override
  Widget build(BuildContext context) {
    final win = result.finished;

    return Container(
      width: 345,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlockedNew
              ? const Color(0xFFFFD54F).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.35),
          width: unlockedNew ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: unlockedNew
                ? const Color(0xFFFF9800).withValues(alpha: 0.3)
                : Colors.black26,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Prize Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      unlockedNew
                          ? Icons.card_giftcard_rounded
                          : (win
                              ? Icons.emoji_events_rounded
                              : Icons.flag_rounded),
                      color: unlockedNew
                          ? const Color(0xFFFFD54F)
                          : (win ? AppTheme.coinGold : Colors.white70),
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        unlockedNew
                            ? 'PRIZE: NEXT LEVEL UNLOCKED!'
                            : (win ? 'VICTORY REWARDS' : 'RACE RESULT'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: unlockedNew
                              ? const Color(0xFFFFD54F)
                              : Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (unlockedNew) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW!',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.inkDark,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Center Preview Area
          if (unlockedNew && unlockedLevel != null) ...[
            // Showcase preview of the newly unlocked level
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientFor(unlockedLevel!.theme),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppTheme.iconFor(unlockedLevel!.theme),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LEVEL ${unlockedLevel!.index + 1}: ${unlockedLevel!.name.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          '${unlockedLevel!.targetDistance.toInt()}m Adventure Track',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '+50🪙',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.inkDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (win) ...[
            // Standard win bounty showcase
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat(
                  Icons.monetization_on_rounded,
                  '+${result.earnedCoins + (firstTimeWin ? 50 : 0)}',
                  'COINS',
                  AppTheme.coinGold,
                ),
                _miniStat(
                  Icons.star_rounded,
                  '${result.starsCollected}',
                  'STARS',
                  AppTheme.nicePink,
                ),
                _miniStat(
                  Icons.favorite_rounded,
                  '${result.heartsLeft}',
                  'HEARTS',
                  AppTheme.niceOrange,
                ),
              ],
            ),
          ] else ...[
            // Try again state
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${result.distanceTravelled.toInt()}m Driven • ${result.coinsCollected} Coins Saved',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Keep steering smoothly to reach the finish line!',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],

          // Bottom footer caption
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  unlockedNew
                      ? '+${result.earnedCoins} Coins + 50 Bonus'
                      : (firstTimeWin
                          ? '+50 First-Time Victory Bonus!'
                          : 'Great drive! Keep wheels rolling!'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (win)
                Text(
                  '⭐ $stars / 3 STARS',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.coinGold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── 🗺️ Championship Level Progression Card ──────────────────────────────────

class _ChampionshipProgressCard extends StatelessWidget {
  const _ChampionshipProgressCard({
    required this.save,
    required this.currentLevelIndex,
    required this.newlyUnlockedIndex,
    required this.win,
  });

  final GameSave save;
  final int currentLevelIndex;
  final int? newlyUnlockedIndex;
  final bool win;

  @override
  Widget build(BuildContext context) {
    final levels = LevelSpec.levels;
    final completedCount = save.completedLevels.length;

    return Container(
      width: 385,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Row: Championship levels + Completion Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.map_rounded,
                      color: AppTheme.coinGold,
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'CHAMPIONSHIP LEVELS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$completedCount / ${levels.length} DONE',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          // 8-Level Mini Track Map
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(levels.length, (i) {
              final isCompleted = save.isLevelCompleted(i);
              final isNewlyUnlocked = i == newlyUnlockedIndex;
              final isUnlocked = save.isLevelUnlocked(i);
              final isCurrent = i == currentLevelIndex;

              Color bgColor;
              Color borderColor;
              Widget iconWidget;

              if (isCompleted) {
                bgColor = const Color(0xFF10B981);
                borderColor = Colors.white.withValues(alpha: 0.6);
                iconWidget = const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 15,
                );
              } else if (isNewlyUnlocked) {
                bgColor = const Color(0xFFFF9800);
                borderColor = const Color(0xFFFFD54F);
                iconWidget = const Icon(
                  Icons.lock_open_rounded,
                  color: AppTheme.inkDark,
                  size: 15,
                );
              } else if (isUnlocked) {
                bgColor = const Color(0xFF3B82F6);
                borderColor = isCurrent
                    ? const Color(0xFFFFD54F)
                    : Colors.white.withValues(alpha: 0.4);
                iconWidget = const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 15,
                );
              } else {
                bgColor = Colors.black.withValues(alpha: 0.38);
                borderColor = Colors.white.withValues(alpha: 0.15);
                iconWidget = const Icon(
                  Icons.lock_rounded,
                  color: Colors.white38,
                  size: 13,
                );
              }

              return Container(
                width: 39,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                    width: (isCurrent || isNewlyUnlocked) ? 2.0 : 1.0,
                  ),
                  boxShadow: (isNewlyUnlocked || isCurrent)
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD54F)
                                .withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWidget,
                    const SizedBox(height: 1),
                    Text(
                      'L${i + 1}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: (isNewlyUnlocked)
                            ? AppTheme.inkDark
                            : (isUnlocked ? Colors.white : Colors.white54),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Bottom Hint Text
          Text(
            completedCount >= levels.length
                ? '🌟 Ultimate Champion! All ${levels.length} championship tracks conquered!'
                : (newlyUnlockedIndex != null
                    ? '🎁 Level ${(newlyUnlockedIndex! + 1)} unlocked and ready to play!'
                    : 'Win more races to unlock all ${levels.length} championship worlds!'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: newlyUnlockedIndex != null
                  ? const Color(0xFFFFD54F)
                  : Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
    this.isHero = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isHero;

  @override
  Widget build(BuildContext context) {
    return PressableButton(
      onPressed: () {
        AudioHub.instance.play(Sfx.click);
        onPressed();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isHero ? 20 : 16,
          vertical: isHero ? 13 : 11,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isHero
                ? [
                    const Color(0xFF6EE7B7),
                    const Color(0xFF10B981),
                    const Color(0xFF047857),
                  ]
                : [lighten(color, 0.12), color],
          ),
          borderRadius: BorderRadius.circular(24),
          border: isHero
              ? Border.all(color: Colors.white, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: (isHero ? Colors.greenAccent : color)
                  .withValues(alpha: 0.45),
              blurRadius: isHero ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: isHero ? 22 : 19),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontSize: isHero ? 14 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
