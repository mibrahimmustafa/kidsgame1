import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';

/// Pick one of six racers. Every car is viable; upgrades are about speed,
/// grip and nitro power — never pay-to-win, purely fun-to-drive variety.
class GarageScreen extends StatefulWidget {
  const GarageScreen({required this.save, super.key});
  final GameSave save;

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pc = PageController(viewportFraction: 0.72);
  int _index = 0;
  bool _showConfetti = false;

  CarSpec get _current =>
      CarSpec.cars[_index.clamp(0, CarSpec.cars.length - 1)];

  void _move(int delta) {
    AudioHub.instance.play(Sfx.click);
    final target = (_index + delta).clamp(0, CarSpec.cars.length - 1);
    _pc.animateToPage(target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic);
    setState(() => _index = target);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _buyOrSelect() {
    final car = _current;
    if (widget.save.isCarOwned(car.id)) {
      AudioHub.instance.play(Sfx.click);
      setState(() => widget.save.selectedCarId = car.id);
      return;
    }
    if (widget.save.coins < car.price) {
      AudioHub.instance.play(Sfx.bounce, volume: 0.7);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You need ${car.price - widget.save.coins} more coins!'),
        backgroundColor: AppTheme.inkDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Buy ${car.name}?'),
        content: Text(
            'It costs ${car.price} coins. Your coins: ${widget.save.coins}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.niceGreen),
            onPressed: () {
              widget.save.buyCar(car);
              AudioHub.instance.play(Sfx.star);
              Navigator.pop(ctx);
              setState(() => _showConfetti = true);
              Future.delayed(const Duration(milliseconds: 1900), () {
                if (mounted) setState(() => _showConfetti = false);
              });
            },
            child: const Text('Buy it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 10),
                  // Header
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      PressableButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: AppTheme.inkDark),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '🚗 GARAGE',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: AppTheme.inkDark,
                                fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      _coinBadge(),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // Cars PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pc,
                      itemCount: CarSpec.cars.length,
                      onPageChanged: (i) {
                        setState(() => _index = i);
                        AudioHub.instance.play(Sfx.click);
                      },
                      itemBuilder: (context, i) {
                        final car = CarSpec.cars[i];
                        final owned = widget.save.isCarOwned(car.id);
                        final selected = widget.save.selectedCarId == car.id;
                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: _CarCard(
                            car: car,
                            owned: owned,
                            selected: selected,
                            coins: widget.save.coins,
                            onTap: _buyOrSelect,
                          ),
                        );
                      },
                    ),
                  ),

                  // Dot indicator + nav arrows
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoundIconButton(
                            hero: false,
                            icon: Icons.chevron_left_rounded,
                            onTap: () => _move(-1)),
                        const SizedBox(width: 14),
                        // Dot indicators
                        Row(
                          children: List.generate(CarSpec.cars.length, (i) {
                            final active = i == _index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppTheme.niceOrange
                                    : Colors.black26,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 14),
                        _RoundIconButton(
                            hero: false,
                            icon: Icons.chevron_right_rounded,
                            onTap: () => _move(1)),
                      ],
                    ),
                  ),
                ],
              ),

              // Confetti overlay
              if (_showConfetti)
                const Positioned.fill(child: IgnorePointer(child: ConfettiOverlay())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coinBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFD93D), Color(0xFFFFA500)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.coinGold.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text('${widget.save.coins}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.hero = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    return PressableButton(
      onPressed: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: hero ? Colors.white : const Color(0x30000000),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: hero ? AppTheme.inkDark : Colors.white, size: 26),
      ),
    );
  }
}

class _CarCard extends StatefulWidget {
  const _CarCard({
    required this.car,
    required this.owned,
    required this.selected,
    required this.coins,
    required this.onTap,
  });

  final CarSpec car;
  final bool owned;
  final bool selected;
  final int coins;
  final VoidCallback onTap;

  @override
  State<_CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<_CarCard>
    with SingleTickerProviderStateMixin {
  // Rotating glow border for selected car
  late final AnimationController _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final dark = darken(car.bodyColor, .3);
    final cardBg = lighten(car.bodyColor, 0.55);

    Widget card = Container(
      decoration: BoxDecoration(
        // Tinted background based on car color
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, cardBg.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: widget.selected
            ? null
            : Border.all(color: Colors.transparent, width: 3),
        boxShadow: [
          BoxShadow(
            color: widget.selected
                ? car.bodyColor.withValues(alpha: 0.4)
                : Colors.black12,
            blurRadius: widget.selected ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Side: Name + Car Preview + Select/Buy Button
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    car.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: dark == Colors.white ? AppTheme.inkDark : dark,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Car preview with color glow shadow
                  Bouncy(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Color shadow ellipse
                        Container(
                          width: 170,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: car.bodyColor.withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 190,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CustomPaint(
                            size: const Size(190, 100),
                            painter: CarPreviewPainter(car),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Select / Buy Button
                  PressableButton(
                    onPressed: widget.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.selected
                              ? [AppTheme.niceGreen, const Color(0xFF34B362)]
                              : widget.owned
                                  ? [AppTheme.niceBlue, const Color(0xFF3A7FD5)]
                                  : widget.coins >= car.price
                                      ? [AppTheme.coinGold, const Color(0xFFF5A623)]
                                      : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.selected
                                    ? AppTheme.niceGreen
                                    : widget.owned
                                        ? AppTheme.niceBlue
                                        : AppTheme.coinGold)
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.selected
                            ? 'SELECTED ✓'
                            : widget.owned
                                ? 'SELECT'
                                : 'BUY • ${car.price}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // Soft vertical divider
              Container(
                width: 1.5,
                height: 160,
                color: Colors.black.withValues(alpha: 0.08),
              ),

              const SizedBox(width: 20),

              // Right Side: Car Description + Stat Bars
              SizedBox(
                width: 240,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkDark,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Colored stat bars
                    _StatRow(
                        label: 'SPEED',
                        value: car.topSpeed / 76,
                        color: AppTheme.niceGreen),
                    const SizedBox(height: 6),
                    _StatRow(
                        label: 'GRIP',
                        value: car.handling / 3.25,
                        color: AppTheme.niceBlue),
                    const SizedBox(height: 6),
                    _StatRow(
                        label: 'NITRO',
                        value: (car.boostPower - 1.2) / 0.6,
                        color: Colors.cyanAccent.shade700),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Animated glowing border for selected car
    if (widget.selected) {
      card = AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, child) {
          final t = _glowCtrl.value;
          // Cycle through 3 glow colors
          final colors = [
            AppTheme.niceGreen,
            Colors.cyanAccent.shade400,
            AppTheme.coinGold,
          ];
          final idx = (t * 3).floor() % 3;
          final frac = (t * 3) - idx.toDouble();
          final glowColor = Color.lerp(colors[idx], colors[(idx + 1) % 3], frac)!;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment(math.cos(t * 2 * math.pi),
                    math.sin(t * 2 * math.pi)),
                end: Alignment(-math.cos(t * 2 * math.pi),
                    -math.sin(t * 2 * math.pi)),
                colors: [
                  glowColor,
                  glowColor.withValues(alpha: 0.4),
                ],
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: card,
        ),
      );
    }

    return card;
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45)),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0, 1)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: v,
                  color: color,
                  backgroundColor: Colors.black12,
                  minHeight: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
