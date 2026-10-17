import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';

/// End of race: celebrates like crazy when they win, and when they
/// come short it says “try again” — never “you failed”.
class ResultScreen extends StatefulWidget {
  const ResultScreen({required this.result, required this.save, super.key});
  final RunResult result;
  final GameSave save;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late int _stars = 0;

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _stars = r.finished ? _rubricStars(r) : 0;
    // persist: coins always counted (collectibles), unlock on finish.
    widget.save.recordRun(r, _stars);
    if (r.finished) {
      AudioHub.instance.play(Sfx.win);
    } else {
      AudioHub.instance.play(Sfx.oops, volume: 0.6);
    }
  }

  int _rubricStars(RunResult r) {
    var s = 1;
    if (r.heartsLeft >= 2) s++;
    if (r.heartsLeft >= kMaxHearts || r.starsCollected >= 12) s++;
    return s.clamp(1, 3);
  }
  LevelSpec get _level =>
      LevelSpec.levels[widget.result.levelIndex.clamp(0, LevelSpec.levels.length - 1)];

  bool get _hasNext =>
      widget.result.levelIndex >= 0 &&
      widget.result.levelIndex + 1 < LevelSpec.levels.length;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final win = r.finished;
    return Scaffold(
      backgroundColor: win ? const Color(0xFF2CB87A) : const Color(0xFF6B6349),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              win ? TripleZeros.win : 'TRY AGAIN!',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 6)]),
            ),
            const SizedBox(height: 10),
            const Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.coinGold,
              size: 56,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.star_rounded,
                    size: 42,
                    color: i < _stars ? AppTheme.coinGold : Colors.black26,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            _ResultCard(result: r, stars: _stars),
            const SizedBox(height: 22),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ResultButton(
                  label: 'HOME',
                  color: AppTheme.niceBlue,
                  icon: Icons.home_rounded,
                  onPressed: () => Navigator.popUntil(context,
                      (route) => route.settings.name == '/home' || route.isFirst),
                ),
                const SizedBox(width: 12),
                _ResultButton(
                  label: 'RETRY',
                  color: AppTheme.niceOrange,
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    Navigator.of(context)
                        .pushReplacementNamed('/race', arguments: <String, dynamic>{
                      'level': _level,
                      'car': CarSpec.byId(widget.save.selectedCarId),
                    });
                  },
                ),
                if (win && _hasNext) ...[
                  const SizedBox(width: 12),
                  _ResultButton(
                    label: 'NEXT',
                    color: AppTheme.niceGreen,
                    icon: Icons.skip_next_rounded,
                    onPressed: () {
                      final next = LevelSpec.levels[widget.result.levelIndex + 1];
                      Navigator.of(context)
                          .pushReplacementNamed('/race', arguments: <String, dynamic>{
                        'level': next,
                        'car': CarSpec.byId(widget.save.selectedCarId),
                      });
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Small neutral holder (avoid world import helper).
const int kMaxHearts = 3;

class TripleZeros {
  static const win = 'YOU WIN!';
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.stars});
  final RunResult result;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(Icons.monetization_on_rounded,
                  '${result.coinsCollected}', AppTheme.coinGold),
              _stat(Icons.star_rounded, '${result.starsCollected}',
                  AppTheme.nicePink),
              _stat(Icons.favorite_rounded, '${result.heartsLeft}',
                  AppTheme.niceOrange),
              _stat(Icons.emoji_events_rounded, '+${result.earnedCoins}',
                  AppTheme.niceGreen),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Great drive! Keep those wheels rolling!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black.withValues(alpha: .6), fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}

class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        icon: Icon(icon),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        onPressed: () {
          AudioHub.instance.play(Sfx.click);
          onPressed();
        },
      ),
    );
  }
}
