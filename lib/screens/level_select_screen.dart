import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';

/// Level select screen: 8 championship races with bespoke themed 3D cards,
/// progression beacon, stats capsules, and instant car switcher.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({required this.save, super.key});
  final GameSave save;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

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

  Future<void> _start(LevelSpec level) async {
    AudioHub.instance.play(Sfx.click);
    await Navigator.of(context).pushNamed('/race', arguments: {
      'level': level,
      'car': CarSpec.byId(widget.save.selectedCarId),
    });
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openGarage() async {
    AudioHub.instance.play(Sfx.click);
    await Navigator.of(context).pushNamed('/garage');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = LevelSpec.levels;
    final save = widget.save;
    final selectedCar = CarSpec.byId(save.selectedCarId);

    // Identify which level is the current "next up" race to highlight
    final nextRaceIndex = save.maxUnlockedLevel.clamp(0, levels.length - 1);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated ambient clouds
              const _DriftingClouds(),

              // Ambient sun
              Positioned(
                top: 8,
                right: 28,
                child: _PulsingSun(),
              ),

              // Main content layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Top Header Bar
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _enterCtrl,
                      curve: Curves.easeOutCubic,
                    )),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 880,
                          child: Row(
                            children: [
                          // 3D Beveled Back Button
                          _BeveledBackButton(
                            onPressed: () {
                              AudioHub.instance.play(Sfx.click);
                              Navigator.pop(context);
                            },
                          ),

                          const SizedBox(width: 12),

                          // Championship Title Lockup
                          ShimmerSweep(
                            duration: const Duration(seconds: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.emoji_events_rounded,
                                      color: AppTheme.coinGold,
                                      size: 26,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CHAMPIONSHIP RACES',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.inkDark,
                                            letterSpacing: 1.5,
                                            shadows: [
                                              Shadow(
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                offset: const Offset(0, 2),
                                                blurRadius: 0,
                                              ),
                                              Shadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.14),
                                                offset: const Offset(0, 3),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '8 ADVENTURE LEVELS • ${save.completedLevels.length}/8 COMPLETED',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.nicePink,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // HUD Capsules: Coins + Stars + Car Shortcut
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Selected Car Shortcut Chip
                              GestureDetector(
                                onTap: _openGarage,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: selectedCar.bodyColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        selectedCar.name.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.inkDark,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.tune_rounded,
                                        size: 13,
                                        color: AppTheme.niceBlue,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Coins Capsule
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: Colors.white, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.coinGold
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_rounded,
                                      color: AppTheme.coinGold,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${save.coins}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.inkDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Stars Capsule (Total / 24)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFFFD93D),
                                    Color(0xFFFFA500),
                                  ]),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.coinGold
                                          .withValues(alpha: 0.45),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${save.totalStars} / 24',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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

                  const SizedBox(height: 6),

                  // 4 Columns x 2 Rows Landscape Championship Grid
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 920,
                            maxHeight: 330,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 1.48,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: levels.length,
                              itemBuilder: (context, i) {
                                final level = levels[i];
                                final unlocked =
                                    save.isLevelUnlocked(level.index);
                                final isCompleted =
                                    save.isLevelCompleted(level.index);
                                final isNext = unlocked &&
                                    !isCompleted &&
                                    (i == nextRaceIndex ||
                                        save.starsFor(level.index) == 0);
                                final racesNeeded = (level.index -
                                        (GameSave.defaultUnlockedCount +
                                            save.completedLevels.length) +
                                        1)
                                    .clamp(1, 8);

                                final staggerAnim = CurvedAnimation(
                                  parent: _enterCtrl,
                                  curve: Interval(
                                    (i * 0.08).clamp(0.0, 0.75),
                                    1.0,
                                    curve: Curves.easeOutBack,
                                  ),
                                );

                                return FadeTransition(
                                  opacity: staggerAnim,
                                  child: ScaleTransition(
                                    scale: staggerAnim,
                                    child: _ChampionshipTrackCard(
                                      level: level,
                                      stars: save.starsFor(level.index),
                                      unlocked: unlocked,
                                      isCompleted: isCompleted,
                                      isNext: isNext,
                                      racesNeededToUnlock: racesNeeded,
                                      onTap: unlocked
                                          ? () => _start(level)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 3D Beveled Back Button ──────────────────────────────────────────────────

class _BeveledBackButton extends StatefulWidget {
  const _BeveledBackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_BeveledBackButton> createState() => _BeveledBackButtonState();
}

class _BeveledBackButtonState extends State<_BeveledBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const size = 42.0;
    const depth = 4.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: size,
        height: size + depth,
        child: Stack(
          children: [
            // Bottom 3D shadow extrusion
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFB0BEC5),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),

            // Top Moving Face
            Positioned(
              left: 0,
              right: 0,
              top: _pressed ? depth * 0.75 : 0,
              height: size,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFF1F5F9)],
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.inkDark,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Championship Track Card ────────────────────────────────────────────────

class _ChampionshipTrackCard extends StatefulWidget {
  const _ChampionshipTrackCard({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.isCompleted,
    required this.isNext,
    required this.racesNeededToUnlock,
    required this.onTap,
  });

  final LevelSpec level;
  final int stars;
  final bool unlocked;
  final bool isCompleted;
  final bool isNext;
  final int racesNeededToUnlock;
  final VoidCallback? onTap;

  @override
  State<_ChampionshipTrackCard> createState() => _ChampionshipTrackCardState();
}

class _ChampionshipTrackCardState extends State<_ChampionshipTrackCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ShakeFeedbackState> _shakeKey =
      GlobalKey<ShakeFeedbackState>();

  bool _pressed = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isNext) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ChampionshipTrackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNext && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isNext && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.unlocked) {
      HapticFeedback.lightImpact();
      AudioHub.instance.play(Sfx.bounce);
      _shakeKey.currentState?.shake();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final racesText = widget.racesNeededToUnlock == 1
          ? '1 more race'
          : '${widget.racesNeededToUnlock} more races';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🏆 Win $racesText to unlock ${widget.level.name}!',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.inkDark,
        ),
      );
    } else {
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.gradientFor(widget.level.theme);
    final depthColor = AppTheme.depthColorFor(widget.level.theme);
    final themeIcon = AppTheme.iconFor(widget.level.theme);
    final themeTag = AppTheme.tagFor(widget.level.theme);

    const bevelDepth = 5.0;

    return ShakeFeedback(
      key: _shakeKey,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          _handleTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: SizedBox(
          height: 142 + bevelDepth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bottom 3D shadow bevel extrusion
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: bevelDepth,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.unlocked
                        ? depthColor
                        : Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Moving Face Layer
              Positioned(
                left: 0,
                right: 0,
                top: _pressed ? bevelDepth * 0.75 : 0,
                bottom: _pressed ? 0 : bevelDepth,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    final pulse = widget.isNext ? _pulseCtrl.value : 0.0;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: widget.isNext
                              ? Color.lerp(
                                  const Color(0xFFFFD54F),
                                  Colors.white,
                                  pulse,
                                )!
                              : Colors.white.withValues(alpha: 0.45),
                          width: widget.isNext ? 2.2 : 1.2,
                        ),
                        boxShadow: widget.isNext
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD54F)
                                      .withValues(alpha: 0.45 + pulse * 0.35),
                                  blurRadius: 10 + pulse * 6,
                                  spreadRadius: 1 + pulse * 2,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      // Upper glossy sheen reflection
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.32),
                                Colors.white.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Periodic shimmer sweep on unlocked tiles
                      if (widget.unlocked)
                        Positioned.fill(
                          child: ShimmerSweep(
                            duration: const Duration(seconds: 4),
                            delay:
                                Duration(milliseconds: widget.level.index * 250),
                            child: const SizedBox.expand(),
                          ),
                        ),

                      // Card Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Row: Level Index + Themed Tag + 3 Stars
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Level number badge + theme icon
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.28),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          themeIcon,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            'LVL ${widget.level.index + 1} • $themeTag',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 4),

                                // 3 Stars display
                                _StarsDisplay(stars: widget.stars),
                              ],
                            ),

                            // Middle: Track Name & Subtitle
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.level.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        offset: Offset(0, 1.5),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  widget.level.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.88),
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Bottom Row: Distance + Speed + Call to Action
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Distance & Speed Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.flag_rounded,
                                        size: 10,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${widget.level.targetDistance.toInt()}m',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(
                                        Icons.bolt_rounded,
                                        size: 10,
                                        color: AppTheme.coinGold,
                                      ),
                                      Text(
                                        '${widget.level.cruiseSpeed.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status action badge
                                if (widget.isNext)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD54F),
                                          Color(0xFFFF9800),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 3,
                                          offset: Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.play_arrow_rounded,
                                          size: 11,
                                          color: AppTheme.inkDark,
                                        ),
                                        SizedBox(width: 1),
                                        Text(
                                          'RACE',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.inkDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (widget.isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'DONE',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (widget.stars > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.replay_rounded,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'PLAY',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Translucent Locked Shield Overlay (keeps track name & theme visible!)
                      if (!widget.unlocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.32),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B)
                                      .withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.lock_rounded,
                                          color: AppTheme.coinGold,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'LOCKED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Win ${widget.racesNeededToUnlock} more ${widget.racesNeededToUnlock == 1 ? "race" : "races"}',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.88),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stars Display ──────────────────────────────────────────────────────────

class _StarsDisplay extends StatelessWidget {
  const _StarsDisplay({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            Icons.star_rounded,
            size: 16,
            color: earned
                ? AppTheme.coinGold
                : Colors.white.withValues(alpha: 0.3),
            shadows: earned
                ? const [
                    Shadow(
                      color: Colors.black38,
                      offset: Offset(0, 1.5),
                      blurRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      }),
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
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

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
              child: Container(
                width: c.size,
                height: c.size * 0.42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(c.size),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
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
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

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
        final glow = 5 + _ctrl.value * 10;
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.coinGold,
            boxShadow: [
              BoxShadow(
                color: AppTheme.coinGold.withValues(alpha: 0.65),
                blurRadius: glow,
                spreadRadius: glow * 0.3,
              ),
            ],
          ),
        );
      },
    );
  }
}
